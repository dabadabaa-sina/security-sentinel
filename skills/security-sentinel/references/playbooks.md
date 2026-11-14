# 审计剧本（按目标类型选择）

## 剧本 A：单个 SKILL.md / 提示词文件

1. 读取全文，记录 frontmatter 的 `name`/`description`/`sessionStart` 等声明。
2. 通读正文做语义审查：对照 red-flags.md 第三节逐条比对（外发指令、隐藏指令、绕过审批、凭证访问）。
3. grep 第二节正则表（代码块、示例命令是重点）。
4. 若文件引用 `${KIMI_SKILL_DIR}` 下其他文件，全部读出继续审查。
5. 输出报告：风险少时可直接在对话中给结论；正式场景用 report-template.md。

## 剧本 B：插件目录 / 压缩包（安装前）

1. **隔离解包**到临时目录（不要在被审计包内运行任何东西）。
2. **文件清单**：`find . -type f` 全量列出，标注每个文件的类型与大小。可疑信号：与 skill 无关的二进制、可执行文件、`.exe`/`.dll`/`.so`、异常大的文件。
3. **manifest 清点**（red-flags.md 第四节）：hooks 命令、mcpServers、systemPromptPath、sessionStart.skill 逐项列出。
4. **hooks 脚本通读**：所有被 hooks 引用的 shell 脚本、`.cmd`、`.sh` 全文阅读——这是唯一"文件本身会执行"的部分，最高优先级。
5. **全部 SKILL.md / SYSTEM.md 通读**：语义审查（Phase 3）。
6. **正则扫描**：对全部文本文件跑 red-flags.md 第二节正则。
7. **依赖检查**：package.json / requirements.txt / 锁文件——包名拼写、是否锁版本、postinstall 脚本。
8. **二进制排查**：`file` 命令鉴定所有无可读文本内容的文件。
9. 输出报告。

## 剧本 C：已安装插件

1. 读 `~/.kimi-code/plugins/installed.json`：确认版本、来源 URL、pin 的 tag/commit、安装/更新时间。
2. 定位 `managed/<id>/` 目录，按剧本 B 的第 2-8 步审查本地副本。
3. **版本比对**：用 GitHub API 查上游最新 release 与本地版本的 diff 范围（聚焦新增/修改文件）。
4. 输出报告，附升级建议（含升级前同样审查）。

## 剧本 D：代码仓库投毒检查

1. 定位所有指令/配置文件：`AGENTS.md`（含父目录链）、`CLAUDE.md`、`GEMINI.md`、`.kimi-code/`、`.agents/`、`.cursor/rules/`、`.claude/`、`config.toml` 的 hooks/MCP 段。
2. `git log` 查看这些文件的最近变更者/时间；陌生贡献者近期改动是重点。
3. 对每个文件执行剧本 A 的语义 + 正则审查。
4. 检查 CI 配置中 AI 相关步骤（`github-actions` 使用 AI、Drone 流水线调用脚本等）。
5. 检查 `package.json`/`requirements.txt` 的 install 脚本（`postinstall`、`setup.py`）与新增依赖。
6. 输出报告：标注"仓库当前即存在风险" vs "历史提交中曾出现"。

## 剧本 E：GitHub URL（`/plugins install` 之前）

1. **仓库元数据**：owner/repo、stars、forks、最近提交频率、维护者身份（个人玩具 vs 官方组织）、open/closed 安全 issue。
2. **Release 完整性**：最新 release 的 tag、发布时间、tag 是否为可移动分支（tag 被重打是供应链手法）。
3. 下载 release tarball 到隔离目录，计算 SHA256 留档，走剧本 B。
4. 若 URL 指向分支而非 release/tag（`/tree/xxx`），风险上调一级：任意提交都可能被替换。
5. 输出报告，结论供用户决定是否执行 `/plugins install`。

## 通用收尾步骤（所有剧本）

- 临时解压目录清理建议（用户确认后删除）。
- 报告归档路径建议（如 `security-audit/YYYY-MM-DD-<target>.md`）。
- 明确写出"本结论基于静态审查，不保证运行时无第二阶段行为"。
