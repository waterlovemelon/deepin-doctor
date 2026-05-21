cmake_minimum_required(VERSION 3.16)
project(deepin-doctor VERSION 0.1.0 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

# Installation prefix
include(GNUInstallDirs)
if (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    set(CMAKE_INSTALL_PREFIX /usr)
endif()

# Find Qt (prefer Qt6, fallback to Qt5)
# Check if Qt6 Quick is actually available before trying Qt6
find_package(Qt6Quick QUIET)
if(Qt6Quick_FOUND)
    set(QT_DEFAULT_MAJOR_VERSION 6)
    find_package(QT NAMES Qt6 REQUIRED COMPONENTS Core DBus Quick QuickControls2 Concurrent Network)
else()
    find_package(QT NAMES Qt5 REQUIRED COMPONENTS Core DBus Quick QuickControls2 Concurrent Network)
endif()
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Core DBus Quick QuickControls2 Concurrent Network)

if(QT_VERSION_MAJOR EQUAL 6)
    qt_standard_project_setup(REQUIRES 6.5)
endif()

# Common library (interfaces)
add_library(deepin-doctor-common STATIC
    src/common/ModuleInterface.h
    src/common/PluginInterface.h
    src/common/Types.h
)

target_include_directories(deepin-doctor-common PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/src/common
)

# Backend daemon
add_executable(deepin-doctor-daemon
    src/backend/main.cpp
    src/backend/DBusService.cpp
    src/backend/DBusAdaptor.cpp
    src/backend/ModuleManager.cpp
    src/backend/PluginManager.cpp
    src/backend/LogDBusService.cpp
    src/backend/LogDBusAdaptor.cpp
    # Built-in modules
    src/backend/modules/network/NetworkModule.cpp
    src/backend/modules/system/SystemModule.cpp
    src/backend/modules/environment/EnvironmentModule.cpp
    src/backend/modules/logs/LogsModule.cpp
)

target_link_libraries(deepin-doctor-daemon
    PRIVATE
        deepin-doctor-common
        Qt${QT_VERSION_MAJOR}::Core
        Qt${QT_VERSION_MAJOR}::DBus
        Qt${QT_VERSION_MAJOR}::Concurrent
)

target_include_directories(deepin-doctor-daemon PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src/common
)

# Frontend application
set(FRONTEND_SOURCES
    src/frontend/main.cpp
    src/frontend/BackendProxy.cpp
    src/frontend/LogBackendProxy.cpp
    src/frontend/ProcessHelper.cpp
)

set(QML_FILES
    src/frontend/qml/Main.qml
    src/frontend/qml/pages/HomePage.qml
    src/frontend/qml/pages/MainPage.qml
    src/frontend/qml/pages/ModulePage.qml
    src/frontend/qml/pages/ExportPage.qml
    src/frontend/qml/pages/LogToolsPage.qml
    src/frontend/qml/components/ModuleSelector.qml
    src/frontend/qml/components/PageLayout.qml
    src/frontend/qml/components/ResultView.qml
    src/frontend/qml/dtk/DTKStyle.qml
    src/frontend/qml/dtk/DTKHighlightPanel.qml
    src/frontend/qml/dtk/DTKItemDelegate.qml
    src/frontend/qml/dtk/DTKBoxPanel.qml
    src/frontend/qml/dtk/DTKButton.qml
    src/frontend/qml/dtk/DTKBusyIndicator.qml
    src/frontend/qml/dtk/DTKCheckBox.qml
    src/frontend/qml/dtk/DTKComboBox.qml
    src/frontend/qml/dtk/DTKDialog.qml
    src/frontend/qml/dtk/DTKMenu.qml
    src/frontend/qml/dtk/DTKMenuItem.qml
    src/frontend/qml/dtk/DTKProgressBar.qml
    src/frontend/qml/dtk/DTKRadioButton.qml
    src/frontend/qml/dtk/DTKScrollBar.qml
    src/frontend/qml/dtk/DTKSearchEdit.qml
    src/frontend/qml/dtk/DTKSlider.qml
    src/frontend/qml/dtk/DTKSwitch.qml
    src/frontend/qml/dtk/DTKTabBar.qml
    src/frontend/qml/dtk/DTKTextArea.qml
    src/frontend/qml/dtk/DTKTextField.qml
    src/frontend/qml/dtk/DTKToolTip.qml
    src/frontend/qml/dtk/qmldir
)

if(QT_VERSION_MAJOR EQUAL 6)
    qt_add_executable(deepin-doctor
        ${FRONTEND_SOURCES}
    )

    qt_add_qml_module(deepin-doctor
        URI DeepinDoctor
        VERSION 1.0
        QML_FILES
            ${QML_FILES}
    )
else()
    # Qt5: use traditional resource file
    set(RESOURCES_FILE "${CMAKE_CURRENT_BINARY_DIR}/resources.qrc")
    set(QML_SOURCE_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/src/frontend/qml")

    # Generate qrc file
    file(WRITE ${RESOURCES_FILE} "<!DOCTYPE RCC><RCC version=\"1.0\">\n<qresource prefix=\"/\">\n")
    foreach(QML_FILE ${QML_FILES})
        set(QML_SOURCE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/${QML_FILE}")
        file(RELATIVE_PATH QML_RESOURCE_PATH "${QML_SOURCE_ROOT}" "${QML_SOURCE_PATH}")
        get_filename_component(QML_RESOURCE_DIR "${QML_RESOURCE_PATH}" DIRECTORY)

        if(QML_RESOURCE_DIR)
            file(MAKE_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/qml/${QML_RESOURCE_DIR}")
        endif()

        file(APPEND ${RESOURCES_FILE} "    <file>qml/${QML_RESOURCE_PATH}</file>\n")
        configure_file(${QML_SOURCE_PATH} ${CMAKE_CURRENT_BINARY_DIR}/qml/${QML_RESOURCE_PATH} COPYONLY)
    endforeach()
    file(APPEND ${RESOURCES_FILE} "</qresource>\n</RCC>\n")

    add_executable(deepin-doctor
        ${FRONTEND_SOURCES}
        ${RESOURCES_FILE}
    )
endif()

target_link_libraries(deepin-doctor
    PRIVATE
        deepin-doctor-common
        Qt${QT_VERSION_MAJOR}::Quick
        Qt${QT_VERSION_MAJOR}::QuickControls2
        Qt${QT_VERSION_MAJOR}::DBus
)

target_include_directories(deepin-doctor PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src/common
)

# ── wb-keyring-check (keyring diagnostic tool) ──
set(KEYRING_CORE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/src/tools/wb-keyring-helper/core)
set(KEYRING_SRC_DIR ${CMAKE_CURRENT_SOURCE_DIR}/src/tools/wb-keyring-helper/src)

set(KEYRING_CORE_SOURCES
    ${KEYRING_CORE_DIR}/common.c
    ${KEYRING_CORE_DIR}/dklog.c
    ${KEYRING_CORE_DIR}/dkcrypt.c
    ${KEYRING_CORE_DIR}/dkfile.c
    ${KEYRING_CORE_DIR}/dkkey.c
)

add_library(wb-keyring-core STATIC ${KEYRING_CORE_SOURCES})
target_include_directories(wb-keyring-core PUBLIC ${KEYRING_CORE_DIR})
target_compile_options(wb-keyring-core PRIVATE -Wall -Wextra -fstack-protector-strong -D_GNU_SOURCE -fPIE -fPIC)
target_link_libraries(wb-keyring-core PUBLIC dl)

# Find libgcrypt
find_package(PkgConfig QUIET)
if(PkgConfig_FOUND)
    pkg_check_modules(GCRYPT_PKG QUIET gcrypt)
endif()
find_path(GCRYPT_INCLUDE_DIR gcrypt.h HINTS ${GCRYPT_PKG_INCLUDE_DIRS})
find_library(GCRYPT_LIBRARY gcrypt HINTS ${GCRYPT_PKG_LIBRARY_DIRS})

if(GCRYPT_INCLUDE_DIR AND GCRYPT_LIBRARY)
    add_executable(wb-keyring-check ${KEYRING_SRC_DIR}/main.c)
    target_include_directories(wb-keyring-check PRIVATE
        ${KEYRING_CORE_DIR}
        ${KEYRING_SRC_DIR}
        ${GCRYPT_INCLUDE_DIR}
    )
    if(GCRYPT_PKG_INCLUDE_DIRS)
        target_include_directories(wb-keyring-check PRIVATE ${GCRYPT_PKG_INCLUDE_DIRS})
    endif()
    target_compile_options(wb-keyring-check PRIVATE -Wall -Wextra -fstack-protector-strong -D_GNU_SOURCE -fPIE -fPIC)
    target_link_libraries(wb-keyring-check PRIVATE wb-keyring-core ${GCRYPT_LIBRARY})
    if(GCRYPT_PKG_LIBRARIES)
        target_link_libraries(wb-keyring-check PRIVATE ${GCRYPT_PKG_LIBRARIES})
    endif()
    set(HAS_KEYRING_CHECK TRUE)
else()
    message(WARNING "libgcrypt not found, wb-keyring-check will not be built")
    set(HAS_KEYRING_CHECK FALSE)
endif()

# Copy keyring tools to build dir for development
file(MAKE_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/tools)
configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/src/tools/wb-keyring-helper/scripts/wb-keyring-fix.sh
    ${CMAKE_CURRENT_BINARY_DIR}/tools/wb-keyring-fix.sh
    COPYONLY
)

# Testing
enable_testing()

# Find Qt Test component
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Test Qml Quick)

# Test executables
function(add_deepin_doctor_test TEST_NAME TEST_SOURCE)
    add_executable(${TEST_NAME} ${TEST_SOURCE} ${ARGN})

    target_link_libraries(${TEST_NAME}
        PRIVATE
            deepin-doctor-common
            Qt${QT_VERSION_MAJOR}::Core
            Qt${QT_VERSION_MAJOR}::Test
            Qt${QT_VERSION_MAJOR}::Concurrent
            Qt${QT_VERSION_MAJOR}::DBus
    )

    target_include_directories(${TEST_NAME} PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src/common
        ${CMAKE_CURRENT_SOURCE_DIR}/src/backend
    )

    add_test(NAME ${TEST_NAME} COMMAND ${TEST_NAME})
endfunction()

# Add test targets
add_deepin_doctor_test(test_network_module
    ${CMAKE_CURRENT_SOURCE_DIR}/tests/test_network_module.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/src/backend/modules/network/NetworkModule.cpp
)

add_executable(test_qml_export_page
    ${CMAKE_CURRENT_SOURCE_DIR}/tests/test_qml_export_page.cpp
)

target_link_libraries(test_qml_export_page
    PRIVATE
        Qt${QT_VERSION_MAJOR}::Core
        Qt${QT_VERSION_MAJOR}::Test
        Qt${QT_VERSION_MAJOR}::Qml
        Qt${QT_VERSION_MAJOR}::Quick
)

add_test(NAME test_qml_export_page COMMAND test_qml_export_page)

add_executable(test_qml_components
    ${CMAKE_CURRENT_SOURCE_DIR}/tests/test_qml_components.cpp
)

target_link_libraries(test_qml_components
    PRIVATE
        Qt${QT_VERSION_MAJOR}::Core
        Qt${QT_VERSION_MAJOR}::Test
        Qt${QT_VERSION_MAJOR}::Qml
        Qt${QT_VERSION_MAJOR}::Quick
)

add_test(NAME test_qml_components COMMAND test_qml_components)

add_deepin_doctor_test(test_system_module
    ${CMAKE_CURRENT_SOURCE_DIR}/tests/test_system_module.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/src/backend/modules/system/SystemModule.cpp
)

add_deepin_doctor_test(test_environment_module
    ${CMAKE_CURRENT_SOURCE_DIR}/tests/test_environment_module.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/src/backend/modules/environment/EnvironmentModule.cpp
)

add_deepin_doctor_test(test_module_manager
    ${CMAKE_CURRENT_SOURCE_DIR}/tests/test_module_manager.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/src/backend/ModuleManager.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/src/backend/modules/network/NetworkModule.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/src/backend/modules/system/SystemModule.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/src/backend/modules/environment/EnvironmentModule.cpp
)

add_deepin_doctor_test(test_logs_module
    ${CMAKE_CURRENT_SOURCE_DIR}/tests/test_logs_module.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/src/backend/modules/logs/LogsModule.cpp
)

add_deepin_doctor_test(test_log_dbus_service
    ${CMAKE_CURRENT_SOURCE_DIR}/tests/test_log_dbus_service.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/src/backend/LogDBusService.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/src/backend/LogDBusAdaptor.cpp
)

# Plugins
add_subdirectory(src/plugins)

# Install targets
install(TARGETS deepin-doctor-daemon
    RUNTIME DESTINATION ${CMAKE_INSTALL_LIBEXECDIR}/deepin-doctor
)

install(TARGETS deepin-doctor
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

# Install DBus config
install(FILES data/dbus/com.deepin.Doctor.conf
    DESTINATION /etc/dbus-1/system.d
)

# Install icons
install(FILES data/icons/deepin-doctor.svg
    DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/scalable/apps
)

# Install keyring tools
if(HAS_KEYRING_CHECK)
    install(TARGETS wb-keyring-check
        RUNTIME DESTINATION ${CMAKE_INSTALL_LIBEXECDIR}/deepin-doctor/tools
    )
endif()
install(PROGRAMS src/tools/wb-keyring-helper/scripts/wb-keyring-fix.sh
    DESTINATION ${CMAKE_INSTALL_LIBEXECDIR}/deepin-doctor/tools
)
