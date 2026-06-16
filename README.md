# 🔀 cc-multi-account (`ccm`)

> 在**一台机器**上**同时**使用多个 Claude Code 账号与 API 后端 —— `claude`、`claude-b`、`claude-glm`…… 多个终端各跑一个、**同时运行互不干扰**,会话与配置共享,凭据互相隔离。

**English TL;DR**: `ccm` is a tiny, dependency-free shell tool that lets you run several Claude Code identities side by side on one machine. Each *official* account gets its own isolated credentials but **shares sessions, settings, skills, plugins and MCP config** with the others; each *proxy* backend points Claude Code at an Anthropic-compatible gateway via `ANTHROPIC_BASE_URL`, billed by your own API key. Add, list, rename and delete commands at runtime — no rebuild.

---

## 👀 一眼看懂

配好之后,在终端里:

```sh
claude        # 账号 A —— 你已登录的默认官方账号
claude-b      # 账号 B —— 另一个官方订阅账号,独立凭据
claude-glm    # 第三方后端 —— 你自己配的 base_url + key 的 Anthropic 兼容 API
```

三个命令背后是**同一个 claude 程序**,只是身份/后端不同,而且**共享同一份会话与配置**。于是你能:

- **同时开着用**:终端 1 跑 `claude`、终端 2 跑 `claude-b`、终端 3 跑 `claude-glm`,各干各的、互不干扰、额度各算各的;
- **跨账号接力**:在 `claude` 里开的会话额度用完 `/exit`,再用 `claude-b -r <会话>` 切到账号 B **原地继续**,上下文完整保留。

---

## 🎯 解决什么问题

你大概是这种情况:

- 手上有**多个订阅账号**(比如两个 Max,或 Team + 个人版),想同时开工、各花各的额度,不互相挤;
- 还想顺手接些**便宜的第三方后端**(自建 new-api,或各类中转/聚合平台上的 GLM、DeepSeek、Kimi、MiniMax 等),和官方账号一起用。

Claude Code 官方还不支持多账号。而你要的「多账号**同时跑**、又**共用**同一份会话和配置」,现成办法都只能做到一半:

| 做法 | 同时跑多账号 | 共用会话 / 配置 |
|---|:---:|:---:|
| 换凭据(cswap 类) | ❌ | ✅ |
| 多开配置目录(现成工具) | ✅ | ❌ |
| **ccm** | ✅ | ✅ |

`ccm` 两者兼得,办法一句话:**每个账号一个独立配置目录(管"同时跑"),除凭据外的一切软链到同一份(管"共用")**。

---

## ⚙️ 核心原理

```
~/.claude/                      默认账号(命令 claude),所有真实文件都在这
├── .credentials.json           凭据   ┐ 私有:绝不共享
├── .claude.json                状态   ┘
├── projects/ todos/ skills/ plugins/ agents/ commands/ hooks/ settings.json ...
│                                      └ 共享数据

~/.claude-accounts/<名>/         ccm 新增的官方账号(独立 CLAUDE_CONFIG_DIR)
├── .credentials.json            该账号自己的凭据(私有)
├── .claude.json                 该账号自己的状态(私有)
└── 其余项 ──软链──▶ ~/.claude/   共享同一份会话与配置
```

- **官方账号**:每个账号一个独立 `CLAUDE_CONFIG_DIR`,凭据/状态私有,**其余一切软链回 `~/.claude`**。
  因此两个账号能**并行**,也能**接力同一个会话**(账号 A `/exit` 后 `claude-b -r <会话>` 原地续,上下文完整)。
- **代理后端**:不碰 OAuth 凭据,只设 `ANTHROPIC_BASE_URL` + key + 三档模型映射,用你自己的 API key 计费 —— 不涉及官方账号登录,所以它没有账号维度。

---

## 📦 安装

依赖:`bash`、`curl`(探活用)、一个支持软链的类 Unix 系统(macOS / Linux)。无需 root,无需 Nix。

```sh
git clone https://github.com/finyorko/cc-multi-account.git
cd cc-multi-account
./install.sh                 # 拷到 ~/.local/bin/ccm 并提示 PATH
# 或手动:
install -m 0755 ccm ~/.local/bin/ccm
```

确认 `~/.local/bin` 在 `PATH` 中(生成的命令也写在这里):

```sh
echo "$PATH" | tr ':' '\n' | grep -q "$HOME/.local/bin" && echo OK || echo "需把 ~/.local/bin 加入 PATH"
```

