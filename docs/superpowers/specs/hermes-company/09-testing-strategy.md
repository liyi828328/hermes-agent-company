# 测试策略

> 本文件是 [Hermes AI 软件公司设计总纲](../hermes-company-design.md) 的子文档。
>
> **用途**：定义三层测试模型（单元/集成/E2E）、覆盖率 85% 门槛、merge 后集成测试自动 revert 机制、bug 修复回归流程。

---

## 三层测试模型

| 层级 | 内容 | 谁写 | 谁跑 | 什么时候跑 |
|------|------|------|------|-----------|
| 单元测试 | 函数/模块级别 | Coder（TDD，先写测试再写实现） | Coder 提 PR 前自跑 + Reviewer 接到 PR 后再跑一次 | 提 PR 前 + Review 阶段 |
| 集成测试 | 模块间交互、API 调用链 | Coder（基于 `docs/contracts/api.yaml` 写） | Dispatcher merge 后自动跑（或 CI） | 每次 merge 到 main |
| E2E 测试 | 模拟用户操作、业务流程验证 | QA Agent（基于 PRD 验收标准） | QA Agent | 全部模块 merge 后、里程碑交付前 |

---

## 覆盖率要求

- **单元测试覆盖率不得低于 85%**
- Coder 提 PR 时必须在 PR body 中附上覆盖率报告（如 `pytest --cov` 或对应工具输出）
- 覆盖率低于 85% → Reviewer 直接 reject，不看代码
- 集成测试和 E2E 测试暂不设覆盖率门槛，靠 Reviewer 和 QA 人肉判断关键路径是否覆盖

---

## 关键规则

### 1. Coder 提 PR 必须附带测试代码

- 不是"自测结果截图"，而是可重复运行的测试文件
- 没有测试的 PR，Reviewer 不看代码直接 reject
- 写代码前先写测试（TDD）：先写 fail 的测试 → 写最小实现让测试 pass → 重构

### 2. Reviewer 审查第一步是跑测试

- `cd code/ && <test command>`（npm test / pytest / go test 等）
- 测试不过 = reject，不看代码
- 测试过了 → 检查覆盖率是否 ≥ 85% → 不够 = reject
- 全部通过才开始审查代码逻辑

### 3. Merge 后跑集成测试

- Dispatcher 每次 merge 一个 PR 到 main 后，立刻跑集成测试
- 集成测试通过 → 继续处理 merge 队列
- 集成测试挂了 → 自动流程（内部闭环，不通知老板）：
  1. 立刻 revert 该 PR（`git revert --no-edit <merge-commit>`）
  2. 创建 bug issue（标记 `integration-failure` + `P1`）
  3. Dispatcher spawn 原 Coder Agent 修复
  4. 修复后重新走 PR → Review → merge → 再跑集成测试
  5. 全程内部自行解决，仅在触发第三层熔断阈值时才上报老板

### 4. QA 只做 E2E，不管单元和集成

- QA 拿到的代码必须是"单元测试和集成测试已全绿"的状态
- QA 只验证业务流程是否符合 PRD 验收标准
- QA 不写单元测试，不写集成测试
- 小程序端 UI/交互测试不在 QA 职责范围（老板在介入点 3 手动验收）

### 5. Bug 修复的回归测试

- Coder 修 bug 的 PR **必须包含一个复现该 bug 的测试用例**
- 该测试用例在修之前跑 fail，修之后跑 pass
- Reviewer 审查 bug fix PR 时，必须先验证这个测试用例确实能复现 bug
- QA 在下一轮验收时对所有已修复的 bug 做回归验证

### 6. 测试代码位置

测试代码与业务代码同仓，按层级分目录：

```
code/
├── src/              # 业务代码
├── tests/
│   ├── unit/         # 单元测试（Coder 写）
│   ├── integration/  # 集成测试（Coder 写）
│   └── e2e/          # E2E 测试（QA 写）
└── ...
```

---

## 与其他子文档的关联

- **04-agent-prompts.md**：Coder 的行为规则中已写明 TDD 要求；Reviewer 的行为规则中已写明"跑测试 → 审代码"流程
- **03-project-archive.md**：PR 创建规约中要求 PR body 包含"自测结果"，本文档升级为"必须包含测试代码 + 覆盖率报告"
- **07-monitoring.md**：集成测试修复过程中如触发第三层熔断阈值（2 小时 / 5M tokens / 同一错误 20 次），才会上报老板
