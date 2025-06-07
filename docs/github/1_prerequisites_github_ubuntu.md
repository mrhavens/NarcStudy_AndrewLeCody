## 📘 `1_prerequisites_github_ubuntu.md`

### 📌 Purpose

Prepare your Ubuntu system to create and work with remote GitHub repositories using SSH.

---

### ✅ System Requirements

* **Install Git**

```bash
sudo apt update
sudo apt install git -y
```

* **Create a GitHub account**
  👉 [https://github.com/join](https://github.com/join)

* **Set your Git identity**

```bash
git config --global user.name "Your Name"
git config --global user.email "your_email@example.com"
```

* **Generate an SSH key (if not already present)**

```bash
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
```

* **Add your SSH public key to GitHub**

```bash
cat ~/.ssh/id_rsa.pub
```

🔗 Copy the output and paste it at:
GitHub → Settings → SSH and GPG keys → *New SSH key*

* **Test the connection**

```bash
ssh -T git@github.com
```

You should see:

> "Hi `your-username`! You've successfully authenticated..."

---
