# deepin-doctor 架构设计文档

## Context

项目需要开发一个系统诊断工具,用于现场工作人员一键收集设备信息、日志、系统状态,导出给研发或AI分析。核心需求:Qt框架、模块化、插件系统、DBus前后端分离。

## 架构概览

### 系统架构

```
┌─────────────────────────────────────────────┐
│           Frontend (QML/UI)                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐ │
│  │ 主界面   │  │ 结果展示 │  │ 导出界面 │ │
│  └──────────┘  └──────────┘  └──────────┘ │
└─────────────────┬───────────────────────────┘
                  │ DBus IPC
┌─────────────────▼───────────────────────────┐
│        Backend Service (DBus Daemon)        │
│  ┌──────────────────────────────────────┐  │
│  │      Module Manager                  │  │
│  │  ┌─────────┐  ┌─────────┐           │  │
│  │  │Network  │  │System   │ ...       │  │
│  │  │Module   │  │Module   │           │  │
│  │  └─────────┘  └─────────┘           │  │
│  └──────────────────────────────────────┘  │
│  ┌──────────────────────────────────────┐  │
│  │      Plugin Manager                  │  │
│  │  ┌─────────┐  ┌─────────┐           │  │
│  │  │Plugin A │  │Plugin B │ ...       │  │
│  │  └─────────┘  └─────────┘           │  │
│  └──────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
```

### 关键设计决策

1. **前后端分离**: Frontend(QML) ↔ DBus ↔ Backend(C++ Service)
2. **模块化**: 每个功能模块独立实现,通过统一接口注册
3. **插件系统**: 动态加载.so插件,隔离运行
4. **异步收集**: 避免UI阻塞,支持进度反馈

## 目录结构

```
deepin-doctor/
├── CMakeLists.txt
├── README.md
├── requirement.md
├── docs/                      # 文档目录
│   └── architecture.md
├── src/
│   ├── backend/               # 后端DBus服务
│   │   ├── main.cpp          # 服务入口
│   │   ├── DBusService.h/cpp  # DBus服务封装
│   │   ├── ModuleManager.h/cpp # 模块管理器
│   │   ├── PluginManager.h/cpp # 插件管理器
│   │   └── modules/           # 内置模块
│   │       ├── network/
│   │       │   ├── NetworkModule.h/cpp
│   │       │   ├── NetworkCollector.h/cpp
│   │       │   └── NetworkDetector.h/cpp
│   │       ├── system/
│   │       │   ├── SystemModule.h/cpp
│   │       │   └── SystemCollector.h/cpp
│   │       ├── environment/
│   │       │   └── EnvironmentModule.h/cpp
│   │       └── logs/
│   │           └── LogsModule.h/cpp
│   ├── frontend/              # 前端QML界面
│   │   ├── main.cpp          # 前端入口
│   │   ├── BackendProxy.h/cpp # DBus代理
│   │   └── qml/
│   │       ├── Main.qml
│   │       ├── components/
│   │       │   ├── ModuleSelector.qml
│   │       │   ├── ProgressBar.qml
│   │       │   └── ResultView.qml
│   │       └── pages/
│   │           ├── MainPage.qml
│   │           └── ExportPage.qml
│   ├── common/                # 共享代码
│   │   ├── ModuleInterface.h  # 模块接口定义
│   │   ├── PluginInterface.h  # 插件接口定义
│   │   ├── Types.h           # 公共类型定义
│   │   └── Utils.h/cpp       # 工具函数
│   └── plugins/               # 插件开发示例
│       └── example/
│           ├── CMakeLists.txt
│           └── ExamplePlugin.h/cpp
├── tests/                     # 单元测试
│   ├── test_network_module.cpp
│   ├── test_system_collector.cpp
│   └── test_dbus_interface.cpp
├── debian/                    # 打包配置
│   ├── compat
│   ├── control
│   ├── rules
│   └── deepin-doctor.install
└── data/                      # 数据文件
    ├── dbus/
    │   └── com.deepin.Doctor.conf # DBus配置
    └── icons/
        └── deepin-doctor.svg
```

