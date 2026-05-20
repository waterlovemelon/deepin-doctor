# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run Commands

```bash
# Full build + run workflow via run.sh
./run.sh build          # cmake + make (auto-detects obj-x86_64-linux-gnu or build dir)
./run.sh start          # start backend daemon
./run.sh gui            # start frontend (auto-starts daemon if needed)
./run.sh stop           # stop daemon
./run.sh restart        # restart daemon
./run.sh status         # show build/daemon/dbus status
./run.sh collect        # quick CLI collection of all modules
./run.sh clean          # remove build dirs

# Manual build
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=/usr ..
make -j$(nproc)

# Tests (via CTest)
./run.sh test-unit      # unit tests only
./run.sh test-dbus      # D-Bus integration tests
./run.sh test           # both

# Run a single test
cd build && ctest -R test_network_module --verbose
```

## Architecture

Frontend/backend split communicating over D-Bus (session bus):

```
Frontend (QML)  ──D-Bus──>  Backend Daemon (C++)
  BackendProxy                 DBusService
  Main.qml                     ModuleManager
  MainPage.qml                 PluginManager
  ExportPage.qml               ├── network/NetworkModule
  ModuleSelector.qml           ├── system/SystemModule
  ResultView.qml               ├── environment/EnvironmentModule
                               └── logs/LogsModule
```

- **D-Bus service**: `com.deepin.Doctor` on session bus, object path `/com/deepin/Doctor`
- **Methods**: `ListModules()`, `Collect(modules) → taskId`, `Detect(modules) → issuesJson`, `Export(json, path) → bool`
- **Signals**: `CollectProgress(taskId, module, progress)`, `CollectFinished(taskId, resultJson)`
- **Async collection pattern**: `Collect()` returns a UUID task ID immediately; progress arrives via `CollectProgress` signals; final result via `CollectFinished` signal. Modules run in parallel via `QtConcurrent::run()`.
- **Plugin system**: Qt's `QPluginLoader` + `Q_DECLARE_INTERFACE`. Plugins are `.so` loaded at startup from plugin directory. Each plugin provides a `PluginInterface` factory that creates a `ModuleInterface`. See `src/plugins/example/` for reference.

## Key Conventions

- **Qt5/Qt6 dual support**: CMake auto-detects. Qt5 uses generated `.qrc`; Qt6 uses `qt_add_qml_module()`. QML imports use `QtQuick 2.15` for compatibility.
- **Module isolation**: Each module's `collect()` runs in `QtConcurrent::run`, wrapped in try/catch. One module failure doesn't affect others. Thread-safe progress/cancel via `QAtomicInt`.
- **Shared types**: `src/common/Types.h` defines `Issue` (Level: Error/Warning/Info) and `ModuleInfo`. All modules use these.
- **Sensitive data masking**: `LogsModule` redacts passwords, tokens, SSH keys, and connection strings from collected logs.
- **System commands via QProcess**: Modules invoke system utilities (`ip`, `ping`, `dig`, `journalctl`, `dmesg`, `lspci`, `dpkg`, `tar`, etc.) rather than linking libraries directly.
- **UI style**: Simple tool-style UI. System/default Qt theme colors. No gradients, no glow effects, no elaborate animations. Functional over decorative.

## Testing

- **Framework**: Qt Test (`QTest`). Tests use `QTEST_MAIN` and `private slots` as test methods.
- **7 test files** in `tests/`: `test_network_module`, `test_system_module`, `test_environment_module`, `test_logs_module`, `test_module_manager`, `test_qml_export_page`, `test_qml_components`.
- **CMake helper**: `add_deepin_doctor_test(name sources)` registers a test, linking against `deepin-doctor-common`, `Qt::Test`, `Qt::Concurrent`.
- **QML tests** use `FakeBackend` and `FakeTheme` mock objects injected into the QML engine context for isolated UI testing.

## Code Layout

- `src/common/` — `ModuleInterface.h`, `PluginInterface.h`, `Types.h` (shared interfaces)
- `src/backend/` — daemon: `DBusService`, `ModuleManager`, `PluginManager`
- `src/backend/modules/{network,system,environment,logs}/` — built-in modules
- `src/frontend/` — `main.cpp`, `BackendProxy.h/.cpp`
- `src/frontend/qml/` — `Main.qml`, `pages/`, `components/`
- `src/plugins/example/` — reference plugin implementation with developer guide
- `tests/` — Qt Test based unit tests (7 test files)
- `data/dbus/` — D-Bus policy config
- `data/icons/` — app icon
- `debian/` — two binary packages: `deepin-doctor` (frontend) and `deepin-doctor-daemon` (backend)
