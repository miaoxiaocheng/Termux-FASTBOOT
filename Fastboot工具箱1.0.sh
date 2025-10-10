#!/data/data/com.termux/files/usr/bin/bash

# 定义颜色变量（加粗高亮版本）
RED='\033[31;1m'
GREEN='\033[32;1m'
YELLOW='\033[33;1m'
BLUE='\033[34;1m'
CYAN='\033[36;1m'
NC='\033[0m' # 重置颜色

# 初始菜单函数
show_main_menu() {
    while true; do
        clear
        echo -e "\033[1;36m===== 主菜单 =====\033[0m"
        echo "1) root模式"
        echo "2) 免root模式(需要安装Termux:api)"
        echo "3) 退出脚本"
        read -p "请选择模式 [1-3]: " main_choice

        case $main_choice in
            1)
                echo -e "\033[32m[√] 已选择root模式\033[0m"
                # 直接运行root模式，不返回此菜单
                run_root_mode
                break
                ;;
            2)
                echo -e "\033[32m[√] 已选择免root模式\033[0m"
                # 运行免root模式
                run_non_root_mode
                ;;
            3)
                echo -e "\033[32m[√] 退出脚本\033[0m"
                exit 0
                ;;
            *)
                echo -e "\033[31m[×] 无效选项\033[0m"
                sleep 1
                ;;
        esac
    done
}

# 免Root模式运行函数
run_non_root_mode() {
    # 初始化环境
    non_root_initialize_environment
    
    while true; do
        clear
        echo -e "${BLUE}===== 免root FASTBOOT全功能菜单 =====${NC}"
        echo -e "${YELLOW}作者酷安by:米粉钉子户1999 
    http://www.coolapk.com/u/6100654
    免费工具，请勿盗卖，倒卖死全家，全家替我挡灾！
    如果你花钱买的，说明你活该被骗，活该被圈钱！${NC}"
        echo -e "${RED}1) ${GREEN}连接设备 (USB模式)${NC}"
        echo -e "${CYAN}2) ${GREEN}fastBoot功能 (NOR模式)${NC}"
        echo -e "${YELLOW}3) ${GREEN}退出${NC}"
        
        read -p "请输入选项编号 (1-3): " choice
        
        case $choice in
            1)
                echo -e "${BLUE}正在连接设备...${NC}"
                non_root_usb_connection
                read -n 1 -s -r -p "按任意键返回菜单..."
                ;;
            2)
                echo -e "${CYAN}进入fastBoot功能...${NC}"
                if non_root_verify_connection; then
                    non_root_fastboot_menu
                else
                    echo -e "${RED}未检测到fastboot设备，请先连接设备!${NC}"
                    read -n 1 -s -r -p "按任意键返回菜单..."
                fi
                ;;
            3)
                echo -e "${YELLOW}正在退出...${NC}"
                return 0
                ;;
            *)
                echo -e "${RED}无效的选项，请重新输入！${NC}"
                sleep 1
                ;;
        esac
    done
}

# 免Root模式初始化环境
non_root_initialize_environment() {
    # 定义日志文件路径
    LOG_FILE="$HOME/storage_permission.log"
    
    # 检查日志文件是否存在
    if [ -f "$LOG_FILE" ]; then
        echo "存储权限已配置，跳过授权步骤"
    else
        echo "正在请求存储权限..."
        termux-setup-storage
        
        echo "记录存储权限状态..."
        ls -l ~/storage > "$LOG_FILE" 2>&1
        echo "权限状态已保存至: $LOG_FILE"
    fi

    # 定义标记文件路径（确保路径可写）
    FLAG_FILE="$PREFIX/.rm_commands_done.flag"

    # 检查标记文件是否存在
    if [ ! -f "$FLAG_FILE" ]; then
        # 首次执行：删除目标文件
        rm -f $PREFIX/etc/tls/openssl.cnf
        rm -f $PREFIX/etc/bash.bashrc
        rm -f $PREFIX/etc/unbound/unbound.conf
        rm -f $PREFIX/etc/profile.d/init-termux-properties.sh
        rm -f $PREFIX/etc/motd

        # 创建标记文件（空文件即可）
        touch "$FLAG_FILE"
        echo "首次执行：已删除文件，并创建标记文件。"
    else
        echo "跳过删除：命令已执行过（标记文件存在）。"
    fi
    
    # 换源加速
    sed -i 's@^\(deb.*stable main\)$@#\1\ndeb https://mirrors.bfsu.edu.cn/termux/termux-packages-24 stable main@' $PREFIX/etc/apt/sources.list && \
    apt update && apt upgrade -y -o Dpkg::Options::="--force-confnew"

    # 包安装检查函数
    pkg_install_check() {
        if pkg list-installed | grep -q "^$1 "; then
            echo "$1 已存在，跳过安装"
            return 0
        else
            if pkg install -y $1; then
                return 0
            else
                echo "$1 安装失败!"
                return 1
            fi
        fi
    }

    # 安装必要包
    required_pkgs=(android-tools termux-api)
    for pkg in ${required_pkgs[@]}; do
        if ! pkg_install_check $pkg; then
            echo "存在依赖安装失败，请检查网络后重试"
            exit 1
        fi
    done
}

