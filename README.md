# Ping&Teammate direction indicator

![Ping&Teammate direction indicator cover](workshop/Ping-Teammate-Direction-Indicator-preview.png)

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

## Important

The default Steam release of Dome Keeper does not load community mods. Use the independent, auditable [Dome Keeper Mod Loader Enabler](https://github.com/ltx001/DomeKeeper-ModLoader-Enabler) with the Steam `staging` build. The enabler activates the Godot Mod Loader already included with the game; it does not install or bundle any mod.

## Step-by-step installation

1. Click the `+ Subscribe` button on the [Steam Workshop page](https://steamcommunity.com/sharedfiles/filedetails/?id=3765500877).
2. In your Steam Library, right-click Dome Keeper, select `Properties > Betas`, then change Beta Participation to `staging`. Steam will download a small update.
3. Download the latest [Dome Keeper Mod Loader Enabler release](https://github.com/ltx001/DomeKeeper-ModLoader-Enabler/releases/latest).
4. Extract the complete release ZIP to any normal folder.
5. Make sure Dome Keeper is closed, then double-click `Enable Mod Loader.bat`. The tool automatically finds the Steam installation, verifies the exact staging build, and keeps the original PCK as a recovery backup.
6. Launch the game normally. This subscribed mod will load automatically from Steam Workshop.

The enabler changes no save data and installs no other mods. Use `Check Status.bat` to verify its state and `Disable Mod Loader.bat` to restore the exact original Steam PCK. After a Dome Keeper update, download an enabler release that explicitly supports the new Build ID.

## Manual installation

1. Download `Codex-TeamPingHud.zip` from the [latest GitHub release](https://github.com/ltx001/DomeKeeper-Ping-Teammate-Direction-Indicator/releases/latest).
2. Place it in the Dome Keeper `mods` directory next to `domekeeper.pck`.
3. Enable Mod Loader with the tool above, then start the game.

`Codex-TeamPingHud` remains the internal mod ID so existing installations and settings continue to work after the public title change.

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
