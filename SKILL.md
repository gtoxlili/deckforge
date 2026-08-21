---
name: DeckForge
description: |
  用 DeckForge CLI 制作多页演示文稿——PPT、pitch deck、月报、季度复盘、提案、培训材料。
  用户需要 3 页以上的演示文稿，或需要为已有 PPT 重做视觉时使用。产出为原生可编辑的
  PPTX（文字、形状、表格、图表在 PowerPoint 中可继续修改）或 PDF。内置成套 design
  system、PPTL 源码格式、渲染预览与校验；作业方法论随二进制分发，由 `deckforge brief`
  输出。
  触发词（中文）："做份 PPT"、"做一份演示文稿"、"pitch deck"、"做一份提案"、
  "品牌月报"、"季度复盘 deck"、"发布会 PPT"、"汇报 slides"、"培训材料"、"路演 PPT"、
  "把这份 PPT 重做好看"。
  触发词（English）："make a deck"、"build slides"、"pitch deck"、
  "presentation for..."、"quarterly review deck"、"redo this ppt"。
  不适用于单页海报、KV、长图，以及仅修改文字而不重做视觉的 .pptx 小改。
metadata:
  short-description: 制作原生可编辑的多页 PPTX / PDF 演示文稿
---

# DeckForge

## 安装

macOS：

```bash
deckforge version || curl -fsSL https://deckforge.gtio.work/install.sh | sh
```

Windows（PowerShell）：

```powershell
deckforge version; if (-not $?) { irm https://deckforge.gtio.work/install.ps1 | iex }
```

单文件，离线可用。macOS 装到 `~/.local/bin/deckforge`；Windows 装到
`%LOCALAPPDATA%\deckforge\bin` 并加入当前用户 PATH（需新开终端生效）。

`deckforge doctor` 报告本机能力：`preview` 与 `build --format pdf` / `png` 需要
本机安装 Chrome、Chromium 或 Edge（或设置 `CHROME_PATH`）；Windows 自带 Edge，
通常无需另装。`build --format pptx` 与 `html` 不依赖浏览器。

## 方法论

```bash
deckforge brief
```

该输出包含工作流、PPTL 语法完整参考、设计纪律、图表规则、字体选型方法、预设形状
名单与授权条款。

PPTL 仅在 DeckForge 内有定义。brief 与解析 PPTL 的解析器出自同一次构建，因此是
本机上唯一保证与渲染器一致的规格说明。

`deckforge brief --section <slug>` 输出单节；`--list-sections` 列出全部小节。

## 命令面

| 命令 | 用途 |
|---|---|
| `deckforge brief [--section <slug>]` | 作业方法论 |
| `deckforge fonts [--cjk] [--embeddable]` | 本机已装字体，带可内嵌 / 覆盖汉字标记 |
| `deckforge systems` | design system 索引 |
| `deckforge systems show <slug> [--full]` | 该系统的 theme；`--full` 追加完整配方与封面样例 |
| `deckforge systems cover <slug> --headline "..." -o x.png` | 以给定文案渲染该系统的封面 |
| `deckforge new <dir> --title T [--system <slug>] [--size WxH]` | 创建 deck 项目 |
| `deckforge page write <dir> <name> [-f f.yaml] [--position N]` | 写入一整页，亦可从 stdin 读入 |
| `deckforge page edit <dir> <name> --target ... --replace ...` | 页内唯一片段替换 |
| `deckforge page rm <dir> <name>` | 删除一页 |
| `deckforge source <dir> [page]` | 清单与校验报告，或指定页源码 |
| `deckforge manifest edit <dir> --target ... --replace ...` | 修改清单（theme、页序、标题） |
| `deckforge check <dir>` | 执行校验，存在 error 时退出码非 0 |
| `deckforge preview <dir> [--pages 1,3] [-o dir]` | 每页 PNG 与总览拼图 |
| `deckforge build <dir> --format pptx\|pdf\|png\|html [-o out]` | 导出成品 |
| `deckforge license [activate <token>]` | 授权状态与激活 |
| `deckforge terms` | 授权条款 |
| `deckforge doctor` | 环境自检 |

`check`、`source`、`page write`、`page edit` 支持 `--json`。每条命令均有 `--help`。

一个 deck 项目即磁盘上的普通目录：`deck.pptl` 清单、`pages/*.page` 与 `media/`。
所有命令以目录路径为操作对象，页面以不带扩展名的裸名寻址（如 `01-cover`）。

## 授权

未授权状态下全流程可用；导出成品每页带署名水印，末尾附加一页联系页。

```bash
deckforge license activate <token>          # 存一次，之后所有命令免传
deckforge build ./deck --format pptx --token <token>
```

也可使用环境变量 `DECKFORGE_TOKEN`。传入的 token 未通过验证时命令报错退出，不会
静默降级为带水印的输出。

条款以 `deckforge terms` 的输出为准。