# 免Root模式USB连接功能
non_root_usb_connection() {
    echo -e "${CYAN}[+] USB连接模式${NC}"
    
    # 获取设备列表
    echo -e "\n${GREEN}正在检测USB设备...${NC}"
    termux-usb -l

    # 用户输入设备路径
    echo -e "\n${YELLOW}请手动输入设备路径（例如 /dev/bus/usb/001/002）：${NC}"
    read -p "输入设备路径: " device_path

    # 验证输入格式
    if [[ ! "$device_path" =~ ^/dev/bus/usb/[0-9]{3}/[0-9]{3}$ ]]; then
        echo -e "${RED}错误：设备路径格式无效！正确示例：/dev/bus/usb/001/002${NC}"
        return 1
    fi

    # 执行连接命令
    echo -e "\n${GREEN}出现弹窗，请点击确定允许！(然后重新执行脚本，选择两次2即可进入功能菜单)${NC}"
    if termux-usb -r -e $SHELL -E "$device_path"; then
        echo -e "${GREEN}[√] 连接设备成功！${NC}"
        return 0
    else
        echo -e "${RED}[×] 连接设备失败！${NC}"
        return 1
    fi
}

# 免Root模式验证fastboot连接
non_root_verify_connection() {
    if ! fastboot devices | grep -q "fastboot"; then
        echo -e "${RED}[×] 设备未连接！请检查："
        echo -e "   1. USB线连接状态\n   2. fastboot模式已启用\n   3. Termux USB权限已授权${NC}"
        return 1
    fi
    return 0
}

# 免Root模式检查设备连接状态
non_root_check_device_connection() {
    echo -e "${YELLOW}[!] 检查设备连接状态...${NC}"
    local result=$(timeout 5s fastboot getvar current-slot 2>&1)
    
    if echo "$result" | grep -q "waiting for any device"; then
        echo -e "${RED}[!] 设备连接已断开${NC}"
        return 1
    elif echo "$result" | grep -q "current-slot"; then
        echo -e "${GREEN}[√] 设备连接正常${NC}"
        return 0
    else
        echo -e "${YELLOW}[!] 无法确定设备状态，可能设备不支持current-slot参数${NC}"
        # 尝试使用其他方法检查
        if fastboot devices | grep -q "fastboot"; then
            echo -e "${GREEN}[√] 设备连接正常（通过fastboot devices确认）${NC}"
            return 0
        else
            echo -e "${RED}[!] 设备连接已断开${NC}"
            return 1
        fi
    fi
}

# 免Root模式执行线刷脚本
non_root_execute_flash_script() {
    echo -e "${CYAN}[+] 线刷模式启动...${NC}"
    read -p "输入线刷脚本路径（如/sdcard/flash_all.sh）：" script_path
    
    if [[ ! -f $script_path ]]; then
        echo -e "${RED}[×] 错误：脚本不存在！请检查："
        echo -e "   1. 存储权限已开启（termux-setup-storage）\n   2. 文件扩展名为.sh${NC}"
        return 1
    fi
    
    chmod +x "$script_path"
    echo -e "${YELLOW}[!] 正在执行：$script_path${NC}"
    if bash "$script_path"; then
        echo -e "${GREEN}[√] 线刷完成！建议执行：fastboot reboot bootloader${NC}"
    else
        echo -e "${RED}[×] 执行失败！可能原因："
        echo -e "   1. 设备未进入fastbootd模式\n   2. 脚本包含不兼容命令${NC}"
        return 1
    fi
    return 0
}

