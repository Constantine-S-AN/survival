extends Node
class_name LocalizationService

signal language_changed(language_code: String)

const DEFAULT_LANGUAGE_CODE := "en"
const SUPPORTED_LANGUAGE_CODES: Array[String] = ["en", "zh_CN"]
const LANGUAGE_DISPLAY_NAMES := {
	"en": {
		"en": "English",
		"zh_CN": "英语"
	},
	"zh_CN": {
		"en": "Chinese (Simplified)",
		"zh_CN": "中文"
	}
}

const TAG_LABELS := {
	"en": {
		"sonar": "Flare",
		"silence": "Silence",
		"heat": "Heat",
		"crit": "Crit",
		"pierce": "Pierce",
		"chain": "Chain",
		"aoe": "AOE",
		"pickup": "Pickup",
		"shield": "Shield",
		"speed": "Speed",
		"trap": "Trap",
		"control": "Control",
		"summon": "Summon",
		"economy": "Economy",
		"damage": "Damage",
		"weapon": "Weapon",
		"tempo": "Tempo",
		"noise": "Noise",
		"mobility": "Mobility",
		"defense": "Defense",
		"hull": "Hull",
		"kinetic": "Kinetic",
		"starter": "Starter"
	},
	"zh_CN": {
		"sonar": "照明弹",
		"silence": "静默",
		"heat": "热能",
		"crit": "暴击",
		"pierce": "穿透",
		"chain": "连锁",
		"aoe": "范围",
		"pickup": "拾取",
		"shield": "护盾",
		"speed": "速度",
		"trap": "陷阱",
		"control": "控制",
		"summon": "召唤",
		"economy": "经济",
		"damage": "伤害",
		"weapon": "武器",
		"tempo": "节奏",
		"noise": "噪声",
		"mobility": "机动",
		"defense": "防御",
		"hull": "船体",
		"kinetic": "动能",
		"starter": "起始"
	}
}

const RARITY_LABELS := {
	"en": {
		"common": "Common",
		"uncommon": "Uncommon",
		"rare": "Rare",
		"epic": "Epic",
		"legendary": "Legendary"
	},
	"zh_CN": {
		"common": "普通",
		"uncommon": "优秀",
		"rare": "稀有",
		"epic": "史诗",
		"legendary": "传说"
	}
}

const STAT_LABELS := {
	"en": {
		"damage_mult": "Damage",
		"attack_speed_mult": "Attack Speed",
		"projectile_speed_mult": "Projectile Speed",
		"projectile_count_bonus": "Projectile Count",
		"pierce_bonus": "Pierce",
		"move_speed_bonus": "Move Speed",
		"dash_cooldown_reduction": "Dash Cooldown",
		"max_hp": "Max HP",
		"heal": "Heal",
		"regen_per_second": "Regen",
		"xp_gain_mult": "XP Gain",
		"noise_generation_mult": "Noise Gain",
		"noise_decay_bonus": "Noise Decay",
		"dash_noise_mult": "Dash Noise",
		"sonar_reveal_duration_mult": "Flare Reveal Duration",
		"revealed_damage_mult": "Revealed Damage",
		"low_noise_damage_mult": "Low-Noise Damage",
		"low_noise_attack_speed_mult": "Low-Noise Attack Speed",
		"high_noise_damage_mult": "High-Noise Damage",
		"high_noise_attack_speed_mult": "High-Noise Attack Speed",
		"pickup_radius_mult": "Pickup Radius",
		"summon_cap_bonus": "Summon Cap",
		"summon_resistance": "Summon Resistance",
		"summon_contact_radius_mult": "Summon Contact Radius",
		"summon_orbit_radius_mult": "Summon Orbit Radius",
		"summon_hit_noise_refund": "Summon Hit Noise Refund",
		"summon_guard_damage_reduction": "Summon Guard Reduction",
		"kill_noise_refund": "Kill Noise Refund",
		"kill_attack_cd_refund": "Kill Attack Cooldown Refund",
		"kill_skill_cd_refund": "Kill Flare Cooldown Refund",
		"flare_noise_spike_mult": "Flare Noise Spike",
		"flare_visibility_grace_mult": "Flare Grace Duration",
		"flare_overdrive_duration": "Flare Overdrive Duration",
		"flare_overdrive_attack_speed_mult": "Flare Overdrive Attack Speed",
		"flare_overdrive_damage_mult": "Flare Overdrive Damage",
		"darkness_noise_decay_boost": "Darkness Noise Decay Boost",
		"chain_bonus": "Chain Chance",
		"weapon_level_up": "Weapon Level",
		"weapon_level_up_active": "Active Weapon Level",
		"weapon_damage_mult": "Weapon Damage",
		"weapon_attack_rate_mult": "Weapon Attack Rate",
		"weapon_range_mult": "Weapon Range",
		"weapon_projectile_speed_mult": "Weapon Projectile Speed",
		"weapon_pierce_bonus": "Weapon Pierce",
		"weapon_crit_chance_add": "Weapon Crit Chance",
		"weapon_crit_multiplier_add": "Weapon Crit Multiplier",
		"weapon_aoe_radius_mult": "Weapon AOE Radius",
		"weapon_noise_mult": "Weapon Noise",
		"weapon_noise_add": "Weapon Noise",
		"weapon_projectile_count_bonus": "Weapon Projectile Count",
		"weapon_reveal_bonus_add": "Weapon Reveal Bonus",
		"weapon_summon_cap_bonus": "Weapon Summon Cap"
	},
	"zh_CN": {
		"damage_mult": "伤害",
		"attack_speed_mult": "攻速",
		"projectile_speed_mult": "弹速",
		"projectile_count_bonus": "弹体数量",
		"pierce_bonus": "穿透",
		"move_speed_bonus": "移速",
		"dash_cooldown_reduction": "冲刺冷却",
		"max_hp": "最大生命",
		"heal": "治疗",
		"regen_per_second": "回复",
		"xp_gain_mult": "经验获取",
		"noise_generation_mult": "噪声获取",
		"noise_decay_bonus": "噪声衰减",
		"dash_noise_mult": "冲刺噪声",
		"sonar_reveal_duration_mult": "照明显形时长",
		"revealed_damage_mult": "对显形目标伤害",
		"low_noise_damage_mult": "低噪伤害",
		"low_noise_attack_speed_mult": "低噪攻速",
		"high_noise_damage_mult": "高噪伤害",
		"high_noise_attack_speed_mult": "高噪攻速",
		"pickup_radius_mult": "拾取范围",
		"summon_cap_bonus": "召唤上限",
		"summon_resistance": "召唤抗性",
		"summon_contact_radius_mult": "召唤接触范围",
		"summon_orbit_radius_mult": "召唤环绕半径",
		"summon_hit_noise_refund": "召唤命中降噪",
		"summon_guard_damage_reduction": "召唤护卫减伤",
		"kill_noise_refund": "击杀降噪",
		"kill_attack_cd_refund": "击杀减攻击冷却",
		"kill_skill_cd_refund": "击杀减照明弹冷却",
		"flare_noise_spike_mult": "照明弹噪声尖峰",
		"flare_visibility_grace_mult": "照明弹可视宽限",
		"flare_overdrive_duration": "照明弹过载时长",
		"flare_overdrive_attack_speed_mult": "照明弹过载攻速",
		"flare_overdrive_damage_mult": "照明弹过载伤害",
		"darkness_noise_decay_boost": "黑暗降噪强化",
		"chain_bonus": "连锁概率",
		"weapon_level_up": "武器等级",
		"weapon_level_up_active": "主动武器等级",
		"weapon_damage_mult": "武器伤害",
		"weapon_attack_rate_mult": "武器攻速",
		"weapon_range_mult": "武器射程",
		"weapon_projectile_speed_mult": "武器弹速",
		"weapon_pierce_bonus": "武器穿透",
		"weapon_crit_chance_add": "武器暴击率",
		"weapon_crit_multiplier_add": "武器暴击倍率",
		"weapon_aoe_radius_mult": "武器范围",
		"weapon_noise_mult": "武器噪声",
		"weapon_noise_add": "武器噪声",
		"weapon_projectile_count_bonus": "武器弹体数量",
		"weapon_reveal_bonus_add": "武器显形加成",
		"weapon_summon_cap_bonus": "武器召唤上限"
	}
}

