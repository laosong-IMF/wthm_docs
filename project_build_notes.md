# MkDocs + Read the Docs 多语言文档项目构建要点

本文档梳理了本项目从零到一的构建过程，总结了核心技术、项目结构、关键配置及工作流，可作为后续维护和学习的参考。

---

### 1. 核心技术：MkDocs

- **MkDocs** 是本项目的核心。它是一个基于 Python 的、快速、简洁的**静态网站生成器**，专门用于构建项目文档。
- 工作模式：用 Markdown 编写文档，通过一个 YAML 配置文件 (`mkdocs.yml`) 来定义网站，最终生成一个完整的静态 HTML 网站。

---

### 2. 项目目录结构

我们最终确定的目录结构是为了清晰地实现**多语言隔离**和**资源共享**：

```
.
├── .readthedocs.yaml     # Read the Docs 的总配置文件
├── mkdocs_en.yml         # 英文版 MkDocs 配置
├── mkdocs_zh.yml         # 中文版 MkDocs 配置
└── docs/
    ├── assets/           # 共享资源 (图片, CSS等)
    │   └── media/
    │       └── image1.png
    ├── en/               # 英文版文档源文件
    │   ├── index.md
    │   └── ...
    └── zh/               # 中文版文档源文件
        ├── index.md
        └── ...
```

- **关注点分离**：`en` 和 `zh` 目录完全独立，互不干扰。`assets` 作为共享资源，独立存放。

---

### 3. 关键配置文件解析

#### a) `mkdocs_en.yml` & `mkdocs_zh.yml` (单个语言的大脑)

这两个文件内容类似，以中文版为例，其核心配置项为：

- `docs_dir: docs/zh/`: **这是关键**。它告诉 MkDocs 在构建时，只把 `docs/zh/` 目录当作文档的根目录。这确保了在构建中文版时，不会包含任何英文版的文件，实现了语言的**构建隔离**。
- `nav`: 定义了该语言版本的导航栏结构，所有路径都是相对于 `docs_dir` 的。
- `markdown_extensions`: 这是 MkDocs 的强大功能之一。我们用它开启了 `attr_list` 扩展，目的是让 Markdown 解析器能识别并处理图片后面的 `{width=180}` 这样的属性，从而控制图片的显示尺寸。

#### b) `.readthedocs.yaml` (构建流程的总指挥)

这是整个自动化和多语言构建流程的**核心**。它告诉 Read the Docs 平台具体要如何操作您的代码仓库：

- **`build.jobs.pre_build`**: 定义了在运行主要的 `mkdocs build` 命令**之前**需要执行的一系列脚本命令。
- **判断语言**: 脚本的核心是 `if [ "$READTHEDOCS_LANGUAGE" = "zh-cn" ]`。`$READTHEDOCS_LANGUAGE` 是 Read the Docs 在构建不同语言版本时为我们提供的环境变量。通过判断它的值，我们就能执行不同的构建逻辑。
- **处理共享资源**: `mkdir -p ... && cp -r ...` 这行命令是解决图片等共享资源问题的关键。它在构建开始前，将公共的 `docs/assets` 目录复制到当前正在构建的语言目录中（例如 `docs/zh/`）。这样一来，即使每个语言的构建是隔离的，它们也都能访问到所需的图片。
- **选择配置文件**: `cp mkdocs_zh.yml mkdocs.yml` 这行命令将对应语言的配置文件重命名为 `mkdocs.yml`，因为这是 Read the Docs 默认会寻找并使用的文件名。

### 4. Read the Docs 平台配置 (多语言的粘合剂)

- **单一项目 + 翻译**：我们在 Read the Docs 上采用的是**一个主项目**（比如英文版）并为其添加**一个翻译**（中文版）的模式。
- **自动切换器**：这种模式是实现网站右下角出现**语言切换菜单**的前提。Read the Docs 会自动发现这两个版本的关联，并生成切换功能。
- **URL 结构**：这种模式也决定了您网站的 URL 结构，即通过 `/en/` 和 `/zh-cn/` 来区分不同语言。

---

### 5. 总结：完整工作流

1.  您将代码 `push` 到 GitHub。
2.  该 `push` 操作触发了 Read the Docs 上的**两次构建**：一次为 `en`，一次为 `zh-cn`。
3.  **在构建 `zh-cn` 版本时**：
    a. Read the Docs 设置环境变量 `$READTHEDOCS_LANGUAGE` 为 `zh-cn`。
    b. `.readthedocs.yaml` 中的脚本检测到这个值，于是将 `assets` 目录复制到 `docs/zh/`，并选择 `mkdocs_zh.yml` 作为配置文件。
    c. MkDocs 基于 `docs/zh` 目录和中文配置，生成一套纯净的中文版 HTML 网站。
4.  **在构建 `en` 版本时**：重复类似的过程，生成英文版网站。
5.  Read the Docs 将这两套独立的网站分别部署到 `/zh-cn/` 和 `/en/` 路径下，最终呈现给用户一个完整的多语言文档。