# 免Root模式自定义命令模式
non_root_custom_command() {
    echo -e "${CYAN}[+] 自定义命令模式${NC}"
    echo -e "支持格式示例：\n  ${BLUE}reboot bootloader\n  erase userdata\n  flash recovery recovery.img${NC}"
    read -p "输入fastboot子命令（无需前缀）：" cmd

    filtered_cmd=$(echo "$cmd" | sed 's/^fastboot\s*//; s/[;&|]//g')
    [[ -z $filtered_cmd ]] && {
        echo -e "${RED}[×] 命令不能为空！${NC}"
        return 1
    }
    
    echo -e "${YELLOW}[!] 正在执行：fastboot $filtered_cmd${NC}"
    if fastboot $filtered_cmd; then
        echo -e "${GREEN}[√] 命令执行成功${NC}"
        return 0
    else
        echo -e "${RED}[×] 失败！错误码：$?\n提示：检查命令语法和设备状态${NC}"
        return 1
    fi
}

# 免Root模式Fastboot功能菜单
non_root_fastboot_menu() {
    while true; do
        clear
        echo -e "${BLUE}===== FASTBOOT全功能菜单 =====${NC}"
        
        read -p $'1) 解锁Bootloader      2) 刷入boot分区
3) 刷入init_boot分区    4) 刷入Recovery镜像
5) 临时启动Recovery     6) 小米线刷功能
7) 自定义命令模式       8) 系统状态管理
9) 重启控制            10) 结束脚本
\033[36m请选择功能 [1-10]: \033[0m' choice

        case $choice in
            1)
                # 检查设备连接
                if ! non_root_check_device_connection; then
                    echo -e "${RED}[!] 设备连接已断开，脚本将退出${NC}"
                    exit 1
                fi
                
                echo -e "${RED}[!] 此操作会清除所有数据！${NC}"
                read -p "确认解锁？(y/N): " confirm
                if [[ $confirm == "y" || $confirm == "Y" ]]; then
                    if fastboot flashing unlock; then
                        echo -e "${GREEN}[√] 解锁成功，设备将重启${NC}"
                        fastboot reboot
                    else
                        echo -e "${RED}[×] 解锁失败！请检查："
                        echo -e "   1. OEM解锁已开启\n   2. 设备处于fastbootd模式${NC}"
                    fi
                fi
                ;;
            2)
                # 检查设备连接
                if ! non_root_check_device_connection; then
                    echo -e "${RED}[!] 设备连接已断开，脚本将退出${NC}"
                    exit 1
                fi
                
                read -p "输入boot镜像路径：" path
                if [[ -f $path ]]; then
                    fastboot flash boot "$path" && echo -e "${GREEN}[√] boot分区刷写成功${NC}"
                else
                    echo -e "${RED}[×] 文件不存在！${NC}"
                fi
                ;;
            3)
                # 检查设备连接
                if ! non_root_check_device_connection; then
                    echo -e "${RED}[!] 设备连接已断开，脚本将退出${NC}"
                    exit 1
                fi
                
                read -p "输入init_boot镜像路径：" path
                if [[ -f $path ]]; then
                    fastboot flash init_boot "$path" && echo -e "${GREEN}[√] init_boot分区刷写成功${NC}"
                else
                    echo -e "${RED}[×] 仅支持Android13+设备！${NC}"
                fi
                ;;
            4)
                # 检查设备连接
                if ! non_root_check_device_connection; then
                    echo -e "${RED}[!] 设备连接已断开，脚本将退出${NC}"
                    exit 1
                fi
                
                read -p "输入Recovery镜像路径：" path
                if [[ -f $path ]]; then
                    fastboot flash recovery "$path" && echo -e "${GREEN}[√] Recovery镜像刷写成功${NC}"
                else
                    echo -e "${RED}[×] 路径错误！${NC}"
                fi
                ;;
            5)
                # 检查设备连接
                if ! non_root_check_device_connection; then
                    echo -e "${RED}[!] 设备连接已断开，脚本将退出${NC}"
                    exit 1
                fi
                
                read -p "输入Recovery镜像路径：" path
                if [[ -f $path ]]; then
                    fastboot boot "$path" && echo -e "${GREEN}[√] 临时启动成功${NC}"
                else
                    echo -e "${RED}[×] 镜像验证失败！${NC}"
                fi
                ;;
            6)
                # 检查设备连接
                if ! non_root_check_device_connection; then
                    echo -e "${RED}[!] 设备连接已断开，脚本将退出${NC}"
                    exit 1
                fi
                
                non_root_execute_flash_script
                ;;
            7)
                # 检查设备连接
                if ! non_root_check_device_connection; then
                    echo -e "${RED}[!] 设备连接已断开，脚本将退出${NC}"
                    exit 1
                fi
                
                non_root_custom_command
                ;;
            8)
                # 检查设备连接
                if ! non_root_check_device_connection; then
                    echo -e "${RED}[!] 设备连接已断开，脚本将退出${NC}"
                    exit 1
                fi
                
                # 使用fastboot getvar all获取全部信息
                device_info=$(fastboot getvar all 2>&1)
                
                # 提取当前分区状态
                current_slot=$(echo "$device_info" | grep -E 'current-slot:' | awk -F: '{print $2}' | tr -d ' ')
                
                # 提取解锁状态（兼容不同设备变量名）
                secure_state=$(echo "$device_info" | grep -E 'unlocked:|device unlocked:' | awk -F: '{print $2}' | tr -d ' ')
                
                # 格式化输出
                echo -e "${CYAN}[状态] 当前分区：${current_slot:-N/A} | 解锁状态：${secure_state:-未知}${NC}"
                ;;
            9)
                # 检查设备连接
                if ! non_root_check_device_connection; then
                    echo -e "${RED}[!] 设备连接已断开，脚本将退出${NC}"
                    exit 1
                fi
                
                echo -e "\n${CYAN}[重启选项]"
                read -p "1) 普通重启  2) Recovery  3) Bootloader
