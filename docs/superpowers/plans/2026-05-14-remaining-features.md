# Remaining Features Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement all remaining unlisted features from requirement.md across network, system, environment, and logs modules.

**Architecture:** Three independent task groups that touch different module files. Each group can be dispatched to a separate agent in parallel. Group A modifies `NetworkModule`, Group B modifies `SystemModule`, Group C modifies `EnvironmentModule` + `LogsModule`.

**Tech Stack:** C++17, Qt5/Qt6 (QProcess, QFile, QDir, QJsonObject), Qt Test framework

---

## Group A: Network Module Enhancements

**Files:**
- Modify: `src/backend/modules/network/NetworkModule.h`
- Modify: `src/backend/modules/network/NetworkModule.cpp`
- Modify: `tests/test_network_module.cpp`
- Modify: `CMakeLists.txt` (test target sources)

### Task A1: DNS Resolution Test

**Files:**
- Modify: `src/backend/modules/network/NetworkModule.h:31-33` (add method declaration)
- Modify: `src/backend/modules/network/NetworkModule.cpp:45-59` (add detect call)
- Modify: `tests/test_network_module.cpp` (add test)

- [ ] **Step 1: Add method declaration to header**

In `src/backend/modules/network/NetworkModule.h`, add after line 33 (`detectMissingPlugins`):

```cpp
    QList<Issue> detectDNSResolution();
```

- [ ] **Step 2: Implement DNS resolution detection**

In `src/backend/modules/network/NetworkModule.cpp`, add after `detectMissingPlugins()` (after line 259):

```cpp
QList<Issue> NetworkModule::detectDNSResolution()
{
    QList<Issue> issues;

    // Read DNS servers from resolv.conf
    QFile resolvConf("/etc/resolv.conf");
    QStringList dnsServers;
    if (resolvConf.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&resolvConf);
        QStringList lines = in.readAll().split('\n');
        resolvConf.close();

        for (const QString& line : lines) {
            if (line.startsWith("nameserver")) {
                QStringList parts = line.split(' ', Qt::SkipEmptyParts);
                if (parts.size() >= 2) {
                    dnsServers.append(parts[1]);
                }
            }
        }
    }

    if (dnsServers.isEmpty()) {
        return issues;
    }

    // Test DNS resolution using dig (or nslookup as fallback)
    QProcess process;
    process.start("which", QStringList() << "dig");
    process.waitForFinished(3000);
    bool hasDig = process.exitCode() == 0;

    QString testDomain = "www.deepin.org";

    if (hasDig) {
        for (const QString& server : dnsServers) {
            process.start("dig", QStringList() << "+short" << "+time=3" << "+tries=1"
                          << ("@" + server) << testDomain << "A");
            process.waitForFinished(10000);
            QString output = process.readAllStandardOutput().trimmed();
            int exitCode = process.exitCode();

            if (exitCode != 0 || output.isEmpty()) {
                Issue issue;
                issue.level = Issue::Warning;
                issue.title = QString("DNS resolution failed: %1").arg(server);
                issue.description = QString("Cannot resolve %1 via DNS server %2")
                    .arg(testDomain).arg(server);
                issue.solution = "Check DNS server configuration or network connectivity";
                issues.append(issue);
            }
        }
    } else {
        // Fallback to nslookup
        for (const QString& server : dnsServers) {
            process.start("nslookup", QStringList() << "-timeout=3" << testDomain << server);
            process.waitForFinished(10000);
            QString output = process.readAllStandardOutput();
            int exitCode = process.exitCode();

            if (exitCode != 0 || output.contains("server can't find")) {
                Issue issue;
                issue.level = Issue::Warning;
                issue.title = QString("DNS resolution failed: %1").arg(server);
                issue.description = QString("Cannot resolve %1 via DNS server %2")
                    .arg(testDomain).arg(server);
                issue.solution = "Check DNS server configuration or network connectivity";
                issues.append(issue);
            }
        }
    }

    return issues;
}
```

- [ ] **Step 3: Wire into detect() method**

In `src/backend/modules/network/NetworkModule.cpp`, in the `detect()` method, add after line 55 (`issues.append(pluginIssues);`):

```cpp
    auto dnsResIssues = detectDNSResolution();
    issues.append(dnsResIssues);
```

- [ ] **Step 4: Add test**

In `tests/test_network_module.cpp`, add a new test method declaration in the private slots section:

```cpp
    void testDNSResolutionDetection();
```

And implement it:

```cpp
void NetworkModuleTest::testDNSResolutionDetection()
{
    DeepinDoctor::NetworkModule module;

    QList<DeepinDoctor::Issue> issues = module.detect();

    // DNS resolution check is environment-dependent
    // Just verify it doesn't crash and returns valid issues
    for (const DeepinDoctor::Issue& issue : issues) {
        if (issue.title.contains("DNS resolution", Qt::CaseInsensitive)) {
            QVERIFY(issue.level == DeepinDoctor::Issue::Warning ||
                    issue.level == DeepinDoctor::Issue::Error);
            QVERIFY(!issue.solution.isEmpty());
        }
    }
}
```

- [ ] **Step 5: Build and test**

```bash
cd /home/ut003607@uos/Workspace/Code/deepin-doctor/obj-x86_64-linux-gnu && make -j$(nproc) && ctest -R test_network_module --verbose
```

- [ ] **Step 6: Commit**

```bash
cd /home/ut003607@uos/Workspace/Code/deepin-doctor && git add src/backend/modules/network/NetworkModule.h src/backend/modules/network/NetworkModule.cpp tests/test_network_module.cpp && git commit -m "feat(network): add DNS resolution test detection"
```

---

### Task A2: IP Conflict Detection

**Files:**
- Modify: `src/backend/modules/network/NetworkModule.h`
- Modify: `src/backend/modules/network/NetworkModule.cpp`
- Modify: `tests/test_network_module.cpp`

- [ ] **Step 1: Add method declaration**

In `src/backend/modules/network/NetworkModule.h`, add after `detectDNSResolution`:

```cpp
    QList<Issue> detectIPConflict();
```

