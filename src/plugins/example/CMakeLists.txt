# Example Plugin CMakeLists.txt
# 用于构建deepin-doctor示例插件

cmake_minimum_required(VERSION 3.16)

# 插件名称
set(PLUGIN_NAME deepin-doctor-plugin-example)

# 查找Qt库
find_package(QT NAMES Qt6 Qt5 REQUIRED COMPONENTS Core)
find_package(Qt${QT_VERSION_MAJOR} REQUIRED COMPONENTS Core)

# 创建动态库
add_library(${PLUGIN_NAME} SHARED
    ExamplePlugin.cpp
    ExamplePlugin.h
    ExampleModule.cpp
    ExampleModule.h
)

# 设置目标属性
set_target_properties(${PLUGIN_NAME} PROPERTIES
    VERSION 1.0.0
    SOVERSION 1
    PREFIX ""  # 移除lib前缀，生成 deepin-doctor-plugin-example.so
)

# 链接依赖
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

# 编译选项
target_compile_options(${PLUGIN_NAME}
    PRIVATE
        -Wall -Wextra -Wpedantic
)

# 安装插件到 lib/deepin-doctor/plugins/
install(TARGETS ${PLUGIN_NAME}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}/deepin-doctor/plugins
)

# 可选：安装插件文档
install(FILES README.md
    DESTINATION ${CMAKE_INSTALL_DOCDIR}/deepin-doctor/plugins/example
)

# 输出构建信息
message(STATUS "Example plugin configuration:")
message(STATUS "  Plugin name: ${PLUGIN_NAME}")
message(STATUS "  Install path: ${CMAKE_INSTALL_LIBDIR}/deepin-doctor/plugins")
