#!/bin/bash
# 初始化 Agent Profiles
# 用途：在新机器上创建 PM 和 Dispatcher 的 Hermes profile，配置 cron job
# 前提：已安装 Hermes、已配置好 ~/.hermes/config.yaml 和 ~/.hermes/.env
# 环境变量（可选）：
#   HERMES_WORKSPACE — 工作空间路径，默认自动检测
#   GITHUB_USER — GitHub 用户名，默认 liyi828328

set -e

WORKSPACE="${HERMES_WORKSPACE:-$(cd "$(dirname "$0")/../.." && pwd)}"
PROMPTS_DIR="${WORKSPACE}/company/prompts"
SCRIPTS_DIR="${WORKSPACE}/company/scripts"
GITHUB_USER="${GITHUB_USER:-liyi828328}"

echo "=== 初始化 Agent Profiles ==="
echo "工作空间：${WORKSPACE}"

# ===== 前置检查 =====
echo ""
echo "[前置检查]"

check_cmd() {
    if command -v "$1" &>/dev/null; then
        echo "  ✅ $1 已安装"
    else
        echo "  ❌ $1 未安装"
        MISSING=true
    fi
}

MISSING=false
check_cmd hermes
check_cmd gh
check_cmd git
check_cmd ssh

if [ "$MISSING" = true ]; then
    echo ""
    echo "❌ 有缺失的依赖，请先安装后再运行"
    exit 1
fi

# 检查 gh 登录状态
if gh auth status &>/dev/null; then
    echo "  ✅ gh CLI 已登录"
else
    echo "  ❌ gh CLI 未登录，请先运行 gh auth login"
    exit 1
fi

# 检查 SSH key
if [ -f "$HOME/.ssh/github" ]; then
    echo "  ✅ SSH key ~/.ssh/github 存在"
else
    echo "  ⚠️  SSH key ~/.ssh/github 不存在，GitHub SSH 推送可能失败"
fi

# 检查 hermes 配置
if [ -f "$HOME/.hermes/config.yaml" ]; then
    echo "  ✅ ~/.hermes/config.yaml 存在"
else
    echo "  ❌ ~/.hermes/config.yaml 不存在，请先配置 Hermes"
    exit 1
fi

# ===== 创建必要目录 =====
echo ""
echo "[创建目录]"
mkdir -p "${WORKSPACE}/company/logs"
mkdir -p "${WORKSPACE}/company/pm-state"
mkdir -p "${WORKSPACE}/projects"
echo "  ✅ company/logs/ company/pm-state/ projects/"

# ===== 1. 创建 PM Agent profile =====
echo ""
echo "[1/3] 创建 PM Agent..."
if [ -d "$HOME/.hermes/profiles/pm-agent" ]; then
    echo "  pm-agent profile 已存在，跳过创建"
else
    hermes profile create pm-agent
fi
# 复制 prompt（替换占位符为实际路径）
sed "s|{{WORKSPACE}}|${WORKSPACE}|g" "${PROMPTS_DIR}/pm-agent.md" > "$HOME/.hermes/profiles/pm-agent/SOUL.md"
# 复制主配置（模型和 provider）
cp "$HOME/.hermes/config.yaml" "$HOME/.hermes/profiles/pm-agent/config.yaml"
cp "$HOME/.hermes/.env" "$HOME/.hermes/profiles/pm-agent/.env" 2>/dev/null || true
# PM 也需要 yolo 模式（自动读 alert 推飞书不需要审批）
if ! grep -q "yolo" "$HOME/.hermes/profiles/pm-agent/config.yaml" 2>/dev/null; then
    cat >> "$HOME/.hermes/profiles/pm-agent/config.yaml" << 'YOLO'

# 自动化运行时跳过命令审批
terminal:
  yolo: true
YOLO
fi
echo "  ✅ PM Agent 就绪"

# ===== 2. 创建 Dispatcher Agent profile =====
echo ""
echo "[2/3] 创建 Dispatcher Agent..."
if [ -d "$HOME/.hermes/profiles/dispatcher-agent" ]; then
    echo "  dispatcher-agent profile 已存在，跳过创建"
else
    hermes profile create dispatcher-agent
fi
# 复制 prompt（替换占位符为实际路径）
sed "s|{{WORKSPACE}}|${WORKSPACE}|g" "${PROMPTS_DIR}/dispatcher-agent.md" > "$HOME/.hermes/profiles/dispatcher-agent/SOUL.md"
# 复制主配置
cp "$HOME/.hermes/config.yaml" "$HOME/.hermes/profiles/dispatcher-agent/config.yaml"
cp "$HOME/.hermes/.env" "$HOME/.hermes/profiles/dispatcher-agent/.env" 2>/dev/null || true
# Dispatcher 开启 yolo 模式（自动化运行跳过命令审批）
if ! grep -q "yolo" "$HOME/.hermes/profiles/dispatcher-agent/config.yaml" 2>/dev/null; then
    cat >> "$HOME/.hermes/profiles/dispatcher-agent/config.yaml" << 'YOLO'

# 自动化运行时跳过命令审批
terminal:
  yolo: true
YOLO
fi
echo "  ✅ Dispatcher Agent 就绪"

# ===== 3. 创建 Cron Job =====
echo ""
echo "[3/3] 配置 Cron Job..."
echo "  ⚠️  Cron job 需要手动创建，请在 Hermes 中运行："
echo ""
echo "  hermes cronjob create \\"
echo "    --name 'dispatcher-poll' \\"
echo "    --schedule 'every 5m' \\"
echo "    --prompt 'bash ${SCRIPTS_DIR}/dispatcher-poll.sh'"
echo ""
echo "  或者使用系统 crontab："
echo "  */5 * * * * bash ${SCRIPTS_DIR}/dispatcher-poll.sh"

# ===== 完成 =====
echo ""
echo "=== 完成 ==="
echo ""
echo "下一步："
echo "  1. 启动 PM Agent（前台常驻）："
echo "     hermes --profile pm-agent gateway run --replace"
echo ""
echo "  2. 或注册为系统服务（后台常驻）："
echo "     hermes --profile pm-agent gateway install"
echo ""
echo "  3. 创建 dispatcher-poll cron job（见上方说明）"
echo ""
echo "验证："
echo "  hermes --profile pm-agent chat -q '你好'"
echo "  hermes --profile dispatcher-agent chat -q '你好'"