const UI_TEXT := {
	"menu.subtitle": {"en": "FOG / FLARE / NOISE", "zh_CN": "迷雾 / 照明弹 / 噪声"},
	"menu.play": {"en": "Play", "zh_CN": "开始游戏"},
	"menu.profile": {"en": "Profile", "zh_CN": "档案"},
	"menu.settings": {"en": "Settings", "zh_CN": "设置"},
	"menu.quit": {"en": "Quit", "zh_CN": "退出游戏"},
	"menu.language": {"en": "Language", "zh_CN": "语言"},
	"menu.placeholder_profile": {"en": "Profile page is coming soon.", "zh_CN": "档案页面即将推出。"},
	"menu.placeholder_settings": {"en": "Settings page is coming soon.", "zh_CN": "设置页面即将推出。"},
	"meta.common.none": {"en": "None", "zh_CN": "无"},
	"meta.common.back": {"en": "Back", "zh_CN": "返回"},
	"meta.common.close": {"en": "Close", "zh_CN": "关闭"},
	"meta.common.no_stamina": {"en": "Not enough stamina.", "zh_CN": "体力不足。"},
	"meta.common.no_actions": {"en": "No daytime actions remaining.", "zh_CN": "今日白天行动次数已用尽。"},
	"meta.phase.day": {"en": "Day", "zh_CN": "白天"},
	"meta.phase.morning": {"en": "Morning", "zh_CN": "早晨"},
	"meta.phase.noon": {"en": "Noon", "zh_CN": "中午"},
	"meta.phase.afternoon": {"en": "Afternoon", "zh_CN": "下午"},
	"meta.phase.evening": {"en": "Evening", "zh_CN": "傍晚"},
	"meta.phase.night": {"en": "Night", "zh_CN": "夜晚"},
	"meta.hub.title": {"en": "Day Hub", "zh_CN": "白昼据点"},
	"meta.hub.subtitle": {"en": "Plan the day, then turn the night haul into tomorrow's edge.", "zh_CN": "规划白天行动，再把夜晚收获变成明天的优势。"},
	"meta.hub.farm": {"en": "Farm", "zh_CN": "农场"},
	"meta.hub.restaurant": {"en": "Restaurant", "zh_CN": "餐馆"},
	"meta.hub.shop": {"en": "Shop", "zh_CN": "商店"},
	"meta.hub.farm_tooltip": {"en": "Spend stamina now to set up future harvests, pantry stock, and cash crops.", "zh_CN": "现在消耗体力，为之后的收获、厨房库存和现金作物做准备。"},
	"meta.hub.restaurant_tooltip": {"en": "Turn stocked ingredients into the best daytime gold. A full service costs {value} actions.", "zh_CN": "把现有食材转成最强的白天金币收入。完整营业会消耗 {value} 次行动。"},
	"meta.hub.shop_tooltip": {"en": "Buy seeds, sell surplus stock, and install restaurant upgrades.", "zh_CN": "购买种子、出售富余库存，并安装餐馆升级。"},
	"meta.hub.shop_tooltip_early": {"en": "Buy seeds for future crop choices, sell only real surplus, and install upgrades. Planned menus usually pay more than raw sales.", "zh_CN": "购买种子以扩展后续作物选择，只卖真正的富余库存，并安装升级。规划好的菜单通常比原料直卖更赚钱。"},
	"meta.hub.wait_evening": {"en": "Rest Until Evening", "zh_CN": "休整至傍晚"},
	"meta.hub.launch_night": {"en": "Launch Night Combat", "zh_CN": "启动夜间战斗"},
	"meta.hub.walkable_world": {"en": "Walkable World", "zh_CN": "步行世界"},
	"meta.hub.walkable_world_tooltip": {"en": "Switch back to the walkable daytime world while keeping the legacy hub available for fallback.", "zh_CN": "切回步行式白天世界，并保留旧版据点作为回退方案。"},
	"meta.hub.menu": {"en": "Main Menu", "zh_CN": "主菜单"},
	"meta.hub.day": {"en": "Day {value}", "zh_CN": "第 {value} 天"},
	"meta.hub.gold": {"en": "Gold: {value}", "zh_CN": "金币：{value}"},
	"meta.hub.reputation": {"en": "Reputation: {value}", "zh_CN": "口碑：{value}"},
	"meta.hub.stamina": {"en": "Stamina: {current}/{max}", "zh_CN": "体力：{current}/{max}"},
	"meta.hub.actions": {"en": "Actions: {current}/{max}", "zh_CN": "行动：{current}/{max}"},
	"meta.hub.phase": {"en": "Phase: {value}", "zh_CN": "阶段：{value}"},
	"meta.hub.inventory": {"en": "Inventory: {value}", "zh_CN": "库存：{value}"},
	"meta.hub.seeds": {"en": "Unlocked seeds: {value}", "zh_CN": "已解锁种子：{value}"},
	"meta.hub.recipes": {"en": "Unlocked recipes: {value}", "zh_CN": "已解锁食谱：{value}"},
	"meta.hub.night_bonus": {"en": "Night bonus: {value}", "zh_CN": "夜间加成：{value}"},
	"meta.hub.bridge": {"en": "Night bridge: {value}", "zh_CN": "夜间联动：{value}"},
	"meta.hub.status_night_locked": {"en": "Night combat opens in {value} more daytime action(s).", "zh_CN": "再推进 {value} 次白天行动后，才能进入夜战。"},
	"meta.hub.status_night_ready": {"en": "Evening has started. You can still use the remaining day actions before descending.", "zh_CN": "傍晚已经开始。你仍可消耗剩余行动后再下潜。"},
	"meta.hub.status_waited": {"en": "Spent {value} action(s) preparing for nightfall.", "zh_CN": "已消耗 {value} 次行动为夜幕降临做准备。"},
	"meta.hub.wait_tooltip": {"en": "Spend {value} action(s) to fast-forward to Evening.", "zh_CN": "消耗 {value} 次行动，直接推进到傍晚。"},
	"meta.hub.wait_tooltip_ready": {"en": "Evening is already here.", "zh_CN": "现在已经是傍晚。"},
	"meta.hub.night_tooltip_locked": {"en": "Reach Evening first or use Rest Until Evening. Remaining to unlock: {value} action(s).", "zh_CN": "先进入傍晚，或使用“休整至傍晚”。还需推进 {value} 次行动。"},
	"meta.hub.night_tooltip_ready": {"en": "Evening reached. Launch night combat when ready.", "zh_CN": "已到傍晚。准备好后即可启动夜间战斗。"},
	"meta.hub.guide_title_day1": {"en": "Day 1 Guide", "zh_CN": "第 1 天指引"},
	"meta.hub.guide_title_day2": {"en": "Day 2 Guide", "zh_CN": "第 2 天指引"},
	"meta.hub.guide_title_day3": {"en": "Day 3 Guide", "zh_CN": "第 3 天指引"},
	"meta.hub.guide_body_day1": {"en": "- Farm now if you want harvests on Day 3.\n- Restaurant converts today's pantry into immediate gold.\n- Reach Evening, run night combat, then use the return summary to plan tomorrow.", "zh_CN": "- 想在第 3 天收获，就要现在开始种地。\n- 餐馆会把今天的库存立刻变成金币。\n- 先推进到傍晚，完成夜战，再根据返程总结规划明天。"},
	"meta.hub.guide_body_day2": {"en": "- Night drops are best spent on unlock progress and premium dishes.\n- A restaurant shift costs {value} actions, so decide early if today is farm-heavy or service-heavy.\n- Shop seeds and upgrades are long-term investments, not emergency fixes.", "zh_CN": "- 夜间掉落最适合用于解锁进度和高价菜品。\n- 一次餐馆营业会消耗 {value} 次行动，所以要尽早决定今天偏种田还是偏营业。\n- 商店种子和升级是长期投资，不是临时补救。"},
	"meta.hub.guide_body_day3": {"en": "- Harvest yesterday's watered crops before you sell or cook them.\n- Selling produce is safe cash, but planned menus usually pay more.\n- Save rare night materials for signature dishes or unlock progress.", "zh_CN": "- 先收昨天浇过水的作物，再决定卖掉还是拿去做菜。\n- 卖作物是稳妥现金，但规划好的菜单通常更赚钱。\n- 稀有夜间材料最好留给招牌菜或解锁进度。"},
	"meta.world.title": {"en": "Harbor District", "zh_CN": "港区街区"},
	"meta.world.subtitle": {"en": "Walk the block to route farm work, kitchen prep, supply runs, and the next descent.", "zh_CN": "在街区中步行安排农场工作、厨房准备、补给采购和下一次下潜。"},
	"meta.world.move_hint": {"en": "WASD / Arrows move  |  E interact  |  Q / Tab tools", "zh_CN": "WASD / 方向键移动  |  E 互动  |  Q / Tab 切换工具"},
	"meta.world.prompt_idle": {"en": "Walk up to a plot, doorway, bench, board, or dock to see what you can do there.", "zh_CN": "走到地块、门口、长椅、公告板或码头旁，就会看到可执行的操作。"},
	"meta.world.prompt_interact": {"en": "Press E to enter {value}.", "zh_CN": "按 E 进入 {value}。"},
	"meta.world.prompt_farm_use": {"en": "Press E to use {value} on {target}.", "zh_CN": "按 E 对 {target} 使用 {value}。"},
	"meta.world.prompt_farm_unavailable": {"en": "{value} is not available right now.", "zh_CN": "{value} 当前不可用。"},
	"meta.world.prompt_locked": {"en": "{value} is not available yet.", "zh_CN": "{value} 目前还不可用。"},
	"meta.world.prompt_orders_open": {"en": "Orders board open. Review contracts or press Esc to close it.", "zh_CN": "订单板已打开。查看委托，或按 Esc 关闭。"},
	"meta.world.orders_ready": {"en": "Orders ready: {value}", "zh_CN": "可领取订单：{value}"},
	"meta.world.orders_tooltip": {"en": "Open the daily orders board to review or claim side work from farm, restaurant, and night pillars.", "zh_CN": "打开每日订单板，查看或领取农场、餐馆和夜间支线订单。"},
	"meta.world.area_farm": {"en": "Farm Lot", "zh_CN": "农场地块"},
	"meta.world.area_restaurant": {"en": "Kitchen Row", "zh_CN": "厨房街"},
	"meta.world.area_shop": {"en": "Supply Stall", "zh_CN": "补给摊位"},
	"meta.world.area_orders": {"en": "Orders Board", "zh_CN": "订单公告板"},
	"meta.world.area_wait": {"en": "Watch Bench", "zh_CN": "守望长椅"},
	"meta.world.area_night": {"en": "Night Dock", "zh_CN": "夜潜码头"},
	"meta.world.legacy_hub": {"en": "Legacy Hub", "zh_CN": "旧版据点"},
	"meta.world.legacy_hub_tooltip": {"en": "Open the original panel-first Day Hub for fallback or debugging.", "zh_CN": "打开原始的面板式白昼据点，用于回退或调试。"},
	"meta.day_hud.orders": {"en": "Orders", "zh_CN": "订单"},
	"meta.day_hud.orders_ready": {"en": "Orders ({value})", "zh_CN": "订单（{value}）"},
	"meta.day_hud.orders_tooltip": {"en": "Open the daily orders board.", "zh_CN": "打开每日订单板。"},
	"meta.day_hud.farm_tool": {"en": "Farm Tool", "zh_CN": "农具"},
	"meta.day_hud.farm_tool_hint": {"en": "Q / Tab cycle  |  E use", "zh_CN": "Q / Tab 切换  |  E 使用"},
	"meta.shop.title": {"en": "Day Shop", "zh_CN": "白昼商店"},
	"meta.shop.subtitle": {"en": "Keep the planning loop moving with seed buys, stock sales, and kitchen upgrades.", "zh_CN": "通过购买种子、出售库存和厨房升级来推动白天规划循环。"},
	"meta.shop.world_title": {"en": "Supply House", "zh_CN": "补给小铺"},
	"meta.shop.world_move_hint": {"en": "WASD / Arrows move  |  E interact  |  Esc close popup", "zh_CN": "WASD / 方向键移动  |  E 互动  |  Esc 关闭弹窗"},
	"meta.shop.world_prompt_idle": {"en": "Walk to the counter, chat with the regular, or head back outside.", "zh_CN": "走到柜台、和常客聊聊，或者直接回到街上。"},
	"meta.shop.world_prompt_interact": {"en": "Press E to check {value}.", "zh_CN": "按 E 查看 {value}。"},
	"meta.shop.world_prompt_popup": {"en": "Station panel open. Review the offer or press Esc to close it.", "zh_CN": "站点面板已打开。查看信息，或按 Esc 关闭。"},
	"meta.shop.station_shopkeeper": {"en": "Shop Counter", "zh_CN": "店主柜台"},
	"meta.shop.station_regular": {"en": "Town Regular", "zh_CN": "镇上常客"},
	"meta.shop.station_exit": {"en": "Street Door", "zh_CN": "街口门"},
	"meta.shop.leave": {"en": "Step Outside", "zh_CN": "走出商店"},
	"meta.shop.popup_merchant_title": {"en": "Shop Counter", "zh_CN": "店主柜台"},
	"meta.shop.popup_customer_title": {"en": "Town Regular", "zh_CN": "镇上常客"},
	"meta.shop.shopkeeper_line": {"en": "Need seed stock, cash from surplus, or a better fixture for the restaurant?", "zh_CN": "想补些种子、把富余库存换成现金，还是给餐馆添点新装置？"},
	"meta.shop.shopkeeper_line_ready": {"en": "Board's moving today. You've got {value} order reward(s) ready once you check the contract board.", "zh_CN": "今天公告板有动静。你去看一下委托板，就能领到 {value} 份订单奖励。"},
	"meta.shop.customer_line_request": {"en": "If you're already making the rounds, could you keep an eye on {value}?", "zh_CN": "如果你正好要在镇里转一圈，能不能顺手帮我留意一下 {value}？"},
	"meta.shop.customer_line_idle": {"en": "Quiet morning. Folks still glance at the board before deciding what the town needs.", "zh_CN": "今早挺安静的。大家还是会先看看公告板，再决定镇上缺什么。"},
	"meta.shop.request_none_title": {"en": "No Request Posted", "zh_CN": "暂时没有请求"},
	"meta.shop.request_none_body": {"en": "No one nearby is flagging fresh work right now. Check back after the town board refreshes tomorrow.", "zh_CN": "附近暂时没人发布新活。等明天公告板刷新后再来看看。"},
	"meta.shop.request_none_status": {"en": "Nothing urgent", "zh_CN": "暂无急事"},
	"meta.shop.request_reward": {"en": "Reward: {value}", "zh_CN": "奖励：{value}"},
	"meta.shop.request_status": {"en": "Status: {value}", "zh_CN": "状态：{value}"},
	"meta.shop.request_objective": {"en": "Need: {value}", "zh_CN": "需求：{value}"},
	"meta.shop.request_progress": {"en": "Progress: {value}", "zh_CN": "进度：{value}"},
	"meta.shop.stats": {"en": "Day {day} · {phase} · Gold {gold} · Actions {actions}/{action_max}", "zh_CN": "第 {day} 天 · {phase} · 金币 {gold} · 行动 {actions}/{action_max}"},
	"meta.shop.inventory": {"en": "Inventory: {value}", "zh_CN": "库存：{value}"},
	"meta.shop.owned_upgrades": {"en": "Installed upgrades: {value}", "zh_CN": "已安装升级：{value}"},
	"meta.shop.owned_none": {"en": "None yet", "zh_CN": "尚无"},
	"meta.shop.seed_title": {"en": "Seed Catalog", "zh_CN": "种子目录"},
	"meta.shop.seed_hint": {"en": "Seeds are long-term picks: cash crops sell safely, but crop-specific recipes pay more.", "zh_CN": "种子是长期选择：现金作物能稳定出售，但对应食谱通常更赚钱。"},
	"meta.shop.sell_title": {"en": "Sell Stock", "zh_CN": "出售库存"},
	"meta.shop.sell_hint": {"en": "Sell true surplus one unit at a time. Planned menus usually beat dumping ingredients raw.", "zh_CN": "每次只卖真正富余的 1 份库存。规划好的菜单通常比原料直卖更赚钱。"},
	"meta.shop.upgrade_title": {"en": "Restaurant Upgrades", "zh_CN": "餐馆升级"},
	"meta.shop.upgrade_hint": {"en": "Upgrades improve every later service, which is usually stronger than a one-day sale spike.", "zh_CN": "升级会强化之后的每一次营业，通常比一天的临时卖货更划算。"},
	"meta.shop.empty": {"en": "Nothing to show right now.", "zh_CN": "当前没有可显示的内容。"},
	"meta.shop.seed_action": {"en": "Buy {name}\nCost ${cost}\nHarvest {yield} x {crop} · Sell ${value}", "zh_CN": "购买 {name}\n花费 ${cost}\n收获 {yield} x {crop} · 售价 ${value}"},
	"meta.shop.seed_owned": {"en": "{name}\nAlready in the farm catalog", "zh_CN": "{name}\n已加入农场目录"},
	"meta.shop.seed_tooltip_cost": {"en": "Cost: ${value}", "zh_CN": "花费：${value}"},
	"meta.shop.seed_tooltip_buy": {"en": "Day shop price: ${value}", "zh_CN": "白天商店售价：${value}"},
	"meta.shop.seed_tooltip_sell_value": {"en": "Sell value: ${value}", "zh_CN": "售价：${value}"},
	"meta.shop.seed_tooltip_use": {"en": "Kitchen uses: {value}", "zh_CN": "厨房用途：{value}"},
	"meta.shop.sell_action": {"en": "Sell 1 x {name}\nHave {count} · Gain ${value}", "zh_CN": "出售 1 x {name}\n持有 {count} · 获得 ${value}"},
	"meta.shop.sell_tooltip_value": {"en": "Gain ${value} for each unit sold.", "zh_CN": "每出售 1 份可获得 ${value}。"},
	"meta.shop.upgrade_action": {"en": "Install {name}\nCost ${cost}\n{effects}", "zh_CN": "安装 {name}\n花费 ${cost}\n{effects}"},
	"meta.shop.upgrade_owned": {"en": "{name}\nInstalled · {effects}", "zh_CN": "{name}\n已安装 · {effects}"},
	"meta.shop.upgrade_tooltip_cost": {"en": "Cost: ${value}", "zh_CN": "花费：${value}"},
	"meta.shop.status_seed_bought": {"en": "Bought {value} for the farm catalog.", "zh_CN": "已将 {value} 加入农场目录。"},
	"meta.shop.status_seed_owned": {"en": "{value} is already available on the farm.", "zh_CN": "{value} 已可在农场使用。"},
	"meta.shop.status_need_gold": {"en": "Not enough gold for that purchase.", "zh_CN": "金币不足，无法完成这次购买。"},
	"meta.shop.status_sell_done": {"en": "Sold 1 x {value}.", "zh_CN": "已出售 1 x {value}。"},
	"meta.shop.status_sell_missing": {"en": "You do not have any {value} to sell.", "zh_CN": "你没有可出售的 {value}。"},
	"meta.shop.status_upgrade_bought": {"en": "Installed {value}. Future services now use its bonus.", "zh_CN": "已安装 {value}。后续营业将使用其加成。"},
	"meta.shop.status_upgrade_owned": {"en": "{value} is already installed.", "zh_CN": "{value} 已经安装。"},
	"meta.shop.effect.demand_bonus": {"en": "+{value}% demand", "zh_CN": "+{value}% 需求"},
	"meta.shop.effect.capacity_bonus": {"en": "+{value} service capacity", "zh_CN": "+{value} 接待容量"},
	"meta.shop.effect.satisfaction_bonus": {"en": "+{value}% satisfaction", "zh_CN": "+{value}% 满意度"},
	"meta.shop.effect.special_slots": {"en": "+{value} specials slot", "zh_CN": "+{value} 特供栏位"},
	"meta.shop.effect.none": {"en": "No direct service bonus", "zh_CN": "没有直接营业加成"},
	"meta.bridge.summary_none": {"en": "Night combat brings back rare drops that unlock better crops, premium dishes, and stronger long-term plans.", "zh_CN": "夜间战斗会带回稀有掉落，用来解锁更强的作物、高价菜品和长期规划。"},
	"meta.bridge.recipe_ready": {"en": "Cook now: {name} (${price}, {servings} servings)", "zh_CN": "现在可做：{name}（${price}，{servings} 份）"},
	"meta.bridge.unlock_progress": {"en": "{name}: {current}/{required} toward {target}", "zh_CN": "{name}：{current}/{required}，目标 {target}"},
	"meta.bridge.crop_ready": {"en": "{name} sells for ${value} and feeds {uses}", "zh_CN": "{name} 售价 ${value}，并可用于 {uses}"},
	"meta.bridge.stock_title": {"en": "Night stock", "zh_CN": "夜间库存"},
	"meta.bridge.stock_line": {"en": "{name} x{amount} -> {uses}", "zh_CN": "{name} x{amount} -> {uses}"},
	"meta.bridge.stock_line_simple": {"en": "{name} x{amount}", "zh_CN": "{name} x{amount}"},
	"meta.bridge.use_unlock": {"en": "{name} unlock", "zh_CN": "解锁 {name}"},
	"meta.bridge.unlock_line": {"en": "Unlock: {value}", "zh_CN": "解锁：{value}"},
	"meta.bridge.use_line": {"en": "Uses: {value}", "zh_CN": "用途：{value}"},
	"meta.bridge.value_line": {"en": "Value: {value}", "zh_CN": "价值：{value}"},
	"meta.bridge.night_source": {"en": "Night source: {value}", "zh_CN": "夜间来源：{value}"},
	"meta.farm.title": {"en": "Farm", "zh_CN": "农场"},
	"meta.farm.subtitle": {"en": "Invest daytime actions now for future harvests, pantry stock, and cash crops.", "zh_CN": "现在投入白天行动，为之后的收获、厨房库存和现金作物做准备。"},
	"meta.farm.stats": {"en": "Day {day} · {phase} · Stamina {stamina}/{max} · Actions {actions}/{action_max}", "zh_CN": "第 {day} 天 · {phase} · 体力 {stamina}/{max} · 行动 {actions}/{action_max}"},
	"meta.farm.inventory": {"en": "Inventory: {value}", "zh_CN": "库存：{value}"},
	"meta.farm.bridge": {"en": "Night path: {value}", "zh_CN": "夜间农线：{value}"},
	"meta.farm.tool_selected": {"en": "Selected tool: {value}", "zh_CN": "当前工具：{value}"},
	"meta.farm.tool_none": {"en": "None", "zh_CN": "无"},
	"meta.farm.tool_till": {"en": "Till\n1 stamina · 1 action", "zh_CN": "翻地\n1 体力 · 1 行动"},
	"meta.farm.tool_water": {"en": "Water\n1 stamina · 1 action", "zh_CN": "浇水\n1 体力 · 1 行动"},
	"meta.farm.tool_harvest": {"en": "Harvest\n1 action", "zh_CN": "收获\n1 行动"},
	"meta.farm.tool_seed_detail": {"en": "Plant · {days} days · {cost} stamina · 1 action", "zh_CN": "播种 · {days} 天 · {cost} 体力 · 1 行动"},
	"meta.farm.tool_night_unlock": {"en": "Night unlock · {value}", "zh_CN": "夜间解锁 · {value}"},
	"meta.farm.tooltip.harvest": {"en": "Harvest: {crop} x{yield} in {days} day(s) · Sell ${value}", "zh_CN": "{days} 天后收获：{crop} x{yield} · 售价 ${value}"},
	"meta.farm.tooltip.use": {"en": "Kitchen uses: {value}", "zh_CN": "厨房用途：{value}"},
	"meta.farm.plot_empty": {"en": "Empty Plot", "zh_CN": "空地块"},
	"meta.farm.plot_empty_hint": {"en": "Till to prepare soil", "zh_CN": "先翻地再种植"},
	"meta.farm.plot_tilled": {"en": "Tilled Soil", "zh_CN": "已翻好的土"},
	"meta.farm.plot_tilled_hint": {"en": "Ready for seeds", "zh_CN": "可以播种"},
	"meta.farm.plot_planted_hint": {"en": "Needs water · {value}", "zh_CN": "需要浇水 · {value}"},
	"meta.farm.plot_watered_hint": {"en": "Watered today · {value}", "zh_CN": "今天已浇水 · {value}"},
	"meta.farm.plot_harvest_hint": {"en": "Ready to harvest", "zh_CN": "可以收获"},
	"meta.farm.plot_number": {"en": "Plot {value}", "zh_CN": "地块 {value}"},
	"meta.farm.status_invalid": {"en": "That plot is unavailable.", "zh_CN": "该地块当前不可用。"},
	"meta.farm.status_locked": {"en": "{value} is still locked.", "zh_CN": "{value} 仍未解锁。"},
	"meta.farm.status_tilled": {"en": "That plot is already prepared.", "zh_CN": "这块地已经处理好了。"},
	"meta.farm.status_till_done": {"en": "Prepared plot {value}.", "zh_CN": "已整理地块 {value}。"},
	"meta.farm.status_need_till": {"en": "Till the plot before planting.", "zh_CN": "播种前需要先翻地。"},
	"meta.farm.status_plot_busy": {"en": "That plot already has a crop.", "zh_CN": "这块地已经种了作物。"},
	"meta.farm.status_plant_done": {"en": "Planted {value}.", "zh_CN": "已种下 {value}。"},
	"meta.farm.status_need_seed": {"en": "Plant something there first.", "zh_CN": "先在这里种下作物。"},
	"meta.farm.status_ready": {"en": "That crop is already ready to harvest.", "zh_CN": "这株作物已经可以收获。"},
	"meta.farm.status_watered": {"en": "That crop was already watered today.", "zh_CN": "这株作物今天已经浇过水。"},
	"meta.farm.status_water_done": {"en": "Watered {value}.", "zh_CN": "已为 {value} 浇水。"},
	"meta.farm.status_not_ready": {"en": "That crop is not ready yet.", "zh_CN": "这株作物还没成熟。"},
	"meta.farm.status_gain": {"en": "Harvested: {value}", "zh_CN": "收获：{value}"},
	"meta.farm.action_locked": {"en": "Unlock after the first successful night.", "zh_CN": "首次成功完成夜晚后解锁。"},
	"meta.farm.action_shop_unlock": {"en": "Buy in the daytime shop.", "zh_CN": "可在白天商店购买。"},
	"meta.restaurant.title": {"en": "Restaurant", "zh_CN": "餐馆"},
	"meta.restaurant.subtitle": {"en": "Plan the menu, open service, and turn stocked ingredients into real margin.", "zh_CN": "规划菜单、开门营业，把库存食材转成真正的利润。"},
	"meta.restaurant.stats": {"en": "Day {day} · {phase} · Gold {gold} · Reputation {reputation} · Actions {actions}/{action_max}", "zh_CN": "第 {day} 天 · {phase} · 金币 {gold} · 口碑 {reputation} · 行动 {actions}/{action_max}"},
	"meta.restaurant.bridge": {"en": "Night specials: {value}", "zh_CN": "夜间特供：{value}"},
	"meta.restaurant.world_title": {"en": "Dining Room", "zh_CN": "餐厅内场"},
	"meta.restaurant.world_move_hint": {"en": "WASD / Arrows move  |  E interact  |  Esc close popup", "zh_CN": "WASD / 方向键移动  |  E 互动  |  Esc 关闭弹窗"},
	"meta.restaurant.world_prompt_idle": {"en": "Walk to the menu board, prep pass, service counter, summary nook, or exit door.", "zh_CN": "走到菜单板、备菜台、前台、总结角或出口门旁。"},
	"meta.restaurant.world_prompt_interact": {"en": "Press E to check {value}.", "zh_CN": "按 E 查看 {value}。"},
	"meta.restaurant.world_prompt_popup": {"en": "Station panel open. Review the room flow or press Esc to close it.", "zh_CN": "站点面板已打开。查看信息，或按 Esc 关闭。"},
	"meta.restaurant.station_menu": {"en": "Menu Board", "zh_CN": "菜单板"},
	"meta.restaurant.station_prep": {"en": "Prep Station", "zh_CN": "备菜台"},
	"meta.restaurant.station_service": {"en": "Service Counter", "zh_CN": "营业前台"},
	"meta.restaurant.station_results": {"en": "Service Notes", "zh_CN": "营业记录角"},
	"meta.restaurant.station_exit": {"en": "Exit Door", "zh_CN": "出口门"},
	"meta.restaurant.leave": {"en": "Step Outside", "zh_CN": "走出餐馆"},
	"meta.restaurant.popup_menu_title": {"en": "Menu Board", "zh_CN": "菜单板"},
	"meta.restaurant.popup_menu_subtitle": {"en": "Pick dishes for the room before you open the floor.", "zh_CN": "在开门前先决定今天要推的菜。"},
	"meta.restaurant.popup_prep_title": {"en": "Prep Station", "zh_CN": "备菜台"},
	"meta.restaurant.popup_prep_subtitle": {"en": "Check pantry stock and make sure the kitchen can support your plan.", "zh_CN": "查看库存，确认后厨撑得住今天的菜单。"},
	"meta.restaurant.popup_service_title": {"en": "Service Counter", "zh_CN": "营业前台"},
	"meta.restaurant.popup_service_subtitle": {"en": "Open the room once the menu, pantry, and action budget are ready.", "zh_CN": "菜单、库存和行动预算都准备好后，再正式营业。"},
	"meta.restaurant.popup_result_title": {"en": "Service Notes", "zh_CN": "营业记录"},
	"meta.restaurant.ingredients_title": {"en": "Available Ingredients", "zh_CN": "可用食材"},
	"meta.restaurant.recipes_title": {"en": "Unlocked Recipes", "zh_CN": "已解锁食谱"},
	"meta.restaurant.menu_title": {"en": "Today's Menu", "zh_CN": "今日菜单"},
	"meta.restaurant.menu_hint": {"en": "Selected {count}/{max} dishes.", "zh_CN": "当前已选 {count}/{max} 道菜。"},
	"meta.restaurant.menu_hint_tooltip": {"en": "Choose up to three dishes. Planned menus usually earn more than selling ingredients raw.", "zh_CN": "最多选择 3 道菜。规划好的菜单通常比原料直卖更赚钱。"},
	"meta.restaurant.menu_empty": {"en": "No dishes selected yet.", "zh_CN": "还没有选择今天的菜单。"},
	"meta.restaurant.recipe_card_night": {"en": "Night loot: {value}", "zh_CN": "夜间掉落：{value}"},
	"meta.restaurant.recipe_tooltip.stats": {"en": "Base ${price} · Prep {prep} · Ready for {servings} servings", "zh_CN": "基础价格 ${price} · 备菜 {prep} · 可做 {servings} 份"},
	"meta.restaurant.recipe_tooltip.ingredients": {"en": "Ingredients: {value}", "zh_CN": "食材：{value}"},
	"meta.restaurant.recipe_tooltip.night": {"en": "Night loot used: {value}", "zh_CN": "用到的夜间掉落：{value}"},
	"meta.restaurant.recipe_tooltip.unlock": {"en": "Unlock path: {value}", "zh_CN": "解锁路径：{value}"},
	"meta.restaurant.open_service": {"en": "Open Service", "zh_CN": "开始营业"},
	"meta.restaurant.open_service_cost": {"en": "Open Service ({value} actions)", "zh_CN": "开始营业（消耗 {value} 行动）"},
	"meta.restaurant.service_tooltip": {"en": "Service uses {value} daytime action(s) and pushes the day toward night.", "zh_CN": "营业会消耗 {value} 次白天行动，并推动时间接近夜晚。"},
	"meta.restaurant.service_closed_today": {"en": "Service Closed For Today", "zh_CN": "今日营业已结束"},
	"meta.restaurant.clear_menu": {"en": "Clear Menu", "zh_CN": "清空菜单"},
	"meta.restaurant.summary_idle_title": {"en": "No Service Yet", "zh_CN": "尚未营业"},
	"meta.restaurant.summary_idle": {"en": "Choose a menu and open for service to generate gold and feedback.", "zh_CN": "先选择菜单再开门营业，以获取金币和反馈。"},
	"meta.restaurant.summary_title": {"en": "Day {day} Service · {headline}", "zh_CN": "第 {day} 天营业 · {headline}"},
	"meta.restaurant.summary_body": {"en": "Served {served}/{expected} guests · Revenue ${revenue} (tips ${tips}) · Satisfaction {satisfaction}% · Reputation {rep}\nIngredients used: {ingredients}", "zh_CN": "接待顾客 {served}/{expected} 位 · 收入 ${revenue}（小费 ${tips}）· 满意度 {satisfaction}% · 口碑 {rep}\n消耗食材：{ingredients}"},
	"meta.restaurant.summary_feedback": {"en": "Feedback: {value}", "zh_CN": "反馈：{value}"},
	"meta.restaurant.summary_sold_today": {"en": "Sold today: {value}", "zh_CN": "今日售出：{value}"},
	"meta.restaurant.summary_sold_lifetime": {"en": "Lifetime sales: {value}", "zh_CN": "累计售出：{value}"},
	"meta.restaurant.feedback.variety_good": {"en": "Guests liked the menu variety.", "zh_CN": "顾客喜欢菜单的多样性。"},
	"meta.restaurant.feedback.price_good": {"en": "Pricing felt fair for the neighborhood.", "zh_CN": "定价对附近顾客来说比较合适。"},
	"meta.restaurant.feedback.price_high": {"en": "Some guests hesitated at the prices.", "zh_CN": "部分顾客觉得价格偏高。"},
	"meta.restaurant.feedback.capacity_strained": {"en": "The kitchen hit its limit during the rush.", "zh_CN": "高峰时段后厨压力偏大。"},
	"meta.restaurant.feedback.capacity_steady": {"en": "Service pacing stayed under control.", "zh_CN": "整体出餐节奏比较稳定。"},
	"meta.restaurant.feedback.satisfaction_high": {"en": "Guests left with strong impressions.", "zh_CN": "顾客离开时评价很好。"},
	"meta.restaurant.feedback.satisfaction_low": {"en": "The shift landed below expectations.", "zh_CN": "这轮营业没有达到顾客预期。"},
	"meta.restaurant.feedback.synergy_used": {"en": "Night materials gave the menu a distinctive edge.", "zh_CN": "夜间材料让菜单更有记忆点。"},
	"meta.restaurant.status_invalid": {"en": "That recipe is unavailable.", "zh_CN": "该食谱当前不可用。"},
	"meta.restaurant.status_locked": {"en": "{value} is still locked.", "zh_CN": "{value} 仍未解锁。"},
	"meta.restaurant.status_menu_full": {"en": "Only {value} dishes can be served in one daytime shift.", "zh_CN": "一次白天营业最多只能上架 {value} 道菜。"},
	"meta.restaurant.status_menu_removed": {"en": "Removed {value} from today's menu.", "zh_CN": "已将 {value} 从今日菜单中移除。"},
	"meta.restaurant.status_menu_added": {"en": "Added {value} to today's menu.", "zh_CN": "已将 {value} 加入今日菜单。"},
	"meta.restaurant.status_menu_cleared": {"en": "Cleared the menu board.", "zh_CN": "已清空菜单板。"},
	"meta.restaurant.status_need_menu": {"en": "Pick at least one dish before opening service.", "zh_CN": "开门营业前至少要选择一道菜。"},
	"meta.restaurant.status_need_stock": {"en": "The pantry cannot support that menu yet.", "zh_CN": "当前库存还撑不起这份菜单。"},
	"meta.restaurant.status_need_time": {"en": "Not enough daytime actions remain for a full service.", "zh_CN": "剩余白天行动不足，无法完整营业。"},
	"meta.restaurant.status_closed_today": {"en": "Today's lunch service is already complete.", "zh_CN": "今天的午市已经结束。"},
	"meta.restaurant.status_service_complete": {"en": "Service closed with ${gold} revenue and {rep} reputation.", "zh_CN": "本次营业收入 ${gold}，口碑变化 {rep}。"},
	"meta.restaurant.status_new_unlock": {"en": "New recipe unlocked: {value}", "zh_CN": "新食谱已解锁：{value}"},
	"meta.summary.title": {"en": "Night Return", "zh_CN": "夜归结算"},
	"meta.summary.subtitle": {"en": "Apply rewards and roll into the next day.", "zh_CN": "结算奖励并推进到下一天。"},
	"meta.summary.continue": {"en": "Start Next Day", "zh_CN": "开始下一天"},
	"meta.summary.outcome_completed": {"en": "Night complete. Day {day} is closing; Day {next_day} awaits.", "zh_CN": "夜晚完成。第 {day} 天结束，第 {next_day} 天即将开始。"},
	"meta.summary.outcome_abandoned": {"en": "Night abandoned. Partial rewards secured before Day {next_day}.", "zh_CN": "夜晚中止。已带回部分奖励，随后进入第 {next_day} 天。"},
	"meta.summary.run": {"en": "Run: {time} survived · {kills} kills · Seed {seed}", "zh_CN": "战斗：生存 {time} · 击杀 {kills} · 种子 {seed}"},
	"meta.summary.loot": {"en": "Loot gained:\n{value}\nNight bonus consumed: {bonus}", "zh_CN": "带回战利品：\n{value}\n已消耗夜间加成：{bonus}"},
	"meta.summary.gold_line": {"en": "Gold: +{value}", "zh_CN": "金币：+{value}"},
	"meta.summary.loot_line": {"en": "{category}: {value}", "zh_CN": "{category}：{value}"},
	"meta.summary.category.common_materials": {"en": "Common materials", "zh_CN": "常见材料"},
	"meta.summary.category.rare_monster_ingredients": {"en": "Rare monster ingredients", "zh_CN": "稀有怪物食材"},
	"meta.summary.category.special_seeds_spores": {"en": "Special seeds / spores", "zh_CN": "特殊种子 / 孢子"},
	"meta.summary.category.unlock_tokens": {"en": "Unlock tokens / fragments", "zh_CN": "解锁代币 / 蓝图碎片"},
	"meta.summary.unlocks": {"en": "New unlocks: {value}", "zh_CN": "新解锁：{value}"},
	"meta.summary.progress": {"en": "Unlock progress:\n{value}", "zh_CN": "解锁进度：\n{value}"},
	"meta.summary.progress_partial": {"en": "{name}: {current}/{required} ({requirements})", "zh_CN": "{name}：{current}/{required}（{requirements}）"},
	"meta.summary.progress_complete": {"en": "{name}: Complete, now available as {target}.", "zh_CN": "{name}：已完成，现已解锁 {target}。"},
	"meta.summary.condition": {"en": "Condition: {value}", "zh_CN": "状态：{value}"},
	"meta.summary.condition_none": {"en": "Stable. No fatigue or injury applied.", "zh_CN": "状态稳定，没有疲劳或伤势惩罚。"},
	"meta.summary.condition_fatigue": {"en": "Fatigue: -{value} stamina next day ({next} available).", "zh_CN": "疲劳：下一天 -{value} 体力（可用 {next}）。"},
	"meta.summary.condition_injury": {"en": "Injury: -{value} stamina next day ({next} available).", "zh_CN": "伤势：下一天 -{value} 体力（可用 {next}）。"},
	"meta.summary.inventory": {"en": "Updated inventory: {value}", "zh_CN": "更新后的库存：{value}"},
	"meta.bonus.gold": {"en": "+{value} gold", "zh_CN": "+{value} 金币"},
	"meta.bonus.material": {"en": "+{value} material reward", "zh_CN": "+{value} 材料奖励"},
	"pause.title": {"en": "Paused", "zh_CN": "游戏暂停"},
	"pause.hint": {"en": "Resume with Esc", "zh_CN": "按 Esc 继续游戏"},
	"pause.resume": {"en": "Resume", "zh_CN": "继续游戏"},
	"pause.settings": {"en": "Settings", "zh_CN": "设置"},
	"pause.main_menu": {"en": "Main Menu", "zh_CN": "返回主菜单"},
	"pause.quit": {"en": "Quit Game", "zh_CN": "退出游戏"},

	"run_setup.title": {"en": "Run Setup", "zh_CN": "开局配置"},
	"run_setup.hint": {"en": "Pick character and map to unlock contracts.", "zh_CN": "先选择角色与地图，再配置契约。"},
	"run_setup.step.character": {"en": "Character", "zh_CN": "角色"},
	"run_setup.step.map": {"en": "Map", "zh_CN": "地图"},
	"run_setup.step.contracts": {"en": "Contracts", "zh_CN": "契约"},
	"run_setup.step.status": {"en": "{current}/3 · {name}", "zh_CN": "第 {current}/3 步 · {name}"},
	"run_setup.content.character.title": {"en": "Step 1 - Character", "zh_CN": "步骤 1 - 角色"},
	"run_setup.content.character.subtitle": {"en": "Choose an operator for this run.", "zh_CN": "选择本局作战角色。"},
	"run_setup.content.map.title": {"en": "Step 2 - Map", "zh_CN": "步骤 2 - 地图"},
	"run_setup.content.map.subtitle": {"en": "Pick a map with your preferred risk profile.", "zh_CN": "选择与你风险偏好匹配的地图。"},
	"run_setup.content.contract.title": {"en": "Step 3 - Contracts", "zh_CN": "步骤 3 - 契约"},
	"run_setup.content.contract.subtitle": {"en": "Select up to {max} contracts. Click again to remove.", "zh_CN": "最多选择 {max} 个契约，再次点击可取消。"},
	"run_setup.action.select": {"en": "Select", "zh_CN": "选择"},
	"run_setup.action.selected": {"en": "Selected", "zh_CN": "已选择"},
	"run_setup.action.add": {"en": "Add", "zh_CN": "添加"},
	"run_setup.action.remove": {"en": "Remove", "zh_CN": "移除"},
	"run_setup.nav.back": {"en": "Back", "zh_CN": "返回"},
	"run_setup.nav.next": {"en": "Next", "zh_CN": "下一步"},
	"run_setup.start": {"en": "Start Run", "zh_CN": "开始本局"},
	"run_setup.summary.character": {"en": "Character: {value}", "zh_CN": "角色：{value}"},
	"run_setup.summary.map": {"en": "Map: {value}", "zh_CN": "地图：{value}"},
	"run_setup.summary.contracts": {"en": "Contracts: {value}", "zh_CN": "契约：{value}"},
	"run_setup.none": {"en": "None", "zh_CN": "无"},
	"run_setup.locked": {"en": "[Locked] {value}", "zh_CN": "[未解锁] {value}"},
	"run_setup.tooltip.hazard": {"en": "Hazard: {value}", "zh_CN": "灾害：{value}"},
	"run_setup.tooltip.unlock": {"en": "Unlock: {value}", "zh_CN": "解锁条件：{value}"},
	"run_setup.tooltip.stats": {"en": "Stats: {value}", "zh_CN": "属性：{value}"},
	"run_setup.tooltip.status": {"en": "Status: {value}", "zh_CN": "状态：{value}"},
	"run_setup.tooltip.status_selected": {"en": "Selected", "zh_CN": "已选择"},
	"run_setup.tooltip.status_optional": {"en": "Optional", "zh_CN": "可选"},
	"run_setup.affects": {"en": "Affects: {value}", "zh_CN": "影响：{value}"},
	"run_setup.mult.xp": {"en": "XP", "zh_CN": "经验"},
	"run_setup.mult.rarity": {"en": "RARITY", "zh_CN": "稀有"},
	"run_setup.mult.drop": {"en": "DROP", "zh_CN": "掉落"},
	"run_setup.mult.meta": {"en": "META", "zh_CN": "元货币"},
	"run_setup.summary_title": {"en": "Run Summary", "zh_CN": "本局摘要"},
	"run_setup.mult_title": {"en": "Multipliers", "zh_CN": "倍率预览"},
	"run_setup.tag_weights_title": {"en": "Tag Weights (Top 5)", "zh_CN": "标签权重（前 5）"},
	"run_setup.unknown_requirement": {"en": "Unknown requirement", "zh_CN": "未知解锁条件"},
	"run_setup.stat.move": {"en": "Move", "zh_CN": "移速"},
	"run_setup.stat.noise": {"en": "Noise", "zh_CN": "噪声"},
	"run_setup.stat.damage": {"en": "Damage", "zh_CN": "伤害"},

	"hud.noise": {"en": "NOISE", "zh_CN": "噪声"},
	"hud.survival": {"en": "Survival", "zh_CN": "生存"},
	"hud.build_snapshot": {"en": "Build Snapshot", "zh_CN": "构筑快照"},
	"hud.skill_sonar": {"en": "Q Flash Grenade", "zh_CN": "Q 闪光弹"},
	"hud.skill_dash": {"en": "Space Dash", "zh_CN": "空格 冲刺"},
	"hud.badge.level": {"en": "Lvl", "zh_CN": "等级"},
	"hud.badge.kills": {"en": "Kills", "zh_CN": "击杀"},
	"hud.badge.time": {"en": "Time", "zh_CN": "时间"},
	"hud.hp": {"en": "HP {current}/{max}", "zh_CN": "生命 {current}/{max}"},
	"hud.enemy_info": {"en": "Enemies {enemy} | Revealed {revealed}", "zh_CN": "敌人 {enemy} | 显形 {revealed}"},
	"hud.streak": {"en": "Kill Streak", "zh_CN": "连杀势能"},
	"hud.streak_tier": {"en": "T{tier} Momentum", "zh_CN": "势能 {tier} 阶"},
	"hud.streak_chain": {"en": "{count} chain · {sec}s left", "zh_CN": "连杀 {count} · 剩余 {sec} 秒"},
	"hud.streak_idle": {"en": "Chain kills to build momentum", "zh_CN": "连续击杀可叠加势能"},
	"hud.tier": {"en": "TIER {tier} · {name}", "zh_CN": "威胁 {tier} 阶 · {name}"},
	"hud.threat": {"en": "THREAT TIER {tier}", "zh_CN": "威胁等级 {tier}"},
	"hud.threshold.max": {"en": "Maximum threat tier reached", "zh_CN": "已到最高威胁等级"},
	"hud.threshold.next": {"en": "Next tier at {value} ({pct}%)", "zh_CN": "下一档阈值 {value}（{pct}%）"},
	"hud.threshold.stable": {"en": "Tier stable ({pct}%)", "zh_CN": "当前档位稳定（{pct}%）"},
	"hud.weapon": {"en": "Weapon: {value}", "zh_CN": "武器：{value}"},
	"hud.key_tags": {"en": "Key tags: {value}", "zh_CN": "核心标签：{value}"},
	"hud.cooldown": {"en": "({sec}s)", "zh_CN": "（{sec}秒）"},
	"hud.ready": {"en": "Ready", "zh_CN": "就绪"},
	"hud.ping_contacts": {"en": "Flare: {count} silhouettes", "zh_CN": "照明弹显形：{count} 个目标"},
	"hud.contract_dash_disabled": {"en": "Dash Disabled", "zh_CN": "冲刺已禁用"},
	"hud.contract_dash_disabled_detail": {"en": "Disabled by Contract", "zh_CN": "受契约影响禁用"},

	"upgrade.subtitle": {"en": "Pick one. Build direction updates on the right.", "zh_CN": "选择其一。右侧将实时更新构筑方向。"},
	"upgrade.input_hint": {"en": "Left/Right focus  Enter select  Up/Down scroll build", "zh_CN": "左右切换  回车选择  上下滚动构筑"},
	"upgrade.title": {"en": "Signal Upgrade", "zh_CN": "信号升级"},
	"upgrade.no_description": {"en": "No description yet", "zh_CN": "暂无描述"},
	"upgrade.no_key_stats": {"en": "No key stats", "zh_CN": "暂无关键数值"},
	"upgrade.unknown": {"en": "Unknown Upgrade", "zh_CN": "未知升级"},
	"upgrade.target": {"en": "({type} {value})", "zh_CN": "（{type}：{value}）"},

	"build.current_weapon": {"en": "Current Weapon: {value}", "zh_CN": "当前武器：{value}"},
	"build.title": {"en": "Build Snapshot", "zh_CN": "构筑快照"},
	"build.top_tags": {"en": "Top Tags", "zh_CN": "核心标签"},
	"build.key_passives": {"en": "Key Passives", "zh_CN": "关键被动"},
	"build.run_modifiers": {"en": "Run Modifiers", "zh_CN": "本局倍率"},
	"build.none": {"en": "-", "zh_CN": "-"},
	"build.more": {"en": "+{count} more", "zh_CN": "另有 {count} 项"},
	"build.modifiers": {"en": "XP x{xp}\nRARITY x{rarity}\nDROP x{drop}\nMETA x{meta}", "zh_CN": "经验 x{xp}\n稀有 x{rarity}\n掉落 x{drop}\n元货币 x{meta}"},

	"summary.title": {"en": "Run Summary", "zh_CN": "本局结算"},
	"summary.subtitle": {"en": "Build recap and progression snapshot", "zh_CN": "构筑复盘与进度快照"},
	"summary.run_stats": {"en": "Run Stats", "zh_CN": "战局数据"},
	"summary.survival_unit": {"en": "Survival", "zh_CN": "生存"},
	"summary.kills_unit": {"en": "Kills", "zh_CN": "击杀"},
	"summary.build_recap": {"en": "Build Recap", "zh_CN": "构筑复盘"},
	"summary.top_tags_title": {"en": "Top tags", "zh_CN": "核心标签"},
	"summary.progress_title": {"en": "Progress", "zh_CN": "进度"},
	"summary.seed": {"en": "Seed {value}", "zh_CN": "种子 {value}"},
	"summary.copy": {"en": "Copy", "zh_CN": "复制"},
	"summary.copy_done": {"en": "Copied", "zh_CN": "已复制"},
	"summary.badge.level": {"en": "Level", "zh_CN": "等级"},
	"summary.badge.noise": {"en": "Noise Peak", "zh_CN": "噪声峰值"},
	"summary.badge.enemies": {"en": "Enemies", "zh_CN": "敌人"},
	"summary.badge.revealed": {"en": "Revealed", "zh_CN": "显形"},
	"summary.boss": {"en": "Boss progress: {value}", "zh_CN": "Boss 进度：{value}"},
	"summary.weapon": {"en": "Weapon: {value}", "zh_CN": "武器：{value}"},
	"summary.chosen": {"en": "Chosen upgrades:\n{value}", "zh_CN": "已选升级：\n{value}"},
	"summary.map_contracts": {"en": "Map: {map}\nContracts: {contracts}", "zh_CN": "地图：{map}\n契约：{contracts}"},
	"summary.contracts_none": {"en": "None", "zh_CN": "无"},
	"summary.progress_all": {"en": "All characters unlocked", "zh_CN": "全部角色已解锁"},
	"summary.progress_none": {"en": "No pending target", "zh_CN": "暂无待完成目标"},
	"summary.progress_next": {"en": "Next target: {value}", "zh_CN": "下一目标：{value}"},
	"summary.progress_detail": {"en": "{display}\nProgress: {text}", "zh_CN": "{display}\n进度：{text}"},
	"summary.new_unlocks": {"en": "New unlocks: {value}", "zh_CN": "新解锁：{value}"},
	"summary.new_unlocks_none": {"en": "New unlocks: -", "zh_CN": "新解锁：-"},
	"summary.more_items": {"en": "• +{count} more", "zh_CN": "• 另有 {count} 项"},
	"summary.meta_currency": {"en": "META CURRENCY: {total} (x{mult})", "zh_CN": "元货币：{total}（x{mult}）"},
	"summary.retry": {"en": "Retry Run", "zh_CN": "再来一局"},
	"summary.menu": {"en": "Back to Menu", "zh_CN": "返回主菜单"},
	"summary.input_hint": {"en": "Enter: Retry   Esc: Back to Menu", "zh_CN": "回车：重开   Esc：回主菜单"},
	"summary.mult": {"en": "XP x{xp}\nRARITY x{rarity}\nDROP x{drop}\nMETA x{meta}", "zh_CN": "经验 x{xp}\n稀有 x{rarity}\n掉落 x{drop}\n元货币 x{meta}"},

	"sys.profile_coming": {"en": "Profile page is coming in a follow-up update.", "zh_CN": "档案页面将在后续更新开放。"},
	"sys.settings_coming": {"en": "Settings page is coming in a follow-up update.", "zh_CN": "设置页面将在后续更新开放。"},
	"sys.upgrade_confirm": {"en": "Upgrade selection must be confirmed to continue.", "zh_CN": "必须确认升级后才能继续。"},
	"sys.boss_eliminated": {"en": "Boss eliminated. Signal field stabilizing.", "zh_CN": "Boss 已击破，信号场正在稳定。"},
	"sys.character_locked": {"en": "Character is locked.", "zh_CN": "角色尚未解锁。"},
	"sys.map_unavailable": {"en": "Map data unavailable.", "zh_CN": "地图数据不可用。"},
	"sys.debug_unlock_all": {"en": "Debug: all characters unlocked.", "zh_CN": "调试：已解锁全部角色。"},
	"sys.sonar_ping": {"en": "Flare exposed: {count} contacts", "zh_CN": "照明弹显形：{count} 个目标"},
	"sys.kill_streak_reward": {"en": "Kill streak x{streak}! Momentum T{tier}: supply surge + flare charge.", "zh_CN": "连杀 x{streak}！势能 {tier} 阶：补给爆发 + 照明充能。"},
	"sys.data_reload_failed": {"en": "Data reload failed.", "zh_CN": "数据重载失败。"},
	"sys.data_reloaded": {"en": "Data reloaded (fog/flare/noise/maps).", "zh_CN": "数据已重载（迷雾/照明弹/噪声/地图）。"},
	"sys.hazard_shift": {"en": "Hazard shift", "zh_CN": "灾害切换"},
	"sys.event_triggered": {"en": "{name} triggered", "zh_CN": "{name} 已触发"},
	"sys.unlocked_list": {"en": "Unlocked:\n{value}", "zh_CN": "已解锁：\n{value}"},
	"profile.progress.reached": {"en": "Reached", "zh_CN": "已达成"},
	"profile.progress.not_reached": {"en": "Not reached", "zh_CN": "未达成"},
	"profile.progress.na": {"en": "N/A", "zh_CN": "无"},
	"upgrade.affects_none": {"en": "Affects: -", "zh_CN": "影响：-"},
	"upgrade.affects": {"en": "Affects: {value}", "zh_CN": "影响：{value}"},
	"upgrade.target.global": {"en": "Target: Global", "zh_CN": "目标：全局"},
	"upgrade.target.weapon": {"en": "Target: {value}", "zh_CN": "目标：{value}"},
	"upgrade.target.tag": {"en": "Target: Tag {value}", "zh_CN": "目标：标签 {value}"},

	"telegraph.pursuer_inbound": {"en": "Pursuer inbound! ({count}) next ETA {eta}s", "zh_CN": "追猎者来袭！({count}) 下次预计 {eta} 秒"},
	"telegraph.hazard_warning": {"en": "Hazard shift incoming.", "zh_CN": "灾害切换即将发生。"},
	"telegraph.hazard_active": {"en": "{text} (ACTIVE)", "zh_CN": "{text}（进行中）"},
	"telegraph.boss_detected": {"en": "Boss detected.", "zh_CN": "检测到 Boss。"},
	"telegraph.boss_phase": {"en": "Boss phase shift.", "zh_CN": "Boss 阶段切换。"},
	"telegraph.boss_attack": {"en": "High-energy attack telegraphed.", "zh_CN": "高能攻击预警。"},
	"telegraph.boss_echoes": {"en": "False echoes deployed: {count}", "zh_CN": "伪装回声已部署：{count}"},
	"telegraph.boss_true_form": {"en": "True core exposed. Push damage now.", "zh_CN": "真核心暴露，立刻集火。"}
}

