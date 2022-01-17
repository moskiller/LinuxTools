#!/bin/bash

# 版本号和更新内容函数
Version="0.0.3"
Udate="2022/01/17"
ChangeLog="新增Aria2和哪吒探针"

# 自定义字体彩色函数
red(){ echo -e "\033[31m\033[01m$1\033[0m"; }
green(){ echo -e "\033[32m\033[01m$1\033[0m"; }
white(){ echo -e "\033[37m\033[01m$1\033[0m"; }
blue(){ echo -e  "\033[36m\033[01m$1\033[0m"; }
reading(){ read -rp "$(white "$1")" "$2"; }

# 检测是否已安装curl wget sudo并自动安装
if ! type curl >/dev/null 2>&1; then 
yellow "检测到您未安装 Curl，正在为您安装中 "
if [ $release = "Centos" ]; then
yum -y update && yum install curl -y
else
apt-get update -y && apt-get install curl -y
fi	   
fi

if ! type wget >/dev/null 2>&1; then 
yellow "检测到您未安装 Wget，正在为您安装中 "
if [ $release = "Centos" ]; then
yum -y update && yum install wget -y
else
apt-get update -y && apt-get install wget -y
fi	   
else
green "已安装 Wget "
fi

if ! type sudo >/dev/null 2>&1; then 
yellow "检测到您未安装 Sudo，正在为您安装中 "
if [ $release = "Centos" ]; then
yum -y update && yum install sudo -y
else
apt-get update -y && apt-get install sudo -y
fi	   
else
green "已安装 Sudo "
fi

# 定义检测内核、架构、有道翻译等函数
vpsname=`uname -n`
arch=`uname -m`
kernelver=`uname -r`
virt=`systemd-detect-virt`
translate(){ [[ -n "$1" ]] && curl -sm8 "http://fanyi.youdao.com/translate?&doctype=json&type=AUTO&i=$1" | cut -d \" -f18 2>/dev/null; }

# 检测 IPv4 IPv6 信息
IP4=$(curl -s4m8 https://ip.gs/json)
LAN4=$(ip route get 162.159.192.1 2>/dev/null | grep -oP 'src \K\S+')
WAN4=$(expr "$IP4" : '.*ip\":\"\([^"]*\).*')
COUNTRY4=$(expr "$IP4" : '.*country\":\"\([^"]*\).*')
ASN4=$(expr "$IP4" : '.*asn\":\"\([^"]*\).*')
ASNORG4=$(expr "$IP4" : '.*asn_org\":\"\([^"]*\).*')

IP6=$(curl -s6m8 https://ip.gs/json)
LAN6=$(ip route get 2606:4700:d0::a29f:c001 2>/dev/null | grep -oP 'src \K\S+')
WAN6=$(expr "$IP6" : '.*ip\":\"\([^"]*\).*')
COUNTRY6=$(expr "$IP6" : '.*country\":\"\([^"]*\).*')
ASN6=$(expr "$IP6" : '.*asn\":\"\([^"]*\).*')
ASNORG6=$(expr "$IP6" : '.*asn_org\":\"\([^"]*\).*')

# 检测操作系统
if [[ -f /etc/redhat-release ]]; then
release="Centos"
elif cat /etc/issue | grep -q -E -i "debian"; then
release="Debian"
elif cat /etc/issue | grep -q -E -i "ubuntu"; then
release="Ubuntu"
elif cat /etc/issue | grep -q -E -i "centos|red hat|redhat"; then
release="Centos"
elif cat /proc/version | grep -q -E -i "debian"; then
release="Debian"
elif cat /proc/version | grep -q -E -i "ubuntu"; then
release="Ubuntu"
elif cat /proc/version | grep -q -E -i "centos|red hat|redhat"; then
release="Centos"
else 
red "不能识别您当前的操作系统，请使用Centos,Ubuntu,Debian系统"
rm -f LTBox.sh
exit 1
fi


# 菜单
function Start_Menu(){
clear
cat << "EOF"


                       _      _                    _______          _             
                      | |    (_)                  |__   __|        | |           
                      | |     _ _ __  _   ___  __    | | ___   ___ | |___        
                      | |    | | '_ \| | | \ \/ /    | |/ _ \ / _ \| / __|        
                      | |____| | | | | |_| |>  <     | | (_) | (_) | \__ \        
                      |______|_|_| |_|\__,_/_/\_\    |_|\___/ \___/|_|___/      
                                        ╚╗ By https://fanyc.eu.org 2022 ╔╝



EOF
red "  当前运行版本：$Version                                                       "
red "  脚本更新日期：$Udate                                                         "
red "  版本更新日志：$ChangeLog                                                     "
echo "                                                                            "
echo "========================================================================================="
echo "                    " 
echo " VPS信息 "
echo " 主机名称是：$vpsname "
echo " 操作系统是：$release "
echo " 内核版本：$kernelver "
echo " 处理器架构是：$arch   "
echo " 虚拟化架构是：$virt   "
echo "                    "
echo " IPV4 "
if [ -z "$IP4" ]; then
red " 地址: 无法获取IPV4地址 ! "
else
echo " 地址: $WAN4        "
echo " 地区: $COUNTRY4 ($(translate "$COUNTRY4")) "
echo " ASN: $ASN4        "
echo " ASN-ORG: $ASNORG4 "
fi
echo "                   "
echo " IPv6 "
if [ -z "$IP6" ]; then
red " 地址: 无法获取IPV6地址 ! "
else
echo " 地址: $WAN6        "
echo " 地区: $COUNTRY6 ($(translate "$COUNTRY6"))   "
echo " ASN: $ASN6        "
echo " ASN-ORG: $ASNORG6 "
fi
blue "                   "              
blue "========================================================================================="
echo "                            "              
blue "请选择对应的脚本分类后进入到相对应的菜单中"
blue "                            "
blue "1. 系统网络脚本"
blue "2. 安装节点脚本"
blue "3. 安装面板脚本"
blue "4. 探针相关脚本"
blue "5. 运行测试脚本"
blue "                            "
blue "9. 更新本脚本"
blue "0. 退出脚本"
blue "                            "
while :
do
reading "请输入数字选项:" MenuNumber
case "$MenuNumber" in
     1 ) p1 ;;
     2 ) p2 ;;
     3 ) p3 ;;
     4 ) p4 ;;
     5 ) p5 ;;
     9 ) update ;;
     0 ) exit 0 ;;
     * ) Start_Menu ;;
