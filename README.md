# Survive: Neon Sonar

一个基于 Godot 4.x 开发的白天经营 + 夜晚战斗混合式 roguelite 纵切项目。

这个版本的核心，不是把“农场”“餐馆”“夜战”并排摆在一起，而是把它们接成一个会互相影响的循环：白天的行动预算有限，夜晚的稀有资源会回流到第二天的经营层，玩家需要在前 3 天内持续做取舍。

## 玩家版介绍

### 这是什么游戏

你白天经营，晚上出战。

白天你主要会在可步行的 `DayWorld` 里规划和执行：

- 走到农场区整地、种植、浇水、收获
- 走到餐馆决定菜单、备菜和开门营业
- 走到商店买种子、卖产出、买升级
- 走到码头，在傍晚后决定是否出发夜战

晚上你会进入一个低视野、重迷雾、靠声呐获取信息的战斗潜航流程。夜战结束后，奖励会通过 `Return Summary` 回流到共享库存、金币和解锁进度里，再进入下一天。

当前主白天入口已经不是“纯菜单据点”了，而是 worldified 的日间空间；旧版 `Day Hub` 仍保留为回退壳层。

### 核心循环怎么走

当前版本的主循环已经接通：

1. 从可步行的 `DayWorld` 开始一天。
2. 在 `Farm / Restaurant / Shop / Dock` 之间分配白天资源。
3. 随着行动推进，时间会从 `Morning -> Noon -> Afternoon -> Evening -> Night` 前进。
4. 到达 `Evening` 后，可从码头进入 `Night Combat`。
5. 夜战结束后进入 `Return Summary`。
6. 奖励进入共享经济层，进入下一天，作物生长推进，白天资源重置。

### 当前版本已经能玩到什么

#### DayWorld 白天总控

当前白天主循环已经 worldified，不再只是按钮列表。玩家会直接在地图里走到不同地点完成操作，同时保留必要的 HUD、引导和回退入口。

DayWorld 当前会稳定提供：

- 可步行的白天总地图
- 农场 / 餐馆 / 商店 / 码头的世界化入口
- 与阶段联动的提示、引导和 landmark 强调
- 前 3 天的 authored opening 引导
- 与返航总结、次日 handoff 连续衔接

左上与页内信息会持续显示：

- 当前是第几天
- 当前时间段
- 剩余体力 `stamina`
- 剩余行动预算 `action budget`
- 当前金币 `gold`
- 关键库存数量
- 当前可进入的白天系统和夜战入口

旧版 `Day Hub` 仍保留，主要用于回退和测试壳层，不再是默认体验。

#### 白天时间 / 体力 / 行动预算

白天已经有真实机会成本，不允许同一天把所有事都做完。

- 时间段分为：`morning`、`noon`、`afternoon`、`evening`、`night`
- `action_budget` 代表白天还能花多少时间
- `stamina` 代表白天还能做多少劳动型操作
- 农场行为会消耗体力和/或行动预算
- 餐馆开门营业会吃掉明显的白天进度
- 夜战需要先到达 `evening`
- 白天仍可直接等待到傍晚，方便切换到夜战

#### 前 3 天 opening 已经被作者化处理

当前版本不是“把几个系统丢给玩家自己拼起来”，而是已经有一个明确的 opening 弧线：

- `Day 1`：先立住农场与第一轮餐馆价值，再从码头出发
- `Day 2`：强调昨晚带回来的东西要尽快转成白天优势
- `Day 3`：让收成、菜单、商店选择与夜战奖励开始互相放大

这套 opening 通过世界引导、订单板、返航文字和轻量对话协同完成，没有额外的大型教程模态框。

#### 农场系统

农场现在已经是可玩的白天子系统。

当前支持：

- 整地 `Till`
- 种植 `Plant`
- 浇水 `Water`
- 收获 `Harvest`
- 跨天作物成长
- 与共享库存联动
- 与存档 / 读档联动