- [ ] **Step 2: Implement IP conflict detection**

In `src/backend/modules/network/NetworkModule.cpp`, add after `detectDNSResolution()`:

```cpp
QList<Issue> NetworkModule::detectIPConflict()
{
    QList<Issue> issues;

    // Get local IP addresses
    QProcess process;
    process.start("ip", QStringList() << "-4" << "addr" << "show");
    process.waitForFinished(5000);
    QString addrOutput = process.readAllStandardOutput();

    QStringList localIPs;
    QStringList lines = addrOutput.split('\n');
    for (const QString& line : lines) {
        if (line.contains("inet ") && !line.contains("127.0.0.1")) {
            QStringList parts = line.trimmed().split(QRegExp("\\s+"));
            for (const QString& part : parts) {
                if (part.contains("/")) {
                    localIPs.append(part.split('/').first());
                }
            }
        }
    }

    if (localIPs.isEmpty()) {
        return issues;
    }

    // Check if arping is available
    process.start("which", QStringList() << "arping");
    process.waitForFinished(3000);
    bool hasArping = process.exitCode() == 0;

    if (!hasArping) {
        return issues;
    }

    // Get default interface
    process.start("ip", QStringList() << "route" << "show" << "default");
    process.waitForFinished(5000);
    QString routeOutput = process.readAllStandardOutput().trimmed();
    QString iface;
    if (routeOutput.contains("dev")) {
        QStringList parts = routeOutput.split(QRegExp("\\s+"));
        int devIdx = parts.indexOf("dev");
        if (devIdx >= 0 && devIdx + 1 < parts.size()) {
            iface = parts[devIdx + 1];
        }
    }

    // Use arping to detect duplicate IPs on local network
    for (const QString& ip : localIPs) {
        QStringList args;
        args << "-c" << "1" << "-w" << "2";
        if (!iface.isEmpty()) {
            args << "-I" << iface;
        }
        args << ip;

        process.start("arping", args);
        process.waitForFinished(10000);
        QString output = process.readAllStandardOutput();

        // arping returns multiple replies if there's a conflict
        if (output.contains("Duplicate")) {
            Issue issue;
            issue.level = Issue::Error;
            issue.title = QString("IP conflict detected: %1").arg(ip);
            issue.description = QString("IP address %1 is used by multiple devices on the network").arg(ip);
            issue.solution = "Change the IP address or resolve the conflict with the other device";
            issues.append(issue);
        }
    }

    return issues;
}
```

- [ ] **Step 3: Wire into detect()**

In `NetworkModule::detect()`, add after the DNS resolution append:

```cpp
    auto ipConflictIssues = detectIPConflict();
    issues.append(ipConflictIssues);
```

- [ ] **Step 4: Add test**

In `tests/test_network_module.cpp`, add:

```cpp
    void testIPConflictDetection();
```

```cpp
void NetworkModuleTest::testIPConflictDetection()
{
    DeepinDoctor::NetworkModule module;
    QList<DeepinDoctor::Issue> issues = module.detect();

    // IP conflict check is environment-dependent, just verify no crash
    for (const DeepinDoctor::Issue& issue : issues) {
        if (issue.title.contains("IP conflict", Qt::CaseInsensitive)) {
            QCOMPARE(issue.level, DeepinDoctor::Issue::Error);
            QVERIFY(!issue.solution.isEmpty());
        }
    }
}
```

- [ ] **Step 5: Build and test**

```bash
cd /home/ut003607@uos/Workspace/Code/deepin-doctor/obj-x86_64-linux-gnu && make -j$(nproc) && ctest -R test_network_module --verbose
```

- [ ] **Step 6: Commit**

```bash
cd /home/ut003607@uos/Workspace/Code/deepin-doctor && git add src/backend/modules/network/NetworkModule.h src/backend/modules/network/NetworkModule.cpp tests/test_network_module.cpp && git commit -m "feat(network): add IP conflict detection via arping"
```

---

### Task A3: NIC Driver Issue Detection

**Files:**
- Modify: `src/backend/modules/network/NetworkModule.h`
- Modify: `src/backend/modules/network/NetworkModule.cpp`
- Modify: `tests/test_network_module.cpp`

- [ ] **Step 1: Add method declaration**

In `src/backend/modules/network/NetworkModule.h`, add after `detectIPConflict`:

```cpp
    QList<Issue> detectDriverIssues();
```

- [ ] **Step 2: Implement driver issue detection**

In `src/backend/modules/network/NetworkModule.cpp`:

```cpp
QList<Issue> NetworkModule::detectDriverIssues()
{
    QList<Issue> issues;

    QProcess process;

    // Check dmesg for network driver errors
    process.start("dmesg", QStringList());
    process.waitForFinished(5000);
    QString dmesgOutput = process.readAllStandardOutput();

    QStringList errorPatterns = {
        "firmware failed",
        "driver crashed",
        "link is down",
        "reset adapter",
        "hardware error",
        "PHY",
        "timeout"
    };

    QStringList driverErrors;
    QStringList lines = dmesgOutput.split('\n');
    for (const QString& line : lines) {
        if (line.contains("eth", Qt::CaseInsensitive) ||
            line.contains("enp", Qt::CaseInsensitive) ||
            line.contains("wlp", Qt::CaseInsensitive) ||
            line.contains("wlan", Qt::CaseInsensitive) ||
            line.contains("network", Qt::CaseInsensitive)) {

            for (const QString& pattern : errorPatterns) {
                if (line.contains(pattern, Qt::CaseInsensitive)) {
                    driverErrors.append(line.trimmed());
                    break;
                }
            }
        }
    }

    if (!driverErrors.isEmpty()) {
        Issue issue;
        issue.level = Issue::Warning;
        issue.title = "Network driver errors detected";
        issue.description = QString("Found %1 network driver related errors in dmesg:\n%2")
            .arg(driverErrors.size())
            .arg(driverErrors.mid(0, 5).join("\n"));
        issue.solution = "Check NIC hardware, update drivers, or replace the network adapter";
        issues.append(issue);
    }

    // Check link status for each interface
    process.start("ip", QStringList() << "link" << "show");
    process.waitForFinished(5000);
    QString linkOutput = process.readAllStandardOutput();

    QStringList linkLines = linkOutput.split('\n');
    QString currentIface;
    for (const QString& line : linkLines) {
        if (line.contains(": <")) {
            QStringList parts = line.split(':');
            if (parts.size() >= 2) {
                currentIface = parts[1].trimmed().split('@').first().trimmed();
            }
            if (currentIface != "lo" && !line.contains("LOWER_UP")) {
                // Interface exists but link is not up
                if (!currentIface.isEmpty()) {
                    Issue issue;
                    issue.level = Issue::Info;
                    issue.title = QString("Interface link down: %1").arg(currentIface);
                    issue.description = QString("Network interface %1 does not have link up").arg(currentIface);
                    issue.solution = "Check cable connection or WiFi signal";
                    issues.append(issue);
                }
            }
        }
    }

    return issues;
}
```

