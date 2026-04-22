#!/bin/bash
# Dispatcher 轮询扫描脚本
# 由 Hermes cron 每 5 分钟调用
# 扫描所有项目，每个有变化的项目独立启动一个 Dispatcher 实例

WORKSPACE="/Users/liyi/work/AI/Hermes/workspace"
LOCK_DIR="${WORKSPACE}/company/pm-state"
PROJECTS_DIR="${WORKSPACE}/projects"

# 检查是否有项目目录
if [ ! -d "$PROJECTS_DIR" ] || [ -z "$(ls -A "$PROJECTS_DIR" 2>/dev/null)" ]; then
    echo "没有项目，跳过"
    exit 0
fi

TRIGGERED=0

# 扫描每个项目
for PROJECT_DIR in "$PROJECTS_DIR"/*/; do
    PROJECT_CODE=$(basename "$PROJECT_DIR")
    LOCK_FILE="${LOCK_DIR}/dispatcher-${PROJECT_CODE}.lock"
    
    # 跳过已交付的项目
    STATUS_FILE="${PROJECT_DIR}STATUS.md"
    if [ -f "$STATUS_FILE" ] && grep -q "\[x\].*交付" "$STATUS_FILE" 2>/dev/null; then
        continue
    fi
    
    # 检查该项目的锁文件
    if [ -f "$LOCK_FILE" ]; then
        # 检查锁文件是否超过 2 小时（残留锁）
        if [ "$(find "$LOCK_FILE" -mmin +120 2>/dev/null)" ]; then
            echo "[${PROJECT_CODE}] 锁文件超过 2 小时，删除残留锁"
            rm -f "$LOCK_FILE"
        else
            echo "[${PROJECT_CODE}] Dispatcher 正在运行，跳过"
            continue
        fi
    fi
    
    # 判断项目是否需要 Dispatcher 介入
    TRIGGER_REASON=""
    PRD_FILE="${PROJECT_DIR}docs/prd.md"
    ARCH_FILE="${PROJECT_DIR}docs/architecture.md"
    
    # 1. PRD approved 但架构还没开始
    if [ -f "$PRD_FILE" ]; then
        PRD_STATUS=$(grep -i "status:" "$PRD_FILE" | head -1 | sed 's/.*status:\s*//' | tr -d ' ')
        if [ "$PRD_STATUS" = "approved" ]; then
            ARCH_DONE="${PROJECT_DIR}docs/tasks/arch-001.done"
            ARCH_HAS_CONTENT=$(grep -c "status:" "$ARCH_FILE" 2>/dev/null)
            if [ -z "$ARCH_HAS_CONTENT" ]; then ARCH_HAS_CONTENT=0; fi
            if [ ! -f "$ARCH_DONE" ] && [ "$ARCH_HAS_CONTENT" = "0" ]; then
                TRIGGER_REASON="项目 ${PROJECT_CODE} PRD 已批准，需要启动架构设计"
            fi
        fi
    fi
    
    # 2. 架构完成（有信号文件）但 status 是 pending_review → 写 alert 通知 PM
    if [ -z "$TRIGGER_REASON" ] && [ -f "$ARCH_FILE" ]; then
        ARCH_DONE="${PROJECT_DIR}docs/tasks/arch-001.done"
        ARCH_STATUS=$(grep -i "status:" "$ARCH_FILE" | head -1 | sed 's/.*status:\s*//' | tr -d ' ')
        ALERT_FILE="${LOCK_DIR}/alerts.jsonl"
        if [ -f "$ARCH_DONE" ] && [ "$ARCH_STATUS" = "pending_review" ]; then
            # 检查是否已经发过这个 alert（避免重复）
            if ! grep -q "arch-pending-review-${PROJECT_CODE}" "$ALERT_FILE" 2>/dev/null; then
                echo "{\"id\":\"arch-pending-review-${PROJECT_CODE}\",\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"project\":\"${PROJECT_CODE}\",\"agent\":\"Architect\",\"type\":\"需要审批\",\"message\":\"架构设计已完成，等待老板审批。请查看 docs/architecture.md 并将 status 改为 approved。\"}" >> "$ALERT_FILE"
                echo "[${PROJECT_CODE}] 架构完成等审批，已写 alert 通知 PM"
            fi
            continue
        fi
    fi
    
    # 3. 架构 approved 但还没拆任务
    if [ -z "$TRIGGER_REASON" ] && [ -f "$ARCH_FILE" ]; then
        ARCH_STATUS=$(grep -i "status:" "$ARCH_FILE" | head -1 | sed 's/.*status:\s*//' | tr -d ' ')
        if [ "$ARCH_STATUS" = "approved" ]; then
            # 检查是否有开发任务信号文件
            DEV_DONE=$(find "${PROJECT_DIR}docs/tasks/" -name "task-*.done" -o -name "dev-*.done" 2>/dev/null | head -1)
            DOC_DONE=$(find "${PROJECT_DIR}docs/tasks/" -name "doc-*.done" 2>/dev/null | head -1)
            if [ -z "$DEV_DONE" ] && [ -z "$DOC_DONE" ]; then
                TRIGGER_REASON="项目 ${PROJECT_CODE} 架构已批准，需要拆任务并开始开发"
            fi
        fi
    fi
    
    # 4. 有 QA failed 需要处理
    if [ -z "$TRIGGER_REASON" ]; then
        QA_FAILED=$(find "${PROJECT_DIR}docs/tasks/" -name "qa-*.failed" -newer "${PROJECT_DIR}STATUS.md" 2>/dev/null | head -1)
        if [ -n "$QA_FAILED" ]; then
            TRIGGER_REASON="项目 ${PROJECT_CODE} QA 验收失败，需要处理"
        fi
    fi
    
    # 有触发原因则启动该项目的 Dispatcher（后台独立）
    if [ -n "$TRIGGER_REASON" ]; then
        echo "[${PROJECT_CODE}] 检测到变化：${TRIGGER_REASON}"
        echo "[${PROJECT_CODE}] 启动 Dispatcher..."
        
        # 创建锁文件
        echo "${TRIGGER_REASON}" > "$LOCK_FILE"
        date >> "$LOCK_FILE"
        
        # 后台启动 Dispatcher（每个项目独立进程）
        (
            dispatcher-agent --yolo chat -q "${TRIGGER_REASON}，项目路径在 ${PROJECT_DIR}，请完整走完当前阶段的所有步骤，包括等待子 agent 完成、检查产出、写 alert 通知 PM。"
            rm -f "$LOCK_FILE"
            echo "[${PROJECT_CODE}] Dispatcher 完成，锁文件已删除"
        ) &
        
        TRIGGERED=$((TRIGGERED + 1))
    fi
done

if [ "$TRIGGERED" -gt 0 ]; then
    echo "共触发 ${TRIGGERED} 个项目的 Dispatcher"
else
    echo "无变化，跳过"
fi
