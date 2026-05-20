# Log Tools Design Spec

Date: 2026-05-15

## Overview

为 deepin-doctor 新增两个日志相关功能：
1. **调试模式开关** — 通过 `deepin-debug-config` 控制 Deepin 系统组件的调试日志输出
2. **日志导出** — 导出系统组件的日志文件（框架先行，具体实现后补）

两个功能都是临时操作，不持久化任何状态。用户在界面上选择组件，执行操作，完成。

## Architecture

新建独立的 `LogDBusService` 类，与现有 `DBusService` 平级，各管各的 D-Bus 接口。

```
Frontend (QML)
  LogToolsPage.qml
       │
       ▼
D-Bus (Session Bus)
  com.deepin.Doctor.LogService
  /com/deepin/Doctor/Log
       │
       ▼
Backend
  LogDBusService.cpp
  (QProcess → deepin-debug-config)
```

## D-Bus Interface

**Service:** `com.deepin.Doctor.LogService`
**Object Path:** `/com/deepin/Doctor/Log`

### Methods

| Method | Parameters | Return | Description |
|--------|-----------|--------|-------------|
| `CheckCommand()` | — | `bool` | 检查 `deepin-debug-config` 是否可用 |
| `ListComponents()` | — | `QStringList` | 返回支持的系统组件列表 |
| `SetDebugMode(QStringList components, bool enabled)` | 组件列表, 开关 | `bool` | 开启/关闭指定组件的调试日志 |
| `IsDebugEnabled(QString component)` | 组件名 | `bool` | 查询单个组件的调试状态 |
| `ExportLogs(QStringList components, QString type, QString path)` | 组件列表, 导出类型, 路径 | `bool` | 导出日志（框架，实现后补） |

### Signals

| Signal | Parameters | Description |
|--------|-----------|--------|
| `DebugModeChanged(QString component, bool enabled)` | 组件名, 状态 | 调试模式变更通知 |
| `ExportProgress(QString component, float progress)` | 组件名, 进度 | 导出进度（框架预留） |
| `ExportFinished(bool success, QString path)` | 成功与否, 路径 | 导出完成通知 |

## Backend Implementation

### Files

- `src/backend/LogDBusService.h` — 头文件
- `src/backend/LogDBusService.cpp` — 实现

### CheckCommand

```cpp
bool LogDBusService::CheckCommand()
{
    return QProcess::execute("which", {"deepin-debug-config"}) == 0;
}
```

### ListComponents

硬编码默认组件列表，TODO：后续改为通过 `deepin-debug-config --list` 动态获取。

```cpp
QStringList LogDBusService::ListComponents()
{
    // TODO: 后续改为动态查询
    return {
        "dde-desktop",
        "dde-dock",
        "dde-launcher",
        "dde-control-center",
        "dde-file-manager",
        "dde-polkit-agent",
        "dde-session-daemon",
        "dde-system-daemon"
    };
}
```

### SetDebugMode

```cpp
bool LogDBusService::SetDebugMode(const QStringList &components, bool enabled)
{
    if (!CheckCommand()) return false;

    QString action = enabled ? "enable" : "disable";
    for (const QString &comp : components) {
        int ret = QProcess::execute("deepin-debug-config", {action, comp});
        if (ret != 0) return false;
        emit DebugModeChanged(comp, enabled);
    }
    return true;
}
```

### IsDebugEnabled

```cpp
bool LogDBusService::IsDebugEnabled(const QString &component)
{
    QProcess proc;
    proc.start("deepin-debug-config", {"status", component});
    proc.waitForFinished(5000);
    // 解析输出判断状态，具体取决于 deepin-debug-config 的输出格式
    return proc.exitCode() == 0;
}
```

### ExportLogs

框架预留，具体实现后补：

```cpp
bool LogDBusService::ExportLogs(const QStringList &components, const QString &type, const QString &path)
{
    // TODO: 实现日志导出逻辑
    // type: "collected" (导出 collect 结果) 或 "raw" (导出系统原始日志)
    // components: 指定组件列表，空列表表示全部
    emit ExportFinished(true, path);
    return true;
}
```

## Frontend

### Files

- `src/frontend/qml/pages/LogToolsPage.qml` — 新页面
- `src/frontend/LogBackendProxy.h/.cpp` — 新的 D-Bus 代理（或复用现有 BackendProxy）

### LogToolsPage 布局

```
┌─────────────────────────────────────────┐
│  日志工具                                │
├─────────────────────────────────────────┤
│                                         │
│  [调试模式]                    [状态: ✓] │
│                                         │
│  ☑ dde-desktop    ☑ dde-dock           │
│  ☑ dde-launcher   ☑ dde-control-center │
│  ☑ dde-file-manager                     │
│  ☑ dde-polkit-agent                     │
│  ☑ dde-session-daemon                   │
│  ☑ dde-system-daemon                    │
│                                         │
│  [ 全选 ]  [ 全不选 ]                    │
│                                         │
│  [ 开启调试 ]  [ 关闭调试 ]              │
│                                         │
├─────────────────────────────────────────┤
│                                         │
│  [导出日志]                              │
│                                         │
│  导出类型: ○ 已收集的结果  ○ 系统原始日志 │
│                                         │
│  ☑ dde-desktop    ☑ dde-dock           │
│  ☑ dde-launcher   ...                   │
│                                         │
│  [ 全选 ]  [ 全不选 ]                    │
│                                         │
│  导出路径: [~/deepin-doctor-logs.tar.gz] │
│  [ 导出 ]                                │
│                                         │
└─────────────────────────────────────────┘
```

### 入口

从 HomePage 的 logs 卡片点击进入，或在 ModulePage 顶部增加一个"日志工具"标签页切换。

## Error Handling

- `CheckCommand()` 返回 false 时，前端显示提示："deepin-debug-config 未安装，请先安装该工具"
- `SetDebugMode()` 失败时，前端显示具体哪个组件失败
- `ExportLogs()` 框架阶段直接返回 true，后续实现时补充错误处理
- QProcess 超时：所有命令设置 10 秒超时，超时视为失败

## Testing

- 新增 `test_log_dbus_service` 测试文件
- 测试 `CheckCommand()` 在有/无命令时的返回值
- 测试 `ListComponents()` 返回非空列表
- 测试 `SetDebugMode()` 的参数传递（mock QProcess）

## TODO

- [ ] 组件列表动态查询（通过 `deepin-debug-config --list`）
- [ ] `ExportLogs` 具体实现
- [ ] `IsDebugEnabled` 输出解析（取决于 deepin-debug-config 的实际输出格式）
