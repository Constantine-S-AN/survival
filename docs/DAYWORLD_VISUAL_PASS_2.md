# DayWorld Visual Pass 2

日期: 2026-03-08

参考基线:
- `docs/DAYWORLD_VISUAL_PASS_1_ACCEPTANCE.md`
- `scripts/meta/day_world.gd`
- `scripts/day/shop/shop_controller.gd`
- `scripts/ui/day_hud.gd`

## 本轮目标

本轮不重写 daytime gameplay，也不替换现有 save / inventory / reward pipeline。

目标只针对 Pass 1 验收里仍为 `PARTIAL` 的几项:
- 地表和路径仍偏程序感，需要更像手工设计过的小镇与农场。
- 首次进入时的方向理解仍有一部分依赖试错。
- 商店外观和内部陈列还不够一眼读懂“买种子 / 卖材料 / 买升级”。
- 商店和关键地点的 “open / active” 状态还不够明显。
- Prompt 和 HUD 还可以更克制，让世界本身承担更多教学。

## 本轮改动

### 1. Overworld 地表和构图

- 重新整理了 DayWorld 的地表铺装，主路、农场服务道、镇中心广场、港口步道都做了更明确的手工切角和过渡。
- 保留程序化 TileMap 流程，但把最终的 grass / meadow / path / sand / water / dock atlas 调成更暖、更细密的生活模拟配色，而不是把外部 props sheet 硬切成底层地砖。
- 增加了更多边缘打散、花带、留白和过渡单元，让路线读起来像刻意布置，而不是大矩形块面。

### 2. Landmark 与首次寻路

- 农场、餐馆、商店、港口都换成更有“村镇感”的外部地标，重点强化建筑轮廓、前场、陈列和边缘 framing。
- 农场加了农舍、前场小摊、供给车、木箱、花箱和围栏组合。
- 餐馆加了暖色门前棚、菜单立牌、门前容器和更明确的营业前场。
- 商店加了摊位、后场仓屋、种子袋、工具架、展示台、开店立牌和 pennant 串旗。
- 港口加了 beacon、码头货物、缆绳、信号旗和更明确的 departure staging。
- 中央告示牌区域补了导向构图，让 farm / restaurant / shop / dock 的流向更自然。

### 3. Shop 身份与 interior 可读性

- 商店 interior 保留现有逻辑和交互区，只加强表现层。
- 用外部 interior sheet 补了后墙饰面、窗、等候角、沙发、桌椅、室内盆栽，让空间更像真实营业小铺。
- 种子货架、升级货架、请求板、展示台、货箱堆仍由现有逻辑驱动，但构图更明确地区分“买种子”“卖货”“接请求”“看升级”。
- 室内地板重新回到自绘木地板 / 石门槛 / 地毯 atlas，避免把 props sheet 当 floor tile 导致画面失真。

### 4. Open / Active 状态

- 商店 exterior 增加了开店立牌、入口暖光、串旗和更强的门前陈列。
- 餐馆、商店、港口的灯光和 glow 节奏继续跟 phase 绑定，晚些时候会更明确地表现“现在可去 / 现在可出发”。
- 港口 departure 点保留现有 gating 逻辑，但视觉上更像一个真实准备出航的地方。

### 5. Prompt / HUD 克制化

- DayWorld HUD prompt 继续收窄，只在需要时显示。
- Shop interior prompt 也收窄并抬高，减少常驻感。
- prompt 仍保留可读性，但进一步退到二线，让建筑、摆设、路面和灯光承担更多提示职责。

## 对 Pass 1 Partial 的回应

### 1. “ground treatment still feels somewhat procedural”

直接处理了。
- 地表 tile 不再错误地从 object sheet 截取。
- 路径、广场、农场边缘和港口过渡都重新做了 authored 切分。
- 大块矩形区域增加了切角、边缘打散和 flower / sand / meadow 过渡。

### 2. “first-time wayfinding may still rely too much on trial/error”

明显改善。
- 四个关键区域现在各自有更强的 silhouette 和前场。
- 中央广场、告示牌、灯、导向牌和路径连接关系更清楚。
- 第一次进入时，更容易凭世界本身读出 farm / restaurant / shop / dock。

### 3. “shop identity is visually closer but not yet fully self-explanatory”

直接处理了。
- exterior 更像种子和补给摊位。
- interior 增加等待角、墙面和展示分区，买卖 / 请求 / 升级不再全靠 popup 文本解释。

### 4. “shop open state is still relatively light-touch”

明显改善。
- 外部增加立牌、串旗、入口 glow 和门前货物。
- interior 也用 ambience glow 和更完整陈列强化“正在营业”的感觉。

### 5. “interaction prompts are improved, but still not fully contextual/minimal”

进一步收窄，但仍是辅助层。
- prompt 面板尺寸更小，显示条件更严格。
- 世界 cue 变强后，prompt 的职责更偏确认而不是导航主导。

## 外部素材接入说明

本轮新增了少量、同一作者来源的 top-down 像素素材，主要用于:
- DayWorld 建筑和村镇 props
- Shop interior 家具和墙面装饰
- 树、灌木、水边 patch 等环境 props

详细来源与许可备注见:
- `docs/DAYWORLD_VISUAL_PASS_2_ASSETS.md`

实现策略上，这些素材现在只承担建筑、道具、家具和 landmark，不再承担底层地砖 atlas。

## 回归与兼容性

本轮没有改动:
- save / inventory 架构
- worldified farm / restaurant / shop / night departure 的底层逻辑
- 现有 economy / onboarding / dialogue / orders / reward 管线

本轮主要风险控制点:
- 所有入口与交互区继续沿用现有 zone / signal 流程。
- 视觉改动尽量局限在 scene layout、tile atlas、props 和 HUD prompt 显示层。

## 有意延后

以下内容本轮没有继续扩大范围:
- 不把 DayWorld 扩成更大地图。
- 不新增新的 daytime 系统或商店功能。
- 不改 save/inventory 数据结构。
- 不做更重的 NPC 日程或复杂营业动画。
- 不追求一比一复制《星露谷》素材或地图语言，而是只吸收“温暖、手工、易读”的方向。

## 验收草案

建议本轮人工实走重点确认:
- 从默认进入点，是否更容易一眼区分 farm / restaurant / shop / dock。
- 商店 exterior 与 interior 是否能在不读长文本的情况下理解其用途。
- 晚间 dock / 商店 / 餐馆的 active cue 是否更明显。
- prompt 是否已经退到辅助层，而不是第一视觉主角。
- 现有农场种植、商店买卖、餐馆、夜战出发与返回流程是否仍然完整。
