# Credits & Asset Licensing

本文件记录仓库内资源来源与许可状态，便于后续发布和替换素材时审计。

## Engine / Runtime
- **Godot Engine 4.x**
  - Source: [https://godotengine.org](https://godotengine.org)
  - License: MIT
  - Notes: 引擎依赖，不随本仓库二次分发其完整源码。

## In-Repository Assets (Current)
| Path | Type | Source | License | Notes |
|---|---|---|---|---|
| `assets/textures/icon.svg` | Icon | Project-authored placeholder | MIT (project) | 本地占位图，用于项目图标 |
| `assets/audio/hit.wav` | SFX | Project-authored placeholder | MIT (project) | 命中占位音效；如替换真实素材需更新来源/作者/许可 |
| `assets/audio/shot.wav` | SFX | Project-authored placeholder | MIT (project) | 射击占位音效；如替换真实素材需更新来源/作者/许可 |
| `assets/shaders/fog_scan_noise.gdshader` | Shader | Project-authored | MIT (project) | 迷雾扫描线/噪点后处理 |
| `assets/textures/commercial/neon_grid_bg.png` | Texture | Project-authored (generated) | MIT (project) | 程序生成背景贴图，用于菜单/战斗背景商业化质感 |
| `assets/textures/player/diver_ship.png` | Texture | Project-authored (generated) | MIT (project) | 玩家角色贴图（替代纯几何体） |
| `assets/external/icons/tabler/*.svg` | UI Icons | [Tabler Icons](https://tabler.io/icons) | MIT | 武器/技能/标签图标资源；保留原许可与署名链接 |
| `assets/fonts/google/Orbitron-Variable.ttf` | Font | [Google Fonts - Orbitron](https://fonts.google.com/specimen/Orbitron) | SIL Open Font License 1.1 | 标题候选字体；当前运行时优先系统字体回退 |
| `assets/fonts/google/Exo2-Variable.ttf` | Font | [Google Fonts - Exo 2](https://fonts.google.com/specimen/Exo+2) | SIL Open Font License 1.1 | 正文候选字体；当前运行时优先系统字体回退 |
| `assets/fonts/google/OFL-Orbitron.txt` | License | Google Fonts package | OFL 1.1 | Orbitron 许可文本 |
| `assets/fonts/google/OFL-Exo2.txt` | License | Google Fonts package | OFL 1.1 | Exo 2 许可文本 |

## Fonts / Music / Third-party Packs
- 当前仓库未打包第三方字体、音乐或商用素材包。
- 若后续新增外部资源，必须在此文件追加以下字段：
  - `asset path`
  - `original source URL`
  - `author`
  - `license`
  - `modification status`（是否二次修改）

## Release Checklist Hook
发布前请确认：
1. 所有外部素材都在本文件登记并与许可证一致。
2. README 与发布页声明与本文件一致。
3. 不满足许可证要求的素材不得进入 `main`/发行包。
