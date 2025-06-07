---

## 🧭 FULL CLI-ONLY WORKFLOW (Ubuntu + GitHub)

---

### 🔹 Step 1 — Install prerequisites

```bash
# Install Git
sudo apt update
sudo apt install git -y

# Install GitHub CLI
type -p curl >/dev/null || sudo apt install curl -y
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
  sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
  https://cli.github.com/packages stable main" | \
  sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh -y
```

---

### 🔹 Step 2 — Authenticate with GitHub

```bash
gh auth login
```

* Choose: `GitHub.com`
* Protocol: `SSH`
* Authenticate via browser (first time only—after that you're CLI-auth’d)

---

### 🔹 Step 3 — Set global Git identity

```bash
git config --global user.name "Your Name"
git config --global user.email "your_email@example.com"
```

---

### 🔹 Step 4 — Create and link a new GitHub repo (CLI-only)

From inside your project directory:

```bash
mkdir myproject
cd myproject
git init
echo "# My Project" > README.md
git add .
git commit -m "Initial commit"
```

Now create a GitHub repo **from the CLI**:

```bash
gh repo create myproject --public --source=. --remote=origin --push
```

✅ This:

* Creates the remote GitHub repo
* Links it to your local repo
* Pushes your first commit to GitHub

---

### 🔹 Step 5 — Make further commits

```bash
# Edit files as needed
nano something.txt

# Stage + commit + push
git add .
git commit -m "Updated something"
git push origin main
```

---

### 🔹 Bonus — Clone a GitHub repo entirely from CLI

```bash
gh repo clone your-username/your-repo
cd your-repo
```

---
