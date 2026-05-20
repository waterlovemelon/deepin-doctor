# PLANS.md

需求实现状态跟踪。基于 `requirement.md` 逐项对比当前代码。

## 已完成

### Network 模块
- [x] 网络接口状态收集 (ip addr, ip route)
- [x] 网络配置信息 (DNS, 路由, /etc/resolv.conf)
- [x] 网络连通性测试 (ping 网关)
- [x] 网络服务状态 (NetworkManager, wpa_supplicant)
- [x] 网卡设备信息 (lspci)
- [x] NetworkManager/wpa_supplicant 日志 (journalctl)
- [x] 内核网络日志 (dmesg)
- [x] DNS 配置错误检测
- [x] DDE 网络插件缺失检测 (dde-dock/dde-control-center)

### System 模块
- [x] CPU 信息 (型号、核心数)
- [x] 内存信息 (总量、使用率、交换分区)
- [x] 磁盘信息 (使用率)
- [x] 显卡信息 (lspci)
- [x] 网卡信息 (lspci)
- [x] 系统版本 (/etc/os-release, /etc/lsb-release)
- [x] 内核版本 (uname)
- [x] 系统启动时间 (/proc/uptime)
- [x] 桌面环境检测
- [x] 关键软件包版本 (dpkg)
- [x] 系统日志 (journalctl, dmesg)
- [x] X11 日志 (/var/log/Xorg.0.log)
- [x] DDE 缓存日志 (~/.cache/deepin/*.log)

### Environment 模块
- [x] 包完整性检查 (dpkg -C, dpkg --audit)
- [x] 锁文件检测 (/var/lib/dpkg/lock*)
- [x] 关键库文件检查 (ldconfig)
- [x] 环境变量收集 (PATH, LD_LIBRARY_PATH 等)
- [x] 配置目录检查 (/etc, ~/.config)
- [x] 必需包缺失检测 (dde-desktop, dde-daemon 等)
- [x] 破损包检测 (dpkg -C)
- [x] 磁盘空间不足检测 (df -h, >90%)
- [x] 权限问题检测 (~/.config 权限)

### Logs 模块
- [x] DDE 应用日志 (journalctl -u dde-*)
- [x] Deepin 缓存日志 (~/.cache/deepin/*.log)
- [x] 用户应用日志 (~/.local/share/*)
- [x] 系统服务日志 (journalctl -u systemd, dbus, NetworkManager 等)
- [x] 崩溃报告 (/var/crash/*.crash)
- [x] Core dump 列表 (coredumpctl list)
- [x] Sentry 报告 (~/.local/share/sentry)
- [x] 多次崩溃警告 (>5 个 crash 文件)

### 导出功能
- [x] tar.gz 压缩包格式
- [x] 按模块分类的目录结构
- [x] manifest.json 清单文件
- [x] 日志文件单独保存

### 插件系统
- [x] 插件接口 (PluginInterface / ModuleInterface)
- [x] 插件注册机制 (QPluginLoader)
- [x] 插件加载/初始化/运行
- [x] 示例插件 (example/)
- [x] 插件开发文档 (src/plugins/example/README.md)

### 前端 UI
- [x] 模块选择 (全选/单选)
- [x] 一键收集按钮
- [x] 一键检测按钮
- [x] 导出按钮
- [x] 收集进度实时显示
- [x] 检测结果展示 (问题列表 + 严重程度标识)
- [x] 一键复制问题信息

### 基础设施
- [x] D-Bus 前后端通信
- [x] Qt5/Qt6 双版本支持
- [x] Debian 打包 (deepin-doctor + deepin-doctor-daemon)
- [x] 单元测试 (7 个测试套件)
- [x] run.sh 构建/运行/测试脚本

### Network 模块 (新增 2026-05-14)
- [x] DNS 解析测试 (dig/nslookup 解析验证)
- [x] IP 冲突检测 (arping)
- [x] 网卡驱动问题检测 (dmesg 驱动错误 + ip link 状态)
- [x] 防火墙规则异常检测 (iptables/nftables 规则检查)

### System 模块 (新增 2026-05-14)
- [x] 关键组件版本收集 (glibc、systemd、gcc、xorg)
- [x] CPU 使用率 (/proc/stat)
- [x] 磁盘 IO 状态 (/proc/diskstats)
- [x] syslog 收集 (/var/log/syslog)
- [x] kern.log 收集 (/var/log/kern.log)
- [x] Wayland 日志 (~/.local/share/wayland/*.log)

### Environment 模块 (新增 2026-05-14)
- [x] 系统更新中断检测 (dpkg 半安装状态 + 锁文件超时)
- [x] 用户配置文件检查 (浏览器配置权限 + .desktop 文件验证)
- [x] 服务配置检查 (masked 服务 + 重启循环检测)

### Logs 模块 (新增 2026-05-14)
- [x] 日志时间范围筛选 (journalctl --since "24 hours ago")
- [x] 敏感信息脱敏 (密码/token/SSH 密钥/连接字符串自动替换)

---

## 未实现

### 导出功能
- [ ] 导出文件加密选项
- [ ] 收集结果本地持久化存储 (历史记录)

### 前端 UI
- [ ] 历史记录查看 (查看之前的收集/检测结果)

### 插件系统
- [ ] 插件崩溃隔离 (插件崩溃不影响主进程, 当前仅 try/catch)
- [ ] 插件权限控制 (文件访问、网络访问限制)

### 非功能性
- [ ] 单模块超时硬性执行 (需求: 单操作最多 30 秒, 当前 ModuleInterface 有 timeout() 但未确认强制终止)