const DATA_TEXT_BY_ID := {
	"silent": {"name": {"en": "Silent", "zh_CN": "静默"}},
	"alert": {"name": {"en": "Alert", "zh_CN": "警戒"}},
	"exposed": {"name": {"en": "Exposed", "zh_CN": "暴露"}},

	"diver": {
		"display_name": {"en": "Silent Diver", "zh_CN": "静潜者"},
		"short_desc": {"en": "Low-noise flare specialist.", "zh_CN": "低噪声照明弹专家。"},
		"passive_summary": {"en": "Reduced noise gain, longer reveal windows.", "zh_CN": "降低噪声获取，延长显形窗口。"},
		"unlock_display": {"en": "Survive for 7:00 in a single run.", "zh_CN": "在单局中生存 7:00。"}
	},
	"arc_tech": {
		"display_name": {"en": "Arc Technician", "zh_CN": "电弧技师"},
		"short_desc": {"en": "Unstable conductor tuned for chain reactions.", "zh_CN": "为连锁反应调校的不稳定导体。"},
		"passive_summary": {"en": "More crit potential, slightly louder output.", "zh_CN": "更高暴击潜力，但噪声更大。"},
		"unlock_display": {"en": "Accumulate 800 total kills.", "zh_CN": "累计击杀 800 名敌人。"}
	},
	"lancer": {
		"display_name": {"en": "Trench Lancer", "zh_CN": "海沟枪骑兵"},
		"short_desc": {"en": "Forward assault frame optimized for puncture runs.", "zh_CN": "为突进穿刺优化的前线机体。"},
		"passive_summary": {"en": "Faster dash cycle and deeper penetration.", "zh_CN": "更快冲刺循环与更深穿透。"},
		"unlock_display": {"en": "Reach Noise 60 (Exposed) in a run.", "zh_CN": "在单局中达到噪声 60（暴露）。"}
	},
	"drone_handler": {
		"display_name": {"en": "Drone Handler", "zh_CN": "无人机操控者"},
		"short_desc": {"en": "Tactical coordinator for autonomous platforms.", "zh_CN": "自主平台战术协调者。"},
		"passive_summary": {"en": "Higher noise, stronger summon focus.", "zh_CN": "噪声更高，召唤方向更强。"},
		"unlock_display": {"en": "Collect 250 pickups.", "zh_CN": "累计拾取 250 个掉落物。"}
	},
	"scavenger": {
		"display_name": {"en": "Crypt Scavenger", "zh_CN": "地牢拾荒者"},
		"short_desc": {"en": "Resource diver who turns scraps into growth.", "zh_CN": "把残骸转化为成长资源的潜行者。"},
		"passive_summary": {"en": "Larger pickup radius and better XP conversion.", "zh_CN": "更大拾取半径与更高经验转化。"},
		"unlock_display": {"en": "Survive for 10:00 in a single run.", "zh_CN": "在单局中生存 10:00。"}
	},

	"map_trench_lab": {
		"name": {"en": "Trench Lab", "zh_CN": "海沟实验区"},
		"description": {"en": "Ancient dungeon trench threaded with unstable magnetic storms.", "zh_CN": "古老地牢海沟中伴随不稳定磁暴。"},
		"hazard_summary": {"en": "Magnetic storms distort flare reveals and raise noise risk.", "zh_CN": "磁暴会扭曲照明弹显形并提高噪声风险。"},
		"event_summary": {"en": "Supply pods and rift surges create tempo spikes.", "zh_CN": "补给舱与裂隙浪涌会带来节奏尖峰。"}
	},
	"map_black_tide": {
		"name": {"en": "Black Tide", "zh_CN": "黑潮深渊"},
		"description": {"en": "Light-starved abyss plain swept by violent black currents.", "zh_CN": "缺光深渊平原，受狂暴黑潮冲刷。"},
		"hazard_summary": {"en": "Black surge shrinks vision but boosts tempo and rewards.", "zh_CN": "黑潮会压缩视野，但提高节奏与收益。"},
		"event_summary": {"en": "Quiet pockets and surges alternate between risk and payoff.", "zh_CN": "静默区与浪涌交替出现，风险与收益并存。"}
	},

	"hazard_magnetic_interference": {
		"name": {"en": "Magnetic Interference", "zh_CN": "磁干扰风暴"},
		"description": {"en": "Electromagnetic bursts destabilize flare echoes and amplify noise signatures.", "zh_CN": "电磁脉冲会扰乱照明弹回波并放大噪声特征。"},
		"warning_text": {"en": "Magnetic interference incoming", "zh_CN": "磁干扰即将来袭"}
	},
	"hazard_black_tide_surge": {
		"name": {"en": "Black Tide Surge", "zh_CN": "黑潮浪涌"},
		"description": {"en": "A pressure wave compresses visibility while creatures surge forward.", "zh_CN": "压强浪会压缩视野并驱使敌群前冲。"},
		"warning_text": {"en": "Black tide surge rising", "zh_CN": "黑潮浪涌正在抬升"}
	},

	"event_table_trench_lab": {"name": {"en": "Trench Lab Event Table", "zh_CN": "海沟实验区事件表"}},
	"event_table_black_tide": {"name": {"en": "Black Tide Event Table", "zh_CN": "黑潮深渊事件表"}},
	"event_trench_supply_pod": {
		"name": {"en": "Supply Pod", "zh_CN": "补给舱"},
		"description": {"en": "A cache pod surfaces with salvage and XP canisters.", "zh_CN": "缓存补给舱上浮，带来素材与经验罐。"},
		"immediate_message": {"en": "Supply pod recovered", "zh_CN": "补给舱已回收"}
	},
	"event_trench_abyss_rift": {
		"name": {"en": "Abyss Rift", "zh_CN": "深渊裂隙"},
		"description": {"en": "Rift pressure erupts into a dense enemy wave with bonus rewards.", "zh_CN": "裂隙压强爆发，涌出高密敌群并伴随奖励提升。"},
		"immediate_message": {"en": "Abyss rift eruption", "zh_CN": "深渊裂隙喷发"}
	},
	"event_trench_quiet_pocket": {
		"name": {"en": "Quiet Pocket", "zh_CN": "静默空腔"},
		"description": {"en": "A low-noise corridor opens briefly, improving control.", "zh_CN": "短暂开启低噪声通道，提升战场控制。"},
		"immediate_message": {"en": "Quiet pocket detected", "zh_CN": "检测到静默空腔"}
	},
	"event_tide_supply_pod": {
		"name": {"en": "Supply Pod", "zh_CN": "补给舱"},
		"description": {"en": "A battered pod emerges from the dark current.", "zh_CN": "受损补给舱从黑潮中浮现。"},
		"immediate_message": {"en": "Supply pod stabilized", "zh_CN": "补给舱已稳定"}
	},
	"event_tide_abyss_rift": {
		"name": {"en": "Abyss Rift", "zh_CN": "深渊裂隙"},
		"description": {"en": "Black current tears open and floods the arena with threats.", "zh_CN": "黑潮撕裂空间，战场威胁激增。"},
		"immediate_message": {"en": "Black rift surge", "zh_CN": "黑潮裂隙浪涌"}
	},
	"event_tide_quiet_pocket": {
		"name": {"en": "Quiet Pocket", "zh_CN": "静默空腔"},
		"description": {"en": "A temporary calm zone restores flare clarity.", "zh_CN": "临时平静区可恢复照明弹清晰度。"},
		"immediate_message": {"en": "Quiet pocket formed", "zh_CN": "静默空腔形成"}
	},

	"contract_small_vision": {"name": {"en": "Narrow Aperture", "zh_CN": "狭缝视界"}, "description": {"en": "Fog radius reduced by 30%.", "zh_CN": "迷雾半径降低 30%。"}},
	"contract_loud_world": {"name": {"en": "Loud World", "zh_CN": "喧响世界"}, "description": {"en": "Noise gain increased by 25%.", "zh_CN": "噪声获取提高 25%。"}},
	"contract_elite_rush": {"name": {"en": "Elite Rush", "zh_CN": "精英狂潮"}, "description": {"en": "Elite spawn chance increased.", "zh_CN": "精英刷新概率提高。"}},
	"contract_no_dash": {"name": {"en": "No Dash", "zh_CN": "禁用冲刺"}, "description": {"en": "Dash is disabled.", "zh_CN": "冲刺被禁用。"}},
	"contract_black_tide_often": {"name": {"en": "Frequent Black Tide", "zh_CN": "高频黑潮"}, "description": {"en": "Hazard cycles speed up.", "zh_CN": "灾害循环加速。"}},
	"contract_sonar_fuzzy": {"name": {"en": "Flare Distortion", "zh_CN": "照明弹失真"}, "description": {"en": "Flare reveal duration reduced by 20%.", "zh_CN": "照明弹显形时长降低 20%。"}},
	"contract_pursuer_hunt": {"name": {"en": "Pursuer Hunt", "zh_CN": "追猎协议"}, "description": {"en": "Pursuers spawn more often but drop better loot.", "zh_CN": "追猎者刷新更频繁，但掉落更好。"}},
	"contract_fast_enemies": {"name": {"en": "Fast Enemies", "zh_CN": "疾速敌群"}, "description": {"en": "Enemy speed and spawn rate increased.", "zh_CN": "敌人移速与刷新速率提高。"}},
	"contract_fragile_player": {"name": {"en": "Fragile Hull", "zh_CN": "脆弱船体"}, "description": {"en": "Player max HP reduced by 15%.", "zh_CN": "玩家最大生命降低 15%。"}},
	"contract_rich_pickups": {"name": {"en": "Rich Pickups", "zh_CN": "丰饶拾取"}, "description": {"en": "More drops, but spawn pressure increases.", "zh_CN": "掉落更多，但刷怪压力提高。"}},
	"contract_silent_bonus": {"name": {"en": "Silent Edge", "zh_CN": "静默刃"}, "description": {"en": "Low-noise damage boosted but exposed penalties increase.", "zh_CN": "低噪伤害提升，但暴露惩罚加重。"}},
	"contract_event_storm": {"name": {"en": "Event Storm", "zh_CN": "事件风暴"}, "description": {"en": "Events trigger more frequently.", "zh_CN": "事件触发更加频繁。"}},

	"needle_rifle": {"name": {"en": "Needle Rifle", "zh_CN": "针刺步枪"}, "description": {"en": "Mid-speed puncture rifle tuned for trench lanes.", "zh_CN": "为海沟战线调校的中速穿刺步枪。"}},
	"burst_smg": {"name": {"en": "Burst SMG", "zh_CN": "爆发冲锋枪"}, "description": {"en": "High-rate muzzle storm with heavy acoustic footprint.", "zh_CN": "高射速火力风暴，声学暴露较高。"}},
	"silence_dart": {"name": {"en": "Silence Dart", "zh_CN": "静默飞镖"}, "description": {"en": "Low-signature dart that extends flare reveal windows.", "zh_CN": "低特征飞镖，可延长照明弹显形窗口。"}},
	"shock_pulse": {"name": {"en": "Shock Pulse", "zh_CN": "震荡脉冲"}, "description": {"en": "Near-field ring pulse for close swarm clearing.", "zh_CN": "近场环形脉冲，适合清理贴身敌群。"}},
	"abyss_mine": {"name": {"en": "Abyss Mine", "zh_CN": "深渊地雷"}, "description": {"en": "Timed abyss charge that detonates on proximity.", "zh_CN": "延时深渊炸弹，接近即爆。"}},
	"tether_beam": {"name": {"en": "Tether Beam", "zh_CN": "束缚光束"}, "description": {"en": "Locks one target with continuous control damage.", "zh_CN": "锁定单体目标并持续施加控制伤害。"}},
	"orbital_drone": {"name": {"en": "Orbital Drone", "zh_CN": "轨道无人机"}, "description": {"en": "Summons an orbiting drone that auto-fires around you.", "zh_CN": "召唤环绕无人机自动射击。"}},
	"sonar_blade": {"name": {"en": "Flare Blade", "zh_CN": "照明刃"}, "description": {"en": "Close-range arc strike that emits amplified flare echoes.", "zh_CN": "近战弧斩并释放强化照明弹回波。"}},
	"flare_lance": {"name": {"en": "Flare Lance", "zh_CN": "炽焰长枪"}, "description": {"en": "High-velocity lance round with bright muzzle burn.", "zh_CN": "高速枪矛弹，具备强烈枪口灼烧效果。"}},
	"night_carbine": {"name": {"en": "Night Carbine", "zh_CN": "夜行卡宾枪"}, "description": {"en": "Stable mid-range carbine tuned for clean burst control.", "zh_CN": "稳定的中距离卡宾枪，适合精准点射控场。"}},
	"pulse_emitter": {"name": {"en": "Pulse Emitter", "zh_CN": "脉冲发射器"}, "description": {"en": "Emits rhythmic control pulses that carve nearby packs.", "zh_CN": "周期释放控制脉冲，切割近身敌群。"}},
	"ion_repeater": {"name": {"en": "Ion Repeater", "zh_CN": "离子连发器"}, "description": {"en": "Fast repeater with ion bursts and high crit cadence.", "zh_CN": "高频离子连发武器，具备高暴击节奏。"}},
	"ember_pike": {"name": {"en": "Ember Pike", "zh_CN": "余烬长戟"}, "description": {"en": "Close pike sweep that spikes tempo at knife distance.", "zh_CN": "近距戟刃横扫，在贴身范围强行提速。"}},
	"frost_shard": {"name": {"en": "Frost Shard", "zh_CN": "寒霜碎晶枪"}, "description": {"en": "Cold shard shots trade raw DPS for safer control windows.", "zh_CN": "寒霜碎晶弹以伤害换取更稳的控场窗口。"}},
	"grav_harpoon": {"name": {"en": "Grav Harpoon", "zh_CN": "引力鱼叉"}, "description": {"en": "Harpoon tether that pins priority threats under pressure.", "zh_CN": "鱼叉牵引可压制高优先级目标。"}},
	"prism_caster": {"name": {"en": "Prism Caster", "zh_CN": "棱镜施放器"}, "description": {"en": "Short-wave prism blast with dense multi-hit spectrum.", "zh_CN": "短波棱镜爆发，提供高密度多段命中。"}},
	"venom_sprayer": {"name": {"en": "Venom Sprayer", "zh_CN": "剧毒喷射器"}, "description": {"en": "Wide toxic spray pattern for close pack suppression.", "zh_CN": "广域毒雾喷射，适合近距压制敌群。"}},
	"echo_revolver": {"name": {"en": "Echo Revolver", "zh_CN": "回响左轮"}, "description": {"en": "Heavy sidearm with sharp crit spikes and echo rebound feel.", "zh_CN": "高爆发重型手炮，暴击峰值高并具回响手感。"}},
	"catacomb_longbow": {"name": {"en": "Catacomb Longbow", "zh_CN": "地窟长弓"}, "description": {"en": "A skeletal longbow that fires heavy piercing bolts through dungeon lanes.", "zh_CN": "骨制长弓可在地牢走廊中射出重型穿刺箭。"}},
	"rune_blunderbuss": {"name": {"en": "Rune Blunderbuss", "zh_CN": "符文喇叭枪"}, "description": {"en": "A rune-loaded scatter gun that blankets short corridors with shard storms.", "zh_CN": "符文散射火枪会在短走廊铺满碎片弹幕。"}},
	"candle_mortar": {"name": {"en": "Candle Mortar", "zh_CN": "烛火迫击炮"}, "description": {"en": "Lobs wick-bombs that burst into burning shrapnel around ignited candles.", "zh_CN": "投掷灯芯炸弹，在烛火周围炸裂成燃烧碎片。"}},
	"crypt_disc": {"name": {"en": "Crypt Disc", "zh_CN": "墓窟圆盘"}, "description": {"en": "A spinning relic disc that ricochets pressure with split burst timing.", "zh_CN": "旋转遗物圆盘以分段爆发节奏持续施压。"}},
	"grave_bell": {"name": {"en": "Grave Bell", "zh_CN": "墓钟"}, "description": {"en": "Rings layered shockwaves that repeatedly mark and punish clustered threats.", "zh_CN": "钟鸣叠加冲击波，可反复显形并惩罚密集敌群。"}},
	"ash_scythe": {"name": {"en": "Ash Scythe", "zh_CN": "余灰镰刃"}, "description": {"en": "Sweeping ash blade with broad arcs that clips whole packs in front of you.", "zh_CN": "余灰镰刃挥出大范围弧斩，能整排扫过前方敌群。"}},
	"wick_thrower": {"name": {"en": "Wick Thrower", "zh_CN": "灯芯投掷器"}, "description": {"en": "Rapid incendiary globes that ignite reveal pulses on every impact.", "zh_CN": "高速燃烧弹每次命中都会触发显形脉冲。"}},
	"reliquary_beam": {"name": {"en": "Reliquary Beam", "zh_CN": "圣匣光束"}, "description": {"en": "Holy relay beam that forks between targets and forces exposure chains.", "zh_CN": "圣匣继电光束可在目标间分叉并形成暴露连锁。"}},
	"gargoyle_drone": {"name": {"en": "Gargoyle Drone", "zh_CN": "石像鬼无人机"}, "description": {"en": "Stone familiars orbit close and unleash split volleys at nearby enemies.", "zh_CN": "石像鬼使魔贴身环绕，并对近敌发射分裂齐射。"}},
	"chain_spike": {"name": {"en": "Chain Spike", "zh_CN": "锁链尖桩枪"}, "description": {"en": "Anchored spike bolts that favor chain propagation across tight formations.", "zh_CN": "锚定尖桩弹更易在密集阵型中扩散连锁伤害。"}},
	"dusk_censer": {"name": {"en": "Dusk Censer", "zh_CN": "昏暮香炉"}, "description": {"en": "Low-noise incense pulses that trade burst damage for reveal control.", "zh_CN": "低噪熏香脉冲以爆发伤害换取更稳定的显形控场。"}},
	"tombbreaker_maul": {"name": {"en": "Tombbreaker Maul", "zh_CN": "裂墓重锤"}, "description": {"en": "Heavy crypt maul that slams enemies backward with crushing arcs.", "zh_CN": "沉重墓锤以碾压弧斩把敌人猛烈击退。"}},
	"spectral_lantern": {"name": {"en": "Spectral Lantern", "zh_CN": "幽魂提灯"}, "description": {"en": "Plants a ghost lantern mine that detonates into revealing spirit fragments.", "zh_CN": "布置幽灯地雷，爆炸后散出可显形的灵体碎片。"}},
	"hex_nailer": {"name": {"en": "Hex Nailer", "zh_CN": "咒钉连射器"}, "description": {"en": "Curses targets with rapid needle bursts that escalate in dense fights.", "zh_CN": "高速咒钉连射会在混战中持续叠压输出。"}},
	"idol_railgun": {"name": {"en": "Idol Railgun", "zh_CN": "神像轨炮"}, "description": {"en": "Relic rail beam that trades cadence for brutal single-target punish.", "zh_CN": "遗物轨炮以射速换取极高单体惩罚能力。"}},
	"briar_whip": {"name": {"en": "Briar Whip", "zh_CN": "荆棘鞭"}, "description": {"en": "A thorn whip that slashes fast and propagates chain pressure nearby.", "zh_CN": "荆棘长鞭高速抽击，并向近邻目标扩散连锁压力。"}},
	"oath_pistol": {"name": {"en": "Oath Pistol", "zh_CN": "誓约手枪"}, "description": {"en": "A disciplined sidearm with compact double-tap bursts and high crit payoff.", "zh_CN": "纪律型手枪以紧凑双连发带来高暴击回报。"}},
	"mirror_shard": {"name": {"en": "Mirror Shard", "zh_CN": "镜晶碎片枪"}, "description": {"en": "Crystalline fan shots refract into splash fragments and reveal ripples.", "zh_CN": "镜晶扇形弹会折射为溅射碎片并触发显形涟漪。"}},
	"sunforged_colossus": {"name": {"en": "Sunforged Colossus", "zh_CN": "日铸巨像炮"}, "description": {"en": "Epic heavy cannon that fires molten rounds with dual-burst collapse shock.", "zh_CN": "史诗重炮发射熔铸弹，双段爆发并触发坍缩震波。"}},
	"eclipse_requiem": {"name": {"en": "Eclipse Requiem", "zh_CN": "蚀月安魂曲"}, "description": {"en": "Epic resonance bell that emits layered void hymns in four diminishing waves.", "zh_CN": "史诗共振圣钟释放四段衰减虚空波。"}},
	"chrono_lance": {"name": {"en": "Chrono Lance", "zh_CN": "时序长枪"}, "description": {"en": "Epic chronal rail that stutters time into triple afterimage pierce shots.", "zh_CN": "史诗时序轨枪将时间抖动成三连残影穿刺。"}},
	"leviathan_bombard": {"name": {"en": "Leviathan Bombard", "zh_CN": "利维坦轰击炮"}, "description": {"en": "Epic abyss mortar that detonates into massive shard storms and echo blasts.", "zh_CN": "史诗深渊迫击炮爆裂为巨量碎片风暴与回响冲击。"}},
	"seraphim_swarm": {"name": {"en": "Seraphim Swarm", "zh_CN": "炽天使蜂群"}, "description": {"en": "Epic sanctified drone choir that sustains crossfire from a rotating halo.", "zh_CN": "史诗圣化无人机圣歌阵列，在光环轨道上持续交叉火力。"}},
	"eclipse_glaive": {"name": {"en": "Eclipse Glaive", "zh_CN": "蚀月战戟"}, "description": {"en": "Epic crescent glaive with sweeping execution arcs and reveal shock recoil.", "zh_CN": "史诗新月战戟拥有处决级横扫弧斩与显形震退。"}},
	"mythic_hailstorm": {"name": {"en": "Mythic Hailstorm", "zh_CN": "神话冰雹风暴"}, "description": {"en": "Epic skyforge repeater that unleashes dense fan volleys of razor hail.", "zh_CN": "史诗天锻连发器释放高密度扇形锋刃弹雨。"}},
	"thunder_sigil": {"name": {"en": "Thunder Sigil", "zh_CN": "雷霆圣印"}, "description": {"en": "Epic arc sigil detonator that repeatedly shocks and repels nearby hordes.", "zh_CN": "史诗雷印引爆器可反复电击并击退近身敌潮。"}},
	"oracle_splitter": {"name": {"en": "Oracle Splitter", "zh_CN": "先知裂分炮"}, "description": {"en": "Epic foresight cannon splitting each shot into delayed omen fragments.", "zh_CN": "史诗预见火炮每发会裂化为延迟预兆碎片。"}},
	"abyssal_monolith": {"name": {"en": "Abyssal Monolith", "zh_CN": "深渊方碑"}, "description": {"en": "Epic monolith beam that drills through one target then chains into many.", "zh_CN": "史诗方碑光束先贯穿主目标，再连锁跳跃多名敌人。"}},
	"starfall_engine": {"name": {"en": "Starfall Engine", "zh_CN": "坠星引擎"}, "description": {"en": "Epic stellar mine core that erupts into radiant meteor shards.", "zh_CN": "史诗星核地雷会爆裂为辉光陨片雨。"}},
	"ragnarok_twinfang": {"name": {"en": "Ragnarok Twinfang", "zh_CN": "诸神黄昏双牙"}, "description": {"en": "Epic twin-barrel relic that stacks brutal crit bursts with recoil shock.", "zh_CN": "史诗双管遗物叠加高暴击连发并附带后坐震击。"}},

	"drifter": {"name": {"en": "Drifter", "zh_CN": "漂游体"}},
	"sprinter": {"name": {"en": "Sprinter", "zh_CN": "疾行体"}},
	"shooter": {"name": {"en": "Shooter", "zh_CN": "射手"}},
	"shielded": {"name": {"en": "Shielded", "zh_CN": "盾卫"}},
	"splitter": {"name": {"en": "Splitter", "zh_CN": "裂解体"}},
	"splitter_shard": {"name": {"en": "Splitter Shard", "zh_CN": "裂片体"}},
	"bloater": {"name": {"en": "Bloater", "zh_CN": "膨胀体"}},
	"summoner": {"name": {"en": "Summoner", "zh_CN": "召唤者"}},
	"lurker": {"name": {"en": "Lurker", "zh_CN": "潜伏者"}},
	"leech": {"name": {"en": "Leech", "zh_CN": "吸能体"}},
	"magnetoid": {"name": {"en": "Magnetoid", "zh_CN": "磁核体"}},
	"pursuer_stalker": {"name": {"en": "Pursuer Stalker", "zh_CN": "追猎潜行者"}},
	"drone_scout": {"name": {"en": "Drone Scout", "zh_CN": "侦察无人机"}},
	"ink_mite": {"name": {"en": "Ink Mite", "zh_CN": "墨蚀螨"}},
	"rusher_eel": {"name": {"en": "Rusher Eel", "zh_CN": "冲锋鳗"}},

	"u_sonar_scope_matrix": {"name": {"en": "Flare Scope Matrix", "zh_CN": "照明弹视域矩阵"}, "description": {"en": "[Tag: flare] Range +12%.", "zh_CN": "[标签：照明弹] 射程 +12%。"}},
	"u_echo_stabilizer": {"name": {"en": "Echo Stabilizer", "zh_CN": "回波稳定器"}, "description": {"en": "Flare reveal duration +14%.", "zh_CN": "照明弹显形时长 +14%。"}},
	"u_exposed_breaker": {"name": {"en": "Exposed Breaker", "zh_CN": "暴露粉碎者"}, "description": {"en": "Damage to revealed enemies +18%.", "zh_CN": "对显形敌人伤害 +18%。"}},
	"u_ping_accelerant": {"name": {"en": "Flare Accelerant", "zh_CN": "照明弹加速剂"}, "description": {"en": "[Tag: flare] Attack rate +10%.", "zh_CN": "[标签：照明弹] 攻速 +10%。"}},
	"u_silent_baffles": {"name": {"en": "Silent Baffles", "zh_CN": "静音隔板"}, "description": {"en": "Noise generation -14%.", "zh_CN": "噪声获取 -14%。"}},
	"u_thermal_sink": {"name": {"en": "Thermal Sink", "zh_CN": "热沉模块"}, "description": {"en": "Noise decay +1.6/s.", "zh_CN": "噪声衰减 +1.6/秒。"}},
	"u_quiet_stride": {"name": {"en": "Quiet Stride", "zh_CN": "静行步态"}, "description": {"en": "Dash noise -25%.", "zh_CN": "冲刺噪声 -25%。"}},
	"u_low_profile_processor": {"name": {"en": "Low Profile Processor", "zh_CN": "低特征处理器"}, "description": {"en": "When Noise<=25, damage +17%.", "zh_CN": "当噪声<=25 时，伤害 +17%。"}},
	"u_hardlight_core": {"name": {"en": "Hardlight Core", "zh_CN": "硬光核心"}, "description": {"en": "Global damage +10%.", "zh_CN": "全局伤害 +10%。"}},
	"u_critical_lens": {"name": {"en": "Critical Lens", "zh_CN": "暴击透镜"}, "description": {"en": "[Tag: crit] Crit chance +5%.", "zh_CN": "[标签：暴击] 暴击率 +5%。"}},
	"u_overdrive_prism": {"name": {"en": "Overdrive Prism", "zh_CN": "过载棱镜"}, "description": {"en": "[Tag: crit] Crit multiplier +0.28.", "zh_CN": "[标签：暴击] 暴击倍率 +0.28。"}},
	"u_heat_sink_ammo": {"name": {"en": "Heat Sink Ammo", "zh_CN": "散热弹药"}, "description": {"en": "[Tag: heat] Damage +14%.", "zh_CN": "[标签：热能] 伤害 +14%。"}},
	"u_drill_wake": {"name": {"en": "Drill Wake", "zh_CN": "钻锋尾迹"}, "description": {"en": "[Tag: pierce] Pierce +1.", "zh_CN": "[标签：穿透] 穿透 +1。"}},
	"u_chain_conductor": {"name": {"en": "Chain Conductor", "zh_CN": "连锁导体"}, "description": {"en": "[Tag: chain] Damage +12%.", "zh_CN": "[标签：连锁] 伤害 +12%。"}},
	"u_chain_velocity": {"name": {"en": "Chain Velocity", "zh_CN": "连锁动量"}, "description": {"en": "[Tag: chain] Attack rate +10%, chain chance +6%.", "zh_CN": "[标签：连锁] 攻速 +10%，连锁概率 +6%。"}},
	"u_aoe_expander": {"name": {"en": "AOE Expander", "zh_CN": "范围扩增器"}, "description": {"en": "[Tag: aoe] Radius +18%.", "zh_CN": "[标签：范围] 半径 +18%。"}},
	"u_blast_density": {"name": {"en": "Blast Density", "zh_CN": "爆破密度"}, "description": {"en": "[Tag: aoe] Damage +11%.", "zh_CN": "[标签：范围] 伤害 +11%。"}},
	"u_drone_bay": {"name": {"en": "Drone Bay", "zh_CN": "无人机舱"}, "description": {"en": "Summon cap +1.", "zh_CN": "召唤上限 +1。"}},
	"u_summon_link": {"name": {"en": "Summon Link", "zh_CN": "召唤链路"}, "description": {"en": "[Tag: summon] Damage +14%.", "zh_CN": "[标签：召唤] 伤害 +14%。"}},
	"u_summon_clock": {"name": {"en": "Summon Clock", "zh_CN": "召唤时钟"}, "description": {"en": "[Tag: summon] Attack rate +13%.", "zh_CN": "[标签：召唤] 攻速 +13%。"}},
	"u_summon_screen": {"name": {"en": "Summon Screen", "zh_CN": "召唤屏障"}, "description": {"en": "Summon damage resistance +18%.", "zh_CN": "召唤物伤害抗性 +18%。"}},
	"u_salvage_loop": {"name": {"en": "Salvage Loop", "zh_CN": "回收回路"}, "description": {"en": "XP gain +16%.", "zh_CN": "经验获取 +16%。"}},
	"u_magnet_fins": {"name": {"en": "Magnet Fins", "zh_CN": "磁鳍模块"}, "description": {"en": "Pickup radius +16%.", "zh_CN": "拾取半径 +16%。"}},
	"u_precision_dart_matrix": {"name": {"en": "Precision Dart Matrix", "zh_CN": "精确飞镖矩阵"}, "description": {"en": "[Weapon: silence_dart] Damage +22%, reveal bonus +0.25s.", "zh_CN": "[武器：静默飞镖] 伤害 +22%，显形加成 +0.25 秒。"}},
	"u_lancer_rail_matrix": {"name": {"en": "Lancer Rail Matrix", "zh_CN": "枪骑兵轨道矩阵"}, "description": {"en": "[Weapon: needle_rifle] Attack rate +12%, pierce +1.", "zh_CN": "[武器：针刺步枪] 攻速 +12%，穿透 +1。"}},
	"u_burst_vent_tuning": {"name": {"en": "Burst Vent Tuning", "zh_CN": "爆发导流调校"}, "description": {"en": "[Weapon: burst_smg] Damage +10%, noise/shot -12%.", "zh_CN": "[武器：爆发冲锋枪] 伤害 +10%，每发噪声 -12%。"}},
	"u_shock_harmonics": {"name": {"en": "Shock Harmonics", "zh_CN": "震荡谐振"}, "description": {"en": "[Weapon: shock_pulse] Radius +20%, attack rate +8%.", "zh_CN": "[武器：震荡脉冲] 半径 +20%，攻速 +8%。"}},
	"u_mine_chain_relay": {"name": {"en": "Mine Chain Relay", "zh_CN": "地雷连锁继电"}, "description": {"en": "[Weapon: abyss_mine] Damage +20%, radius +12%.", "zh_CN": "[武器：深渊地雷] 伤害 +20%，半径 +12%。"}},
	"u_tether_focus": {"name": {"en": "Tether Focus", "zh_CN": "束缚聚焦"}, "description": {"en": "[Weapon: tether_beam] Damage +15%, range +12%.", "zh_CN": "[武器：束缚光束] 伤害 +15%，射程 +12%。"}},
	"u_drone_cluster_ai": {"name": {"en": "Drone Cluster AI", "zh_CN": "蜂群无人机 AI"}, "description": {"en": "[Weapon: orbital_drone] Summon +1, attack rate +10%.", "zh_CN": "[武器：轨道无人机] 召唤 +1，攻速 +10%。"}},
	"u_blade_resonance": {"name": {"en": "Blade Resonance", "zh_CN": "刃波共振"}, "description": {"en": "Flare Blade damage +16%, attack rate +12%.", "zh_CN": "照明刃伤害 +16%，攻速 +12%。"}}
}

