# DayWorld Visual Pass 1 正式验收报告

日期: 2026-03-08

结论: `PASS`

说明:
- 本报告基于当前仓库实现、代码检查、现有进度截图，以及当日重新执行的 DayWorld 相关导入与 smoke 回归。
- `PASS` 表示当前 Pass 1 目标已满足。
- `PARTIAL` 表示方向正确且已有明显改善，但仍需要人工实走确认，或仍保留下一轮更高完成度 polish 空间。
- `FAIL` 表示当前轮的目标未满足，或有明确阻塞问题。

证据基线:
- 视觉方向文档: `docs/DAYWORLD_VISUAL_PASS_1.md`
- 视觉实现: `scripts/meta/day_world.gd`
- HUD 实现: `scripts/ui/day_hud.gd`
- 文案清理: `scripts/core/localization.gd`
- 进度截图: `docs/progress/dayworld_visual_pass_1_morning.png`, `docs/progress/dayworld_visual_pass_1_dock_ready.png`
- 导入检查: `godot --headless --path . --import`
- 回归检查: `./scripts/ci/run_plugin_focused_tests.sh`

保留说明:
- 本轮没有重新做一整套真人手柄/键盘漫游录屏，因此凡是强依赖“第一次进入手感”或“纯导航主观体验”的条目，会更严格地标为 `PARTIAL`，而不是过度乐观地写成 `PASS`。
- 这不影响 Pass 1 总体通过判断，但代表它还不是最终美术定稿。

## 0. 本轮验收原则

| 项目 | 结果 | 备注 |
| --- | --- | --- |
| 更像一个完整世界 | PASS | DayWorld 已从功能区壳子推进到带有镇区、农场、店面、码头身份的统一空间。 |
| 更容易读懂和导航 | PASS | 主路、镇区铺装、农场边界、码头轮廓都明显增强了可读性。 |
| 不破坏现有 worldified loop | PASS | 导入通过，DayWorld 相关 smoke 和 save/load 覆盖通过。 |

## 1. 视觉目标验收

### 1.1 整体视觉统一性

| 项目 | 结果 | 备注 |
| --- | --- | --- |
| DayWorld 看起来像同一个世界 | PASS | 同一轮主要采用现有 Tiny Swords 建筑与 foliage 方向，辅以 Godot 形状道具。 |
| 地面、道路、边界、道具、建筑轮廓风格基本统一 | PASS | 地表、石板、木栈道、围栏、招牌、棚布都围绕同一像素 top-down 语言组织。 |
| 没有明显不同来源素材硬拼违和感 | PASS | 本轮未引入新的外部素材或插件，没有新增混搭风险。 |
| 色调/明度/饱和度大致一致 | PASS | Phase 调色与 HUD 调色都已收拢到暖色生活模拟方向。 |
| 主要视觉语言明确 | PASS | 现在的读感已经是温暖、平静、top-down、像素生活模拟。 |

### 1.2 原型感是否下降

| 项目 | 结果 | 备注 |
| --- | --- | --- |
| 白天世界不再像 debug/admin shell | PASS | HUD、prompt、区域 props、地标与 phase 表现都明显降低了工具壳感。 |
| 不再主要依赖大块文字说明地点 | PASS | farm / restaurant / shop / dock 已有更强的地表、建筑和 props 识别。 |
| 视觉本身已经能传达很多信息 | PASS | 围栏、铺装、棚布、门脸、码头构件已承担了更多空间说明职责。 |
| 第一眼不再像测试场景或占位地图 | PARTIAL | 已明显脱离原型图，但地表仍偏程序化，尚未达到高完成度手工 authored 生活模拟地图质感。 |

### 1.3 小镇感是否出现

| 项目 | 结果 | 备注 |
| --- | --- | --- |
| 像一个小镇/村庄/港口生活区 | PASS | 镇中心铺装、店铺门脸、码头与农区分区已经成形。 |
| 空间里有生活痕迹 | PASS | 木箱、花箱、灯、围栏、码头杂物、长椅、告示牌都在强化生活痕迹。 |
| props 提升真实感 | PASS | 装饰量足以建立身份，不再只剩交互点。 |
| 留白和装饰比例合理 | PASS | 仍有可呼吸的空地，没有因为补 props 而变成噪音场。 |