当前已有 5 种作物：

- `wheat`
- `herb`
- `kelpberry`
- `emberleaf`
- `mooncap`

它们的定位不同：

- `wheat`、`herb` 是早期基础盘
- `kelpberry`、`emberleaf` 能让你在“直接卖”与“拿去做菜”之间做选择
- `mooncap` 是夜战驱动的高级作物路径

#### 餐馆经营系统

餐馆已经接通完整的“菜单规划 -> 开门营业 -> 结算收益 -> 保存结果”流程。

当前支持：

- 查看共享库存食材
- 选择当日菜单，最多 3 个配方
- 基于库存、菜单、复杂度、声望和升级效果进行 deterministic service simulation
- 结算金币与餐馆声望
- 记录卖出菜品统计
- 保存最近一次营业总结

当前已有 8 个食谱，覆盖：

- 基础农场菜
- 早期稳定出餐路线
- 商店种子带来的新菜路
- 夜战材料驱动的高价值菜
- 更后期的高级夜战菜

#### 商店 / 买卖 / 升级

白天商店已经接通，定位是经济转换器和中期规划节点。

当前支持：

- 购买 2 种种子
  - `kelpberry_seed`
  - `emberleaf_seed`
- 出售部分农产品和材料
  - `wheat`
  - `herb`
  - `kelpberry`
  - `emberleaf`
  - `mooncap`
  - `scrap`
- 购买餐馆升级
- 在 UI 中清楚显示价格、效果、已拥有状态和金币不足提示

当前商店可购买的餐馆升级包括：

- `Window Herb Boxes`：提高进店需求
- `Second Stock Pot`：提高产能
- `Counter Runner`：提高满意度稳定性

这些升级都已经真实作用到餐馆营业结果里。

#### 夜战奖励回流白天经济

夜战不再是独立小游戏，而是白天经营的重要资源来源。

当前支持：

- 从 DayWorld / Day Hub 在正确时间进入 Night Combat
- 夜战时长按天数缩放：`当天数 * 60 秒`
- 夜战结束后显示 Return Summary
- Summary 展示 loot、金币、特殊材料和解锁进度
- 奖励在 Summary 出现前就写入共享状态
- 关闭 Summary 后进入下一天，奖励不会丢失

当前返航页会明确给出下一步：

- 点击 `进入第 X 天`
- 或直接按 `Enter / E` 回到白天
- 长内容会保留在可滚动区域里，不会把继续按钮挤出屏幕

当前夜战专属材料至少包括：

- `abyssfin`
- `glow_kelp`
- `reef_salt`
- `moon_spore`
- `kitchen_blueprint_fragment`

它们已经有真实用途：

- 高价值餐馆料理
- 农场高级种子 / 高级作物路径
- 配方或长期解锁进度

### 当前版本的策略重点

这个版本故意把三条路线做成不同价值，不让任何一个系统无脑统治前 3 天。

- 农场：偏未来投资，为后续菜单和库存做准备
- 餐馆：偏计划兑现，是白天最强的利润引擎
- 夜战：偏特殊价值，提供白天买不到的稀有材料和解锁

理想体验是：你不会只做一件事，而是每天都在权衡“今天该先做什么、该卖什么、该留什么、要不要赶夜战”。

### 当前内容量

当前 opening slice 已达到：

- 5 种作物
- 8 个食谱
- 5 种夜战专属材料 / 稀有食材
- 3 个已接入商店并真实生效的餐馆升级

### 新手前 3 天会得到什么提示

当前 DayWorld / Day Hub 有前 3 天的轻量 onboarding：

- Day 1：解释完整循环，告诉玩家白天和夜战分别在解决什么问题
- Day 2：强调机会成本，提醒玩家餐馆、农场、商店不能都零成本全做
- Day 3：提醒玩家优先收成熟作物，再决定卖出、做菜，还是留给高价值路线

