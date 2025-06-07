### 📘 `CLI-ONLY_workflow_gitlab_ubuntu.md`

```markdown
## 📘 `CLI-ONLY_workflow_gitlab_ubuntu.md`

### 📌 Purpose

Set up, initialize, and push a GitLab repo using only the terminal — no browser required.

---

### 🪐 Step-by-Step CLI Workflow

#### 1. Install everything you need

```bash
sudo apt update
sudo apt install git curl -y
curl -s https://raw.githubusercontent.com/profclems/glab/trunk/scripts/install.sh | sudo bash
````

#### 2. Configure your Git identity

```bash
git config --global user.name "Your Name"
git config --global user.email "your_email@example.com"
```

#### 3. Authenticate with GitLab

```bash
glab auth login
```

Use **SSH** and paste your **Personal Access Token** (create one at [https://gitlab.com/-/profile/personal\_access\_tokens](https://gitlab.com/-/profile/personal_access_tokens))

---

#### 4. Initialize your project

```bash
mkdir myproject
cd myproject
git init
touch README.md
git add .
git commit -m "Initial commit"
```

#### 5. Create GitLab repo via CLI

```bash
glab repo create myproject --visibility public --confirm
```

#### 6. Push your changes

```bash
git push -u origin master
```

---

✅ Done. You've created and linked a GitLab repository entirely from the CLI.

```

---

