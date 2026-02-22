# Survive: Neon Sonar (Godot 4.x)

2D 俯视角幸存者游戏原型。当前完成 **M3 / P0-B**：在 M2 基础上加入 `角色系统 + 角色选择 + 解锁存档迁移`。

## 当前里程碑状态（M3 / P0-B）
- 已实现：移动、冲刺、自动/指向攻击切换、刷怪、击杀得经验、升级三选一、死亡结算、重开。
- 已实现：`GameRoot / World / Player / EnemyManager / ProjectileManager / UI` 场景分层。
- 已实现：`DataRegistry` 统一加载 JSON（武器/敌人/升级/刷怪曲线）并做基础 schema 校验。
- 已实现（Fog）：世界默认压暗 + 玩家视野光圈 + 全屏扫描线/噪点遮罩，`F2` 可开关。
- 已实现（Sonar）：命中/拾取/主动技能触发声呐波纹，波纹扫过敌人触发 revealed，并显示高亮轮廓。
- 已实现（Noise）：噪声值 `0..100`，三档位（静默/警戒/暴露）联动刷怪倍率与追猎者概率。
- 已实现（Debug）：`F1` 调试面板显示 noise/tier/倍率/追猎概率/revealed/timeline 与配置版本；支持固定噪声和热重载。
- 已实现（M1.5）：命中粒子、命中/开火占位音效（运行时合成）、轻屏震、短 hitstop。
- 已实现（P0-A）：对象池（Projectile + Pickup）与 `pool_hit_rate / hits / misses` 实时统计。
- 已实现（P0-B）：5角色配置、主菜单 -> 角色选择 -> 开局、profile schema 迁移、结算解锁评估与解锁弹窗。
- 还未实现：M3 后续内容量（8武器、25升级、2地图、10敌人、1Boss 等）与导出脚本。

## 运行

### 方式 A：Godot 编辑器
1. 用 Godot 4.2+ 打开项目目录：`/Users/shijiean/Desktop/project/survive`
2. 主场景是 `res://scenes/game/GameRoot.tscn`
3. 点击 Play 运行。

### 方式 B：命令行（需要 Godot CLI）
```bash
godot4 --path /Users/shijiean/Desktop/project/survive
```
或（若你的命令是 `godot`）：
```bash
godot --path /Users/shijiean/Desktop/project/survive
```

## 操作
- `WASD` / `方向键`：移动
- `Space` / `Shift`：冲刺（冷却）
- `Q` / `E`：主动声呐技能（有冷却，产生较高噪声）
- `Tab`：切换攻击模式
- 自动模式 `AUTO`：自动锁定威胁最高敌人
- 指向模式 `AIM`：朝鼠标方向自动射击
- 开局流程：Main Menu -> `Start Run` -> CharacterSelect -> `Start`

## Characters（P0-B）
- `diver` / Silent Diver：控噪+延长揭示。解锁：单局生存 420 秒。
- `arc_tech` / Arc Technician：偏链式/暴击权重，噪声更高。解锁：累计击杀 800。
- `lancer` / Trench Lancer：穿透与冲刺 CD 优势。解锁：噪声峰值达到 60（Exposed）。
- `drone_handler` / Drone Handler：召唤向权重，噪声更高。解锁：累计拾取 250。
- `scavenger` / Neon Scavenger：拾取半径和经验收益强化。解锁：单局生存 600 秒。
- 角色配置文件：`/Users/shijiean/Desktop/project/survive/data/characters.json`

## Fog / Sonar / Noise 玩法联动
- Fog：默认黑暗迷雾，仅玩家视野圈内清晰可见，外部区域通过扫描线与噪点保持“科技深海”压迫感。
- Sonar：命中、拾取、主动技能会释放波纹；波纹扫过敌人会短暂揭示（reveal），并显示高亮轮廓。
- Noise：攻击/冲刺/技能会抬升噪声；噪声越高，刷怪速率和数量上限越高，且更容易触发追猎者生成。
- 构筑意义：更激进的输出节奏会更快压高噪声，形成“信息优势 vs 风险暴露”的权衡。

## 调试快捷键
- `F1`：开关调试面板
- `F2`：开关 Fog（压暗+视野光圈+扫描遮罩）
- `F3`：开关 Sonar 视觉（波纹显示）
- `F5`：调试模式下热重载数据配置（`DataRegistry.reload_in_debug()`）
- `F6`：固定噪声值开关
- `F7`：固定噪声值 -10
- `F8`：固定噪声值 +10
- CharacterSelect 调试：Debug 构建下提供 `Unlock All (Debug)` 按钮（默认关闭，不在发行版启用）。

## 数据调参入口
- 武器：`/Users/shijiean/Desktop/project/survive/data/weapons.json`
- 敌人：`/Users/shijiean/Desktop/project/survive/data/enemies.json`
- 升级池：`/Users/shijiean/Desktop/project/survive/data/upgrades.json`
- 刷怪曲线：`/Users/shijiean/Desktop/project/survive/data/spawn_curve.json`
- Fog：`/Users/shijiean/Desktop/project/survive/data/fog.json`
- Sonar：`/Users/shijiean/Desktop/project/survive/data/sonar.json`
- Noise：`/Users/shijiean/Desktop/project/survive/data/noise.json`
- Characters：`/Users/shijiean/Desktop/project/survive/data/characters.json`
- 数据加载与校验：`/Users/shijiean/Desktop/project/survive/scripts/core/data_registry.gd`
- Profile 存储与迁移：`/Users/shijiean/Desktop/project/survive/scripts/core/profile_store.gd`

## Profile Schema（v2）
`user://profile.json` 包含：
- `schema_version`
- `unlocked_characters`
- `last_selected_character_id`
- `progress`：
  - `total_kills`
  - `pickups_collected`
  - `elite_or_pursuer_kills`
  - `best_survive_time_seconds`
  - `best_max_noise_reached`
  - `reached_noise_tiers`
- `run_count`

## 自动化测试（当前）
M3 测试场景（包含 Pool + Fog/Sonar/Noise + Character/Profile）：
```bash
godot --headless --path /Users/shijiean/Desktop/project/survive --scene res://tests/TestRunner.tscn --quit-after 3400
```
说明：headless 强制退出时可能出现 `ObjectDB leaked` 警告，当前不影响游戏 Play 流程和测试断言结果。

## 目录结构（M1）
- `scenes/`：主场景与实体场景
- `scripts/`：核心逻辑、实体逻辑、管理器、UI
- `data/`：JSON 数据配置
- `tests/`：脚本化测试入口
- `assets/`：占位资源
- `exports/`：后续导出产物目录
- `assets_inbox/`：外部素材暂存目录
- `tmp/`：临时文件

## 外部资源与许可
- 本里程碑未引入外部下载素材。
- 图标 `assets/textures/icon.svg` 为本地生成占位图（原创占位）。
- 音效为运行时程序合成占位，不依赖外部素材授权。
