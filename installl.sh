#!/data/data/com.termux/files/usr/bin/bash
# subs-check 一键安装脚本 (Termux 用户版)
# 用法: bash <(curl -fsSL https://raw.githubusercontent.com/beck-8/subs-check/master/install.sh)

set -e

# ============ 配置 ============
REPO="beck-8/subs-check"
INSTALL_DIR="$HOME/subs-check"
BINARY_NAME="subs-check"
GITHUB_API="https://api.github.com/repos/${REPO}/releases/latest"
GITHUB_PROXY="${1:-}"

# ============ 颜色输出 ============
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info()  { printf "${BLUE}[INFO]${NC} %s\n" "$1"; }
ok()    { printf "${GREEN}[OK]${NC} %s\n" "$1"; }
warn()  { printf "${YELLOW}[WARN]${NC} %s\n" "$1"; }
error() { printf "${RED}[ERROR]${NC} %s\n" "$1"; exit 1; }

# ============ 前置检查 ============
check_os() {
    if [ "$(uname -s)" != "Linux" ]; then
        error "此脚本仅支持 Linux/Android Termux"
    fi
}

check_download_tool() {
    if command -v curl >/dev/null 2>&1; then
        DOWNLOADER="curl"
    elif command -v wget >/dev/null 2>&1; then
        DOWNLOADER="wget"
    else
        error "需要 curl 或 wget，请先安装其中之一"
    fi
}

# ============ 下载封装 ============
download() {
    url="$1"
    output="$2"
    if [ "$DOWNLOADER" = "curl" ]; then
        curl -fsSL -o "$output" "$url"
    else
        wget -qO "$output" "$url"
    fi
}

fetch_url() {
    url="$1"
    if [ "$DOWNLOADER" = "curl" ]; then
        curl -fsSL "$url"
    else
        wget -qO- "$url"
    fi
}

# ============ 架构检测 ============
detect_arch() {
    arch="$(uname -m)"
    case "$arch" in
        x86_64|amd64) ARCH="x86_64" ;;
        aarch64|arm64) ARCH="aarch64" ;;
        armv7*|armhf) ARCH="armv7" ;;
        i386|i686) ARCH="i386" ;;
        *) error "不支持的架构: $arch" ;;
    esac
    ok "检测到系统架构: $ARCH"
}

# ============ 获取最新版本 ============
get_latest_version() {
    info "正在获取最新版本..."
    LATEST_VERSION=$(fetch_url "$GITHUB_API" | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"//;s/".*//')
    if [ -z "$LATEST_VERSION" ]; then
        error "无法获取最新版本号，请检查网络连接"
    fi
    ok "最新版本: $LATEST_VERSION"
}

# ============ 下载并安装 ============
install_binary() {
    FILE_NAME="${BINARY_NAME}_Linux_${ARCH}.tar.gz"
    DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${LATEST_VERSION}/${FILE_NAME}"

    if [ -n "$GITHUB_PROXY" ]; then
        DOWNLOAD_URL="${GITHUB_PROXY}${DOWNLOAD_URL}"
    fi

    TMP_DIR=$(mktemp -d)
    trap 'rm -rf "$TMP_DIR"' EXIT

    info "正在下载 ${FILE_NAME}..."
    download "$DOWNLOAD_URL" "${TMP_DIR}/${FILE_NAME}"
    ok "下载完成"

    mkdir -p "$INSTALL_DIR"
    tar -xzf "${TMP_DIR}/${FILE_NAME}" -C "$INSTALL_DIR"

    chmod +x "${INSTALL_DIR}/${BINARY_NAME}"
    ok "安装完成: ${INSTALL_DIR}/${BINARY_NAME}"

    # 创建启动脚本 subs-check
    LAUNCHER=$HOME/subs-check
    cat > $LAUNCHER << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
WORKDIR=$HOME/subs-check
cd $WORKDIR
./subs-check "$@"
EOF
    chmod +x $LAUNCHER

    # 将 HOME 加入 PATH
    if ! grep -q 'export PATH=$PATH:$HOME' ~/.bashrc; then
        echo 'export PATH=$PATH:$HOME' >> ~/.bashrc
    fi
    source ~/.bashrc

    ok "现在你可以直接运行: subs-check"
}

# ============ 主流程 ============
check_os
check_download_tool
detect_arch
get_latest_version
install_binary