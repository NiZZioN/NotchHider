<h1 align="center">⬛ Notch Hider</h1>

<p align="center"><b>Paints your MacBook's menu bar true black, so the notch disappears into it.</b></p>

<p align="center">
  <img src="https://img.shields.io/badge/Swift-F05138?style=for-the-badge&logo=swift&logoColor=white" alt="Swift">
  <img src="https://img.shields.io/badge/SwiftUI_+_AppKit-0D96F6?style=for-the-badge&logo=swift&logoColor=white" alt="SwiftUI + AppKit">
  <img src="https://img.shields.io/badge/macOS_13+-000000?style=for-the-badge&logo=apple&logoColor=white" alt="macOS 13+">
  <img src="https://img.shields.io/badge/Apple_silicon-333333?style=for-the-badge&logo=apple&logoColor=white" alt="Apple silicon">
  <img src="https://img.shields.io/badge/Swift_Testing-F05138?style=for-the-badge&logo=swift&logoColor=white" alt="Swift Testing">
  <img src="https://img.shields.io/badge/License-MIT-2EA043?style=for-the-badge" alt="MIT License">
</p>

---

## ✨ What's inside

| | Feature | | Feature |
|:-:|---|:-:|---|
| ⬛ | **True black**: every pixel RGB 0, verified | 🧊 | **Blurred glass**: 1–100% strength |
| 🔲 | **Round corners**: 0–20 pt slider | 🖥️ | **Notched screens only**: externals untouched |
| 🚀 | **Launch at login**: native Login Items | 👻 | **Hideable icon**: reopen app for settings |
| 🔄 | **Follows changes**: displays, Spaces, wake | 🧪 | **Tested**: unit + live pixel checks |

---

## 🗺️ How it fits together

```mermaid
flowchart LR
    S["⚙️ Settings<br/>+ menu icon"] -->|"UserDefaults"| A["Notch Hider"]
    A -->|"one per notched screen"| W["Strip window<br/>under the menu bar"]
    W -->|"black or glass"| M["Menu bar<br/>drawn on top"]
    A -->|"SMAppService"| L["Login Items"]
    D["🖥️ Display, Space<br/>and wake events"] -.->|"rebuild"| A

    classDef app fill:#F05138,stroke:#F05138,color:#fff
    classDef ui fill:#0D96F6,stroke:#0D96F6,color:#fff
    classDef sys fill:#333333,stroke:#333333,color:#fff
    class A app
    class S,W ui
    class M,L,D sys
```

---

## 🚀 Quick start

Needs a Mac with a notch and Xcode or the Command Line Tools (`xcode-select --install`).

**1. Build and install** (runs the tests, copies the app to `~/Applications`, starts it)

```sh
git clone https://github.com/NiZZioN/NotchHider.git && cd NotchHider
./install.sh --login        # --login turns on Launch at login; --dest /Applications to install elsewhere
```

**2. Configure:** click the menu bar icon → **Settings…** (or open Notch Hider again if you hid the icon).

**3. Uninstall**

```sh
./uninstall.sh              # removes the login item, the app and its settings
```

| 🧪 Unit tests | 🎯 Live black check | 🔁 Live restyle check |
|:-:|:-:|:-:|
| `./test.sh` | `./verify-live.sh` | `./verify-restyle.sh` |

The live checks capture the real strip window as 16-bit float pixels and require exactly RGB 0. They need Screen Recording permission for your terminal; `verify-live.sh` restarts the app twice and restores your settings.

---

📚 [Source](Sources) · [Tests](Tests) · [Info.plist](Info.plist) (change `CFBundleIdentifier` there for your own fork) · [MIT License](LICENSE)