## 核心接口设计

### ModuleInterface.h

```cpp
namespace DeepinDoctor {

class ModuleInterface {
public:
    virtual ~ModuleInterface() = default;

    // 模块元信息
    virtual QString name() const = 0;
    virtual QString description() const = 0;
    virtual QString version() const = 0;

    // 收集操作
    virtual void collect(QJsonObject& result) = 0;

    // 检测操作
    virtual QList<Issue> detect() = 0;

    // 进度反馈
    virtual float progress() const = 0;

    // 取消操作
    virtual void cancel() = 0;

    // 超时设置(秒)
    virtual int timeout() const { return 30; }
};

struct Issue {
    enum Level { Error, Warning, Info };

    Level level;
    QString title;
    QString description;
    QString solution;
};

}
```

### DBus接口定义

```xml
<!-- com.deepin.Doctor.xml -->
<node name="/">
  <interface name="com.deepin.Doctor">
    <!-- 模块管理 -->
    <method name="ListModules">
      <arg name="modules" type="as" direction="out"/>
    </method>

    <!-- 收集操作 -->
    <method name="Collect">
      <arg name="modules" type="as" direction="in"/>
      <arg name="taskId" type="s" direction="out"/>
    </method>

    <signal name="CollectProgress">
      <arg name="taskId" type="s"/>
      <arg name="module" type="s"/>
      <arg name="progress" type="d"/>
    </signal>

    <signal name="CollectFinished">
      <arg name="taskId" type="s"/>
      <arg name="result" type="s"/> <!-- JSON -->
    </signal>

    <!-- 检测操作 -->
    <method name="Detect">
      <arg name="modules" type="as" direction="in"/>
      <arg name="issues" type="s" direction="out"/> <!-- JSON -->
    </method>

    <!-- 导出 -->
    <method name="Export">
      <arg name="result" type="s" direction="in"/>
      <arg name="outputPath" type="s" direction="in"/>
      <arg name="success" type="b" direction="out"/>
    </method>
  </interface>
</node>
```

## 数据流

### 收集流程

```
User Click "Collect"
    ↓
Frontend: BackendProxy.collect(selectedModules)
    ↓ (DBus call)
Backend: ModuleManager.createTask(modules)
    ↓
For each module (async):
    module.collect(result)
    emit Progress(module, progress)
    ↓
Backend: emit CollectFinished(taskId, resultJSON)
    ↓ (DBus signal)
Frontend: onCollectFinished(result)
    ↓
Display results / Export
```

### 导出格式

```json
{
  "manifest": {
    "timestamp": "20260417_174500",
    "version": "0.1.0",
    "modules": ["network", "system"]
  },
  "network": {
    "status": { ... },
    "logs": [ ... ],
    "issues": [ ... ]
  },
  "system": {
    "hardware": { ... },
    "software": { ... },
    "logs": [ ... ]
  }
}
```

## 构建系统

### CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.16)
project(deepin-doctor VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

# Qt依赖
find_package(Qt6 REQUIRED COMPONENTS
    Core
    DBus
    Quick
    QuickControls2
    Concurrent
    Network
)

# 后端可执行文件
add_executable(deepin-doctor-daemon
    src/backend/main.cpp
    src/backend/DBusService.cpp
    src/backend/ModuleManager.cpp
    src/backend/PluginManager.cpp
    # 内置模块
    src/backend/modules/network/NetworkModule.cpp
    src/backend/modules/system/SystemModule.cpp
    # ...
)

target_link_libraries(deepin-doctor-daemon
    PRIVATE
        Qt6::Core
        Qt6::DBus
        Qt6::Concurrent
)

# 前端可执行文件
qt_add_executable(deepin-doctor
    src/frontend/main.cpp
    src/frontend/BackendProxy.cpp
)

qt_add_qml_module(deepin-doctor
    URI DeepinDoctor
    VERSION 1.0
    QML_FILES
        src/frontend/qml/Main.qml
        src/frontend/qml/pages/MainPage.qml
        # ...
)

target_link_libraries(deepin-doctor
    PRIVATE
        Qt6::Quick
        Qt6::DBus
)

# 测试
enable_testing()
add_subdirectory(tests)
```

## 插件系统

### 插件接口

```cpp
// PluginInterface.h
class PluginInterface {
public:
    virtual ~PluginInterface() = default;

    virtual QString id() const = 0;
    virtual ModuleInterface* createModule() = 0;
};

QT_BEGIN_NAMESPACE
Q_DECLARE_INTERFACE(PluginInterface, "com.deepin.Doctor.PluginInterface/1.0")
QT_END_NAMESPACE
```

### 插件加载机制

```cpp
// PluginManager.cpp
void PluginManager::loadPlugins(const QString& pluginDir) {
    QDir dir(pluginDir);
    for (const QString& file : dir.entryList(QStringList() << "*.so")) {
        QPluginLoader loader(dir.absoluteFilePath(file));
        QObject* instance = loader.instance();

        if (auto* plugin = qobject_cast<PluginInterface*>(instance)) {
            m_plugins.append(plugin);
            ModuleInterface* module = plugin->createModule();
            m_moduleManager->registerModule(module);
        }
    }
}
```

## 关键技术点

### 1. 异步收集

使用 `QtConcurrent` 避免阻塞DBus调用:

```cpp
void ModuleManager::collect(const QStringList& modules) {
    QString taskId = QUuid::createUuid().toString();

    QtConcurrent::run([this, modules, taskId]() {
        QJsonObject result;

        for (const QString& mod : modules) {
            if (m_modules.contains(mod)) {
                QJsonObject modResult;
                m_modules[mod]->collect(modResult);
                result[mod] = modResult;

                emit progress(taskId, mod, 1.0);
            }
        }

        emit finished(taskId, QJsonDocument(result).toJson());
    });
}
```

### 2. 超时控制

```cpp
QTimer::singleShot(module->timeout() * 1000, [module]() {
    if (module->isRunning()) {
        module->cancel();
        qWarning() << "Module timeout:" << module->name();
    }
});
```

### 3. 错误处理

所有模块收集失败不影响其他模块:

```cpp
for (auto* module : modules) {
    try {
        QJsonObject modResult;
        module->collect(modResult);
        result[module->name()] = modResult;
    } catch (const std::exception& e) {
        result[module->name()] = QJsonObject{
            {"error", e.what()}
        };
    }
}
```

## 验证计划

### 单元测试

- 每个Module独立测试(collect/detect正确性)
- DBus接口测试(前端调用后端响应)
- 插件加载测试

### 集成测试

- 启动后端服务: `./deepin-doctor-daemon`
- 启动前端: `./deepin-doctor`
- 手动测试: 选择模块 → 收集 → 查看结果 → 导出

### 打包测试

```bash
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr ..
make -j$(nproc)
make install
dpkg-buildpackage -us -uc
```

## 下一步实施

1. 创建CMakeLists.txt和基础目录结构
2. 实现common接口定义(ModuleInterface, PluginInterface)
3. 实现backend DBusService和ModuleManager
4. 实现第一个模块(network或system)验证流程
5. 实现frontend基础界面
6. 完善其他内置模块
7. 实现插件系统
8. 添加测试和文档

## 风险和备选方案

### 风险

1. **DBus权限**: 需要正确配置DBus policy文件
   - 备选: 使用session bus而非system bus

2. **插件崩溃**: 动态库可能影响主进程稳定性
   - 备选: 使用QProcess隔离插件进程

3. **大文件处理**: 日志文件可能上百MB
   - 备选: 分块读取+限制大小+异步IO

### 备选架构

如果DBus方案过于复杂,可简化为单进程架构:

```
Frontend (QML) → C++ Backend (same process)
    - 模块系统: 直接C++调用
    - 插件系统: 仍使用QPluginLoader
    - 简化部署,但牺牲前后端独立性
```