var _language_code: String = DEFAULT_LANGUAGE_CODE


func _ready() -> void:
	if ProfileStore != null and ProfileStore.has_method("get_language_code"):
		_language_code = normalize_language_code(String(ProfileStore.call("get_language_code")))
	else:
		_language_code = DEFAULT_LANGUAGE_CODE


func get_language_code() -> String:
	return _language_code


func get_supported_language_codes() -> Array[String]:
	return SUPPORTED_LANGUAGE_CODES.duplicate()


func get_language_display_name(code: String) -> String:
	var normalized := normalize_language_code(code)
	var row_variant: Variant = LANGUAGE_DISPLAY_NAMES.get(normalized, {})
	if row_variant is Dictionary:
		var row: Dictionary = row_variant
		return String(row.get(_language_code, row.get(DEFAULT_LANGUAGE_CODE, normalized)))
	return normalized


func set_language_code(language_code: String) -> void:
	var normalized := normalize_language_code(language_code)
	if normalized == _language_code:
		return
	_language_code = normalized
	if ProfileStore != null and ProfileStore.has_method("set_language_code"):
		ProfileStore.call("set_language_code", _language_code)
	language_changed.emit(_language_code)


func normalize_language_code(language_code: String) -> String:
	var code := language_code.strip_edges()
	if code.is_empty():
		return DEFAULT_LANGUAGE_CODE
	if code == "zh" or code == "zh_CN" or code == "zh-Hans":
		return "zh_CN"
	return DEFAULT_LANGUAGE_CODE


