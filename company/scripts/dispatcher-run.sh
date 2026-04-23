#!/bin/bash
# 项目 Dispatcher 流水线脚本
# 为单个项目执行完整的开发流水线，处理完所有阶段才退出
# 用法: bash dispatcher-run.sh <项目代号>
# 后台运行: nohup bash dispatcher-run.sh <项目代号> &

set -e

if [ -z "$1" ]; then
    echo "用法: $0 <项目代号>"
    exit 1
fi

PROJECT_CODE="$1"
WORKSPACE="${HERMES_WORKSPACE:-$(cd "$(dirname "$0")/../.." && pwd)}"
PROJECT_PATH="${WORKSPACE}/projects/${PROJECT_CODE}"
LOCK_DIR="${WORKSPACE}/company/pm-state"
LOCK_FILE="${LOCK_DIR}/dispatcher-${PROJECT_CODE}.lock"
ALERT_FILE="${LOCK_DIR}/alerts.jsonl"
DISPATCHER="${DISPATCHER_CMD:-dispatcher-agent}"
LOG_FILE="${WORKSPACE}/company/logs/dispatcher-${PROJECT_CODE}.log"

# 检查项目是否存在
if [ ! -d "$PROJECT_PATH" ]; then
    echo "错误：项目目录不存在 ${PROJECT_PATH}"
    exit 1
fi

# 检查锁文件
if [ -f "$LOCK_FILE" ]; then
    echo "错误：项目 ${PROJECT_CODE} 的 Dispatcher 已在运行"
    exit 1
fi

# 创建锁文件
echo "PID: $$" > "$LOCK_FILE"
echo "项目: ${PROJECT_CODE}" >> "$LOCK_FILE"
echo "启动时间: $(date)" >> "$LOCK_FILE"

# 确保退出时删除锁文件
trap "rm -f '$LOCK_FILE'; echo '[${PROJECT_CODE}] Dispatcher 退出' >> '$LOG_FILE'" EXIT

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [${PROJECT_CODE}] $1" | tee -a "$LOG_FILE"
}

write_alert() {
    echo "{\"id\":\"$1\",\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"project\":\"${PROJECT_CODE}\",\"agent\":\"$2\",\"type\":\"$3\",\"message\":\"$4\"}" >> "$ALERT_FILE"
}

run_dispatcher() {
    local stage_name="$1"
    local prompt="$2"
    log "阶段 [${stage_name}] 开始"
    $DISPATCHER --yolo chat -q "$prompt" >> "$LOG_FILE" 2>&1
    local exit_code=$?
    log "阶段 [${stage_name}] 完成 (exit: ${exit_code})"
    return $exit_code
}

wait_for_file() {
    local file_path="$1"
    local timeout="${2:-600}"
    local interval=10
    local waited=0
    while [ ! -f "$file_path" ] && [ $waited -lt $timeout ]; do
        sleep $interval
        waited=$((waited + interval))
    done
    [ -f "$file_path" ]
}

log "========== 流水线启动 =========="

# ========== 阶段 1：架构设计 ==========
ARCH_DONE="${PROJECT_PATH}/docs/tasks/arch-001.done"
ARCH_FILE="${PROJECT_PATH}/docs/architecture.md"

if [ ! -f "$ARCH_DONE" ]; then
    log "阶段 1：启动架构设计"
    run_dispatcher "架构设计" "项目 ${PROJECT_CODE} PRD 已批准，请只执行架构设计阶段。项目路径：${PROJECT_PATH}。spawn Architect Agent 生成架构文档和契约文件，等待 Architect 完成后确认产出文件存在，然后退出。"
    
    # 等待 Architect 完成（可能是后台子 agent）
    if ! wait_for_file "$ARCH_DONE" 600; then
        log "错误：Architect 超时未完成"
        write_alert "arch-timeout-${PROJECT_CODE}" "Architect" "超时" "架构设计超过 10 分钟未完成"
        exit 1
    fi
    log "阶段 1：架构设计完成"
fi

# ========== 阶段 2：等待架构审批 ==========
ARCH_STATUS=$(grep -i "status:" "$ARCH_FILE" 2>/dev/null | head -1 | sed 's/.*status:\s*//' | tr -d ' ')

if [ "$ARCH_STATUS" = "pending_review" ]; then
    log "阶段 2：架构等待审批，写 alert 通知 PM"
    if ! grep -q "arch-pending-review-${PROJECT_CODE}" "$ALERT_FILE" 2>/dev/null; then
        write_alert "arch-pending-review-${PROJECT_CODE}" "Architect" "需要审批" "架构设计已完成，等待老板审批。请查看 docs/architecture.md 并将 status 改为 approved。"
    fi
    
    # 轮询等待 status 变为 approved
    log "等待老板审批架构..."
    while true; do
        ARCH_STATUS=$(grep -i "status:" "$ARCH_FILE" 2>/dev/null | head -1 | sed 's/.*status:\s*//' | tr -d ' ')
        if [ "$ARCH_STATUS" = "approved" ]; then
            break
        fi
        sleep 30
    done
    log "阶段 2：架构已审批通过"
fi

# ========== 阶段 3：拆任务 + 开发 ==========
CODE_DONE=$(find "${PROJECT_PATH}/docs/tasks/" -name "code-*.done" -o -name "task-*.done" -o -name "dev-*.done" -o -name "T*.done" 2>/dev/null | head -1)

