#!/bin/bash
# Dispatcher 轮询扫描脚本
# 由 Hermes cron 每 5 分钟调用
# 检查项目状态变化，有变化则启动 dispatcher-agent 处理

WORKSPACE="/Users/liyi/work/AI/Hermes/workspace"
LOCK_FILE="${WORKSPACE}/company/pm-state/dispatcher.lock"
PROJECTS_DIR="${WORKSPACE}/projects"

# 检查锁文件——Dispatcher 是否正在运行
if [ -f "$LOCK_FILE" ]; then
    # 检查锁文件是否超过 2 小时（可能是残留锁）
    if [ "$(find "$LOCK_FILE" -mmin +120 2>/dev/null)" ]; then
        echo "警告：锁文件超过 2 小时，可能是残留锁，删除"
        rm -f "$LOCK_FILE"
    else
        echo "Dispatcher 正在运行，跳过"
        exit 0
    fi
fi

# 检查是否有项目目录
if [ ! -d "$PROJECTS_DIR" ] || [ -z "$(ls -A "$PROJECTS_DIR" 2>/dev/null)" ]; then
    echo "没有项目，跳过"
    exit 0
fi

TRIGGER_REASON=""

# 扫描每个项目
for PROJECT_DIR in "$PROJECTS_DIR"/*/; do
    PROJECT_CODE=$(basename "$PROJECT_DIR")
    
    # 1. 检查 PRD 是否 approved 但架构还没开始
    PRD_FILE="${PROJECT_DIR}docs/prd.md"
    ARCH_FILE="${PROJECT_DIR}docs/architecture.md"
    if [ -f "$PRD_FILE" ]; then
        PRD_STATUS=$(grep -i "status:" "$PRD_FILE" | head -1 | sed 's/.*status:\s*//' | tr -d ' ')
        if [ "$PRD_STATUS" = "approved" ]; then
            # 检查架构是否已经存在（非模板状态）
            ARCH_LINES=$(wc -l < "$ARCH_FILE" 2>/dev/null || echo "0")
            ARCH_DONE="${PROJECT_DIR}docs/tasks/arch-001.done"
            if [ "$ARCH_LINES" -lt 10 ] && [ ! -f "$ARCH_DONE" ]; then
                TRIGGER_REASON="项目 ${PROJECT_CODE} PRD 已批准，需要启动架构设计"
                break
            fi
        fi
    fi
    
    # 2. 检查架构是否 approved 但还没拆任务
    if [ -f "$ARCH_FILE" ]; then
        ARCH_STATUS=$(grep -i "status:" "$ARCH_FILE" | head -1 | sed 's/.*status:\s*//' | tr -d ' ')
        TASKS_FILE="${PROJECT_DIR}docs/tasks/tasks.md"
        TASKS_LINES=$(wc -l < "$TASKS_FILE" 2>/dev/null || echo "0")
        if [ "$ARCH_STATUS" = "approved" ] && [ "$TASKS_LINES" -lt 10 ]; then
            # 检查是否有开发任务信号文件
            DEV_DONE=$(find "${PROJECT_DIR}docs/tasks/" -name "task-*.done" -o -name "dev-*.done" 2>/dev/null | head -1)
            if [ -z "$DEV_DONE" ]; then
                TRIGGER_REASON="项目 ${PROJECT_CODE} 架构已批准，需要拆任务并开始开发"
                break
            fi
        fi
    fi
    
    # 3. 检查是否有未处理的信号文件（QA failed 等需要重新处理的）
    QA_FAILED=$(find "${PROJECT_DIR}docs/tasks/" -name "qa-*.failed" -newer "${PROJECT_DIR}STATUS.md" 2>/dev/null | head -1)
    if [ -n "$QA_FAILED" ]; then
        TRIGGER_REASON="项目 ${PROJECT_CODE} QA 验收失败，需要处理"
        break
    fi
done

# 有触发原因则启动 Dispatcher
if [ -n "$TRIGGER_REASON" ]; then
    echo "检测到变化：${TRIGGER_REASON}"
    echo "启动 Dispatcher..."
    
    # 创建锁文件
    echo "${TRIGGER_REASON}" > "$LOCK_FILE"
    date >> "$LOCK_FILE"
    
    # 启动 Dispatcher（后台）
    dispatcher-agent --yolo chat -q "${TRIGGER_REASON}，项目路径在 ${PROJECTS_DIR}/${PROJECT_CODE}，请开始工作。" &
    DISPATCHER_PID=$!
    echo "Dispatcher PID: ${DISPATCHER_PID}" >> "$LOCK_FILE"
    
    # 等待完成后删除锁文件
    wait $DISPATCHER_PID
    rm -f "$LOCK_FILE"
    echo "Dispatcher 完成"
else
    echo "无变化，跳过"
fi
