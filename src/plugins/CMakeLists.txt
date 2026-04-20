# deepin-doctor Plugins CMakeLists.txt
# 统一管理所有插件的构建

cmake_minimum_required(VERSION 3.16)

message(STATUS "Configuring deepin-doctor plugins...")

# 添加插件子目录
# 每个插件在自己的子目录中构建

# 示例插件（演示用途，可选安装）
add_subdirectory(example)

# 未来可以添加更多插件：
# add_subdirectory(custom-app-logs)
# add_subdirectory(performance-monitor)
# 等等

message(STATUS "Plugins configuration completed")
