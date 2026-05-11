# 🚀Microsoft Entra ID Lifecycle Automation (MSP Simulation Toolkit)

A PowerShell-based automation toolkit for Microsoft Entra ID (Azure AD) user lifecycle management, designed for onboarding and offboarding users in a Managed Service Provider (MSP) or enterprise environment.

---

## 📌 Overview

This project automates common identity management tasks using Microsoft Graph API, including:

* User onboarding from CSV input
* User offboarding (disable, group removal)
* Security group assignment (license-based model ready)
* Audit logging for all operations

Built for learning and real-world MSP scenarios.

---

## 🧰 Tech Stack

* PowerShell 7+
* Microsoft Graph PowerShell SDK
* Microsoft Entra ID (Azure AD)
* CSV-based automation input
* Git & GitHub for version control

---

## 📁 Project Structure

```
M365-Identity-Automation-Toolkit/
│
├── scripts/
│   ├── onboarding/
│   │   └── onboard-users.ps1
│   ├── offboarding/
│   │   └── offboard-users.ps1
│   ├── config/
│   │   ├── auth.ps1 (ignored)
│   │   └── auth.sample.ps1
│   ├── input/
│   │   ├── users.csv
│   │   └── offboard-users.csv
│
├── logs/ (ignored)
├── .gitignore
└── README.md
```

---

## ⚙️ Features

### 👤 Onboarding Automation

* Creates new users in Microsoft Entra ID
* Reads user data from CSV
* Assigns department & job title
* Prepares for group/license assignment

### 🚪 Offboarding Automation

* Disables user accounts
* Removes from security groups
* Prepares account for deletion or retention
* Generates audit logs

### 📊 Logging System

* Tracks onboarding/offboarding actions
* Stores logs locally (excluded from GitHub)

---

## 📥 Sample CSV Format

### Users (Onboarding)

```csv
FirstName,LastName,Department,JobTitle,Email
John,Doe,IT,System Administrator,john.doe@contoso.com
```

---

## 🔐 Security Best Practices

* No secrets stored in GitHub repository
* Authentication handled via external `auth.ps1`
* Sensitive files excluded using `.gitignore`
* Uses `auth.sample.ps1` for safe configuration reference

---

## ⚠️ Important Notes

* This project uses Microsoft Graph API App Registration
* Requires proper Entra ID permissions:

  * User.ReadWrite.All
  * Directory.ReadWrite.All
  * Group.ReadWrite.All
* Intended for educational and MSP simulation environments

---

## 🚀 Future Improvements

* Azure Key Vault integration
* License assignment automation (M365 E3/E5)
* Intune device onboarding
* CI/CD pipeline with GitHub Actions
* JSON-based logging system

---

## 👨‍💻 Author

Built as a hands-on DevOps / Microsoft 365 automation project focusing on identity lifecycle management, PowerShell scripting, and cloud administration.

---

## 📌 Purpose

This project demonstrates practical skills in:

* Microsoft 365 administration
* Identity lifecycle automation
* PowerShell scripting
* API-based automation (Microsoft Graph)
* Secure DevOps practices

---
