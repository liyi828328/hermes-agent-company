#!/bin/bash
# Dispatcher 轮询扫描脚本
# 由 Hermes cron 每 5 分钟调用
# 扫描所有项目，有未完成的项目则启动 dispatcher-run.sh 后台处理

WORKSPACE="/Users/liyi/work/AI/Hermes/workspace"
LOCK_DIR="${WORKSPACE}/company/pm-state"
PROJECTS_DIR="${WORKSPACE}/projects"
ALERT_FILE="${LOCK_DIR}/alerts.jsonl"
RUN_SCRIPT="${WORKSPACE}/company/scripts/dispatcher-run.sh"

# 检查是否有项目目录
if [ ! -d "$PROJECTS_DIR" ] || [ -z "$(ls -A "$PROJECTS_DIR" 2>/dev/null)" ]; then
    exit 0
fi

# 扫描每个项目
for PROJECT_DIR in "$PROJECTS_DIR"/*/; do
    PROJECT_CODE=$(basename "$PROJECT_DIR")
    LOCK_FILE="${LOCK_DIR}/dispatcher-${PROJECT_CODE}.lock"
    
    # 跳过已交付的项目
    STATUS_FILE="${PROJECT_DIR}STATUS.md"
    if [ -f "$STATUS_FILE" ] && grep -q "\[x\].*交付" "$STATUS_FILE" 2>/dev/null; then
        continue
    fi
    
    # 检查该项目的锁文件（Dispatcher 是否已在运行）
    if [ -f "$LOCK_FILE" ]; then
        # 检查锁文件对应的进程是否还活着
        LOCK_PID=$(grep "PID:" "$LOCK_FILE" 2>/dev/null | sed 's/PID:\s*//' | tr -d ' ')
        if [ -n "$LOCK_PID" ] && kill -0 "$LOCK_PID" 2>/dev/null; then
            continue
        else
            # 进程已死但锁文件还在，清理残留锁
            rm -f "$LOCK_FILE"
        fi
    fi
    
    # 检查项目是否有需要处理的状态
    PRD_FILE="${PROJECT_DIR}docs/prd.md"
    NEED_DISPATCH=false
    
    # 条件：PRD approved
    if [ -f "$PRD_FILE" ]; then
        PRD_STATUS=$(grep -i "status:" "$PRD_FILE" | head -1 | sed 's/.*status:\s*//' | tr -d ' ')
        if [ "$PRD_STATUS" = "approved" ]; then
            # 检查是否已经完成全部流程
            DOC_DONE=$(find "${PROJECT_DIR}docs/tasks/" -name "doc-*.done" 2>/dev/null | head -1)
            if [ -z "$DOC_DONE" ]; then
                NEED_DISPATCH=true
            fi
        fi
    fi
    
    # 需要 Dispatcher → 后台启动 dispatcher-run.sh
    if [ "$NEED_DISPATCH" = true ]; then
        nohup bash "$RUN_SCRIPT" "$PROJECT_CODE" >> "${WORKSPACE}/company/logs/dispatcher-${PROJECT_CODE}.log" 2>&1 &
    fi
done
