### 📘 `1_prerequisites_gitlab_ubuntu.md`

````markdown
## 📘 `1_prerequisites_gitlab_ubuntu.md`

### 📌 Purpose

Prepare your Ubuntu system to create and work with remote GitLab repositories using SSH and CLI tools.

---

### ✅ System Requirements

* **Install Git**

```bash
sudo apt update
sudo apt install git -y
````

* **Create a GitLab account**
  👉 [https://gitlab.com/users/sign\_up](https://gitlab.com/users/sign_up)

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

* **Add your SSH key to GitLab**

```bash
cat ~/.ssh/id_rsa.pub
```

🔗 Copy the output and paste it at:
GitLab → Preferences → SSH Keys → *Add key*

* **Test the connection**

```bash
ssh -T git@gitlab.com
```

✅ You should see something like:

> Welcome to GitLab, @your-username!

---

````

---

