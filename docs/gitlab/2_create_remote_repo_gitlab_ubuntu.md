### 📘 `2_create_remote_repo_gitlab_ubuntu.md`

```markdown
## 📘 `2_create_remote_repo_gitlab_ubuntu.md`

### 📌 Purpose

Create a new GitLab repository and push your local Ubuntu project to it using the CLI.

---

### 🪐 Step-by-Step

#### Step 1: Install GitLab CLI

```bash
curl -s https://raw.githubusercontent.com/profclems/glab/trunk/scripts/install.sh | sudo bash
````

#### Step 2: Authenticate GitLab CLI

```bash
glab auth login
```

Choose:

* GitLab.com or custom instance
* Paste your **Personal Access Token** when prompted

---

#### Step 3: Initialize your project

```bash
mkdir myproject
cd myproject
git init
echo "# My Project" > README.md
git add .
git commit -m "Initial commit"
```

---

#### Step 4: Create GitLab repository via CLI

```bash
glab repo create myproject --visibility public --confirm
```

This:

* Creates the GitLab repo
* Links it to your local repo
* Adds `origin` remote

---

#### Step 5: Push to GitLab

```bash
git push -u origin master
```

✅ From now on, `git push` will work as expected.

---

````

---