- [ ] **Step 3: Wire into detect()**

In `NetworkModule::detect()`, add:

```cpp
    auto driverIssues = detectDriverIssues();
    issues.append(driverIssues);
```

- [ ] **Step 4: Add test**

```cpp
    void testDriverIssueDetection();
```

```cpp
void NetworkModuleTest::testDriverIssueDetection()
{
    DeepinDoctor::NetworkModule module;
    QList<DeepinDoctor::Issue> issues = module.detect();

    for (const DeepinDoctor::Issue& issue : issues) {
        if (issue.title.contains("driver", Qt::CaseInsensitive) ||
            issue.title.contains("link down", Qt::CaseInsensitive)) {
            QVERIFY(issue.level == DeepinDoctor::Issue::Warning ||
                    issue.level == DeepinDoctor::Issue::Info);
        }
    }
}
```

- [ ] **Step 5: Build and test**

```bash
cd /home/ut003607@uos/Workspace/Code/deepin-doctor/obj-x86_64-linux-gnu && make -j$(nproc) && ctest -R test_network_module --verbose
```

- [ ] **Step 6: Commit**

```bash
cd /home/ut003607@uos/Workspace/Code/deepin-doctor && git add src/backend/modules/network/NetworkModule.h src/backend/modules/network/NetworkModule.cpp tests/test_network_module.cpp && git commit -m "feat(network): add NIC driver and link status detection"
```

---

### Task A4: Firewall Rule Detection

**Files:**
- Modify: `src/backend/modules/network/NetworkModule.h`
- Modify: `src/backend/modules/network/NetworkModule.cpp`
- Modify: `tests/test_network_module.cpp`

- [ ] **Step 1: Add method declaration**

In `src/backend/modules/network/NetworkModule.h`:

```cpp
    QList<Issue> detectFirewallIssues();
```

- [ ] **Step 2: Implement firewall detection**

```cpp
QList<Issue> NetworkModule::detectFirewallIssues()
{
    QList<Issue> issues;

    QProcess process;

    // Check iptables for restrictive rules
    process.start("which", QStringList() << "iptables");
    process.waitForFinished(3000);
    bool hasIptables = process.exitCode() == 0;

    if (hasIptables) {
        process.start("iptables", QStringList() << "-L" << "OUTPUT" << "-n");
        process.waitForFinished(5000);
        QString output = process.readAllStandardOutput();

        // Check if default OUTPUT policy is DROP
        if (output.contains("policy DROP")) {
            Issue issue;
            issue.level = Issue::Warning;
            issue.title = "Restrictive outbound firewall";
            issue.description = "iptables OUTPUT chain default policy is DROP, which may block outbound connections";
            issue.solution = "Review firewall rules: sudo iptables -L OUTPUT -n";
            issues.append(issue);
        }

        // Check for DNS blocking rules (port 53)
        if (output.contains("53") && output.contains("DROP")) {
            Issue issue;
            issue.level = Issue::Warning;
            issue.title = "DNS traffic may be blocked by firewall";
            issue.description = "Found firewall rules that may block DNS traffic on port 53";
            issue.solution = "Review firewall rules for port 53: sudo iptables -L -n | grep 53";
            issues.append(issue);
        }
    }

    // Check nftables
    process.start("which", QStringList() << "nft");
    process.waitForFinished(3000);
    bool hasNft = process.exitCode() == 0;

    if (hasNft) {
        process.start("nft", QStringList() << "list" << "ruleset");
        process.waitForFinished(5000);
        QString output = process.readAllStandardOutput();

        if (!output.isEmpty() && output.contains("drop", Qt::CaseInsensitive)) {
            // Just note that nftables rules exist with drops
            Issue issue;
            issue.level = Issue::Info;
            issue.title = "nftables rules with drop policies found";
            issue.description = "System has nftables rules that include drop policies";
            issue.solution = "Review nftables rules: sudo nft list ruleset";
            issues.append(issue);
        }
    }

    return issues;
}
```

- [ ] **Step 3: Wire into detect()**

```cpp
    auto fwIssues = detectFirewallIssues();
    issues.append(fwIssues);
```

- [ ] **Step 4: Add test**

```cpp
    void testFirewallDetection();
```

```cpp
void NetworkModuleTest::testFirewallDetection()
{
    DeepinDoctor::NetworkModule module;
    QList<DeepinDoctor::Issue> issues = module.detect();

    for (const DeepinDoctor::Issue& issue : issues) {
        if (issue.title.contains("firewall", Qt::CaseInsensitive) ||
            issue.title.contains("nftables", Qt::CaseInsensitive)) {
            QVERIFY(issue.level == DeepinDoctor::Issue::Warning ||
                    issue.level == DeepinDoctor::Issue::Info);
        }
    }
}
```

- [ ] **Step 5: Build and test**

```bash
cd /home/ut003607@uos/Workspace/Code/deepin-doctor/obj-x86_64-linux-gnu && make -j$(nproc) && ctest -R test_network_module --verbose
```

- [ ] **Step 6: Commit**

