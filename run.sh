#!/bin/bash

# deepin-doctor 运行脚本
# 用法: ./run.sh [命令] [选项]

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目根目录
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$PROJECT_ROOT/build"
DAEMON_LOG="/tmp/deepin-doctor-daemon.log"

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查依赖
check_dependencies() {
    print_info "检查依赖..."

    local missing=()

    # 检查cmake
    if ! command -v cmake &> /dev/null; then
        missing+=("cmake")
    fi

    # 检查make
    if ! command -v make &> /dev/null; then
        missing+=("make")
    fi

    # 检查g++
    if ! command -v g++ &> /dev/null; then
        missing+=("g++")
    fi

    if [ ${#missing[@]} -ne 0 ]; then
        print_error "缺少依赖: ${missing[*]}"
        print_info "请安装: sudo apt install ${missing[*]}"
        exit 1
    fi

    print_success "依赖检查通过"
}

# 构建项目
build() {
    print_info "构建项目..."

    cd "$PROJECT_ROOT"

    if [ ! -d "$BUILD_DIR" ]; then
        mkdir -p "$BUILD_DIR"
    fi

    cd "$BUILD_DIR"

    # 运行cmake
    if [ ! -f "$BUILD_DIR/Makefile" ]; then
        print_info "配置项目..."
        cmake -DCMAKE_INSTALL_PREFIX=/usr ..
    fi

    # 编译
    print_info "编译项目..."
    make -j$(nproc)

    print_success "构建完成"
    ls -lh "$BUILD_DIR/deepin-doctor"* 2>/dev/null | grep -v autogen | head -5
}

# 清理构建
clean() {
    print_info "清理构建目录..."
    rm -rf "$BUILD_DIR"
    print_success "清理完成"
}

# 检查daemon是否运行
is_daemon_running() {
    pgrep -f "deepin-doctor-daemon" > /dev/null
}

# 启动daemon
start_daemon() {
    if is_daemon_running; then
        print_warning "Daemon已经在运行"
        return 0
    fi

    print_info "启动daemon..."

    if [ ! -f "$BUILD_DIR/deepin-doctor-daemon" ]; then
        print_error "Daemon不存在，请先构建项目: ./run.sh build"
        exit 1
    fi

    cd "$BUILD_DIR"
    ./deepin-doctor-daemon > "$DAEMON_LOG" 2>&1 &
    local pid=$!

    sleep 2

    if kill -0 $pid 2>/dev/null; then
        print_success "Daemon已启动 (PID: $pid)"
        print_info "日志文件: $DAEMON_LOG"
        print_info "查看日志: tail -f $DAEMON_LOG"
    else
        print_error "Daemon启动失败"
        print_info "查看日志: cat $DAEMON_LOG"
        exit 1
    fi
}

# 停止daemon
stop_daemon() {
    print_info "停止daemon..."
    pkill -f "deepin-doctor-daemon" 2>/dev/null || true
    print_success "Daemon已停止"
}

# 启动前端GUI
start_gui() {
    print_info "启动前端GUI..."

    if [ ! -f "$BUILD_DIR/deepin-doctor" ]; then
        print_error "前端不存在，请先构建项目: ./run.sh build"
        exit 1
    fi

    # 确保daemon运行
    if ! is_daemon_running; then
        print_warning "Daemon未运行，正在启动..."
        start_daemon
    fi

    cd "$BUILD_DIR"
    ./deepin-doctor
}

# 测试DBus接口
test_dbus() {
    print_info "测试DBus接口..."

    # 确保daemon运行
    if ! is_daemon_running; then
        print_warning "Daemon未运行，正在启动..."
        start_daemon
    fi

    echo ""
    print_info "列出可用模块:"
    gdbus call --session --dest com.deepin.Doctor \
        --object-path /com/deepin/Doctor \
        --method com.deepin.Doctor.ListModules

    echo ""
    print_info "收集网络信息（后台任务）:"
    local task_id=$(gdbus call --session --dest com.deepin.Doctor \
        --object-path /com/deepin/Doctor \
        --method com.deepin.Doctor.Collect "['network']" | grep -oP "'\K[^']+")
    echo "任务ID: $task_id"

    echo ""
    print_info "等待收集完成..."
    sleep 5

    echo ""
    print_info "检测网络问题:"
    gdbus call --session --dest com.deepin.Doctor \
        --object-path /com/deepin/Doctor \
        --method com.deepin.Doctor.Detect "['network']" | head -c 200
    echo "..."

    print_success "DBus测试完成"
}

# 运行单元测试
test_unit() {
    print_info "运行单元测试..."

    if [ ! -d "$BUILD_DIR" ]; then
        print_error "构建目录不存在，请先构建项目: ./run.sh build"
        exit 1
    fi

    cd "$BUILD_DIR"
    make test

    print_success "单元测试完成"
}

# 显示状态
status() {
    echo "=== deepin-doctor 状态 ==="
    echo ""

    # 项目状态
    if [ -d "$BUILD_DIR" ]; then
        echo -e "构建目录: ${GREEN}存在${NC}"
        if [ -f "$BUILD_DIR/deepin-doctor" ]; then
            echo -e "前端: ${GREEN}已构建${NC} ($(ls -lh $BUILD_DIR/deepin-doctor | awk '{print $5}'))"
        else
            echo -e "前端: ${RED}未构建${NC}"
        fi
        if [ -f "$BUILD_DIR/deepin-doctor-daemon" ]; then
            echo -e "后端: ${GREEN}已构建${NC} ($(ls -lh $BUILD_DIR/deepin-doctor-daemon | awk '{print $5}'))"
        else
            echo -e "后端: ${RED}未构建${NC}"
        fi
    else
        echo -e "构建目录: ${RED}不存在${NC}"
    fi

    echo ""

    # Daemon状态
    if is_daemon_running; then
        local pid=$(pgrep -f "deepin-doctor-daemon")
        echo -e "Daemon: ${GREEN}运行中${NC} (PID: $pid)"
        echo "日志: $DAEMON_LOG"
    else
        echo -e "Daemon: ${RED}未运行${NC}"
    fi

    echo ""

    # DBus状态
    if gdbus call --session --dest com.deepin.Doctor \
        --object-path /com/deepin/Doctor \
        --method com.deepin.Doctor.ListModules &> /dev/null; then
        echo -e "DBus服务: ${GREEN}可用${NC}"
    else
        echo -e "DBus服务: ${RED}不可用${NC}"
    fi
}

# 快速收集（命令行）
collect() {
    local modules="${1:-['network', 'system', 'environment', 'logs']}"

    print_info "收集模块: $modules"

    # 确保daemon运行
    if ! is_daemon_running; then
        print_warning "Daemon未运行，正在启动..."
        start_daemon
    fi

    local task_id=$(gdbus call --session --dest com.deepin.Doctor \
        --object-path /com/deepin/Doctor \
        --method com.deepin.Doctor.Collect "$modules" | grep -oP "'\K[^']+")

    print_info "任务ID: $task_id"
    print_info "等待收集完成..."

    # 等待完成（监听日志）
    sleep 10

    print_success "收集完成"
    print_info "结果已保存，可使用GUI查看或导出"
}

# 导出结果
export_result() {
    print_info "导出功能需要通过GUI使用"
    print_info "请运行: ./run.sh gui"
}

# 显示帮助
show_help() {
    cat << EOF
deepin-doctor 运行脚本

用法: $0 <命令> [选项]

命令:
  build       构建项目
  clean       清理构建目录
  start       启动daemon（后台运行）
  stop        停止daemon
  restart     重启daemon
  gui         启动前端GUI
  test        运行所有测试（DBus + 单元测试）
  test-dbus   测试DBus接口
  test-unit   运行单元测试
  status      显示项目状态
  collect     快速收集信息（命令行）
  help        显示此帮助信息

示例:
  # 首次使用
  $0 build
  $0 start
  $0 gui

  # 快速测试
  $0 test

  # 查看状态
  $0 status

  # 停止服务
  $0 stop

  # 清理并重新构建
  $0 clean
  $0 build

EOF
}

# 主函数
main() {
    local command="${1:-help}"

    case "$command" in
        build)
            check_dependencies
            build
            ;;
        clean)
            clean
            ;;
        start)
            start_daemon
            ;;
        stop)
            stop_daemon
            ;;
        restart)
            stop_daemon
            sleep 1
            start_daemon
            ;;
        gui)
            start_gui
            ;;
        test)
            test_dbus
            echo ""
            test_unit
            ;;
        test-dbus)
            test_dbus
            ;;
        test-unit)
            test_unit
            ;;
        status)
            status
            ;;
        collect)
            collect "$2"
            ;;
        export)
            export_result
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            print_error "未知命令: $command"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

# 运行主函数
main "$@"
