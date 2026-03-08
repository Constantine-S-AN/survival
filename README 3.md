# Survive: Neon Sonar

一个基于 Godot 4.x 开发的白天经营 + 夜晚战斗混合式 roguelite 纵切项目。

白天阶段，玩家要在 Day Hub 中规划农场、餐馆、商店与行动预算。夜晚阶段，玩家进入低视野、高噪声压力的战斗潜航，通过声呐、位移和进攻在迷雾中争取稀有资源。夜战收益会通过 Return Summary 回流到第二天的经营层，形成完整的日夜闭环。

## 项目现状

- 引擎：`Godot 4.6.x`
- 类型：动作 roguelite + 经营规划混合玩法
- 当前主循环：`Day Hub -> Farm / Restaurant / Shop -> Night Combat -> Return Summary -> Next Day`
- 当前目标：把这个版本稳定成一个可连续游玩 3 天以上的 playable vertical slice

## 当前版本已经接通的核心功能

### 1. Day Hub 白天总控界面

Day Hub 已经不是单纯跳转页，而是日间规划中心。当前会清楚展示：

- 当前是第几天
- 当前时间段：`Morning / Noon / Afternoon / Evening / Night`
- 剩余体力 `stamina`
- 剩余行动预算 `action budget`
- 当前金币 `gold`
- 关键库存数量
- 当前可进入的白天系统和夜战入口

Day Hub 还承载了前 3 天的轻量引导文案，帮助第一次游玩的玩家理解完整循环。

### 2. 白天时间段与机会成本系统

白天已经接入真实的时间与资源成本，不再允许“同一天把所有事都做完”。

- 时间段分为：`morning`、`noon`、`afternoon`、`evening`、`night`
- `action_budget` 代表白天可支配的时间资源
- `stamina` 代表白天可支配的劳动资源
- 农场操作会消耗体力和/或行动预算
- 餐馆开门营业会消耗明显的白天进度
- 夜战需要到达 `evening` 或 `night` 才能进入
- Day Hub 支持等待到傍晚，方便主动切换到夜战节奏

这个系统的目的很明确：让玩家必须在“种地、做饭、买卖、夜战”之间做取舍。

### 3. 农场系统

农场现在已经是可玩的白天子系统，而不是占位页面。

当前支持：

- 整地 `Till`
- 种植 `Plant`
- 浇水 `Water`
- 收获 `Harvest`
- 与共享库存联动
- 与跨天作物生长联动
- 与存档/读档联动

当前 starter crop 共 5 种：

- `wheat`：基础谷物，餐馆的稳定底料
- `herb`：生长快，适合早期轻料理与茶饮
- `kelpberry`：可直接卖，也可做高价值烘焙
- `emberleaf`：可安全卖出，也可转化为更高收益午餐菜
- `mooncap`：夜战驱动的高级作物路径

当前规则要点：

- 整地消耗 `1` 点体力
- 种植体力成本由 `data/seeds.json` 决定
- 浇水消耗 `1` 点体力
- 收获消耗 `1` 点行动预算，不消耗体力
- 作物只会在跨天时推进生长
- 是否浇水会影响第二天的生长推进

### 4. 餐馆经营系统

餐馆现在已具备完整的“菜单规划 -> 开门营业 -> 结算收益 -> 记录结果”闭环。

当前支持：

- 查看共享库存食材
- 选择当日菜单，最多 3 个配方
- 基于库存、菜单、复杂度、声望、升级效果进行 deterministic service simulation
- 结算金币
- 结算餐馆声望 `restaurant_reputation`
- 记录卖出菜品统计 `sold_dishes_stats`
- 保存最近一次营业总结 `last_service_summary`

当前 starter recipe 共 8 个，覆盖：

- 基础农场菜
- 早期稳定出餐
- 商店种子带来的新利润路线
- 夜战稀有材料带来的高价值菜
- 更后期的高级夜战菜

餐馆定位是当前白天层里最强的“计划型收益引擎”：

- 直接卖原料是保底方案
- 把库存组织成合适菜单，通常会比直接卖更赚钱
- 稀有夜战材料更适合拿去做高票价料理，而不是简单卖掉

### 5. 商店 / 买卖 / 升级系统

白天商店已经接通，作用不是卖 NPC 剧情，而是做资源转换和中期规划。

当前支持：

- 购买至少 2 种种子
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
- 在 UI 中明确展示价格、效果、已拥有状态和金币不足提示

当前商店可购的餐馆升级包括：

- `Window Herb Boxes`：提高进店需求
- `Second Stock Pot`：提高产能
- `Counter Runner`：提高满意度稳定性

这些升级不是文字装饰，已经真实影响餐馆结算结果。

### 6. 夜战与白天经济回流

夜战不再是独立小游戏，已经和白天经营形成真实资源桥接。

当前支持：

- 从 Day Hub 在合适时间进入 Night Combat
- 夜战结束后进入 Return Summary
- Summary 展示本次获得的 loot / gold / 特殊材料 / 解锁进度
- 奖励会在 Summary 出现前就写入共享状态
- 关闭 Summary 后进入下一天，并保留已经获得的奖励

当前夜战专属材料至少包括 5 种：

- `abyssfin`
- `glow_kelp`
- `reef_salt`
- `moon_spore`
- `kitchen_blueprint_fragment`

它们的用途已经真实接通：

- 可用于高级餐馆料理
- 可用于农场高级种子/作物路径
- 可用于配方或进度解锁

### 7. 新手引导与首日体验

当前版本已经加入轻量 onboarding，避免新玩家进来不知道先做什么。