同时，商店、餐馆、返航总结和订单板也补了更明确的 authored cue，让玩家更早理解“今晚为什么有意义，明天为什么值得处理这批战利品”。

### 如何启动

#### 一键运行最新版本

```bash
./play_latest.sh
```

默认行为：

1. 切到 `main`
2. 从 `origin/main` 拉取最新版本
3. 显式启动新的日夜混合主入口 `res://scenes/meta/MetaLoopRoot.tscn`

可选参数：

```bash
./play_latest.sh --no-update
./play_latest.sh --allow-dirty
./play_latest.sh --branch main
./play_latest.sh --godot /Applications/Godot.app/Contents/MacOS/Godot
./play_latest.sh --scene res://scenes/meta/MetaLoopRoot.tscn
```

#### 直接运行

```bash
godot --path .
```

或显式指定主入口：

```bash
godot --path . res://scenes/meta/MetaLoopRoot.tscn
```

### 默认操作

- 白天移动：`WASD` / 方向键
- 白天交互 / 确认：`E` / `Enter`
- 农场工具切换：`Q` / `Tab`
- 白天快捷栏：`1-6`
- 返航总结继续到下一天：`Enter` / `E`
- 夜战移动：`WASD` / 方向键
- 冲刺：`Space` / `Shift`
- 声呐主动技能：`Q` / `E`
- 攻击模式切换：`Tab`
- 调试面板：`F1`
- 迷雾显示切换：`F2`
- 声呐视觉切换：`F3`
- 数据热重载：`F5`

## 开发者版说明

### 项目概况

- 引擎：`Godot 4.6.x`
- 类型：动作 roguelite + 经营规划混合玩法
- 当前主循环：`DayWorld -> Farm / Restaurant / Shop / Dock -> Night Combat -> Return Summary -> Next Day`
- 当前目标：把当前版本稳定成可连续游玩的 hybrid day-night vertical slice

### 当前系统状态

当前版本已经接通并稳定化的系统包括：

- `Meta Loop Root`：日夜总流程路由
- `DayWorld`：walkable 白天世界、地标交互、过渡与 handoff
- `Day Hub`：白天状态展示与 legacy fallback 入口
- `Day Clock / Day State`：时间段、体力、行动预算
- `Farm`：地块状态、作物生长、收获入库
- `Restaurant`：菜单规划、营业模拟、收益与声望结算
- `Shop`：买种子、卖材料、买升级
- `Reward Pipeline`：夜战奖励回流白天经济与解锁
- `Return Summary`：战斗结算展示与跨天推进
- `Day Hub Intro Dialogue Layer`：前 3 天 opening / authored cue / return timing
- `ProfileStore`：统一存档 / 读档与字段归一化
- `DataRegistry`：白天与夜战系统的 JSON 数据加载
- `Headless Tests`：围绕混合循环的回归测试

### 存档模型概要

当前混合循环的持久化重点包括：

- 当前天数 `current_day`
- 当前白天阶段 `current_phase`
- 体力 / 最大体力
- 行动预算 / 最大行动预算
- 金币 `gold`
- 共享库存 `inventory.materials`
- 已解锁种子 `unlocked_seeds`
- 已解锁配方 `unlocked_recipes`
- 农场地块与作物状态
- 当前菜单 `selected_menu_recipe_ids`
- 最近一次餐馆营业总结 `last_service_summary`
- 餐馆声望 `restaurant_reputation`
- 累计卖出菜品统计
- 已拥有餐馆升级 `owned_upgrade_ids`
- 夜战后的待显示总结 `pending_return_summary`
- 战斗带来的长期奖励与解锁进度

当前存档设计原则：

- 场景切换本身不会凭空增减库存
- 夜战奖励在 Summary 弹出前就已结算进共享状态
- Summary 只负责展示，不负责二次发奖
- 中途存档恢复后，不会重复扣材料或重复发奖励
- 存档字段会在 `ProfileStore` 中统一做 normalization