esac
done
}
    
# 第一页
function p1(){
clear
echo "1.系统网络脚本"
echo "           "
echo "请选择功能： "                  
echo "           "
echo "1. 安装 一键开启BBR"
echo "2. 安装 Warp (by fscarmen)"
echo "3. 安装 Docker"
echo "4. 一键修改DNS为Trex.fi的DNS64解析"
echo "5. 修改主机名"
echo "           "
echo "0. 返回主菜单"
echo "           "
while :
do
reading "请输入选项(回车键默认取消):" P1NumberInput
case "$P1NumberInput" in
     1 ) bbr ;;
     2 ) warp ;;
     3 ) docker ;;
     4 ) dns64ns ;;
     5 ) changehostname ;;
     0 ) Start_Menu ;;
     * ) Start_Menu ;;
esac
done
}

# 第二页
function p2(){
clear
echo "2.安装节点脚本"
echo "           "
echo "请选择功能： "                  
echo "          "
echo "1. 安装 一键SS四合一脚本 (by teddysun)"
echo "2. 安装 V2 8合1脚本 (by mack-a) "
echo "3. 安装 支持IBM LinuxONE的V2脚本 (by hijkpw)"
echo "           "
echo "0. 返回主菜单"
echo "           "
while :
do
reading "请输入选项:" P2NumberInput
case "$P2NumberInput" in
     1 ) teddysun ;;
     2 ) macka ;;
     3 ) hijkpw ;;
     0 ) Start_Menu ;;
     * ) Start_Menu ;;
esac
done
}

