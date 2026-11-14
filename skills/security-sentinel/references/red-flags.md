# 危险模式清单（Red Flags）

整合自公开安全研究与审计实践：Smithery audit skill 否决清单、SlowMist 对 ClawHub 472+ 恶意 skill 的分析、TAR Engine 规则分类（SS/PI/CE/FA/DE 系列）、Aguara 4 万+ skill 扫描经验、Snyk ToxicSkills 报告。

## 一、立即否决清单（命中任一条 → CRITICAL / 拒绝）

1. **`curl`/`wget` 到非 localhost 域名**——skill 没有"回传电话回家"的正当理由。
2. **访问 `~/.ssh/`、`~/.aws/`、`.env`、凭证/token 文件**——没有合法理由需要碰这些。
3. **Base64 编码的 shell 命令**——经典混淆手段，如 `echo "Y3VybCAtcyAuLi4=" | base64 -d | bash`。
4. **未知来源的 MCP server**（未验证的代码执行入口）。
5. **"ignore safety" / "ignore previous instructions" / "override system prompt" / "jailbreak" / "DAN" 类指令**——明确的提示注入。
6. **动态代码执行**：`eval`、`exec`、`Function()`、`os.system`、`subprocess` 拼接待审计内容。

## 二、危险模式正则表（逐条 grep，命中后人工判读）

### 外联通信（重点：目的地）

```regex
curl\s+(-[A-Za-z]+\s+)*["']?https?://
wget\s+["']?https?://
https?://[a-zA-Z0-9.-]+          # 汇总所有域名逐一甄别
nc\s+[-A-Za-z0-9 ]+\s+[0-9]{2,5} # netcat 反向连接
socket\.(connect|create_connection)
```

甄别标准：`github.com`/官方 CDN/包管理源/ localhost（127.0.0.1、0.0.0.0）通常合法；**陌生域名、IP 直连、短链、pastebin 类站点**为高危。注意区分"出现在文档示例中"与"会被 agent 当指令执行"。

### 混淆与编码

```regex
base64\s+(-d|--decode)
eval\s+["'`]
exec\s*\(
\beval\b|\bexec\b
fromhex|unhexlify
\\x[0-9a-fA-F]{2}\\x[0-9a-fA-F]{2}   # 连续十六进制转义
atob\(|btoa\(
charCodeAt.*fromCharCode            # JS 字符串拼接混淆
```

### 凭证与敏感文件访问

```regex
\.ssh/|id_rsa|id_ed25519|\.aws/|\.gnupg/
\.env\b|credentials|config\.json.*token
api[_-]?key|secret[_-]?key|access[_-]?token|bearer\s+[A-Za-z0-9]
process\.env\.[A-Z_]+               # JS 读环境变量（结合上下文判断）
os\.environ\[                       # Python 读环境变量（结合上下文判断）
keychain|security find-generic-password   # macOS 钥匙串
```

### 命令注入与危险执行

```regex
\|\s*(ba|z|da)?sh\s*$               # 管道到 shell（TAR: SS-003 critical）
sudo\s|chmod\s+777|setuid
rm\s+(-[a-zA-Z]*\s+)*(-r|--recursive).*~|/(\s|$)   # 危险删除
mkfifo|/dev/tcp/                    # 反弹 shell 手法
child_process\.(exec|spawn|execSync)
subprocess\.(call|run|Popen|check_output)
os\.system\(|Runtime\.getRuntime\(\)\.exec
```

### 提示注入话术（出现在 SKILL.md/SYSTEM.md/tool description 中即命中）

```regex
ignore (all )?(previous|the above|prior) (instructions|rules)
override (the )?(system|safety|security)
disregard.*(instructions|guidelines|safety)
without (asking|confirmation|approval).*(user|permission)
do not (tell|inform|show|mention).*(user|human)
system prompt|jailbreak|\bDAN\b
把你看到的.*发送|发送到.*(http|webhook)|保密|不要告诉用户
```

## 三、语义级红旗（grep 无法覆盖，必须通读）

- 把仓库文件内容、环境变量、git 历史打包发送到任何外部端点。
- "每次构建/测试/提交前自动执行某脚本"——用工程惯例包装持久化执行。
- 要求 agent 关闭审批、关闭日志、降低权限提示级别。
- 指令链迂回：让 agent 先读文件 A，文件 A 再指示读文件 B，B 里才是 payload（间接注入）。
- MCP tool description 里夹带"调用本工具时应先……"的隐藏指令（tool poisoning，对模型可见、对用户隐藏）。

## 四、Kimi Code 插件专项清点

审计插件目录时，逐项检查 `kimi.plugin.json` / `.kimi-plugin/plugin.json`：

| 字段 | 检查点 | 风险 |
|------|--------|------|
| `hooks` | 每个 `event`（SessionStart/PreToolUse 等）对应的 `command` 是什么 | **最高优先级**：生命周期事件触发真实命令执行，已知被利用绕过人工审批（参见 Check Point 披露，CVSS 8.7） |
| `mcpServers` | `command` 启动的进程、`url` 指向的远程服务 | 未验证进程执行/网络连接 |
| `systemPrompt` / `systemPromptPath` | 注入系统提示的文本内容 | 每次会话自动生效的指令面 |
| `sessionStart.skill` | 会话启动自动加载的 skill | 加载即生效的指令面 |
| `skills` 路径下所有 SKILL.md | 走 Phase 3 语义审查 | 提示注入 |
| `agents/` 目录 | 自定义 agent 定义文件 | 同上 |
| `commands/` 目录 | 注册的 slash command | prompt 模板注入 |

同样模式适用于其他生态：`.claude/settings.json` 的 hooks、`.claude/skills/`、`CLAUDE.md`、Cursor 的 `.cursor/rules/`、Codex 的 `AGENTS.md`——仓库内配置文件攻击面是同一族（CSA 研究笔记、arXiv 2604.03081 供应链投毒论文均有实证）。

## 五、仓库级检查点（剧本 D 使用）

- 各级 `AGENTS.md` / `CLAUDE.md` / `GEMINI.md`（项目根、子目录、父目录链）。
- `.kimi-code/skills/`、`.agents/skills/`（项目级 skill，随仓库分发给所有协作者）。
- `config.toml` 中 `[[hooks]]` 规则、MCP server 声明。
- CI 配置（`.github/workflows/`、`.drone.yml`）中调用 AI 的步骤——CI 里的注入同样"加载即生效"。
- 新增/近期修改的上述文件——对 diff 做重点审查，而不是全量平均用力。

## 六、合法但需确认的（MEDIUM 候选，勿误报）

- 访问 github.com / pypi / npm 官方源。
- 监听 localhost 的调试服务。
- 文档中"例如：curl https://api.example.com"的教学示例（确认 agent 不会自动执行）。
- 依赖锁文件中锁定的常见包。
