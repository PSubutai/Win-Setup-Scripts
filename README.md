# Windows Setup Scripts

A collection of PowerShell scripts and other resources for setting up a new Windows 11 install.

**Note**: This was intended to only be used by me. It is likely not something the average user would want to use, and it may contain customisations that you do not want.

**Warning**: If you do not know what you are doing and use what you see here, you may damage your Windows installation. I am not at fault for any damage you may cause.

## Table of Contents

### Scripts:

- [install-apps.ps1](#install-appsps1)

### Other:

- [ChrisTitusTech's PowerShell Profile (Pretty PowerShell)](#christitustechs-powershell-profile-pretty-powershell)
- [Chris Titus Tech's Windows Utility (Winutil)](#chris-titus-techs-windows-utility-winutil)

---

### install-apps.ps1

Installs a configurable list of Windows applications via three methods: **winget**, **Chocolatey**, and **direct download** (raw URL or latest GitHub release asset).

Edit the three app lists at the top of the script. You can then either paste the whole script into the FirstLogon field of the [schneegans.de unattend generator](https://schneegans.de/windows/unattend-generator/) or invoke it remotely by instead entering:

```powershell
irm https://raw.githubusercontent.com/PSubutai/Win-Setup-Scripts/main/install-apps.ps1 | iex
```

You can also run it manually (as Administrator):

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\install-apps.ps1
```
---

## Others

### [ChrisTitusTech's PowerShell Profile (Pretty PowerShell)](https://github.com/ChrisTitusTech/powershell-profile)

A stylish and functional PowerShell profile that looks and feels almost as good as a Linux terminal.

#### ⚡ One Line Install (Elevated PowerShell Recommended)

Execute the following command in an elevated PowerShell window to install the PowerShell profile:

```powershell
irm "https://github.com/ChrisTitusTech/powershell-profile/raw/main/setup.ps1" | iex
```

#### OR it can be installed from Chris Titus Tech's Windows Utility below.
---

### [Chris Titus Tech's Windows Utility (Winutil)](https://github.com/ChrisTitusTech/winutil)

A tool for debloating, tweaking, and troubleshooting Windows installations.

Run command in an elevated PowerShell or Windows Terminal:

#### Stable Branch:

```powershell
irm "https://christitus.com/win" | iex
```

#### Dev Branch:

```powershell
irm "https://christitus.com/windev" | iex
```
---