# 第三页
function p3(){
clear
echo "3.安装面板脚本"
echo "           "
echo "请选择功能： "                  
echo "          "
echo "1. 安装 宝塔纯净版 7.6.0 (by hostcli.com)"
echo "2. 安装 安装 X-UI面板 (by vaxilu)"
echo "3. 安装 aaPanel (宝塔国际版)"
echo "4. 安装 Aria2一键脚本"
echo "           "
echo "0. 返回主菜单"
echo "           "
while :
do
reading "请输入选项:" P3NumberInput
case "$P3NumberInput" in
     1 ) btclean ;;
     2 ) xui ;;
     3 ) aapanel ;;
     4 ) aria2onekey ;;
     0 ) Start_Menu ;;
     * ) Start_Menu ;;
esac
done
}

# 第四页
function p4(){
clear
echo "4.探针相关脚本"
echo "           "
echo "请选择功能： "                  
echo "          "
echo "1. 安装 ServerStatus-Horatu探针 (by cokemine)"
echo "2. 安装 哪吒探针 (by naiba)"
echo "           "
echo "0. 返回主菜单"
echo "           "
while :
do
reading "请输入选项:" P4NumberInput
case "$P4NumberInput" in
     1 ) serverstatus ;;
     2 ) nezha ;;
     0 ) Start_Menu ;;
     * ) Start_Menu ;;
esac
done
}

# 第五页
function p5(){
clear
echo "5.运行测试脚本"
echo "           "
echo "请选择功能： "                  
echo "          "
echo "1. 流媒体解锁测试（全面版, by lmc999）"
echo "2. 流媒体解锁测试（简化版, by CoiaPrant）"
echo "3. VPS三网测速"
echo "4. Superbench 测试"
echo "5. unixbench 跑分测试 (by rptec)"
echo "6. bestTrace 测试回程脚本"
echo "           "
echo "0. 返回主菜单"
echo "                            "
while :
do
reading "请输入选项(回车键默认取消):" P5NumberInput
case "$P5NumberInput" in
     1 ) mediaUnblockTestAll ;;
     2 ) mediaUnblockTest ;;
     3 ) vpsSpeedTest ;;
     4 ) superBench ;;
     5 ) unixBench ;;
     6 ) bestTrace ;;
     0 ) Start_Menu ;;
     * ) Start_Menu ;;
esac
done
}





# 以下为脚本功能区

# 秋水大佬的一键SS四合一脚本
function teddysun(){
    wget --no-check-certificate -O shadowsocks-all.sh https://raw.githubusercontent.com/teddysun/shadowsocks_install/master/shadowsocks-all.sh && chmod +x shadowsocks-all.sh && ./shadowsocks-all.sh 2>&1 | tee shadowsocks-all.log
}

function warp(){
    wget -N https://cdn.jsdelivr.net/gh/fscarmen/warp/menu.sh && bash menu.sh
}

function xui(){
    bash <(curl -Ls https://raw.githubusercontent.com/vaxilu/x-ui/master/install.sh)
}

function aria2onekey(){
    if [ $release = "Centos" ]; then
        yum install wget curl ca-certificates && wget -N git.io/aria2.sh && chmod +x aria2.sh && ./aria2.sh
    else
        apt install wget curl ca-certificates && wget -N git.io/aria2.sh && chmod +x aria2.sh && ./aria2.sh
    fi
}

function aapanel(){
    if [ $release = "Centos" ]; then
        yum install -y wget && wget -O install.sh http://www.aapanel.com/script/install_6.0_en.sh && bash install.sh forum
    elif [ $release = "Debian" ]; then
        wget -O install.sh http://www.aapanel.com/script/install-ubuntu_6.0_en.sh && bash install.sh forum
    else
        wget -O install.sh http://www.aapanel.com/script/install-ubuntu_6.0_en.sh && sudo bash install.sh forum
    fi
}

function macka(){
    wget -P /root -N --no-check-certificate "https://raw.githubusercontent.com/mack-a/v2ray-agent/master/install.sh" && chmod 700 /root/install.sh && /root/install.sh
}

function bbr(){
    if [ ${virt} == "kvm" ]; then
        wget -N --no-check-certificate "https://raw.githubusercontent.com/chiakge/Linux-NetSpeed/master/tcp.sh" && chmod +x tcp.sh && ./tcp.sh
    fi
    if [[ ${virt} == "lxc" || ${virt} == "openvz" ]]; then
        if [[ ${TUN} == "cat: /dev/net/tun: File descriptor in bad state" ]]; then
            green "已开启TUN，准备安装针对OpenVZ / LXC架构的BBR"
            wget --no-cache -O lkl-haproxy.sh https://github.com/mzz2017/lkl-haproxy/raw/master/lkl-haproxy.sh && bash lkl-haproxy.sh
        else
            red "你还未开启TUN，请在VPS后台设置以开启TUN"
            exit 1
        fi
    fi
}

function btclean(){
    echo "                   "
    echo "请选择你需要安装的版本"
    echo "1. CentOS版"
    echo "2. Ubuntu/Deepin版"
    echo "3. Debian版"
    echo "4. Fedora版"
    echo "5. 从其它低版本升级到最新版"
    echo "           "
    echo "0. 返回主页"
    echo "------------------"
    reading "请输入选项:" menuNumberInput1
    case "$menuNumberInput1" in     
        1 ) btcleancentos;;
        2 ) btcleanubuntu;;
        3 ) btcleandebian;;
        4 ) btcleanfedora;;
        5 ) btcleanupdata;;
        0 ) start_menu;;
    esac
}