> 若你的 shell 是 **fish**,把路径加进 fish:`fish_add_path $HOME/.local/bin`。

---

## 🚀 快速开始

```sh
# 1) 新增一个官方账号命令(不给名字会交互提示,默认推荐 claude-b/c/d…)
ccm add-official claude-b
ccm login claude-b                 # 浏览器 OAuth 登录;之后日常直接用 `claude-b`

# 2) 新增一个第三方后端命令(Anthropic 兼容网关)
ccm add-proxy claude-glm \
  --base-url https://your-gateway.example.com \
  --key      sk-xxxxxxxxxxxx \
  --opus glm-x --sonnet glm-x --haiku some-cheap-model
#   省略参数则逐项交互输入;保存前会自动探活验证

# 3) 查看 / 管理
ccm list
ccm rename claude-glm cc-glm
ccm delete claude-glm
```

`ccm list` 一眼看清有几个账号、各是什么:

```
Claude Code commands — 3 total (official 2 · proxy 1)

  [1] claude          official · default
      account you@example.com (You) · Team
      dir     ~/.claude

  [2] claude-b         official
      account alt@example.com (Alt) · Max
      dir     ~/.claude-accounts/claude-b

  [3] claude-glm       proxy
      backend https://your-gateway.example.com
      models  opus=glm-x  sonnet=glm-x  haiku=some-cheap-model
```

---

## 📖 命令参考

| 命令 | 说明 |
|---|---|
| `ccm add-official [名字]` | 新增官方账号命令(OAuth)。不给名字会交互提示并推荐默认名 |
| `ccm add-proxy [名字] [选项]` | 新增第三方后端命令 |
| `ccm login <名字>` | 启动该命令做 OAuth 登录 |
| `ccm list` | 列出全部命令(含已登录的默认账户),带序号、类型、账号/后端 |
| `ccm delete [-y] <名字>` | 删除命令(`-y` 免确认);会话是共享数据,不会被删 |
| `ccm rename <旧> <新>` | 重命名命令 |

**`add-proxy` 选项**:

| 选项 | 含义 |
|---|---|
| `--base-url URL` | 网关地址,**不要带 `/v1`**(Claude Code 自动拼 `/v1/messages`) |
| `--key KEY` | API key |
| `--opus / --sonnet / --haiku M` | 三档分别映射到后端的哪个模型(`haiku` 档供后台与子 agent 的轻量任务,后端没有小模型时三档可填同一个) |
| `--api-key-style` | 用 `x-api-key` 头而非默认的 `Authorization: Bearer`(个别网关需要) |
| `--early-compact` | 后端上下文窗口偏小时提前压缩 |
| `--no-probe` | 跳过保存前的探活 |

后端参数存于 `~/.config/ccm/backends/<名>.env`(权限 600),**改完即时生效,无需任何重建**。

---

## ⚠️ 注意事项与已知限制

- **同一个会话别被两个进程同时打开** —— 会并写同一个 `jsonl` 互相覆盖。这是 Claude Code 本身的行为(**非 ccm 引入**,单账号开同一会话两次也一样);接力前让旧窗口先真正退出即可。
- **Claude Code 静默丢对话的已知 bug([#67603](https://github.com/anthropics/claude-code/issues/67603))**:2.1.173+ 起,交互式会话若**继承了 `CLAUDE_CODE_CHILD_SESSION` 环境变量**(常见于从 claude 内部开的终端、被污染的 tmux 或 IDE 集成终端),会完全不写对话转写、`--resume` 失效,且**全程无任何报错**。`ccm` 生成的每个命令都已内置 `unset` 规避,**天然免疫**;但**原版 `claude`** 若从这种环境启动仍可能中招 —— 保险做法:在 shell 配置里加 `unset CLAUDE_CODE_CHILD_SESSION`,或开重要会话前 `echo $CLAUDE_CODE_CHILD_SESSION` 确认为空。
- **凭据天然隔离**:每个账号有独立的 `CLAUDE_CONFIG_DIR`,登录后各自的凭据分开存储、互不影响,无需手动导出或迁移。
- **多账号轮换属个人生产力用法**,请自行留意各订阅的服务条款。
- 凭据(`.credentials.json`)与状态(`.claude.json`)**始终私有,绝不软链**。

---

## 📄 License

MIT © finyorko
