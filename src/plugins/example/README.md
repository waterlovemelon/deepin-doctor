# deepin-doctor 插件开发示例

本文档提供完整的插件开发指南，帮助开发者快速开发自己的deepin-doctor插件。

## 目录

- [概述](#概述)
- [插件架构](#插件架构)
- [开发步骤](#开发步骤)
- [接口说明](#接口说明)
- [编译安装](#编译安装)
- [测试验证](#测试验证)
- [最佳实践](#最佳实践)
- [常见问题](#常见问题)

## 概述

deepin-doctor采用插件化架构，允许第三方开发者开发插件扩展功能。本示例插件展示了：

- 收集用户最近打开的文件记录
- 检测异常文件访问模式
- 收集自定义应用日志
- 完整的进度反馈和取消机制

## 插件架构

### 核心组件

1. **PluginInterface**: 插件入口接口
   - 提供插件唯一标识
   - 创建模块实例

2. **ModuleInterface**: 功能模块接口
   - 实现信息收集逻辑
   - 实现问题检测逻辑
   - 提供进度反馈

### 文件结构

```
src/plugins/example/
├── ExamplePlugin.h       # 插件类声明
├── ExamplePlugin.cpp     # 插件类实现
├── ExampleModule.h       # 模块类声明
├── ExampleModule.cpp     # 模块类实现
├── CMakeLists.txt        # 构建配置
└── README.md             # 本文档
```

## 开发步骤

### 步骤1：创建插件类

创建 `ExamplePlugin.h`：

```cpp
#ifndef EXAMPLE_PLUGIN_H
#define EXAMPLE_PLUGIN_H

#include "PluginInterface.h"

namespace DeepinDoctor {

class ExamplePlugin : public QObject, public PluginInterface
{
    Q_OBJECT
    Q_PLUGIN_METADATA(IID "com.deepin.Doctor.PluginInterface/1.0")
    Q_INTERFACES(DeepinDoctor::PluginInterface)

public:
    ExamplePlugin();
    ~ExamplePlugin() override;

    QString id() const override;
    ModuleInterface* createModule() override;
};

} // namespace DeepinDoctor

#endif // EXAMPLE_PLUGIN_H
```

**要点：**
- 继承 `QObject` 和 `PluginInterface`
- 使用 `Q_PLUGIN_METADATA` 宏声明插件元数据
- 使用 `Q_INTERFACES` 宏声明实现的接口

### 步骤2：实现插件类

创建 `ExamplePlugin.cpp`：

```cpp
#include "ExamplePlugin.h"
#include "ExampleModule.h"

namespace DeepinDoctor {

ExamplePlugin::ExamplePlugin()
{
}

ExamplePlugin::~ExamplePlugin()
{
}

QString ExamplePlugin::id() const
{
    // 使用反向域名格式，确保唯一性
    return "com.deepin.doctor.plugin.example";
}

ModuleInterface* ExamplePlugin::createModule()
{
    // 返回新的模块实例，调用者负责删除
    return new ExampleModule();
}

} // namespace DeepinDoctor
```

**要点：**
- `id()` 返回全局唯一的插件标识符
- `createModule()` 每次调用返回新的模块实例

### 步骤3：创建模块类

创建 `ExampleModule.h`：

```cpp
#ifndef EXAMPLE_MODULE_H
#define EXAMPLE_MODULE_H

#include "ModuleInterface.h"
#include <QAtomicInt>

namespace DeepinDoctor {

class ExampleModule : public ModuleInterface
{
public:
    ExampleModule();
    ~ExampleModule() override;

    // 元数据
    QString name() const override;
    QString description() const override;
    QString version() const override;

    // 核心功能
    void collect(QJsonObject& result) override;
    QList<Issue> detect() override;

    // 进度控制
    float progress() const override;
    void cancel() override;
    bool isRunning() const override;

    // 可选：自定义超时时间（秒）
    int timeout() const override { return 60; }

private:
    void collectRecentlyOpenedFiles(QJsonObject& result);
    void collectApplicationLogs(QJsonObject& result);
    QList<Issue> checkForAbnormalPatterns(const QJsonObject& data);

    QAtomicInt m_running;
    QAtomicInt m_cancelled;
    mutable QAtomicInt m_progress;
};

} // namespace DeepinDoctor

#endif // EXAMPLE_MODULE_H
```

**要点：**
- 实现所有纯虚函数
- 使用 `QAtomicInt` 保证线程安全
- 可以重写 `timeout()` 设置自定义超时

### 步骤4：实现模块类

创建 `ExampleModule.cpp`：

```cpp
#include "ExampleModule.h"
#include <QDebug>
#include <QFile>
#include <QDir>
#include <QJsonArray>
#include <QTextStream>

namespace DeepinDoctor {

ExampleModule::ExampleModule()
    : m_running(false)
    , m_cancelled(false)
    , m_progress(0)
{
}

ExampleModule::~ExampleModule()
{
}

QString ExampleModule::name() const
{
    return "example";
}

QString ExampleModule::description() const
{
    return "Example plugin: Collect recently opened files and application logs";
}

QString ExampleModule::version() const
{
    return "1.0.0";
}

void ExampleModule::collect(QJsonObject& result)
{
    m_running = true;
    m_cancelled = false;
    m_progress = 0;

    // 第一步：收集最近文件
    QJsonObject recentFiles;
    collectRecentlyOpenedFiles(recentFiles);
    
    if (m_cancelled) {
        m_running = false;
        return;
    }
    
    m_progress = 40;
    result["recent_files"] = recentFiles;

    // 第二步：收集应用日志
    QJsonObject appLogs;
    collectApplicationLogs(appLogs);
    
    if (m_cancelled) {
        m_running = false;
        return;
    }
    
    m_progress = 80;
    result["application_logs"] = appLogs;

    // 添加元数据
    result["collection_time"] = QDateTime::currentDateTime().toString(Qt::ISODate);
    
    m_progress = 100;
    m_running = false;
}

QList<Issue> ExampleModule::detect()
{
    QList<Issue> issues;
    
    // 先收集数据
    QJsonObject data;
    collect(data);
    
    if (m_cancelled) {
        return issues;
    }
    
    // 检测问题
    issues = checkForAbnormalPatterns(data);
    
    return issues;
}

float ExampleModule::progress() const
{
    return m_progress / 100.0;
}

void ExampleModule::cancel()
{
    m_cancelled = true;
}

bool ExampleModule::isRunning() const
{
    return m_running;
}

// ... 实现私有方法 ...

} // namespace DeepinDoctor
```

**要点：**
- `collect()` 和 `detect()` 都可能被长时间调用，需要支持取消
- 定期检查 `m_cancelled` 标志
- 及时更新 `m_progress` 进度值

### 步骤5：编写CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.16)

set(PLUGIN_NAME deepin-doctor-plugin-example)

# 查找Qt
find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Core)
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Core)

# 创建动态库
add_library(${PLUGIN_NAME} SHARED
    ExamplePlugin.cpp
    ExamplePlugin.h
    ExampleModule.cpp
    ExampleModule.h
)

# 设置属性
set_target_properties(${PLUGIN_NAME} PROPERTIES
    VERSION 1.0.0
    SOVERSION 1
    PREFIX ""  # 不添加lib前缀
)

# 链接库
target_link_libraries(${PLUGIN_NAME}
    PRIVATE
        deepin-doctor-common
        Qt${QT_VERSION_MAJOR}::Core
)

# 包含目录
target_include_directories(${PLUGIN_NAME}
    PRIVATE
        ${CMAKE_SOURCE_DIR}/src/common
        ${CMAKE_CURRENT_SOURCE_DIR}
)

# 安装到插件目录
install(TARGETS ${PLUGIN_NAME}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}/deepin-doctor/plugins
)
```

**要点：**
- 使用 `SHARED` 创建动态库
- 链接 `deepin-doctor-common` 获取接口定义
- 安装路径为 `lib/deepin-doctor/plugins/`

## 接口说明

### PluginInterface

```cpp
class PluginInterface
{
public:
    virtual ~PluginInterface() = default;
    
    // 插件唯一标识符
    virtual QString id() const = 0;
    
    // 创建模块实例（调用者负责删除）
    virtual ModuleInterface* createModule() = 0;
};
```

### ModuleInterface

```cpp
class ModuleInterface
{
public:
    virtual ~ModuleInterface() = default;
    
    // 元数据
    virtual QString name() const = 0;
    virtual QString description() const = 0;
    virtual QString version() const = 0;
    
    // 收集信息
    virtual void collect(QJsonObject& result) = 0;
    
    // 检测问题
    virtual QList<Issue> detect() = 0;
    
    // 进度反馈（0.0 - 1.0）
    virtual float progress() const = 0;
    
    // 取消操作
    virtual void cancel() = 0;
    
    // 运行状态
    virtual bool isRunning() const = 0;
    
    // 超时时间（秒），默认30秒
    virtual int timeout() const { return 30; }
};
```

### Issue结构

```cpp
struct Issue {
    enum Level { Error, Warning, Info };
    
    Level level;           // 问题级别
    QString title;         // 问题标题
    QString description;   // 详细描述
    QString solution;      // 解决方案
    
    QJsonObject toJson() const;
    static Issue fromJson(const QJsonObject& json);
};
```

## 编译安装

### 编译插件

在项目根目录执行：

```bash
mkdir build && cd build
cmake ..
make
```

### 安装插件

```bash
sudo make install
```

插件将被安装到：`/usr/lib/deepin-doctor/plugins/deepin-doctor-plugin-example.so`

### 仅编译插件

如果只想编译插件而不编译整个项目：

```bash
cd build
make deepin-doctor-plugin-example
```

## 测试验证

### 方法1：通过前端测试

1. 启动deepin-doctor前端：
   ```bash
   deepin-doctor
   ```

2. 在模块列表中应该能看到"example"模块

3. 选择模块并点击"收集"或"检测"按钮

### 方法2：通过DBus测试

```bash
# 列出所有可用模块
dbus-send --system --print-reply \
    --dest=com.deepin.Doctor \
    /com/deepin/Doctor \
    com.deepin.Doctor.listModules

# 运行收集
dbus-send --system --print-reply \
    --dest=com.deepin.Doctor \
    /com/deepin/Doctor \
    com.deepin.Doctor.collect \
    string:"example"

# 运行检测
dbus-send --system --print-reply \
    --dest=com.deepin.Doctor \
    /com/deepin/Doctor \
    com.deepin.Doctor.detect \
    string:"example"
```

### 方法3：查看日志

```bash
# 查看守护进程日志
journalctl -u deepin-doctor -f
```

## 最佳实践

### 1. 错误处理

```cpp
void ExampleModule::collect(QJsonObject& result)
{
    QFile file("/path/to/file");
    if (!file.open(QIODevice::ReadOnly)) {
        qWarning() << "Failed to open file:" << file.errorString();
        result["error"] = file.errorString();
        return;  // 不要抛出异常
    }
    
    // 正常处理...
}
```

### 2. 敏感信息处理

```cpp
// 过滤敏感配置项
QJsonObject sanitizeSettings(const QSettings& settings)
{
    QJsonObject result;
    QStringList sensitiveKeys = {"password", "token", "secret", "key"};
    
    for (const QString& key : settings.allKeys()) {
        bool isSensitive = false;
        for (const QString& pattern : sensitiveKeys) {
            if (key.contains(pattern, Qt::CaseInsensitive)) {
                isSensitive = true;
                break;
            }
        }
        
        if (isSensitive) {
            result[key] = "[REDACTED]";
        } else {
            result[key] = settings.value(key).toString();
        }
    }
    
    return result;
}
```

### 3. 大文件处理

```cpp
void readLargeFile(const QString& path, QJsonObject& result)
{
    QFile file(path);
    if (file.size() > 10 * 1024 * 1024) {  // 10MB
        result["content"] = "File too large, skipped";
        result["size_bytes"] = file.size();
        return;
    }
    
    // 读取文件...
}
```

### 4. 进度更新

```cpp
void ExampleModule::collect(QJsonObject& result)
{
    const int totalSteps = 100;
    
    for (int i = 0; i < totalSteps; ++i) {
        if (m_cancelled) {
            return;
        }
        
        // 处理第i步
        processStep(i);
        
        // 更新进度
        m_progress = (i + 1) * 100 / totalSteps;
    }
}
```

### 5. 资源清理

```cpp
void ExampleModule::collect(QJsonObject& result)
{
    QFile* file = new QFile("/path/to/file");
    
    // 使用RAII或确保清理
    QScopedPointer<QFile> fileGuard(file);
    
    if (!file->open(QIODevice::ReadOnly)) {
        return;  // fileGuard会自动删除file
    }
    
    // 使用文件...
}
```

## 常见问题

### Q1: 插件加载失败？

**A:** 检查以下项目：
1. 插件文件是否在正确的目录：`/usr/lib/deepin-doctor/plugins/`
2. 文件权限是否正确：`-rwxr-xr-x`
3. 插件是否正确链接 `deepin-doctor-common`
4. 查看日志：`journalctl -u deepin-doctor -n 50`

### Q2: 如何调试插件？

**A:** 
1. 使用 `qDebug()` 输出调试信息
2. 查看守护进程日志：`journalctl -u deepin-doctor -f`
3. 使用 `QT_LOGGING_RULES="*.debug=true"` 开启详细日志

### Q3: collect() 和 detect() 有什么区别？

**A:**
- `collect()`：收集信息，不进行问题检测，返回JSON数据
- `detect()`：检测问题，返回问题列表（Issue列表）
- 建议：`detect()` 可以先调用 `collect()` 收集数据，然后分析

### Q4: 如何支持取消操作？

**A:**
```cpp
void ExampleModule::collect(QJsonObject& result)
{
    for (int i = 0; i < 1000; ++i) {
        // 定期检查取消标志
        if (m_cancelled) {
            qDebug() << "Collection cancelled";
            m_running = false;
            return;
        }
        
        // 处理...
    }
}
```

### Q5: 插件可以依赖哪些库？

**A:**
- Qt Core（必须）
- deepin-doctor-common（必须）
- 其他Qt模块（根据需要添加）
- 系统库
- 注意：避免依赖大型第三方库，保持插件轻量

### Q6: 如何处理超时？

**A:**
```cpp
// 重写 timeout() 方法
int ExampleModule::timeout() const
{
    return 60;  // 60秒超时
}
```

守护进程会在超时后自动调用 `cancel()`。

### Q7: 插件之间如何避免冲突？

**A:**
1. 使用唯一的插件ID（反向域名格式）
2. 使用唯一的模块名称
3. 避免修改全局状态
4. 不要收集重复的信息

### Q8: 如何更新插件？

**A:**
1. 修改版本号
2. 重新编译安装
3. 重启守护进程：`systemctl restart deepin-doctor`

## 更多资源

- [deepin-doctor 主项目](https://github.com/deepin-community/deepin-doctor)
- [Qt 插件系统文档](https://doc.qt.io/qt-6/plugins-howto.html)
- [问题反馈](https://github.com/deepin-community/deepin-doctor/issues)

## 许可证

本示例插件遵循 GPL-3.0 许可证。
