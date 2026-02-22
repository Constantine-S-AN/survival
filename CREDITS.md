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
| `assets/audio/hit.wav` | SFX | Project-authored placeholder | MIT (project) | 命中占位音效 |
| `assets/audio/shot.wav` | SFX | Project-authored placeholder | MIT (project) | 射击占位音效 |
| `assets/shaders/fog_scan_noise.gdshader` | Shader | Project-authored | MIT (project) | 迷雾扫描线/噪点后处理 |

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
