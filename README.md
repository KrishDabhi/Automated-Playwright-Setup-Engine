# 🚀 All-in-One Portable Playwright installation Engine

This is a 100% portable, self-bootstrapping automation suite for Playwright designed for maximum reliability and **zero system footprint**.

---

## 🌟 Key Features

- **Portability**: Carries its own Node.js engine and Playwright browsers.
- **Zero-Trace**: Deleting the project folder removes everything (No leftover caches or registry keys).
- **Hybrid Detection**: Reuses system tools if compatible, otherwise builds a private environment.
- **Security-First**: Bypasses Administrator/UAC blocks by using localized "Extraction" instead of system-wide installation.

---

## ⚡ Quick Start (Single Command)

| OS | Action | Simple Command |
| :--- | :--- | :--- |
| **Windows** | Double-click | `run.bat` |
| **Mac/Linux**| Run in terminal | `bash run.sh` |

---

### 🪟 Windows (Foolproof)
1. Open the project folder.
2. **Double-click `run.bat`**.
That's it. Permissions and engines are handled automatically.

### 🍎 Mac & Linux (One-Line)
1. Open terminal in the project folder.
2. Run: `bash run.sh`
This will automatically set permissions and start the engine.

---

## 📂 Project Structure

- `run.bat` / `run.sh`: Simple, one-click launchers.
- `task.json`: **The Config File.** This is the only file you need to edit to change your automation.
- `internal/`: The "Engine Room" (Contains the private Node.js, Playwright, and logic. You don't need to touch this).

---

## 🛠️ Customizing the Automation

To change what the automation does, simply edit the **`task.json`** file in the root folder. You can add or modify steps using the supported actions:
- `goto`: Navigate to a URL.
- `click`: Click an element via selector.
- `fill`: Fill an input field.
- `wait`: Pause for X milliseconds.
- `verifyText`: Ensure specific text is present on the page.

---

## 🧹 Cleanup & Uninstallation

To completely remove the suite from your system:
1.  Close any running automation windows.
2.  **Delete the entire project folder.**

Since the engine uses session-based redirection, **nothing** ever left the folder. Your computer remains as clean as it was before you started.