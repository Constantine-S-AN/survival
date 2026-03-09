# DayWorld Feel Pass 1

日期: 2026-03-08

参考实现:
- `scripts/meta/day_world.gd`
- `scripts/day/shop/shop_controller.gd`
- `scripts/day/restaurant/restaurant_controller.gd`
- `scripts/ui/day_hud.gd`

## 本轮目标

这轮不做新的大规模地表重刷，也不改 daytime / save / inventory / reward 的底层架构。

目标只聚焦在 DayWorld 的体感层:
- 让白天世界更像“正在运转”的小镇，而不是静态功能图。
- 让玩家前 10 分钟更容易顺着世界 cue 理解 farm / shop / restaurant / dock。
- 给种地、拾取和关键交互补上更直接的瞬时反馈。
- 继续收窄 prompt，让 UI 更像辅助而不是主导。

## 本轮改动

### 1. 轻量 liveliness

- DayWorld 增加了轻量 ambient motion 系统，用于招牌、立牌、串旗、小船和部分 NPC 的微摆动。
- 镇上补了少量 phase-sensitive ambient characters:
  - 农场边的 farmhand
  - 餐馆门前的 patron
  - 告示牌附近的 board reader
  - dock 附近的 dockhand
- 这些角色只承担气氛和引导，不接入新的 AI、存档状态或路线系统。
- 商店 interior 增加了常驻店主、轻量顾客可见度变化和室内微动。
- 餐馆 interior 增加了 host / floor runner、蒸汽 glow 和服务后 patron 的轻微动态。
- dock 在合适 phase 下补强了信号旗、departure 立牌和 skiff 的动态感。

### 2. 前 10 分钟的世界引导

- 为 farm / restaurant / shop / orders board / dock 增加了轻量 landmark guide glow。
- guide glow 会根据当前 day / phase / night readiness 调整强弱，重点引导第一天最需要理解的几个节点。
- 既有 zone marker 的 subtle marker / pulse 也会在新手阶段获得额外权重，让重要地点更容易被看见。
- 引导权重会在玩家已经聚焦对应区域时自动压低，避免过度闪烁。
- 这套引导没有改 quest / onboarding 逻辑，只增强世界层的“去哪里更合理”。

### 3. 交互反馈

- DayWorld 新增轻量 feedback effect layer。
- 现在以下操作会在世界里给出短促的视觉反馈:
  - 浇水
  - 收获
  - pickups
  - restaurant / shop / orders board / wait / night departure 等关键交互
- 反馈是小范围 ring / core / lift 动效，持续时间很短，不会压过角色和场景。
- pickups 在触发时会先短暂减淡自身，再走原本的 shared state 刷新流程。
- 这些反馈只挂在现有 signal 发射前后，没有替换既有交互链路，也给后续补 SFX 留了明确 hook 点。

### 4. Prompt 与 HUD 克制化

- DayWorld、Shop、Restaurant 的 prompt 都增加了很短的 dwell/reveal delay。
- 直接动作点位如 farm plot / pickup 的 reveal 更快，保证响应感；较大的 world interaction 则略晚出现，减少“路过就满屏提示”。
- HUD 底部 prompt 区在存在实际 contextual prompt 时，会自动隐藏 move hint，避免双层文字叠加。
- Shop / Restaurant interior 里也沿用了同样策略，让 prompt 更像确认提示，而不是持续导航层。

## 玩家体感改善目标

这轮主要想让玩家感受到:

- 走进白天世界时，空间不是静止的，有轻微但持续的“营业中 / 有人活动 / 风在吹”的感觉。
- 第一天不用读大段 guide，也更容易自然看出哪里是农场、哪里是商店、哪里接单、晚上从哪里出发。
- 浇水、收菜、拾东西、开关键交互时，手上操作会立刻得到回应，不再只有数值和状态改变。
- prompt 不再抢前景，而是退到需要时才提醒。

## 保持不变的部分

- 没有替换现有 save / inventory / reward / onboarding / dialogue 架构。
- 没有重做 DayWorld 的 routing、入口、zone、worldified shop / restaurant / dock 主流程。
- 没有新增复杂 NPC AI、排程系统或行为树。
- 没有新增外部素材或插件。

## 有意延后

- 更丰富的 NPC 日程、来回走动、停留逻辑仍然延后。
- 更完整的 farming / pickup / interaction SFX 仍然延后，本轮只先把视觉反馈和 hook 补齐。
- 更深的 diegetic onboarding 仍可继续做，例如更少文字的告示牌版式、图标化指引和更强的 tutorial staging。
- 更重的环境动画、天气层和客流模拟不在本轮范围内。
- 截图 / GIF 风格进度素材这轮没有稳定自动产出，因此未作为正式交付的一部分。

## 回归说明

本轮改动集中在表现层和 prompt 行为层:
- `scripts/meta/day_world.gd`
- `scripts/day/shop/shop_controller.gd`
- `scripts/day/restaurant/restaurant_controller.gd`
- `scripts/ui/day_hud.gd`

已有 worldified flow、save/load、phase cue、dialogue 与 smoke 覆盖应继续作为主要回归基线。
