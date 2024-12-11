#!/bin/bash

# 严格模式
set -e

# 全局变量
DEBUG=false
VERSION="1.0.0"
USERNAME=$(whoami)
WORKDIR="/home/${USERNAME}/nezha-agent"
LOG_FILE="${WORKDIR}/install.log"
TMP_DIRECTORY="/home/${USERNAME}/nezha-agent/tmp"
ZIP_FILE="${TMP_DIRECTORY}/nezha-agent_freebsd_amd64.zip"

# 清理函数
cleanup() {
    [ -d "${TMP_DIRECTORY}" ] && rm -rf "${TMP_DIRECTORY}"
    if [ $? -ne 0 ]; then
        log "ERROR" "清理临时文件失败"
    fi
}

# 确保脚本退出时清理
trap 'cleanup' EXIT

# 日志函数
log() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # 确保日志目录存在
    mkdir -p "$(dirname "$LOG_FILE")"
    
    echo "${timestamp} [${level}] ${message}" | tee -a "$LOG_FILE"
    [ "$DEBUG" = true ] && [ "$level" = "DEBUG" ] && echo "${timestamp} [DEBUG] ${message}"
}

# 显示帮助信息
usage() {
    echo "使用方法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  --version      显示脚本版本号并退出"
    echo "  --uninstall    卸载 Nezha Agent"
    echo "  --upgrade      升级 Nezha Agent 到最新版本"
    echo "  --help         显示此帮助信息并退出"
    echo ""
}

# 参数解析
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --version)
                echo "Nezha Agent 安装脚本 v${VERSION}"
                exit 0
                ;;
            --uninstall)
                uninstall_agent
                exit 0
                ;;
            --upgrade)
                upgrade_agent
                exit 0
                ;;
            --help)
                usage
                exit 0
                ;;
            *)
                log "ERROR" "未知选项: $1"
                usage
                exit 1
                ;;
        esac
    done
}

# 检查必要命令
check_requirements() {
    local required_commands=("sudo" "pgrep" "pkill" "uuidgen" "wget" "unzip")
    
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log "ERROR" "$cmd 命令不存在，请安装后再试"
            exit 1
        fi
    done
}

# 检查权限
check_permissions() {
    if [ ! -w "$WORKDIR" ]; then
        log "ERROR" "没有工作目录的写入权限: $WORKDIR"
        return 1
    fi
    
    if [ ! -w "$(dirname "$LOG_FILE")" ]; then
        log "ERROR" "没有日志目录的写入权限"
        return 1
    fi
}

# 下载函数
download_agent() {
    local max_retries=3
    local retry=0
    
    if [ -z "$VERSION" ]; then
        DOWNLOAD_LINK="https://github.com/nezhahq/agent/releases/latest/download/nezha-agent_freebsd_amd64.zip"
        VERSION="latest"
    else
        DOWNLOAD_LINK="https://github.com/nezhahq/agent/releases/download/${VERSION}/nezha-agent_freebsd_amd64.zip"
    fi
    
    mkdir -p "$TMP_DIRECTORY"
    
    log "INFO" "开始下载 Nezha Agent ${VERSION}..."
    
    while [ $retry -lt $max_retries ]; do
        if wget --timeout=10 --tries=3 -qO "$ZIP_FILE" "$DOWNLOAD_LINK"; then
            log "INFO" "下载成功: $DOWNLOAD_LINK"
            return 0
        fi
        retry=$((retry + 1))
        log "WARN" "下载失败，第 $retry 次重试..."
        sleep 2
    done
    
    log "ERROR" "下载失败: $DOWNLOAD_LINK"
    return 1
}

# 解压函数
decompression() {
    unzip -o "$1" -d "$TMP_DIRECTORY"
    if [ $? -ne 0 ]; then
        log "ERROR" "解压失败"
        return 1
    fi
}

# 安装函数
install_agent() {
    install -m 755 ${TMP_DIRECTORY}/nezha-agent ${WORKDIR}/nezha-agent
}

# 验证输入
validate_input() {
    local input=$1
    local type=$2
    
    case "$type" in
        "server")
            [[ "$input" =~ ^[a-zA-Z0-9._-]+$ ]] || return 1
            ;;
        "port")
            [[ "$input" =~ ^[0-9]+$ ]] && [ "$input" -ge 1 ] && [ "$input" -le 65535 ] || return 1
            ;;
    esac
    return 0
}