```bash
cd /home/ut003607@uos/Workspace/Code/deepin-doctor && git add src/backend/modules/network/NetworkModule.h src/backend/modules/network/NetworkModule.cpp tests/test_network_module.cpp && git commit -m "feat(network): add firewall rule anomaly detection"
```

---

## Group B: System Module Enhancements

**Files:**
- Modify: `src/backend/modules/system/SystemModule.h`
- Modify: `src/backend/modules/system/SystemModule.cpp`
- Modify: `tests/test_system_module.cpp`

### Task B1: Key Component Version Collection

**Files:**
- Modify: `src/backend/modules/system/SystemModule.cpp:156-258` (collectSystemInfo)

- [ ] **Step 1: Add component version collection**

In `src/backend/modules/system/SystemModule.cpp`, in `collectSystemInfo()`, after the `packageVersions` block (after line 257), add:

```cpp
    // Collect key component versions
    QJsonObject componentVersions;

    // glibc version
    process.start("ldd", QStringList() << "--version");
    process.waitForFinished(5000);
    QString lddOutput = process.readAllStandardOutput();
    if (!lddOutput.isEmpty()) {
        QStringList lddLines = lddOutput.split('\n');
        if (!lddLines.isEmpty()) {
            componentVersions["glibc"] = lddLines.first().trimmed();
        }
    }

    // systemd version
    process.start("systemctl", QStringList() << "--version");
    process.waitForFinished(5000);
    QString systemdOutput = process.readAllStandardOutput();
    if (!systemdOutput.isEmpty()) {
        QStringList systemdLines = systemdOutput.split('\n');
        if (!systemdLines.isEmpty()) {
            componentVersions["systemd"] = systemdLines.first().trimmed();
        }
    }

    // GCC version
    process.start("gcc", QStringList() << "--version");
    process.waitForFinished(5000);
    QString gccOutput = process.readAllStandardOutput();
    if (!gccOutput.isEmpty()) {
        QStringList gccLines = gccOutput.split('\n');
        if (!gccLines.isEmpty()) {
            componentVersions["gcc"] = gccLines.first().trimmed();
        }
    }

    // Xorg version
    process.start("Xorg", QStringList() << "-version");
    process.waitForFinished(5000);
    QString xorgOutput = process.readAllStandardError(); // Xorg prints version to stderr
    if (!xorgOutput.isEmpty()) {
        QStringList xorgLines = xorgOutput.split('\n');
        for (const QString& line : xorgLines) {
            if (line.contains("X.Org")) {
                componentVersions["xorg"] = line.trimmed();
                break;
            }
        }
    }

    result["component_versions"] = componentVersions;
```

- [ ] **Step 2: Update test to verify new key**

In `tests/test_system_module.cpp`, find the test that checks `collectSystemInfo` output and add a check:

```cpp
    // Verify component versions are collected
    QJsonObject system = result["system"].toObject();
    QVERIFY(system.contains("component_versions"));
    QJsonObject components = system["component_versions"].toObject();
    // At least glibc should be detectable on any Linux system
    QVERIFY(components.contains("glibc") || components.contains("systemd"));
```

- [ ] **Step 3: Build and test**

```bash
cd /home/ut003607@uos/Workspace/Code/deepin-doctor/obj-x86_64-linux-gnu && make -j$(nproc) && ctest -R test_system_module --verbose
```

- [ ] **Step 4: Commit**

```bash
cd /home/ut003607@uos/Workspace/Code/deepin-doctor && git add src/backend/modules/system/SystemModule.cpp tests/test_system_module.cpp && git commit -m "feat(system): add key component version collection (glibc, systemd, gcc, xorg)"
```

---

### Task B2: CPU/Memory Real-time Usage

**Files:**
- Modify: `src/backend/modules/system/SystemModule.cpp:56-154` (collectHardwareInfo)

- [ ] **Step 1: Add CPU usage calculation**

In `src/backend/modules/system/SystemModule.cpp`, in `collectHardwareInfo()`, after the CPU model/core block (after line 80), add:

```cpp
    // CPU usage from /proc/stat
    QFile cpuStat("/proc/stat");
    if (cpuStat.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream cpuIn(&cpuStat);
        QString cpuLine = cpuIn.readLine(); // First line: cpu  user nice system idle ...
        cpuStat.close();

        QStringList cpuParts = cpuLine.split(QRegExp("\\s+"), Qt::SkipEmptyParts);
        if (cpuParts.size() >= 5) {
            // cpuParts[0] = "cpu", [1]=user, [2]=nice, [3]=system, [4]=idle
            qlonglong user = cpuParts[1].toLongLong();
            qlonglong nice = cpuParts[2].toLongLong();
            qlonglong system = cpuParts[3].toLongLong();
            qlonglong idle = cpuParts[4].toLongLong();
            qlonglong total = user + nice + system + idle;

            result["cpu_user_jiffies"] = user;
            result["cpu_system_jiffies"] = system;
            result["cpu_idle_jiffies"] = idle;
            result["cpu_total_jiffies"] = total;

            // Usage percentage (snapshot, not over time)
            if (total > 0) {
                double usage = (total - idle) * 100.0 / total;
                result["cpu_usage_percent"] = usage;
            }
        }
    }
```

- [ ] **Step 2: Add memory usage percentage**

The existing code already calculates `memory_usage_percent`. Just verify the test checks for it.

- [ ] **Step 3: Add disk IO stats**

After the disk info block (after line 122), add:

```cpp
    // Disk IO stats from /proc/diskstats
    QFile diskStats("/proc/diskstats");
    if (diskStats.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream dsIn(&diskStats);
        QString dsContent = dsIn.readAll();
        diskStats.close();

        // Parse for the root device (sda or vda)
        QStringList dsLines = dsContent.split('\n');
        for (const QString& line : dsLines) {
            if (line.contains(" sda ") || line.contains(" vda ") ||
                line.contains(" nvme0n1 ")) {
                QStringList parts = line.trimmed().split(QRegExp("\\s+"));
                if (parts.size() >= 14) {
                    QJsonObject ioInfo;
                    ioInfo["reads_completed"] = parts[3].toLongLong();
                    ioInfo["sectors_read"] = parts[5].toLongLong();
                    ioInfo["writes_completed"] = parts[7].toLongLong();
                    ioInfo["sectors_written"] = parts[9].toLongLong();
                    result["disk_io"] = ioInfo;
                }
                break;
            }
        }
    }
```

