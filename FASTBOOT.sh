#!/data/data/com.termux/files/usr/bin/bash
# Termux环境Fastboot工具（增强版：支持线刷&自定义命令）

termux-setup-storage

configure_source() {
    if ! grep -q "mirrors.tuna.tsinghua.edu.cn" $PREFIX/etc/apt/sources.list; then
        sed -i 's@^\(deb.*stable main\)$@#\1\ndeb https://mirrors.tuna.tsinghua.edu.cn/termux/termux-packages-24 stable main@' $PREFIX/etc/apt/sources.list
        apt update && apt upgrade -y
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
        echo -e "提示：请直接输入fastboot子命令，例如：reboot 或 flash boot boot.img"  # 新增错误提示
    fi
}

root_fastboot() {
    # 权限验证[6,8](@ref)
    if ! sudo -v; then
        echo -e "\033[31m[×] 需要配置sudo权限："
        echo -e "   1. 执行 'sudo visudo' 添加：$(whoami) ALL=(ALL) NOPASSWD:ALL"
        exit 1
    fi

    # 设备检测[2,5](@ref)
    devices=$(sudo fastboot devices 2>&1)
    if ! echo "$devices" | grep -q "fastboot"; then
        echo -e "\033[31m[!] 设备未连接！请检查："
        echo -e "   1. 设备已进入fastboot模式（LED灯闪烁）"
        echo -e "   2. USB线连接稳定（推荐原装线）\033[0m"
        exit 1
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
            read -p "确认解锁？(y/N)" confirm
            [[ $confirm == "y" ]] && sudo fastboot flashing unlock
            ;;
        2)
            read -p "输入boot镜像路径（如/sdcard/boot.img）：" path
            [[ -f $path ]] && sudo fastboot flash boot "$path" || echo -e "\033[31m[×] 文件不存在！\033[0m"
            ;;
        3)
            read -p "输入init_boot镜像路径：" path
            [[ -f $path ]] && sudo fastboot flash init_boot "$path" || echo -e "\033[31m[×] 仅支持Android13+设备！\033[0m"
            ;;
        4)
            read -p "输入Recovery镜像路径：" path
            [[ -f $path ]] && sudo fastboot flash recovery "$path" || echo -e "\033[31m[×] 路径错误！\033[0m"
            ;;
        5)
            read -p "输入Recovery镜像路径：" path
            [[ -f $path ]] && sudo fastboot boot "$path" || echo -e "\033[31m[×] 镜像验证失败！\033[0m"
            ;;
        6)
            execute_flash_script
            ;;
        7)
            custom_command
            ;;
        8)
            current_slot=$(sudo fastboot getvar current-slot 2>&1 | awk -F: '/current-slot/{print $2}')
            echo -e "\033[34m[!] 当前系统分区：${current_slot:-不支持A/B分区}"
            sudo fastboot getvar all | grep -E 'unlocked|secure'
            ;;
        9)
            echo -e "\033[34m[!] 重启选项："
            echo "1) 普通重启  2) Recovery  3) Bootloader"
            read -p "选择模式[1-3]：" mode
            case $mode in
                1) sudo fastboot reboot ;;
                2) sudo fastboot reboot recovery ;;
                3) sudo fastboot reboot bootloader
            esac
            ;;
        10)
            exit 0
            ;;
        *)
            echo -e "\033[31m[!] 无效选项\033[0m"
            ;;
    esac
}

# 主流程
configure_source
install_dependencies
root_fastboot
