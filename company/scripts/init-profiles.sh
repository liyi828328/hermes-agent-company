#!/bin/bash
# 初始化 Agent Profiles
# 用途：在新机器上创建 PM 和 Dispatcher 的 Hermes profile
# 前提：已安装 Hermes、已配置好 ~/.hermes/config.yaml 和 ~/.hermes/.env

set -e

WORKSPACE="$(cd "$(dirname "$0")/../.." && pwd)"
PROMPTS_DIR="${WORKSPACE}/company/prompts"

echo "=== 初始化 Agent Profiles ==="
echo "工作空间：${WORKSPACE}"

# 1. 创建 PM Agent profile
echo ""
echo "[1/2] 创建 PM Agent..."
if [ -d "$HOME/.hermes/profiles/pm-agent" ]; then
    echo "  pm-agent profile 已存在，跳过创建"
else
    hermes profile create pm-agent
fi
# 复制 prompt
cp "${PROMPTS_DIR}/pm-agent.md" "$HOME/.hermes/profiles/pm-agent/SOUL.md"
# 复制主配置（模型和 provider）
cp "$HOME/.hermes/config.yaml" "$HOME/.hermes/profiles/pm-agent/config.yaml"
cp "$HOME/.hermes/.env" "$HOME/.hermes/profiles/pm-agent/.env" 2>/dev/null || true
echo "  ✅ PM Agent 就绪"

# 2. 创建 Dispatcher Agent profile
echo ""
echo "[2/2] 创建 Dispatcher Agent..."
if [ -d "$HOME/.hermes/profiles/dispatcher-agent" ]; then
    echo "  dispatcher-agent profile 已存在，跳过创建"
else
    hermes profile create dispatcher-agent
fi
# 复制 prompt
cp "${PROMPTS_DIR}/dispatcher-agent.md" "$HOME/.hermes/profiles/dispatcher-agent/SOUL.md"
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

echo ""
echo "=== 完成 ==="
echo "验证："
echo "  pm-agent chat -q '你好'"
echo "  dispatcher-agent chat -q '你好'"