func is_chinese() -> bool:
	return _language_code == "zh_CN"


func t(key: String, args: Dictionary = {}) -> String:
	var row_variant: Variant = UI_TEXT.get(key, {})
	if not (row_variant is Dictionary):
		return _apply_args(key, args)
	var row: Dictionary = row_variant
	var value := String(row.get(_language_code, row.get(DEFAULT_LANGUAGE_CODE, key)))
	return _apply_args(value, args)


func tag_name(tag: String) -> String:
	var normalized := tag.strip_edges().to_lower()
	var locale_variant: Variant = TAG_LABELS.get(_language_code, TAG_LABELS[DEFAULT_LANGUAGE_CODE])
	if locale_variant is Dictionary:
		var locale_labels: Dictionary = locale_variant
		if locale_labels.has(normalized):
			return String(locale_labels.get(normalized, normalized))
	return normalized.capitalize()


func rarity_name(rarity: String) -> String:
	var normalized := rarity.strip_edges().to_lower()
	var locale_variant: Variant = RARITY_LABELS.get(_language_code, RARITY_LABELS[DEFAULT_LANGUAGE_CODE])
	if locale_variant is Dictionary:
		var locale_labels: Dictionary = locale_variant
		if locale_labels.has(normalized):
			return String(locale_labels.get(normalized, normalized))
	return normalized.capitalize()


