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
		"sonar": "Sonar",
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
		"sonar": "声呐",
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
		"sonar_reveal_duration_mult": "Reveal Duration",
		"revealed_damage_mult": "Revealed Damage",
		"low_noise_damage_mult": "Low-Noise Damage",
		"pickup_radius_mult": "Pickup Radius",
		"summon_cap_bonus": "Summon Cap",
		"summon_resistance": "Summon Resistance",
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
		"sonar_reveal_duration_mult": "显形时长",
		"revealed_damage_mult": "对显形目标伤害",
		"low_noise_damage_mult": "低噪伤害",
		"pickup_radius_mult": "拾取范围",
		"summon_cap_bonus": "召唤上限",
		"summon_resistance": "召唤抗性",
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
	"hud.skill_sonar": {"en": "Q Flare", "zh_CN": "Q 照明弹"},
	"hud.skill_dash": {"en": "Space Dash", "zh_CN": "空格 冲刺"},
	"hud.badge.level": {"en": "Lvl", "zh_CN": "等级"},
	"hud.badge.kills": {"en": "Kills", "zh_CN": "击杀"},
	"hud.badge.time": {"en": "Time", "zh_CN": "时间"},
	"hud.hp": {"en": "HP {current}/{max}", "zh_CN": "生命 {current}/{max}"},
	"hud.enemy_info": {"en": "Enemies {enemy} | Revealed {revealed}", "zh_CN": "敌人 {enemy} | 显形 {revealed}"},
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
	"sys.data_reload_failed": {"en": "Data reload failed.", "zh_CN": "数据重载失败。"},
	"sys.data_reloaded": {"en": "Data reloaded (fog/sonar/noise/maps).", "zh_CN": "数据已重载（迷雾/声呐/噪声/地图）。"},
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
		"short_desc": {"en": "Low-noise sonar specialist.", "zh_CN": "低噪声声呐专家。"},
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
		"display_name": {"en": "Neon Scavenger", "zh_CN": "霓虹拾荒者"},
		"short_desc": {"en": "Resource diver who turns scraps into growth.", "zh_CN": "把残骸转化为成长资源的潜行者。"},
		"passive_summary": {"en": "Larger pickup radius and better XP conversion.", "zh_CN": "更大拾取半径与更高经验转化。"},
		"unlock_display": {"en": "Survive for 10:00 in a single run.", "zh_CN": "在单局中生存 10:00。"}
	},

	"map_trench_lab": {
		"name": {"en": "Trench Lab", "zh_CN": "海沟实验区"},
		"description": {"en": "Neon industrial trench with unstable magnetic storms.", "zh_CN": "霓虹工业海沟，伴随不稳定磁暴。"},
		"hazard_summary": {"en": "Magnetic storms disrupt sonar and raise noise risk.", "zh_CN": "磁暴会干扰声呐并提高噪声风险。"},
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
		"description": {"en": "Electromagnetic bursts destabilize sonar and amplify noise signatures.", "zh_CN": "电磁脉冲会扰乱声呐并放大噪声特征。"},
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
		"description": {"en": "A temporary calm zone restores sonar clarity.", "zh_CN": "临时平静区可恢复声呐清晰度。"},
		"immediate_message": {"en": "Quiet pocket formed", "zh_CN": "静默空腔形成"}
	},

	"contract_small_vision": {"name": {"en": "Narrow Aperture", "zh_CN": "狭缝视界"}, "description": {"en": "Fog radius reduced by 30%.", "zh_CN": "迷雾半径降低 30%。"}},
	"contract_loud_world": {"name": {"en": "Loud World", "zh_CN": "喧响世界"}, "description": {"en": "Noise gain increased by 25%.", "zh_CN": "噪声获取提高 25%。"}},
	"contract_elite_rush": {"name": {"en": "Elite Rush", "zh_CN": "精英狂潮"}, "description": {"en": "Elite spawn chance increased.", "zh_CN": "精英刷新概率提高。"}},
	"contract_no_dash": {"name": {"en": "No Dash", "zh_CN": "禁用冲刺"}, "description": {"en": "Dash is disabled.", "zh_CN": "冲刺被禁用。"}},
	"contract_black_tide_often": {"name": {"en": "Frequent Black Tide", "zh_CN": "高频黑潮"}, "description": {"en": "Hazard cycles speed up.", "zh_CN": "灾害循环加速。"}},
	"contract_sonar_fuzzy": {"name": {"en": "Sonar Fuzzy", "zh_CN": "声呐失真"}, "description": {"en": "Sonar reveal duration reduced by 20%.", "zh_CN": "声呐显形时长降低 20%。"}},
	"contract_pursuer_hunt": {"name": {"en": "Pursuer Hunt", "zh_CN": "追猎协议"}, "description": {"en": "Pursuers spawn more often but drop better loot.", "zh_CN": "追猎者刷新更频繁，但掉落更好。"}},
	"contract_fast_enemies": {"name": {"en": "Fast Enemies", "zh_CN": "疾速敌群"}, "description": {"en": "Enemy speed and spawn rate increased.", "zh_CN": "敌人移速与刷新速率提高。"}},
	"contract_fragile_player": {"name": {"en": "Fragile Hull", "zh_CN": "脆弱船体"}, "description": {"en": "Player max HP reduced by 15%.", "zh_CN": "玩家最大生命降低 15%。"}},
	"contract_rich_pickups": {"name": {"en": "Rich Pickups", "zh_CN": "丰饶拾取"}, "description": {"en": "More drops, but spawn pressure increases.", "zh_CN": "掉落更多，但刷怪压力提高。"}},
	"contract_silent_bonus": {"name": {"en": "Silent Edge", "zh_CN": "静默刃"}, "description": {"en": "Low-noise damage boosted but exposed penalties increase.", "zh_CN": "低噪伤害提升，但暴露惩罚加重。"}},
	"contract_event_storm": {"name": {"en": "Event Storm", "zh_CN": "事件风暴"}, "description": {"en": "Events trigger more frequently.", "zh_CN": "事件触发更加频繁。"}},

	"needle_rifle": {"name": {"en": "Needle Rifle", "zh_CN": "针刺步枪"}, "description": {"en": "Mid-speed puncture rifle tuned for trench lanes.", "zh_CN": "为海沟战线调校的中速穿刺步枪。"}},
	"burst_smg": {"name": {"en": "Burst SMG", "zh_CN": "爆发冲锋枪"}, "description": {"en": "High-rate muzzle storm with heavy acoustic footprint.", "zh_CN": "高射速火力风暴，声学暴露较高。"}},
	"silence_dart": {"name": {"en": "Silence Dart", "zh_CN": "静默飞镖"}, "description": {"en": "Low-signature dart that extends sonar reveal windows.", "zh_CN": "低特征飞镖，可延长声呐显形窗口。"}},
	"shock_pulse": {"name": {"en": "Shock Pulse", "zh_CN": "震荡脉冲"}, "description": {"en": "Near-field ring pulse for close swarm clearing.", "zh_CN": "近场环形脉冲，适合清理贴身敌群。"}},
	"abyss_mine": {"name": {"en": "Abyss Mine", "zh_CN": "深渊地雷"}, "description": {"en": "Timed abyss charge that detonates on proximity.", "zh_CN": "延时深渊炸弹，接近即爆。"}},
	"tether_beam": {"name": {"en": "Tether Beam", "zh_CN": "束缚光束"}, "description": {"en": "Locks one target with continuous control damage.", "zh_CN": "锁定单体目标并持续施加控制伤害。"}},
	"orbital_drone": {"name": {"en": "Orbital Drone", "zh_CN": "轨道无人机"}, "description": {"en": "Summons an orbiting drone that auto-fires around you.", "zh_CN": "召唤环绕无人机自动射击。"}},
	"sonar_blade": {"name": {"en": "Sonar Blade", "zh_CN": "声呐刃"}, "description": {"en": "Close-range arc strike that emits amplified sonar.", "zh_CN": "近战弧斩并释放强化声呐。"}},
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

	"u_sonar_scope_matrix": {"name": {"en": "Sonar Scope Matrix", "zh_CN": "声呐视域矩阵"}, "description": {"en": "[Tag: sonar] Range +12%.", "zh_CN": "[标签：声呐] 射程 +12%。"}},
	"u_echo_stabilizer": {"name": {"en": "Echo Stabilizer", "zh_CN": "回波稳定器"}, "description": {"en": "Sonar reveal duration +14%.", "zh_CN": "声呐显形时长 +14%。"}},
	"u_exposed_breaker": {"name": {"en": "Exposed Breaker", "zh_CN": "暴露粉碎者"}, "description": {"en": "Damage to revealed enemies +18%.", "zh_CN": "对显形敌人伤害 +18%。"}},
	"u_ping_accelerant": {"name": {"en": "Ping Accelerant", "zh_CN": "脉冲加速剂"}, "description": {"en": "[Tag: sonar] Attack rate +10%.", "zh_CN": "[标签：声呐] 攻速 +10%。"}},
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
	"u_blade_resonance": {"name": {"en": "Blade Resonance", "zh_CN": "刃波共振"}, "description": {"en": "[Weapon: sonar_blade] Damage +16%, attack rate +12%.", "zh_CN": "[武器：声呐刃] 伤害 +16%，攻速 +12%。"}}
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