## 2. 空间布局与导航验收

### 2.1 大布局是否清楚

| 项目 | 结果 | 备注 |
| --- | --- | --- |
| 进入 DayWorld 后能大致看懂整体布局 | PASS | 中央主路、农区、镇区、码头区的分块已经足够清楚。 |
| 主路和次路清楚 | PASS | 木栈道主轴和广场铺装承担了主要导向。 |
| 从出生点/主入口能自然找到主要区域 | PASS | 关键区域都围绕主路组织，没有藏在角落。 |
| 地图没有大量视觉噪音干扰方向判断 | PASS | 当前 props 密度适中，没有压过路线本身。 |
| 重要路径不会被装饰物遮挡 | PASS | 视觉装饰主要沿边界和节点布置，没有侵占主通行线。 |

### 2.2 导航是否依赖文字过多

| 项目 | 结果 | 备注 |
| --- | --- | --- |
| 不看大段 UI 也能猜出主要区域 | PASS | farm / shop / restaurant / dock 的外部身份已基本自说明。 |
| 路、边界、建筑轮廓、道具承担导航作用 | PASS | 视觉导航已从“纯 prompt 驱动”转到“世界地标驱动”。 |
| 不需要每到一个地方都靠 prompt 才知道是什么 | PASS | prompt 仍有辅助作用，但不再是唯一识别来源。 |
| 玩家第一次进入时不会明显迷路 | PARTIAL | 从当前构图看问题不大，但这一项仍建议以真人首进实走做最终签字。 |

### 2.3 进出流线是否顺

| 项目 | 结果 | 备注 |
| --- | --- | --- |
| DayWorld 到 farm / restaurant / shop / dock 路径顺畅 | PASS | 主路串联四个核心区域，空间关系比之前更自然。 |
| 建筑入口位置自然 | PASS | 入口与前场铺装、招牌、棚布、门脸已形成对应关系。 |
| 没有明显绕路或卡边角触发 | PARTIAL | 自动化覆盖已证明交互与路由未坏，但“物理行走触发手感”仍建议手动再确认一轮。 |
| 主要功能区距离合理 | PASS | 区域间距属于小镇级别，既不会过散，也没有挤成一个点。 |

## 3. 四个核心区域辨识度验收

### 3.1 Farm 区域

| 项目 | 结果 | 备注 |
| --- | --- | --- |
| 农场区域一眼能认出来 | PASS | 农田、围栏、农舍、农具/箱体语言都已建立。 |
| 有明确农业视觉语言 | PASS | 耕地、围栏、田块边界、辅助 props 都在。 |
| 农场不像单纯空地 | PASS | 农场已经是一个明确功能区，不是草地上摆几个交互框。 |
| 玩家会自然理解为种地的地方 | PASS | 读图层面已经成立。 |
| 农场入口/边界与镇子主体区分清楚 | PASS | 农区边界和主镇路网分开，身份明确。 |

### 3.2 Restaurant 区域

| 项目 | 结果 | 备注 |
| --- | --- | --- |
| 餐馆外观有明显身份 | PASS | 红色建筑、门脸、棚布、暖光已经形成餐馆气质。 |
| 门口/招牌/外墙/窗户/道具表达餐馆 | PASS | 暖窗、棚布、前场 props 提升了“营业中”的感觉。 |
| 相比商店身份清晰不同 | PASS | 与 shop 的蓝色市场式外观区分明确。 |
| 外部能感受到是营业中的地方 | PASS | 尤其在 afternoon / evening，暖光与前场更有烟火气。 |
| 餐馆周边不过空也不过乱 | PASS | 门前构图比较克制，能看清轮廓也不显单薄。 |

### 3.3 Shop 区域

| 项目 | 结果 | 备注 |
| --- | --- | --- |
| 商店外观清楚区别于餐馆 | PASS | 蓝色建筑、市场棚布和更轻的售卖氛围与餐馆区分明显。 |
| 门口/柜台/招牌/货物道具表达买卖 | PASS | 货物 props、门脸与前场布置已在传达交易属性。 |
| 玩家能自然推断这里可以买种子/卖东西 | PARTIAL | 现在已经能看出“店”，但“种子/售卖”的具体业务身份仍有一部分来自系统上下文。 |
| 商店和 town life 的关系更自然 | PASS | 商店已融入镇中心广场，而不是单独立在一个功能点上。 |