func stat_name(stat: String) -> String:
	var normalized := stat.strip_edges().to_lower()
	var locale_variant: Variant = STAT_LABELS.get(_language_code, STAT_LABELS[DEFAULT_LANGUAGE_CODE])
	if locale_variant is Dictionary:
		var labels: Dictionary = locale_variant
		if labels.has(normalized):
			return String(labels.get(normalized, normalized))
	return normalized.replace("_", " ").capitalize()


func localize_data_entry(entry: Dictionary) -> Dictionary:
	var output := entry.duplicate(true)
	var entry_id := String(output.get("id", "")).strip_edges()
	if output.has("name"):
		output["name"] = data_field(entry_id, "name", String(output.get("name", "")), output)
	if output.has("description"):
		output["description"] = data_field(entry_id, "description", String(output.get("description", "")), output)
	if output.has("display_name"):
		output["display_name"] = data_field(entry_id, "display_name", String(output.get("display_name", "")), output)
	if output.has("short_desc"):
		output["short_desc"] = data_field(entry_id, "short_desc", String(output.get("short_desc", "")), output)
	if output.has("passive_summary"):
		output["passive_summary"] = data_field(entry_id, "passive_summary", String(output.get("passive_summary", "")), output)
	if output.has("hazard_summary"):
		output["hazard_summary"] = data_field(entry_id, "hazard_summary", String(output.get("hazard_summary", "")), output)
	if output.has("event_summary"):
		output["event_summary"] = data_field(entry_id, "event_summary", String(output.get("event_summary", "")), output)
	if output.has("warning_text"):
		output["warning_text"] = data_field(entry_id, "warning_text", String(output.get("warning_text", "")), output)
	if output.has("unlock"):
		var unlock_variant: Variant = output.get("unlock", {})
		if unlock_variant is Dictionary:
			var unlock: Dictionary = unlock_variant.duplicate(true)
			unlock["display"] = data_field(entry_id, "unlock_display", String(unlock.get("display", "")), unlock)
			output["unlock"] = unlock
	return output