### 自动化测试与验证入口

#### 直接运行 headless runner

```bash
godot --headless --path . res://tests/TestRunner.tscn --quit-after 3600
```

#### 本地 / CI 统一入口

```bash
./scripts/ci/run_headless_tests.sh
```

当前自动化覆盖重点包括：

- 作物跨天生长
- 农场状态存档 / 读档
- 菜单食材消耗
- 餐馆结算结果持久化
- 夜战奖励转移到白天库存
- 夜战时长按天数缩放
- Summary 后进入下一天
- 商店买种子 / 卖材料 / 买升级
- 升级对餐馆结果的真实影响
- 中途存档并恢复完整日夜循环

### 数据驱动入口

白天-夜晚混合循环相关的数据主要在：

- `data/seeds.json`
- `data/crops.json`
- `data/recipes.json`
- `data/shop_inventory.json`
- `data/special_ingredients.json`
- `data/restaurant_upgrades.json`
- `data/unlocks.json`
- `data/night_loot_tables.json`

动作 roguelite 其余运行数据仍保持数据驱动：

- 角色：`data/characters.json`
- 武器：`data/weapons.json`
- 升级：`data/upgrades.json`
- 敌人 / 精英 / Boss：`data/enemies.json`、`data/elites.json`、`data/bosses.json`
- 地图 / 危险 / 事件：`data/maps.json`、`data/hazards.json`、`data/events.json`
- 合同：`data/contracts.json`
- 迷雾 / 声呐 / 噪声：`data/fog.json`、`data/sonar.json`、`data/noise.json`

### 仓库结构

- `scenes/`：游戏场景与 UI 场景
- `scripts/`：玩法逻辑、UI 控制器、CI / 测试脚本
- `ui/`：通用 UI 组件与主题资源
- `tests/`：headless runner 与回归测试
- `docs/`：系统设计、存档模型与风格文档
- `data/`：JSON 数据配置
- `assets/`：图片、字体、图标、音频与其他素材
- `.github/workflows/`：CI 配置

### 推荐阅读文档

- 日夜循环：[docs/DAY_LOOP.md](/Users/shijiean/Desktop/project/survive/docs/DAY_LOOP.md)
- 完整循环打磨：[docs/FULL_LOOP_POLISH_PASS_1.md](/Users/shijiean/Desktop/project/survive/docs/FULL_LOOP_POLISH_PASS_1.md)
- 音频与微反馈：[docs/AUDIO_MICRO_FEEDBACK_PASS_1.md](/Users/shijiean/Desktop/project/survive/docs/AUDIO_MICRO_FEEDBACK_PASS_1.md)
- 前 3 天作者化 opening：[docs/AUTHORED_FIRST_THREE_DAYS_PASS.md](/Users/shijiean/Desktop/project/survive/docs/AUTHORED_FIRST_THREE_DAYS_PASS.md)
- 农场系统：[docs/FARM_SYSTEM.md](/Users/shijiean/Desktop/project/survive/docs/FARM_SYSTEM.md)
- 餐馆系统：[docs/RESTAURANT_SYSTEM.md](/Users/shijiean/Desktop/project/survive/docs/RESTAURANT_SYSTEM.md)
- 存档模型：[docs/SAVE_MODEL.md](/Users/shijiean/Desktop/project/survive/docs/SAVE_MODEL.md)
- UI 风格：[docs/UI_STYLE_GUIDE.md](/Users/shijiean/Desktop/project/survive/docs/UI_STYLE_GUIDE.md)
- 设计说明：[docs/DESIGN_NOTES.md](/Users/shijiean/Desktop/project/survive/docs/DESIGN_NOTES.md)
- 录屏与展示参考：`media/TRAILER_CAPTURE.md`、`media/SHOTLIST.md`

### 许可证与鸣谢

- 许可证：`LICENSE`
- 第三方素材与鸣谢：`CREDITS.md`