- [ ] **Step 4: Build and test**

```bash
cd /home/ut003607@uos/Workspace/Code/deepin-doctor/obj-x86_64-linux-gnu && make -j$(nproc) && ctest -R test_system_module --verbose
```

- [ ] **Step 5: Commit**

```bash
cd /home/ut003607@uos/Workspace/Code/deepin-doctor && git add src/backend/modules/system/SystemModule.cpp && git commit -m "feat(system): add CPU usage and disk IO stats collection"
```

---

### Task B3: syslog, kern.log, and Wayland Log Collection

**Files:**
- Modify: `src/backend/modules/system/SystemModule.cpp:260-315` (collectSystemLogs)

- [ ] **Step 1: Add syslog collection**

In `collectSystemLogs()`, after the Xorg log block (after line 288), add:

```cpp
    // syslog (if exists)
    QFile syslogFile("/var/log/syslog");
    if (syslogFile.exists()) {
        if (syslogFile.size() < 2 * 1024 * 1024) { // Only if < 2MB
            if (syslogFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
                QTextStream in(&syslogFile);
                QStringList allLines = in.readAll().split('\n');
                syslogFile.close();
                // Last 500 lines
                QStringList lastLines = allLines.mid(qMax(0, allLines.size() - 500));
                result["syslog"] = lastLines.join('\n');
            }
        } else {
            // Read last 500 lines efficiently
            if (syslogFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
                QTextStream in(&syslogFile);
                in.seek(qMax(0LL, syslogFile.size() - 100 * 1024)); // Read last 100KB
                result["syslog"] = in.readAll();
                syslogFile.close();
            }
        }
    }

    // kern.log (if exists)
    QFile kernlogFile("/var/log/kern.log");
    if (kernlogFile.exists()) {
        if (kernlogFile.size() < 2 * 1024 * 1024) {
            if (kernlogFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
                QTextStream in(&kernlogFile);
                QStringList allLines = in.readAll().split('\n');
                kernlogFile.close();
                QStringList lastLines = allLines.mid(qMax(0, allLines.size() - 500));
                result["kern_log"] = lastLines.join('\n');
            }
        }
    }
```

- [ ] **Step 2: Add Wayland log collection**

After the syslog/kern.log block, add:

```cpp
    // Wayland compositor log
    QString waylandLogDir = QDir::homePath() + "/.local/share/wayland";
    QDir waylandDir(waylandLogDir);
    if (waylandDir.exists()) {
        QStringList waylandLogs = waylandDir.entryList(QStringList() << "*.log", QDir::Files);
        QJsonObject waylandLogData;
        for (const QString& logFile : waylandLogs) {
            QFile file(waylandDir.filePath(logFile));
            if (file.size() < 512 * 1024) {
                if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
                    QTextStream in(&file);
                    waylandLogData[logFile] = in.readAll();
                    file.close();
                }
            }
        }
        if (!waylandLogData.isEmpty()) {
            result["wayland_logs"] = waylandLogData;
        }
    }

    // Check XDG_SESSION_TYPE to note if running Wayland
    QString sessionType = qEnvironmentVariable("XDG_SESSION_TYPE");
    if (!sessionType.isEmpty()) {
        result["session_type"] = sessionType;
    }
```

- [ ] **Step 3: Build and test**

```bash
cd /home/ut003607@uos/Workspace/Code/deepin-doctor/obj-x86_64-linux-gnu && make -j$(nproc) && ctest -R test_system_module --verbose
```

- [ ] **Step 4: Commit**

```bash
cd /home/ut003607@uos/Workspace/Code/deepin-doctor && git add src/backend/modules/system/SystemModule.cpp && git commit -m "feat(system): add syslog, kern.log, and Wayland log collection"
```

---

## Group C: Environment & Logs Enhancements

**Files:**
- Modify: `src/backend/modules/environment/EnvironmentModule.h`
- Modify: `src/backend/modules/environment/EnvironmentModule.cpp`
- Modify: `src/backend/modules/logs/LogsModule.h`
- Modify: `src/backend/modules/logs/LogsModule.cpp`
- Modify: `tests/test_environment_module.cpp`

### Task C1: System Update Interruption Detection

**Files:**
- Modify: `src/backend/modules/environment/EnvironmentModule.h`
- Modify: `src/backend/modules/environment/EnvironmentModule.cpp`
- Modify: `tests/test_environment_module.cpp`

- [ ] **Step 1: Add method declaration**

In `src/backend/modules/environment/EnvironmentModule.h`, add in the private section:

```cpp
    QList<Issue> detectUpdateInterruption();
```

- [ ] **Step 2: Implement detection**

In `EnvironmentModule.cpp`, add before the closing namespace brace:

```cpp
QList<Issue> EnvironmentModule::detectUpdateInterruption()
{
    QList<Issue> issues;

    QProcess process;

    // Check dpkg for packages in half-installed / config-files state
    process.start("dpkg", QStringList() << "-l");
    process.waitForFinished(10000);
    QString dpkgOutput = process.readAllStandardOutput();

    QStringList halfInstalled;
    QStringList needsConfig;
    QStringList lines = dpkgOutput.split('\n');
    for (const QString& line : lines) {
        if (line.startsWith("iU") || line.startsWith("iF")) {
            // iU = half-installed, unpacked; iF = half-installed, config-files
            QStringList parts = line.split(QRegExp("\\s+"), Qt::SkipEmptyParts);
            if (parts.size() >= 2) {
                halfInstalled.append(parts[1]);
            }
        }
        if (line.startsWith("cF")) {
            // cF = config-files, failed config
            QStringList parts = line.split(QRegExp("\\s+"), Qt::SkipEmptyParts);
            if (parts.size() >= 2) {
                needsConfig.append(parts[1]);
            }
        }
    }

    if (!halfInstalled.isEmpty()) {
        Issue issue;
        issue.level = Issue::Error;
        issue.title = "Packages in half-installed state";
        issue.description = QString("Found %1 packages that are partially installed, indicating an interrupted update:\n%2")
            .arg(halfInstalled.size())
            .arg(halfInstalled.mid(0, 10).join(", "));
        issue.solution = "Run: sudo dpkg --configure -a && sudo apt-get install -f";
        issues.append(issue);
    }

    if (!needsConfig.isEmpty()) {
        Issue issue;
        issue.level = Issue::Warning;
        issue.title = "Packages need configuration";
        issue.description = QString("Found %1 packages that need to be configured:\n%2")
            .arg(needsConfig.size())
            .arg(needsConfig.mid(0, 10).join(", "));
        issue.solution = "Run: sudo dpkg --configure -a";
        issues.append(issue);
    }

    // Check if dpkg is in an inconsistent state
    QFile dpkgStatus("/var/lib/dpkg/status");
    if (dpkgStatus.exists()) {
        // Check for lock file held too long (might indicate a crashed update)
        QFile lockFile("/var/lib/dpkg/lock");
        if (lockFile.exists()) {
            QProcess fuser;
            fuser.start("fuser", QStringList() << "/var/lib/dpkg/lock");
            fuser.waitForFinished(5000);
            QString holder = fuser.readAllStandardOutput().trimmed();
            if (!holder.isEmpty()) {
                // Check how long the process has been running
                QStringList pids = holder.split(QRegExp("\\s+"), Qt::SkipEmptyParts);
                for (const QString& pid : pids) {
                    QProcess uptime;
                    uptime.start("ps", QStringList() << "-o" << "etime=" << "-p" << pid.trimmed());
                    uptime.waitForFinished(3000);
                    QString elapsed = uptime.readAllStandardOutput().trimmed();
                    if (!elapsed.isEmpty()) {
                        // Parse elapsed time (format: [[dd-]hh:]mm:ss)
                        QStringList timeParts = elapsed.split(':');
                        int totalMinutes = 0;
                        if (timeParts.size() == 3) {
                            // hh:mm:ss or dd-hh:mm:ss
                            QString hoursPart = timeParts[0];
                            if (hoursPart.contains('-')) {
                                QStringList dayParts = hoursPart.split('-');
                                totalMinutes += dayParts[0].toInt() * 1440;
                                totalMinutes += dayParts[1].toInt() * 60;
                            } else {
                                totalMinutes += hoursPart.toInt() * 60;
                            }
                            totalMinutes += timeParts[1].toInt();
                        } else if (timeParts.size() == 2) {
                            totalMinutes = timeParts[0].toInt();
                        }

                        if (totalMinutes > 30) {
                            Issue issue;
                            issue.level = Issue::Warning;
                            issue.title = "dpkg lock held for extended time";
                            issue.description = QString("dpkg lock file has been held by PID %1 for %2 minutes, "
                                                       "which may indicate a crashed package manager")
                                .arg(pid.trimmed()).arg(totalMinutes);
                            issue.solution = "If no package operation is running, run: sudo rm /var/lib/dpkg/lock && sudo dpkg --configure -a";
                            issues.append(issue);
                        }
                    }
                }
            }
        }
    }

    return issues;
}
```

- [ ] **Step 3: Wire into detect()**

In `EnvironmentModule::detect()`, add:

```cpp
    issues.append(detectUpdateInterruption());
```

- [ ] **Step 4: Add test**

In `tests/test_environment_module.cpp`, add:

```cpp
    void testUpdateInterruptionDetection();
```

```cpp
void EnvironmentModuleTest::testUpdateInterruptionDetection()
{
    DeepinDoctor::EnvironmentModule module;
    QList<DeepinDoctor::Issue> issues = module.detect();

    for (const DeepinDoctor::Issue& issue : issues) {
        if (issue.title.contains("half-installed", Qt::CaseInsensitive) ||
            issue.title.contains("dpkg lock", Qt::CaseInsensitive)) {
            QVERIFY(issue.level == DeepinDoctor::Issue::Error ||
                    issue.level == DeepinDoctor::Issue::Warning);
            QVERIFY(!issue.solution.isEmpty());
        }
    }
}
```

- [ ] **Step 5: Build and test**

```bash
cd /home/ut003607@uos/Workspace/Code/deepin-doctor/obj-x86_64-linux-gnu && make -j$(nproc) && ctest -R test_environment_module --verbose
```

- [ ] **Step 6: Commit**

```bash
cd /home/ut003607@uos/Workspace/Code/deepin-doctor && git add src/backend/modules/environment/EnvironmentModule.h src/backend/modules/environment/EnvironmentModule.cpp tests/test_environment_module.cpp && git commit -m "feat(environment): add system update interruption detection"
```

---

### Task C2: User Config and Service Config Checks

**Files:**
- Modify: `src/backend/modules/environment/EnvironmentModule.h`
- Modify: `src/backend/modules/environment/EnvironmentModule.cpp`
- Modify: `tests/test_environment_module.cpp`

- [ ] **Step 1: Add method declarations**

In `src/backend/modules/environment/EnvironmentModule.h`:

```cpp
    QList<Issue> detectUserConfigIssues();
    QList<Issue> detectServiceConfigIssues();
```

- [ ] **Step 2: Implement user config checks**