func localize_data_array(value: Array) -> Array:
	var output: Array = []
	for item_variant in value:
		if item_variant is Dictionary:
			output.append(localize_data_entry(item_variant))
		else:
			output.append(item_variant)
	return output


func data_field(entry_id: String, field: String, fallback: String, source: Dictionary = {}) -> String:
	var fallback_text := fallback
	if _language_code == "zh_CN":
		var field_zh := "%s_zh" % field
		if source.has(field_zh):
			var source_zh := String(source.get(field_zh, "")).strip_edges()
			if not source_zh.is_empty():
				return source_zh
	var pack_variant: Variant = DATA_TEXT_BY_ID.get(entry_id, {})
	if pack_variant is Dictionary:
		var pack: Dictionary = pack_variant
		var field_variant: Variant = pack.get(field, {})
		if field_variant is Dictionary:
			var field_dict: Dictionary = field_variant
			var translated := String(field_dict.get(_language_code, field_dict.get(DEFAULT_LANGUAGE_CODE, fallback_text))).strip_edges()
			if not translated.is_empty():
				return translated
	return fallback_text


func _apply_args(text: String, args: Dictionary) -> String:
	var output := text
	for key_variant in args.keys():
		var key := str(key_variant)
		output = output.replace("{%s}" % key, str(args.get(key_variant, "")))
	return output
