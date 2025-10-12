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

## 3. SSH多账户管理

为了在同一台本地机器上同时操作两个GitHub账户，我们配置了SSH，使其能根据目标仓库自动选择正确的SSH密钥。

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
  # 克隆
  git clone git@github.com-company:YourCompanyUsername/YourDocsRepo.git
  # 或修改现有仓库
  git remote set-url origin git@github.com-company:YourCompanyUsername/YourDocsRepo.git
  ```

- **操作私人仓库**:
  ```bash
  # 克隆
  git clone git@github.com-personal:YourPrivateUsername/YourDocsRepo.git
  # 或修改现有仓库
  git remote set-url origin git@github.com-personal:YourPrivateUsername/YourDocsRepo.git
  ```

#### 验证连接

```bash
# 测试私人账户连接
ssh -T git@github.com-personal

# 测试公司账户连接
ssh -T git@github.com-company
```

## 4. 维护与部署流程

### 4.1. 日常内容更新

所有文档的修改和更新都**必须**在**私人仓库**的本地克隆中进行。

1.  在本地编辑文档内容。
2.  像往常一样提交更改：
    ```bash
    git add .
    git commit -m "docs: 更新了xxx内容"
    git push origin main
    ```
3.  此操作仅将代码推送到您的私人仓库。

### 4.2. 通过Pull Request同步与部署

当您希望将最新的文档发布到公司GitHub Pages网站时，需要通过创建一个跨仓库的Pull Request来同步内容并触发自动部署。

1.  在浏览器中，导航到**公司仓库**的GitHub页面。
2.  点击仓库主页上方的 `Pull requests` 标签页。
3.  点击绿色的 `New pull request` 按钮。
4.  **关键步骤**: 默认页面是比较同一个仓库内的分支。您需要点击蓝色的 `compare across forks` 链接。
5.  现在您会看到四个下拉框，请按以下方式设置：
    *   **base repository**: 选择公司仓库 `YourCompanyUsername/YourDocsRepo`
    *   **base**: 选择 `main` 分支
    *   **head repository**: 选择您的私人仓库 `YourPrivateUsername/YourDocsRepo`
    *   **compare**: 选择 `main` 分支
6.  确认更改后，点击 `Create pull request`。
7.  为这个PR添加一个标题（例如“Sync from upstream”），然后再次点击 `Create pull request`。
8.  在PR页面，确认无误后，点击 `Merge pull request` 并确认合并。

合并操作完成后，GitHub的自动化部署流程将被触发。

## 5. 部署自动化详解

本项目使用GitHub官方**内置的自动化工作流** (`pages-build-deployment`) 来实现部署，无需自定义工作流文件。

### 5.1. 触发机制

该工作流由**公司仓库**的 `Settings -> Pages` 配置驱动。

- **配置**: "Build and deployment" 的 "Source" 必须设置为 "**Deploy from a branch**"，并选择 `main` 分支。
- **触发**: 每当 `main` 分支有新的 `push` 事件（包括合并Pull Request），该工作流就会自动运行。

### 5.2. 智能构建

GitHub的内置工作流足够智能，可以自动识别 `mkdocs` 项目：
- 它会检测仓库根目录下的 `mkdocs.yml` 和 `requirements.txt` 文件。
- 它会自动创建一个包含Python的环境。
- 它会自动运行 `pip install -r requirements.txt` 来安装依赖。
- 它会自动运行 `mkdocs build` 来构建静态网站。
- 最后，它会将构建好的网站发布到GitHub Pages。

这种方式简化了仓库的维护，因为所有的构建逻辑都由GitHub官方托管和维护。

