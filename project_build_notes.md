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

---

### 6. 本地开发与 Read the Docs 行为差异的根源及解决方案

**问题现象：**

在 Read the Docs 上，文档（包括图片）可以正常显示。但在本地使用 `mkdocs serve -f mkdocs_en.yml` 或 `mkdocs serve -f mkdocs_zh.yml` 时，图片会提示找不到，导致无法正常加载。

**根源分析：**

这种差异的根本原因在于 Read the Docs 的构建流程中，有一个关键的 `pre_build` 步骤（定义在 `.readthedocs.yaml` 中），而本地的 `mkdocs serve` 命令不会自动执行这个步骤。

具体来说：

1.  **Read the Docs 的行为：**
    当 Read the Docs 构建文档时，它会根据当前构建的语言（例如 `zh-cn` 或 `en`），在运行 MkDocs 之前，执行以下操作：
    *   `cp -r docs/assets docs/zh/` (或 `cp -r docs/assets docs/en/`)：将项目根目录下的 `docs/assets` 目录（包含所有共享图片）完整复制到当前语言的文档目录（例如 `docs/zh/`）内部。
    *   `cp mkdocs_zh.yml mkdocs.yml` (或 `cp mkdocs_en.yml mkdocs.yml`)：将对应语言的配置文件复制并重命名为 `mkdocs.yml`。
    这样，当 MkDocs 真正开始构建时，它所使用的 `docs_dir` (例如 `docs/zh/`) 内部已经包含了 `assets` 目录的副本。因此，Markdown 文件中引用的 `assets/media/imageX.png` 路径能够正确解析，图片也就能正常显示。

2.  **本地 `mkdocs serve` 的行为：**
    在本地运行 `mkdocs serve -f mkdocs_zh.yml` 时，MkDocs 会将 `docs/zh/` 视为其文档根目录。然而，由于没有执行上述的 `cp -r` 操作，`docs/zh/` 目录下并没有 `assets` 目录的副本。因此，当 `docs/zh/wifi-setup.md` 尝试引用 `assets/media/imageX.png` 时，MkDocs 会在 `docs/zh/assets/media/imageX.png` 路径下查找，但该路径不存在，从而导致图片加载失败并报错。

**解决方案：**

为了在本地开发环境中也能正确预览文档并加载图片，您需要在运行 `mkdocs serve` 命令之前，手动执行与 Read the Docs `pre_build` 步骤中相同的 `cp -r` 操作。

**具体操作步骤：**

1.  **复制共享资产：**
    在项目根目录下执行以下命令，将 `docs/assets` 复制到 `docs/zh/` 和 `docs/en/`：
    ```bash
    cp -r docs/assets docs/zh/
    cp -r docs/assets docs/en/
    ```
2.  **运行本地服务：**
    执行您需要的 MkDocs 服务命令，例如：
    ```bash
    mkdocs serve -f mkdocs_en.yml
    # 或者
    mkdocs serve -f mkdocs_zh.yml
    ```
    此时，图片应该能够正常加载。

3.  **清理（可选但推荐）：**
    在停止本地服务后，您可以选择删除这些复制的 `assets` 目录，以保持工作目录的整洁，避免不必要的 Git 跟踪：
    ```bash
    rm -rf docs/zh/assets
    rm -rf docs/en/assets
    ```

**自动化本地开发流程：**

为了简化上述步骤，我已经为您创建了一个 `serve_docs.sh` 脚本。您只需运行 `bash serve_docs.sh`，它将自动完成复制资产、启动两个语言的 MkDocs 服务，并在您停止服务时自动清理复制的资产。这样既能保证本地预览的正确性，又不会影响 Git 仓库的结构。