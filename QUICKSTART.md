# 快速使用指南

## 一键运行脚本

使用 `run.sh` 脚本可以快速构建、启动和管理 deepin-doctor。

### 基础使用

```bash
# 首次使用：构建项目
./run.sh build

# 启动daemon（后台服务）
./run.sh start

# 启动GUI界面
./run.sh gui

# 查看状态
./run.sh status

# 停止服务
./run.sh stop
```

### 常用命令

#### 1. 构建
```bash
./run.sh build        # 构建项目
./run.sh clean        # 清理构建目录
```

#### 2. 服务管理
```bash
./run.sh start        # 启动daemon
./run.sh stop         # 停止daemon
./run.sh restart      # 重启daemon
./run.sh status       # 查看状态
```

#### 3. 使用界面
```bash
./run.sh gui          # 启动前端GUI
```

#### 4. 测试
```bash
./run.sh test         # 运行所有测试
./run.sh test-dbus    # 测试DBus接口
./run.sh test-unit    # 运行单元测试
```

#### 5. 命令行收集
```bash
# 收集所有模块
./run.sh collect

# 收集指定模块
./run.sh collect "['network', 'system']"
```

### 完整工作流程示例

#### 开发调试模式
```bash
# 终端1: 构建并启动daemon
./run.sh build
./run.sh start

# 终端2: 启动GUI
./run.sh gui

# 终端3: 查看日志
tail -f /tmp/deepin-doctor-daemon.log
```

#### 快速测试模式
```bash
# 构建并测试
./run.sh build
./run.sh test

# 查看状态
./run.sh status
```

#### 仅命令行模式
```bash
# 启动daemon
./run.sh start

# 收集信息
./run.sh collect

# 查看日志
tail -f /tmp/deepin-doctor-daemon.log

# 停止
./run.sh stop
```

### 命令详解

| 命令 | 说明 |
|------|------|
| `build` | 检查依赖并构建项目 |
| `clean` | 删除构建目录 |
| `start` | 后台启动daemon服务 |
| `stop` | 停止daemon服务 |
| `restart` | 重启daemon服务 |
| `gui` | 启动前端GUI界面 |
| `test` | 运行所有测试（DBus + 单元测试） |
| `test-dbus` | 测试DBus接口功能 |
| `test-unit` | 运行C++单元测试 |
| `status` | 显示项目构建和运行状态 |
| `collect` | 命令行快速收集信息 |
| `help` | 显示帮助信息 |

### 日志查看

```bash
# 查看daemon日志
tail -f /tmp/deepin-doctor-daemon.log

# 查看最近日志
tail -n 50 /tmp/deepin-doctor-daemon.log

# 搜索错误
grep -i error /tmp/deepin-doctor-daemon.log
```

### 故障排除

#### 问题1: Daemon启动失败
```bash
# 检查是否已运行
./run.sh status

# 如果已运行，先停止
./run.sh stop

# 重新启动
./run.sh start
```

#### 问题2: 构建失败
```bash
# 清理并重新构建
./run.sh clean
./run.sh build
```

#### 问题3: GUI无法连接DBus
```bash
# 检查daemon状态
./run.sh status

# 如果未运行，启动daemon
./run.sh start

# 然后启动GUI
./run.sh gui
```

#### 问题4: 权限问题
```bash
# 某些系统日志需要root权限
# 使用sudo运行daemon
sudo ./build/deepin-doctor-daemon
```

### 输出目录结构

```
build/
├── deepin-doctor           # 前端可执行文件 (56KB)
├── deepin-doctor-daemon    # 后端daemon (269KB)
├── libdeepin-doctor-plugin-example.so  # 示例插件 (128KB)
└── test_*                  # 测试可执行文件
```

### 手动运行（不使用脚本）

如果不想使用脚本，也可以手动运行：

```bash
# 构建
mkdir -p build && cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr ..
make -j$(nproc)

# 启动daemon
./deepin-doctor-daemon > /tmp/daemon.log 2>&1 &

# 启动GUI
./deepin-doctor

# 测试DBus
gdbus call --session --dest com.deepin.Doctor \
  --object-path /com/deepin/Doctor \
  --method com.deepin.Doctor.ListModules

# 停止daemon
pkill -f deepin-doctor-daemon
```

### 性能提示

- **首次启动**: Daemon需要1-2秒注册DBus服务
- **收集时间**: 单模块约5-10秒，全部模块约20-30秒
- **内存占用**: Daemon约50MB，GUI约30MB
- **CPU占用**: 收集时约20-30%，空闲时<1%

### 进阶用法

#### 1. 调试模式
```bash
# 前台运行daemon（查看详细输出）
./build/deepin-doctor-daemon

# 在另一个终端启动GUI
./run.sh gui
```

#### 2. 自定义模块收集
```bash
# 仅收集网络和系统信息
./run.sh collect "['network', 'system']"
```

#### 3. 测试特定模块
```bash
# 测试DBus接口 - 网络模块
gdbus call --session --dest com.deepin.Doctor \
  --object-path /com/deepin/Doctor \
  --method com.deepin.Doctor.Detect "['network']"
```

### 获取帮助

```bash
# 查看所有可用命令
./run.sh help

# 查看项目状态
./run.sh status
```

---

## 更多信息

- 完整文档: [README.md](README.md)
- 架构设计: [docs/architecture.md](docs/architecture.md)
- 需求文档: [requirement.md](requirement.md)
- 插件开发: [src/plugins/example/README.md](src/plugins/example/README.md)
