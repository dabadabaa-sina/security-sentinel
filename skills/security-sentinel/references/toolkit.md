# 超级组合：外部工具 + 防御基线 + 研究参考

Security Sentinel（本 skill）解决"人工语义审查"——发现隐藏指令、社工话术、逻辑层面恶意。自动扫描器解决"规模与规则覆盖"。两者组合使用。

## 一、同类开源工具（2026 年公开生态调研）

| 工具 | 出品方 | 覆盖 | 用法 |
|------|--------|------|------|
| **skill-audit** | 社区 (pors) | Skill 注入/密钥/危险代码模式 CLI 扫描 | `github.com/pors/skill-audit` |
| **SkillSpector** | NVIDIA | Agent skill 漏洞、恶意模式、提示注入、数据外泄扫描（2026-11 发布） | `github.com/nvidia/skillspector` |
| **mcp-scan** | Invariant Labs | MCP server 注入/工具投毒/有毒流程；Snyk 已集成其能力做 Agent Skills 检测 | `npx @invariantlabs/mcp-scan` / Snyk |
| **AI-Infra-Guard** | 腾讯 | MCP 资产安全扫描 | GitHub 开源 |
| **skill-security-audit** | SlowMist | 基于 ClawHub 472+ 真实恶意 skill 样本的规则库 | 规则库可人工对照本 skill 的 red-flags.md |
| **Garak** | NVIDIA | LLM 漏洞探测（越狱/注入基准） | 运行时探测，适合对已部署 agent 做红队 |
| **MCPTox / MindGuard** | 学术界 | MCP 工具投毒检测与归因 | 研究原型，参考其攻击分类 |

**推荐组合工作流**：

```
安装/升级前：Security Sentinel（本 skill，人工语义审查）
           + skill-audit / SkillSpector（自动规则扫描）
           + mcp-scan（若涉及 MCP server）
CI 集成：   把自动扫描器加进 CI，对本仓库 .kimi-code/skills/、AGENTS.md 做 MR 门禁
运行时：    Garak 类红队探测 + agent 权限最小化（见第二节）
```

## 二、防御配置基线（Kimi Code CLI）

1. **权限模式**：日常使用保持需要确认的模式；对 `Bash`、文件写入类工具不开放全自动。
2. **hooks 审查**：`config.toml` 与插件 manifest 中的 `[[hooks]]` 全部视为"每次事件即执行代码"——只保留能解释清楚用途的规则；插件 hooks 单独审计。
3. **MCP server 最小化**：只启用正在使用的 server；远程 HTTP server 确认 TLS 与来源；stdio server 确认 command 路径。
4. **skill 来源纪律**：只装 Named source（官方市场/固定 tag 的 GitHub release）；避免 `/tree/分支` 形式安装。
5. **项目级配置纳入 code review**：`AGENTS.md`、`.kimi-code/`、`.agents/` 的任何改动走 review 流程，与 `.sh` 同级警惕。
6. **敏感目录隔离**：agent 工作目录避免放真实生产凭证；`.env`、SSH 密钥不进工作区。
7. **定期复查**：`~/.kimi-code/plugins/installed.json` 中的插件版本与上游 release 比对（本会话已演示 v6.3.0 → v7.0.2 的检查流程）。

## 三、威胁情报与研究参考（按主题）

**插件/skill 投毒实证**
- Snyk《ToxicSkills》：36% 的抽样 skill 存在提示注入，1467 个恶意 skill（snyk.io/blog/toxicskills-malicious-ai-agent-skills-clawhub）
- Datadog Security Labs：恶意 skill 利用动态上下文在模型防御生效前执行（securitylabs.datadoghq.com）
- SlowMist：ClawHub 平台 472+ 恶意 skill 样本分析

**hooks 与配置文件攻击面**
- Check Point Research：Claude Code hooks 机制利用（GHSA-ph6w-f82w-28w6，CVSS 8.7）
- PromptArmor：通过 marketplace 插件注入劫持 Claude Code（恶意 hook 绕过 human-in-the-loop）
- CSA 研究笔记：readme/指令文件注入 AI 编码助手（labs.cloudsecurityalliance.org）
- arXiv 2604.03081：针对 LLM 编码工具的供应链投毒（Claude Code/OpenHands/Codex/Gemini CLI 确认 4 个安全问题）

**MCP 专项**
- Invariant Labs：MCP Tool Poisoning 攻击通告（invariantlabs.ai）
- NSA CSI：MCP 安全指南（nsa.gov CSI_MCP_SECURITY.pdf）
- CSA：《Agentic MCP Security Best Practices v1》
- CVE-2025-54074：连接恶意 MCP server 导致的 OS 命令注入（Cherry Studio）
- Unit 42：MCP sampling 新攻击面

**加固框架与清单**
- efij/awesome-claude-code-security：渐进式加固框架（配置保护/hooks/运行时/注入防护/供应链）
- Smithery berezhasecurity/audit skill：六条"立即否决"红线（已整合进本 skill 的 red-flags.md）
- Aguara：《SKILL.md 安全审计指南》——4 万+ skill 扫描经验
- TAR Engine core-llm-prompt-security：SS/PI/CE/FA/DE 规则分类法
- Trail of Bits：CI/CD 工作流 AI 代理静态分析 skill

## 四、给审计者的提醒

- 攻击者也在读这些公开清单——真正高级的投毒会刻意避开所有已知正则。所以 **Phase 3 语义通读不可省略**，正则扫描只是初筛。
- "维护者知名"≠"当前版本干净"：账号被盗、维护者更替、release 流程被入侵都会污染信任链。版本级审查永远必要。
- 报告要写给"拍板的人"看：结论先行、证据可查、整改可执行。
