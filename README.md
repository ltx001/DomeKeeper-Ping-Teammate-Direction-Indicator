# Dome Keeper Team Ping HUD

A lightweight co-op HUD mod for Dome Keeper. It adds edge indicators for off-screen teammates and synchronized position pings for online and local split-screen multiplayer.

## Features

- Cyan edge chevrons point toward off-screen teammates.
- Yellow edge chevrons and diamond markers show player pings.
- Short presses create 60-second pings; long presses create 5-minute pings.
- Pressing ping again near your existing marker cancels it.
- Every local split-screen player receives an independent overlay.
- Ping bindings appear under `Settings > Key Bindings > General > Team Ping`.
- Default controls: middle mouse button and right-stick click (R3/RS).

Pings mark the Keeper's current position, rather than the mouse cursor or aim point.

## Installation

The standard Steam release does not load community script mods by itself. Select the `staging` beta branch and apply the [Dome Keeper Mod Loader Patcher](https://github.com/LeonardoLuca/dome-keeper-coop-mod-patcher/releases/latest) before using this mod.

### Steam Workshop

Subscribe to the Workshop item, then launch the patched game. Reapply the patcher after Dome Keeper updates replace the patched game pack.

### Manual

1. Download `Codex-TeamPingHud.zip` from the latest GitHub release.
2. Place it in the Dome Keeper `mods` directory next to `domekeeper.pck`.
3. Start the patched game.

## Building

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\package.ps1
```

This creates `dist/Codex-TeamPingHud.zip`. To also install it locally:

```powershell
powershell -ExecutionPolicy Bypass -File .\package.ps1 -GameDir "D:\path\to\Dome Keeper"
```

The archive uses forward-slash ZIP entry paths required by Mod Loader 7.x.

## Compatibility

- Dome Keeper 5.0+
- Dome Keeper Mod Loader 7.0.1+
- Online co-op and local split-screen

## License

Released under the [MIT License](LICENSE).

---

# Dome Keeper 队伍标点 HUD

这是一个轻量级多人 HUD Mod，为联机和本地分屏模式添加屏幕边缘队友指示箭头及同步位置标点。

- 青色箭头指向屏幕外的队友。
- 黄色箭头和菱形标记显示玩家标点。
- 短按标点保留 60 秒，长按保留 5 分钟。
- 在已有标点附近再次按下会取消标点。
- 默认按键为鼠标中键和右摇杆按下（R3/RS）。
- 可在 `设置 > 按键绑定 > 通用 > 队伍标点` 中修改。

使用前需要切换到 Dome Keeper 的 `staging` 测试分支并安装上方链接中的 Mod Loader Patcher。
