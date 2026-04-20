#!/bin/bash
# 示例插件测试脚本
# 用于验证示例插件是否正确加载和运行

echo "=== deepin-doctor 示例插件测试 ==="
echo

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 测试函数
test_plugin_file() {
    echo "1. 检查插件文件..."

    PLUGIN_FILE="/usr/lib/deepin-doctor/plugins/deepin-doctor-plugin-example.so"

    if [ -f "$PLUGIN_FILE" ]; then
        echo -e "${GREEN}✓${NC} 插件文件存在: $PLUGIN_FILE"
        ls -lh "$PLUGIN_FILE"
    else
        echo -e "${YELLOW}!${NC} 插件文件未安装，检查构建目录..."
        BUILD_PLUGIN="./build/src/plugins/example/deepin-doctor-plugin-example.so"
        if [ -f "$BUILD_PLUGIN" ]; then
            echo -e "${GREEN}✓${NC} 构建目录中找到插件: $BUILD_PLUGIN"
            ls -lh "$BUILD_PLUGIN"
        else
            echo -e "${RED}✗${NC} 未找到插件文件"
            return 1
        fi
    fi

    # 检查插件符号
    echo
    echo "检查插件符号..."
    if nm -D "$PLUGIN_FILE" 2>/dev/null | grep -q "qt_plugin_instance"; then
        echo -e "${GREEN}✓${NC} 插件符号正确"
        nm -D "$PLUGIN_FILE" | grep "qt_plugin"
    else
        echo -e "${RED}✗${NC} 插件符号缺失"
        return 1
    fi

    return 0
}

test_plugin_loading() {
    echo
    echo "2. 测试插件加载..."

    # 检查守护进程服务
    if systemctl is-active --quiet deepin-doctor; then
        echo -e "${GREEN}✓${NC} deepin-doctor 守护进程正在运行"
    else
        echo -e "${YELLOW}!${NC} deepin-doctor 守护进程未运行"
        echo "尝试启动守护进程..."

        if [ -f "./build/deepin-doctor-daemon" ]; then
            echo "使用构建目录中的守护进程..."
            # 注意：实际环境中应该使用系统安装的版本
        fi
    fi

    # 测试DBus接口
    echo
    echo "测试DBus接口..."
    if dbus-send --system --print-reply \
        --dest=com.deepin.Doctor \
        /com/deepin/Doctor \
        com.deepin.Doctor.listModules 2>/dev/null | grep -q "example"; then
        echo -e "${GREEN}✓${NC} 插件已加载到守护进程"
    else
        echo -e "${YELLOW}!${NC} 插件未在DBus中注册（可能需要重启守护进程）"
    fi
}

test_plugin_functionality() {
    echo
    echo "3. 测试插件功能..."

    # 创建测试数据目录
    TEST_DATA_DIR="$HOME/.local/share/myapp"
    mkdir -p "$TEST_DATA_DIR"

    # 创建测试日志文件
    echo "创建测试日志文件..."
    cat > "$TEST_DATA_DIR/test.log" <<EOF
[2026-04-17 10:00:00] INFO: Application started
[2026-04-17 10:00:01] ERROR: Failed to load configuration
[2026-04-17 10:00:02] WARNING: Using default settings
[2026-04-17 10:00:03] ERROR: Connection failed
EOF

    echo -e "${GREEN}✓${NC} 测试数据已创建: $TEST_DATA_DIR"

    # 测试收集功能
    echo
    echo "测试收集功能（通过DBus）..."
    if dbus-send --system --print-reply \
        --dest=com.deepin.Doctor \
        /com/deepin/Doctor \
        com.deepin.Doctor.collect \
        string:"example" 2>&1 | head -20; then
        echo -e "${GREEN}✓${NC} 收集功能测试完成"
    else
        echo -e "${YELLOW}!${NC} DBus调用失败（守护进程可能未运行）"
    fi
}

test_documentation() {
    echo
    echo "4. 检查文档..."

    README_FILE="./src/plugins/example/README.md"
    if [ -f "$README_FILE" ]; then
        echo -e "${GREEN}✓${NC} README文档存在"
        echo "文档大小: $(wc -l < "$README_FILE") 行"
    else
        echo -e "${RED}✗${NC} README文档缺失"
    fi
}

# 主测试流程
main() {
    test_plugin_file
    test_plugin_loading
    test_plugin_functionality
    test_documentation

    echo
    echo "=== 测试完成 ==="
    echo
    echo "后续步骤:"
    echo "1. 如果插件未安装，执行: sudo make install"
    echo "2. 如果守护进程未运行，执行: sudo systemctl start deepin-doctor"
    echo "3. 查看详细文档: cat src/plugins/example/README.md"
    echo "4. 使用前端测试: deepin-doctor"
}

main
