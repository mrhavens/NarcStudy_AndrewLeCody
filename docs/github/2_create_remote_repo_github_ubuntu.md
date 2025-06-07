## 📘 `2_create_remote_repo_github_ubuntu.md`

### 📌 Purpose

Create a new remote repository on GitHub and push your local Ubuntu-based Git project to it.

---

### 🪐 Step-by-Step

#### Step 1: Create the remote repository

1. Go to [https://github.com/new](https://github.com/new)
2. Set:

   * Repository Name
   * Visibility (Public or Private)
   * ✅ Leave **"Initialize with README"** unchecked
3. Click **Create repository**

---

#### Step 2: Prepare your local repository

If starting fresh:

```bash
mkdir myproject
cd myproject
git init
```

If converting an existing project:

```bash
cd myproject
git init
```

---

#### Step 3: Add files and commit

```bash
touch README.md  # or edit existing files
git add .
git commit -m "Initial commit"
```

---

#### Step 4: Link to GitHub remote

```bash
git remote add origin git@github.com:your-username/your-repo-name.git
```

---

#### Step 5: Push to GitHub

```bash
git push -u origin main
```

> If you get an error about `main` not existing:

```bash
git branch -M main
git push -u origin main
```

---
