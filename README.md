# 在 Gemini CLI 中使用 Karpathy Guidelines

把這份 Karpathy 風格的 LLM 寫程式紀律，安裝到 Gemini CLI 裡。提供兩支腳本：

- `install_gemini-cli.sh` — 安裝
- `uninstall_gemini-cli.sh` — 解除安裝

## 為什麼預設用 `GEMINI.md` 而不是 Skill？

這份 guidelines 的本質是 **always-on 行為紀律**（不要瞎猜假設、不要過度工程、外科手術式修改、目標導向），不是「特定任務才用」的工具型 skill。

- **Skill 模式**：靠 description 關鍵字觸發，agent 沒判斷到就完全不生效。Karpathy 想解決的「LLM 瞎猜假設」這種毛病，恰恰最容易發生在 agent **沒意識到自己該謹慎**的時候 → 結構性破口。
- **GEMINI.md 模式**：每次對話都載入，永遠在線。整份只有 ~70 行，token 成本可忽略。
- 對應 Karpathy 原 repo：`GEMINI.md 模式 ≈ 原作的 CLAUDE.md`，`Skill 模式 ≈ 原作的 Plugin`。

如果你想要「trivial 任務不受拘束」，可以改用 `--mode skill`。

## 快速開始

> 本 fork 在原作 [`forrestchang/andrej-karpathy-skills`](https://github.com/forrestchang/andrej-karpathy-skills) 之上加了 Gemini CLI 的 install / uninstall 腳本。
> **要 clone 這個 fork 才有 `install_gemini-cli.sh`。**

```bash
# clone 本 fork
git clone https://github.com/martin-hsu-test/andrej-karpathy-skills.git
cd andrej-karpathy-skills

# 預設安裝（GEMINI.md, user scope）
./install_gemini-cli.sh
```

完成後新開一個 `gemini` session，這四條原則就會永遠在 context 裡。

## 安裝選項

```bash
./install_gemini-cli.sh [--mode MODE] [--scope SCOPE]
```

### `--mode`

| 值 | 行為 | 對應原作 |
|---|---|---|
| `gemini-md`（預設）| append 到 GEMINI.md，永遠載入 | CLAUDE.md |
| `skill` | 註冊為 Gemini skill，按需觸發 | Plugin |
| `both` | 兩個都裝（雙保險） | — |

### `--scope`

| 值 | GEMINI.md 路徑 | Skill 安裝位置 |
|---|---|---|
| `user`（預設）| `~/.gemini/GEMINI.md` | `~/.gemini/skills/` |
| `workspace` | `$PWD/GEMINI.md` | `./.gemini/skills/` |

### 範例

```bash
# 全域永遠開啟（最常見）
./install_gemini-cli.sh

# 只在當前專案開啟
./install_gemini-cli.sh --scope workspace

# 改用 skill 模式（按需觸發）
./install_gemini-cli.sh --mode skill

# 雙保險
./install_gemini-cli.sh --mode both
```

## 安裝做了什麼

### `--mode gemini-md`
在 `GEMINI.md` 裡加入一段 fenced block：

```markdown
<!-- BEGIN karpathy-guidelines -->
（CLAUDE.md 全文，四大原則）
<!-- END karpathy-guidelines -->
```

- **Idempotent**：重跑會替換整段，不會重複 append
- **不破壞既有內容**：原本 `GEMINI.md` 裡的東西完全保留

### `--mode skill`
等同於：
```bash
gemini skills install ./skills/karpathy-guidelines --scope user --consent
```

## 驗證安裝

```bash
# gemini-md 模式
grep -c 'karpathy-guidelines' ~/.gemini/GEMINI.md

# skill 模式
gemini skills list | grep karpathy

# 在 gemini 互動模式裡
/memory show          # 看 GEMINI.md 是否載入
/skills list          # 看 skill 是否註冊
```

## 解除安裝

```bash
./uninstall_gemini-cli.sh                    # user scope
./uninstall_gemini-cli.sh --scope workspace  # workspace
```

會做兩件事：
1. 從 `GEMINI.md` 移除 fenced block（保留其他內容）
2. 移除 skill（如果有裝）

兩者**不存在時自動跳過**，所以即使你只裝了其中一種也安全。

## 跟原作 Plugin 安裝方式的差異

| 安裝方式 | 適用 CLI | 啟動機制 |
|---|---|---|
| 原作 `/plugin install ...` | Claude Code | Plugin 系統 |
| 原作 `curl ... > CLAUDE.md` | Claude Code | always-on |
| **這份 `install_gemini-cli.sh`** | **Gemini CLI** | **預設 always-on，可選 skill** |

## 故障排除

**`--mode skill` 失敗**
→ 預設 `--mode gemini-md` 不需要 Gemini CLI（只是寫檔），優先用它。  
→ 真要用 skill 模式：先裝 [Gemini CLI](https://github.com/google-gemini/gemini-cli)；如果 `gemini` 是 shell alias（公司 setup 常見），用 `GEMINI_BIN=/path/to/real/gemini ./install_gemini-cli.sh --mode skill`。

**重跑後 `GEMINI.md` 變很長**
→ 不會。腳本用 fenced block，重跑只會替換不會疊加。如果你看到重複，可能是手動編輯時破壞了 `<!-- BEGIN -->` / `<!-- END -->` 標記。

## 設計取捨（誠實說明）

- **偏向 caution over speed**：跟原作一樣的取捨。trivial 任務（typo、明顯一行 fix）會被「請先確認假設」之類的提醒拖慢。如果這對你是問題，用 `--mode skill` 或裝 `--scope workspace` 只在嚴肅專案開啟。
- **不修改原 repo 其他檔案**：這兩支腳本只新增、不改既有檔案，遵守 Karpathy 第 3 條「Surgical Changes」。
