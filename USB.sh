#!/data/data/com.termux/files/usr/bin/bash
# 定义日志文件路径
LOG_FILE="$HOME/storage_permission.log"

# 检查日志文件是否存在
if [ -f "$LOG_FILE" ]; then
    echo "日志文件已存在 ($LOG_FILE)，无需重复执行权限申请。"
    exit 0
fi

# 申请存储权限
echo "正在申请Termux存储权限..."
termux-setup-storage

# 检查~/storage目录权限并输出日志
echo "正在记录存储目录权限状态..."
ls -l $HOME/storage > "$LOG_FILE" 2>&1

# 验证操作结果
if [ $? -eq 0 ]; then
    echo "权限申请成功！日志已保存至: $LOG_FILE"
    echo "目录权限详情："
    cat "$LOG_FILE"
else
    echo "错误：权限记录失败，请检查Termux存储授权状态！" >&2
    exit 1
fi

# 定义标记文件路径（确保路径可写）
FLAG_FILE="$PREFIX/.rm_commands_done.flag"

# 检查标记文件是否存在
if [ ! -f "$FLAG_FILE" ]; then
  # 首次执行：删除目标文件
  rm -f $PREFIX/etc/tls/openssl.cnf
  rm -f $PREFIX/etc/bash.bashrc

  # 创建标记文件（空文件即可）
  touch "$FLAG_FILE"
  echo "首次执行：已删除文件，并创建标记文件。"
else
  echo "跳过删除：命令已执行过（标记文件存在）。"
fi
# 换源加速
sed -i 's@^\(deb.*stable main\)$@#\1\ndeb https://mirrors.bfsu.edu.cn/termux/termux-packages-24 stable main@' $PREFIX/etc/apt/sources.list && \
apt update && apt upgrade -y

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

# 获取设备列表（用户确认此部分正常，无需修改）
echo -e "\n\033[32m正在检测USB设备...\033[0m"
termux-usb -l

# 用户输入设备路径（保留路径格式校验）
echo -e "\n\033[33m请手动输入设备路径（例如 /dev/bus/usb/001/002）：\033[0m"
read -p "输入设备路径: " device_path

# 验证输入格式（严格匹配路径格式）
if [[ ! "$device_path" =~ ^/dev/bus/usb/[0-9]{3}/[0-9]{3}$ ]]; then
    echo -e "\033[31m错误：设备路径格式无效！正确示例：/dev/bus/usb/001/002\033[0m"
    exit 1
fi

# 执行连接命令（直接执行，不检测结果）
echo -e "\n\033[32m出现弹窗，点击确定允许！连接设备成功！请继续输入链接，然后回车，输入2 回车，即可进入fastboot工具箱！\033[0m"
termux-usb -r -e $SHELL -E "$device_path"  # 关键修正点[6,7](@ref)