# 生成配置
generate_config() {
    echo "关于接下来需要输入的三个变量，请注意："
    echo "Dashboard 站点地址可以写 IP 也可以写域名（域名不可套 CDN）"
    echo "面板 RPC 端口为你的 Dashboard 安装时设置的用于 Agent 接入的 RPC 端口（默认 5555）"
    echo "Agent 密钥需要先在管理面板上添加 Agent 获取"
    
    read -p "请输入 Dashboard 站点地址：" NZ_DASHBOARD_SERVER
    while true; do
        read -p "请输入面板 RPC 端口：" NZ_DASHBOARD_PORT
        validate_input "$NZ_DASHBOARD_PORT" "port" && break
        echo "无效的端口号，请输入 1-65535 之间的整数！"
    done
    read -p "请输入 Agent 密钥: " NZ_DASHBOARD_PASSWORD
    
    if ! validate_input "$NZ_DASHBOARD_SERVER" "server"; then
        log "ERROR" "无效的服务器地址"
        return 1
    fi
    
    # 生成配置文件
    cat > ${WORKDIR}/config.yml << EOF
client_secret: ${NZ_DASHBOARD_PASSWORD}
debug: false
disable_auto_update: false
disable_command_execute: false
disable_force_update: false
disable_nat: false
disable_send_query: false
gpu: false
insecure_tls: false
ip_report_period: 1800
report_delay: 1
server: ${NZ_DASHBOARD_SERVER}:${NZ_DASHBOARD_PORT}
skip_connection_count: false
skip_procs_count: false
temperature: false
tls: false
use_gitee_to_upgrade: false
use_ipv6_country_code: false
uuid: $(uuidgen)   # 自动生成唯一标识符
EOF

    # 生成启动脚本
    cat > ${WORKDIR}/start.sh << EOF
#!/bin/bash
if pgrep -f 'nezha-agent' >/dev/null; then
    echo "Nezha Agent 已经在运行中"
    exit 0
fi
pgrep -f 'nezha-agent' | xargs -r kill
cd ${WORKDIR}
TMPDIR="${WORKDIR}" exec ${WORKDIR}/nezha-agent -c config.yml >/dev/null 2>&1
EOF
    chmod +x ${WORKDIR}/start.sh
}

# 进程管理
check_process() {
    pgrep -f "nezha-agent -c config.yml" >/dev/null
}

stop_agent() {
    if check_process; then
        log "INFO" "停止 nezha-agent 进程..."
        pkill -f 'nezha-agent'
        sleep 2
        check_process && pkill -9 -f 'nezha-agent'
    fi
}

# 运行 agent
run_agent() {
    stop_agent
    
    nohup ${WORKDIR}/start.sh >/dev/null 2>&1 &
    printf "Nezha-agent 已经准备就绪，请按下回车键启动\n"
    read
    
    printf "正在启动 Nezha-agent，请耐心等待...\n"
    sleep 3
    
    if check_process; then
        log "INFO" "Nezha-agent 已成功启动"
        echo "Nezha-agent 已启动！"
    else
        log "ERROR" "Nezha-agent 启动失败"
        echo "启动失败，请检查配置并重试"
    fi
}

# 卸载函数
uninstall_agent() {
    log "INFO" "开始卸载 Nezha Agent..."
    stop_agent
    rm -rf "$WORKDIR"
    log "INFO" "Nezha Agent 已成功卸载"
}

# 版本比较
version_gt() {
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"
}

# 获取最新版本
get_latest_version() {
    local api_url="https://api.github.com/repos/nezhahq/agent/releases/latest"
    local version
    
    version=$(wget -qO- --timeout=10 "$api_url" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g')
    
    if [ -z "$version" ]; then
        log "ERROR" "获取最新版本失败"
        return 1
    fi
    
    echo "$version"
}

# 升级函数
upgrade_agent() {
    log "INFO" "开始检查 Nezha Agent 版本..."
    
    if [ ! -e "${WORKDIR}/nezha-agent" ]; then
        log "INFO" "未安装 Nezha Agent，将直接安装最新版本"
        download_agent && decompression "${ZIP_FILE}" && install_agent
        run_agent
        return 0
    fi
    
    local current_version=$(${WORKDIR}/nezha-agent -v 2>&1 | awk '{print $3}')
    local latest_version=$(get_latest_version)
    
    log "INFO" "当前版本: ${current_version}"
    log "INFO" "最新版本: ${latest_version}"
    
    if [ "${latest_version}" == "${current_version}" ]; then
        log "INFO" "已是最新版本"
        return 0
    fi
    
    if version_gt "${latest_version}" "${current_version}"; then
        log "INFO" "开始升级到 ${latest_version}..."
        stop_agent
        download_agent && decompression "${ZIP_FILE}" && install_agent
        run_agent
    else
        log "WARN" "当前版本高于最新版本，请检查版本号"
    fi
}

# 主函数
main() {
    log "INFO" "开始执行 Nezha Agent 安装脚本..."
    
    # 系统检查
    if [ "$(uname)" != "FreeBSD" ]; then
        log "ERROR" "此脚本仅支持 FreeBSD 系统"
        exit 1
    fi
    }
    
    # 创建工作目录
    mkdir -p "$WORKDIR"
    
    # 检查权限和依赖
    check_permissions || exit 1
    check_requirements
    
    # 处理命令行参数
    parse_args "$@"
    
    # 如果没有配置文件，生成配置
    [ ! -e ${WORKDIR}/start.sh ] && generate_config
    
    # 安装或升级
    if [ ! -e "${WORKDIR}/nezha-agent" ] || [ -n "${VERSION}" ]; then
        download_agent && decompression "${ZIP_FILE}" && install_agent
    fi
    
    # 运行 agent
    [ -e ${WORKDIR}/start.sh ] && run_agent
    
    log "INFO" "Nezha Agent 安装脚本执行完毕"
}

# 执行主函数
main "$@"
