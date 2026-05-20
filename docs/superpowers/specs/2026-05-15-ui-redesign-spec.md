# Deepin Doctor UI Redesign - Design Spec

## Overview

Complete visual overhaul of the Deepin Doctor QML frontend, replacing the current sidebar+action-bar layout with a home-page-driven navigation model matching Deepin desktop aesthetic.

## Navigation Model

- **Home Page**: Grid of module cards. No sidebar. No header text. Just the cards.
- **Module Detail Page**: Clicking a card navigates to its detail page. Sidebar appears for switching between modules.
- **StackView**: `Main.qml` uses StackView to push/pop between HomePage and ModulePage.

## Home Page

- 4-column grid of cards
- Each card: emoji icon + name + status badge ("可用"/"规划中") + description
- All cards same size (no featured card)
- 8 modules total:
  1. 日志 📋 (logs) - ready
  2. 网络 🌐 (network) - ready
  3. 系统 ⚙️ (system) - ready
  4. 环境 🌏 (environment) - ready
  5. 监听任务 📡 (listening) - planned
  6. 网络环境检查 🛡 (netenv) - planned
  7. 磁盘健康 💽 (disk) - planned
  8. 安全检查 🔒 (security) - planned

## Module Detail Page

- **Header**: icon + name + description + action buttons (采集/检测)
- **Summary Cards Row**: 3 metric cards showing key indicators (e.g. error count, memory usage)
- **Progress Area**: spinner + progress bar (visible during collect/detect)
- **Results Area**: tabbed view (采集结果/检测结果) with grouped key-value rows
- **Empty State**: prompt to click 采集 or 检测

## Sidebar (Module Detail Only)

- Visible only on module detail pages, hidden on home
- Lists all modules with emoji icon + name + description
- Active module highlighted
- Clicking navigates to that module (replaces current module page)

## Styling

- Deepin desktop aesthetic (not web style)
- System/default Qt theme colors
- No gradients, no glow effects, no elaborate animations
- Functional over decorative
- Theme colors defined in Main.qml as readonly properties

## Backend API (Unchanged)

The backend interface via `BackendProxy` remains unchanged:
- `listModules()` → QStringList
- `collect(modules)` → taskId (async with progress signals)
- `detect(modules)` → result JSON
- `exportResult(json, path)` → bool
- `homePath()` → string

## Files to Modify/Create

| File | Action | Purpose |
|---|---|---|
| `Main.qml` | Rewrite | Window + StackView + theme properties |
| `HomePage.qml` | Create | Module grid page |
| `ModulePage.qml` | Create | Module detail page (replaces MainPage role) |
| `ModuleSelector.qml` | Rewrite | Sidebar for module detail pages |
| `ResultView.qml` | Minor update | Keep mostly as-is, update color references |
| `ExportPage.qml` | Minor update | Keep as-is, update color references |
| `MainPage.qml` | Delete | Replaced by HomePage + ModulePage |
| `main.cpp` | No change | Backend setup unchanged |
| `CMakeLists.txt` | Update | Add new QML files to QML_FILES |