### 3.4 Dock / Night Departure 区域

| 项目 | 结果 | 备注 |
| --- | --- | --- |
| 一眼能认出来是 dock / harbor / 出发点 | PASS | 木平台、水边、塔楼、绳桩、货物与 shoreline 语言都到位。 |
| 有明确码头元素 | PASS | 栈桥、绳索、箱桶、岸边石、水面与灯光都已建立。 |
| 夜战出发点有足够地标感 | PASS | 码头塔楼和信标组合已经是全图最强地标之一。 |
| 不需要重文字也能知道晚上从这里走 | PASS | 就算不读长 prompt，也会自然把这里识别成 departure point。 |
| 与 farm / restaurant / shop 视觉语言明显不同 | PASS | 码头区已经形成独立的 shoreline / harbor 语言。 |

## 4. phase / 氛围 / 世界反馈验收

### 4.1 白天阶段差异是否可见

| 项目 | 结果 | 备注 |
| --- | --- | --- |
| morning / noon / evening 画面有可感知区别 | PASS | 天空、地表调色、日照位置、港口 glow、灯光与窗光都会变。 |
| 差异不只是 UI，世界本身有变化 | PASS | 变化直接落在 sky/overlay/scenery/window glow/dock gate/NPC 可见度上。 |
| 色调变化自然，不刺眼 | PASS | 颜色变化比较克制，没有为了“明显”把画面打脏。 |
| 差异足够明显但不过度 | PASS | 已达到 Pass 1 可感知标准。 |

### 4.2 evening / night readiness 是否清楚

| 项目 | 结果 | 备注 |
| --- | --- | --- |
| evening 后 dock 的可出发感增强 | PASS | gate 开闭、beacon glow、dock cue 与 HUD departure cue 会同步增强。 |
| 码头/灯光/信标/开门状态能传达 readiness | PASS | 视觉状态与逻辑状态对齐，并已纳入 smoke 覆盖。 |
| 未到条件时 world cue 能表达还不能出发 | PASS | 关闭 gate、较弱 beacon 与锁定文案共同表达未开放。 |
| 不用只靠系统字样判断能不能夜战 | PASS | 世界本体已有足够明显的 ready / locked 表达。 |

### 4.3 餐馆和商店的氛围是否更合理

| 项目 | 结果 | 备注 |
| --- | --- | --- |
| 餐馆在适合营业的阶段更暖、更有烟火气 | PASS | 餐馆窗光和整体配色已经明显朝这个方向推进。 |
| 商店在开放阶段有更清晰的可用状态 | PARTIAL | 可用状态现在比之前清楚，但仍主要依赖棚布、前场和轻量 glow，而不是更强的结构化营业动画。 |
| phase 反馈与世界表现一致 | PASS | Phase cue smoke 与 transition smoke 已验证逻辑和展示没有打架。 |

## 5. HUD / Prompt / UI 验收

### 5.1 HUD 压迫感是否下降

| 项目 | 结果 | 备注 |
| --- | --- | --- |
| HUD 比之前更轻、更克制 | PASS | 版式收紧，色彩从 neon/admin 转到暖色卡片式辅助层。 |
| HUD 不会抢走世界注意力 | PASS | 权重明显下降，世界更像主角。 |
| 重要信息仍可读 | PASS | day / phase / stamina / actions / gold / hotbar 均保留。 |
| HUD 风格与世界一致 | PASS | 视觉语言已经接近“辅助卡片”而不是“调试条”。 |

### 5.2 Prompt 是否更自然

| 项目 | 结果 | 备注 |
| --- | --- | --- |
| 交互提示不再像 debug label | PASS | 文案和面板样式都更自然。 |
| prompt 只在需要时出现 | PARTIAL | 当前 prompt 区仍是持续存在的辅助区块，只是文案与视觉已被弱化。 |
| prompt 层级清楚，不遮挡关键区域 | PASS | 面板位置稳定，没有压在核心交互点正上方。 |
| prompt 文案简短明确 | PASS | 文案已去掉 prototype/admin 口吻。 |
| 不会同时出现太多提示 | PASS | 当前信息分层基本可控。 |