if [ -z "$CODE_DONE" ]; then
    log "阶段 3：拆任务并启动开发"
    run_dispatcher "拆任务+开发" "项目 ${PROJECT_CODE} 架构已批准。项目路径：${PROJECT_PATH}。请执行以下步骤：1) 拆任务为 GitHub Issues 2) spawn Coder Agent 开发 3) 等待 Coder 完成（用 process wait）4) 确认信号文件存在后退出。Coder 必须创建分支、写单元测试（覆盖率≥85%）、跑静态检查、提 PR。"
    
    # 等待 Coder 完成
    waited=0
    while [ $waited -lt 900 ]; do
        CODE_DONE=$(find "${PROJECT_PATH}/docs/tasks/" -name "code-*.done" -o -name "task-*.done" -o -name "dev-*.done" -o -name "T*.done" 2>/dev/null | head -1)
        if [ -n "$CODE_DONE" ]; then break; fi
        sleep 15
        waited=$((waited + 15))
    done
    
    if [ -z "$CODE_DONE" ]; then
        log "错误：Coder 超时未完成"
        write_alert "coder-timeout-${PROJECT_CODE}" "Coder" "超时" "开发超过 15 分钟未完成"
        exit 1
    fi
    log "阶段 3：开发完成"
fi

# ========== 阶段 4：代码审查 ==========
REVIEW_DONE=$(find "${PROJECT_PATH}/docs/tasks/" -name "review-*.done" 2>/dev/null | head -1)

if [ -z "$REVIEW_DONE" ]; then
    log "阶段 4：启动代码审查"
    run_dispatcher "代码审查" "项目 ${PROJECT_CODE} 开发已完成。项目路径：${PROJECT_PATH}。请执行以下步骤：1) spawn Reviewer Agent 审查 PR 2) 等待 Reviewer 完成 3) 如果 approve 则退出 4) 如果 reject 则 spawn Coder 修复，再 spawn Reviewer 增量审查，循环直到 approve。"
    
    waited=0
    while [ $waited -lt 900 ]; do
        REVIEW_DONE=$(find "${PROJECT_PATH}/docs/tasks/" -name "review-*.done" 2>/dev/null | head -1)
        if [ -n "$REVIEW_DONE" ]; then break; fi
        sleep 15
        waited=$((waited + 15))
    done
    
    if [ -z "$REVIEW_DONE" ]; then
        log "错误：Reviewer 超时未完成"
        write_alert "reviewer-timeout-${PROJECT_CODE}" "Reviewer" "超时" "代码审查超过 15 分钟未完成"
        exit 1
    fi
    log "阶段 4：代码审查完成"
fi

# ========== 阶段 5：Merge + 集成测试 ==========
log "阶段 5：Merge 并跑集成测试"
run_dispatcher "Merge+集成测试" "项目 ${PROJECT_CODE} 代码审查已通过。项目路径：${PROJECT_PATH}。请执行以下步骤：1) 将 PR merge 到 main 2) 跑集成测试 3) 如果测试失败则 revert + 创建 bug issue + spawn Coder 修复 4) 集成测试通过后退出。"

# ========== 阶段 6：QA 验收 ==========
QA_DONE=$(find "${PROJECT_PATH}/docs/tasks/" -name "qa-*.done" 2>/dev/null | head -1)

if [ -z "$QA_DONE" ]; then
    log "阶段 6：启动 QA 验收"
    run_dispatcher "QA验收" "项目 ${PROJECT_CODE} 集成测试已通过。项目路径：${PROJECT_PATH}。请执行以下步骤：1) spawn QA Agent 做端到端验收 2) 等待 QA 完成 3) 如果验收失败则启动 QA 闭环（Coder 修 bug → Reviewer 审 → merge → QA 回归）4) 验收通过后退出。"
    
    waited=0
    while [ $waited -lt 900 ]; do
        QA_DONE=$(find "${PROJECT_PATH}/docs/tasks/" -name "qa-*.done" 2>/dev/null | head -1)
        if [ -n "$QA_DONE" ]; then break; fi
        sleep 15
        waited=$((waited + 15))
    done
    
    if [ -z "$QA_DONE" ]; then
        log "错误：QA 超时未完成"
        write_alert "qa-timeout-${PROJECT_CODE}" "QA" "超时" "QA 验收超过 15 分钟未完成"
        exit 1
    fi
    log "阶段 6：QA 验收完成"
fi

# ========== 阶段 7：文档 ==========
DOC_DONE=$(find "${PROJECT_PATH}/docs/tasks/" -name "doc-*.done" 2>/dev/null | head -1)

if [ -z "$DOC_DONE" ]; then
    log "阶段 7：启动文档编写"
    run_dispatcher "文档" "项目 ${PROJECT_CODE} QA 验收已通过。项目路径：${PROJECT_PATH}。请执行以下步骤：1) spawn Doc Agent 编写文档 2) 等待 Doc 完成 3) push 到 GitHub 4) 更新 STATUS.md 标记交付完成 5) 退出。"
    
    waited=0
    while [ $waited -lt 600 ]; do
        DOC_DONE=$(find "${PROJECT_PATH}/docs/tasks/" -name "doc-*.done" 2>/dev/null | head -1)
        if [ -n "$DOC_DONE" ]; then break; fi
        sleep 15
        waited=$((waited + 15))
    done
    
    if [ -z "$DOC_DONE" ]; then
        log "错误：Doc 超时未完成"
        write_alert "doc-timeout-${PROJECT_CODE}" "Doc" "超时" "文档编写超过 10 分钟未完成"
        exit 1
    fi
    log "阶段 7：文档编写完成"
fi

# ========== 完成 ==========
log "========== 流水线完成 =========="
write_alert "project-done-${PROJECT_CODE}" "Dispatcher" "项目交付" "项目 ${PROJECT_CODE} 全流程完成，已交付。"
