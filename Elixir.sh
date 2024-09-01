#!/bin/bash

# 检查脚本是否以root权限运行
if [ "$(id -u)" != "0" ]; then
    echo "请以root权限运行此脚本。"
    echo "使用 'sudo -i' 切换到root用户后重试。"
    exit 1
fi

# 定义脚本保存路径
SCRIPT_PATH="$HOME/ElixirV3.sh"

# 检查并安装Docker
function ensure_docker_installed() {
    if ! command -v docker &> /dev/null; then
        echo "Docker未检测到，正在安装..."
        sudo apt-get update
        sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        sudo apt-get update
        sudo apt-get install -y docker-ce
        echo "Docker已成功安装。"
    else
        echo "Docker已安装。"
    fi
}

# 安装节点
function install_validator_node() {
    ensure_docker_installed

    # 获取用户输入的配置参数
    read -p "请输入验证节点的IP地址: " ip_address
    read -p "请输入验证节点的名称: " validator_name
    read -p "请输入奖励收取地址: " beneficiary_address
    read -p "请输入签名者私钥(去掉0x前缀): " private_key

    # 将配置参数保存到 validator.env 文件
    cat <<EOF > validator.env
ENV=testnet-3

STRATEGY_EXECUTOR_IP_ADDRESS=${ip_address}
STRATEGY_EXECUTOR_DISPLAY_NAME=${validator_name}
STRATEGY_EXECUTOR_BENEFICIARY=${beneficiary_address}
SIGNER_PRIVATE_KEY=${private_key}
EOF

    echo "配置已保存至 validator.env 文件。"

    # 拉取 Docker 镜像
    docker pull elixirprotocol/validator:v3

    # 判断用户是否使用Apple/ARM架构
    read -p "是否在Apple/ARM架构上运行？(y/n): " is_arm

    if [[ "$is_arm" == "y" ]]; then
        # 针对Apple/ARM架构的运行选项
        docker run -it -d \
          --env-file validator.env \
          --name elixir \
          --platform linux/amd64 \
          elixirprotocol/validator:v3
    else
        # 默认运行选项
        docker run -it -d \
          --env-file validator.env \
          --name elixir \
          elixirprotocol/validator:v3
    fi
}

# 查看Docker容器日志
function view_docker_logs() {
    echo "正在查看Elixir Docker容器的日志..."
    docker logs -f elixir
}

# 主菜单
function display_main_menu() {
    clear
    echo "===================== Elixir V3 节点管理 ========================="
    echo "请选择需要执行的操作:"
    echo "1. 安装Elixir V3节点"
    echo "2. 查看Docker日志"
    read -p "请输入选项（1-2）: " OPTION

    case $OPTION in
    1) install_validator_node ;;
    2) view_docker_logs ;;
    *) echo "无效的选项。" ;;
    esac
}

# 运行主菜单
display_main_menu