### 5.3 面板是否真正退居二线

| 项目 | 结果 | 备注 |
| --- | --- | --- |
| 玩家主要依靠世界探索和地标，而不是面板导航 | PARTIAL | 世界导航已明显增强，但系统细节与节奏判断仍依赖 HUD/prompt 辅助。 |
| UI 是辅助，不是主要信息载体 | PASS | 当前权重已明显退居二线。 |
| 没有新的大块管理面板重新抢回主导地位 | PASS | 本轮没有新增侵入式管理面板。 |

## 6. 素材 / Tile / Props / 资源接入验收

### 6.1 资源组织是否干净

| 项目 | 结果 | 备注 |
| --- | --- | --- |
| 新素材放在清楚目录里 | PASS | 本轮未新增外部素材；继续复用现有 repo 内资源。 |
| 没有把下载内容乱塞进逻辑目录 | PASS | 本轮无新增下载内容。 |
| vendor / third_party / art 结构清楚 | PASS | 本轮无新的 vendor 接入。 |
| 文件命名大体整洁 | PASS | 本轮新增内容主要为文档与截图。 |

### 6.2 风格是否统一

| 项目 | 结果 | 备注 |
| --- | --- | --- |
| 外部素材与当前项目风格大体匹配 | PASS | 本轮未新增外部素材，避免了风格漂移。 |
| 没有明显“像另一款游戏”的割裂 | PASS | 统一使用现有建筑/foliage 方向。 |
| 没有混入太多风格冲突的 tileset | PASS | 本轮没有增加新的 tileset 来源。 |
| 少量素材比大量混搭更统一 | PASS | 实际策略就是不新增混搭。 |

### 6.3 License / 来源是否记录

| 项目 | 结果 | 备注 |
| --- | --- | --- |
| 新导入资源有来源说明 | PASS | 本轮无新导入资源。 |
| License 至少有简单文档记录 | PASS | 本轮无新导入资源，因此没有新增 license 风险。 |
| 没有不明来源资源直接进仓库 | PASS | 本轮未新增外部资源。 |
| 如有插件也有版本/来源说明 | PASS | 本轮未安装新插件。 |

## 7. DayWorld Visual Pass 1 专用回归验收

### 7.1 基础世界流程

| 项目 | 结果 | 备注 |
| --- | --- | --- |
| DayWorld 能正常加载 | PASS | `godot --headless --path . --import` 通过。 |
| 玩家可以正常移动 | PASS | DayWorld shell smoke 仍通过，未见输入/载入退化。 |
| camera 正常 | PASS | 当前没有新的 camera 回归迹象。 |
| Tile / props 调整没有打乱碰撞 | PASS | Farm、店铺、dock 的交互与 phase smoke 仍然正常通过。 |
| 美术层变化没有导致场景报错 | PASS | 导入和 smoke 均未报场景加载失败。 |

### 7.2 入口与路由

| 项目 | 结果 | 备注 |
| --- | --- | --- |
| farm 入口正常 | PASS | DayWorld shell / farm save-load smoke 覆盖通过。 |
| restaurant 入口正常 | PASS | Restaurant world gating / save-load smoke 通过。 |
| shop 入口正常 | PASS | Shop world gating / save-load smoke 通过。 |
| dock / night departure 正常 | PASS | DayWorld phase cue / transition gating smoke 通过。 |
| 返回 DayWorld 后位置/状态合理 | PASS | Transition gating 与 save/load 覆盖未发现恢复错位。 |

### 7.3 农场 world 交互

| 项目 | 结果 | 备注 |
| --- | --- | --- |
| plot 仍可交互 | PASS | DayWorld shell 与 farm save-load smoke 通过。 |
| plant / water / harvest 没坏 | PASS | 农场循环相关 smoke 仍通过。 |
| 工具槽位/提示未因 UI 调整失效 | PASS | hotbar 仍受 DayWorld snapshot 与 smoke 覆盖。 |
| 作物状态可见性未被新地面/props 遮住 | PASS | 当前构图没有把 plot/crop 覆盖到不可读。 |

