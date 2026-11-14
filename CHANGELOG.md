# Changelog

## [1.0.0] - 2026-11-14

### 新增

- `security-sentinel` skill：五步法静态安全审查流程（攻击面清点 → 模式扫描 → 语义审查 → 供应链核查 → 分级报告）
- `references/red-flags.md`：危险模式清单，整合 Smithery 否决红线、SlowMist ClawHub 恶意样本规则、TAR Engine 规则分类、Aguara 4 万+ skill 扫描经验
- `references/playbooks.md`：五套审计剧本（SKILL.md / 插件目录 / 已装插件 / 仓库 / 远程 URL）
- `references/toolkit.md`：超级组合（skill-audit、NVIDIA SkillSpector、mcp-scan、AI-Infra-Guard、Garak、SlowMist、Snyk）+ Kimi Code 防御配置基线 + 威胁情报参考
- `references/report-template.md`：标准审查报告模板
- `kimi.plugin.json`：插件 manifest（零 hooks / 零 MCP / 零 systemPrompt 注入）
- `scripts/export.sh`：一键打包导出 zip
