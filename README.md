# Windows Setup Scripts

A collection of PowerShell scripts for setting up a new Windows 11 install.

## Table of Contents

- [install-apps.ps1](#install-appsps1)

---

### install-apps.ps1

Installs a configurable list of Windows applications via three methods: **winget**, **Chocolatey**, and **direct download** (raw URL or latest GitHub release asset).

Edit the three app lists at the top of the script. You can then either paste the whole script into the FirstLogon field of the [schneegans.de unattend generator](https://schneegans.de/windows/unattend-generator/) or invoke it remotely by instead entering:

```powershell
irm https://raw.githubusercontent.com/<user>/<repo>/main/install-apps.ps1 | iex
```

You can also run it manually (as Administrator):

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\install-apps.ps1
```