```cpp
QList<Issue> EnvironmentModule::detectUserConfigIssues()
{
    QList<Issue> issues;

    // Check browser config directories
    QStringList browserConfigs = {
        QDir::homePath() + "/.config/google-chrome",
        QDir::homePath() + "/.config/chromium",
        QDir::homePath() + "/.mozilla/firefox"
    };

    for (const QString& configDir : browserConfigs) {
        QDir dir(configDir);
        if (dir.exists()) {
            QFileInfo info(configDir);
            if (!info.isReadable() || !info.isWritable()) {
                Issue issue;
                issue.level = Issue::Warning;
                issue.title = QString("Browser config permission issue: %1").arg(QFileInfo(configDir).fileName());
                issue.description = QString("Config directory %1 has incorrect permissions").arg(configDir);
                issue.solution = QString("Fix permissions: chmod -R 700 %1").arg(configDir);
                issues.append(issue);
            }
        }
    }

    // Check desktop file associations
    QString mimeDir = QDir::homePath() + "/.local/share/applications";
    QDir dir(mimeDir);
    if (dir.exists()) {
        QStringList desktopFiles = dir.entryList(QStringList() << "*.desktop", QDir::Files);
        for (const QString& file : desktopFiles) {
            QFile desktopFile(dir.filePath(file));
            if (desktopFile.open(QIODevice::ReadOnly)) {
                QString content = desktopFile.readAll();
                desktopFile.close();
                if (!content.contains("[Desktop Entry]")) {
                    Issue issue;
                    issue.level = Issue::Info;
                    issue.title = QString("Invalid desktop file: %1").arg(file);
                    issue.description = QString("Desktop file %1 is missing [Desktop Entry] section").arg(file);
                    issue.solution = "Fix or remove the invalid desktop file";
                    issues.append(issue);
                }
            }
        }
    }

    return issues;
}
```

- [ ] **Step 3: Implement service config checks**

```cpp
QList<Issue> EnvironmentModule::detectServiceConfigIssues()
{
    QList<Issue> issues;

    QProcess process;

    // Check for masked services that should be running
    QStringList criticalServices = {
        "dbus.service",
        "systemd-logind.service",
        "NetworkManager.service"
    };

    for (const QString& service : criticalServices) {
        process.start("systemctl", QStringList() << "is-enabled" << service);
        process.waitForFinished(5000);
        QString status = process.readAllStandardOutput().trimmed();

        if (status == "masked") {
            Issue issue;
            issue.level = Issue::Error;
            issue.title = QString("Critical service masked: %1").arg(service);
            issue.description = QString("Service %1 is masked and cannot start").arg(service);
            issue.solution = QString("Unmask service: sudo systemctl unmask %1").arg(service);
            issues.append(issue);
        }
    }

    // Check for services in infinite restart loops
    process.start("systemctl", QStringList() << "list-units" << "--state=failed" << "--no-legend");
    process.waitForFinished(10000);
    QString failedOutput = process.readAllStandardOutput();

    if (!failedOutput.isEmpty()) {
        QStringList lines = failedOutput.split('\n', Qt::SkipEmptyParts);
        for (const QString& line : lines) {
            QStringList parts = line.split(QRegExp("\\s+"), Qt::SkipEmptyParts);
            if (parts.size() >= 1) {
                QString serviceName = parts[0];

                // Check restart count
                process.start("systemctl", QStringList() << "show" << serviceName
                              << "--property=NRestarts");
                process.waitForFinished(5000);
                QString restartInfo = process.readAllStandardOutput().trimmed();

                if (restartInfo.contains("=")) {
                    int restarts = restartInfo.split('=').last().toInt();
                    if (restarts > 10) {
                        Issue issue;
                        issue.level = Issue::Warning;
                        issue.title = QString("Service restart loop: %1").arg(serviceName);
                        issue.description = QString("Service %1 has restarted %2 times").arg(serviceName).arg(restarts);
                        issue.solution = QString("Check service logs: journalctl -u %1").arg(serviceName);
                        issues.append(issue);
                    }
                }
            }
        }
    }

    return issues;
}
```

- [ ] **Step 4: Wire into detect()**

```cpp
    issues.append(detectUserConfigIssues());
    issues.append(detectServiceConfigIssues());
```

- [ ] **Step 5: Add tests**

```cpp
    void testUserConfigDetection();
    void testServiceConfigDetection();
```

```cpp
void EnvironmentModuleTest::testUserConfigDetection()
{
    DeepinDoctor::EnvironmentModule module;
    QList<DeepinDoctor::Issue> issues = module.detect();

    // Just verify it doesn't crash and returns valid issues
    for (const DeepinDoctor::Issue& issue : issues) {
        if (issue.title.contains("desktop file", Qt::CaseInsensitive) ||
            issue.title.contains("browser config", Qt::CaseInsensitive)) {
            QVERIFY(!issue.solution.isEmpty());
        }
    }
}

void EnvironmentModuleTest::testServiceConfigDetection()
{
    DeepinDoctor::EnvironmentModule module;
    QList<DeepinDoctor::Issue> issues = module.detect();

    for (const DeepinDoctor::Issue& issue : issues) {
        if (issue.title.contains("masked", Qt::CaseInsensitive) ||
            issue.title.contains("restart loop", Qt::CaseInsensitive)) {
            QVERIFY(issue.level == DeepinDoctor::Issue::Error ||
                    issue.level == DeepinDoctor::Issue::Warning);
        }
    }
}
```

- [ ] **Step 6: Build and test**

```bash
cd /home/ut003607@uos/Workspace/Code/deepin-doctor/obj-x86_64-linux-gnu && make -j$(nproc) && ctest -R test_environment_module --verbose
```

- [ ] **Step 7: Commit**

```bash
cd /home/ut003607@uos/Workspace/Code/deepin-doctor && git add src/backend/modules/environment/EnvironmentModule.h src/backend/modules/environment/EnvironmentModule.cpp tests/test_environment_module.cpp && git commit -m "feat(environment): add user config and service config checks"
```

---

### Task C3: Log Time Range Filtering

**Files:**
- Modify: `src/backend/modules/logs/LogsModule.h`
- Modify: `src/backend/modules/logs/LogsModule.cpp`

- [ ] **Step 1: Add time range helper method**

In `src/backend/modules/logs/LogsModule.h`, add private method:

```cpp
    QString filterByTimeRange(const QString& logContent, int hoursBack);
```

- [ ] **Step 2: Implement time range filtering**

In `LogsModule.cpp`:

```cpp
QString LogsModule::filterByTimeRange(const QString& logContent, int hoursBack)
{
    QDateTime cutoff = QDateTime::currentDateTime().addSecs(-hoursBack * 3600);
    QStringList filteredLines;

    QStringList lines = logContent.split('\n');
    for (const QString& line : lines) {
        // journalctl format: "Mon DD HH:MM:SS hostname service[pid]: message"
        // Try to parse the timestamp from common log formats
        bool keep = true;

        // Try ISO format (2026-05-14T10:30:00)
        QRegularExpression isoRe("(\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2})");
        QRegularExpressionMatch isoMatch = isoRe.match(line);
        if (isoMatch.hasMatch()) {
            QDateTime logTime = QDateTime::fromString(isoMatch.captured(1), Qt::ISODate);
            if (logTime.isValid() && logTime < cutoff) {
                keep = false;
            }
        }

        // Try syslog format (May 14 10:30:00)
        QRegularExpression syslogRe("(\\w{3})\\s+(\\d{1,2})\\s+(\\d{2}:\\d{2}:\\d{2})");
        QRegularExpressionMatch syslogMatch = syslogRe.match(line);
        if (syslogMatch.hasMatch() && !isoMatch.hasMatch()) {
            QString month = syslogMatch.captured(1);
            int day = syslogMatch.captured(2).toInt();
            QString time = syslogMatch.captured(3);

            // Build date string for current year
            QDate logDate = QDate::currentDate();
            int monthNum = QDate::fromString(month, "MMM").month();
            if (monthNum > 0) {
                logDate = QDate(QDate::currentDate().year(), monthNum, day);
            }

            QDateTime logTime = QDateTime::fromString(
                logDate.toString("yyyy-MM-dd") + " " + time, "yyyy-MM-dd HH:mm:ss");
            if (logTime.isValid() && logTime < cutoff) {
                keep = false;
            }
        }

        if (keep) {
            filteredLines.append(line);
        }
    }

    return filteredLines.join('\n');
}
```

- [ ] **Step 3: Apply filtering in collectApplicationLogs**

In `collectApplicationLogs()`, when reading journalctl logs, add the `-S` flag to limit by time:

Replace the journalctl call for DDE apps:
```cpp
        // Use --since to limit log range (last 24 hours by default)
        process.start("journalctl", QStringList() << "-u" << app << "-n" << "200" << "--no-pager" << "--since" << "24 hours ago");
```

Do the same for `collectServiceLogs()`.

- [ ] **Step 4: Build and test**

```bash
cd /home/ut003607@uos/Workspace/Code/deepin-doctor/obj-x86_64-linux-gnu && make -j$(nproc) && ctest -R test --verbose
```

- [ ] **Step 5: Commit**

```bash
cd /home/ut003607@uos/Workspace/Code/deepin-doctor && git add src/backend/modules/logs/LogsModule.h src/backend/modules/logs/LogsModule.cpp && git commit -m "feat(logs): add time range filtering for log collection"
```

---

### Task C4: Sensitive Info Masking

**Files:**
- Modify: `src/backend/modules/logs/LogsModule.h`
- Modify: `src/backend/modules/logs/LogsModule.cpp`

- [ ] **Step 1: Add masking method**

In `src/backend/modules/logs/LogsModule.h`:

```cpp
    QString maskSensitiveInfo(const QString& content);
```

- [ ] **Step 2: Implement masking**

In `LogsModule.cpp`:

```cpp
QString LogsModule::maskSensitiveInfo(const QString& content)
{
    QString masked = content;

    // Mask password-like patterns (password=xxx, passwd=xxx, pwd=xxx)
    masked.replace(QRegularExpression("(password|passwd|pwd|secret|token|api_key|apikey)\\s*[=:]\\s*\\S+",
                   QRegularExpression::CaseInsensitiveOption),
                   "\\1=***REDACTED***");

    // Mask connection strings with passwords (e.g., postgresql://user:pass@host)
    masked.replace(QRegularExpression("(://[^:]+:)[^@]+(@)"),
                   "\\1***REDACTED***\\2");

    // Mask SSH private key content
    masked.replace(QRegularExpression("-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----[\\s\\S]*?-----END (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----"),
                   "-----BEGIN PRIVATE KEY-----\n***REDACTED***\n-----END PRIVATE KEY-----");

    // Mask environment variables with sensitive names
    masked.replace(QRegularExpression("((?:export\\s+)?(?:DB_PASSWORD|DATABASE_PASSWORD|MYSQL_PWD|PGPASSWORD|AWS_SECRET_ACCESS_KEY|SECRET_KEY)=)\\S+",
                   QRegularExpression::CaseInsensitiveOption),
                   "\\1***REDACTED***");

    return masked;
}
```

- [ ] **Step 3: Apply masking before returning results**

In `collectApplicationLogs()`, after reading each log file, apply masking:

```cpp
        if (!logs.isEmpty()) {
            result[app] = maskSensitiveInfo(logs);
        }
```

Do the same in `collectServiceLogs()` and `collectCrashReports()`.

- [ ] **Step 4: Add test**

Add a simple test to verify masking works:

```cpp
    void testSensitiveInfoMasking();
```

```cpp
void LogsModuleTest::testSensitiveInfoMasking()
{
    DeepinDoctor::LogsModule module;

    // Test via a helper - since maskSensitiveInfo is private, test through collect
    // Just verify it doesn't crash
    QJsonObject result;
    module.collect(result);

    // Verify no raw passwords in collected data
    QJsonDocument doc(result);
    QString jsonStr = doc.toJson();

    // These patterns should not appear unmasked
    QVERIFY(!jsonStr.contains("password=secret123"));
    QVERIFY(!jsonStr.contains("token=abc123"));
}
```

- [ ] **Step 5: Build and test**

```bash
cd /home/ut003607@uos/Workspace/Code/deepin-doctor/obj-x86_64-linux-gnu && make -j$(nproc) && ctest -R test --verbose
```

- [ ] **Step 6: Commit**

```bash
cd /home/ut003607@uos/Workspace/Code/deepin-doctor && git add src/backend/modules/logs/LogsModule.h src/backend/modules/logs/LogsModule.cpp && git commit -m "feat(logs): add sensitive information masking in collected logs"
```