function btcleancentos(){
    yum install -y wget && wget -O install.sh http://v7.hostcli.com/install/install_6.0.sh && sh install.sh
}

function btcleanubuntu(){
    wget -O install.sh http://v7.hostcli.com/install/install-ubuntu_6.0.sh && sudo bash install.sh
}

function btcleandebian(){
    wget -O install.sh http://v7.hostcli.com/install/install-ubuntu_6.0.sh && bash install.sh
}

function btcleanfedora(){
    wget -O install.sh http://v7.hostcli.com/install/install_6.0.sh && bash install.sh
}
function btcleanupdata(){
    curl http://v7.hostcli.com/install/update6.sh|bash
}

function docker(){
    curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
}

function mediaUnblockTestAll(){
    bash <(curl -L -s https://raw.githubusercontent.com/lmc999/RegionRestrictionCheck/main/check.sh)
}

function mediaUnblockTest(){
    bash <(curl -sSL "https://github.com/CoiaPrant/MediaUnlock_Test/raw/main/check.sh")
}

function vpsSpeedTest(){
    bash <(curl -sSL "https://github.com/CoiaPrant/Speedtest/raw/main/speedtest-multi.sh")
}

function superBench(){
    wget -qO- git.io/superbench.sh | bash
}

function unixBench(){
    wget https://raw.githubusercontent.com/rptec/vps-shell/master/unixbench.sh && sh unixbench.sh
}

function bestTrace(){
    wget -qO- git.io/besttrace | bash
}

function serverstatus(){
    wget -N https://raw.githubusercontent.com/cokemine/ServerStatus-Hotaru/master/status.sh
    echo "请选择你需要安装的客户端类型"
    echo "1. 服务端"
    echo "2. 监控端"
    echo "0. 返回主页"
    reading "请输入选项:" menuNumberInput1
    case "$menuNumberInput1" in     
        1 ) bash status.sh s ;;
        2 ) bash status.sh c ;;
        0 ) start_menu ;;
    esac
}

function nezha(){
    curl -L https://raw.githubusercontent.com/naiba/nezha/master/script/install.sh -o nezha.sh && chmod +x nezha.sh && sudo ./nezha.sh
}

function changehostname(){
    reading "请输入您想要的新主机名:" newhostname
    hostnamectl set-hostname $newhostname
    green "修改完成，请重新连接SSH 或 重新启动服务器!"
}

function hijkpw(){
    bash <(curl -sL https://raw.githubusercontent.com/moskiller/scripts/master/v2ray.sh)
}

function dns64ns(){
    cp /etc/resolv.conf /etc/resolv.conf.bak
    echo -e "nameserver 2001:67c:2b0::4\nnameserver 2001:67c:2b0::6" > /etc/resolv.conf
}

function update(){
    wget -N https://raw.githubusercontent.com/moskiller/LinuxToolBox/main/LTBox.sh && chmod -R 777 LTBox.sh && bash LTBox.sh
}


Start_Menu
