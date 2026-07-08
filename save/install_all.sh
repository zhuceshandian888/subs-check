#!/data/data/com.termux/files/usr/bin/bash
# subs-check 整合版安装 + 自动启动脚本

WORKDIR=$HOME/subs-check

# 1. 更新 Termux 包管理器
pkg update -y
pkg upgrade -y

# 2. 安装必要依赖
pkg install -y curl wget unzip git python

# 3. 创建工作目录并下载项目
if [ ! -d "$WORKDIR/.git" ]; then
    mkdir -p $WORKDIR
    cd $WORKDIR
    git clone https://github.com/beck-8/subs-check.git .
else
    cd $WORKDIR
    git pull
fi

# 4. 安装 Python 依赖（用户目录）
pip install --user -r requirements.txt

# 5. 创建自动启动脚本 subs-check
LAUNCHER=$HOME/subs-check
cat > $LAUNCHER << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
WORKDIR=$HOME/subs-check
if [ ! -d "$WORKDIR" ]; then
    echo "❌ subs-check 未安装，请先运行 install_all.sh"
    exit 1
fi
cd $WORKDIR
python main.py "$@"
EOF

chmod +x $LAUNCHER

# 6. 将 HOME 加入 PATH（避免重复写入）
if ! grep -q 'export PATH=$PATH:$HOME' ~/.bashrc; then
    echo 'export PATH=$PATH:$HOME' >> ~/.bashrc
fi
source ~/.bashrc

# 7. 完成提示
echo "✅ subs-check 已安装并配置完成！"
echo "现在你可以直接运行： subs-check"