# 项目维护与部署指南

本文档旨在为本项目提供清晰的维护、开发和部署指引，作为后续开发人员的参考和知识沉淀。

## 1. 核心架构概览

本项目采用**“内容与部署分离”**的策略，以满足在私人账户上进行日常维护，同时利用公司账户的GitHub Pages域名进行发布的双重需求。

- **内容源头**: 位于开发者私人GitHub账户的仓库，作为所有文档内容的“唯一真实来源 (Single Source of Truth)”。
- **部署载体**: 位于公司GitHub账户的Fork仓库，其唯一职责是获取上游内容并执行自动化部署。

## 2. 账户与仓库关系

| 实体 | 角色 | GitHub 用户名/仓库 | 说明 |
| :--- | :--- | :--- | :--- |
| **私人账户** | 内容维护者 | `YourPrivateUsername` | 所有内容的创建和修改都在此账户下完成。 |
| **公司账户** | 网站发布者 | `YourCompanyUsername` | 仅用于发布GitHub Pages网站。 |
| **私人仓库** | **上游仓库 (Upstream)** | `YourPrivateUsername/YourDocsRepo` | 存储所有文档的源文件，是主要工作区。 |
| **公司仓库** | **下游仓库 (Downstream)** | `YourCompanyUsername/YourDocsRepo` | 从上游仓库同步内容，并负责执行部署工作流。 |

## 3. SSH多账户管理（备用参考）

本节内容描述了如何在同一台本地机器上通过命令行同时管理两个GitHub账户。**对于当前已确定的“Sync fork”工作流，本节操作并非必需**，但作为一份有价值的技术参考予以保留，以备未来可能需要的更复杂的命令行操作。

### 3.1. 问题背景

GitHub不允许将同一个SSH公钥分配给多个用户账户。尝试这样做会导致 "Key is already in use" 的错误。

### 3.2. 解决方案

为每个账户生成独立的SSH密钥，并通过 `~/.ssh/config` 文件来管理。

#### 配置文件 (`~/.ssh/config`)

```
# 个人GitHub账户配置
Host github.com-personal
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519  # 指向您的私人密钥文件

# 公司GitHub账户配置
Host github.com-company
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_company # 指向您的公司密钥文件
```

#### 使用方法

在克隆或设置远程仓库URL时，使用 `config` 文件中定义的 `Host` 别名，而不是 `github.com`。

- **操作公司仓库**:
  ```bash
  git clone git@github.com-company:YourCompanyUsername/YourDocsRepo.git
  ```

- **操作私人仓库**:
  ```bash
  git clone git@github.com-personal:YourPrivateUsername/YourDocsRepo.git
  ```

## 4. 维护与部署流程

### 4.1. 日常内容更新

所有文档的修改和更新都**必须**在**私人仓库** (`YourPrivateUsername/YourDocsRepo`) 的本地克隆中进行。

1.  在本地编辑文档内容。
2.  像往常一样提交更改并推送到您的私人仓库：
    ```bash
    git add .
    git commit -m "docs: 更新了xxx内容"
    git push
    ```

### 4.2. 通过 Sync fork 同步与部署 (最终方案)

当您希望将最新的文档发布到公司网站时，请使用GitHub官方提供的一键同步功能。

1.  在浏览器中，导航到**公司仓库** (`YourCompanyUsername/YourDocsRepo`) 的GitHub主页。
2.  在代码列表上方，您会看到一行提示 "This branch is X commits behind `YourPrivateUsername:main`."
3.  在这行提示的旁边，点击 **`Sync fork`** 按钮。
4.  在出现的下拉框中，点击绿色的 **`Update branch`** 按钮。

操作完成。这个动作会自动从您的私人仓库拉取最新提交并更新公司仓库，该更新会立即触发后续的网站构建和发布流程。

## 5. 部署自动化详解

本项目使用GitHub官方**内置的自动化工作流** (`pages-build-deployment`) 来实现部署，无需自定义工作流文件。

### 5.1. 触发、构建与发布机制

该工作流的完整机制分为三个步骤：

1.  **触发 (Trigger)**: 每当 `main` 分支有新的 `push` 事件（包括通过`Sync fork`更新），该工作流就会自动从 `main` 分支拉取**源代码**并开始构建。

2.  **构建与提交 (Build & Commit)**: 工作流在云端构建您的 `mkdocs` 项目。关键在于，构建完成后，它会将生成的静态网站文件（HTML/CSS等）自动**提交到一个名为 `gh-pages` 的特殊分支**上。

3.  **发布与配置 (Serve & Configure)**: GitHub Pages服务器从 `gh-pages` 分支读取静态文件并将其发布。因此，仓库的配置**必须**如下：
    *   **路径**: `Settings -> Pages`
    *   **Source**: "Deploy from a branch"
    *   **Branch**: 必须选择 **`gh-pages`** 分支

### 5.2. 智能构建

GitHub的内置工作流足够智能，可以自动识别 `mkdocs` 项目：
- 它会检测 `main` 分支根目录下的 `mkdocs.yml` 和 `requirements.txt` 文件。
- 它会自动创建一个包含Python的环境并安装依赖。
- 它会自动运行 `mkdocs build` 来构建静态网站。
- 最后，它会将构建产物推送到 `gh-pages` 分支，以供发布。

这种方式简化了仓库的维护，因为所有的构建逻辑都由GitHub官方托管和维护。
