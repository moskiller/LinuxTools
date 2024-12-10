#!/bin/bash

# ===================== 全局变量定义 =====================
Version="0.0.5"
Update="2024/12/10"
ChangeLog="Claude帮我优化了脚本,hehe..."
LOGFILE="/var/log/linuxtools.log"

# ===================== 基础函数定义 =====================
red(){ echo -e "\033[31m\033[01m$1\033[0m"; }
green(){ echo -e "\033[32m\033[01m$1\033[0m"; }
yellow(){ echo -e "\033[33m\033[01m$1\033[0m"; }
white(){ echo -e "\033[37m\033[01m$1\033[0m"; }
blue(){ echo -e  "\033[36m\033[01m$1\033[0m"; }

# ===================== 工具函数 =====================
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a $LOGFILE
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        red "错误：请使用root用户运行此脚本"
        exit 1
    fi
}

check_network() {
    if ! ping -c 1 google.com >/dev/null 2>&1; then
        if ! ping -c 1 baidu.com >/dev/null 2>&1; then
            red "错误：网络连接异常，请检查网络设置"
            exit 1
        fi
    fi
}

reading() {
    local prompt="$1"
    local var_name="$2"
    local input
    while true; do
        read -rp "$(white "$prompt")" input
        if [[ -n "$input" ]]; then
            eval "$var_name='$input'"
            break
        else
            yellow "输入不能为空，请重新输入"
        fi
    done
}

show_progress() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

confirm_action() {
    local prompt="$1"
    local input
    while true; do
        read -rp "$(yellow "$prompt [y/n]: ")" input
        case $input in
            [yY]) return 0 ;;
            [nN]) return 1 ;;
            *) yellow "请输入 y 或 n" ;;
        esac
    done
}
# ===================== 系统检测函数 =====================
check_system() {
    if [[ -f /etc/redhat-release ]]; then
        release="Centos"
    elif cat /etc/issue | grep -q -E -i "debian"; then
        release="Debian"
    elif cat /etc/issue | grep -q -E -i "ubuntu"; then
        release="Ubuntu"
    elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
        release="Centos"
    else 
        red "不支持的操作系统，请使用Centos、Ubuntu或Debian"
        exit 1
    fi
    
    case $(uname -m) in
        x86_64)
            arch="x64"
            ;;
        aarch64)
            arch="arm64"
            ;;
        *)
            red "不支持的架构: $(uname -m)"
            exit 1
            ;;
    esac

    # 检测虚拟化技术
    if [ -f /proc/cpuinfo ]; then
        if grep -qi 'kvm' /proc/cpuinfo; then
            virt="kvm"
        elif grep -qi 'openvz' /proc/cpuinfo; then
            virt="openvz"
        elif grep -qi 'lxc' /proc/cpuinfo; then
            virt="lxc"
        else
            virt="unknown"
        fi
    fi

    # 检测TUN
    TUN=$(cat /dev/net/tun 2>&1)
}

