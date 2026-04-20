# deepin-doctor

系统诊断工具 - 用于现场工作人员一键收集设备信息、日志、系统状态

## 架构

- **Frontend**: QML界面，通过DBus调用后端服务
- **Backend**: DBus守护进程，管理模块和插件
- **Modules**: 内置模块(network, system, environment, logs)
- **Plugins**: 可扩展插件系统

## 依赖

- Qt5 或 Qt6 (自动检测)
- Qt模块: Core, DBus, Quick, QuickControls2, Concurrent, Network

## 构建

```bash
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr ..
make -j$(nproc)
```

## 运行

### 方式1: 直接运行

```bash
# 启动后端服务
./build/deepin-doctor-daemon

# 启动前端界面 (另一个终端)
./build/deepin-doctor
```

### 方式2: DBus测试

```bash
# 启动daemon
./build/deepin-doctor-daemon &

# 列出可用模块
gdbus call --session --dest com.deepin.Doctor --object-path /com/deepin/Doctor --method com.deepin.Doctor.ListModules

# 收集所有模块信息
gdbus call --session --dest com.deepin.Doctor --object-path /com/deepin/Doctor --method com.deepin.Doctor.Collect "['network', 'system', 'environment', 'logs']"

# 检测问题
gdbus call --session --dest com.deepin.Doctor --object-path /com/deepin/Doctor --method com.deepin.Doctor.Detect "['network', 'environment']"
```

### 方式3: 使用测试脚本

```bash
chmod +x test-dbus.sh
./test-dbus.sh
```

## 安装

```bash
sudo make install
```

## 已实现功能

### Network模块 ✅
- ✅ 网络接口状态收集(ip addr, ip route)
- ✅ 网络配置信息(DNS、路由)
- ✅ NetworkManager/wpa_supplicant日志(journalctl)
- ✅ 内核网络日志(dmesg)
- ✅ DNS配置问题检测
- ✅ 网关连通性测试(ping)
- ✅ DDE网络插件缺失检测(/usr/lib/dde-dock/plugins, /usr/lib/dde-control-center/modules)

### System模块 ✅
- ✅ CPU信息(型号、核心数)
- ✅ 内存信息(总量、使用率、交换分区)
- ✅ 磁盘信息(使用率)
- ✅ GPU设备信息(lspci)
- ✅ 网卡设备信息(lspci)
- ✅ 系统版本信息(/etc/os-release, /etc/lsb-release)
- ✅ 内核版本(uname)
- ✅ 系统启动时间(/proc/uptime)
- ✅ 桌面环境检测(ps)
- ✅ 关键软件包版本(dpkg)
- ✅ 系统日志(journalctl, dmesg)
- ✅ X11日志(/var/log/Xorg.0.log)
- ✅ DDE日志(~/.cache/deepin/*.log)

### Environment模块 ✅
- ✅ 包完整性检查(dpkg -C, dpkg --audit)
- ✅ 锁文件检测(/var/lib/dpkg/lock*)
- ✅ 关键库文件检查(ldconfig)
- ✅ 环境变量收集(PATH, LD_LIBRARY_PATH等)
- ✅ 配置目录检查(/etc, ~/.config)
- ✅ 必需包缺失检测(dde-desktop, dde-daemon等)
- ✅ 破损包检测(dpkg -C)
- ✅ 磁盘空间不足检测(df -h, >90%)
- ✅ 权限问题检测(~/.config权限)

### Logs模块 ✅
- ✅ DDE应用日志(journalctl -u dde-*)
- ✅ Deepin缓存日志(~/.cache/deepin/*.log)
- ✅ 用户应用日志(~/.local/share/*)
- ✅ 系统服务日志(journalctl -u systemd, dbus, NetworkManager等)
- ✅ 崩溃报告(/var/crash/*.crash)
- ✅ Core dump列表(coredumpctl list)
- ✅ Sentry报告(~/.local/share/sentry)
- ✅ 多次崩溃警告(>5个crash文件)

### 导出功能 ✅
- ✅ JSON格式导出(manifest.json + 模块数据)
- ✅ 日志文件单独保存
- ✅ tar.gz压缩包打包
- ✅ 目录结构清晰

## 导出格式

```
export_YYYYMMDD_HHMMSS.tar.gz
├── manifest.json           # 收集清单(时间戳、版本、模块列表)
├── network/
│   ├── network.json        # 网络模块收集结果
│   └── logs/              # 网络日志
│       ├── networkmanager_journal.txt
│       └── dmesg_network.txt
├── system/
│   ├── system.json
│   └── logs/
│       ├── journal_system.txt
│       ├── dmesg.txt
│       └── xorg_log.txt
├── environment/
│   └── environment.json
└── logs/
    ├── logs.json
    └── logs/
        ├── dde-desktop.txt
        └── dde-dock.txt
```

## 开发

### 添加新模块

1. 在 `src/backend/modules/` 创建新模块目录
2. 实现 `ModuleInterface` 接口
3. 在 `src/backend/main.cpp` 注册模块
4. 更新 `CMakeLists.txt`

示例:

```cpp
// MyModule.h
class MyModule : public ModuleInterface {
public:
    QString name() const override { return "mymodule"; }
    void collect(QJsonObject& result) override;
    QList<Issue> detect() override;
    // ...
};
```

### 开发插件

参考 `src/plugins/example/` 示例

```cpp
// MyPlugin.h
class MyPlugin : public PluginInterface {
public:
    QString id() const override { return "my-plugin"; }
    ModuleInterface* createModule() override {
        return new MyModule();
    }
};
```

## API文档

### DBus接口

**服务名**: `com.deepin.Doctor`
**对象路径**: `/com/deepin/Doctor`

#### 方法

- `ListModules() → QStringList`: 列出所有可用模块
- `Collect(QStringList modules) → QString taskId`: 异步收集模块信息
- `Detect(QStringList modules) → QString issuesJson`: 同步检测问题
- `Export(QString resultJson, QString outputPath) → bool success`: 导出结果为tar.gz

#### 信号

- `CollectProgress(QString taskId, QString module, double progress)`: 收集进度
- `CollectFinished(QString taskId, QString resultJson)`: 收集完成

## 性能指标

- 启动时间: <2秒
- 模块收集: 单模块<10秒
- 内存占用: <50MB (daemon)
- CPU占用: 收集时<30%

## 安全考虑

- ✅ 不收集密码、证书等敏感信息
- ✅ 日志文件大小限制(<5MB)
- ✅ 仅当前用户可访问导出文件
- ✅ 不执行不可信的外部命令

## License

GPL-3.0
