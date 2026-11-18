<p align="center">
  <a href="https://github.com/DTM-Mods"><img src="https://raw.githubusercontent.com/DTM-Mods/.github/main/assets/dtm-header.jpg" alt="DTM Mods by PropaineX & Fennell" width="100%"></a>
</p>

<p align="center">
  <img src="preview/icon_preview_v4.png" alt="Input Alert icon" width="128">
</p>

<h1 align="center">Input Alert</h1>

<p align="center">
  <img src="https://img.shields.io/badge/Farming%20Simulator-25-2E6B4F" alt="Farming Simulator 25">
  <img src="https://img.shields.io/badge/version-1.1.3.0-D9A441" alt="Version 1.1.3.0">
  <a href="https://github.com/DTM-Mods"><img src="https://img.shields.io/badge/DTM-Mods-143326" alt="DTM Mods"></a>
</p>

<p align="center">
  <b>See at a glance which production inputs are running out.</b><br>
  <sub>by PropaineX</sub>
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/DTM-Mods/.github/main/assets/features.jpg" alt="Features" width="100%">
</p>

Everything shows in the game's own **Production Chains** menu:

- **Incoming materials**: every material a switched-on product needs is highlighted in soft red when it is at
  **10% of its capacity or less**. Materials that only switched-off products use are left alone.
- **Recipe status boxes**: pick a product and every input in its recipe gets a box to the left of its icon:
  - green tick: plenty in storage (10 or more production cycles)
  - yellow plus: okay, nothing to do yet (2 to 10 cycles)
  - red X: low or empty (under 2 cycles), deliver this

Works with base game, map and mod productions. Read only: it changes nothing in your productions, sends no network
traffic of its own and adds no hotkeys. Multiplayer and dedicated servers are supported (it reads the storage levels
the game already sends to every player).

<p align="center">
  <img src="https://raw.githubusercontent.com/DTM-Mods/.github/main/assets/installation.jpg" alt="Installation" width="100%">
</p>

Put `FS25_InputAlert.zip` in `Documents/My Games/FarmingSimulator2025/mods`, without unzipping or renaming it.
In multiplayer, install it on the server **and** on every player's game, all on the same version.

In the log, look for lines starting with `[InputAlert]`.

See [PATCH_NOTES.md](PATCH_NOTES.md) for what changed in each version.

## How it works (for modders)

- `scripts/InputAlertMenu.lua` is appended to `InGameMenuProductionFrame.draw`. The menu's own code is not public,
  so the rows are found by their text and the boxes and highlights are drawn on top.
- Thresholds at the top of the script: `InputAlert.LOW_CYCLES` (2), `InputAlert.GOOD_CYCLES` (10),
  `InputAlert.LOW_PERCENT` (0.10).
- Does not hook `ProductionPoint.load`.
- Passes the GIANTS TestRunner 0.9.24.

<p align="center">
  <img src="https://raw.githubusercontent.com/DTM-Mods/.github/main/assets/license.jpg" alt="License" width="100%">
</p>

MIT, see [LICENSE](LICENSE).

---

<p align="center">
  <a href="https://github.com/DTM-Mods"><img src="https://raw.githubusercontent.com/DTM-Mods/.github/main/assets/dtm-intro.gif" alt="DTM Mods by PropaineX & Fennell" width="420"></a><br>
  <sub>Part of <a href="https://github.com/DTM-Mods">DTM Mods</a> (Designed To Manage) by PropaineX & Fennell</sub>
</p>
