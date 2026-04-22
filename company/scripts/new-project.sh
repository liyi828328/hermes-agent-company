#!/bin/bash
# 一键创建新项目仓库
# 用法: ./new-project.sh <项目代号>
# 示例: ./new-project.sh mall

set -e

if [ -z "$1" ]; then
    echo "用法: $0 <项目代号>"
    echo "示例: $0 mall"
    exit 1
fi

PROJECT_CODE="$1"
REPO_NAME="hermes-proj-${PROJECT_CODE}"
WORKSPACE="$(cd "$(dirname "$0")/../.." && pwd)"
TEMPLATE_DIR="${WORKSPACE}/company/templates/project-scaffold"
PROJECT_DIR="${WORKSPACE}/projects/${PROJECT_CODE}"
DATE=$(date +%Y-%m-%d)
GITHUB_USER="liyi828328"
export GIT_SSH_COMMAND="ssh -i ~/.ssh/github -o StrictHostKeyChecking=no -p 443"

echo "=== 创建项目: ${PROJECT_CODE} ==="
echo "  仓库名: ${REPO_NAME}"
echo "  本地路径: ${PROJECT_DIR}"

# 检查项目是否已存在
if [ -d "${PROJECT_DIR}" ]; then
    echo "错误: 项目目录已存在 ${PROJECT_DIR}"
    exit 1
fi

# 1. 在 GitHub 创建私仓
echo ""
echo "[1/4] 创建 GitHub 私仓..."
gh repo create "${GITHUB_USER}/${REPO_NAME}" --private --description "Hermes AI 软件公司 - ${PROJECT_CODE}" 2>&1

# 2. Clone 到本地
echo ""
echo "[2/4] Clone 到本地..."
git clone "ssh://git@ssh.github.com:443/${GITHUB_USER}/${REPO_NAME}.git" "${PROJECT_DIR}" 2>&1

# 3. 复制模板并替换占位符
echo ""
echo "[3/4] 初始化项目结构..."
cp -r "${TEMPLATE_DIR}/"* "${PROJECT_DIR}/"
cp "${TEMPLATE_DIR}/.gitignore" "${PROJECT_DIR}/.gitignore"

# 替换占位符
if [[ "$OSTYPE" == "darwin"* ]]; then
    SED_INPLACE=(sed -i '')
else
    SED_INPLACE=(sed -i)
fi
find "${PROJECT_DIR}" -type f -name "*.md" -exec "${SED_INPLACE[@]}" "s/{{PROJECT_NAME}}/${PROJECT_CODE}/g" {} \;
find "${PROJECT_DIR}" -type f -name "*.md" -exec "${SED_INPLACE[@]}" "s/{{DATE}}/${DATE}/g" {} \;

# 4. 首次提交
echo ""
echo "[4/4] 首次提交..."
cd "${PROJECT_DIR}"
git add -A
git commit -m "初始化项目: ${PROJECT_CODE}"
git push origin main 2>&1

echo ""
echo "=== 完成 ==="
echo "  GitHub: https://github.com/${GITHUB_USER}/${REPO_NAME}"
echo "  本地: ${PROJECT_DIR}"