# ===================== 软件包安装函数 =====================
install_required_packages() {
    local packages=("curl" "wget" "sudo" "socat")
    
    for package in "${packages[@]}"; do
        if ! type "$package" >/dev/null 2>&1; then 
            yellow "检测到您未安装 ${package}，正在为您安装中 "
            if [ "$release" = "Centos" ]; then
                yum -y update && yum install -y "$package" || {
                    red "安装 ${package} 失败"
                    log "安装 ${package} 失败"
                    exit 1
                }
            else
                apt-get update -y && apt-get install -y "$package" || {
                    red "安装 ${package} 失败"
                    log "安装 ${package} 失败"
                    exit 1
                }
            fi
            green "${package} 安装完成"
            log "${package} 安装完成"
        else
            green "${package} 已安装"
        fi
    done
}
# ===================== 功能函数 =====================
function bbr() {
    log "开始BBR安装流程"
    if [ "${virt}" == "kvm" ]; then
        if confirm_action "确认在KVM架构上安装BBR?"; then
            wget -N --no-check-certificate "https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh" || {
                red "下载BBR脚本失败"
                log "BBR脚本下载失败"
                return 1
            }
            chmod +x tcp.sh
            ./tcp.sh &
            show_progress $!
            log "BBR安装完成"
        fi
    elif [[ "${virt}" == "lxc" || "${virt}" == "openvz" ]]; then
        if [[ "${TUN}" == "cat: /dev/net/tun: File descriptor in bad state" ]]; then
            if confirm_action "确认安装OpenVZ/LXC架构的BBR?"; then
                green "已开启TUN，准备安装针对OpenVZ/LXC架构的BBR"
                wget --no-cache -O lkl-haproxy.sh https://github.com/mzz2017/lkl-haproxy/raw/master/lkl-haproxy.sh || {
                    red "下载LKL脚本失败"
                    log "LKL脚本下载失败"
                    return 1
                }
                bash lkl-haproxy.sh &
                show_progress $!
                log "OpenVZ/LXC BBR安装完成"
            fi
        else
            red "错误：未开启TUN，请在VPS后台设置开启TUN"
            log "BBR安装失败：未开启TUN"
            return 1
        fi
    fi
}

function docker() {
    log "开始Docker安装流程"
    if confirm_action "确认安装Docker?"; then
        if [ "$release" = "Centos" ]; then
            yum install -y yum-utils
            yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            yum install -y docker-ce docker-ce-cli containerd.io
        else
            apt-get update
            apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
            curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
            apt-get update
            apt-get install -y docker-ce docker-ce-cli containerd.io
        fi

        systemctl start docker
        systemctl enable docker
        
        if docker --version >/dev/null 2>&1; then
            green "Docker安装成功"
            log "Docker安装成功"
        else
            red "Docker安装失败"
            log "Docker安装失败"
            return 1
        fi
    fi
}
# ===================== 更新函数 =====================
function update() {
    log "开始更新系统"
    if confirm_action "确认更新系统?"; then
        if [ "$release" = "Centos" ]; then
            yum update -y
        else
            apt-get update -y && apt-get upgrade -y
        fi
        green "系统更新完成"
        log "系统更新完成"
    fi
}

# ===================== 主菜单函数 =====================
function Start_Menu() {
    check_root
    check_network
    check_system
    install_required_packages
    
    clear
    green "=============================================="
    green "Linux Tools ${Version} ${Update}"
    green "=============================================="
    green "1. 安装BBR"
    green "2. 安装Docker"
    green "3. 安装Aria2"
    green "4. 安装哪吒探针"
    green "5. 系统工具"
    green "6. 系统信息"
    green "9. 更新系统"
    green "0. 退出脚本"
    green "=============================================="
    echo "更新日志：${ChangeLog}"
    green "=============================================="
    
    while true; do
        reading "请输入数字选项:" MenuNumber
        case "$MenuNumber" in
            1) 
                if confirm_action "确认安装BBR?"; then
                    log "用户选择安装BBR"
                    bbr
                fi
                ;;
            2)
                if confirm_action "确认安装Docker?"; then
                    log "用户选择安装Docker"
                    docker
                fi
                ;;
            3)
                if confirm_action "确认安装Aria2?"; then
                    log "用户选择安装Aria2"
                    aria2
                fi
                ;;
            4)
                if confirm_action "确认安装哪吒探针?"; then
                    log "用户选择安装哪吒探针"
                    nezha
                fi
                ;;
            5)
                if confirm_action "确认进入系统工具菜单?"; then
                    log "用户进入系统工具菜单"
                    system_tools
                fi
                ;;
            6)
                if confirm_action "确认查看系统信息?"; then
                    log "用户查看系统信息"
                    system_info
                fi
                ;;
            9)
                if confirm_action "确认更新系统?"; then
                    log "用户选择更新系统"
                    update
                fi
                ;;
            0)
                log "用户退出脚本"
                exit 0
                ;;
            *)
                yellow "无效的选项，请重新输入"
                ;;
        esac
    done
}

# ===================== 脚本入口 =====================
Start_Menu
