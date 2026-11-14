# Security Sentinel

AI agent 技能 / 插件 / 仓库的**注入与投毒安全审查** skill。安装或升级任何第三方 skill、plugin 之前，用它做一道安全门禁。

> **设计原则：本插件自身零 hooks、零 MCP server、零 systemPrompt 注入**——只含一个纯 prompt 型 skill 与四份参考文档。审查者先自证清白。

## 解决什么问题

AI 编程助手的 skill / 插件体系存在一类特殊攻击面——**"加载即生效"**：

- `SKILL.md`、`AGENTS.md`、`SYSTEM.md` 等提示词文件被 agent 自动读入上下文，其中的恶意指令会在后续工具调用中被执行；
- 插件 manifest 中的 `hooks` 在生命周期事件上**真实执行 shell 命令**，可绕过人工审批；
- 供应链投毒：被篡改的开源仓库、恶意 PR、typosquatting 依赖。

本 skill 以"纯静态、不执行、证据驱动"的方式审计这些对象。

## 快速开始

### 安装

```bash
# 方式一：作为插件安装（推荐，可跨项目使用）
/plugins install https://github.com/dabadabaa-sina/security-sentinel

# 方式二：用户级 skill 安装
cp -r skills/security-sentinel ~/.kimi-code/skills/

# 方式三：项目级（随仓库共享）
cp -r skills/security-sentinel .kimi-code/skills/
```

安装后执行 `/reload` 或开新会话生效。

### 使用

```bash
# 审查一个 GitHub 插件/skill（安装前）
/skill:security-sentinel https://github.com/obra/superpowers/releases/tag/v7.0.2

# 审查本地插件目录或压缩包
/skill:security-sentinel ./some-plugin/

# 审查当前仓库是否被投毒
/skill:security-sentinel 当前仓库
```

也可以直接说人话："安装这个插件前先帮我做安全检查：\<url\>"，模型会自动调用。

## 审查方法论（五步法）

| 阶段 | 内容 |
|------|------|
| Phase 0 | 界定目标类型，选择剧本（SKILL.md / 插件目录 / 已装插件 / 仓库 / 远程 URL） |
| Phase 1 | 清点攻击面：提示词面、执行面（hooks/MCP）、依赖面 |
| Phase 2 | 静态模式扫描：否决清单 + 危险正则表 + 插件 manifest 专项 |
| Phase 3 | **语义审查**：通读全部提示词，发现 grep 覆盖不到的社工话术与隐蔽指令 |
| Phase 4 | 供应链核查：来源可信度、版本完整性、依赖投毒、版本 diff 聚焦 |
| Phase 5 | 分级报告：CRITICAL / HIGH / MEDIUM / LOW + ✅可用 / ⚠️条件可用 / ❌拒绝 |

## 目录结构

```
security-sentinel-plugin/
├── kimi.plugin.json          # 插件 manifest（无 hooks / 无 MCP / 无 systemPrompt）
├── skills/security-sentinel/
│   ├── SKILL.md              # 主技能：五步法流程 + 审计铁律
│   └── references/
│       ├── red-flags.md      # 危险模式清单（否决清单/正则表/语义红旗/插件专项）
│       ├── playbooks.md      # 五套审计剧本
│       ├── toolkit.md        # 超级组合：外部工具 + 防御基线 + 威胁情报
│       └── report-template.md# 审查报告模板
├── scripts/export.sh         # 打包导出（zip，可分发给团队或上传 release）
├── README.md / LICENSE / CHANGELOG.md
```

## 超级组合（Super Combo）

本 skill 负责人工语义层审查，与开源自动扫描器组合成完整防线：

| 层 | 工具 | 覆盖 |
|----|------|------|
| 语义审查 | **Security Sentinel（本 skill）** | 隐藏指令、社工话术、逻辑恶意 |
| 规则扫描 | [skill-audit](https://github.com/pors/skill-audit)、[NVIDIA SkillSpector](https://github.com/nvidia/skillspector) | 注入模式、密钥、危险代码 |
| MCP 专项 | [mcp-scan](https://invariantlabs.ai/)（Invariant Labs）、AI-Infra-Guard（腾讯） | MCP 注入、工具投毒、有毒流程 |
| 运行时红队 | [Garak](https://github.com/NVIDIA/garak)（NVIDIA） | 已部署 agent 的越狱/注入探测 |
| 规则情报 | SlowMist（ClawHub 472+ 恶意样本）、Snyk ToxicSkills（36% 注入率） | 真实恶意样本特征库 |

推荐工作流：**安装/升级前** 本 skill + 自动扫描器双跑；**CI** 中对仓库内 `.kimi-code/skills/`、`AGENTS.md` 做 MR 门禁；**运行时** Garak 红队 + 权限最小化。

详见 `skills/security-sentinel/references/toolkit.md`。

## 导出与分发

```bash
./scripts/export.sh          # 生成 security-sentinel-<version>.zip
```

产物 zip 可通过 `/plugins install <path-or-url>` 安装，或作为 GitHub release 附件分发。

## 开源协作

欢迎提交 PR：新增恶意模式正则、补充真实审计案例、改进剧本。提交前请确保：

1. 本插件**不引入任何 hooks / MCP server / systemPrompt 注入**（安全插件不能以安全之名行注入之实）；
2. 新增的危险模式附公开来源（研究、CVE、真实样本）；
3. `CHANGELOG.md` 同步更新。

## License

MIT
