#!/data/data/com.termux/files/usr/bin/bash
# Termux免Root版Fastboot工具（全功能版）

RED='\033[31;1m'
GREEN='\033[32;1m'
YELLOW='\033[33;1m'
BLUE='\033[34;1m'
CYAN='\033[36;1m'
NC='\033[0m' # 重置颜色

verify_connection() {
    if ! fastboot devices | grep -q "fastboot"; then
        echo -e "${RED}[×] 设备未连接！请检查："
        echo -e "   1. USB线连接状态\n   2. fastboot模式已启用\n   3. Termux USB权限已授权${NC}"
        exit 1
    fi
}

execute_flash_script() {
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
    fi
}

custom_command() {
    echo -e "${CYAN}[+] 自定义命令模式${NC}"
    echo -e "支持格式示例：\n  ${BLUE}reboot bootloader\n  erase userdata\n  flash recovery recovery.img${NC}"
    read -p "输入fastboot子命令（无需前缀）：" cmd

    filtered_cmd=$(echo "$cmd" | sed 's/^fastboot\s*//; s/[;&|]//g')
    [[ -z $filtered_cmd ]] && {
        echo -e "${RED}[×] 命令不能为空！${NC}"
        return
    }
    
    echo -e "${YELLOW}[!] 正在执行：fastboot $filtered_cmd${NC}"
    if fastboot $filtered_cmd; then
        echo -e "${GREEN}[√] 命令执行成功${NC}"
    else
        echo -e "${RED}[×] 失败！错误码：$?\n提示：检查命令语法和设备状态${NC}"
    fi
}

main_menu() {
    clear
    # 使用read -p实现多行彩色菜单[6,7](@ref)
    read -p $'\033[34m===== FASTBOOT全功能菜单 =====
1) 解锁Bootloader      2) 刷入boot分区
3) 刷入init_boot分区    4) 刷入Recovery镜像
5) 临时启动Recovery     6) 小米线刷功能
7) 自定义命令模式       8) 系统状态管理
9) 重启控制            10) 退出
\033[36m请选择功能 [1-10]: \033[0m' choice

    case $choice in
        1)
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
            read -p "输入boot镜像路径：" path
            if [[ -f $path ]]; then
                fastboot flash boot "$path" && echo -e "${GREEN}[√] boot分区刷写成功${NC}"
            else
                echo -e "${RED}[×] 文件不存在！${NC}"
            fi
            ;;
        3)
            read -p "输入init_boot镜像路径：" path
            if [[ -f $path ]]; then
                fastboot flash init_boot "$path" && echo -e "${GREEN}[√] init_boot分区刷写成功${NC}"
            else
                echo -e "${RED}[×] 仅支持Android13+设备！${NC}"
            fi
            ;;
        4)
            read -p "输入Recovery镜像路径：" path
            if [[ -f $path ]]; then
                fastboot flash recovery "$path" && echo -e "${GREEN}[√] Recovery镜像刷写成功${NC}"
            else
                echo -e "${RED}[×] 路径错误！${NC}"
            fi
            ;;
        5)
            read -p "输入Recovery镜像路径：" path
            if [[ -f $path ]]; then
                fastboot boot "$path" && echo -e "${GREEN}[√] 临时启动成功${NC}"
            else
                echo -e "${RED}[×] 镜像验证失败！${NC}"
            fi
            ;;
        6) execute_flash_script ;;
        7) custom_command ;;
        8)
    # 使用fastboot getvar all获取全部信息[3,11](@ref)
    device_info=$(fastboot getvar all 2>&1)
    
    # 提取当前分区状态
    current_slot=$(echo "$device_info" | grep -E 'current-slot:' | awk -F: '{print $2}' | tr -d ' ')
    
    # 提取解锁状态（兼容不同设备变量名）
    secure_state=$(echo "$device_info" | grep -E 'unlocked:|device unlocked:' | awk -F: '{print $2}' | tr -d ' ')
    
    # 格式化输出[8](@ref)
    read -p "${CYAN}[状态] 当前分区：${current_slot:-N/A} | 解锁状态：${secure_state:-未知}${NC}"
            ;;
        9)
            echo -e "\n${CYAN}[重启选项]"
            read -p "1) 普通重启  2) Recovery  3) Bootloader
请选择模式：" mode
            case $mode in
                1) fastboot reboot ;;
                2) fastboot reboot recovery ;;
                3) fastboot reboot bootloader ;;
            esac
            ;;
        10) exit 0 ;;
        *) echo -e "${RED}[!] 无效选项${NC}" ;;
    esac
}

# 主流程
verify_connection
while true; do
    main_menu
    read -p "按 Enter 继续操作..."
done
