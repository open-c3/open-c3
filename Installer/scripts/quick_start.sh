#!/usr/bin/env bash

# 颜色提示函数
red() { echo -e "\033[31m$1\033[0m"; }
green() { echo -e "\033[32m$1\033[0m"; }

# 判断网络环境
check_network() {
    if curl -s --max-time 3 https://www.google.com >/dev/null; then
        echo "overseas"
    elif curl -s --max-time 3 https://www.baidu.com >/dev/null; then
        echo "china"
    else
        echo "unknown"
    fi
}

# 判断系统类型
check_os() {
    unameOut="$(uname -s)"
    case "${unameOut}" in
        Linux*)     echo "linux";;
        Darwin*)    echo "macos";;
        *)          echo "unknown";;
    esac
}

OS=$(check_os)
NETWORK=$(check_network)

if [[ "$NETWORK" == "overseas" ]]; then
    green "🌍 检测到为【海外环境】。"
elif [[ "$NETWORK" == "china" ]]; then
    green "🌏 检测到为【国内环境】。"
else
    red "❌ 无法判断网络环境，请检查网络连接。"
    exit 1
fi

# 检查并安装 Git
if ! command -v git &>/dev/null; then
    red "🔧 Git 未安装，尝试自动安装 Git..."

    if [[ "$OS" == "linux" ]]; then
        if command -v apt &>/dev/null; then
            apt update && apt install -y git
        elif command -v dnf &>/dev/null; then
            dnf install -y git
        elif command -v yum &>/dev/null; then
            yum install -y git
        else
            red "❌ 无法识别 Linux 包管理器，Git 安装失败。"
            exit 1
        fi
    elif [[ "$OS" == "macos" ]]; then
        if command -v brew &>/dev/null; then
            brew install git
        else
            red "❌ macOS 未检测到 Homebrew，请先安装 Homebrew："
            echo '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
            exit 1
        fi
    else
        red "❌ 未知系统，无法自动安装 Git。"
        exit 1
    fi

    if ! command -v git &>/dev/null; then
        red "❌ Git 安装失败，请手动检查。"
        exit 1
    fi

    green "✅ Git 安装成功。"
else
    green "✅ Git 已安装。"
fi

# 检查并安装 Docker（仅限 Linux）
if [[ "$OS" == "linux" ]]; then
    if ! command -v docker &>/dev/null; then
        red "🔧 Docker 未安装，开始自动安装 Docker..."

        if [[ "$NETWORK" == "china" ]]; then
            curl -fsSL https://get.daocloud.io/docker | bash
        else
            curl -fsSL https://get.docker.com | bash
        fi

        systemctl enable docker
        systemctl start docker

        sleep 3

        if ! command -v docker &>/dev/null; then
            red "❌ Docker 安装失败，请手动检查网络或权限问题。"
            exit 1
        fi
        green "✅ Docker 安装成功。"
    else
        green "✅ Docker 已安装。"
    fi

    # 拉取 Docker 镜像测试
    echo "🔍 正在测试是否可以拉取 Docker 镜像 openc3/pkg-book:latest ..."
    if docker pull openc3/pkg-book:latest &>/dev/null; then
        green "✅ Docker 镜像拉取成功，网络正常。"
    else
        red "❌ 无法拉取 Docker 镜像 openc3/pkg-book:latest。"
        red "请检查你的网络是否可以访问 Docker Hub，或配置国内镜像源。"
        exit 1
    fi
else
    green "💡 当前系统为 macOS，请确保已安装 Docker Desktop。"
fi

# 安装 Open-C3
if [[ "$NETWORK" == "china" ]]; then
    green "📦 使用 Gitee 安装 Open-C3..."
    curl https://gitee.com/open-c3/open-c3/raw/v2.6.1/Installer/scripts/single.sh | OPENC3VERSION=v2.6.1 OPENC3_ZONE=CN bash -s install 10.10.10.10
else
    green "📦 使用 GitHub 安装 Open-C3..."
    curl https://raw.githubusercontent.com/open-c3/open-c3/v2.6.1/Installer/scripts/single.sh | OPENC3VERSION=v2.6.1 bash -s install 10.10.10.10
fi

