## 📘 `3_commit_existing_repo_github_ubuntu.md`

### 📌 Purpose

Work with an existing remote GitHub repository on Ubuntu. This includes cloning, committing changes, and pushing updates.

---

### 🛠️ Step-by-Step

#### Step 1: Clone the repository

```bash
git clone git@github.com:your-username/your-repo-name.git
cd your-repo-name
```

---

#### Step 2: Make your changes

```bash
nano example.txt
```

Or update files as needed.

---

#### Step 3: Stage and commit your changes

```bash
git add .
git commit -m "Describe your update"
```

---

#### Step 4: Push to GitHub

```bash
git push origin main
```

> Use the correct branch name if not `main`. Confirm with:

```bash
git branch
```

---
