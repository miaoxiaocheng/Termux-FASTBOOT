#!/bin/bash

# 定义颜色变量（加粗高亮版本）
RED='\033[31;1m'
GREEN='\033[32;1m'
YELLOW='\033[33;1m'
BLUE='\033[34;1m'
CYAN='\033[36;1m'
NC='\033[0m'  # 重置颜色

show_menu() {
    clear
    echo -e "${BLUE}===== 免root FASTBOOT全功能菜单 =====${NC}"
    echo -e "${YELLOW}作者酷安by:米粉钉子户1999 
    http://www.coolapk.com/u/6100654
    免费工具，请勿盗卖，倒卖死全家，全家替我挡灾！
    如果你花钱买的，说明你活该被骗，活该被圈钱！${YELLOW}"
    echo -e "${RED}1) ${GREEN}连接设备${NC}"
    echo -e "${CYAN}2) ${GREEN}fastBoot功能${NC}"
    echo -e "${YELLOW}3) ${GREEN}退出${NC}"
}

while true; do
    show_menu
    read -p "请输入选项编号 (1-3): " choice
    
    case $choice in
        1)
            echo -e "${BLUE}正在连接设备...${NC}"
            bash -c "$(curl -sL https://raw.githubusercontent.com/miaoxiaocheng/Termux-FASTBOOT/main/USB.sh)"
            read -n 1 -s -r -p "按任意键返回菜单..."
            ;;
        2)
            echo -e "${CYAN}进入fastBoot功能...${NC}"
            bash -c "$(curl -sL https://raw.githubusercontent.com/miaoxiaocheng/Termux-FASTBOOT/main/FASTBOOT2.sh)"
            read -n 1 -s -r -p "按任意键返回菜单..."
            ;;
        3)
            echo -e "${YELLOW}正在退出...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}无效的选项，请重新输入！${NC}"
            sleep 1
            ;;
    esac
done
