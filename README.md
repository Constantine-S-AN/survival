# Survive: Neon Sonar (Godot 4.x)

2D 俯视角幸存者游戏原型。当前完成 **M1 + M1.5**：工程骨架 + 最小可玩循环 + 最低反馈雏形。

## 当前里程碑状态（M1 + M1.5）
- 已实现：移动、冲刺、自动/指向攻击切换、刷怪、击杀得经验、升级三选一、死亡结算、重开。
- 已实现：`GameRoot / World / Player / EnemyManager / ProjectileManager / UI` 场景分层。
- 已实现：`DataRegistry` 统一加载 JSON（武器/敌人/升级/刷怪曲线）并做基础 schema 校验。
- 已实现：噪声值已接入（攻击/冲刺叠加 + 随时间衰减）并影响刷怪速率/上限。
- 已实现（M1.5）：命中粒子、命中/开火占位音效（运行时合成）、轻屏震、短 hitstop。
- 还未实现：声呐迷雾视觉、完整内容量、局外成长、设置菜单、导出脚本等（后续里程碑）。

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
- `Tab`：切换攻击模式
- 自动模式 `AUTO`：自动锁定威胁最高敌人
- 指向模式 `AIM`：朝鼠标方向自动射击

## 数据调参入口
- 武器：`/Users/shijiean/Desktop/project/survive/data/weapons.json`
- 敌人：`/Users/shijiean/Desktop/project/survive/data/enemies.json`
- 升级池：`/Users/shijiean/Desktop/project/survive/data/upgrades.json`
- 刷怪曲线：`/Users/shijiean/Desktop/project/survive/data/spawn_curve.json`
- 数据加载与校验：`/Users/shijiean/Desktop/project/survive/scripts/core/data_registry.gd`

## 自动化测试（当前）
数据层脚本测试：
```bash
godot4 --headless --path /Users/shijiean/Desktop/project/survive --script res://tests/test_runner.gd
```

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