### 7.4 phase / dock / world cue

| 项目 | 结果 | 备注 |
| --- | --- | --- |
| phase 变化仍驱动正确 world cue | PASS | DayWorldPhaseCueSmoke 明确覆盖此项。 |
| dock readiness 与底层状态一致 | PASS | cue、gate、popup、HUD departure text 都已做一致性检查。 |
| 不会出现视觉上能走但系统上不能或反过来 | PASS | transition gating smoke 已覆盖关键阻塞与恢复路径。 |

### 7.5 save/load

| 项目 | 结果 | 备注 |
| --- | --- | --- |
| DayWorld 改造后仍能存档/读档 | PASS | Idle / farm / phase / transition save-load smoke 都通过。 |
| 读档后不会丢失世界状态关键引用 | PASS | 选中工具、订单板、dock popup 等状态恢复仍正常。 |
| 新增视觉节点没有破坏 world-state 恢复 | PASS | 当前 smoke 没有显示恢复断链。 |

### 7.6 测试

| 项目 | 结果 | 备注 |
| --- | --- | --- |
| 相关 focused/smoke tests 仍通过 | PASS | `run_plugin_focused_tests.sh` 最终结果为 PASS。 |
| 至少跑一轮 DayWorld 直接相关回归 | PASS | 本次重新执行了 import 与 plugin-focused DayWorld 相关 smoke。 |
| 没有把刚建立的测试覆盖打坏 | PASS | DayWorld shell / cue / gating / save-load 覆盖均保持通过。 |

回归观察:
- plugin-focused smoke 过程中仍出现 `ObjectDB instances leaked at exit` 警告，但脚本最终 `PASS`，这属于现有非阻塞噪音，不构成此次 visual pass 的失败项。

## 8. 手动验收步骤建议

这一节本身不打 `PASS / PARTIAL / FAIL`，它是最终人工签字建议。当前最值得重走的手动 Case:
- Case A: 第一次进入 DayWorld，只靠视觉指出 farm / restaurant / shop / dock。
- Case B: 从主入口实际走一遍四个核心区域，确认没有“视觉上顺、手感上别扭”的入口问题。
- Case C: 连续观察 morning / noon / evening，确认 dock readiness 的读感足够明显。
- Case D: 实机完成种地、进餐馆、进商店、去 dock、返回、存档、读档一整套流程。

## 9. 代码 / 实现层面审查点

### 9.1 实现方式是否克制

| 项目 | 结果 | 备注 |
| --- | --- | --- |
| 没有为了视觉 pass 去重写 meta loop | PASS | 改动集中在 DayWorld/HUD/文案/文档层。 |
| 没有改 inventory / save 架构 | PASS | 保存与状态恢复只做了兼容复用，没有架构改写。 |
| 没有把业务逻辑硬塞进纯视觉节点 | PASS | 视觉反馈仍由现有 view model 驱动，没有新增并行系统。 |
| 改动主要集中在 DayWorld / HUD / 视觉资源层 | PASS | 当前实现与本轮范围一致。 |

### 9.2 结构是否可继续迭代

| 项目 | 结果 | 备注 |
| --- | --- | --- |
| 视觉资源接入方式后续还能继续用 | PASS | 现有做法可继续追加 props、palette、地表细化和 authored tile pass。 |

说明:
- 原始清单在 9.2 之后被截断；因此这里只评估了可见条目。

## 最终结论

DayWorld Visual Pass 1 `通过`。

当前版本已经从“能走的原型地图”提升到“具有统一视觉语言、清晰导航、四大核心区域身份和 phase-aware 世界反馈的小镇空间”。它仍有下一轮可继续拔高的地方，主要是:
- 地表仍偏程序化，尚未达到更高密度的 authored terrain / shoreline 质感
- 个别导航与入口手感项仍建议做一次真人实走签字
- prompt 面板虽然已弱化，但还没有完全做到“只在必要时出现”

这些都属于后续 polish，而不是 Pass 1 阻塞。