前 3 天的 Day Hub 提示会分别强调：

- Day 1：完整循环怎么走，白天和夜战各自负责什么
- Day 2：机会成本，为什么餐馆、农场、商店不能都无脑全做
- Day 3：先收成熟作物，再决定卖、做菜，还是留给高价值路线

这套引导是管理向的，没有额外堆 NPC 或强制教程场景。

## 当前内容量

当前 opening slice 已达到：

- 5 种作物
- 8 个食谱
- 5 种夜战专属材料 / 稀有食材
- 3 个已接入商店购买并真实生效的餐馆升级

这个量级已经足够支撑前 3 天产生有意义的选择，而不是只有一条明显最优路线。

## 存档 / 读档能力

当前混合循环已经做了完整的 save model 加固。以下关键状态会被持久化：

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
- 最近一次餐馆结算 `last_service_summary`
- 餐馆声望 `restaurant_reputation`
- 累计卖出菜品统计
- 已拥有餐馆升级 `owned_upgrade_ids`
- 夜战后的待显示总结 `pending_return_summary`
- 战斗带来的长期奖励和解锁进度

关键设计原则：

- 场景切换本身不会凭空增减库存
- 夜战奖励在 Summary 出现前就已结算进共享状态
- Summary 只是显示桥梁，不会二次发奖
- 跨存档恢复中途流程时，不会重复扣材料或重复发奖励

## 自动化测试覆盖

当前已有 headless regression coverage，重点覆盖混合循环而不是只有单点 getter/setter。

已覆盖内容包括：

- 作物跨天生长
- 农场状态存档/读档
- 菜单食材消耗
- 餐馆结算结果持久化
- 夜战奖励转移到白天库存
- Summary 后进入下一天
- 商店买种子 / 卖材料 / 买升级
- 升级对餐馆结果的真实影响
- 中途存档并恢复完整日夜循环

## 运行方式

### 一键运行最新版本

```bash
./play_latest.sh
```

默认行为：

1. 切到 `main`
2. 从 `origin/main` 拉取最新版本
3. 用 `godot --path .` 启动项目

可选参数：

```bash
./play_latest.sh --no-update
./play_latest.sh --allow-dirty
./play_latest.sh --branch main
./play_latest.sh --godot /Applications/Godot.app/Contents/MacOS/Godot
```

### 正常运行

```bash
godot --path .
```

### 运行 Headless Tests

```bash
godot --headless --path . res://tests/TestRunner.tscn --quit-after 3600
```

### 本地 / CI 统一测试入口

```bash
./scripts/ci/run_headless_tests.sh
```

## 默认操作

- 移动：`WASD` / 方向键
- 冲刺：`Space` / `Shift`
- 声呐主动技能：`Q` / `E`
- 攻击模式切换：`Tab`
- 调试面板：`F1`
- 迷雾显示切换：`F2`
- 声呐视觉切换：`F3`
- 数据热重载：`F5`

## 数据驱动配置

当前大部分核心运行参数都走 `data/` 下的 JSON，而不是硬编码在 UI 或控制器里。

与白天-夜晚纵切直接相关的数据包括：

- `data/seeds.json`
- `data/crops.json`
- `data/recipes.json`
- `data/shop_inventory.json`
- `data/special_ingredients.json`
- `data/restaurant_upgrades.json`
- `data/unlocks.json`
- `data/night_loot_tables.json`

其他动作 roguelite 运行数据仍保持数据驱动：

- 角色：`data/characters.json`
- 武器：`data/weapons.json`
- 升级：`data/upgrades.json`
- 敌人 / 精英 / Boss：`data/enemies.json`、`data/elites.json`、`data/bosses.json`
- 地图 / 危险 / 事件：`data/maps.json`、`data/hazards.json`、`data/events.json`
- 合同：`data/contracts.json`
- 迷雾 / 声呐 / 噪声：`data/fog.json`、`data/sonar.json`、`data/noise.json`

## 仓库结构

- `scenes/`：游戏场景与 UI 场景
- `scripts/`：玩法逻辑、UI 控制器、CI/测试脚本
- `ui/`：通用 UI 组件与主题资源
- `tests/`：headless runner 与回归测试
- `docs/`：系统设计、存档模型与风格文档
- `data/`：JSON 数据配置
- `assets/`：图片、字体、图标、音频与其他素材
- `.github/workflows/`：CI 配置

## 当前推荐阅读文档

- 日夜循环：`docs/DAY_LOOP.md`
- 农场系统：`docs/FARM_SYSTEM.md`
- 餐馆系统：`docs/RESTAURANT_SYSTEM.md`
- 存档模型：`docs/SAVE_MODEL.md`
- UI 风格：`docs/UI_STYLE_GUIDE.md`
- 设计说明：`docs/DESIGN_NOTES.md`
- 录屏与展示参考：`media/TRAILER_CAPTURE.md`、`media/SHOTLIST.md`

## 当前版本的玩法定位

这个版本不是纯动作，也不是纯农场，而是强调三层价值分工：

- 农场：偏未来投资，为后续菜单和利润铺货
- 餐馆：偏计划收益，是白天最强的兑现器
- 夜战：偏特殊价值，提供白天无法替代的稀有材料、解锁与高价值路线

如果系统表现正常，玩家在前 3 天里应该始终在思考：

- 今天先把行动预算花在农场、餐馆还是商店？
- 现在卖原料，还是留着做菜？
- 要不要赶在傍晚前把资源凑齐，冲一次夜战高价值回报？

## 许可证与鸣谢

- 许可证：`LICENSE`
- 第三方素材与鸣谢：`CREDITS.md`
