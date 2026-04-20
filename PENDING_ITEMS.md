# Pending Items

## Open task
- None.

## Resolved review issues
- `src/frontend/qml/components/ResultView.qml`
  - Raw tab and copy action now derive text from `resultData`.
  - Summary view now exposes stable repeater-backed state and has regression coverage.
- `src/frontend/qml/components/ModuleSelector.qml`
  - Selection updates now clone and reassign arrays so QML bindings refresh reliably.
- `src/frontend/qml/pages/ExportPage.qml`
  - UI-only export option toggles were removed.
  - Success dialog body now follows `msgText` correctly.
  - Export serialization failure now resets `isExporting` instead of leaving the page stuck.
- `tests/test_qml_export_page.cpp`
  - Test harness now provides `mainWindow` theme context so isolated QML loading runs without `ReferenceError` noise.
  - Regression coverage now includes success dialog text sync and stringify failure state reset.

## Verification
- `test_qml_components` passed.
- `test_qml_export_page` passed.
- GUI process stayed running under `QT_QPA_PLATFORM=offscreen` during startup verification.