请选择模式：" mode
                case $mode in
                    1) fastboot reboot ;;
                    2) fastboot reboot recovery ;;
                    3) fastboot reboot bootloader ;;
                esac
                ;;
            10)
                echo -e "${YELLOW}正在结束脚本...${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}[!] 无效选项${NC}"
                ;;
        esac
        
        read -p "按 Enter 继续操作..."
    done
}

# Root模式运行函数（保持不变）
run_root_mode() {
    # 以下是原有的所有代码，保持不变
    # 定义日志文件路径
    LOG_FILE="$HOME/storage_permission.log"
    
    # 检查日志文件是否存在
    if [ -f "$LOG_FILE" ]; then
        echo "存储权限已配置，跳过授权步骤"
    else
        echo "正在请求存储权限..."
        termux-setup-storage
        
        echo "记录存储权限状态..."
        ls -l ~/storage > "$LOG_FILE" 2>&1
        echo "权限状态已保存至: $LOG_FILE"
    fi
    
    # 记录存储目录权限
    echo -e "\033[36m[步骤2]\033[0m 生成存储目录权限日志..."
    ls -l ~/storage > "$LOG_FILE" 2>&1
    
    # 验证日志创建结果
    if [ -f "$LOG_FILE" ]; then
        echo -e "\033[32m[完成]\033[0m 日志文件创建成功：$LOG_FILE"
        echo -e "\033[32m[状态]\033[0m 存储权限状态已记录"
    else
        echo -e "\033[31m[错误]\033[0m 日志文件创建失败！" >&2
        exit 2
    fi
    
    # 定义标记文件路径（确保路径可写）
    FLAG_FILE="$PREFIX/.rm_commands_done.flag"
    
    # 检查标记文件是否存在
    if [ ! -f "$FLAG_FILE" ]; then
      # 首次执行：删除目标文件
      rm -f $PREFIX/etc/tls/openssl.cnf
      rm -f $PREFIX/etc/bash.bashrc
      rm -f $PREFIX/etc/unbound/unbound.conf
      rm -f $PREFIX/etc/profile.d/init-termux-properties.sh
      rm -f $PREFIX/etc/motd
    
      # 创建标记文件（空文件即可）
      touch "$FLAG_FILE"
      echo "首次执行：已删除文件，并创建标记文件。"
    else
      echo "跳过删除：命令已执行过（标记文件存在）。"
    fi
    
    configure_source() {
        if ! grep -q "mirrors.tuna.tsinghua.edu.cn" $PREFIX/etc/apt/sources.list; then
    sed -i 's@^\(deb.*stable main\)$@#\1\ndeb https://mirrors.bfsu.edu.cn/termux/termux-packages-24 stable main@' $PREFIX/etc/apt/sources.list && \
    apt update && apt upgrade -y -o Dpkg::Options::="--force-confnew"
        fi
    }
    
    install_dependencies() {
        pkg_list=("android-tools" "sudo")
        for pkg in "${pkg_list[@]}"; do
            ! pkg list-installed | grep -q $pkg && pkg install $pkg -y
        done
    }
    
    execute_flash_script() {
        # 新增小米线刷功能[1,3](@ref)
        echo -e "\033[36m[+] 小米线刷模式启动..."
        read -p "输入线刷脚本路径（如/sdcard/xiaomi_flash.sh）：" script_path
        
        if [ ! -f "$script_path" ]; then
            echo -e "\033[31m[×] 错误：脚本不存在！请检查："
            echo -e "   1. 使用绝对路径\n   2. 确认文件后缀为.sh\033[0m"
            return 1
        fi
        
        chmod +x "$script_path"
        echo -e "\033[33m[!] 正在执行：$script_path"
        if sudo bash "$script_path"; then
            echo -e "\033[32m[√] 线刷完成！建议执行：fastboot reboot bootloader"
        else
            echo -e "\033[31m[×] 执行失败！可能原因："
            echo -e "   1. 脚本需要root权限\n   2. 设备未进入fastbootd模式"
        fi
    }
    
    custom_command() {
        echo -e "\033[36m[+] 自定义命令模式"
        echo -e "支持格式示例：\nreboot bootloader\nerase userdata\nflash recovery recovery.img"
        read -p "输入fastboot子命令（无需输入'sudo'或'fastboot'前缀）：" cmd
    
        # 过滤命令前缀
        filtered_cmd=$(echo "$cmd" | sed 's/^sudo\s*//; s/^fastboot\s*//; s/^\s*//')
        
        if [[ -z $filtered_cmd ]]; then
            echo -e "\033[31m[×] 命令不能为空！"
            return
        fi
        
        echo -e "\033[33m[!] 正在执行：sudo fastboot $filtered_cmd"
        if sudo fastboot $filtered_cmd; then
            echo -e "\033[32m[√] 命令执行成功"
        else
            echo -e "\033[31m[×] 执行失败！错误码：$?"
            echo -e "提示：请直接输入fastboot子命令，例如：reboot 或 flash boot boot.img"
        fi
    }
    
    root_fastboot() {
        # 权限验证[6,8](@ref)
        if ! sudo -v; then
            echo -e "\033[31m[×] 需要配置sudo权限："
            echo -e "   1. 执行 'sudo visudo' 添加：$(whoami) ALL=(ALL) NOPASSWD:ALL"
            exit 1
        fi
    
        # 主循环
        while true; do
            # 设备检测[2,5](@ref)
            devices=$(sudo fastboot devices 2>&1)
            if ! echo "$devices" | grep -q "fastboot"; then
                echo -e "\033[31m[!] 设备未连接！请检查："
                echo -e "   1. 设备已进入fastboot模式（LED灯闪烁）"
                echo -e "   2. USB线连接稳定（推荐原装线）\033[0m"
                echo -e "\033[33m[!] 按回车键返回菜单重新检测，或输入'exit'退出...\033[0m"
                read -p "请输入: " input
                if [ "$input" = "exit" ]; then
                    exit 1
                fi
                continue
            fi
    
            # 增强功能菜单[1,4](@ref)
            clear
            echo -e "\033[1;36m===== FASTBOOT全功能菜单 =====\033[0m"
            echo "作者酷安by:米粉钉子户1999 
            http://www.coolapk.com/u/6100654
            免费工具，请勿盗卖，倒卖死全家，全家替我挡灾！
            如果你花钱买的，说明你活该被骗，活该被圈钱！"
            echo "1) 解锁Bootloader"
            echo "2) 刷入boot分区"
            echo "3) 刷入init_boot分区"
            echo "4) 刷入Recovery镜像"
            echo "5) 临时启动Recovery"
            echo "6) 小米线刷功能"
            echo "7) 自定义命令模式"
            echo "8) 系统状态管理"
            echo "9) 重启控制"
            echo "10) 退出"
            read -p "请选择功能 [1-10]: " choice
    
            case $choice in
                1)
                    echo -e "\033[31m[!] 此操作会清除所有数据！[1,5](@ref)"
                    read -p "确认解锁？(y/N): " confirm
                    if [[ $confirm == "y" || $confirm == "Y" ]]; then
                        sudo fastboot flashing unlock
                        echo -e "\033[32m[√] Bootloader解锁完成！设备将重启"
                        echo -e "\033[33m[!] 按回车键返回菜单...\033[0m"
                        read
                    fi
                    ;;
                2)
                    read -p "输入boot镜像路径（如/sdcard/boot.img）：" path
                    if [[ -f $path ]]; then
                        sudo fastboot flash boot "$path"
                        echo -e "\033[32m[√] boot分区刷入完成！"
                    else
                        echo -e "\033[31m[×] 文件不存在！\033[0m"
                    fi
                    echo -e "\033[33m[!] 按回车键返回菜单...\033[0m"
                    read
                    ;;
                3)
                    read -p "输入init_boot镜像路径：" path
                    if [[ -f $path ]]; then
                        sudo fastboot flash init_boot "$path"
                        echo -e "\033[32m[√] init_boot分区刷入完成！"
                    else
                        echo -e "\033[31m[×] 文件不存在或仅支持Android13+设备！\033[0m"
                    fi
                    echo -e "\033[33m[!] 按回车键返回菜单...\033[0m"
                    read
                    ;;
                4)
                    read -p "输入Recovery镜像路径：" path
                    if [[ -f $path ]]; then
                        sudo fastboot flash recovery "$path"
                        echo -e "\033[32m[√] Recovery刷入完成！"
                    else
                        echo -e "\033[31m[×] 路径错误！\033[0m"
                    fi
                    echo -e "\033[33m[!] 按回车键返回菜单...\033[0m"
                    read
                    ;;
                5)
                    read -p "输入Recovery镜像路径：" path
                    if [[ -f $path ]]; then
                        sudo fastboot boot "$path"
                        echo -e "\033[32m[√] 临时启动Recovery完成！"
                    else
                        echo -e "\033[31m[×] 镜像验证失败！\033[0m"
                    fi
                    echo -e "\033[33m[!] 按回车键返回菜单...\033[0m"
                    read
                    ;;
                6)
                    execute_flash_script
                    echo -e "\033[33m[!] 按回车键返回菜单...\033[0m"
                    read
                    ;;
                7)
                    custom_command
                    echo -e "\033[33m[!] 按回车键返回菜单...\033[0m"
                    read
                    ;;
                8)
                    current_slot=$(sudo fastboot getvar current-slot 2>&1 | awk -F: '/current-slot/{print $2}')
                    echo -e "\033[34m[!] 当前系统分区：${current_slot:-不支持A/B分区}"
                    sudo fastboot getvar all | grep -E 'unlocked|secure'
                    echo -e "\033[33m[!] 按回车键返回菜单...\033[0m"
                    read
                    ;;
                9)
                    echo -e "\033[34m[!] 重启选项："
                    echo "1) 普通重启  2) Recovery  3) Bootloader"
                    read -p "选择模式[1-3]：" mode
                    case $mode in
                        1) 
                            sudo fastboot reboot
                            echo -e "\033[32m[√] 设备正在重启..."
                            sleep 3
                            ;;
                        2) 
                            sudo fastboot reboot recovery
                            echo -e "\033[32m[√] 设备正在重启到Recovery..."
                            sleep 3
                            ;;
                        3) 
                            sudo fastboot reboot bootloader
                            echo -e "\033[32m[√] 设备正在重启到Bootloader..."
                            sleep 3
                            ;;
                        *)
                            echo -e "\033[31m[×] 无效选项\033[0m"
                            ;;
                    esac
                    # 重启后需要重新检测设备
                    echo -e "\033[33m[!] 设备已重启，请等待设备重新进入fastboot模式后按回车键继续...\033[0m"
                    read
                    ;;
                10)
                    echo -e "\033[32m[√] 退出FASTBOOT工具箱"
                    exit 0
                    ;;
                *)
                    echo -e "\033[31m[!] 无效选项\033[0m"
                    echo -e "\033[33m[!] 按回车键返回菜单...\033[0m"
                    read
                    ;;
            esac
        done
    }
    
    # 主流程
    configure_source
    install_dependencies
    root_fastboot
}

# 启动主菜单
show_main_menu
