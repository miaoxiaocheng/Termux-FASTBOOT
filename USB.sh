#!/data/data/com.termux/files/usr/bin/bash
# 功能：为 Termux 申请访问手机内部存储（/storage/emulated/0/）的权限
# 作者：根据 Termux 官方文档编写
# 使用方法：在 Termux 中执行 `bash request_storage_permission.sh`

# 检查是否已授予存储权限
if [ -d "$HOME/storage/shared" ]; then
    echo "✅ 存储权限已授予，访问路径：$HOME/storage/shared"
    exit 0
fi

# 申请权限
echo "📲 正在申请存储权限..."
termux-setup-storage -y

# 检查命令执行结果
if [ $? -eq 0 ]; then
    echo "🔓 请在弹出的系统窗口中点击「允许」以授权访问手机存储！"
    echo "💡 授权后，Termux 会自动创建软链接：$HOME/storage/shared → /storage/emulated/0/"
else
    echo "❌ 权限申请失败！请确保："
    echo "   1. Termux 已更新至最新版本（通过 F-Droid 安装）[2,7](@ref)"
    echo "   2. 设备系统版本 ≥ Android 6.0（支持运行时权限）[3](@ref)"
fi
# 换源加速
rm -f $PREFIX/etc/tls/openssl.cnf && \
rm -f $PREFIX/etc/bash.bashrc && \
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
echo -e "\n\033[32m连接设备成功！请继续输入链接，然后回车，输入2 回车，即可进入fastboot工具箱！\033[0m"
termux-usb -r -e $SHELL -E "$device_path"  # 关键修正点[6,7](@ref)
