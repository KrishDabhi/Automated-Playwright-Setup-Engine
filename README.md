# 🚀 All-in-One Portable Playwright Installation Engine

This is a **100% portable**, self-bootstrapping automation suite for Playwright, designed for maximum reliability, speed, and **zero system footprint**.

---

## 📥 How to Get Started

To use this engine, you first need to download the project files:

1.  **Click the green "<> Code" button** at the top right of this GitHub page.
2.  Select **"Download ZIP"** from the dropdown menu.
3.  **Extract the ZIP file** to a folder on your computer.
4.  Open the newly extracted folder and follow the "Quick Start" steps below.

---

## ⚡ Quick Start (Single Command)

| OS | Action | Simple Command |
| :--- | :--- | :--- |
| **Windows** | Double-click | `run.bat` |
| **Mac/Linux**| Run in terminal | `bash run.sh` |

---

## 📂 Final Clean Structure

The project is split into a **User Area** (clean root) and a hidden **Engine Room**:

- `run.bat` / `run.sh`: **The Launchers.** Double-click or run these to start everything.
- `task.json`: **The Config File.** This is the only file you need to edit to change your automation.
- `internal/`: **The Engine Room.** Contains the verbose engine logic, Node.js, and browser binaries.

---

## 🛠️ Viewing the Process (Verbosity)

When you run the engine, it provides a clear **7-step diagnostic log** in your console. You will see:
1.  **Initialization**: Loading internal engine room.
2.  **Detection**: Identifying your OS and Architecture.
3.  **Node.js Check**: Validating if system Node is suitable or if private Node is needed.
4.  **Engine Decision**: Choosing the best suit for your hardware.
5.  **Environment Sync**: Configuring isolated paths.
6.  **Dependency Check**: Ensuring libraries and browsers are ready.
7.  **Final Execution**: Launching the runner.

---

## 🧹 Cleanup & Uninstallation

To completely remove the suite:
1.  Close any running automation windows.
2.  **Delete only the `internal/` folder** (to remove the engine) or the entire project folder to remove everything.

Since the engine uses session-based redirection, **nothing** ever leaves the folder. Your computer remains as clean as it was before you started.
