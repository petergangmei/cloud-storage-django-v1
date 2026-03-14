# 🚀 Django Server Deployment Guide

This directory contains automated scripts and configuration templates for deploying the **{{PROJECT_NAME}}** Django project on an Ubuntu-based VPS (like AWS EC2, DigitalOcean, etc.).

## 📁 Directory Structure

```text
server/
├── deploy.env          # ⚙️ Centralized configuration (EDIT THIS FIRST)
├── setup.sh            # 🛠️ Main automation script
├── stage/              # 🏗️ Staging environment templates (Nginx/Gunicorn)
└── live/               # 💎 Production environment templates (Nginx/Gunicorn)
```

---

## 🛠️ Prerequisites

1.  **Server**: A fresh Ubuntu 22.04+ instance.
2.  **SSH Access**: You should be able to SSH into the server as a user with `sudo` privileges (usually `ubuntu`).
3.  **Domain**: Point your domain/subdomain A-records to the server's IP.

---

## 🚀 Setup Instructions

### 1. Clone the Project
SSH into your server and clone your repository into the home directory:

```bash
cd /home/ubuntu
git clone <your-repo-url> cloud
```

### 2. Configure Your Variables
Open `server/deploy.env` and update the variables to match your project and domain:

```bash
nano server/deploy.env
```

### 3. Run the Setup Script
The script handles everything: installing Nginx/Python, setting up Virtualenvs, and configuring Systemd services.

```bash
chmod +x server/setup.sh
./server/setup.sh
```

**Choose the appropriate option:**
- `1` for a fresh server installation.
- `2` for updating an existing instance.
- `3` to simply restart the services.

### 4. Create a Superuser
Once the setup is complete, navigate to your project folder and create an admin user:

```bash
source venv/bin/activate
python manage.py createsuperuser
```

---

## 📜 Key Commands

- **Check Project Logs**: `sudo journalctl -u cloud.service -f`
- **Nginx Status**: `sudo systemctl status nginx`
- **Restart App**: `./server/setup.sh` (Then choose option 3)

## 🔒 Security Notes
- Ensure your EC2 Security Group allows **Port 80 (HTTP)** and **Port 443 (HTTPS)**.
- For SSL, it is highly recommended to run **Certbot** after this setup:
  `sudo apt install certbot python3-certbot-nginx && sudo certbot --nginx`
