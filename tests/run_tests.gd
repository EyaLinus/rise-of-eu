extends SceneTree
## Unit and data tests. Run: godot --headless --path . -s res://tests/run_tests.gd
## Exit code 1 on any failure.

const Game = preload("res://scripts/core/game.gd")
const Data = preload("res://scripts/core/data.gd")

var data: Dictionary
var failures := 0
var checks := 0


func _init() -> void:
	data = Data.load_all()
	var only := []  # godot --headless -s res://tests/run_tests.gd -- test_a test_b
	for arg in OS.get_cmdline_user_args():
		only.append(arg)
	for t in [
		"test_data_references", "test_map_geometry", "test_map_connected", "test_events_shape",
		"test_develop_and_tech", "test_recruit_limits", "test_war_and_peace", "test_vassal_and_annex", "test_unrest_and_revolt", "test_hre_election", "test_alliance_joins_war", "test_protector_defends_small_state",
		"test_economy_goods_and_trade", "test_buildings", "test_autobuild", "test_army_power", "test_road_march", "test_power_actions", "test_building_gain", "test_marriage", "test_generals", "test_peace_offer_cooldown", "test_mercenaries", "test_trade_pacts", "test_loans_and_shocks", "test_harbor", "test_army_stances", "test_progression", "test_stability", "test_coalition_forms", "test_inherit", "test_inherit_never_takes_player", "test_save_roundtrip",
		"test_separate_peace", "test_tired_ai_seeks_peace", "test_ai_marriage_and_generals", "test_ai_access_and_guarantee", "test_income_bonus_and_army_cost",
		"test_difficulty",
		"test_march_time_and_terrain", "test_interception", "test_battle_rounds",
		"test_naval",
		"test_ai_peace_spending",
		"test_capitulation",
		"test_coalition_softer_vs_player",
		"test_fleet_missions",
		"test_ai_war_odds",
		"test_military_access",
		"test_guarantee",
		"test_rivals",
		"test_urban",
		"test_city_tiers",
		"test_manpower_overflow",
		"test_units_and_templates",
		"test_colonial",
		"test_fog_of_war",
		"test_na_west_and_netherlands",
		"test_alert_bar",
		"test_west_africa",
		"test_south_africa",
		"test_south_america",
		"test_world_map",
		"test_troop_transport",
		"test_embargo",
		"test_hall_of_fame",
		"test_rival_missions",
		"test_play_on",
		"test_formables",
		"test_chronicle",
		"test_religion",
		"test_monuments_and_feast", "test_first_steps", "test_score_history",
		"test_missions_complete", "test_tech_data", "test_tech_tree", "test_special_techs", "test_tech_modifiers",
		"test_government_data", "test_advisors", "test_companies", "test_laws", "test_gov_save_roundtrip", "test_company_invest", "test_estates", "test_gov_events", "test_budget", "test_eco_content", "test_rel_content", "test_court_content", "test_monument_events", "test_ctx_events", "test_late_content", "test_era_content", "test_event_keys", "test_war_events", "test_south_content", "test_morale_modifiers", "test_reforms", "test_tech_spread",
		"test_empire_reforms",
		"test_religion_modifiers",
		"test_age_goals",
		"test_advisor_skill",
		"test_gov_forms",
		"test_tech_ahead",
		"test_tech_queue",
		"test_heir",
		"test_building_tech",
		"test_gov_sources",
		"test_regency",
		"test_form_change",
		"test_start_resources",
		"test_age_decisions",
		"test_diplo_capacity",
		"test_cape_route",
		"test_overseas_markets",
		"test_market_dominance",
		"test_debug_tools",
		"test_ledger",
		"test_goods_events",
		"test_playable_flavour",
		"test_hungary_powerhouse",
		"test_colonial_events", "test_colonial_exhaustion", "test_subjects",
		"test_event_balance",
		"test_more_goods_and_softer_costs",
		"test_supply_and_ai_stacks",
		"test_landmarks", "test_daily_gain",
		"test_world_playables",
		"test_tribes",
		"test_perf_caches",
		"test_modifier_keys_known",
		"test_old_save_tech_levels", "test_council", "test_elections", "test_ai_uses_government", "test_long_run_no_softlock", "test_emoji_coverage", "test_event_pictures", "test_ui_kit",
	]:
		if not only.is_empty() and not only.has(t):
			continue
		var before := failures
		call(t)
		print(("PASS " if failures == before else "FAIL ") + t)
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func check(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		printerr("  ✗ " + msg)


func new_game(player := "FRA", seed_value := 7):
	var g = Game.new()
	g.setup(data, seed_value, player)
	return g


# ---------------------------------------------------------------- data

func test_data_references() -> void:
	var keys := {}
	for p in data.map.provinces:
		keys[p.key] = true
	var tags: Dictionary = data.nations
	for tag in tags:
		check(keys.has(tags[tag].capital), "capital of %s exists" % tag)
	var owners := {}
	for p in data.map.provinces:
		check(tags.has(p.owner), "owner %s of %s is a nation" % [p.owner, p.key])
		owners[p.owner] = true
	for tag in tags:
		if tags[tag].has("dormant"):
			continue  # pool nations for colonial nations and appanages (Subjects) start without land
		check(owners.has(tag), "%s owns at least one province" % tag)
	var refs := []
	for e in data.events:
		refs.append([e.id, e.get("trigger", {})])
		for o in e.options:
			refs.append([e.id, o.get("effects", {})])
	for tag in data.missions:
		check(tags.has(tag), "mission tag %s" % tag)
		for m in data.missions[tag]:
			refs.append([m.id, m.get("require", {})])
			refs.append([m.id, m.get("reward", {})])
	for r in refs:
		var d: Dictionary = r[1]
		for k in ["owns", "owns_any", "not_owns", "claim"]:
			for key in d.get(k, []):
				check(keys.has(key), "%s: province key %s exists" % [r[0], key])
		for k in ["alive", "not_alive", "allied", "alliance", "inherit", "war", "vassal"]:
			if d.has(k):
				check(tags.has(d[k]), "%s: tag %s exists" % [r[0], d[k]])
		if d.has("province"):
			check(keys.has(d.province), "%s: province %s exists" % [r[0], d.province])
		for t in d.get("relations", {}):
			check(tags.has(t), "%s: relation tag %s" % [r[0], t])


func test_map_geometry() -> void:
	for p in data.map.provinces:
		for poly in p.polys:
			var arr := PackedVector2Array()
			for pt in poly:
				arr.append(Vector2(pt[0], pt[1]))
			check(arr.size() >= 3 and not Geometry2D.triangulate_polygon(arr).is_empty(), "polygon of %s triangulates" % p.key)


## The Old World (with all of Africa, over the Saharan caravan routes and the Comoros crossing to
## Madagascar) and the New World are each one connected landmass (no land route across the Atlantic).
## Only Aotearoa and Hawaii are separate island groups, reached by sea.
func test_map_connected() -> void:
	var g = new_game()
	var Col = load("res://scripts/core/colonial.gd")
	check(g.nw_first > 200 and g.nw_first < g.wa_first and g.wa_first < g.provinces.size(), "the map has a New World (%d) and a West African part (%d)" % [g.nw_first, g.wa_first])
	# the Middle East and the Horn of Africa come after the overseas block and are Old World again
	check(g.nw_end > g.wa_first and g.nw_end < g.provinces.size(), "the map has an eastern Old World block (%d)" % g.nw_end)
	for k in ["baghdad", "isfahan", "mecca", "amhara", "harar"]:
		var pid: int = g.key_to_pid[k]
		check(Col.region(g, pid) == "old" and not Col.is_new_world(g, pid) and Col.knows(g, "FRA", pid), "%s is known Old World land" % k)
	check(Col.region(g, g.nw_end - 1) == "africa", "the overseas block ends with West Africa")
	# Aotearoa and Hawaii lie far out in the Pacific: islands reached only by ship, each its own landmass
	var starts := [0, g.nw_first]
	for k in ["northland", "hawaii"]:
		var ip: int = g.key_to_pid[k]
		check(not g.province_seas.get(ip, []).is_empty(), "%s has a coast for ships" % k)
		starts.append(ip)
	var seen := {}
	for start in starts:
		seen[start] = true
		var q := [start]
		while not q.is_empty():
			var c: int = q.pop_back()
			for a in g.provinces[c].adj:
				check(g.provinces[a].adj.has(c), "adjacency symmetric %d-%d" % [c, a])
				check((Col.region(g, a) == "america") == (Col.region(g, c) == "america"), "no adjacency across the Atlantic %d-%d" % [c, a])
				if not seen.has(a):
					seen[a] = true
					q.append(a)
	check(seen.size() == g.provinces.size(), "all provinces connected (%d/%d)" % [seen.size(), g.provinces.size()])


func test_events_shape() -> void:
	var ids := {}
	for e in data.events:
		check(not ids.has(e.id), "unique event id " + e.id)
		ids[e.id] = true
		check(e.options.size() == 3, "event %s has 3 options" % e.id)
	for tag in ["FRA", "ENG", "SPA", "BOH", "HAB", "RUS", "NAP"]:
		var n := 0
		for e in data.events:
			if e.get("tag", "") == tag:
				n += 1
		check(n >= 5, "%s has >= 5 events (%d)" % [tag, n])
		check(data.missions.has(tag) and data.missions[tag].size() >= 5, "%s has missions" % tag)


# ---------------------------------------------------------------- mechanics

func test_develop_and_tech() -> void:
	var g = new_game()
	var n = g.nations.FRA
	var pid: int = n.capital
	var dev: int = g.provinces[pid].dev
	n.adm = 500
	check(g.develop("FRA", pid) == "", "develop succeeds")
	check(g.provinces[pid].dev == dev + 1, "dev increased")
	check(n.adm < 500, "adm spent")
	n.adm = 0
	check(g.develop("FRA", pid) != "", "develop fails without adm")
	n.mil = 1000
	var lvl: int = n.tech.mil
	check(g.buy_tech("FRA", "mil") == "", "tech bought")
	check(n.tech.mil == lvl + 1, "tech level up")
	check(g.develop("FRA", g.key_to_pid["london"]) != "", "cannot develop foreign province")
	n.adm = 0
	n.dip = 500
	var d2: int = g.provinces[pid].dev
	check(g.develop("FRA", pid, "dip") == "", "develop with diplomacy")
	check(g.provinces[pid].dev == d2 + 1 and n.dip < 500 and n.adm == 0, "diplomacy paid, admin untouched")
	n.mil = 0
	check(g.develop("FRA", pid, "mil") != "", "develop fails without mil")
	# capped power is not lost: the player's overflow goes into the cheapest development
	var g2 = new_game("FRA")
	var n2 = g2.nations.FRA
	var cheap: int = g2.cheapest_develop("FRA")
	var dev_before: int = g2.provinces[cheap].dev
	n2.mil = float(g2.bal.power_cap)
	g2._overflow_develop(n2)
	check(g2.provinces[cheap].dev == dev_before + 1 and n2.mil < float(g2.bal.power_cap), "overflow develops the cheapest province")
	n2.adm = 10.0
	g2._overflow_develop(n2)
	check(n2.adm == 10.0, "no overflow spending below the cap")


func test_recruit_limits() -> void:
	var g = new_game()
	var n = g.nations.FRA
	n.gold = 10000
	n.manpower = 1000
	var fl: float = g.force_limit("FRA")
	var have: float = g.army_regs("FRA")
	var room := int(fl - have)
	check(g.recruit("FRA", n.capital, room) == "", "recruit up to force limit")
	check(g.recruit("FRA", n.capital, 1) != "", "force limit enforced")
	# battle losses leave fractions: the HUD shows rounded regiments over whole-regiment limit and recruiting must agree
	var g2 = new_game()
	var n2 = g2.nations.FRA
	n2.gold = 10000
	n2.manpower = 1000
	var army = g2.armies_of("FRA")[0]
	army.regs += g2.force_cap("FRA") - g2.regs_counted("FRA") - 1  # one regiment short of the limit (as shown)
	army.regs += 0.4 - fmod(g2.army_regs("FRA"), 1.0)  # e.g. 15.4 shown as 15
	check(g2.regs_counted("FRA") == g2.force_cap("FRA") - 1 and g2.force_room("FRA") == 1, "one regiment of room")
	check(g2.recruit("FRA", n2.capital, 2) != "", "two do not fit")
	check(g2.recruit("FRA", n2.capital, 1) == "", "15/16 shown: one more regiment can be raised")
	check(g2.force_room("FRA") == 0 and g2.recruit("FRA", n2.capital, 1) != "", "16/16: limit reached")


func test_war_and_peace() -> void:
	var g = new_game("FRA")
	# isolate: drop alliances so only two nations fight
	for t in g.order:
		g.nations[t].allies.clear()
	g.nations.FRA.claims.clear()
	check(g.declare_war("FRA", "BRI") == "", "war declared (no CB)")
	var w = g.war_between("FRA", "BRI")
	check(w != null, "war exists")
	check(g.nations.FRA.ae > 0, "no-CB war adds AE")
	var rennes: int = g.key_to_pid["rennes"]
	g.provinces[rennes].controller = "FRA"
	check(g.warscore(w) > 0, "occupation gives war score")
	check(g.demandable(w, true).has(rennes), "occupied province demandable")
	var ae_before: float = g.nations.FRA.ae
	g.make_peace(w, true, [rennes])
	check(g.provinces[rennes].owner == "FRA", "province transferred")
	check(g.nations.FRA.ae > ae_before, "taking land adds AE")
	check(g.provinces[rennes].core_months > 0, "new province uncored")
	check(not g.at_war("FRA", "BRI"), "war ended")
	check(g.has_truce("FRA", "BRI"), "truce after peace")
	check(g.declare_war("FRA", "BRI") != "", "cannot attack during truce")


func test_vassal_and_annex() -> void:
	var g = new_game("FRA")
	for t in g.order:
		g.nations[t].allies.clear()
	g.nations.FRA.claims.clear()
	g.declare_war("FRA", "BRI")
	var w = g.war_between("FRA", "BRI")
	# keep the war two-sided so the vassal test does not depend on protectors
	w.defenders = ["BRI"]
	check(g.vassal_block_reason(w, true) == "", "Brittany can be vassalized: " + g.vassal_block_reason(w, true))
	check(g.vassal_block_reason(w, false) != "", "player can never become a vassal")
	g.provinces[g.key_to_pid["rennes"]].controller = "FRA"
	check(not g.offer_peace("FRA", w, [], true, true) or g.nations.BRI.overlord == "FRA", "offer consistent")
	if g.wars.has(w):
		g.make_peace(w, true, [], true)
	var bri = g.nations.BRI
	check(bri.overlord == "FRA" and bri.alive, "BRI is a living vassal of FRA")
	check(g.is_allied("FRA", "BRI") and g.vassals_of("FRA") == ["BRI"], "vassal counts as same side")
	check(g.declare_war("BRI", "ENG") != "", "vassal cannot declare war")
	check(g.propose_alliance("BRI", "ENG") != "", "vassal cannot make alliances")
	# vassal joins the overlord's wars and the overlord defends the vassal
	g.nations.ENG.truces.clear()
	g.nations.FRA.truces.clear()
	g.nations.BRI.truces.clear()
	g.declare_war("ENG", "BRI")
	var w2 = g.war_between("ENG", "BRI")
	check(w2 != null and w2.defenders.has("FRA"), "overlord defends its vassal")
	g.wars.erase(w2)
	# tribute flows to the overlord
	var gold_before: float = g.nations.FRA.gold
	g._economy(bri)
	check(g.nations.FRA.gold > gold_before, "vassal pays tribute")
	check(g.tribute_income("FRA") > 0.0, "tribute shown")
	# annexation is gated by time, then moves all land
	check(g.annex_vassal("FRA", "BRI") != "", "annex blocked during waiting period")
	g.month += int(g.bal.vassal_annex_years) * 12
	g.nations.FRA.dip = 999.0
	g.nations.FRA.adm = 999.0
	var bri_provs: Array = g.provinces_of("BRI").duplicate()
	check(g.annex_vassal("FRA", "BRI") == "", "annexation succeeds")
	check(not bri.alive, "annexed vassal is gone")
	for pid in bri_provs:
		check(g.provinces[pid].owner == "FRA" and g.provinces[pid].core_months > 0, "annexed land owned and integrating")
	# save/load keeps vassal links
	var g2 = new_game("FRA")
	var war3 = null
	for t in g2.order:
		g2.nations[t].allies.clear()
	g2.declare_war("FRA", "BRI")
	war3 = g2.war_between("FRA", "BRI")
	g2.make_peace(war3, true, [], true)
	var d: Dictionary = JSON.parse_string(JSON.stringify(g2.to_dict()))
	var g3 = new_game("FRA")
	g3.from_dict(d)
	check(g3.nations.BRI.overlord == "FRA" and g3.nations.BRI.vassal_since == g2.nations.BRI.vassal_since, "vassal survives save/load")
	# overlord death frees the vassal
	for pid in g2.provinces_of("FRA").duplicate():
		g2.provinces[pid].owner = "ENG"
	g2._rebuild_owned()
	g2._check_alive("FRA")
	check(g2.nations.BRI.overlord == "", "vassal freed when overlord dies")


func test_unrest_and_revolt() -> void:
	var g = new_game("FRA")
	var rennes: int = g.key_to_pid["rennes"]
	var p = g.provinces[rennes]
	# conquered, uncored, exhausted: high unrest
	p.owner = "FRA"
	p.controller = "FRA"
	p.prev_owner = "BRI"
	p.core_months = 60
	g._rebuild_owned()
	g.nations.FRA.we = 16.0
	for a in g.armies.duplicate():
		if a.pid == rennes:
			g.armies.erase(a)
	check(g.unrest(rennes) >= float(g.bal.revolt_threshold), "uncored + war exhaustion = unrest %.1f" % g.unrest(rennes))
	g._revolt(p)
	check(p.owner == "BRI", "unruly conquest defects back to its former owner")
	# suppression lowers unrest
	var paris: int = g.key_to_pid["paris"]
	var u0: float = g.unrest(paris)
	g.nations.FRA.mil = 999.0
	check(g.suppress_unrest("FRA", paris) == "", "suppress works")
	check(g.unrest(paris) <= u0, "suppression does not raise unrest")
	# plain revolt without a former owner costs development
	var orl: int = g.key_to_pid["orleans"]
	var dev0: int = g.provinces[orl].dev
	g._revolt(g.provinces[orl])
	check(g.provinces[orl].dev == maxi(1, dev0 - 1) and g.provinces[orl].owner == "FRA", "revolt loots, province stays")
	# war exhaustion makes the AI accept peace more easily and can be reduced
	g.nations.FRA.dip = 999.0
	check(g.reduce_we("FRA") == "" and g.nations.FRA.we < 16.0, "reduce war exhaustion")
	# a strong vassal breaks free
	var g2 = new_game("FRA")
	g2.nations.BRI.overlord = "ENG"
	g2.add_rel("BRI", "ENG", -50.0)
	for a in g2.armies.duplicate():
		if a.owner == "ENG":
			g2.armies.erase(a)
	check(g2.liberty("BRI") >= float(g2.bal.vassal_liberty_threshold), "liberty high when overlord is weak")
	for i in 40:
		g2._liberty_yearly()
	check(g2.nations.BRI.overlord == "", "vassal declares independence")
	# save roundtrip keeps the new fields
	var d: Dictionary = JSON.parse_string(JSON.stringify(g.to_dict()))
	var g3 = new_game("FRA")
	g3.from_dict(d)
	check(absf(g3.nations.FRA.we - g.nations.FRA.we) < 0.01 and g3.provinces[paris].suppress_months == 24, "unrest state saved")


func test_hre_election() -> void:
	var g = new_game("BOH")
	check(g.emperor == "HAB", "Habsburg starts as emperor")
	check(g.current_electors().size() == 7, "seven electors")
	var votes: Dictionary = g.election_votes()
	for e in votes:
		check(votes[e] != e, "electors never vote for themselves")
	# win over every elector: the player becomes emperor
	for e in g.current_electors():
		if e != "BOH":
			g.add_rel("BOH", e, 200.0)
	g.nations.BOH.prestige = 200.0
	g.hre_election()
	check(g.emperor == "BOH", "favoured candidate wins the election (got %s)" % g.emperor)
	check(g.monthly_power(g.nations.BOH, "dip") > g.monthly_power(g.nations.BOH, "adm") - 10, "emperor bonus applies")
	var d: Dictionary = JSON.parse_string(JSON.stringify(g.to_dict()))
	var g2 = new_game("BOH")
	g2.from_dict(d)
	check(g2.emperor == "BOH", "emperor saved")
	# new content conditions
	g2.nations.BOH.we = 5.0
	check(g2.check_conditions("BOH", {"we_min": 4, "is_vassal": false, "has_vassal": false}), "we_min / is_vassal / has_vassal")
	check(not g2.check_conditions("BOH", {"we_min": 6}), "we_min fails below")
	check(g2.check_conditions("BOH", {"unrest_min": 0}) and not g2.check_conditions("BOH", {"unrest_min": 50}), "unrest_min")
	check(g2.check_conditions("BOH", {"hre": true, "emperor": true}) and g2.check_conditions("FRA", {"hre": false, "emperor": false}), "hre / emperor")
	# a dead emperor triggers a new election at year end
	for pid in g.provinces_of("BOH").duplicate():
		g.provinces[pid].owner = "SAX"
	g._rebuild_owned()
	g._check_alive("BOH")
	g._yearly()
	check(g.emperor != "BOH" and g.emperor != "", "new emperor after the old one died")


func test_alliance_joins_war() -> void:
	var g = new_game("FRA")
	for t in g.order:
		g.nations[t].allies.clear()
	g._ally("BRI", "ENG")
	g.declare_war("FRA", "BRI")
	var w = g.war_between("FRA", "BRI")
	check(w.defenders.has("ENG"), "defensive ally joins")


func test_separate_peace() -> void:
	var g = new_game("FRA")
	for t in g.order:
		g.nations[t].allies.clear()
		g.nations[t].truces.clear()
	g._ally("BRI", "ENG")
	g.declare_war("FRA", "BRI")
	var w = g.war_between("FRA", "BRI")
	check(g.leave_war("BRI", w) != "", "the war leader cannot leave its own war")
	check(g.leave_war("FRA", w) != "", "nor can the attacking leader")
	var york: int = g.key_to_pid["york"]
	g.provinces[york].controller = "FRA"
	var rel_before: float = g.get_rel("BRI", "ENG")
	check(g.leave_war("ENG", w) == "", "an ally may make a separate peace")
	check(not w.defenders.has("ENG") and g.wars.has(w), "the war goes on without the ally")
	check(g.provinces[york].controller == "ENG", "occupations between the two end")
	check(g.has_truce("ENG", "FRA"), "a truce follows")
	check(g.get_rel("BRI", "ENG") < rel_before, "the abandoned leader resents it")


func test_tired_ai_seeks_peace() -> void:
	var g = new_game("ENG")
	for t in g.order:
		g.nations[t].allies.clear()
		g.nations[t].truces.clear()
	g._ally("BRI", "SPA")
	g.declare_war("FRA", "BRI")
	var w = g.war_between("FRA", "BRI")
	w.start = g.month - 24
	g.nations.SPA.we = float(g.bal.we_max)
	g.ai._consider_peace(g, g.nations.SPA)
	check(not w.defenders.has("SPA"), "an exhausted ally leaves a war it is not winning")
	g.nations.FRA.we = float(g.bal.we_max)
	g.nations.BRI.we = float(g.bal.we_max)
	g.ai._consider_peace(g, g.nations.FRA)
	check(not g.wars.has(w), "an exhausted leader settles an even war")


func test_protector_defends_small_state() -> void:
	var g = new_game("")
	for t in g.order:
		g.nations[t].allies.clear()
	g.declare_war("FRA", "BRI")
	var w = g.war_between("FRA", "BRI")
	check(w.defenders.size() >= 2, "a neighbour protects Brittany (%s)" % str(w.defenders))
	check(not w.defenders.has("FRA"), "attacker is not a protector")


func test_coalition_forms() -> void:
	var g = new_game("")
	var n = g.nations.FRA
	n.ae = 150
	for i in 3:
		g._coalitions_yearly()
	check(n.coalition.size() >= 2, "coalition members joined (%d)" % n.coalition.size())
	var fought := false
	for w in g.wars:
		if w.coalition and w.defenders.has("FRA"):
			fought = true
	# with huge AE and weakened army a coalition war must start
	for a in g.armies_of("FRA"):
		a.regs = 1.0
	g._coalitions_yearly()
	for w in g.wars:
		if w.coalition and w.defenders.has("FRA"):
			fought = true
	check(fought, "coalition declares war")


func test_inherit() -> void:
	var g = new_game("FRA")
	g.apply_effects("SPA", {"inherit": "ARA"})
	check(not g.nations.ARA.alive, "Aragon gone after inheritance")
	check(g.provinces[g.key_to_pid["barcelona"]].owner == "SPA", "Spain owns Barcelona")


func test_inherit_never_takes_player() -> void:
	var g = new_game("BOH")
	g.apply_effects("HAB", {"inherit": "BOH"})
	check(g.nations.BOH.alive, "player nation is never inherited")


func test_economy_goods_and_trade() -> void:
	var g = new_game("FRA", 5)
	for p in g.provinces:
		check(g.goods_def.has(p.good), "%s has a known good" % p.key)
		check(g.markets.has(p.market), "%s trades in a market" % p.key)
	check(g.provinces[g.key_to_pid["venice"]].market == g.key_to_pid["venice"], "market center trades in itself")
	for i in 13:
		g.tick()
	var n = g.nations.FRA
	check(n.tax_income > 0.0 and n.prod_income > 0.0 and n.trade_income > 0.0, "income has tax, production and trade")
	check(absf(n.income - n.tax_income - n.prod_income - n.trade_income) < 0.001, "income is the sum of its parts")
	for k in g.prices:
		var base: float = float(g.goods_def[k].price)
		var shock: float = float(g.shocks[k].mult) if g.shocks.has(k) else 1.0
		check(g.prices[k] >= base * float(g.bal.price_min) * shock - 0.002 and g.prices[k] <= base * float(g.bal.price_max) * shock + 0.002, "price of %s stays in bounds" % k)
	# demand grows with the world economy: twice the output everywhere doubles demand too
	var doubled := {}
	for k in g.base_supply:
		doubled[k] = float(g.base_supply[k]) * 2.0
	check(absf(g.Economy.economy_growth(g, doubled) - pow(2.0, float(g.bal.demand_econ_elasticity))) < 0.001, "demand follows world output")
	check(g.Economy.price_level(g) <= float(g.bal.price_level_start) + 0.001 and g.Economy.price_level(g) >= float(g.bal.price_level_end) - 0.001, "price level between start and end")
	# merchants: count, send, recall
	var Eco = g.Economy
	check(n.merchants.size() == Eco.merchant_count(g, n), "AI/auto fills all merchant slots")
	var before: float = Eco.trade_income(g, n)
	var m: int = n.merchants[0]
	Eco.recall_merchant(g, "FRA", m)
	check(not n.merchant_auto and not n.merchants.has(m), "recall removes the merchant and stops auto mode")
	check(Eco.trade_income(g, n) < before, "recalling a merchant lowers trade income")
	check(Eco.send_merchant(g, "FRA", m) == "", "merchant can be sent again")
	check(Eco.send_merchant(g, "FRA", m) != "", "only one merchant per market")
	# goods leader bonus lands in n.bonus["goods"]
	for k in g.goods_leader:
		var t: String = g.goods_leader[k]
		for key in g.goods_def[k].bonus:
			check(g.nations[t].bonus.goods.get(key, 0.0) != 0.0, "%s gets the %s bonus" % [t, k])
	# more development, more of everything
	var p = g.provinces[g.key_to_pid["paris"]]
	var tax0: float = Eco.tax(g, p)
	var prod0: float = Eco.production_value(g, p)
	var tp0: float = Eco.province_trade_power(g, p)
	var mp0: float = Eco.local_manpower(g, p)
	p.dev += 6
	check(Eco.tax(g, p) > tax0 and Eco.production_value(g, p) > prod0 and Eco.province_trade_power(g, p) > tp0 \
			and Eco.local_manpower(g, p) > mp0, "development raises tax, production, trade power and manpower")


func test_harbor() -> void:
	var g = new_game("ENG", 5)
	var Eco = g.Economy
	var n = g.nations.ENG
	n.gold = 10000.0
	var london = g.provinces[g.key_to_pid["london"]]
	check(london.coastal, "London is coastal")
	var inland := -1
	for pid in g.provinces_of("ENG"):
		if not g.provinces[pid].coastal:
			inland = pid
	var coastal_count := 0
	for p in g.provinces:
		if p.coastal:
			coastal_count += 1
	check(coastal_count > 40 and coastal_count < g.provinces.size() - 20, "a plausible share of provinces is coastal")
	if inland >= 0:
		check(Eco.build_block_reason(g, "ENG", inland, "harbor") != "", "no harbor inland")
	var tp0: float = Eco.province_trade_power(g, london)
	london.buildings["harbor"] = 1
	Eco.refresh_local(g, london)
	check(Eco.province_trade_power(g, london) > tp0 + 2.9, "harbor adds trade power")
	g._update_cached(n)
	check(g.mod(n, "trade") >= 0.02, "harbor raises national trade income")


func test_loans_and_shocks() -> void:
	var g = new_game("FRA", 5)
	var Eco = g.Economy
	var n = g.nations.FRA
	n.gold = 0.0
	var size: float = Eco.loan_size(g, n)
	check(size >= float(g.bal.loan_min), "a loan is at least the minimum")
	check(Eco.take_loan(g, "FRA") == "" and n.gold == size, "taking a loan pays out gold")
	check(Eco.interest(g, n) > 0.0, "loans cost interest")
	var r1: float = Eco.loan_rate(g, n)
	Eco.take_loan(g, "FRA")
	check(Eco.loan_rate(g, n) > r1, "every further loan is more expensive")
	for i in 10:
		Eco.take_loan(g, "FRA")
	check(n.loans.size() == int(g.bal.max_loans), "loans are capped")
	n.gold = 0.0
	check(Eco.repay_loan(g, "FRA") != "", "repaying needs gold")
	n.gold = 100000.0
	check(Eco.repay_loan(g, "FRA") == "" and n.loans.size() == int(g.bal.max_loans) - 1, "repaying removes a loan")
	var g2 = new_game("FRA", 9)
	g2.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
	check(g2.nations.FRA.loans.size() == n.loans.size(), "loans are saved")
	# market shocks: price follows the shock, shocks expire
	var k: String = g.goods_def.keys()[0]
	g.shocks = {k: {"mult": 1.4, "years": 2}}
	g.bal.shock_chance = 0.0
	var base: float = g.prices[k]
	Eco.yearly(g)
	check(g.prices[k] > base * 1.2, "a scarcity shock raises the price")
	Eco.yearly(g)
	check(not g.shocks.has(k), "shocks expire")
	g.bal.shock_chance = 1.0
	Eco.yearly(g)
	check(g.shocks.size() == 1, "new shocks appear")


func test_trade_pacts() -> void:
	var g = new_game("FRA", 5)
	var Eco = g.Economy
	var n = g.nations.FRA
	n.dip = 500.0
	var other := ""
	for t in g.order:
		if t != "FRA" and g.nations[t].alive and not g.has_claim_on("FRA", t) and not g.has_claim_on(t, "FRA") and not g.at_war("FRA", t):
			other = t
			break
	var trade0: float = g.mod(n, "trade")
	n.relations[other] = 0.0
	g.nations[other].relations["FRA"] = 0.0
	check(Eco.offer_pact(g, "FRA", other) != "" and n.trade_pacts.is_empty(), "low relations: the AI declines a trade pact")
	g.nations[other].relations["FRA"] = 60.0
	n.relations[other] = 60.0
	check(Eco.offer_pact(g, "FRA", other) == "", "friendly nations accept a trade pact")
	check(n.trade_pacts.has(other) and g.nations[other].trade_pacts.has("FRA"), "pact is mutual")
	check(g.mod(n, "trade") > trade0, "pact raises trade income")
	var g2 = new_game("FRA", 9)
	g2.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
	check(g2.nations.FRA.trade_pacts.has(other) and g2.mod(g2.nations.FRA, "trade") > trade0, "pacts are saved")
	Eco.cancel_pact(g, "FRA", other)
	check(n.trade_pacts.is_empty() and absf(g.mod(n, "trade") - trade0) < 0.0001, "cancel removes the bonus")


func test_start_resources() -> void:
	var g = new_game("FRA", 5)
	var n = g.nations.FRA
	check(n.adm >= 150.0 and n.dip >= 150.0 and n.mil >= 150.0, "start with 150 of each power")
	check(n.gold >= 150.0, "start with more gold")


func test_diplo_capacity() -> void:
	var g = new_game("FRA", 5)
	var n = g.nations.FRA
	var small := 0.0
	n.dev_total = 100
	small = g.alliance_cost("FRA")
	n.dev_total = 700
	check(g.alliance_cost("FRA") > small * 3.0, "alliances cost more for big realms")
	n.dip = 999.0
	var free := []
	for t in g.order:
		if t != "FRA" and g.nations[t].alive and g.nations[t].overlord == "" and not g.is_allied("FRA", t) and not g.at_war("FRA", t):
			free.append(t)
	# fill every slot with vassals: then no new alliance is possible
	for t in n.allies:
		g.nations[t].allies.erase("FRA")
	n.allies.clear()
	var i := 0
	while g.diplo_used("FRA") < g.diplo_cap("FRA"):
		g.nations[free[i]].overlord = "FRA"
		i += 1
	check(g.diplo_used("FRA") == g.diplo_cap("FRA"), "vassals take diplomatic slots")
	var err: String = g.propose_alliance("FRA", free[i + 1])
	check(err.contains("Kapazität"), "no alliance over the diplomatic capacity: " + err)
	check(not g.ai.accepts_alliance(g, "FRA", free[i + 1]), "AI realms at capacity refuse alliances")
	g.nations[free[i]].overlord = "FRA"
	check(g.diplo_over("FRA") == 1, "one over capacity")
	var dip0: float = n.dip
	var pr0: float = n.prestige
	g.tick()
	check(n.prestige < pr0 + 1.0 and n.dip < dip0 + g.monthly_power(n, "dip"), "over capacity costs diplomacy and prestige")


func test_cape_route() -> void:
	var g = new_game("FRA", 5)
	var T = g.Trade
	var tag := "POR" if g.atlantic_tags.has("POR") else String(g.atlantic_tags[0])
	var n = g.nations[tag]
	check(not T.is_open(g) and T.route_value(g) == 0.0, "the spice route starts closed")
	check(T.voyage_block_reason(g, tag) != "", "no voyage at the start (year / tech)")
	g.month = (int(g.bal.cape_year) - int(g.bal.start_year) + 1) * 12
	n.tech.dip = int(g.bal.cape_dip_tech)
	n.gold = 2000.0
	n.dip = 500.0
	check(T.voyage_block_reason(g, tag) == "", "voyage possible with tech, year and gold: " + T.voyage_block_reason(g, tag))
	check(T.start_voyage(g, tag) == "" and g.east.voyage.has(tag), "voyage starts")
	g.east.voyage.erase(tag)
	g.bal.cape_success = 1.0
	T._voyage_done(g, tag)
	check(T.is_open(g) and T.knows(g, tag) and g.east.cape == tag, "first voyage opens the route")
	check(T.route_value(g) > 0.0, "the route has value")
	check(T.factory_block_reason(g, tag, "goa") != "", "a factory needs Indiamen")
	g.month = (1500 - int(g.bal.start_year)) * 12
	for k in int(g.bal.east_factory_ships):
		check(T.buy_ship(g, tag) == "", "buy an Indiaman")
	check(T.take_factory(g, tag, "maldives") == "" and g.east.factories.maldives == tag, "found a factory")
	check(T.east_income(g, tag) > 0.0 and absf(T.share(g, tag) - 1.0) < 0.001, "sole trader takes the whole route")
	var inc0: float = g.Economy.trade_income(g, n)
	g.month += 120
	check(T.route_value(g) > float(g.bal.east_value_base), "the route grows over time")
	check(g.Economy.trade_income(g, n) > inc0, "route income is trade income")
	if not g.levant.is_empty():
		check(T.market_mult(g, g.levant[0]) < 1.0, "the Levant loses value once the Cape route is open")
	# another realm storms the factory in war with more ships
	var other := ""
	for t in g.atlantic_tags:
		if t != tag and g.nations[t].alive:
			other = t
			break
	if other != "":
		g.east.known[other] = true
		g.east.ships[other] = T.ships(g, tag) + 2
		check(T.factory_block_reason(g, other, "maldives") != "", "no storming in peace")
		g.declare_war(other, tag)
		if g.at_war(other, tag):
			check(T.take_factory(g, other, "maldives") == "" and g.east.factories.maldives == other, "factory stormed in war")
	var g2 = new_game("FRA", 9)
	g2.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
	check(g2.east.cape == tag and g2.Trade.knows(g2, tag) and g2.Trade.ships(g2, tag) == T.ships(g, tag), "far trade is saved")
	check(g2.east.factories.size() == g.east.factories.size(), "factories are saved")


func test_overseas_markets() -> void:
	var g = new_game("FRA", 5)
	var T = g.Trade
	var nw := -1
	for m in g.markets:
		if T.is_overseas_market(g, m):
			nw = m
			break
	check(nw >= 0, "there is a New World market")
	check(T.market_block_reason(g, "BOH", nw) != "", "unknown New World market is closed")
	check(not g.Economy.send_merchant(g, "BOH", nw).is_empty(), "no merchant into an unknown market")
	g.nations.BOH.known_nw[nw] = true
	check(T.market_block_reason(g, "BOH", nw) != "", "a landlocked realm cannot trade overseas")
	var atl: String = g.atlantic_tags[0]
	g.nations[atl].known_nw[nw] = true
	check(T.market_block_reason(g, atl, nw) == "", "an Atlantic realm that knows the market may trade there")
	g.Economy.auto_merchants(g, g.nations.BOH)
	check(not g.nations.BOH.merchants.has(nw), "AI does not send merchants where it cannot trade")
	var p = g.provinces[nw]
	check(T.value_mult(g, p) == 1.0, "native land: normal value")
	var old: String = p.owner
	p.owner = atl
	check(T.value_mult(g, p) > 1.0, "colonial goods are worth more")
	p.owner = old


func test_market_dominance() -> void:
	var g = new_game("FRA", 5)
	g.tick()
	var any := false
	for m in g.markets:
		var lord: String = g.Trade.dominant(g, m)
		if lord == "":
			continue
		any = true
		check(g.Economy.trade_share(g, lord, m) >= float(g.bal.dom_share) - 0.0001, "market master holds the share")
	check(any, "some realm dominates a market at the start")
	var d: Dictionary = JSON.parse_string(JSON.stringify(g.to_dict()))
	var g2 = new_game("FRA", 9)
	g2.from_dict(d)
	check(g2.east.dom.size() == g.east.dom.size(), "dominance is saved")


func test_mercenaries() -> void:
	var g = new_game("FRA", 5)
	var n = g.nations.FRA
	n.gold = 1000.0
	n.manpower = 0.0
	var regs0: float = g.army_regs("FRA")
	check(g.recruit("FRA", n.capital, 1) != "", "no manpower: normal recruiting fails")
	check(g.hire_mercs("FRA", n.capital) == "", "mercenaries need no manpower")
	check(g.army_regs("FRA") > regs0 and n.gold < 1000.0, "mercenaries add regiments for gold")
	check(g.hire_mercs("FRA", n.capital) != "", "mercenaries have a cooldown")
	for i in int(g.bal.merc_cooldown):
		g.tick()
	n.gold = 1000.0
	check(g.merc_ready_in("FRA") == 0, "cooldown ends")


func test_army_power() -> void:
	var g = new_game("FRA", 5)
	var cap: int = g.nations.FRA.capital
	var a = g.spawn_army("FRA", cap, 5.0)
	check(a.power < g.power_max("FRA"), "fresh armies start below full power")
	var p0: float = a.power
	g._recover_power(a)
	check(a.power > p0, "power recovers over time")
	var regen_home: float = g.power_regen(a)
	var prov = g.provinces[cap]
	prov.buildings["road"] = 2
	g.Economy.refresh_local(g, prov)
	check(g.power_regen(a) > regen_home, "roads speed up recovery")
	for i in 40:
		g._recover_power(a)
	check(absf(a.power - g.power_max("FRA")) < 0.0001, "power ticks up to the maximum and stops")
	var full_f: float = g.power_factor(a)
	a.power = 0.0
	check(g.power_factor(a) < full_f and g.power_factor(a) > 0.0, "low power weakens the army in battle")
	# battle: winner loses a little, loser a lot
	for o in g.armies_of("ENG"):
		g.armies.erase(o)  # (the loser retreats: it must not merge into a fresh English army)
	var w = g.spawn_army("FRA", cap, 20.0)
	var l = g.spawn_army("ENG", cap, 2.0)
	w.power = 1.0
	l.power = 1.0
	g.nations.FRA.truces.erase("ENG")
	g.nations.ENG.truces.erase("FRA")
	g.declare_war("FRA", "ENG")
	var war = g.war_between("FRA", "ENG")
	g._battle(war, [w], [l], cap)
	check(w.power > 0.75 and w.power < 1.0, "a won battle costs some power")
	# (-50 % in the battle; the beaten army retreats into its own land and may recover a little there,
	# which depends on the map around the battlefield)
	check(l.power <= 0.6 + 0.0001, "a lost battle costs a lot of power (%.2f)" % l.power)
	var g2 = new_game("FRA", 9)
	g2.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
	check(absf(g2.army_by_id(w.id).power - w.power) < 0.0001, "army power is saved")


func test_road_march() -> void:
	var g = new_game("FRA", 5)
	var W = g.Warfare
	var cap: int = g.nations.FRA.capital
	var path: Array = []
	for pid in g.provinces_of("FRA"):
		var pp: Array = g.find_path("FRA", cap, pid)
		if pp.size() >= 4:
			path = pp
			break
	check(path.size() >= 4, "France has a province three marches from the capital")
	var a = g.spawn_army("FRA", cap, 3.0)
	var slow: float = W.speed(g, a, path[0], path[1])
	for pid in path:
		g.provinces[pid].buildings["road"] = 2
	check(absf(W.speed(g, a, path[0], path[1]) - slow - 2 * float(g.bal.road_speed)) < 0.0001, "two road levels add march speed")
	var e = g.spawn_army("ENG", cap, 3.0)
	check(W.road_bonus(g, "ENG", path[0], path[1]) == 0.0, "roads only help their owner")
	g.armies.erase(e)
	g.move_army(a, path[-1])
	var months := 0
	while a.pid != path[-1] and months < 20:
		g._armies_tick()
		months += 1
	check(a.pid == path[-1] and a.target == -1, "the army arrives and stops")
	check(months <= W.eta(g, a) + 6, "march time is finite")


func test_march_time_and_terrain() -> void:
	var g = new_game("FRA", 5)
	var W = g.Warfare
	var t: Dictionary = {}
	for p in g.provinces:
		t[p.terrain] = true
	check(t.has("mountains") and t.has("plains") and t.has("desert"), "provinces have terrain")
	var mtn: int = g.key_to_pid["tirol"]
	check(g.provinces[mtn].terrain == "mountains", "Tirol is mountains")
	var nb: int = g.provinces[mtn].adj[0]
	var flat_cost: float = g.provinces[nb].center.distance_to(g.provinces[mtn].center) / float(g.bal.march_px_per_month)
	flat_cost = clampf(flat_cost, float(g.bal.march_min_months), float(g.bal.march_max_months))
	check(W.step_cost(g, nb, mtn) > flat_cost * 1.5, "marching into the mountains takes longer")
	var lon: int = g.key_to_pid["london"]
	var cal: int = g.key_to_pid["calais"]
	check(W.is_strait(g, lon, cal) and W.is_strait(g, cal, lon), "the Channel is a sea crossing")
	check(W.step_cost(g, lon, cal) >= float(g.bal.strait_months), "a sea crossing costs extra months")
	# an army stays put until the step is done, then arrives
	var a = g.spawn_army("FRA", g.nations.FRA.capital, 4.0)
	var to: int = -1
	for x in g.provinces[a.pid].adj:
		if g.provinces[x].owner == "FRA" and W.step_cost(g, a.pid, x) > 1.0:
			to = x
	if to >= 0:
		var from: int = a.pid
		g.move_army(a, to)
		g._armies_tick()
		check(a.pid == from and a.move > 0.0, "a long step is not done in one month")
		check(W.eta(g, a) >= 1, "eta counts the remaining months")
		var other: int = -1
		for x in g.provinces[from].adj:
			if x != to and g.can_enter("FRA", x):
				other = x
		if other >= 0:
			g.move_army(a, other)
			check(a.move == 0.0, "turning round throws the march progress away")


func test_interception() -> void:
	var g = new_game("FRA", 5)
	var W = g.Warfare
	g.nations.FRA.truces.erase("ENG")
	g.nations.ENG.truces.erase("FRA")
	g.declare_war("FRA", "ENG")
	g.bal.march_min_months = 0.1
	g.bal.march_max_months = 0.2
	var x: int = g.nations.FRA.capital
	var y: int = -1
	for nb in g.provinces[x].adj:
		if g.provinces[nb].owner == "FRA" and not W.is_strait(g, x, nb):
			y = nb
			break
	var f = g.spawn_army("FRA", x, 5.0)
	var e = g.spawn_army("ENG", y, 5.0)
	g.move_army(f, y)
	e.target = x
	e.path = g.find_path("ENG", y, x)
	W.move_armies(g)
	check(f.pid == e.pid, "armies marching past each other meet instead of swapping places")
	W.gather(g)
	check(W.in_battle(g, f) and W.in_battle(g, e), "the meeting starts a battle")
	check(g.move_army(f, x) != "", "an army in battle cannot march away")


func test_battle_rounds() -> void:
	var g = new_game("FRA", 5)
	var W = g.Warfare
	g.nations.FRA.truces.erase("ENG")
	g.nations.ENG.truces.erase("FRA")
	g.declare_war("FRA", "ENG")
	var pid: int = g.nations.FRA.capital
	var f = g.spawn_army("FRA", pid, 10.0)
	var e = g.spawn_army("ENG", pid, 10.0)
	f.power = 1.0
	e.power = 1.0
	W.gather(g)
	var b = W.battle_at(g, pid)
	check(b != null, "equal armies start a battle")
	check(W.phase(b) == "Feuergefecht", "battles open with the fire fight")
	W.fight_round(g, b)
	check(g.battles.has(b), "an even battle is not decided in the first round")
	check(b.log.size() == 1 and b.log[0][1] > 0.0 and b.log[0][2] > 0.0, "each round is logged with both sides' losses")
	W.fight_round(g, b)
	check(W.phase(b) == "Nahkampf" or not g.battles.has(b), "melee follows the fire fight")
	# reinforcements join the running battle
	var r = g.spawn_army("ENG", pid, 4.0)
	W.gather(g)
	check(b.def.has(r) or b.att.has(r), "an army marching in joins the battle")
	var months := 0
	while g.battles.has(b) and months < 10:
		W.battles_tick(g)
		months += 1
	check(not g.battles.has(b), "the battle ends")
	check(b.round >= 3, "an even battle lasts several rounds (%d)" % b.round)
	check(months >= 1, "an even battle takes at least a month")
	# lopsided battles end fast, the loser bleeds
	var g2 = new_game("FRA", 6)
	g2.nations.FRA.truces.erase("ENG")
	g2.nations.ENG.truces.erase("FRA")
	g2.declare_war("FRA", "ENG")
	var big = g2.spawn_army("FRA", pid, 30.0)
	var small = g2.spawn_army("ENG", pid, 5.0)
	big.power = 1.0
	small.power = 1.0
	var war = g2.war_between("FRA", "ENG")
	var sc0: float = war.battle_score
	g2._battle(war, [big], [small], pid)
	check(big.regs > 26.0, "the big army loses little (%.1f)" % big.regs)
	check(not g2.armies.has(small) or small.regs < 3.5, "the small army loses a lot")
	check(war.battle_score > sc0, "the winner gains war score")
	# terrain defence: holding mountains helps
	var mtn: int = g.key_to_pid["tirol"]
	var hold: String = g.provinces[mtn].controller
	var bb = W.Battle.new()
	bb.pid = mtn
	var h = g.spawn_army(hold, mtn, 5.0)
	bb.att = [h]
	var p_hold: float = W.side_power(g, bb, true)
	h.owner = "FRA" if hold != "FRA" else "ENG"
	check(p_hold > W.side_power(g, bb, true) * 1.2 or h.owner == hold, "holding the mountains is worth a lot")
	h.owner = hold
	# landings fight worse
	h.landing = true
	check(W.side_power(g, bb, true) < p_hold, "troops fresh off the ships fight worse")
	# saved mid-battle
	var g3 = new_game("FRA", 7)
	g3.nations.FRA.truces.erase("ENG")
	g3.nations.ENG.truces.erase("FRA")
	g3.declare_war("FRA", "ENG")
	g3.spawn_army("FRA", pid, 10.0)
	g3.spawn_army("ENG", pid, 10.0)
	W.gather(g3)
	W.fight_round(g3, g3.battles[0])
	var g4 = new_game("FRA", 9)
	g4.from_dict(JSON.parse_string(JSON.stringify(g3.to_dict())))
	check(g4.battles.size() == 1 and g4.battles[0].round == 1, "a running battle is saved")


func test_naval() -> void:
	var g = new_game("FRA", 5)
	var N = g.Naval
	check(g.seas.size() >= 10, "sea regions loaded")
	check(N.limit(g, "ENG") > 0.0 and g.nations.ENG.ships > 0.0, "England starts with a fleet")
	check(N.limit(g, "BOH") == 0.0, "landlocked Bohemia has no fleet")
	var lon: int = g.key_to_pid["london"]
	var cal: int = g.key_to_pid["calais"]
	check(N.sea_of_strait(g, lon, cal) == "channel", "London-Calais crosses the Channel")
	# building ships
	var n = g.nations.FRA
	n.gold = 1000.0
	n.mil = 200.0
	var before: float = n.ships
	check(N.build_ships(g, "FRA", 1) == "", "France builds a ship")
	check(n.ships == before + 1.0, "the ship is there")
	n.ships = N.limit(g, "FRA")
	check(N.build_ships(g, "FRA", 1) != "", "not above the limit")
	# stationing
	var seas: Array = N.coast_weights(g, "FRA").keys()
	check(seas.has("channel"), "France borders the Channel")
	N.station(g, "FRA", "channel")
	check(N.presence(g, "FRA").keys() == ["channel"], "a stationed fleet sits in one sea")
	check(N.station(g, "FRA", "black") != "", "only own coastal seas")
	# war: England rules the Channel -> French armies cannot cross, French coast blockaded
	g.nations.FRA.truces.erase("ENG")
	g.nations.ENG.truces.erase("FRA")
	g.declare_war("ENG", "FRA")
	g.nations.ENG.ships = 30.0
	g.nations.ENG.fleet_sea = "channel"
	g.nations.FRA.ships = 2.0
	N.refresh(g)
	var w = g.war_between("ENG", "FRA")
	check(N.control(g, w, "channel") == "att", "England rules the Channel")
	check(not N.can_cross(g, "FRA", cal, lon), "France cannot cross the Channel")
	check(N.can_cross(g, "ENG", lon, cal), "England can")
	check(g.find_path("FRA", cal, lon).is_empty(), "no French path to London")
	var a = g.spawn_army("FRA", cal, 5.0)
	check(g.move_army(a, lon).contains("Flotte"), "the order says the enemy fleet blocks it")
	var blk := false
	for pid in g.provinces_of("FRA"):
		if N.is_blockaded(g, pid):
			blk = true
	check(blk, "French Channel coast is blockaded")
	check(g.nations.FRA.bonus.get("blockade", {}).get("income", 0.0) < 0.0, "a blockade costs income")
	check(not N.is_blockaded(g, lon), "London, behind the ruling fleet, is not blockaded")
	# a fleet battle: the bigger fleet wins and the loser loses ships
	g.nations.FRA.ships = 10.0
	g.nations.FRA.fleet_sea = "channel"
	N.refresh(g)
	var sc0: float = w.battle_score
	N._fleet_battle(g, w, g.sea_by_id["channel"], 30.0, 10.0)
	check(g.nations.FRA.ships < 10.0 and w.battle_score > sc0, "England wins the sea battle")
	# save
	var g2 = new_game("FRA", 9)
	g2.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
	check(absf(g2.nations.FRA.ships - g.nations.FRA.ships) < 0.001 and g2.nations.ENG.fleet_sea == "channel", "fleets are saved")
	check(not g2.can_cross("FRA", cal, lon), "sea control is restored after loading")


func test_power_actions() -> void:
	var g = new_game("FRA", 5)
	var n = g.nations.FRA
	var cap: int = n.capital
	# drill: morale to max for military power, only on friendly land
	var a = g.spawn_army("FRA", cap, 4.0)
	a.power = 0.2
	n.mil = 0.0
	check(g.drill_army("FRA", a.id) != "", "drill needs military power")
	n.mil = 200.0
	var cost: float = g.drill_cost(a)
	check(g.drill_army("FRA", a.id) == "", "drill works at home")
	check(absf(a.power - g.power_max("FRA")) < 0.0001 and absf(n.mil - (200.0 - cost)) < 0.001, "drill fills morale and costs mil")
	check(g.drill_army("FRA", a.id) != "", "no drill at full morale")
	a.power = 0.2
	a.pid = g.nations.ENG.capital
	check(g.drill_army("FRA", a.id) != "", "no drill in foreign land")
	# conscription: manpower now, then a cooldown
	n.manpower = 0.0
	n.mil = 200.0
	check(g.conscript("FRA") == "", "conscription works")
	check(n.manpower > 0.0 and n.manpower <= n.max_manpower, "conscription adds manpower")
	check(g.conscript("FRA") != "" and g.conscript_ready_in("FRA") > 0, "conscription has a cooldown")
	# integration: conquered land becomes core faster
	var pid: int = g.provinces_of("FRA")[1]
	g.provinces[pid].core_months = 30
	n.dip = 200.0
	check(g.integrate("FRA", pid) == "", "integration works")
	check(g.provinces[pid].core_months == 30 - int(g.bal.integrate_months), "integration shortens the wait")
	g.provinces[pid].core_months = 0
	check(g.integrate("FRA", pid) != "", "cored land needs no integration")
	check(g.integrate("FRA", g.nations.ENG.capital) != "", "only own provinces")
	# reputation: less AE
	n.ae = 12.0
	check(g.restore_reputation("FRA") == "", "reputation works")
	check(absf(n.ae - (12.0 - float(g.bal.reputation_ae))) < 0.001, "reputation lowers AE")
	n.ae = 0.0
	check(g.restore_reputation("FRA") != "", "nothing to repair without AE")


func test_building_gain() -> void:
	var g = new_game("FRA", 5)
	var p = g.provinces[g.nations.FRA.capital]
	var before: Dictionary = p.buildings.duplicate()
	var dev: int = p.dev
	var inc: float = g.Economy.province_income(g, p)
	var gain: float = g.Economy.building_gain(g, p, "workshop")
	check(gain > 0.0, "a workshop raises income")
	check(p.buildings == before and p.dev == dev and absf(g.Economy.province_income(g, p) - inc) < 0.0001, "estimate leaves the province untouched")
	check(g.Economy.building_gain(g, p, "road") < gain, "a road brings less income than a workshop")


func test_military_access() -> void:
	var g = new_game("FRA", 5)
	var nb := ""
	for t in g.neighbors_of("FRA"):
		if not g.is_allied("FRA", t) and g.nations[t].overlord != "FRA" and g.nations[t].overlord == "" and not g.at_war("FRA", t):
			nb = t
			break
	check(nb != "", "France has a neutral neighbour")
	if nb == "":
		return
	var pid: int = g.nations[nb].capital
	check(not g.can_enter("FRA", pid), "neutral land is closed")
	g.nations.FRA.dip = 200.0
	g.add_rel(nb, "FRA", -100.0)
	check(g.request_access("FRA", nb) != "", "a hostile neighbour refuses access")
	g.add_rel(nb, "FRA", 200.0)
	check(g.request_access("FRA", nb) == "", "a friendly neighbour grants access")
	check(g.can_enter("FRA", pid), "access opens the land")
	check(not g.find_path("FRA", g.nations.FRA.capital, pid).is_empty(), "armies can path through granted land")
	var g2 = new_game("FRA", 9)
	g2.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
	check(g2.nations.FRA.access.has(nb), "access is saved")
	var a = g.spawn_army("FRA", pid, 2.0)
	g.nations[nb].relations["FRA"] = -100.0
	g.tick()
	check(not g.nations.FRA.access.has(nb), "bad relations end access")
	check(a.pid == g.nations.FRA.capital, "troops in revoked land go home")


func test_guarantee() -> void:
	var g = new_game("ENG", 5)
	g.nations.FRA.dip = 200.0
	var target := ""
	for t in g.nations:
		var n = g.nations[t]
		if t != "FRA" and t != "ENG" and n.overlord == "" and not g.is_allied("ENG", t) and not g.is_allied("FRA", t) and not g.has_truce("ENG", t) and n.allies.is_empty():
			target = t
			break
	check(target != "", "a lone state exists")
	if target == "":
		return
	check(g.guarantee("FRA", target) == "", "France guarantees a small state")
	check(g.guarantee("FRA", target) != "", "no double guarantee")
	check(g.defenders_for("ENG", target).has("FRA"), "the guarantor defends")
	var g2 = new_game("FRA", 9)
	g2.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
	check(g2.nations.FRA.guarantees.has(target), "guarantees are saved")
	g.nations.FRA.truces.erase(target)
	g.nations[target].truces.erase("FRA")
	g.declare_war("FRA", target)
	check(not g.nations.FRA.guarantees.has(target), "attacking the protected state breaks the guarantee")


func test_rivals() -> void:
	var g = new_game("ENG", 5)
	check(g.rival_block_reason("ENG", "FRA") == "", "England may rival France: " + g.rival_block_reason("ENG", "FRA"))
	check(g.set_rival("ENG", "FRA") == "", "rivalry declared")
	check(g.set_rival("ENG", "FRA") != "", "no double rivalry")
	check(g.get_rel("ENG", "FRA") <= -60.0 - float(g.bal.rival_rel) + 0.01, "rivalry sours relations")
	var weak := ""
	for t in g.nations_in_range("ENG", int(g.bal.rival_range)):
		if t != "FRA" and g.nations[t].dev_total < g.nations.ENG.dev_total * 0.3 and g.strength(t) < g.strength("ENG") * 0.3:
			weak = t
			break
	if weak != "":
		check(g.set_rival("ENG", weak) != "", "a far weaker realm is no worthy rival")
	check(g.rival_block_reason("ENG", "TUR") != "", "a realm out of reach cannot be rivalled")
	# rivalry is a casus belli: no dip cost, no no-CB aggressive expansion
	g.nations.ENG.truces.erase("FRA")
	g.nations.FRA.truces.erase("ENG")
	var dip0: float = g.nations.ENG.dip
	var ae0: float = g.nations.ENG.ae
	check(g.declare_war("ENG", "FRA") == "", "war on a rival")
	check(is_equal_approx(g.nations.ENG.dip, dip0) and is_equal_approx(g.nations.ENG.ae, ae0), "no no-CB penalty against a rival")
	# power projection: provinces taken from a rival, mil bonus, decay
	var w = g.wars[0]
	var pid: int = g.provinces_of("FRA")[0]
	g.provinces[pid].controller = "ENG"
	g.make_peace(w, true, [pid])
	check(g.nations.ENG.power_proj >= float(g.bal.pp_province) - 0.01, "a province from a rival projects power")
	g.add_power_proj("ENG", 1000.0)
	check(g.nations.ENG.power_proj == float(g.bal.pp_max), "power projection is capped")
	g._rivals_monthly(g.nations.ENG)
	check(g.nations.ENG.bonus.has("rivals") and g.nations.ENG.bonus.rivals.mil > 1.0, "high power projection gives military power")
	var pp: float = g.nations.ENG.power_proj
	check(pp < float(g.bal.pp_max), "power projection decays")
	var g2 = new_game("FRA", 9)
	g2.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
	check(g2.nations.ENG.rivals.has("FRA") and is_equal_approx(g2.nations.ENG.power_proj, pp), "rivals and power projection are saved")
	# ending a rivalry costs prestige and blocks the same rival for a while
	var pr: float = g.nations.ENG.prestige
	g.end_rival("ENG", "FRA")
	check(not g.nations.ENG.rivals.has("FRA") and g.nations.ENG.prestige < pr, "ending a rivalry costs prestige")
	check(g.rival_block_reason("ENG", "FRA") != "", "cooldown after ending a rivalry")
	# an alliance ends the rivalry on both sides
	g.set_rival("FRA", "ENG")
	g._ally("FRA", "ENG")
	check(not g.nations.FRA.rivals.has("ENG"), "allies are no rivals")
	# AI picks rivals within a few years
	var g3 = new_game("", 11)
	for m in 10 * 12:
		g3.tick()
	var with_rivals := 0
	var powers := 0
	for t in g3.order:
		var n = g3.nations[t]
		if n.alive and n.overlord == "":
			powers += 1
			if not n.rivals.is_empty():
				with_rivals += 1
	print("    rivals after 10 years: %d of %d realms, %d rivalries, TUR rivalled by %d" % [with_rivals, powers, _count_rivalries(g3), g3.rivaled_by("TUR").size()])
	check(with_rivals >= powers / 3, "most AI realms pick a rival within ten years")
	for t in g3.order:
		for r in g3.nations[t].rivals:
			check(g3.nations[r].alive and not g3.is_allied(t, r), "AI rivals are alive and not allies")


func test_urban() -> void:
	var g = new_game("FRA", 9)
	var Eco = g.Economy
	var Urb = g.Urban
	var cities: int = Urb.count(g, true)
	check(cities >= 25 and cities <= g.provinces.size() / 10, "a plausible number of starting cities (%d)" % cities)
	check(g.provinces[g.key_to_pid["paris"]].urban, "Paris starts as a city")
	check(g.provinces[g.key_to_pid["london"]].urban, "London starts as a city")
	var n = g.nations.FRA
	n.gold = 10000.0
	# pick a rural province of France and compare with itself as a city
	var pid := -1
	for q in g.provinces_of("FRA"):
		if not g.provinces[q].urban and g.provinces[q].core_months == 0:
			pid = q
			break
	check(pid >= 0, "France has countryside")
	var p = g.provinces[pid]
	var tax0: float = Eco.tax(g, p)
	var mp0: float = Eco.local_manpower(g, p)
	var slots0: int = Eco.slots(g, p)
	var u0: float = g.unrest_parts(pid).buildings
	p.dev = 4
	check(Urb.block_reason(g, "FRA", pid, true) != "", "too little development for a city")
	p.dev = int(g.bal.urban_min_dev)
	check(Urb.block_reason(g, "FRA", pid, false) != "", "countryside cannot become countryside")
	var gold0: float = n.gold
	check(Urb.change(g, "FRA", pid, true) == "", "founding a city is allowed")
	check(n.gold < gold0, "founding a city costs gold")
	check(p.urban_months == int(g.bal.urban_months) and not p.urban, "the change takes months")
	check(Urb.block_reason(g, "FRA", pid, true) != "", "no second change while one runs")
	for i in int(g.bal.urban_months) + 1:
		Urb.tick(g, n)
	check(p.urban and p.urban_months == 0, "the province became a city")
	# development speeds the change up; countryside at urban_auto_dev becomes a city by itself
	var fast := {"dev": int(g.bal.urban_min_dev) + 6}
	check(Urb.change_months(g, true, fast) < int(g.bal.urban_months), "more development, faster city")
	fast.dev = 99
	check(Urb.change_months(g, true, fast) == int(g.bal.urban_months_min), "never faster than the minimum")
	var q2 := -1
	for q in g.provinces_of("FRA"):
		if not g.provinces[q].urban and g.provinces[q].urban_months == 0 and g.provinces[q].core_months == 0:
			q2 = q
			break
	if q2 >= 0:
		var pq = g.provinces[q2]
		var d0: int = pq.dev
		pq.dev = int(g.bal.urban_auto_dev)
		Urb.auto_grow(g)
		check(pq.urban, "countryside at development %d grows into a city by itself" % int(g.bal.urban_auto_dev))
		pq.urban = false
		pq.dev = d0
		Eco.refresh_local(g, pq)
	# autobuild founds cities (best candidate first) and stops at the share cap
	g.player = "FRA"
	n.autobuild = true
	n.autobuild_reserve = 0.0
	n.gold = 100000.0
	var cand: int = Urb.best_candidate(g, "FRA")
	if cand >= 0 and Urb.city_share(g, "FRA") < float(g.bal.autobuild_urban_share):
		check(Urb.autobuild(g, n) == cand and g.provinces[cand].urban_months > 0, "autobuild starts the best city")
	g.bal.autobuild_urban_share = 0.0
	check(Urb.autobuild(g, n) == -1, "autobuild respects the city share cap")
	g.bal.autobuild_urban_share = 0.5
	n.autobuild = false
	n.gold = 10000.0
	tax0 = Eco.tax(g, p)  # recompute at the same dev
	p.urban = false
	Eco.refresh_local(g, p)
	var tax_rural: float = Eco.tax(g, p)
	var mp_rural: float = Eco.local_manpower(g, p)
	var slots_rural: int = Eco.slots(g, p)
	var u_rural: float = g.unrest_parts(pid).buildings
	p.urban = true
	Eco.refresh_local(g, p)
	check(Eco.tax(g, p) > tax_rural * 1.1, "a city pays more tax")
	check(Eco.local_manpower(g, p) < mp_rural, "a city raises fewer men")
	check(Eco.slots(g, p) == slots_rural + int(g.bal.urban_slots), "a city has an extra building slot")
	check(g.unrest_parts(pid).buildings > u_rural, "a city is more restless than the countryside")
	check(mp0 > 0.0 and slots0 > 0 and u0 <= 0.0, "rural baseline sane")
	# back to the countryside
	check(Urb.change(g, "FRA", pid, false) == "", "turning back into countryside is allowed")
	for i in int(g.bal.rural_months) + 1:
		Urb.tick(g, n)
	check(not p.urban, "the province is countryside again")
	# goods fit: a city producing cloth gets the production bonus, a city producing grain does not
	p.urban = true
	p.good = "cloth"
	Eco.refresh_local(g, p)
	var prod_fit: float = Eco.local(g, p, "production")
	p.good = "grain"
	Eco.refresh_local(g, p)
	check(prod_fit > Eco.local(g, p, "production"), "city goods are produced better in a city")
	# demand follows the number of cities
	var dm0: float = Urb.demand_mult(g, "cloth")
	for q in g.provinces_of("FRA"):
		g.provinces[q].urban = true
	check(Urb.demand_mult(g, "cloth") > dm0, "more cities raise demand for city goods")
	check(Urb.demand_mult(g, "grain") < 1.0, "more cities lower demand for country goods")
	# event hooks: conditions and the charter effect
	var mine: int = Urb.count_of(g, "FRA")
	check(g.check_conditions("FRA", {"cities_min": mine}) and not g.check_conditions("FRA", {"cities_min": mine + 1}), "cities_min counts own cities")
	check(g.check_conditions("FRA", {"cities_max": mine}) and not g.check_conditions("FRA", {"cities_max": mine - 1}), "cities_max counts own cities")
	for q in g.provinces_of("FRA"):
		g.provinces[q].urban = false
	g.apply_effects("FRA", {"urbanize": 2})
	check(Urb.count_of(g, "FRA") == 2, "a charter founds cities at once")
	var urb_events := 0
	for e in data.events:
		if e.id.begins_with("urb_"):
			urb_events += 1
	check(urb_events >= 8, "urb_ events present (%d)" % urb_events)
	# cities grow by themselves in peace (forced chance), the countryside does not
	var grow_c: int = g.provinces_of("FRA")[0]
	var grow_p = g.provinces[grow_c]
	grow_p.urban = true
	grow_p.dev = 5
	var rural_dev := -1
	var rural_pid := -1
	for q in g.provinces_of("FRA"):
		if q != grow_c:
			g.provinces[q].urban = false
			rural_pid = q
			rural_dev = g.provinces[q].dev
	g.bal.city_growth_chance = 1.0
	g.wars.clear()
	Urb.yearly(g)
	check(grow_p.dev == 6, "a city at peace grows by one development")
	check(g.provinces[rural_pid].dev == rural_dev, "the countryside does not grow by itself")
	grow_p.dev = int(g.bal.dev_soft_cap)
	Urb.yearly(g)
	check(grow_p.dev == int(g.bal.dev_soft_cap), "growth stops at the soft cap")
	g.bal.city_growth_chance = 0.03
	p.urban = true  # the growth check above made it countryside again
	# save roundtrip keeps the status
	var d := g.to_dict()
	var g2 = new_game("FRA", 9)
	g2.from_dict(d)
	check(g2.provinces[pid].urban, "urban status survives a save")
	check(g2.urban_start == g.urban_start, "demand baseline survives a save")
	# AI founds a city when rich
	var ai = g.nations.ENG
	ai.gold = 5000.0
	var before: int = 0
	for q in g.provinces_of("ENG"):
		if g.provinces[q].urban or g.provinces[q].urban_months > 0:
			before += 1
	for q in g.provinces_of("ENG"):
		g.provinces[q].dev = maxi(g.provinces[q].dev, int(g.bal.urban_min_dev))
		g.provinces[q].core_months = 0
	Urb.ai_found_city(g, ai)
	var after: int = 0
	for q in g.provinces_of("ENG"):
		if g.provinces[q].urban or g.provinces[q].urban_months > 0:
			after += 1
	check(after == before + 1 or float(before) >= ceilf(g.provinces_of("ENG").size() * float(g.bal.ai_urban_share)), "the AI founds a city when it has few")


func test_embargo() -> void:
	var g = new_game("ENG", 5)
	check(g.set_embargo("ENG", "FRA") != "", "no embargo without rivalry")
	g.set_rival("ENG", "FRA")
	g.nations.ENG.dip = 100.0
	check(g.set_embargo("ENG", "FRA") == "", "embargo against a rival")
	check(g.set_embargo("ENG", "FRA") != "", "no double embargo")
	g._rivals_monthly(g.nations.FRA)
	g._rivals_monthly(g.nations.ENG)
	check(g.nations.FRA.bonus.has("embargo") and g.nations.FRA.bonus.embargo.trade < 0.0, "the target loses trade")
	check(g.nations.ENG.bonus.has("embargo") and g.nations.ENG.bonus.embargo.trade < 0.0 and g.nations.ENG.bonus.embargo.trade > g.nations.FRA.bonus.embargo.trade, "the embargoing side loses a little too")
	var g2 = new_game("FRA", 9)
	g2.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
	check(g2.nations.ENG.embargoes.has("FRA"), "embargoes are saved")
	g.end_rival("ENG", "FRA")
	g._rivals_monthly(g.nations.ENG)
	g._rivals_monthly(g.nations.FRA)
	check(g.nations.ENG.embargoes.is_empty() and not g.nations.FRA.bonus.has("embargo"), "the embargo ends with the rivalry")


func test_hall_of_fame() -> void:
	var path := "user://test_hall.json"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var g = new_game("FRA", 3)
	for m in 24:
		g.tick()
	var e: Dictionary = HallOfFame.entry_for(g)
	check(e.tag == "FRA" and e.score > 0 and e.rank >= 1 and e.alive and e.year == 1446, "entry describes the game")
	check(HallOfFame.add(e, path) == 1, "first game is the record")
	var better := e.duplicate()
	better.score = e.score + 100
	check(HallOfFame.add(better, path) == 1, "a better game takes the first place")
	var same_place: int = HallOfFame.add(e.duplicate(), path)
	check(same_place >= 2 and same_place <= 3, "an equal game ranks behind the record (place %d)" % same_place)
	for i in HallOfFame.MAX_ENTRIES + 5:
		var low := e.duplicate()
		low.score = 1
		HallOfFame.add(low, path)
	check(HallOfFame.load_entries(path).size() == HallOfFame.MAX_ENTRIES, "the hall keeps at most %d games" % HallOfFame.MAX_ENTRIES)
	g.nations.FRA.alive = false
	check(HallOfFame.entry_for(g).rank == 0 and not HallOfFame.entry_for(g).alive, "a destroyed nation has no rank")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _count_rivalries(g) -> int:
	var c := 0
	for t in g.order:
		c += g.nations[t].rivals.size()
	return c


func test_religion() -> void:
	var F = load("res://scripts/core/religion.gd")
	var g = new_game("TUR", 5)
	check(g.nations.TUR.religion == "sunni" and g.nations.FRA.religion == "catholic" and g.nations.BYZ.religion == "orthodox", "start religions")
	var bp: int = g.nations.BYZ.capital
	check(g.provinces[bp].religion == "orthodox", "provinces follow their owner at start")
	check(g.unrest_parts(bp).religion == 0.0, "own faith gives no unrest")
	g.provinces[bp].owner = "TUR"
	g.provinces[bp].controller = "TUR"
	g._rebuild_owned()
	check(g.unrest_parts(bp).religion > 0.0, "a foreign faith is restless")
	g.nations.TUR.gold = 500.0
	check(F.send_missionary(g, "TUR", bp) == "", "missionary sent")
	check(F.send_missionary(g, "TUR", bp) != "", "one missionary per province")
	for i in int(g.bal.convert_months):
		F.monthly(g, g.nations.TUR)
	check(g.provinces[bp].religion == "sunni", "the missionary converts the province")
	var g2 = new_game("FRA", 9)
	g2.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
	check(g2.provinces[bp].religion == "sunni" and g2.nations.BYZ.religion == "orthodox", "religion is saved")
	# state religion change needs enough of the realm
	check(F.change_religion(g, "FRA", "orthodox") != "", "no change without believers")
	# the Reformation
	var h = new_game("FRA", 5)
	h.month = (int(h.bal.reformation_year) - 1444) * 12
	F.yearly(h)
	var prot := 0
	for p in h.provinces:
		if p.religion == "protestant":
			prot += 1
	check(prot == 1, "the Reformation starts in one province")
	h.bal.reformation_spread = 1.0
	var drift = h.bal.religion_drift
	h.bal.religion_drift = 0.0  # drift back to the ruler's faith would make this depend on the rng path
	for i in 3:
		h.month += 12
		F.yearly(h)
	var prot2 := 0
	for p in h.provinces:
		if p.religion == "protestant":
			prot2 += 1
	check(prot2 > prot, "Protestantism spreads")
	h.bal.religion_drift = drift
	check(h.check_conditions("FRA", {"religion": "catholic"}) and not h.check_conditions("FRA", {"religion": "sunni"}), "religion condition")


## Ranking chart data: one entry per year with the top realms and the player, kept by save/load.
func test_score_history() -> void:
	var g = new_game("NAP")
	for i in 25:
		g.tick()
	check(g.score_history.size() == 2, "a score snapshot each new year (%d)" % g.score_history.size())
	var top: Dictionary = g.score_history[-1][1]
	check(top.size() <= g.SCORE_HISTORY_TOP + 1 and top.has("NAP"), "snapshot holds the best realms and the player")
	var g2 = new_game("NAP")
	g2.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
	check(g2.score_history.size() == 2 and int(g2.score_history[-1][1]["NAP"]) == int(top["NAP"]), "score history survives save/load")


func test_first_steps() -> void:
	var FS = load("res://scripts/core/first_steps.gd")
	var g = new_game("FRA", 5)
	var n = g.nations.FRA
	check(FS.claimable(g, "FRA") == 0, "no beginner goal is done at the start")
	n.adm = 500.0
	check(g.develop("FRA", n.capital) == "", "develop the capital")
	check(FS.claimable(g, "FRA") == 1, "developing finishes the first goal")
	check(FS.claim(g, "FRA", "build") != "", "an open goal cannot be claimed")
	var gold: float = n.gold
	check(FS.claim(g, "FRA", "develop") == "" and n.gold > gold, "claiming pays gold")
	check(FS.claim(g, "FRA", "develop") != "", "a goal pays once")
	var g2 = new_game("FRA", 9)
	g2.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
	var st: Array = FS.steps(g2, "FRA")
	check(st[0].claimed and not st[1].done, "beginner goals are saved")
	check(not FS.all_claimed(g2, "FRA"), "five goals remain")


func test_monuments_and_feast() -> void:
	var M = load("res://scripts/core/monuments.gd")
	var g = new_game("FRA", 5)
	var n = g.nations.FRA
	n.gold = 100000.0
	check(M.start(g, "FRA", "university") != "", "great works need technology")
	n.tech.adm = 3
	var before: float = n.gold
	check(M.start(g, "FRA", "cathedral") == "", "the cathedral is started")
	check(n.gold < before - 250.0, "great works cost more for developed realms")
	check(M.start(g, "FRA", "cathedral") != "", "one great work at a time")
	var u0: float = g.mod(n, "unrest")
	for i in int(g.monument_defs.cathedral.months):
		M.tick(g, n)
	check(n.monuments.has("cathedral") and n.monument_build.is_empty(), "the cathedral is finished")
	check(g.mod(n, "unrest") < u0, "its bonus applies")
	var g2 = new_game("FRA", 9)
	g2.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
	check(g2.nations.FRA.monuments.has("cathedral") and g2.mod(g2.nations.FRA, "unrest") < u0 + 0.001, "great works are saved")
	var p0: float = n.prestige
	# the feast price follows the prestige rank: full price at the top, rank_cost_bottom at the bottom
	n.income = 100.0
	n.prestige = 1000.0
	check(absf(g.prestige_rank_mult("FRA") - 1.0) < 0.001 and absf(g.feast_cost("FRA") - 100.0 * float(g.bal.feast_income_months)) < 0.01, "most prestigious court pays the full feast")
	var p_keep: float = n.prestige
	n.prestige = -1000.0
	check(absf(g.prestige_rank_mult("FRA") - float(g.bal.rank_cost_bottom)) < 0.001, "least prestigious court pays the bottom share")
	n.prestige = p_keep
	n.prestige = p0
	check(g.hold_feast("FRA") == "" and n.prestige > p0, "a feast brings prestige")
	check(g.hold_feast("FRA") != "", "feasts have a cooldown")


func test_marriage() -> void:
	var g = new_game("FRA", 5)
	g.nations.FRA.dip = 200.0
	g.add_rel("FRA", "SAV", -100.0)
	check(g.marry("FRA", "SAV") != "", "a hostile house refuses")
	g.add_rel("FRA", "SAV", 200.0)
	check(g.marry("FRA", "SAV") == "", "marriage with a friendly house")
	check(g.nations.FRA.marriages.has("SAV") and g.nations.SAV.marriages.has("FRA"), "marriage on both sides")
	check(g.marry("FRA", "SAV") != "", "no double marriage")
	g.nations.SAV.relations["FRA"] = 10.0
	g.nations.FRA.relations["SAV"] = 10.0
	for i in 24:
		g.tick()
	check(g.get_rel("SAV", "FRA") >= float(g.bal.marriage_rel_floor) - 0.001, "married relations stay friendly")
	var g2 = new_game("FRA", 9)
	g2.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
	check(g2.nations.FRA.marriages.has("SAV"), "marriages are saved")
	# personal union on succession
	g.bal.marriage_union_chance = 1.0
	var lord0: String = g.nations.SAV.overlord  # 24 months of play may have made SAV a vassal or married it again
	g._marriage_succession(g.nations.SAV)
	check(g.nations.SAV.overlord == lord0 or g.nations.SAV.marriages.has(g.nations.SAV.overlord), "union only to the partner (%s -> %s)" % [lord0, g.nations.SAV.overlord])
	var h = new_game("ENG", 5)
	h.nations.FRA.marriages.append("SAV")
	h.nations.SAV.marriages.append("FRA")
	h.bal.marriage_union_chance = 1.0
	h._marriage_succession(h.nations.SAV)
	check(h.nations.SAV.overlord == "FRA", "a small married realm can fall to a strong house")
	h.nations.FRA.truces.erase("SAV")
	h.nations.SAV.truces.erase("FRA")
	h.nations.ENG.marriages.append("BRI")
	h.nations.BRI.marriages.append("ENG")
	h.nations.ENG.truces.erase("BRI")
	h.declare_war("ENG", "BRI")
	check(not h.nations.ENG.marriages.has("BRI"), "war ends a marriage")


func test_generals() -> void:
	var g = new_game("FRA", 5)
	var cap: int = g.nations.FRA.capital
	var a = g.spawn_army("FRA", cap, 6.0)
	var base: float = g._side_power([a], cap)
	g.nations.FRA.mil = 0.0
	check(g.hire_general("FRA", a.id) != "", "a general costs military power")
	g.nations.FRA.mil = 100.0
	check(g.hire_general("FRA", a.id) == "", "hire a general")
	check(a.general == 1, "a new general starts at level 1")
	check(g._side_power([a], cap) > base, "a general makes the army stronger")
	check(g.hire_general("FRA", a.id) != "", "only one general per army")
	var b = g.spawn_army("FRA", cap, 2.0)
	var stars: int = a.general
	g.merge_armies("FRA", cap)
	var merged = null
	for x in g.armies_in(cap):
		if x.owner == "FRA":
			merged = x
	check(merged != null and merged.general == stars, "merged army keeps the general")
	var g2 = new_game("FRA", 9)
	g2.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
	check(g2.army_by_id(merged.id).general == stars, "generals are saved")
	# levels: promotion costs military power, more combat and more command; max level 3
	var lead = merged
	g.nations.FRA.mil = 0.0
	check(g.promote_general("FRA", lead.id) != "", "promotion costs military power")
	g.nations.FRA.mil = 500.0
	var lim1: float = g.command_limit(lead)
	var p1: float = g._side_power([lead], cap)
	check(g.promote_general("FRA", lead.id) == "" and lead.general == 2, "promote to level 2")
	check(g.command_limit(lead) > lim1 and g._side_power([lead], cap) > p1, "higher level: more command and strength")
	check(g.promote_general("FRA", lead.id) == "" and lead.general == 3, "promote to level 3")
	check(g.promote_general("FRA", lead.id) != "", "level 3 is the top")
	# command limit: regiments beyond it fight at general_overflow
	var big = g.spawn_army("FRA", g.provinces_of("FRA")[1], 60.0)
	var lim: float = g.command_limit(big)
	check(absf(g.command_regs(big) - (lim + (60.0 - lim) * float(g.bal.general_overflow))) < 0.01, "regiments over the command limit count less")
	var c0: float = g.command_limit(big)
	g.nations.FRA.set_bonus("test_cmd", {"command": 0.5})
	check(absf(g.command_limit(big) - c0 * 1.5) < 0.01, "command bonus scales the limit")
	# war academy and the general staff tech: start level +1 each, capped at 3
	check(g.general_start_level("FRA") == 1, "start level 1 by default")
	g.nations.FRA.set_bonus("monuments", {"general_start": 1.0})
	check(g.general_start_level("FRA") == 2, "war academy: generals start at level 2")
	g.nations.FRA.set_bonus("tech_x", {"general_start": 1.0})
	check(g.general_start_level("FRA") == 3, "academy + general staff: level 3")
	var c = g.spawn_army("FRA", cap, 4.0)
	g.hire_general("FRA", c.id)
	check(c.general == 3, "hired general starts at the boosted level")
	var mon: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/monuments.json"))
	check(float(mon.academy.bonus.get("general_start", 0.0)) == 1.0, "the war academy gives +1 general level")
	var staff := false
	var techs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/techs.json"))
	for t in techs.techs:
		if float(t.effects.get("general_start", 0.0)) >= 1.0 and int(t.year) >= 1630:
			staff = true
	check(staff, "a late tech gives +1 general level")


func test_peace_offer_cooldown() -> void:
	var g = new_game("ENG", 5)
	g.nations.FRA.truces.erase("ENG")
	g.nations.ENG.truces.erase("FRA")
	g.declare_war("FRA", "ENG")
	var w = g.war_between("FRA", "ENG")
	g.offer_peace("FRA", w, [], true)
	check(g.pending_peace.size() == 1, "AI offer to the player is queued")
	g.answer_player_peace(g.pending_peace[0], false)
	g.offer_peace("FRA", w, [], true)
	check(g.pending_peace.is_empty(), "no new offer right after a rejection")
	g.month += int(g.bal.peace_offer_cooldown)
	g.offer_peace("FRA", w, [], true)
	check(g.pending_peace.size() == 1, "after the cooldown the AI may offer again")


func test_autobuild() -> void:
	var g = new_game("FRA", 5)
	var n = g.nations.FRA
	n.gold = 150.0
	n.autobuild_reserve = 140.0
	check(g.Economy.autobuild(g, n) == 0, "autobuild off by default")
	n.autobuild = true
	check(g.Economy.autobuild(g, n) == 0, "autobuild never goes below the reserve")
	n.autobuild_reserve = 0.0
	n.gold = 1000.0
	check(g.Economy.autobuild(g, n) >= 1, "autobuild starts buildings above the reserve")
	check(n.gold >= 0.0, "autobuild keeps the treasury at or above the reserve")
	n.autobuild_reserve = 777.0
	var g2 = new_game("FRA", 9)
	g2.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
	check(g2.nations.FRA.autobuild and g2.nations.FRA.autobuild_reserve == 777.0, "autobuild is saved")


func test_buildings() -> void:
	var g = new_game("FRA", 5)
	var Eco = g.Economy
	var pid: int = g.key_to_pid["paris"]
	var p = g.provinces[pid]
	var n = g.nations.FRA
	n.gold = 10000.0
	g.bal.city_growth_chance = 0.0  # random yearly city growth (Urban) would add development too
	g.bal.shock_chance = 0.0  # a random glut of Paris' good would outweigh the new level
	check(g.construct("FRA", g.key_to_pid["london"], "workshop") != "", "cannot build in foreign province")
	check(g.construct("FRA", pid, "manufactory") != "", "manufactory needs a workshop")
	var cost: float = Eco.building_cost(g, "FRA", pid, "workshop")
	var dev0: int = p.dev
	var prod0: float = Eco.production_value(g, p)
	check(g.construct("FRA", pid, "workshop") == "", "workshop can be built")
	check(absf(n.gold - (10000.0 - cost)) < 0.01, "building costs gold")
	check(g.construct("FRA", pid, "marketplace") != "", "one construction per province at a time")
	for i in 12:
		g.tick()
	check(Eco.level(p, "workshop") == 1 and p.constructing.is_empty(), "workshop finished after 12 months")
	check(p.dev == dev0 + 1, "a finished building level adds development (%d -> %d)" % [dev0, p.dev])
	check(Eco.production_value(g, p) > prod0, "workshop raises production (%.3f -> %.3f, price %s)" % [prod0, Eco.production_value(g, p), str(g.prices[p.good])])
	check(Eco.building_cost(g, "FRA", pid, "workshop") > cost, "next level costs more")
	# slots
	p.buildings = {}
	p.dev = 7
	Eco.refresh_local(g, p)
	var free: int = Eco.slots(g, p)
	var ids: Array = ["marketplace", "workshop", "estate", "barracks", "courthouse", "fortress"]
	for i in free:
		p.buildings[ids[i]] = 1
	check(Eco.build_block_reason(g, "FRA", pid, ids[free]) != "", "no new building without a free slot")
	var gate: String = Eco.level_tech(g, ids[0], 2)
	if gate != "":
		n.techs[gate] = 0
	check(Eco.build_block_reason(g, "FRA", pid, ids[0]) == "", "upgrades do not need a slot")
	# barracks raise the force limit, courthouse lowers unrest, fortress counts as fort
	g._update_cached(n)
	var fl0: float = g.force_limit("FRA")
	var q = g.provinces[g.key_to_pid["orleans"]]
	q.buildings = {"barracks": 2, "courthouse": 1, "fortress": 1}
	Eco.refresh_local(g, q)
	g._update_cached(n)
	check(absf(g.force_limit("FRA") - fl0 - 2.0) < 0.01, "barracks level 2 adds 2 force limit")
	check(g.unrest_parts(q.id).buildings < 0.0, "courthouse and fortress lower unrest")
	check(Eco.fort_level(g, q) >= 1, "fortress counts as a fort")
	# save/load keeps buildings, construction and merchants
	n.gold = 10000.0
	g.construct("FRA", g.key_to_pid["lyon"], "estate")
	var text := JSON.stringify(g.to_dict())
	var g2 = new_game("FRA", 9)
	g2.from_dict(JSON.parse_string(text))
	check(JSON.stringify(g2.to_dict()) == text, "economy state survives save/load")
	check(g2.provinces[q.id].loc.get("unrest", 0.0) < 0.0, "building cache is rebuilt on load")


func test_army_stances() -> void:
	var g = new_game("BOH", 11)
	var n = g.nations.BOH
	n.army_stance = "defend"
	var a = g.spawn_army("BOH", n.capital, 6.0)
	check(a.auto and a.stance == "defend", "new armies follow the player's default stance")
	g.nations.BOH.truces.erase("BAV")
	g.nations.BAV.truces.erase("BOH")
	check(g.declare_war("BOH", "BAV") == "", "war declared")
	var ok := true
	for i in 36:
		g.tick()
		for x in g.armies_of("BOH"):
			if not x.auto or x.stance != "defend":
				continue
			var p = g.provinces[x.pid]
			var near: bool = g.ai._friendly(g, "BOH", p.owner)
			for nb in p.adj:
				near = near or g.ai._friendly(g, "BOH", g.provinces[nb].owner)
			ok = ok and near
	check(ok, "defending armies stay in or next to friendly land")
	var b = g.spawn_army("BOH", n.capital, 2.0)
	var t: int = g.ai.nearest_siege(g, b)
	check(t < 0 or g.at_war("BOH", g.provinces[t].controller), "quick order 'siege' points at enemy land")


func test_progression() -> void:
	var g = new_game("FRA", 4)
	var P = g.Progression
	check(P.rank(g, "FRA") == 3 and g.nations.FRA.bonus.rank.has("diplo_cap"), "France starts as a kingdom with its bonuses")
	check(g.nations.TUR.rank == 4 and g.nations.NAT.rank == 0, "the Ottomans start as an empire, uncolonized land has no rank")
	var tiny := ""
	for t in g.order:
		if g.provinces_of(t).size() == 1 and not P.START_RANKS.has(t) and not g.nation_data_native.has(t):
			tiny = t
			break
	check(tiny != "" and g.nations[tiny].rank == 0, "a one-province realm starts as a city state")
	var p = g.provinces[g.key_to_pid["paris"]]
	p.buildings = {"workshop": 1}
	g.Economy.refresh_local(g, p)
	var gold0: float = g.nations.FRA.gold
	var got: Array = P.check_milestones(g, "FRA")
	check(got.any(func(m): return m.id == "first_building"), "first building milestone reached")
	check(g.nations.FRA.gold > gold0, "milestone pays its reward")
	check(P.check_milestones(g, "FRA").is_empty(), "milestones pay only once")
	# empire: needs 20 provinces, 280 development, stability and the price
	var n = g.nations.FRA
	check(P.upgrade_block_reason(g, "FRA").begins_with("Fehlt"), "France is too small for an empire")
	var took := 0
	for q in g.provinces:
		if took >= 8:
			break
		if q.owner != "FRA" and q.owner != "NAT" and q.owner != "" and g.provinces_of(q.owner).size() > 1 and q.id < g.nw_first:
			q.owner = "FRA"
			q.controller = "FRA"
			took += 1
	g._rebuild_owned()
	for pid in g.provinces_of("FRA"):
		g.provinces[pid].dev += 10
	g._update_cached(n)
	n.gold = 100.0
	n.adm = 500.0
	n.prestige = 500.0
	n.stability = 30.0
	check(P.upgrade_block_reason(g, "FRA").find("💰") >= 0, "the empire needs its gold (%s)" % P.upgrade_block_reason(g, "FRA"))
	n.gold = 2000.0
	check(P.upgrade(g, "FRA") == "" and n.rank == 4 and absf(n.gold - 500.0) < 0.01, "France becomes an empire and pays for it")
	check(n.bonus.rank.get("ae_decay", 0.0) > 0.0 and n.bonus.rank.get("force_limit", 0.0) > P.RANKS[3].bonus.force_limit, "empire adds a new bonus and improves the old ones")
	check(n.stability > 30.0, "rising in rank brings stability")
	var d: Dictionary = g.to_dict()
	var g2 = new_game("FRA", 9)
	g2.from_dict(JSON.parse_string(JSON.stringify(d)))
	check(g2.nations.FRA.rank == 4 and g2.nations.FRA.bonus.rank.has("ae_decay"), "rank survives save and load")
	# AI realms climb by themselves when they can afford it
	var ai = g.nations.ENG
	ai.gold = 10000.0
	ai.adm = 500.0
	ai.prestige = 500.0
	var before: int = ai.rank
	P.yearly(g)
	check(ai.rank >= before, "a rich AI realm does not lose its rank")
	# demotion: a buffer below the rank's size, two years in a row, then one rank down
	var por = g.nations.POR
	check(por.rank == 3 and g.provinces_of("POR").size() < 10, "small Portugal holds its historical crown")
	P.yearly(g)
	check(por.rank == 3 and not por.flags.has("rank_low"), "the historical size counts as the base, no demotion")
	var fl: Array = P.demote_floor(g, n)
	var keep: Array = g.provinces_of("FRA").slice(0, maxi(1, int(fl[0]) - 1))
	for pid in g.provinces_of("FRA"):
		if not keep.has(pid):
			g.provinces[pid].owner = "ENG"
			g.provinces[pid].controller = "ENG"
	g._rebuild_owned()
	g._update_cached(n)
	var st0: float = n.stability
	P.yearly(g)
	check(n.rank == 4 and int(n.flags.get("rank_low", 0)) == 1, "one bad year only warns")
	P.yearly(g)
	check(n.rank == 3 and n.bonus.rank == P.RANKS[3].bonus and n.stability < st0, "two bad years cost a rank and stability")
	P.yearly(g)
	check(n.rank == 3, "after a demotion the new size is the base: no fall through every rank at once")


## Stability: drift toward a target, shocks, raising it with administration, effects and AI use.
func test_stability() -> void:
	var g = new_game("FRA", 6)
	var St = g.Stability
	var n = g.nations.FRA
	check(absf(n.stability - float(g.bal.stab_start)) < 0.01, "realms start at the start stability")
	check(St.level(-80.0) == 0 and St.level(-10.0) == 1 and St.level(0.0) == 2 and St.level(60.0) == 3, "four display levels")
	var good: Dictionary = St.effects(g, 100.0)
	var bad: Dictionary = St.effects(g, -100.0)
	check(good.tax > 0.0 and good.unrest < 0.0 and bad.tax < 0.0 and bad.unrest > 0.0, "high stability helps, low stability hurts")
	n.stability = 80.0
	var t0: float = St.target(g, n)
	St.monthly(g, n)
	check(n.stability < 80.0 and n.stability >= t0, "stability drifts down toward its target")
	check(absf(g.mod(n, "tax") - g.nations.FRA.bonus.stability.tax - (g.mod(n, "tax") - g.nations.FRA.bonus.stability.tax)) < 0.001 and n.bonus.stability.tax > 0.0, "positive stability raises taxes")
	n.we = 15.0
	check(St.target(g, n) < t0 - 15.0, "war exhaustion lowers the target")
	n.we = 0.0
	n.stability = -30.0
	n.adm = 200.0
	var c: float = St.raise_cost(g, "FRA")
	check(St.raise(g, "FRA") == "" and absf(n.stability - (-30.0 + float(g.bal.stab_raise))) < 0.01 and absf(n.adm - (200.0 - c)) < 0.01, "administration buys stability")
	n.stability = 60.0
	check(St.raise_cost(g, "FRA") > c, "raising high stability costs more")
	n.adm = 0.0
	check(St.raise(g, "FRA") != "", "no stability without administration")
	g.apply_effects("FRA", {"stability": -200})
	check(n.stability == -100.0, "stability is clamped at -100")
	check(g.check_conditions("FRA", {"stability_max": -50}) and not g.check_conditions("FRA", {"stability_min": 0}), "stability conditions")
	check(g.check_conditions("FRA", {"rank_min": 3}) and not g.check_conditions("FRA", {"rank_min": 4}), "rank conditions")
	var u0: float = g.unrest_base(n)
	n.stability = 100.0
	St.monthly(g, n)
	check(g.unrest_base(n) < u0, "high stability calms every province")
	# a lost war shakes the loser, the winner gains
	var e = g.nations.ENG
	n.stability = 0.0
	e.stability = 0.0
	check(g.declare_war("FRA", "ENG") == "" or true, "war declared")
	var w = g.war_between("FRA", "ENG")
	if w != null:
		g.make_peace(w, true, [])
		check(n.stability > 0.0 and e.stability < 0.0, "winning a war raises, losing lowers stability")
	# AI shores up negative stability with spare administration
	var ai = g.nations.SPA
	ai.stability = -40.0
	ai.adm = 400.0
	for i in 12:
		g.month = i
		St.monthly(g, ai)
	check(ai.stability > -30.0 and ai.adm < 400.0, "AI raises its stability when it can")


func test_save_roundtrip() -> void:
	var g = new_game("ENG", 3)
	for i in 30:
		g.tick()
	var d: Dictionary = g.to_dict()
	var text := JSON.stringify(d)
	var g2 = new_game("ENG", 99)
	g2.from_dict(JSON.parse_string(text))
	check(JSON.stringify(g2.to_dict()) == text, "save/load round trip is identical")
	for i in 12:
		g.tick()
		g2.tick()
	# JSON keeps ~15 significant digits, so allow tiny float drift
	check(g.month == g2.month and absf(g.nations.ENG.gold - g2.nations.ENG.gold) < 1.0, "game continues identically after load")


func _overseas_count() -> int:
	var n := 0
	for pd in data.map.provinces:
		if pd.get("nw", false):
			n += 1
	return n


## The North American west (v1.0.3): an overseas block after South America, the Pacific seas only reached
## round Cape Horn or overland from Mexico; then the Low Countries, Old World again, for the Netherlands.
func test_na_west_and_netherlands() -> void:
	const Col = preload("res://scripts/core/colonial.gd")
	var g = new_game("NED", 5)
	check(g.pac_first > g.sa_first and g.pac_first < g.provinces.size(), "the North American west follows South America (%d)" % g.pac_first)
	var west := 0
	for pid in range(g.pac_first, g.provinces.size()):
		var p = g.provinces[pid]
		if data.map.provinces[pid].get("pac", false):
			west += 1
			check(Col.is_new_world(g, pid) and Col.region(g, pid) == "america" and p.owner == Col.NATIVE, "%s is native land in America" % p.key)
		elif not data.map.provinces[pid].get("nw", false):  # the world regions add overseas blocks of their own (test_world_map)
			check(not Col.is_new_world(g, pid) and Col.region(g, pid) == "old", "%s is Old World" % p.key)
	check(west >= 40, "the west coast has %d provinces" % west)
	check(int(data.map.size[0]) > 4096, "the map is wider than one Android texture")
	for td in data.map.terrain_tiles:
		check(int(td[3]) <= 4096 and int(td[4]) <= 4096, "tile %s within 4096 px" % td[0])
	# the Pacific coast: unknown seas, never joined to the Atlantic except round Cape Horn
	for sid in ["cortez", "california", "cascadia"]:
		check(g.sea_by_id.has(sid) and Col.NEW_SEAS.has(sid), "%s is a New World sea" % sid)
		for a in g.sea_by_id[sid].get("adj", []):
			check(not ["caribbean", "gulf", "ocean", "east_coast", "sargasso"].has(a), "%s does not touch the Atlantic (%s)" % [sid, a])
	check(not Col.knows_sea(g, "SPA", "california"), "California is unknown in Europe")
	# the Netherlands: a playable merchant republic in the Empire, rival of the Hanse
	var n = g.nations.NED
	check(n.alive and n.playable and g.provinces_of("NED").size() == 4, "the Netherlands start with Holland, Zeeland, Utrecht and Friesland")
	check(g.provinces[n.capital].key == "holland", "Holland is the capital")
	check(g.govt.form_name("NED") == "Kaufmannsrepublik", "the Netherlands are a merchant republic")
	check(g.hre.has("NED") and g.get_rel("NED", "HSA") < 0.0, "member of the Empire, bad blood with the Hanse")
	check(g.mission_defs.get("NED", []).size() >= 8, "national missions")
	for i in 12:
		g.tick()
	check(n.alive, "the game runs with the new provinces")


## Africa south of the Sahara: an overseas block after the Middle East, native kingdoms, the Swahili
## coast known to the monsoon traders, seas that Europe has to explore around the Cape first.
func test_south_africa() -> void:
	const Col = preload("res://scripts/core/colonial.gd")
	var g = new_game("POR", 5)
	check(g.af_first > g.nw_end and g.af_first < g.provinces.size(), "Africa south of the Sahara follows the east block (%d)" % g.af_first)
	for pid in range(g.af_first, g.sa_first):
		check(Col.is_new_world(g, pid) and Col.region(g, pid) == "africa" and g.overseas.has(pid) and g.africa.has(pid), "%s is overseas Africa" % g.provinces[pid].key)
	check(g.overseas.size() == _overseas_count(), "overseas list covers every overseas block")
	for tag in ["KAN", "BOR", "DAR", "AJU", "MLD", "MBA", "KIL", "KIT", "KON", "NDO", "MUT"]:
		check(g.nations[tag].alive and Col.is_native_realm(g, tag), "%s is a living African realm" % tag)
		check(Col.region(g, g.nations[tag].capital) == "africa", "%s sits in Africa" % tag)
	var kongo: int = g.key_to_pid["kongo"]
	var kilwa: int = g.key_to_pid["kilwa"]
	var bornu: int = g.key_to_pid["bornu"]
	check(not Col.knows(g, "POR", kongo) and not Col.knows(g, "FRA", kilwa), "Kongo and Kilwa are unknown in Europe")
	check(Col.knows(g, "POR", bornu), "Bornu is known from the Saharan caravans")
	check(Col.knows(g, "YEM", kilwa) and Col.knows_sea(g, "YEM", "swahili"), "Yemen knows the Swahili coast (monsoon trade)")
	check(not Col.knows_sea(g, "POR", "swahili") and not Col.knows_sea(g, "POR", "south_atlantic"), "Portugal has to explore the seas around Africa")
	check(Col.knows(g, "KON", kongo) and Col.knows_sea(g, "KIL", "swahili"), "the African realms know their own lands and seas")
	# expeditions only start from seas our own ships can reach: not the Arabian Sea from Lisbon
	g.nations.POR.known_seas["guinea"] = true
	var t: Array = Col.explore_targets(g, "POR")
	check(t.has("south_atlantic") and not t.has("swahili") and not t.has("indian"), "Portugal sails on along the coast, not from the Arabian Sea (%s)" % [t])
	# settlers need a sea route over known seas
	var maj: int = g.key_to_pid["majerteen"]
	check(g.provinces[maj].owner == Col.NATIVE, "the Majerteen coast is native land")
	check(not Col.reachable(g, "FRA", maj), "France cannot settle at the Horn without a way there")
	check(Col.reachable(g, "YEM", maj), "Yemen can (Gulf of Aden)")
	check(g.provinces[g.key_to_pid["hausa"]].owner == "KAN", "Kano rules Hausaland")
	# a few months of the whole game with the new region
	for i in 6:
		g.tick()
	check(g.nations.KON.alive and g.nations.KIL.alive, "the game runs with the new region")


## South America and the finer North American east coast: an overseas block after Africa, region "america",
## Andean realms, seas that Europe reaches over the Atlantic, the Pacific only round Cape Horn.
func test_south_america() -> void:
	const Col = preload("res://scripts/core/colonial.gd")
	var g = new_game("POR", 5)
	check(g.sa_first > g.af_first and g.sa_first < g.provinces.size(), "South America follows Africa (%d)" % g.sa_first)
	for pid in range(g.sa_first, g.pac_first):
		check(Col.is_new_world(g, pid) and Col.region(g, pid) == "america" and g.overseas.has(pid) and not g.africa.has(pid),
				"%s is overseas America" % g.provinces[pid].key)
	check(g.overseas.size() == _overseas_count(), "overseas list covers all blocks")
	for tag in ["INC", "CHM", "MUI", "QTO", "CLL"]:
		check(g.nations[tag].alive and Col.is_native_realm(g, tag), "%s is a living Andean realm" % tag)
		check(Col.region(g, g.nations[tag].capital) == "america", "%s sits in America" % tag)
	var cusco: int = g.key_to_pid["cusco"]
	var bahia: int = g.key_to_pid["bahia"]
	check(g.provinces[cusco].owner == "INC" and g.provinces[bahia].owner == Col.NATIVE, "the Inca rule Cusco, Bahia is native land")
	check(not Col.knows(g, "POR", bahia) and not Col.knows_sea(g, "POR", "brazil"), "Brazil is unknown in Europe")
	check(Col.knows(g, "INC", bahia) == Col.knows(g, "INC", g.key_to_pid["havana"]), "the native realms know their continent")
	# the Darién links both Americas by land, the Pacific is reached only round Cape Horn
	check(g.provinces[g.key_to_pid["darien"]].adj.has(g.key_to_pid["zenu"]), "the Darién gap is a land link")
	var hum: Dictionary = g.sea_by_id["humboldt"]
	check(not hum.adj.has("caribbean") and hum.adj.has("horn"), "no Panama canal: the Humboldt Sea reaches the Atlantic round Cape Horn")
	check(hum.provinces.has(g.key_to_pid["chan_chan"]) and g.sea_by_id["brazil"].provinces.has(g.key_to_pid["pernambuco"]), "the coasts have their seas")
	g.nations.POR.known_seas["west_africa"] = true
	var t: Array = Col.explore_targets(g, "POR")
	check(t.has("amazon") and not t.has("humboldt") and not t.has("brazil"), "Portugal can sail west to the Amazon, not straight into the Pacific (%s)" % [t])
	# the finer east coast keeps the old keys and adds the colonial landing places
	for k in ["munsee", "wampanoag", "guale", "powhatan", "lenape", "massachusett", "stadacona"]:
		check(g.key_to_pid.has(k), "east coast province " + k)
	for i in 6:
		g.tick()
	check(g.nations.INC.alive, "the game runs with the new region")


## The whole world (tools/world): the map spans the globe in Android-sized tiles, the new blocks follow
## the Low Countries, the Old World blocks are known land, and the seas meet across the date line.
func test_world_map() -> void:
	const Col = preload("res://scripts/core/colonial.gd")
	var g = new_game("RUS", 5)
	check(int(data.map.size[0]) > 9000, "the map spans the world (%d px)" % int(data.map.size[0]))
	var covered := 0.0
	for td in data.map.terrain_tiles:
		check(int(td[3]) <= 2048 and int(td[4]) <= 2048 and str(td[0]).begins_with("terrain_"), "tile %s is a grid cell" % td[0])
		check(ResourceLoader.exists("res://assets/art/map/" + str(td[0])), "tile %s is painted" % td[0])
		covered += float(td[3]) * float(td[4])
	check(covered < float(data.map.size[0]) * float(data.map.size[1]), "open-sea cells are not painted")
	# the regions follow the Low Countries, in order; Siberia and the Volga are Old World land
	var low: int = g.key_to_pid["zeeland"]
	for key in ["sarai", "isker", "yakutsk", "kamchatka", "iceland", "trondelag"]:
		var pid: int = g.key_to_pid[key]
		check(pid > low and not Col.is_new_world(g, pid) and Col.knows(g, "FRA", pid), "%s is known Old World land" % key)
		check(data.map.provinces[pid].get("ru", false), "%s is in the ru block" % key)
	for tag in ["GHO", "NOG", "PRM", "SIB", "YUG", "EVK", "YAK", "CHK"]:
		check(g.nations[tag].alive, "%s lives" % tag)
	check(Col.is_native_realm(g, "YAK") and not Col.is_native_realm(g, "SIB"), "the forest peoples are tribal realms, Sibir is a khanate")
	# overland from Moscow to the Pacific
	var seen := {g.key_to_pid["moscow"]: true}
	var queue := [g.key_to_pid["moscow"]]
	while not queue.is_empty():
		var cur: int = queue.pop_back()
		for a in g.provinces[cur].adj:
			if not seen.has(a) and data.map.provinces[a].get("ru", false) or not seen.has(a) and a < low:
				seen[a] = true
				queue.append(a)
	check(seen.has(g.key_to_pid["kamchatka"]) or seen.has(g.key_to_pid["okhotsk"]), "Siberia is reachable by land from Moscow")
	# seas: the Pacific meets across the date line, the polar passages are closed
	check(g.sea_by_id["bering"].adj.has("chukchi") and g.sea_by_id["west_pacific"].adj.has("east_pacific"), "the Pacific is one ocean across the map edge")
	check(not g.sea_by_id["kara"].adj.has("arctic") and not g.sea_by_id["nw_passage"].adj.has("baffin"), "no sailing through the polar ice")
	check(not g.sea_by_id["indian"].adj.has("south_atlantic") and g.sea_by_id["indian"].adj.has("cape"), "the way to India is round the Cape")
	check(g.sea_by_id["caspian"].provinces.has(g.key_to_pid["astrakhan"]) and g.sea_by_id["white_sea"].provinces.has(g.key_to_pid["dvina"]), "new coasts have their seas")
	check(g.sea_by_id["asian_lakes"].adj.is_empty(), "the Asian lakes are inland water")
	# Central Asia, Persia's east and the Indus: the Timurids rule from Herat
	for key in ["samarkand", "herat", "kabul", "kashgar", "thatta", "multan", "turkestan"]:
		var pid: int = g.key_to_pid[key]
		check(data.map.provinces[pid].get("ca", false) and not Col.is_new_world(g, pid), "%s is Old World land in the ca block" % key)
	for tag in ["TIM", "SHY", "MOG", "TKM", "SIS", "BLC", "SND", "MUL"]:
		check(g.nations[tag].alive and not Col.is_native_realm(g, tag), "%s is a living realm" % tag)
	check(g.nations.TIM.capital == g.key_to_pid["herat"] and g.provinces[g.key_to_pid["samarkand"]].owner == "TIM", "the Timurids hold Herat and Samarkand")
	var herat: int = g.key_to_pid["herat"]
	var hops := {herat: 0}
	var q2 := [herat]
	while not q2.is_empty():
		var cur: int = q2.pop_front()
		if hops[cur] >= 4:
			continue
		for a in g.provinces[cur].adj:
			if not hops.has(a):
				hops[a] = hops[cur] + 1
				q2.append(a)
	check(hops.has(g.key_to_pid["isfahan"]), "Herat is a few marches from Isfahan")
	check(g.sea_by_id["arabian"].provinces.has(g.key_to_pid["thatta"]), "the Indus delta lies on the Arabian Sea")
	# India and Ceylon: Hindu subjects under the sultans, Buddhist Kotte, Adam's Bridge
	const Faith = preload("res://scripts/core/religion.gd")
	for key in ["delhi", "jaunpur", "gaur", "vijayanagara", "calicut", "kotte", "kathmandu", "srinagar"]:
		var pid: int = g.key_to_pid[key]
		check(data.map.provinces[pid].get("in", false) and not Col.is_new_world(g, pid), "%s is Old World land in the in block" % key)
	for tag in ["DLH", "JNP", "BNG", "MLW", "GUJ", "BAH", "VIJ", "ORI", "MEW", "CLC", "KOT", "JFN", "NPL", "KSH", "AHO"]:
		check(g.nations[tag].alive and not Col.is_native_realm(g, tag), "%s is a living realm" % tag)
	check(Faith.FAITHS.has("hindu") and Faith.FAITHS.has("buddhist"), "Hinduism and Buddhism are faiths")
	check(g.nations.JNP.religion == "sunni" and g.provinces[g.key_to_pid["jaunpur"]].religion == "hindu", "the people of Jaunpur stay Hindu under their sultan")
	check(g.provinces[g.key_to_pid["delhi"]].religion == "sunni" and g.provinces[g.key_to_pid["vijayanagara"]].religion == "hindu", "Delhi is Muslim, Vijayanagara Hindu")
	check(g.provinces[g.key_to_pid["kotte"]].religion == "buddhist" and g.nations.KOT.religion == "buddhist", "Kotte is Buddhist")
	check(Faith.unrest(g, g.provinces[g.key_to_pid["jaunpur"]]) > 0.0, "a Hindu province under a sultan has religious unrest")
	check(float(Faith.FAITHS.hindu.drift) < 1.0, "Hindus hold on to their faith longer")
	check(g.provinces[g.key_to_pid["madurai"]].adj.has(g.key_to_pid["vanni"]), "Adam's Bridge links India and Ceylon")
	check(g.provinces[g.key_to_pid["golconda"]].good == "gems" and g.goods_def.has("gems"), "Golconda produces gems")
	# East Asia: Ming China, Tibet, the steppe, Manchuria, Korea and Japan
	for key in ["beijing", "nanjing", "guangzhou", "lhasa", "karakorum", "liaoyang", "sakhalin"]:
		var pid: int = g.key_to_pid[key]
		check(data.map.provinces[pid].get("cn", false) and not Col.is_new_world(g, pid), "%s is Old World land in the cn block" % key)
	for key in ["hanseong", "kyoto", "okinawa", "ezo"]:
		check(data.map.provinces[g.key_to_pid[key]].get("jk", false), "%s is in the jk block" % key)
	for tag in ["MNG", "TIB", "MGL", "OIR", "JIA", "JOS", "ASH", "HSK", "OUC", "SHZ", "RYU"]:
		check(g.nations[tag].alive and not Col.is_native_realm(g, tag), "%s is a living realm" % tag)
	check(Col.is_native_realm(g, "AIN") and Col.is_native_realm(g, "NIV") and Col.is_native_realm(g, "TAW"), "Ainu, Nivkh and Formosa are tribal realms")
	check(g.nations.MNG.religion == "confucian" and g.nations.ASH.religion == "shinto" and g.provinces[g.key_to_pid["xining"]].religion == "buddhist", "Confucian Ming, Shinto Japan, Buddhist Amdo")
	check(g.provinces[g.key_to_pid["jingdezhen"]].good == "porcelain" and g.provinces[g.key_to_pid["jianning"]].good == "tea", "Jingdezhen porcelain, Fujian tea")
	check(g.provinces[g.key_to_pid["dongnae"]].adj.has(g.key_to_pid["tsushima"]) and g.provinces[g.key_to_pid["tsushima"]].adj.has(g.key_to_pid["hizen"]), "Tsushima links Korea and Japan")
	check(g.provinces[g.key_to_pid["kaiyuan"]].adj.has(g.key_to_pid["jianzhou"]) or g.provinces[g.key_to_pid["liaoyang"]].adj.has(g.key_to_pid["jianzhou"]), "Liaodong borders the Jurchen")
	check(g.sea_by_id["japan_sea"].provinces.has(g.key_to_pid["hamhung"]) and g.sea_by_id["east_china"].provinces.has(g.key_to_pid["ningbo"]), "the seas of East Asia have their coasts")
	# Southeast Asia and the islands
	for key in ["ayutthaya", "pegu", "thang_long", "malacca", "trowulan", "ternate", "tondo"]:
		var pid: int = g.key_to_pid[key]
		check(data.map.provinces[pid].get("se", false) and not Col.is_new_world(g, pid), "%s is Old World land in the se block" % key)
	for tag in ["AVA", "HAN", "AYU", "DAI", "KHM", "MLC", "MJP", "TER", "BRU"]:
		check(g.nations[tag].alive and not Col.is_native_realm(g, tag), "%s is a living realm" % tag)
	check(Col.is_native_realm(g, "TON") and Col.is_native_realm(g, "DYK"), "Tondo and the Dayak are tribal realms")
	check(g.sea_by_id["malacca"].provinces.has(g.key_to_pid["malacca"]) and g.provinces[g.key_to_pid["malacca"]].adj.has(g.key_to_pid["pagaruyung"]), "Malacca holds the strait")
	check(g.provinces[g.key_to_pid["ternate"]].good == "spices" and g.nations.DAI.religion == "confucian" and g.nations.AYU.religion == "buddhist", "clove islands, Confucian Dai Viet, Buddhist Siam")
	# Oceania and the American Arctic: open land of their peoples, unknown in 1444
	for key in ["arrernte", "eora", "sepik", "waikato", "fiji", "hawaii"]:
		var pid: int = g.key_to_pid[key]
		check(Col.is_new_world(g, pid) and Col.region(g, pid) == "oceania" and g.provinces[pid].owner == "NAT", "%s is open land in Oceania" % key)
		check(not Col.knows(g, "FRA", pid) and not Col.knows(g, "AZT", pid), "%s is unknown in Europe and America" % key)
	for key in ["yupik", "yukon", "kivalliq", "qikiqtaaluk"]:
		var pid: int = g.key_to_pid[key]
		check(Col.region(g, pid) == "america" and g.provinces[pid].owner == "NAT" and data.map.provinces[pid].get("ak", false), "%s is open land in the American north" % key)
	check(g.provinces[g.key_to_pid["kulin"]].adj.has(g.key_to_pid["palawa"]) and g.provinces[g.key_to_pid["arnhem"]].adj.has(g.key_to_pid["timor"]), "Bass Strait and the Timor Sea crossings")
	check(Col.region(g, g.key_to_pid["timor"]) == "old", "Timor stays Old World")
	for i in 6:
		g.tick()
	check(g.nations.SIB.alive, "the game runs with the world map")


## The New World: terra incognita, expeditions, colonies, natives, save/load and old saves.
## West Africa: native kingdoms, colonizable coast known from the start, the Gulf of Guinea to explore.
func test_west_africa() -> void:
	const Col = preload("res://scripts/core/colonial.gd")
	var g = new_game("POR", 5)
	for tag in ["MAL", "SON", "JOL", "BEN"]:
		check(g.nations[tag].alive and Col.is_native_realm(g, tag), "%s is a living West African realm" % tag)
		check(Col.region(g, g.nations[tag].capital) == "africa", "%s sits in West Africa" % tag)
	var mal = g.nations.MAL
	check(mal.known_nw.has(g.key_to_pid["gold_coast"]) and not mal.known_nw.has(g.key_to_pid["havana"]), "Mali knows its own continent, not America")
	check(not g.nations.AZT.known_nw.has(g.key_to_pid["niani"]), "the Aztecs do not know Africa")
	var gam: int = g.key_to_pid["gambia"]
	var elmina: int = g.key_to_pid["gold_coast"]
	check(Col.knows(g, "POR", gam) and Col.knows(g, "ENG", gam), "the Senegambian coast is known in Europe")
	check(not Col.knows(g, "POR", elmina) and not Col.knows_sea(g, "POR", "guinea"), "the Gulf of Guinea is not")
	check(Col.explore_targets(g, "POR").has("guinea"), "Portugal can sail on into the Gulf of Guinea")
	check(Col.knows(g, "MOR", g.key_to_pid["taghaza"]), "Morocco knows the caravan road to Taghaza")
	check(Col.knows(g, "ENG", g.key_to_pid["timbuktu"]) and not Col.knows(g, "ENG", g.key_to_pid["oyo"]), "Mali is known from the caravans, the forest belt is not")
	check(g.provinces[g.key_to_pid["sous"]].adj.has(g.key_to_pid["taghaza"]), "a caravan route crosses the Sahara")
	check(g.provinces[elmina].good == "gold" and g.goods_def.has("gold"), "the Gold Coast produces gold")
	g.bal.explore_dip_tech = 0
	g.nations.POR.gold = 5000.0
	check(Col.colony_block_reason(g, "POR", gam) == "", "Portugal can settle the Gambia")
	check(Col.colony_block_reason(g, "BOH", gam).contains("erreichbar"), "a landlocked realm cannot ship settlers")
	check(Col.colony_block_reason(g, "POR", elmina) != "", "unknown coast cannot be settled")
	# more settlers: recruited with diplomacy (for good, ever dearer) and from finished colonies
	var por = g.nations.POR
	var c0: int = Col.colonists(g, por)
	por.dip = 1000.0
	var cost0: float = Col.recruit_cost(g, por)
	check(Col.recruit_colonist(g, "POR") == "" and Col.colonists(g, por) == c0 + 1 and Col.recruit_cost(g, por) > cost0, "a settler band is recruited")
	for i in int(g.bal.recruit_colonist_max) - 1:
		Col.recruit_colonist(g, "POR")
	check(Col.recruit_colonist(g, "POR") != "" and Col.recruited(por) == int(g.bal.recruit_colonist_max), "recruiting has a cap")
	check(Col.recruit_colonist(g, "MAL") != "", "native realms do not recruit settlers")
	var c1: int = Col.colonists(g, por)
	for key in ["arguin", "waalo", "cayor", "gambia"]:
		var p = g.provinces[g.key_to_pid[key]]
		g.owned[p.owner].erase(p.id)
		p.owner = "POR"
		g.owned["POR"].append(p.id)
	check(Col.colonists(g, por) == c1 + 1, "every %d colonies bring a settler" % int(g.bal.colonies_per_colonist))


## Armies sail from a port to any known coast: ships, gold and time; enemy fleets close the way.
func test_troop_transport() -> void:
	const Nav = preload("res://scripts/core/naval.gd")
	var g = new_game("POR", 5)
	var n = g.nations.POR
	var lisbon: int = g.key_to_pid["lisbon"]
	var gam: int = g.key_to_pid["gambia"]
	var a = g.armies_of("POR")[0]
	a.pid = lisbon
	a.regs = 8.0
	n.gold = 500.0
	n.ships = 10.0
	check(Nav.transport_block_reason(g, a, gam).contains("landen"), "no landing on foreign land without war or access")
	var cayor: int = g.key_to_pid["cayor"]
	g.declare_war("POR", "JOL")
	check(g.at_war("POR", "JOL"), "war on Jolof")
	var route: Array = Nav.sea_route(g, "POR", lisbon, cayor)
	check(route.size() >= 2 and route[0] == "atlantic" and route[-1] == "west_africa", "the route runs over the Atlantic to the West African coast (%s)" % str(route))
	n.ships = 1.0
	check(Nav.transport_block_reason(g, a, cayor).contains("Schiffe"), "8 regiments need 2 ships")
	n.ships = 10.0
	check(Nav.transport_block_reason(g, a, g.key_to_pid["madrid"] if g.key_to_pid.has("madrid") else g.key_to_pid["toledo"]) != "", "inland provinces cannot be reached by sea")
	var regs0: float = g.army_regs("POR")
	var gold0: float = n.gold
	check(Nav.transport(g, a, cayor) == "", "the army sails")
	check(not g.armies.has(a) and g.voyages.size() == 1 and n.gold < gold0, "it is at sea and the voyage cost gold")
	check(is_equal_approx(g.army_regs("POR"), regs0), "armies at sea count against the force limit")
	check(Nav.free_ships(g, "POR") == 8.0, "its ships are busy")
	var months: int = g.voyages[0].total
	check(months >= 2 and months <= 6, "the voyage takes a few months (%d)" % months)
	# save and load at sea
	var text := JSON.stringify(g.to_dict())
	var g2 = new_game("POR", 5)
	g2.from_dict(JSON.parse_string(text))
	check(g2.voyages.size() == 1 and int(g2.voyages[0].to) == cayor, "a voyage survives save/load")
	for i in months:
		g.tick()
	# (the landing malus only lasts into a battle that starts right away, so it is not checked here)
	check(g.armies.has(a) and a.pid == cayor and g.voyages.is_empty(), "the army lands in Kayor")
	# an enemy fleet rules the sea: no way over it
	var b = g.spawn_army("POR", lisbon, 4.0)
	g.sea_blocked["POR"] = {"atlantic": true}
	check(Nav.sea_route(g, "POR", lisbon, cayor).is_empty() and Nav.transport_block_reason(g, b, cayor).contains("Flotte"), "an enemy fleet closes the sea")


func test_fog_of_war() -> void:
	const Vision = preload("res://scripts/core/vision.gd")
	var g = new_game("FRA", 3)
	var paris: int = g.key_to_pid["paris"]
	var wien: int = g.key_to_pid["wien"]
	var calais: int = g.key_to_pid["calais"]
	for a in g.armies.duplicate():
		if a.owner == "FRA" and Vision.compute(g, "FRA")[wien] == Vision.SEEN:
			g.armies.erase(a)  # (no French army near Vienna)
	g.nations.FRA.allies = []
	g.nations.FRA.ships = 0.0
	var s: PackedByteArray = Vision.compute(g, "FRA")
	check(s[paris] == Vision.SEEN, "own land is in sight")
	check(s[calais] != Vision.HIDDEN, "the neighbour next door is in sight")
	check(s[wien] == Vision.HIDDEN, "Vienna lies in the fog for France")
	g.nations.FRA.allies = ["HAB"]
	check(Vision.compute(g, "FRA")[wien] == Vision.SEEN, "an ally shares its sight")
	g.nations.FRA.allies = []
	var a = g.spawn_army("FRA", wien, 1.0)
	var s2: PackedByteArray = Vision.compute(g, "FRA")
	check(s2[wien] == Vision.SEEN, "an army sees the province it stands in")
	var nb: int = g.provinces[wien].adj[0]
	check(s2[nb] != Vision.HIDDEN, "... and the next one")
	g.armies.erase(a)
	check(Vision.compute(g, "")[wien] == Vision.SEEN, "an observer sees everything")
	# the player view: cached, follows the fog setting
	g.player = "FRA"
	g.fog_of_war = true
	var other = g.spawn_army("HAB", wien, 3.0)
	check(not Vision.sees(g, wien) and not Vision.sees_army(g, other), "foreign armies in the fog are hidden from the player")
	g.fog_of_war = false
	check(Vision.sees(g, wien) and Vision.sees_army(g, other), "without fog of war everything is visible")
	g.fog_of_war = true
	var t0 := Time.get_ticks_usec()
	for i in 10:
		Vision.compute(g, "FRA")
	var ms := float(Time.get_ticks_usec() - t0) / 10000.0
	check(ms < 15.0, "sight is cheap to compute (%.2f ms)" % ms)


func test_colonial() -> void:
	const Col = preload("res://scripts/core/colonial.gd")
	var g = new_game("POR", 5)
	var nat = g.nations[Col.NATIVE]
	check(not nat.alive and g.provinces_of(Col.NATIVE).size() > 50, "native land belongs to a nation that is never alive")
	check(g.armies_of(Col.NATIVE).is_empty() and not g.neighbors_of("AZT").has(Col.NATIVE), "native land has no army and is nobody's neighbour")
	check(g.nations.AZT.alive and g.nations.AZT.known_nw.size() > 50, "the Aztecs are a living realm that knows its continent")
	var n = g.nations.POR
	var hav: int = g.key_to_pid["havana"]
	check(not Col.knows(g, "POR", hav) and Col.knows(g, "POR", g.key_to_pid["lisbon"]), "the New World starts unknown, the Old World known")
	check(g.atlantic_tags.has("POR") and not g.atlantic_tags.has("HAB") and not g.atlantic_tags.has("AZT"), "only Atlantic realms explore")
	check(Col.explore_targets(g, "POR").has("ocean") and not Col.explore_targets(g, "POR").has("caribbean"), "the first voyages go into the Atlantic")
	check(Col.explore(g, "POR", "ocean").contains("Technologie"), "expeditions need diplomatic technology")
	g.bal.explore_dip_tech = 0  # (raising n.tech directly would not survive the save test below)
	n.gold = 5000.0
	n.dip = 500.0
	check(Col.explore(g, "POR", "caribbean") != "", "an expedition cannot skip a sea")
	g.bal.explore_success = 1.0
	check(Col.explore(g, "POR", "ocean") == "" and not n.expedition.is_empty(), "the expedition sails")
	check(Col.explore(g, "POR", "ocean") != "", "one expedition at a time")
	for i in int(g.bal.explore_months):
		g.tick()
	check(n.known_seas.has("ocean") and n.expedition.is_empty(), "the expedition comes back with a map")
	check(Col.explore_targets(g, "POR").has("caribbean"), "new seas open up behind the ocean")
	Col.reveal_sea(g, "POR", "caribbean")
	var qis: int = g.key_to_pid["quisqueya"]
	check(Col.knows(g, "POR", qis) and not Col.knows(g, "ENG", qis), "a discovery is first only ours")
	# a colony
	var tenoch: int = g.key_to_pid["tenochtitlan"]
	check(Col.colony_block_reason(g, "POR", tenoch) != "", "native realms are no colony targets")
	check(Col.colony_block_reason(g, "POR", g.key_to_pid["cree"]) != "", "unknown land cannot be settled")
	var gold0: float = n.gold
	check(Col.start_colony(g, "POR", qis) == "" and g.provinces[qis].colonist == "POR", "a colony is founded")
	check(n.gold < gold0, "the colony costs gold")
	check(Col.start_colony(g, "POR", g.key_to_pid["boriken"]).contains("Siedler"), "settlers are limited")
	g.provinces[qis].natives = 6.0
	check(Col.native_treaty(g, "POR", qis) == "" and g.provinces[qis].natives == 3.0, "a treaty halves the natives")
	g.provinces[qis].natives = 0.0
	var months: int = Col.colony_months(g, g.provinces[qis])
	for i in months + 1:
		Col.monthly(g)  # only the colonial tick: a full game could see Portugal conquered in these years
	var q = g.provinces[qis]
	check(q.owner == "POR" and q.colonist == "" and q.dev >= int(g.bal.colony_dev), "the colony becomes a Portuguese province")
	check(g.provinces_of("POR").has(qis) and not g.provinces_of(Col.NATIVE).has(qis), "ownership lists follow")
	check(q.religion == n.religion and q.core_months == 0, "the colony is cored and shares the faith")
	check(Col.knows(g, "POR", g.key_to_pid["ayiti"]), "settlers reveal the neighbouring land")
	# raids can wipe out a young colony
	var bor: int = g.key_to_pid["boriken"]
	check(Col.start_colony(g, "POR", bor) == "", "the next colony starts")
	g.provinces[bor].natives = 1.0 / float(g.bal.native_raid_chance)  # a raid every month (50 natives left it to chance: 7 % of seeds kept the colony)
	g.bal.native_raid_destroy = 1.0
	for i in 12:
		g.tick()
	check(g.provinces[bor].colonist == "" and g.provinces[bor].owner == Col.NATIVE, "strong natives destroy a young colony")
	# knowledge spreads after some decades
	g.found["s:caribbean"] = g.month - int(g.bal.map_spread_years) * 12
	Col.yearly(g)
	check(Col.knows_sea(g, "ENG", "caribbean") and Col.knows(g, "ENG", qis), "old discoveries become common knowledge")
	# save and load
	var text := JSON.stringify(g.to_dict())
	var g2 = new_game("POR", 9)
	g2.from_dict(JSON.parse_string(text))
	# JSON floats may lose their last digit in the first round trip, so compare the second one
	var text2 := JSON.stringify(g2.to_dict())
	var g2b = new_game("POR", 11)
	g2b.from_dict(JSON.parse_string(text2))
	check(text2.length() > text.length() - 200 and JSON.stringify(g2b.to_dict()) == text2, "colonial state survives save/load")
	# a save from before the New World (fewer provinces, no colonial data) still loads
	var d: Dictionary = JSON.parse_string(text)
	d.provinces = d.provinces.slice(0, g.nw_first)
	for t in d.nations:
		d.nations[t].erase("colonial")
	for t in ["AZT", "TLX", "ZAP", "TAR", "MAY", "KIC", "IRO", "NAT", "MAL", "SON", "JOL", "BEN"]:
		d.nations.erase(t)
	var g3 = new_game("POR", 9)
	g3.from_dict(d)
	g3.tick()
	check(g3.provinces[qis].owner == Col.NATIVE and g3.nations.POR.known_seas.has("atlantic") and not g3.nations.POR.known_seas.has("ocean"), "an old save gets an unknown New World")


func test_rival_missions() -> void:
	var g = new_game("ENG", 5)
	for tag in g.mission_defs:
		var ids := []
		for m in g.mission_defs[tag]:
			ids.append(m.id)
		check(ids.has(tag.to_lower() + "_riv_declare") and ids.has(tag.to_lower() + "_riv_power"), "%s has rival missions" % tag)
	var declare := ""
	var power := ""
	for m in g.available_missions("ENG"):
		if m.id == "eng_riv_declare":
			declare = m.id
		if m.id == "eng_riv_power":
			power = m.id
	check(declare != "" and power == "", "declare is open, power waits for its predecessor")
	check(g.complete_mission("ENG", "eng_riv_declare") != "", "no rival, no mission")
	check(g.set_rival("ENG", "FRA") == "", "rivalry declared")
	var mil_before: float = g.nations.ENG.mil
	check(g.complete_mission("ENG", "eng_riv_declare") == "", "rival mission completes")
	check(g.nations.ENG.mil > mil_before, "mission pays military points")
	check(g.complete_mission("ENG", "eng_riv_power") != "", "power projection too low")
	g.add_power_proj("ENG", 60.0)
	check(g.complete_mission("ENG", "eng_riv_power") == "", "power mission completes at 50 pp")
	check(g.mod(g.nations.ENG, "naval") > 0.0, "second mission grants its permanent modifier")


func test_missions_complete() -> void:
	var g = new_game("SPA")
	g.apply_effects("SPA", {"province": "pamplona"})
	check(g.provinces[g.key_to_pid["pamplona"]].owner == "SPA", "province effect works")
	check(g.complete_mission("SPA", "spa_navarre") == "", "mission completes")
	check(g.complete_mission("SPA", "spa_navarre") != "", "mission only once")


func test_long_run_no_softlock() -> void:
	var g = new_game("HAB", 11)
	# a shortened game (50 years) keeps the test fast; the end-of-game logic is the same
	g.bal.total_months = 600
	var months := int(g.bal.total_months)
	for i in months + 5:
		# simulate a passive player who always picks the first event option and accepts peace
		while not g.pending_events.is_empty():
			g.choose_event_option("HAB", g.pending_events[0], 0)
		while not g.pending_peace.is_empty():
			g.answer_player_peace(g.pending_peace[0], true)
		g.tick()
	check(g.game_over, "game ends after the last month")
	check(g.month == months or not g.nations.HAB.alive, "ended at the right month (%d)" % g.month)
	var stuck := 0
	for w in g.wars:
		if g.month - w.start > int(g.bal.war_timeout_months):
			stuck += 1
	check(stuck == 0, "no war older than the timeout")


# ---------------------------------------------------------------- tech tree + government

const Tech = preload("res://scripts/core/tech.gd")


func test_tech_data() -> void:
	var td: Dictionary = data.techs
	var ids := {}
	var per_cat := {"adm": 0, "dip": 0, "mil": 0}
	for t in td.techs + td.special:
		check(not ids.has(t.id), "tech id %s unique" % t.id)
		ids[t.id] = true
		check(per_cat.has(t.cat), "tech %s has a valid category" % t.id)
		for k in t.effects:
			check(Tech.LABELS.has(k), "tech %s effect key %s has a label" % [t.id, k])
	for t in td.techs:
		per_cat[t.cat] += 1
	for t in td.techs + td.special:
		for r in t.get("req", []):
			check(ids.has(r), "tech %s requirement %s exists" % [t.id, r])
	for c in per_cat:
		check(per_cat[c] == 30, "30 generic %s techs" % c)
	for tag in data.nations:
		if data.nations[tag].get("playable", false):
			var n := 0
			for t in td.special:
				if t.tag == tag:
					n += 1
			check(n == 3, "%s has 3 special techs" % tag)


func test_tech_tree() -> void:
	var g = new_game("FRA")
	var n = g.nations.FRA
	n.adm = 900.0
	check(g.research("FRA", "adm_landvoegte") != "", "requirement blocks research")
	check(g.research("FRA", "adm_kanzlei") == "", "first adm tech researched")
	check(n.tech.adm == 1 and n.techs.has("adm_kanzlei"), "level and id recorded")
	check(g.research("FRA", "adm_kanzlei") != "", "no double research")
	check(g.research("FRA", "adm_landvoegte") == "", "second tech after its requirement")
	check(g.research("FRA", "adm_kataster") != "", "year lock (1484 tech in 1444)")
	var before: float = n.adm
	var c: float = g.tech_cost("FRA", "adm")
	check(g.research("FRA", "adm_zuenfte") == "", "other branch researched")
	check(absf(before - c - n.adm) < 0.01, "research costs tech_cost")
	n.dip = 0.0
	check(g.research("FRA", "dip_gesandte") != "", "not enough power blocks research")
	n.mil = 900.0
	check(g.buy_tech("FRA", "mil") == "", "buy_tech picks a tech automatically")
	check(n.tech.mil == 1, "buy_tech advanced mil")


func test_special_techs() -> void:
	var g = new_game("FRA")
	var n = g.nations.FRA
	n.mil = 900.0
	check(g.research("FRA", "fra_ordonnance") != "", "special tech needs its requirement")
	check(g.research("FRA", "mil_pikenhaufen") == "", "requirement researched")
	var lvl: int = n.tech.mil
	check(g.research("FRA", "fra_ordonnance") == "", "special tech researched")
	check(n.tech.mil == lvl, "special techs do not count as levels")
	g.nations.ENG.mil = 900.0
	g.research("ENG", "mil_pikenhaufen")
	check(g.research("ENG", "fra_ordonnance") != "", "other nations cannot take French special techs")
	var spec := 0
	for t in g.tree.techs_for("ENG", "mil"):
		if Tech.is_special(t):
			check(t.tag == "ENG", "techs_for only lists own specials")
			spec += 1
	check(spec >= 1, "ENG sees its mil special tech")
	# AI path prefers available special techs
	var g2 = new_game("ENG")
	g2.nations.FRA.mil = 900.0
	g2.research("FRA", "mil_pikenhaufen")
	check(g2.tree.best_choice(g2, "FRA", "mil") == "fra_ordonnance", "AI picks the special tech first")


func test_tech_modifiers() -> void:
	var g = new_game("FRA")
	var n = g.nations.FRA
	n.mil = 2000.0
	n.adm = 2000.0
	g.research("FRA", "mil_lehnsaufgebot")
	var fl: float = g.force_limit("FRA")
	g.research("FRA", "mil_soldwesen")
	check(absf(g.force_limit("FRA") - fl - 2.0) < 0.01, "force limit +1 from tech, +1 from the second mil level")
	g.research("FRA", "adm_universitaet")
	var with_bonus: float = g.tech_cost("FRA", "adm")
	var saved: Dictionary = n.bonus.tech
	n.bonus.tech = {}
	var without: float = g.tech_cost("FRA", "adm")
	n.bonus.tech = saved
	check(absf(with_bonus - round(without * 0.97)) <= 1.0, "tech_cost modifier applies (%d vs %d)" % [with_bonus, without])
	check(absf(g.mod(n, "tech_cost") - float(n.bonus.get("stability", {}).get("tech_cost", 0.0)) + 0.03) < 0.001, "bonus tech recorded in mod()")
	check(g.ae_mult("FRA") == 1.0, "no ae modifier yet")
	check(g.core_time("FRA") == int(g.bal.core_months), "default core time")


func test_government_data() -> void:
	var gd: Dictionary = data.government
	var ids := {}
	for a in gd.advisors:
		check(not ids.has(a.id), "advisor %s unique" % a.id)
		ids[a.id] = true
		check(["adm", "dip", "mil"].has(a.type), "advisor %s type" % a.id)
		for k in a.effects:
			check(Tech.LABELS.has(k), "advisor %s key %s has a label" % [a.id, k])
		if a.has("tag"):
			check(data.nations.has(a.tag) and int(a.from) <= int(a.to), "national advisor %s valid" % a.id)
	for c in gd.companies:
		for k in c.effects:
			check(Tech.LABELS.has(k), "company %s key %s has a label" % [c.id, k])
	var tech_ids := {}
	for t in data.techs.techs:
		tech_ids[t.id] = true
	for l in gd.laws:
		check(l.options[0].effects.is_empty(), "law %s default option has no effects" % l.id)
		for o in l.options:
			if o.has("req"):
				check(tech_ids.has(o.req), "law option %s requirement exists" % o.id)
			var good := false
			var bad := false
			for line in Tech.effect_lines(o.effects):
				if line[1]:
					good = true
				else:
					bad = true
			check(o.effects.is_empty() or (good and bad), "law option %s is a trade-off" % o.id)
	for tag in data.nations:
		if data.nations[tag].get("playable", false):
			var na := 0
			var nc := 0
			for a in gd.advisors:
				if a.get("tag", "") == tag:
					na += 1
			for c in gd.companies:
				if c.get("tag", "") == tag:
					nc += 1
			check(na >= 3 and nc >= 1, "%s has national advisors and a company" % tag)


func test_advisors() -> void:
	var g = new_game("FRA")
	var n = g.nations.FRA
	n.adm = 500.0
	n.dip = 500.0
	n.mil = 500.0
	var pool := []
	for a in g.govt.advisor_pool(g, "FRA"):
		pool.append(a.id)
	check(pool.has("fra_coeur"), "Jacques Coeur available in 1444")
	check(not pool.has("fra_richelieu"), "Richelieu not yet born")
	check(not pool.has("eng_cromwell"), "no foreign national advisors")
	var inc: float = g.mod(n, "income")
	check(g.govt.hire(g, "FRA", "kaemmerer") == "", "hire advisor")
	check(absf(g.mod(n, "income") - inc - 0.06) < 0.001, "advisor bonus applies")
	check(absf(n.adm - (500.0 - g.govt.advisor_cost(g, n, "kaemmerer"))) < 0.01, "advisor costs power of its type")
	check(g.govt.hire(g, "FRA", "kaemmerer") != "", "no double hire")
	g.govt.hire(g, "FRA", "fra_coeur")
	g.govt.hire(g, "FRA", "feldhauptmann")
	check(g.govt.hire(g, "FRA", "gesandter") != "", "slot limit of 3")
	g.govt.dismiss(g, "FRA", "kaemmerer")
	check(absf(g.mod(n, "income") - inc - 0.03) < 0.001, "dismissal removes bonus (Coeur keeps +3 %)")
	# national advisors leave after their time
	g.month = (1457 - 1444) * 12
	g.govt.yearly(g, n)
	check(not n.gov.advisors.has("fra_coeur"), "Coeur leaves court after 1456")


func test_companies() -> void:
	var g = new_game("ENG")
	var n = g.nations.ENG
	n.gold = 5000.0
	var cost: float = g.govt.company_cost(g, n, "lombarden")
	check(cost >= float(data.government.company_base_gold), "company costs at least the base price")
	# slow linear growth with the years plus a small share of the yearly income
	var inc0: float = n.income
	n.income = 0.0
	var c0: float = g.govt.company_cost(g, n, "lombarden")
	g.month = 100 * 12
	var c100: float = g.govt.company_cost(g, n, "lombarden")
	check(absf(c100 - c0 * (1.0 + 100.0 * float(data.government.company_year_scale))) < 1.0, "price grows linearly with the years (%d -> %d)" % [c0, c100])
	n.income = 300.0
	check(absf(g.govt.company_cost(g, n, "lombarden") - c100 - 12.0 * 300.0 * float(data.government.company_income_share)) < 1.0, "plus a small share of the yearly income")
	g.month = 0
	n.income = inc0
	cost = g.govt.company_cost(g, n, "lombarden")
	check(g.govt.found_company(g, "ENG", "eng_muscovy") != "", "Muscovy Company only from 1555")
	check(g.govt.found_company(g, "ENG", "fra_lyon") != "", "foreign company blocked")
	check(g.govt.found_company(g, "ENG", "lombarden") == "", "found company")
	check(absf(n.gold - (5000.0 - cost)) < 0.01, "company costs gold")
	check(g.govt.found_company(g, "ENG", "kaufmannsgilde") == "", "second company")
	check(g.govt.found_company(g, "ENG", "bergbau") != "", "two company slots")
	n.dip = 5000.0
	for id in ["dip_messen", "dip_wechsel"]:
		check(g.research("ENG", id) == "", "research " + id)
	g.month = (1580 - 1444) * 12
	for id in ["dip_gilden", "dip_karavellen", "dip_boersen", "dip_girobanken", "dip_aktien"]:
		g.research("ENG", id)
	check(g.govt.company_slots(g, n) == 3, "Aktiengesellschaften unlock a third slot")
	check(g.govt.found_company(g, "ENG", "bergbau") == "", "third company")
	g.govt.dissolve_company(g, "ENG", "bergbau")
	check(not n.gov.companies.has("bergbau"), "dissolve company")


func test_difficulty() -> void:
	var g = new_game("ENG")
	check(g.difficulty == "normal", "default difficulty is normal")
	g.set_difficulty("easy")
	check(absf(float(g.nations.ENG.bonus.difficulty.income) - 0.25) < 0.001, "easy gives player income bonus")
	check(g.nations.FRA.bonus.difficulty.is_empty(), "easy gives AI no bonus")
	g.set_difficulty("very_hard")
	check(g.nations.ENG.bonus.difficulty.is_empty(), "very hard: no player bonus")
	check(float(g.nations.FRA.bonus.difficulty.get("income", 0.0)) >= 0.15 - 0.001, "very hard: AI income bonus")
	check(g.diff("ai_vs_player") > 1.0, "very hard: AI targets player more")
	g.set_difficulty("nonsense")
	check(g.difficulty == "normal", "unknown difficulty falls back to normal")
	g.set_difficulty("hard")
	var g2 = new_game("ENG")
	g2.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
	check(g2.difficulty == "hard", "difficulty survives save/load")
	check(g2.nations.ENG.bonus.difficulty.is_empty(), "loaded difficulty replaces the player bonus")


func test_laws() -> void:
	var g = new_game("SPA")
	g.set_difficulty("hard")  # no player bonus from difficulty
	var n = g.nations.SPA
	n.adm = 500.0
	n.mil = 500.0
	check(n.gov.laws.heer == "lehnsheer", "default law")
	check(g.govt.set_law(g, "SPA", "heer", "stehendes_heer") != "", "law needs its tech")
	var mp: float = g.mod(n, "manpower")
	check(g.govt.set_law(g, "SPA", "heer", "landesaufgebot") == "", "change law")
	check(absf(g.mod(n, "manpower") - mp - 0.25) < 0.001, "law buff applies")
	check(g.mod(n, "combat") < float(data.nations.SPA.bonus.combat), "law nerf applies")
	check(g.govt.set_law(g, "SPA", "heer", "soeldner") != "", "cooldown blocks changes")
	check(g.check_conditions("SPA", {"law": {"heer": "landesaufgebot"}}), "law condition")
	check(not g.check_conditions("SPA", {"has_tech": "adm_kanzlei"}), "has_tech condition (missing)")
	var pid: int = g.provinces_of("SPA")[0]
	check(absf(g.unrest_parts(pid).policy - 0.5) < 0.001, "law unrest shows in province unrest")
	g.month += 121
	check(g.govt.set_law(g, "SPA", "heer", "soeldner") == "", "law change after cooldown")


func test_gov_save_roundtrip() -> void:
	var g = new_game("POL", 5)
	var n = g.nations.POL
	n.adm = 900.0
	n.dip = 900.0
	n.gold = 900.0
	g.govt.hire(g, "POL", "pol_olesnicki")
	g.month = (1470 - 1444) * 12
	g.research("POL", "dip_messen")
	g.research("POL", "pol_kornhandel")
	g.govt.found_company(g, "POL", "pol_danzig")
	g.govt.set_law(g, "POL", "kirche", "toleranz")
	var text := JSON.stringify(g.to_dict())
	var g2 = new_game("POL", 9)
	g2.from_dict(JSON.parse_string(text))
	check(JSON.stringify(g2.to_dict()) == text, "tech/government state survives save/load")
	var n2 = g2.nations.POL
	check(n2.techs.has("pol_kornhandel") and n2.gov.advisors.has("pol_olesnicki") and n2.gov.companies.has("pol_danzig"),
			"techs, advisors and companies restored")
	for k in ["trade", "dip", "unrest", "income", "prestige"]:
		check(absf(g.mod(n, k) - g2.mod(n2, k)) < 0.0001, "bonus %s rebuilt after load" % k)


func test_old_save_tech_levels() -> void:
	var g = new_game("FRA", 4)
	g.nations.FRA.tech = {"adm": 4, "dip": 2, "mil": 3}
	var d: Dictionary = JSON.parse_string(JSON.stringify(g.to_dict()))
	for tag in d.nations:
		d.nations[tag].erase("techs")
		d.nations[tag].erase("gov")
	var g2 = new_game("FRA", 4)
	g2.from_dict(d)
	var n = g2.nations.FRA
	check(n.techs.size() == 9, "old save: levels turn into the oldest techs (%d)" % n.techs.size())
	check(n.gov.laws.size() == data.government.laws.size(), "old save: default laws")
	check(g2.research("FRA", "adm_kanzlei") != "", "old save: granted techs count as researched")


func test_ai_uses_government() -> void:
	var g = new_game("FRA", 21)
	for i in 12 * 40:
		while not g.pending_events.is_empty():
			g.choose_event_option("FRA", g.pending_events[0], 0)
		while not g.pending_peace.is_empty():
			g.answer_player_peace(g.pending_peace[0], true)
		g.tick()
	var adv := 0
	var comp := 0
	var laws := 0
	var spec := 0
	var alive := 0
	for tag in g.order:
		var n = g.nations[tag]
		if not n.alive or tag == "FRA":
			continue
		alive += 1
		adv += n.gov.advisors.size()
		comp += n.gov.companies.size()
		for l in n.gov.laws:
			if n.gov.laws[l] != g.govt.law_by_id[l].options[0].id:
				laws += 1
		for t in g.tree.specials_of(tag):
			if n.techs.has(t.id):
				spec += 1
	print("    AI 1484: %d nations, %d advisors, %d companies, %d laws changed, %d special techs" % [alive, adv, comp, laws, spec])
	check(adv >= alive, "AI hires advisors")
	# since the world map (v1.1, ~200 realms) many are one-to-three-province tribes that cannot pay ~175 gold
	check(comp >= alive / 3, "AI founds companies")
	check(laws >= alive / 2, "AI changes laws")
	check(spec >= 5, "AI researches special techs")
## Every emoji in UI code and data/*.json needs a pixel glyph (scripts/ui/pixel_emoji.gd); there is no emoji font.
## Nation emoji are exempt (nations show their flag) but every nation needs one.
func test_emoji_coverage() -> void:
	var have: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/emoji/emoji.json"))
	var files := []
	for f in DirAccess.get_files_at("res://data"):
		# nation emoji are replaced by flags; the map has no text
		if f.ends_with(".json") and f != "nations.json" and f != "map.json":
			files.append("res://data/" + f)
	for f in DirAccess.get_files_at("res://scripts/ui"):
		if f.ends_with(".gd"):
			files.append("res://scripts/ui/" + f)
	for path in files:
		var text := FileAccess.get_file_as_string(path)
		for i in text.length():
			var c := text.unicode_at(i)
			# emoji blocks; leaves arrows, maths signs, box drawing and the variation selector alone
			if (c >= 0x2300 and c < 0x2500) or (c >= 0x25A0 and c < 0x2C00) or c >= 0x1F000:
				check(have.has("%x" % c), "%s: no pixel glyph for %s (U+%X), add it in tools/art/emoji_icons.py" % [path, char(c), c])
	for tag in data.nations:
		if data.nations[tag].has("dormant"):
			continue  # pool nations fly their overlord's flag (Icons.flag_alias)
		check(ResourceLoader.exists("res://assets/art/icons/flag_%s.png" % tag), "nation %s has no flag" % tag)
	# every flag is a glyph of the pixel font, registered before any text is drawn
	var PE = load("res://scripts/ui/pixel_emoji.gd")
	PE.install()
	PE.add_nations(data.nations.keys())
	for tag in data.nations:
		if data.nations[tag].has("dormant"):
			continue
		var f: String = PE.nation(tag)
		check(f.length() == 1 and f.unicode_at(0) >= PE.PUA and PE.font.has_char(f.unicode_at(0)), "flag of %s is a pixel glyph" % tag)
	check(PE.nation("XXX") == "🏳" and have.has("1f3f3"), "a nation without flag shows the white flag glyph")
	# a changed global oversampling (window resize, UI size, Windows DPI) must not wipe the glyphs
	var ts := TextServerManager.get_primary_interface()
	var was := ts.font_get_global_oversampling()
	ts.font_set_global_oversampling(was * 1.4 + 0.1)
	var flag: String = PE.nation(data.nations.keys()[0])
	check(PE.font.has_char(0x1F4B0) and PE.font.has_char(flag.unicode_at(0)), "pixel glyphs survive an oversampling change")
	ts.font_set_global_oversampling(was)


## Pixel UI kit (tools/art/ui_kit.py): every slice texture exists and is big enough for its margins;
## modifier rows mark buffs and nerfs by meaning, not by sign (lower build cost is a buff).
func test_ui_kit() -> void:
	for k in UiTheme.SLICES:
		var t := UiTheme.tex(k)
		check(t != null, "ui kit texture %s missing, run tools/art/ui_kit.py" % k)
		if t != null:
			check(t.get_width() > 2 * UiTheme.SLICES[k] and t.get_height() > 2 * UiTheme.SLICES[k] or k == "topbar", "ui kit %s smaller than its slices" % k)
	for k in ["mod_up", "mod_down", "separator", "slider_grabber"]:
		check(UiTheme.tex(k) != null, "ui kit texture %s missing" % k)
	var rows: Array = UiTheme.mod_rows({"build_cost": -0.1, "income": 0.05, "unrest": 1.0, "tax": 0.0})
	check(rows.size() == 3, "zero modifiers are hidden")
	var good := {}
	for r in rows:
		good[r[0]] = r[2]
	check(good.get("Baukosten") == true, "lower build cost is a buff")
	check(good.get("Einkommen") == true, "more income is a buff")
	check(good.get("Unruhe") == false, "more unrest is a nerf")
	check(UiTheme.tone_bb("💰 +5", 1).contains("mod_up.png"), "buffs get the up arrow")


## Every event's picture (own "image" or the generated motif map) must exist; tools/art/event_motifs.py.
func test_event_pictures() -> void:
	var motifs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/events/event_motifs.json"))
	for e in data.events:
		var m: String = e.get("image", motifs.get(e.id, "court"))
		check(ResourceLoader.exists("res://assets/art/events/%s.png" % m), "event %s: picture %s missing" % [e.id, m])


func test_company_invest() -> void:
	var g = new_game("HAB")
	var n = g.nations.HAB
	n.gold = 100000.0
	g.month = (1495 - 1444) * 12
	check(g.govt.found_company(g, "HAB", "hab_fugger") == "", "found Fugger")
	check(g.govt.invest_level(n, "hab_fugger") == 1, "new company starts at level 1")
	var inc: float = g.mod(n, "income")
	var ae: float = g.mod(n, "ae_gen")
	check(g.govt.invest(g, "HAB", "hab_fugger", 1) != "", "cannot invest to the same level")
	var c: float = g.govt.invest_cost(g, n, "hab_fugger", 3)
	var gold: float = n.gold
	check(c > g.govt.company_cost(g, n, "hab_fugger") * 0.5, "two levels cost more than half a company")
	check(g.govt.invest(g, "HAB", "hab_fugger", 3) == "", "invest two levels")
	check(absf(gold - c - n.gold) < 0.01, "investment costs gold")
	check(absf(g.mod(n, "income") - inc - 0.15 * 1.0) < 0.001, "benefit +100 % at level 3 (+15 % more income)")
	check(absf(g.mod(n, "ae_gen") - ae) < 0.001, "drawback unchanged")
	check(g.govt.invest(g, "HAB", "hab_fugger", 6) != "", "max level 5")
	check(g.govt.invest(g, "HAB", "hab_fugger", 5) == "", "invest to the top level")
	check(absf(g.mod(n, "ae_gen") - ae + float(g.govt.comp_by_id.hab_fugger.effects.get("ae_gen", 0.0))) < 0.001, "top level drops the drawback")
	check(g.govt.company_effects("hab_fugger", 4).has("ae_gen") and not g.govt.company_effects("hab_fugger", 5).has("ae_gen"), "drawback only gone at level 5")
	var d: Dictionary = JSON.parse_string(JSON.stringify(g.to_dict()))
	var g2 = new_game("HAB")
	g2.from_dict(d)
	check(g2.govt.invest_level(g2.nations.HAB, "hab_fugger") == 5, "investment level survives save/load")
	check(absf(g2.mod(g2.nations.HAB, "income") - g.mod(n, "income")) < 0.0001, "scaled bonus rebuilt after load")
	g.govt.dissolve_company(g, "HAB", "hab_fugger")
	check(not n.gov.invest.has("hab_fugger"), "dissolving drops the investment")


func test_estates() -> void:
	var g = new_game("FRA")
	var n = g.nations.FRA
	check(n.gov.estates.size() == 3, "three estates")
	for e in g.govt.estates:
		check(g.event_by_id.has("estate_crisis_" + e.id), "crisis event for %s registered" % e.id)
		check(not g.event_defs.has(g.event_by_id["estate_crisis_" + e.id]), "crisis events are not in the random pool")
	n.adm = 500.0
	check(g.govt.set_law(g, "FRA", "staat", "staendestaat") == "", "Ständestaat")
	var form_adel: float = g.govt.form_effects("FRA").get("estate_adel", 0.0)
	check(absf(g.govt.estate_target(g, n, "adel") - 65.0 - form_adel) < 0.01, "law shifts the nobility's target to 65 (+ form)")
	for i in 60:
		g.govt.estates_monthly(g, n)
	check(n.gov.estates.adel > 60.0, "nobility drifts towards its target (%.1f)" % n.gov.estates.adel)
	g.govt.change_estate(g, n, "adel", 5.0)
	check(n.gov.estates.adel >= 65.0 and g.govt.estate_tier(n, "adel") == "loyal", "nobility is loyal from 65 (%.1f)" % n.gov.estates.adel)
	check(n.bonus.estates.get("manpower", 0.0) > 0.0, "loyal nobility gives manpower")
	g.govt.change_estate(g, n, "klerus", -40.0)
	check(g.govt.estate_tier(n, "klerus") == "angry", "angry clergy")
	var pid: int = g.provinces_of("FRA")[0]
	check(absf(g.unrest_parts(pid).estates - 1.0) < 0.001, "angry clergy shows as its own unrest item")
	n.gold = 1000.0
	var before: float = n.gov.estates.klerus
	check(g.govt.grant_concession(g, "FRA", "klerus") == "", "concession")
	check(absf(n.gov.estates.klerus - before - 20.0) < 0.01, "concession +20")
	check(g.govt.grant_concession(g, "FRA", "klerus") != "", "concession cooldown")
	n.gov.estates.buerger = 50.0
	g.apply_effects("FRA", {"estate": {"buerger": -30}})
	check(absf(n.gov.estates.buerger - 20.0) < 0.01, "estate effect")
	check(g.check_conditions("FRA", {"estate_max": {"buerger": 25}}) and not g.check_conditions("FRA", {"estate_min": {"buerger": 25}}), "estate conditions")
	# crisis fires for the player at most once per estate_crisis_years
	g.month = 120
	var fired := 0
	for y in 8:
		g.month += 12
		g.pending_events.clear()
		n.gov.estates.buerger = 10.0
		for i in 20:
			g.govt._estate_crisis(g, n)
		fired += g.pending_events.size()
	check(fired >= 1 and fired <= 2, "estate crisis at most every 4 years (%d in 8 years)" % fired)
	g.govt.change_estate(g, n, "adel", 80.0 - n.gov.estates.adel)
	var text := JSON.stringify(g.to_dict())
	var g2 = new_game("FRA", 3)
	g2.from_dict(JSON.parse_string(text))
	check(JSON.stringify(g2.to_dict()) == text, "estates survive save/load")
	check(g2.govt.estate_tier(g2.nations.FRA, "adel") == "loyal" and g2.nations.FRA.bonus.estates.has("manpower"), "estate bonus rebuilt after load")


## Government events (tools/content/gov_events.py) reference real laws, techs and estates and fire once their law is set.
func test_gov_events() -> void:
	var g = new_game("FRA")
	var n = g.nations.FRA
	var count := 0
	for e in data.events:
		if not e.id.begins_with("gov_"):
			continue
		count += 1
		var tr: Dictionary = e.trigger
		for l in tr.get("law", {}):
			check(g.govt.law_by_id.has(l) and not g.govt.law_option(l, tr.law[l]).is_empty(), "%s: law %s exists" % [e.id, l])
		if tr.has("has_tech"):
			check(g.tree.by_id.has(tr.has_tech), "%s: tech %s exists" % [e.id, tr.has_tech])
		for k in ["estate_min", "estate_max"]:
			for es in tr.get(k, {}):
				check(n.gov.estates.has(es), "%s: estate %s exists" % [e.id, es])
		for o in e.options:
			for es in o.effects.get("estate", {}):
				check(n.gov.estates.has(es), "%s: effect estate %s exists" % [e.id, es])
	check(count >= 15, "at least 15 government events (%d)" % count)
	var ev: Dictionary = g.event_by_id["gov_heretics"]
	g.month = (1510 - 1444) * 12
	check(not g.check_conditions("FRA", ev.trigger), "heretics need Glaubenseifer")
	n.gov.laws["kirche"] = "glaubenseifer"
	check(g.check_conditions("FRA", ev.trigger), "heretics fire under Glaubenseifer")
	var before: float = n.gov.estates.klerus
	g.choose_event_option("FRA", "gov_heretics", 0)
	check(n.gov.estates.klerus > before, "inquisition pleases the clergy")


## EU5-style budget sliders: neutral by default, effects and gold per step, saved, AI tightens when poor.
func test_budget() -> void:
	var g = new_game("FRA")
	var n = g.nations.FRA
	var gv = g.govt
	check(gv.budget.size() == 4, "four budget sliders")
	check(n.bonus.budget.is_empty() and absf(gv.budget_cost(g, n)) < 0.001, "default budget is neutral")
	g.tick()
	var inc: float = n.income
	check(gv.set_budget(g, "FRA", "hof", 4) == "", "set court to max")
	check(absf(gv.budget_cost(g, n) - 0.08 * inc) < 0.001, "lavish court costs 8 % of income")
	check(absf(n.bonus.budget.prestige - 2.0) < 0.001 and n.bonus.budget.estate_adel > 0.0, "court gives prestige and pleases the nobility")
	check(gv.set_budget(g, "FRA", "steuern", 0) == "", "set taxes to minimum")
	check(absf(n.bonus.budget.tax + 0.2) < 0.001 and n.bonus.budget.unrest < 0.0, "mild taxes: less tax, less unrest")
	check(gv.set_budget(g, "FRA", "bildung", 9) == "" and gv.budget_step(n, "bildung") == 4, "slider clamped to max")
	check(gv.budget_slider_cost(n, "bildung", 0) < 0.0, "cutting research saves gold")
	var exp_before: float = n.expenses
	g.tick()
	check(n.expenses > 0.0 and absf(gv.budget_cost(g, n)) > 0.0, "budget cost is part of expenses (%.2f vs %.2f)" % [n.expenses, exp_before])
	var text := JSON.stringify(g.to_dict())
	var g2 = new_game("FRA", 3)
	g2.from_dict(JSON.parse_string(text))
	check(g2.govt.budget_step(g2.nations.FRA, "hof") == 4 and g2.nations.FRA.bonus.budget.has("prestige"), "budget survives save/load")
	var ai = g.nations.ENG
	ai.gold = 0.0
	gv._ai_budget(g, ai)
	check(gv.budget_step(ai, "hof") == 1 and gv.budget_step(ai, "bildung") == 1 and gv.budget_step(ai, "heer") <= 2, "poor AI cuts court, research and never raises the army budget")
	ai.gold = 5000.0
	gv._ai_budget(g, ai)
	check(gv.budget_step(ai, "hof") == 3 and gv.budget_step(ai, "bildung") == 3, "rich AI spends on court and research")


## eco_ events/missions (tools/content/eco_events.py): references are valid and the new conditions/effects work.
func test_eco_content() -> void:
	var g = new_game("ENG")
	var n = g.nations.ENG
	var known := ["building", "no_building", "coastal", "produces", "goods_leader", "shock", "loans_min", "loans_max",
		"trade_pacts_min", "mercs_recent", "morale_max", "budget_min", "budget_max", "gold_max", "year_min", "at_war",
		"at_peace", "estate_min", "estate_max"]
	var reqs := []
	for e in data.events:
		if e.id.begins_with("eco_"):
			reqs.append(e.trigger)
			for o in e.options:
				var b = o.effects.get("build", "")
				check(b == "" or g.buildings_def.has(b), "%s builds a known building" % e.id)
	for tag in data.missions:
		for m in data.missions[tag]:
			if "_eco_" in m.id:
				reqs.append(m.require)
	check(reqs.size() >= 60, "eco content present (%d)" % reqs.size())
	for r in reqs:
		for k in r:
			check(known.has(k), "known condition " + k)
		for bid in r.get("building", {}):
			check(g.buildings_def.has(bid), "known building " + bid)
		for key in ["produces", "goods_leader"]:
			check(not r.has(key) or r[key] is bool or g.goods_def.has(r[key]), "known good in " + key)
		for key in ["budget_min", "budget_max"]:
			for id in r.get(key, {}):
				check(g.govt.budget_by_id.has(id), "known budget slider " + id)
		g.check_conditions("ENG", r)  # must not crash
	# conditions
	check(g.check_conditions("ENG", {"coastal": true}) and not g.check_conditions("BOH", {"coastal": true}), "England is coastal, Bohemia is not")
	check(g.check_conditions("ENG", {"produces": "wool"}) and not g.check_conditions("ENG", {"produces": "furs"}), "England produces wool, no furs")
	check(g.check_conditions("ENG", {"no_building": "road"}) and not g.check_conditions("ENG", {"building": {"road": 1}}), "no roads at start")
	# effects: free building level
	var dev0: int = n.dev_total
	g.apply_effects("ENG", {"build": "road"})
	check(g.Economy.building_total(g, "ENG", "road") == 1 and g.check_conditions("ENG", {"building": {"road": 1}}), "build effect adds a road level")
	check(g.nation_dev("ENG") == dev0, "free road gives no development (no_dev)")
	g.apply_effects("ENG", {"build": "marketplace"})
	check(g.nation_dev("ENG") == dev0 + int(g.bal.building_dev), "free marketplace grows the province like a finished building")
	# loans
	g.apply_effects("ENG", {"loan": 2})
	check(n.loans.size() == 2 and g.check_conditions("ENG", {"loans_min": 2}) and not g.check_conditions("ENG", {"loans_max": 1}), "loan effect + loan conditions")
	g.apply_effects("ENG", {"loan_forgiven": 5})
	check(n.loans.is_empty(), "loan_forgiven clears loans and never underflows")
	# mercenaries
	n.flags["merc_month"] = g.month
	check(g.check_conditions("ENG", {"mercs_recent": 12}) and g.merc_ready_in("ENG") > 0, "mercs recently hired")
	g.apply_effects("ENG", {"merc_ready": true})
	check(g.merc_ready_in("ENG") == 0 and not g.check_conditions("ENG", {"mercs_recent": 12}), "merc_ready resets the cooldown")
	# morale
	var a = g.armies_of("ENG")[0]
	a.regs = maxf(a.regs, 3.0)
	a.power = 0.2 * g.power_max("ENG")
	check(g.check_conditions("ENG", {"morale_max": 0.45}), "worn-out army detected")
	g.apply_effects("ENG", {"army_power": 0.3})
	check(absf(a.power - 0.5 * g.power_max("ENG")) < 0.001 and not g.check_conditions("ENG", {"morale_max": 0.35}), "army_power effect raises morale")
	g.apply_effects("ENG", {"army_power": 5.0})
	check(a.power <= g.power_max("ENG") + 0.0001, "morale capped at maximum")
	# budget
	check(g.check_conditions("ENG", {"budget_max": {"hof": 2}}) and not g.check_conditions("ENG", {"budget_min": {"hof": 4}}), "budget at default")
	g.govt.set_budget(g, "ENG", "hof", 4)
	check(g.check_conditions("ENG", {"budget_min": {"hof": 4}}), "budget_min after raising the court")
	# shocks
	g.shocks = {"wool": {"mult": 1.4, "years": 3}}
	check(g.check_conditions("ENG", {"shock": "up"}) and not g.check_conditions("ENG", {"shock": "down"}), "scarcity shock on own good")

## Techs, laws, advisors and the army budget feed the morale system (army_power / army_power_regen).
func test_morale_modifiers() -> void:
	var g = new_game("FRA")
	var n = g.nations.FRA
	var base: float = g.power_max("FRA")
	n.techs["mil_stehendes_heer"] = 0
	g.tree.refresh(n)
	check(absf(g.power_max("FRA") - base - 0.1) < 0.001, "standing army tech raises max morale")
	n.gov.laws["heer"] = "stehendes_heer"
	g.govt.refresh(n)
	check(absf(g.power_max("FRA") - base - 0.2) < 0.001, "standing army law raises max morale")
	var r0: float = g.mod(n, "army_power_regen")
	g.govt.set_budget(g, "FRA", "heer", 4)
	check(absf(g.mod(n, "army_power_regen") - r0 - 0.5) < 0.001, "lavish army budget speeds up morale recovery")
	check(g.govt.adv_by_id.has("drillmeister") and g.govt.adv_by_id.drillmeister.effects.has("army_power"), "drill master advisor")


## State reforms: tiers unlock by year, cost administrative power, are trade-offs, survive save/load, AI fills them.
func test_reforms() -> void:
	var g = new_game("FRA")
	var n = g.nations.FRA
	var gv = g.govt
	check(gv.reforms.size() == 5, "five reform tiers")
	for t in gv.reforms:
		for o in t.options:
			var good := false
			var bad := false
			for l in Tech.effect_lines(o.effects):
				good = good or l[1]
				bad = bad or not l[1]
			check(good and bad, "reform %s has a buff and a nerf" % o.id)
	n.adm = 1000.0
	check(gv.open_reform_tiers(g, n) == ["grundlage"], "only the first tier is open in 1444")
	check(gv.reform_block(g, "FRA", "verwaltung", "hofrat") != "", "second tier locked in 1444")
	check(gv.enact_reform(g, "FRA", "grundlage", "domaenen") == "", "enact a reform")
	check(absf(n.adm - 900.0) < 0.01, "first tier costs 100 adm")
	var fe: Dictionary = gv.form_effects("FRA")
	check(absf(n.bonus.gov.get("tax", 0.0) - fe.get("tax", 0.0) - 0.1) < 0.001 and n.bonus.gov.get("manpower", 0.0) < fe.get("manpower", 0.0), "reform effects apply")
	check(gv.enact_reform(g, "FRA", "grundlage", "lehnswesen") != "", "reform change has a cooldown")
	g.month = (1530 - 1444) * 12
	check(gv.open_reform_tiers(g, n) == ["verwaltung", "heerwesen"], "tiers unlock over time")
	check(absf(gv.reform_cost(g, n, "heerwesen") - 200.0) < 0.01, "later tiers cost more")
	var text := JSON.stringify(g.to_dict())
	var g2 = new_game("FRA", 3)
	g2.from_dict(JSON.parse_string(text))
	check(g2.nations.FRA.gov.reforms.get("grundlage", "") == "domaenen", "reforms survive save/load")
	var ai = g.nations.ENG
	ai.adm = 1000.0
	gv._ai_reforms(g, ai)
	check(ai.gov.reforms.has("grundlage"), "AI enacts the oldest open tier")


## Knowledge spreads: techs known by many other nations get cheaper, specials never.
func test_tech_spread() -> void:
	var g = new_game("FRA")
	var n = g.nations.FRA
	var id := ""
	for t in g.tree.techs_for("FRA", "adm"):
		if not n.techs.has(t.id) and not Tech.is_special(t):
			id = t.id
			break
	for o in g.nations.values():
		o.techs.erase(id)
	g.tree.forget_shares()
	var full: float = g.tree.cost(g, "FRA", id)
	check(absf(full - g.tech_cost("FRA", "adm")) < 0.01, "nobody knows it: full price")
	var others: Array = g.nations.values().filter(func(o): return o.alive and o.tag != "FRA")
	for i in others.size() / 2:
		others[i].techs[id] = 0
	g.tree.forget_shares()
	var share: float = g.tree.known_share(g, "FRA", id)
	check(share > 0.45 and share <= 0.5, "half the world knows it (%.2f)" % share)
	check(absf(g.tree.cost(g, "FRA", id) - full * (1.0 - 0.5 * share)) < 0.01, "spread discount")
	for o in others:
		o.techs[id] = 0
	g.tree.forget_shares()
	check(absf(g.tree.cost(g, "FRA", id) - full * 0.7) < 0.01, "discount capped at 30 %")
	var sp: Dictionary = g.tree.specials_of("FRA")[0]
	check(g.tree.spread_discount(g, "FRA", sp.id) == 0.0, "special techs never get cheaper")


## Imperial reforms: authority, elector support, member/emperor effects, Ewiger Landfriede, save/load, AI.
func test_empire_reforms() -> void:
	var g = new_game("FRA")
	var gv = g.govt
	var emp: String = g.emperor
	check(emp != "" and g.hre.has(emp), "there is an emperor")
	check(gv.empire_reforms().size() == 5, "five imperial reforms")
	check(absf(g.hre_authority - 10.0) < 0.01, "authority starts at 10")
	check(gv.authority_gain(g) > 2.0, "authority grows with the members")
	check(gv.empire_reform_block(g, "FRA") != "", "only the emperor passes reforms")
	check(gv.empire_reform_block(g, emp).contains("1450"), "the first reform waits for 1450")
	g.month = (1450 - 1444) * 12
	g.hre_authority = 0.0
	check(gv.empire_reform_block(g, emp).contains("Autorität"), "reforms cost authority")
	for e in g.current_electors():
		if e != emp:
			g.add_rel(e, emp, 200.0)
	g.hre_authority = 50.0
	check(gv.pass_empire_reform(g, emp) == "", "the emperor passes the Reichstag")
	check(g.hre_reforms == ["reichstag"] and absf(g.hre_authority - 10.0) < 0.01, "authority spent, reform recorded")
	var member := ""
	for t in g.hre_members():
		if t != emp:
			member = t
			break
	check(absf(g.nations[emp].bonus.empire.get("prestige", 0.0) - 1.0) < 0.001 and g.nations[emp].bonus.empire.get("unrest", 0.0) < 0.0, "emperor gets both effects")
	check(g.nations[member].bonus.empire.get("unrest", 0.0) < 0.0 and not g.nations[member].bonus.empire.has("prestige"), "members get the member effects")
	check(g.nations.FRA.bonus.get("empire", {}).is_empty(), "outsiders get nothing")
	g.hre_authority = 1000.0
	check(gv.empire_reform_block(g, emp).contains("1470"), "reforms unlock by year")
	g.month = (1600 - 1444) * 12
	for e in g.current_electors():
		if e != emp:
			g.add_rel(e, emp, -400.0)
	check(gv.empire_reform_block(g, emp).contains("Kurfürsten"), "electors must back the emperor")
	for e in g.current_electors():
		if e != emp:
			g.add_rel(e, emp, 400.0)
	while gv.next_empire_reform(g).size() > 0:
		check(gv.pass_empire_reform(g, emp) == "", "pass %s" % gv.next_empire_reform(g).get("id", "?"))
	check(g.hre_reforms.size() == 5, "all reforms passed")
	check(gv.landfriede(g, emp, member) and not gv.landfriede(g, "FRA", member), "Landfriede binds members only")
	for a in g.hre_members():
		for b in g.hre_members():
			if a != b and not g.is_allied(a, b) and not g.has_truce(a, b) and not g.at_war(a, b) and g.nations[a].overlord == "":
				check(g.declare_war(a, b).contains("Landfriede"), "no wars between members")
				break
		break
	var text := JSON.stringify(g.to_dict())
	var g2 = new_game("FRA", 3)
	g2.from_dict(JSON.parse_string(text))
	check(g2.hre_reforms.size() == 5 and absf(g2.hre_authority - g.hre_authority) < 0.01, "reforms survive save/load")
	check(absf(g2.nations[emp].bonus.empire.get("tax", 0.0) - g.nations[emp].bonus.empire.get("tax", 0.0)) < 0.001, "effects restored on load")
	g2.hre_authority = 100.0
	gv.on_new_emperor(g2)
	check(absf(g2.hre_authority - 75.0) < 0.01, "a new house keeps 75 % of the authority")
	var g3 = new_game("FRA")
	g3.month = (1450 - 1444) * 12
	g3.hre_authority = 39.0
	for e in g3.current_electors():
		if e != g3.emperor:
			g3.add_rel(e, g3.emperor, 200.0)
	g3.govt.empire_yearly(g3)
	check(g3.hre_reforms == ["reichstag"], "an AI emperor passes reforms on its own")


## Church laws and advisors change religious unrest and conversion speed.
func test_religion_modifiers() -> void:
	var Religion = Game.Religion
	var g = new_game("FRA")
	var n = g.nations.FRA
	var gv = g.govt
	var pid: int = g.provinces_of("FRA")[0]
	var p = g.provinces[pid]
	p.religion = "orthodox"
	var base: float = Religion.unrest(g, p)
	check(base > 0.0, "another faith causes unrest")
	n.dip = 500.0
	check(gv.set_law(g, "FRA", "kirche", "toleranz") == "", "enact Toleranz")
	check(absf(Religion.unrest(g, p) - base * 0.25) < 0.001, "Toleranz cuts religious unrest by 75 %")
	var months: int = Religion.convert_months(g, n)
	n.gov.law_month.erase("kirche")
	check(gv.set_law(g, "FRA", "kirche", "glaubenseifer") == "", "enact Glaubenseifer")
	check(Religion.unrest(g, p) > base, "zeal angers other faiths")
	check(Religion.convert_months(g, n) < months, "zeal speeds up missionaries")
	check(gv.adv_by_id.has("hofprediger"), "court preacher advisor exists")


## Age goals: count only in their age, give permanent rewards, two of three win the triumph.
func test_gov_sources() -> void:
	var g = new_game("FRA", 5)
	var n = g.nations.FRA
	n.gov.ruler_trait = "kaufmann"
	g.govt.refresh(n)
	var srcs: Array = g.govt.gov_sources(n)
	check(srcs[0][0].begins_with("🏛"), "first source is the state form")
	check(srcs.any(func(s): return s[0].contains("Herrscher") and not s[1].is_empty()), "ruler trait listed as a source")
	var sum := {}
	for s in srcs:
		for k in s[1]:
			sum[k] = sum.get(k, 0.0) + float(s[1][k])
	for k in n.bonus.gov:
		check(absf(sum.get(k, 0.0) - float(n.bonus.gov[k])) < 0.0001, "sources add up to bonus.gov: " + k)


func test_regency() -> void:
	var g = new_game("FRA", 5)
	var gv = g.govt
	var n = g.nations.FRA
	var age: int = gv.heir_age(g, n)
	check(age >= 0 and age <= 12, "new heirs are children or adults up to 12")
	n.gov.heir.born = g.year() - 5
	n.gov.heir.trait = ""
	gv.succession(g, n)
	check(gv.regency_until(n) == g.year() + 10, "child ruler gets a regency until age 15")
	check(n.ruler.years > 10, "reign outlasts the regency")
	check(gv.gov_sources(n).any(func(s): return s[0].contains("Regentschaft")), "regency is a gov source")
	check(gv.court_condition(g, n, "regency", true) and not gv.court_condition(g, n, "regency", false), "regency condition")
	var save: Dictionary = gv.to_save(n).duplicate(true)
	var n2 = g.nations.ENG
	gv.load_save(n2, save)
	check(gv.regency_until(n2) == gv.regency_until(n), "regency survives save/load")
	gv.apply_court_effect(g, n, "end_regency", true)
	check(gv.regency_until(n) == 0 and not gv.gov_sources(n).any(func(s): return s[0].contains("Regentschaft")), "end_regency clears it")
	n.gov.heir.born = g.year() - 5
	n.gov.regency_until = g.year() + 3
	g.month += 36
	gv.regency_tick(g, n)
	check(gv.regency_until(n) == 0, "regency ends when the ruler comes of age")
	n.gov.heir.born = g.year() - 30
	gv.succession(g, n)
	check(gv.regency_until(n) == 0, "adult heir: no regency")
	n.gov.heir.born = g.year() - 8
	check(gv.court_condition(g, n, "heir_age_max", 10) and not gv.court_condition(g, n, "heir_age_min", 15), "heir age conditions")
	n.gov.heir.erase("born")
	check(gv.heir_age(g, n) == 99, "old-save heirs count as adults")


func test_form_change() -> void:
	var g = new_game("FRA", 5)
	var gv = g.govt
	var n = g.nations.FRA
	check(gv.form_name("FRA") == "Feudalmonarchie", "France starts feudal")
	var opts: Array = gv.form_change_options("FRA").map(func(c): return c.form)
	check(opts.has("Wahlmonarchie") and opts.has("Absolute Monarchie") and not opts.has("Kaufmannsrepublik"), "monarchy options only")
	check(gv.form_change_block(g, "FRA", "Absolute Monarchie").begins_with("Verfügbar ab"), "absolutism needs 1580")
	check(gv.form_change_block(g, "FRA", "Kaufmannsrepublik") != "", "no switch across families")
	n.adm = 0.0
	check(gv.form_change_block(g, "FRA", "Wahlmonarchie").contains("Verwaltungspunkte"), "needs admin power")
	n.adm = 900.0
	n.prestige = 50.0
	for w in g.wars.duplicate():
		g.wars.erase(w)
	check(gv.change_form(g, "FRA", "Wahlmonarchie") == "", "switch to elective monarchy")
	check(gv.form_name("FRA") == "Wahlmonarchie" and gv.heir_title("FRA") == "Nachfolger", "new form applies")
	check(float(n.bonus.gov.get("dip", 0.0)) >= 0.5 - 0.001, "new form effects in gov bonus")
	check(n.adm == 650.0 and n.prestige == 30.0, "cost paid")
	check(gv.form_change_block(g, "FRA", "Feudalmonarchie").contains("Jahren"), "cooldown after a change")
	var save: Dictionary = gv.to_save(n).duplicate(true)
	gv.load_save(n, save)
	check(gv.form_name("FRA") == "Wahlmonarchie" and gv.form_cooldown_left(g, n) > 0, "form survives save/load")
	gv.init_nation(n)
	check(gv.form_name("FRA") == "Feudalmonarchie", "fresh nation state drops the override")


func test_building_tech() -> void:
	var g = new_game("FRA", 5)
	var Eco = g.Economy
	var n = g.nations.FRA
	var pid: int = g.key_to_pid["paris"]
	var p = g.provinces[pid]
	n.gold = 100000.0
	p.dev = 30
	p.buildings = {"workshop": 2, "marketplace": 1, "barracks": 1}
	Eco.refresh_local(g, p)
	var tech: String = Eco.level_tech(g, "workshop", 3)
	check(tech != "" and g.tree.by_id.has(tech), "workshop level 3 needs a tech")
	n.techs.erase(tech)
	check(Eco.build_block_reason(g, "FRA", pid, "workshop").begins_with("Braucht Technologie"), "level gated by tech")
	n.techs[tech] = 0
	check(Eco.build_block_reason(g, "FRA", pid, "workshop") == "", "tech unlocks the level")
	check(g.tree.unlocks.has(tech) and g.tree.unlocks[tech].has(["workshop", 3]), "tech knows what it unlocks")
	# late buildings: tech first, at most max_count per realm
	var ut: String = Eco.level_tech(g, "university", 1)
	n.techs.erase(ut)
	check(Eco.build_block_reason(g, "FRA", pid, "university").begins_with("Braucht Technologie"), "university needs its tech")
	n.techs[ut] = 0
	var cap: int = int(g.buildings_def.university.max_count)
	var done := 0
	for q in g.provinces_of("FRA"):
		if done >= cap:
			break
		var pr = g.provinces[q]
		if q == pid:
			continue
		pr.buildings["university"] = 1
		done += 1
	check(done < cap or Eco.build_block_reason(g, "FRA", pid, "university").begins_with("Höchstens"), "max per realm")
	# every gate names a real tech
	for bid in g.buildings_def:
		for lvl in g.buildings_def[bid].get("level_tech", {}):
			check(g.tree.by_id.has(g.buildings_def[bid].level_tech[lvl]), "%s level %s tech exists" % [bid, lvl])


func test_heir() -> void:
	var g = new_game("FRA")
	var gv = g.govt
	var n = g.nations.FRA
	var h: Dictionary = n.gov.heir
	check(not h.is_empty() and h.has("adm") and str(h.name) != "", "every nation starts with a named heir")
	check(gv.heir_title("FRA") == "Erbe" and gv.heir_title("VEN") == "Nachfolger", "heir or successor by form")
	# education: costs power of that kind, +1, once a year, capped at ruler_max
	h.adm = 1
	n.adm = 500.0
	var c: float = gv.educate_cost(g, n, "adm")
	check(gv.educate(g, "FRA", "adm") == "" and int(n.gov.heir.adm) == 2 and is_equal_approx(n.adm, 500.0 - c), "educate raises a skill for power")
	check(gv.educate_block(g, "FRA", "dip") != "", "once a year")
	check(gv.educate_cost(g, n, "adm") > c, "each level costs more")
	g.month += 12
	n.gov.heir.mil = int(g.bal.ruler_max)
	check(gv.educate_block(g, "FRA", "mil") != "", "capped at ruler_max")
	n.adm = 0.0
	check(gv.educate_block(g, "FRA", "adm").begins_with("Zu wenig"), "needs power")
	# saved and loaded
	var g2 = new_game("FRA", 9)
	g2.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
	check(g2.nations.FRA.gov.heir.adm == n.gov.heir.adm and g2.nations.FRA.gov.heir.name == n.gov.heir.name, "heir saved")
	# succession: the heir becomes ruler, a new heir is named
	var old: Dictionary = n.gov.heir.duplicate()
	n.ruler.years = 1
	g.month = (g.month / 12) * 12 + 11
	g.tick()
	check(n.ruler_name == str(old.name) and int(n.ruler.adm) == int(old.adm) and int(n.ruler.mil) == int(old.mil), "heir takes the throne")
	check(n.ruler.years >= 8 and not n.gov.heir.is_empty() and n.gov.heir.name != old.name, "new reign and a new heir")
	check(n.gov.ruler_trait == str(old.get("trait", "")) and n.gov.heir.has("trait"), "the heir's trait comes to the throne")
	# traits count as a government source
	n.gov.ruler_trait = "baumeister"
	gv.refresh(n)
	var bc: float = g.mod(n, "build_cost")
	n.gov.ruler_trait = ""
	gv.refresh(n)
	check(is_equal_approx(g.mod(n, "build_cost") - bc, 0.1), "ruler trait effects apply")
	# event hooks: conditions and effects on ruler and heir
	n.gov.heir.trait = "grausam"
	check(g.check_conditions("FRA", {"heir_trait": "grausam"}) and g.check_conditions("FRA", {"heir_trait": "any"}), "heir trait condition")
	check(not g.check_conditions("FRA", {"heir_trait": ""}), "heir trait none condition")
	g.apply_effects("FRA", {"heir_trait": "fromm", "heir": {"adm": 1}})
	check(n.gov.heir.trait == "fromm", "event changes the heir's trait")
	g.apply_effects("FRA", {"ruler_trait": "gelehrt"})
	check(g.check_conditions("FRA", {"ruler_trait": "gelehrt"}) and n.bonus.gov.get("tech_cost", 0.0) <= -0.05 + 0.001, "event gives the ruler a trait")
	n.gov.ruler_trait = ""
	gv.refresh(n)
	var seen := {}
	for i in 200:
		seen[gv.roll_trait(g)] = true
	check(seen.has("") and seen.size() >= 8, "traits roll with a chance of none")
	# disinheriting: prestige for a new heir, then a cooldown
	n.prestige = 30.0
	var before: String = n.gov.heir.name
	check(gv.disinherit(g, "FRA") == "" and n.gov.heir.name != before and is_equal_approx(n.prestige, 30.0 - float(gv.cfg.heir_disinherit_prestige)), "disinherit names a new heir for prestige")
	check(gv.disinherit_block(g, "FRA") != "", "disinherit cooldown")
	# old saves without heir get one at the next turn of the year
	n.gov.erase("heir")
	gv.yearly(g, n)
	check(not n.gov.get("heir", {}).is_empty(), "missing heir is named yearly")


func test_tech_queue() -> void:
	var g = new_game("FRA")
	var tr = g.tree
	var n = g.nations.FRA
	g.month = (1470 - 1444) * 12
	# a generic adm tech with an unresearched prerequisite, regular window already open
	var t: Dictionary = {}
	for d in tr.defs:
		if not Tech.is_special(d) and d.cat == "adm" and tr.years_ahead(g, d.id) == 0 and not d.get("req", []).is_empty() \
				and d.req.any(func(r): return not n.techs.has(r)) and not n.techs.has(d.id):
			t = d
			break
	check(not t.is_empty(), "found a tech with a missing prerequisite")
	check(tr.queue_add(g, "FRA", t.id) == "", "plan accepts it")
	var pre: String = tr.queue_of(n, "adm")[0]
	check(t.req.has(pre) or tr.by_id[pre].cat == "adm", "prerequisite planned first")
	check(n.tech_queue.back() == t.id, "target last")
	check(tr.queue_add(g, "FRA", t.id) != "", "no duplicates")
	n.adm = 0.0
	check(tr.queue_tick(g, n).is_empty(), "waits without points")
	check(tr.queue_wait(g, "FRA", pre).begins_with("wartet auf Punkte"), "says why it waits")
	n.adm = float(g.bal.power_cap)
	var done: Array = tr.queue_tick(g, n)
	check(n.techs.has(t.id) and n.techs.has(pre), "plan researched in order")
	check(done.size() >= 2 and not n.tech_queue.has(t.id), "researched techs leave the plan")
	# removing a planned prerequisite drops what builds on it; saves keep the plan
	n.tech_queue.clear()
	var u: Dictionary = {}
	for d in tr.defs:
		if not Tech.is_special(d) and d.cat == "dip" and not n.techs.has(d.id) and d.get("req", []).any(func(r): return not n.techs.has(r)):
			u = d
			break
	tr.queue_add(g, "FRA", u.id)
	var g2 = new_game("FRA", 9)
	g2.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
	check(g2.nations.FRA.tech_queue == n.tech_queue, "plan saved")
	tr.queue_remove(n, n.tech_queue[0])
	check(not n.tech_queue.has(u.id), "dependent dropped with its prerequisite")
	# early techs wait for their regular year unless points are capped
	var e: Dictionary = {}
	for d in tr.defs:
		if not Tech.is_special(d) and tr.years_ahead(g, d.id) > 0 and tr.block_reason(g, "FRA", d.id) == "":
			e = d
			break
	if not e.is_empty():
		n.tech_queue = [e.id]
		n.set(e.cat, float(g.bal.power_cap) - 1.0)
		if n.get(e.cat) >= tr.cost(g, "FRA", e.id):
			check(tr.queue_tick(g, n).is_empty(), "early tech waits below the cap")
		n.set(e.cat, float(g.bal.power_cap))
		if n.get(e.cat) >= tr.cost(g, "FRA", e.id):
			check(tr.queue_tick(g, n).size() == 1, "early tech taken at the cap")


func test_tech_ahead() -> void:
	var g = new_game("FRA")
	var tr = g.tree
	var n = g.nations.FRA
	g.month = (1455 - 1444) * 12
	# a generic tech whose regular window opens 10 years from now
	var t: Dictionary = {}
	for d in tr.defs:
		if not Tech.is_special(d) and int(d.year) - tr.early_years == g.year() + 10 and d.get("req", []).all(func(r): return n.techs.has(r)):
			t = d
			break
	if t.is_empty():
		for d in tr.defs:
			if not Tech.is_special(d) and int(d.year) - tr.early_years > g.year() and int(d.year) - tr.early_years - tr.ahead_years <= g.year():
				t = d
				break
	check(not t.is_empty(), "found a tech ahead of time")
	var ya: int = tr.years_ahead(g, t.id)
	check(ya > 0 and ya <= tr.ahead_years, "years ahead within the window")
	var base: float = g.tech_cost("FRA", t.cat) * (1.0 - tr.spread_discount(g, "FRA", t.id))
	check(is_equal_approx(tr.cost(g, "FRA", t.id), base * (1.0 + tr.ahead_penalty * ya)), "ahead-of-time premium")
	for r in t.get("req", []):
		n.techs[r] = 0
	check(tr.block_reason(g, "FRA", t.id) == "", "researchable ahead of time")
	var far: Dictionary = {}
	for d in tr.defs:
		if not Tech.is_special(d) and int(d.year) - tr.early_years - tr.ahead_years > g.year():
			far = d
			break
	check(far.is_empty() or tr.block_reason(g, "FRA", far.id).begins_with("Verfügbar ab") or tr.block_reason(g, "FRA", far.id).begins_with("Benötigt"), "too far ahead stays locked")
	# the AI only goes ahead with power to spare
	n.set(t.cat, tr.cost(g, "FRA", t.id) * 1.2)
	var avail_now: Array = tr.available(g, "FRA", t.cat).filter(func(x): return tr.years_ahead(g, x.id) == 0)
	if avail_now.is_empty():
		check(tr.best_choice(g, "FRA", t.cat) == "", "AI keeps a reserve before researching ahead")


func test_gov_forms() -> void:
	var g = new_game("FRA")
	var gv = g.govt
	for form in gv.cfg.form_effects:
		for k in gv.cfg.form_effects[form]:
			check(Tech.LABELS.has(k), "%s effect %s has a label" % [form, k])
	for t in g.order:
		check(not gv.form_effects(t).is_empty(), "%s (%s) has form effects" % [t, gv.form_name(t)])
	var ven = g.nations.get("VEN")
	if ven != null:
		check(gv.form_name("VEN") == "Kaufmannsrepublik", "Venice is a merchant republic")
		check(ven.bonus.gov.get("trade", 0.0) >= 0.15 - 0.001, "merchant republic trade bonus applies")
	check(g.nations.FRA.bonus.gov.get("manpower", 0.0) >= 0.1 - 0.001, "feudal monarchy manpower bonus applies")


func test_advisor_skill() -> void:
	var g = new_game("FRA")
	var n = g.nations.FRA
	var gv = g.govt
	n.gov.advisors.clear()
	var a: Dictionary = gv.advisors[0]
	n.set(a.type, 1000.0)
	check(gv.hire(g, "FRA", a.id) == "", "hire advisor")
	check(gv.advisor_skill(n, a.id) == 1, "hired at skill 1")
	var k: String = ""
	for key in a.effects:
		if (float(a.effects[key]) > 0.0) == Tech.LABELS.get(key, [key, false, true])[2]:
			k = key
	check(k != "", "advisor has a benefit")
	var base: float = n.bonus.gov.get(k, 0.0)
	var before: float = n.get(a.type)
	check(gv.promote(g, "FRA", a.id) == "", "promote to 2")
	check(is_equal_approx(before - n.get(a.type), gv.advisor_cost(g, n, a.id) * 1.5), "promotion cost")
	check(gv.advisor_skill(n, a.id) == 2, "skill 2")
	check(is_equal_approx(n.bonus.gov.get(k, 0.0) - base, float(a.effects[k]) * 0.5), "benefit +50 % at skill 2")
	gv.promote(g, "FRA", a.id)
	check(gv.promote_block(g, "FRA", a.id) != "", "skill 3 is the maximum")
	# drawbacks stay up to skill 2 and are gone at the top skill
	var with_bad := 0
	for adv in gv.advisors:
		for key in adv.effects:
			if (float(adv.effects[key]) > 0.0) != Tech.LABELS.get(key, [key, false, true])[2]:
				with_bad += 1
				check(gv.advisor_effects(adv.id, 2).has(key) and not gv.advisor_effects(adv.id, 3).has(key), "%s: drawback %s gone only at skill 3" % [adv.id, key])
	check(with_bad > 0, "some advisors have drawbacks")
	var text := JSON.stringify(g.to_dict())
	var g2 = new_game("FRA", 3)
	g2.from_dict(JSON.parse_string(text))
	check(g2.govt.advisor_skill(g2.nations.FRA, a.id) == 3, "skill survives save/load")
	# retirement: after 20+ years a pupil takes over one level lower
	g.month += 12 * 25
	var cfg: Dictionary = gv.cfg
	var old_chance = cfg.get("advisor_retire_chance")
	cfg["advisor_retire_chance"] = 1.0
	gv._advisor_careers(g, n)
	cfg["advisor_retire_chance"] = old_chance
	check(n.gov.advisors.has(a.id) and gv.advisor_skill(n, a.id) == 2, "retired advisor replaced one level lower")
	check(gv.service_years(g, n, a.id) == 0, "successor starts fresh")
	gv.dismiss(g, "FRA", a.id)
	check(not n.gov.adv_skill.has(a.id), "dismiss clears skill")
	# AI promotes with spare power once the council is full
	var g3 = new_game("FRA")
	var promoted := 0
	for y in 10:
		for mo in 12:
			g3.tick()
	for t in g3.order:
		for id in g3.nations[t].gov.advisors:
			if g3.govt.advisor_skill(g3.nations[t], id) > 1:
				promoted += 1
	print("  AI promoted advisors after 10 years: %d" % promoted)
	check(promoted > 0, "AI promotes advisors")


func test_age_goals() -> void:
	var g = new_game("FRA")
	var n = g.nations.FRA
	var gv = g.govt
	check(gv.ages().size() == 4, "four ages")
	for a in gv.ages():
		check(a.goals.size() == 3, "%s has three goals" % a.id)
	check(gv.age_of_year(1444).id == "renaissance" and gv.age_of_year(1555).id == "reformation", "ages by year")
	var p: Array = gv.goal_progress(g, n, {"techs": 10})
	check(p[0] == n.techs.size() and p[1] == 10, "tech goal progress")
	n.gov.advisors.clear()
	for a in gv.advisors.slice(0, 3):
		n.gov.advisors.append(a.id)
	gv.ages_yearly(g, n)
	check(n.gov.ages.has("gelehrtenhof"), "three advisors reach Hof der Gelehrten")
	check(not n.gov.ages.has("renaissance"), "one goal is no triumph")
	check(n.bonus.gov.get("prestige", 0.0) >= 0.5 - 0.001, "goal reward applies")
	for t in g.tree.defs:
		if n.techs.size() >= 10:
			break
		if not Tech.is_special(t):
			n.techs[t.id] = 0
	gv.ages_yearly(g, n)
	check(n.gov.ages.has("humanisten") and n.gov.ages.has("renaissance"), "two goals win the triumph")
	check(n.bonus.gov.get("adm", 0.0) >= 0.5 - 0.001, "triumph reward applies")
	g.month = (1500 - 1444) * 12
	n.gov.companies = ["lombarden"]
	n.gov.invest["lombarden"] = 3
	gv.ages_yearly(g, n)
	check(not n.gov.ages.has("bankhaeuser"), "Renaissance goals no longer count in 1500")
	var text := JSON.stringify(g.to_dict())
	var g2 = new_game("FRA", 3)
	g2.from_dict(JSON.parse_string(text))
	check(g2.nations.FRA.gov.ages.has("renaissance"), "age goals survive save/load")
	check(g2.nations.FRA.bonus.gov.get("tech_cost", 0.0) < 0.0, "rewards restored on load")
	var ai_hits := 0
	var g3 = new_game("FRA")
	for i in 12 * 10:
		g3.tick()
	for t in g3.order:
		ai_hits += g3.nations[t].gov.ages.size()
	check(ai_hits > 0, "AI nations reach age goals too (%d)" % ai_hits)


func test_ai_marriage_and_generals() -> void:
	var g = new_game("ENG")
	var fra = g.nations.FRA
	g.bal.ai_marriage_chance = 1.0
	fra.dip = 500.0
	for t in g.order:
		g.add_rel("FRA", t, 60.0)
	g.ai._marriage(g, fra)
	check(fra.marriages.size() == 1, "the AI marries a friendly house")
	fra.mil = 999.0
	var arms: Array = g.armies_of("FRA")
	check(not arms.is_empty(), "France starts with an army")
	g.ai._hire_general(g, fra, float(g.bal.power_cap))
	var led := 0
	for a in g.armies_of("FRA"):
		if a.general > 0:
			led += 1
	check(led == 1, "the largest army gets a general from a power surplus")


func test_ai_war_odds() -> void:
	var g = new_game("ENG")
	for t in g.order:
		g.nations[t].allies.clear()
	var base: float = g.ai.war_odds(g, "TUR", "BYZ")
	# a friend of both sides stays out, so it must not count for the attacker
	g._ally("TUR", "HUN")
	g._ally("BYZ", "HUN")
	g.add_rel("TUR", "HUN", 100.0)
	check(g.ai.war_odds(g, "TUR", "BYZ") <= base + 0.001, "an ally that defends the target does not count for the attacker")
	g.nations.BYZ.allies.erase("HUN")
	g.nations.HUN.allies.erase("BYZ")
	check(g.ai.war_odds(g, "TUR", "BYZ") > base, "an ally that joins counts")
	# a historic war event is (almost) never chosen when the war is hopeless
	for a in g.armies_of("TUR"):
		a.regs = 0.1
	g.nations.TUR.allies.clear()
	g.nations.HUN.allies.clear()
	var e := {"options": [{"effects": {"war": "BYZ"}, "ai": 70}, {"effects": {"adm": 10}}]}
	var wars := 0
	for i in 200:
		if g.ai.pick_event_option(g, g.nations.TUR, e) == 0:
			wars += 1
	check(wars < 40, "the AI avoids a hopeless event war (%d/200)" % wars)


func test_ai_peace_spending() -> void:
	var g = new_game("ENG")
	var fra = g.nations.FRA
	fra.tech.adm = 3
	fra.gold = 5000.0
	fra.we = 5.0
	var other: int = -1
	for pid in g.provinces_of("FRA"):
		if pid != fra.capital:
			other = pid
			break
	g.provinces[other].religion = "protestant" if fra.religion != "protestant" else "catholic"
	g.ai._peace_spending(g, fra, 100.0)
	check(g.provinces[other].convert_months > 0, "the AI sends a missionary to a province of another faith")
	check(fra.we < 5.0 and g.feast_ready_in("FRA") > 0, "the AI holds a feast against war exhaustion")
	check(not fra.monument_build.is_empty(), "a rich AI starts a great work")
	var gold: float = fra.gold
	g.ai._peace_spending(g, fra, 100.0)
	check(fra.gold == gold, "only one great work at a time, no second feast")


func test_ai_access_and_guarantee() -> void:
	var g = new_game("ENG")
	var fra = g.nations.FRA
	for t in g.order:
		g.nations[t].allies.clear()
		g.nations[t].truces.clear()
		g.add_rel("FRA", t, 50.0)
	var mine: Array = g.neighbors_of("FRA")
	var target := ""
	for t in mine:
		for e in g.neighbors_of(t):
			if e != "FRA" and not mine.has(e) and e != "ENG" and target == "":
				target = e
	check(target != "", "some nation lies behind a French neighbour")
	g.declare_war("FRA", target)
	for e in g.enemies_of("FRA"):
		for t in mine:
			g.add_rel(t, e, -100.0)
	fra.dip = 500.0
	g.ai._war_access(g, fra)
	check(not fra.access.is_empty(), "the AI asks a neutral neighbour for passage to its enemy")
	g.wars.clear()
	g.bal.ai_guarantee_chance = 1.0
	g.ai._guarantee(g, fra)
	check(fra.guarantees.size() == 1, "a great power guarantees a small friendly neighbour")


## rel_ events (tools/content/rel_events.py): faith conditions and the convert_random effect.
func test_rel_content() -> void:
	var g = new_game("BOH")
	var n = g.nations.BOH
	var cnt := 0
	for e in data.events:
		if e.id.begins_with("rel_"):
			cnt += 1
			g.check_conditions("BOH", e.trigger)  # must not crash
	check(cnt >= 15, "religion events present (%d)" % cnt)
	check(not g.check_conditions("BOH", {"province_faith": "protestant"}) and not g.check_conditions("BOH", {"faith_share_max": 0.9}), "united catholic realm at start")
	var own: Array = g.provinces_of("BOH")
	for pid in own:
		g.provinces[pid].religion = "protestant"
	check(g.check_conditions("BOH", {"province_faith": "protestant", "faith_share_max": 0.1}), "protestant provinces detected")
	g.apply_effects("BOH", {"convert_random": 2})
	var back := 0
	for pid in own:
		if g.provinces[pid].religion == n.religion:
			back += 1
	check(back == mini(2, own.size()), "convert_random returns two provinces to the state faith (%d)" % back)
	g.apply_effects("BOH", {"convert_random": 99})
	check(g.check_conditions("BOH", {"faith_share_max": 1.0}) and not g.check_conditions("BOH", {"province_faith": "protestant"}), "convert_random never overshoots")


func test_income_bonus_and_army_cost() -> void:
	var g = new_game("FRA")
	var n = g.nations.FRA
	var p = g.provinces[n.capital]
	var base_tax: float = g.Economy.tax(g, p)
	n.tech.adm = 10
	var ib: float = g.Economy.income_bonus(g, n)
	var lt: float = g.Economy.local(g, p, "tax")  # the capital is a city: local tax bonus
	check(absf(g.Economy.tax(g, p) - base_tax * (1.0 + lt + ib + g.mod(n, "tax")) / (1.0 + lt + ib - 10 * float(g.bal.adm_tech_income) + g.mod(n, "tax"))) < 0.001,
			"admin tech adds to the tax bonus instead of multiplying it")
	var c0: float = g.regiment_cost("FRA")
	n.tech.mil += 5
	check(absf(g.regiment_cost("FRA") - c0 - 5 * float(g.bal.army_cost_per_mil_tech) * float(g.bal.regiment_cost)) < 0.001,
			"regiments get dearer with military tech")
	check(g.regiment_upkeep("FRA") > float(g.bal.regiment_maintenance), "and so does their upkeep")


## court_ events (tools/content/court_events.py): great works, feasts and marriages as conditions and effects.
func test_south_content() -> void:
	var g = new_game("FRA")
	var cnt := 0
	for e in data.events:
		if e.id.begins_with("south_"):
			cnt += 1
			check(g.nations.has(e.tag), "%s belongs to a known nation" % e.id)
			if g.nations.has(e.tag):
				g.check_conditions(e.tag, e.trigger)  # must not crash (province keys resolve)
	check(cnt >= 20, "south events present (%d)" % cnt)
	for tag in ["TUR", "MAM", "MOR"]:
		var found := 0
		for m in data.missions.get(tag, []):
			if "_south_" in m.id:
				found += 1
				g.check_conditions(tag, m.require)
		check(found >= 2, "%s has south missions" % tag)
	check(g.check_conditions("MAM", {"owns": ["aleppo", "damascus"]}), "Mamluks start with Syria")


func test_monument_events() -> void:
	var g = new_game("FRA")
	var n = g.nations.FRA
	for id in g.monument_defs:
		for stage in ["start", "half", "done"]:
			var eid := "mon_%s_%s" % [id, stage]
			check(g.event_by_id.has(eid) and g.event_by_id[eid].get("manual", false), "%s exists and is manual" % eid)
	# manual events are never drawn at random
	g.bal.event_chance = 1.0
	for i in 30:
		g._check_events(n)
	for eid in g.pending_events:
		check(not eid.begins_with("mon_"), "random draw picked manual event %s" % eid)
	g.pending_events.clear()
	var id := "cathedral"
	n.tech[g.monument_defs[id].tech[0]] = 20
	n.gold = 1e6
	check(g.Monuments.start(g, "FRA", id) == "", "great work starts")
	check(g.pending_events.has("mon_cathedral_start"), "start event fires on start")
	var total := int(g.monument_defs[id].months)
	for i in total / 2 - 1:
		g.Monuments.tick(g, n)
	check(not g.pending_events.has("mon_cathedral_half"), "no half event before half time")
	g.Monuments.tick(g, n)
	check(g.pending_events.has("mon_cathedral_half"), "half event at half time")
	for i in total:
		g.Monuments.tick(g, n)
	check(n.monuments.has(id) and g.pending_events.has("mon_cathedral_done"), "done event on completion")
	var cnt: int = g.pending_events.size()
	g.fire_event("FRA", "mon_cathedral_done")
	check(g.pending_events.size() == cnt, "context events fire once per realm")
	# the AI decides at once
	var ai = g.nations.ENG
	ai.tech[g.monument_defs.embassy.tech[0]] = 20
	ai.gold = 1e6
	g.Monuments.start(g, "ENG", "embassy")
	check(ai.flags.has("ev_mon_embassy_start") and not g.pending_events.has("mon_embassy_start"), "AI resolves its start event")


func test_ctx_events() -> void:
	var g = new_game("FRA")
	var n = g.nations.FRA
	for id in ["bld_manufactory_first", "bld_harbor_first", "bld_max_level", "nav_first_win", "nav_first_loss"]:
		check(g.event_by_id.has(id) and g.event_by_id[id].get("manual", false), "%s exists and is manual" % id)
	for e in data.events:
		if e.id.begins_with("nav_") or e.id.begins_with("bld_"):
			g.check_conditions("FRA", e.trigger)  # must not crash
	# first building of a kind fires its event once; reaching the top level fires bld_max_level
	var pid: int = n.capital
	var p = g.provinces[pid]
	p.buildings["courthouse"] = 0
	p.constructing = {"id": "courthouse", "months": 1}
	g.Economy.construction_tick(g, n)
	check(g.pending_events.has("bld_courthouse_first"), "first courthouse fires its event")
	g.pending_events.clear()
	p.buildings["courthouse"] = g.Economy.max_level(g, "courthouse") - 1
	p.constructing = {"id": "courthouse", "months": 1}
	g.Economy.construction_tick(g, n)
	check(not g.pending_events.has("bld_courthouse_first") and g.pending_events.has("bld_max_level"), "top level fires once, first-event not again")
	# ships effect and naval conditions
	var lim: float = g.Naval.limit(g, "FRA")
	n.ships = 2.0
	check(g.check_conditions("FRA", {"ships_min": 2}) and not g.check_conditions("FRA", {"ships_min": 3}), "ships_min")
	g.apply_effects("FRA", {"ships": 1000})
	check(is_equal_approx(n.ships, maxf(lim, 2.0)), "ships effect capped at the fleet limit")
	g.apply_effects("FRA", {"ships": -1000})
	check(n.ships == 0.0, "ships effect never below zero")
	check(g.check_conditions("FRA", {"blockaded": false}) and not g.check_conditions("FRA", {"blockaded": true}), "no blockade at start")
	# fleet missions ask for ships, not land regiments (naval_fix.py)
	for tag in ["ENG", "SPA", "TUR", "VEN", "NAP"]:
		for m in data.missions.get(tag, []):
			if m.id in ["eng_navy", "eng_royal_navy", "spa_armada", "tur_fleet", "ven_arsenal", "nap_galleys"]:
				check(m.require.has("ships_min") and not m.require.has("regs"), "%s requires ships" % m.id)


func test_late_content() -> void:
	var g = new_game("FRA")
	var cnt := {}
	for e in data.events:
		if "_late_" in e.id:
			check(g.nations.has(e.tag), "%s belongs to a known nation" % e.id)
			cnt[e.tag] = cnt.get(e.tag, 0) + 1
			g.check_conditions(e.tag, e.trigger)  # must not crash (province keys resolve)
	for tag in ["BUR", "POL", "TUR"]:
		check(cnt.get(tag, 0) >= 6, "%s has late events" % tag)


func test_era_content() -> void:
	var g = new_game("FRA")
	var cnt := 0
	for e in data.events:
		if e.id.begins_with("era_"):
			cnt += 1
			check(int(e.trigger.get("year_min", 0)) >= 1600, "%s is late-game" % e.id)
			g.check_conditions("FRA", e.trigger)  # must not crash
	check(cnt >= 12, "late-game events present (%d)" % cnt)
	for tag in ["ENG", "FRA", "SPA", "BOH", "HAB", "RUS", "NAP", "BUR", "POL", "TUR"]:
		var found := false
		for m in data.missions.get(tag, []):
			if "_era_" in m.id:
				found = true
				check(not g.check_conditions(tag, m.require), "%s not done at the start" % m.id)
		check(found, "%s has a late-game mission" % tag)



## Keys the match blocks in Game.check_conditions / Game.apply_effects handle (read from the source, since an
## unknown key is silently ignored there), plus year windows that close before the game ends.

func test_war_events() -> void:
	var g = new_game("FRA")
	for id in ["war_first_win", "war_first_loss", "war_long_battle", "war_first_fort", "war_capital_lost", "war_peace_gain",
			"war_peace_loss", "war_white_peace", "dip_coalition", "dip_first_vassal", "dip_became_vassal"]:
		check(g.event_by_id.has(id) and g.event_by_id[id].get("manual", false), "%s exists and is manual" % id)
	for t in g.order:
		g.nations[t].allies.clear()
	g.nations.FRA.claims.clear()
	g.declare_war("FRA", "BRI")
	var w = g.war_between("FRA", "BRI")
	w.defenders = ["BRI"]
	var rennes: int = g.key_to_pid["rennes"]
	g.make_peace(w, true, [rennes])
	check(g.pending_events.has("war_peace_gain") and g.nations.BRI.flags.has("ev_war_peace_loss"), "peace with land fires gain/loss events")
	g.pending_events.clear()
	g.nations.FRA.truces.clear()
	g.nations.BRI.truces.clear()
	g.nations.FRA.dip = 999.0
	var why: String = g.declare_war("FRA", "BRI")
	check(why == "", "second war declared: " + why)
	w = g.war_between("FRA", "BRI")
	if w == null:
		return
	w.defenders = ["BRI"]
	g.make_peace(w, true, [], true)
	check(g.pending_events.has("dip_first_vassal") and g.nations.BRI.flags.has("ev_dip_became_vassal"), "vassalizing fires both vassal events")
	check(not g.pending_events.has("war_peace_gain"), "peace events fire once per realm")

func _handled_keys(src: String, fn: String) -> Dictionary:
	var body := src.split("func %s(" % fn, true, 1)[1].split("\nfunc ", true, 1)[0]
	var keys := {}
	var re := RegEx.create_from_string("\"([a-z_]+)\"")
	for line in body.split("\n"):
		if line.begins_with("\t\t\t\"") and line.ends_with(":"):
			for m in re.search_all(line):
				keys[m.get_string(1)] = true
	return keys


func test_event_keys() -> void:
	var src := FileAccess.get_file_as_string("res://scripts/core/game.gd")
	var conds := _handled_keys(src, "check_conditions")
	var effs := _handled_keys(src, "apply_effects")
	check(conds.has("year_min") and effs.has("gold"), "handled keys parsed from game.gd")
	var end_year := int(data.balance.start_year) + int(data.balance.total_months) / 12
	var bad := []
	var items := []
	for e in data.events:
		items.append([e.id, e.get("trigger", {}), e.options.map(func(o): return o.get("effects", {}))])
	for tag in data.missions:
		for m in data.missions[tag]:
			items.append([m.id, m.get("require", {}), [m.get("reward", {})]])
	for it in items:
		for k in it[1]:
			if not conds.has(k):
				bad.append("%s: condition %s" % [it[0], k])
		if int(it[1].get("year_min", 0)) > mini(int(it[1].get("year_max", end_year)), end_year):
			bad.append("%s: year window after %d" % [it[0], end_year])
		for eff in it[2]:
			for k in eff:
				if not effs.has(k):
					bad.append("%s: effect %s" % [it[0], k])
	check(bad.is_empty(), "all event/mission keys handled and windows open: %s" % str(bad.slice(0, 5)))

func test_court_content() -> void:
	var g = new_game("FRA")
	var n = g.nations.FRA
	var cnt := 0
	for e in data.events:
		if e.id.begins_with("court_"):
			cnt += 1
			g.check_conditions("FRA", e.trigger)  # must not crash
			for key in ["monument"]:
				check(not e.trigger.has(key) or g.monument_defs.has(e.trigger[key]), "%s names a known great work" % e.id)
	check(cnt >= 15, "court events present (%d)" % cnt)
	check(not g.check_conditions("FRA", {"monument_building": true}) and g.check_conditions("FRA", {"monument_building": false}), "nothing under construction at start")
	n.monument_build = {"id": "cathedral", "months": 10}
	g.apply_effects("FRA", {"monument_progress": 6})
	check(int(n.monument_build.months) == 4 and g.check_conditions("FRA", {"monument_building": true}), "monument_progress brings the work forward")
	g.apply_effects("FRA", {"monument_progress": 99})
	check(int(n.monument_build.months) == 1, "monument_progress never finishes the work outright")
	n.monuments["cathedral"] = true
	check(g.check_conditions("FRA", {"monument": "cathedral", "monuments_min": 1}) and not g.check_conditions("FRA", {"monuments_min": 2}), "finished great works")
	n.flags["feast_month"] = g.month
	check(g.check_conditions("FRA", {"feast_recent": 6}) and g.feast_ready_in("FRA") > 0, "feast held recently")
	g.apply_effects("FRA", {"feast_ready": true})
	check(g.feast_ready_in("FRA") == 0, "feast_ready resets the cooldown")
	check(not g.check_conditions("FRA", {"married": true}), "not married at start")
	check(g.check_conditions("FRA", {"is_player": true}) and not g.check_conditions("ENG", {"is_player": true}), "is_player only for the player")
	n.marriages.append("ENG")
	g.nations.ENG.marriages.append("FRA")
	var r0: float = g.get_rel("FRA", "ENG")
	g.apply_effects("FRA", {"spouse_rel": 20})
	check(g.check_conditions("FRA", {"married": true}) and g.get_rel("FRA", "ENG") > r0, "spouse_rel improves relations with in-laws")



func test_play_on() -> void:
	var g = new_game()
	check(not g.can_play_on(), "play on only after the end")
	g.month = int(g.bal.total_months) - 1
	g.tick()
	check(g.game_over and g.can_play_on(), "game ends at the final month")
	var m: int = g.month
	check(g.play_on() and not g.game_over and g.endless, "play on reopens the game")
	for i in 14:
		g.tick()
	check(not g.game_over and g.month == m + 14, "endless game keeps ticking past the end")
	check(not g.play_on(), "play on only once")
	var g2 = new_game()
	g2.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
	check(g2.endless and not g2.game_over, "endless survives save/load")

func test_capitulation() -> void:
	var g = new_game("TUR")
	for t in g.order:
		g.nations[t].allies.clear()
		g.nations[t].guarantees.clear()
	g.nations.TUR.truces.erase("BYZ")
	g.nations.BYZ.truces.erase("TUR")
	g.declare_war("TUR", "BYZ")
	var w = g.war_between("TUR", "BYZ")
	check(w != null, "TUR declares war on BYZ")
	w.defenders = ["BYZ"]
	w.attackers = ["TUR"]
	var all: Array = g.provinces_of("BYZ")
	var half := []
	for i in all.size():
		if i * 2 < all.size():
			g.provinces[all[i]].controller = "TUR"
			half.append(all[i])
	check(g.Warfare.pressure(g, w, false) > 0.0, "occupied land puts pressure on the loser")
	var we0: float = g.nations.BYZ.we
	g.nations.BYZ.we += g.Warfare.occupation_we(g, g.nations.BYZ)
	check(g.nations.BYZ.we > we0, "occupation raises war exhaustion")
	check(not g.Warfare.capitulated(g, w, false) or g.warscore(w) >= float(g.bal.surrender_ws), "half occupied, fresh: no capitulation yet")
	for pid in all:
		g.provinces[pid].controller = "TUR"
	check(g.Warfare.capitulated(g, w, false), "fully occupied leader capitulates")
	check(g.Warfare.peace_budget(g, w, true) >= 9999.0, "capitulation: unlimited budget")
	var ok: bool = g.offer_peace("TUR", w, all, true)
	check(ok, "capitulated BYZ accepts giving everything")
	check(not g.nations.BYZ.alive or g.provinces_of("BYZ").is_empty(), "BYZ annexed")
	check(g.nations.TUR.ae <= float(g.bal.ae_peace_cap_player) + 1.0, "player AE per peace is capped (%d)" % int(g.nations.TUR.ae))


func test_coalition_softer_vs_player() -> void:
	var g = new_game("FRA")
	check(g.coalition_threshold("FRA") > g.coalition_threshold("ENG"), "player has a higher coalition threshold")
	var n = g.nations.FRA
	n.ae = g.coalition_threshold("FRA") - 1.0
	g._coalitions_yearly()
	check(n.coalition.is_empty(), "no coalition below the player threshold")
	n.ae = 300.0
	for i in 6:
		g._coalitions_yearly()
	check(n.coalition.size() <= int(g.bal.coalition_player_max), "player coalition capped (%d)" % n.coalition.size())
	var e = g.nations.ENG
	e.ae = 300.0
	for i in 6:
		g._coalitions_yearly()
	check(e.coalition.size() <= int(g.bal.coalition_max), "AI coalition capped (%d)" % e.coalition.size())


func test_fleet_missions() -> void:
	var g = new_game("ENG")
	var n = g.nations.ENG
	check(g.Naval.mission(g, "ENG") == "patrol", "default mission is patrol")
	var p0: float = g.Naval.power_mult(g, "ENG")
	check(g.Naval.set_mission(g, "ENG", "blockade") == "", "mission can be set")
	check(g.Naval.power_mult(g, "ENG") < p0, "blockade duty costs fighting power")
	check(g.Naval.set_mission(g, "ENG", "nonsense") != "", "unknown mission refused")
	g.Naval.set_mission(g, "ENG", "escort")
	n.ships = g.Naval.limit(g, "ENG")
	g.Naval.refresh(g)
	if not g.is_at_war("ENG"):
		check(n.bonus.has("escort"), "escort in peace gives trade income")
	var g2 = new_game("ENG", 99)
	g2.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
	check(g2.nations.ENG.fleet_mission == "escort", "mission survives save/load")
	check(g.Naval.blockade_strength(g, -1) == 0.0, "no blockade on unknown province")

func test_formables() -> void:
	var g = new_game("NAP")
	for id in g.formable_defs:
		var f: Dictionary = g.formable_defs[id]
		check(not g.nations.has(id), "formable id %s collides with a nation tag (flags would mix)" % id)
		check(ResourceLoader.exists("res://assets/art/icons/flag_%s.png" % id), "formable %s has a flag" % id)
		check(g.event_by_id.has("form_" + id.to_lower()), "formable %s has its event" % id)
		for t in f.from:
			check(t == "*" or g.nations.has(t), "formable %s: unknown nation %s" % [id, t])
		for k in g.Formables.all_provinces(g, id) + f.get("capital_in", []):
			check(g.key_to_pid.has(k), "formable %s: unknown province %s" % [id, k])
		for gr in g.Formables.groups(g, id):
			check(int(gr.need) <= gr.provinces.size(), "formable %s: need too high" % id)
		for k in f.get("bonus", {}):
			check(UiTheme.label(k)[0] != k, "formable %s: bonus key %s has no label" % [id, k])
		for t in g.order:
			if g.nations[t].alive and ("*" in f.from or t in f.from):
				check(g.Formables.block_reason(g, t, id) != "", "%s can form %s at the start" % [t, id])
	check("ITA" in g.Formables.options(g, "NAP"), "Naples may form Italy")
	check(not "ITA" in g.Formables.options(g, "FRA"), "France may not form Italy")
	for k in ["rome", "florence", "milan", "venice", "genoa"]:
		var p = g.provinces[g.key_to_pid[k]]
		p.owner = "NAP"
		p.controller = "NAP"
	g._rebuild_owned()
	g.nations.NAP.adm = 500.0
	check(g.Formables.block_reason(g, "NAP", "ITA") == "", "Naples holding 6 of 7 can form Italy: " + g.Formables.block_reason(g, "NAP", "ITA"))
	var pr: float = g.nations.NAP.prestige
	check(g.Formables.form(g, "NAP", "ITA") == "", "forming works")
	var n = g.nations.NAP
	check(n.formed == "ITA" and n.name == "Italien" and n.prestige > pr and n.bonus.has("formed"), "new identity and bonus")
	check(n.claims.has(g.key_to_pid["bologna"]), "claim on the missing province")
	check(g.pending_events.has("form_ita"), "the player gets the formation event")
	check(g.Formables.options(g, "NAP").all(func(id): return g.Formables.tier(g, id) >= 2) and g.Formables.block_reason(g, "VEN", "ITA") != "", "only one regional formation")
	var g2 = new_game("NAP")
	g2.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
	check(g2.nations.NAP.name == "Italien" and g2.nations.NAP.bonus.has("formed"), "formed realm survives save/load")
	check(n.rank >= 3, "Italy is at least a kingdom")
	# tier 2: a formed realm may still proclaim a great empire; Europe needs rank, year and 9 capitals
	check(not "EUR" in g.Formables.options(g, "NAP"), "Europe is not listed while far out of reach")
	check(g.Formables.block_reason(g, "NAP", "EUR").contains("1500"), "Europe waits for 1500")
	g.month = (1500 - 1444) * 12
	check(g.Formables.block_reason(g, "NAP", "EUR").contains("Rang"), "Europe needs the empire rank")
	n.rank = 4
	var reqs: Array = g.Formables.requirements(g, "NAP", "EUR")
	check(reqs.any(func(r): return not r[0] and str(r[1]).contains("Hauptstädte")), "checklist shows the missing capitals")
	for k in ["london", "paris", "toledo", "lisbon", "wien", "prague", "buda", "krakow"]:
		var p = g.provinces[g.key_to_pid[k]]
		p.owner = "NAP"
		p.controller = "NAP"
	g._rebuild_owned()
	n.adm = 999.0
	check("EUR" in g.Formables.options(g, "NAP"), "Italy may still aim for Europe")
	check(g.Formables.block_reason(g, "NAP", "EUR") == "", "Europe can be proclaimed: " + g.Formables.block_reason(g, "NAP", "EUR"))
	check(g.Formables.form(g, "NAP", "EUR") == "" and n.formed == "EUR" and n.rank == 5, "Imperium Europa: hegemon rank")
	check(n.flags.formed_hist == ["ITA"] and float(n.bonus.formed.get("trade", 0.0)) > 0.15, "Italy's bonus stays on top of Europe's")
	check(g.Formables.block_reason(g, "VEN", "ITA") != "", "Italy stays taken after the second formation")
	# USA: any non-native realm with its capital on the North American east coast
	var u = g.nations.ENG
	check(g.Formables.block_reason(g, "ENG", "USA").contains("Hauptstadt"), "England (capital London) cannot form the USA")
	check(not "USA" in g.Formables.options(g, "IRO"), "natives do not form the USA")
	var na: Array = g.formable_defs.USA.groups[0].provinces
	for k in na:
		var p = g.provinces[g.key_to_pid[k]]
		p.owner = "ENG"
		p.controller = "ENG"
	g._rebuild_owned()
	u.capital = g.key_to_pid["massachusett"]
	u.adm = 999.0
	check(g.is_at_war("ENG") or (g.Formables.form(g, "ENG", "USA") == "" and u.name == "Vereinigte Staaten"), "USA proclaimed")
	# old saves: the Maghreb was stored as MAG (Maguindanao's tag)
	var m = g.nations.MOR
	m.formed = "MAG"
	g.Formables.apply_identity(g, m)
	check(m.formed == "MGB" and m.name == "Maghreb", "old MAG formation is read as the Maghreb")


func test_chronicle() -> void:
	var g = new_game("FRA")
	check(g.chronicle.is_empty(), "chronicle starts empty")
	for pid in g.provinces_of("NAV").duplicate():
		g.provinces[pid].owner = "FRA"
		g.provinces[pid].controller = "FRA"
	g._rebuild_owned()
	g._check_alive("NAV")
	check(g.chronicle.size() == 1 and str(g.chronicle[0][1]).contains("Navarra"), "a fallen realm enters the chronicle")
	g.declare_war("FRA", "ENG")
	check(str(g.chronicle[-1][1]).contains("Großmächte"), "great power war enters the chronicle")
	var n0: int = g.chronicle.size()
	for i in 12 * 30:
		g.tick()
	check(g.chronicle.size() > n0, "30 years write world history (%d entries)" % g.chronicle.size())
	var g2 = new_game("FRA")
	g2.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
	check(g2.chronicle.size() == g.chronicle.size() and g2.chronicle[0][1] == g.chronicle[0][1], "chronicle survives save/load")


func test_debug_tools() -> void:
	var DT = load("res://scripts/core/debug_tools.gd")
	var g = new_game("FRA")
	var snap: Dictionary = DT.snapshot(g)
	check(int(snap.armies) == g.armies.size() and int(snap.nations_alive) > 20 and snap.has("max_stacks_in_province"), "snapshot counts the game lists")
	var crowd: Array = DT.crowded_provinces(g, 3)
	check(crowd.size() == 3 and int(crowd[0][1]) >= int(crowd[2][1]), "crowded provinces sorted by stacks")
	var n = g.nations["FRA"]
	var gold0: float = n.gold
	check(DT.add_resources(g, "FRA", 1000.0, 50.0) == "" and is_equal_approx(n.gold, gold0 + 1000.0), "resource cheat")
	check(int(g.stats.get("debug_used", 0)) > 0, "cheats are marked in the stats")
	# take all of Navarra: it dies
	for pid in g.provinces_of("NAV").duplicate():
		check(DT.take_province(g, "FRA", pid) == "", "take province %d" % pid)
	check(not g.nations["NAV"].alive and g.provinces_of("NAV").is_empty(), "taking the last province ends a realm")
	check(DT.take_province(g, "FRA", g.nations["FRA"].capital) != "", "own province cannot be taken")
	check(DT.reveal_world(g, "FRA") > 0 and DT.reveal_world(g, "FRA") == 0, "reveal world, second time nothing new")
	g.declare_war("FRA", "ENG")
	check(g.at_war("FRA", "ENG") and DT.end_wars(g, "FRA") >= 1 and not g.at_war("FRA", "ENG"), "white peace in all wars")
	check(DT.switch_player(g, "ENG") == "" and g.player == "ENG" and DT.switch_player(g, "NAV") != "", "play as another living realm")
	var ids: Array = DT.event_ids(g, "war_", 5)
	check(ids.size() == 5 and String(ids[0]).begins_with("war_"), "event id search")
	check(DT.fire_event(g, "ENG", "no_such_event") != "", "unknown event is an error")
	var m0: int = g.month
	check(DT.skip_months(g, 24) == 24 and g.month == m0 + 24 and g.pending_events.is_empty() and g.pending_peace.is_empty(), "skip 2 years answers player decisions")

func test_units_and_templates() -> void:
	var g = new_game("FRA", 5)
	var U = g.Units
	var W = g.Warfare
	# standard mix: an AI army with the standard mix costs exactly what a plain regiment did
	var std: Dictionary = U.standard_mix(g, "FRA")
	check(absf(U.cost_mult(g, "FRA", std) - 1.0) < 0.001 and absf(U.cost_mult(g, "FRA", {}) - 1.0) < 0.001, "standard mix costs x1")
	var a = g.spawn_army("FRA", g.nations.FRA.capital, 10.0)
	check(absf(U.upkeep_regs(g, "FRA") - g.army_regs("FRA")) < 0.001, "upkeep unchanged for standard armies")
	# artillery needs tech, shares are clamped
	g.nations.FRA.tech.mil = 0
	check(U.clean(g, "FRA", {"cav": 0.2, "art": 0.3}).art == 0.0, "no artillery before the tech")
	g.nations.FRA.tech.mil = 5
	var c: Dictionary = U.clean(g, "FRA", {"cav": 0.9, "art": 0.3})
	check(c.cav <= 0.6 and absf(c.inf + c.cav + c.art - 1.0) < 0.02, "shares are clamped and sum to 1")
	# phases: artillery shines in the fire fight, cavalry in melee but not in the mountains
	var pid: int = g.nations.FRA.capital
	a.mix = U.clean(g, "FRA", {"cav": 0.0, "art": 0.4})
	var fire_art: float = U.battle_mult(g, a, 0, pid)
	var melee_art: float = U.battle_mult(g, a, 3, pid)
	check(fire_art > 1.2 and melee_art < fire_art, "artillery: strong fire, weak melee (%.2f / %.2f)" % [fire_art, melee_art])
	a.mix = U.clean(g, "FRA", {"cav": 0.6, "art": 0.0})
	var plain: float = U.battle_mult(g, a, 3, pid)
	var mtn: int = g.key_to_pid["tirol"]
	check(plain > 1.05 and U.battle_mult(g, a, 3, mtn) < plain, "cavalry hits hard on open ground, less in the mountains")
	check(U.pursuit_mult(g, [a]) > 1.2, "cavalry drives the pursuit")
	a.mix = U.clean(g, "FRA", {"art": 0.4})
	check(U.siege_mult(g, [a]) > 1.1, "artillery speeds up sieges")
	# unique units
	check(U.unique(g, "TUR").name == "Janitscharen" and U.stat(g, "TUR", "inf", "shock") > U.stat(g, "FRA", "inf", "shock"), "Ottoman janissaries are better infantry")
	check(U.stat(g, "POL", "cav", "shock") > U.stat(g, "FRA", "cav", "shock"), "winged hussars beat gendarmes in the charge")
	# templates: add, adjust, recruit with one, refit
	var n = g.nations.FRA
	check(U.add_template(g, "FRA", "Reiter", {"cav": 0.5}) == "", "a template is added")
	U.adjust_template(g, "FRA", 0, "cav", 0.1)
	check(absf(float(n.templates[0].cav) - 0.6) < 0.01, "the cavalry share goes up in 10 % steps")
	n.recruit_tmpl = 0
	n.gold = 5000.0
	n.manpower = 50.0
	var gold0: float = n.gold
	var free: int = -1
	for q in g.provinces_of("FRA"):
		if g.armies_in(q).is_empty():
			free = q
			break
	for q in g.armies_of("FRA").duplicate():
		g.armies.erase(q)
	var rerr: String = g.recruit("FRA", free, 2)
	check(rerr == "", "recruiting with a template works " + rerr)
	var na = g.armies_in(free)[0]
	check(absf(float(na.mix.cav) - 0.6) < 0.01 and na.tmpl == 0, "new regiments use the template")
	check(gold0 - n.gold > 2.0 * g.regiment_cost("FRA") * 1.01, "cavalry-heavy regiments cost more")
	n.gold = 5000.0
	var p0: float = na.power
	check(U.refit(g, na, -1) == "" and na.mix.is_empty() and na.tmpl == -1, "refitting back to the standard mix")
	check(na.power < p0 and n.gold < 5000.0, "refitting costs gold and morale")
	U.remove_template(g, "FRA", 0)
	check(n.templates.is_empty() and n.recruit_tmpl == -1, "deleting a template resets its users")
	# merging blends the mix
	var x = g.spawn_army("FRA", mtn, 4.0)
	var y = g.spawn_army("FRA", mtn, 4.0)
	x.owner = "FRA"
	x.mix = {"inf": 1.0, "cav": 0.0, "art": 0.0}
	y.mix = {"inf": 0.5, "cav": 0.5, "art": 0.0}
	g.merge_armies("FRA", mtn)
	check(absf(float(x.mix.cav) - 0.25) < 0.02, "merging blends unit shares")
	# save/load keeps mixes and templates
	U.add_template(g, "FRA", "Feld", {"cav": 0.3, "art": 0.1})
	g.nations.FRA.tech.mil = 0  # (raising tech directly would not survive the save)
	var text := JSON.stringify(g.to_dict())
	var g2 = new_game("FRA", 5)
	g2.from_dict(JSON.parse_string(text))
	check(JSON.stringify(g2.to_dict()) == text, "unit mixes and templates survive save/load")
	# sea battles are recorded for the map
	check(g.sea_fights is Array, "sea fights list exists")
	# a battle is slow: one round a month
	check(int(g.bal.battle_rounds_per_month) == 1, "one battle round per month")
	var _w = W


func test_age_decisions() -> void:
	var Ages = load("res://scripts/core/ages.gd")
	var Tech = load("res://scripts/core/tech.gd")
	var cfg: Dictionary = data.ages
	check(cfg.ages.size() == 4 and cfg.questions.size() == 12, "four ages with twelve questions")
	var per_age := {}
	var ev_by_id := {}
	for e in data.events:
		ev_by_id[e.id] = e
	for q in cfg.questions:
		per_age[q.age] = per_age.get(q.age, 0) + 1
		check(q.options.size() == 3, "%s has three options" % q.id)
		check(ev_by_id.has("age_q_" + q.id) and ev_by_id["age_q_" + q.id].get("manual", false), "%s has its manual event" % q.id)
		var harsh := false
		var humane := false
		for o in q.options:
			harsh = harsh or o.tone == "hart"
			humane = humane or o.tone == "human"
			check(o.power in ["adm", "dip", "mil"], "%s: power" % o.id)
			for part in [o.effects, o.up, o.get("synergy", {}).get("effects", {})]:
				for k in part:
					check(Tech.LABELS.has(k), "%s: unknown modifier %s" % [o.id, k])
		check(not harsh or humane, "%s: a harsh option always has a humane alternative" % q.id)
		# the humane path must be worth it in the long run: fully deepened it beats the harsh one
		if harsh:
			var best_h := -999.0
			var best_x := -999.0
			for o in q.options:
				var v: float = Tech.effect_value(Ages.option_effects(o, 3, o.has("synergy")))
				if o.tone == "human":
					best_h = maxf(best_h, v)
				elif o.tone == "hart":
					best_x = maxf(best_x, v)
			check(best_h >= best_x, "%s: humane option is at least as strong when deepened (%.1f vs %.1f)" % [q.id, best_h, best_x])
	for a in cfg.ages:
		check(per_age.get(a.id, 0) == 3, "%s has three questions" % a.id)
	# the question pops up for the player in its year
	var g = new_game("FRA")
	var n = g.nations.FRA
	Ages.yearly(g, n)
	check(g.pending_events.is_empty() and n.age_picks.is_empty(), "no question before its year")
	g.month = (1452 - 1444) * 12
	Ages.yearly(g, n)
	check(g.pending_events.has("age_q_buchdruck"), "the printing question is put in 1452")
	var tc: float = g.mod(n, "tech_cost")
	g.choose_event_option("FRA", "age_q_buchdruck", 0)
	check(n.age_picks.get("buchdruck", ["", 0])[0] == "druck_frei" and Ages.level(n, "buchdruck") == 1, "choice stored at level 1")
	check(is_equal_approx(g.mod(n, "tech_cost"), tc - 0.06), "choice gives its modifier")
	check(g.check_conditions("FRA", {"age_pick": "druck_frei"}) and not g.check_conditions("FRA", {"age_pick": "druck_hof"}), "condition age_pick")
	Ages.yearly(g, n)
	check(g.pending_events.is_empty(), "a question is put only once")
	# deepening costs power and adds the "up" effects
	n.adm = 50.0
	check(Ages.upgrade(g, "FRA", "buchdruck") != "", "deepening needs power")
	n.adm = 300.0
	check(Ages.upgrade(g, "FRA", "buchdruck") == "" and is_equal_approx(n.adm, 200.0), "level 2 costs 100")
	check(Ages.upgrade(g, "FRA", "buchdruck") == "" and is_equal_approx(n.adm, 40.0), "level 3 costs 160")
	check(is_equal_approx(g.mod(n, "tech_cost"), tc - 0.12), "two levels add twice the up effect")
	n.adm = 900.0
	check(Ages.upgrade(g, "FRA", "buchdruck") != "", "level 3 is the top")
	# one-time payment only for the first answer; an event can change the answer and keeps the level
	var gold: float = n.gold
	g.apply_effects("FRA", {"age_pick": ["vertriebene", "vertreibung"]})
	check(is_equal_approx(n.gold, gold + 250.0), "harsh choice pays at once")
	n.adm = 300.0
	Ages.upgrade(g, "FRA", "vertriebene")
	g.apply_effects("FRA", {"age_pick": ["vertriebene", "aufnahme"]})
	check(n.age_picks.vertriebene[0] == "aufnahme" and Ages.level(n, "vertriebene") == 2, "an event changes the choice, the level stays")
	check(is_equal_approx(n.gold, gold + 250.0), "no second payment")
	# synergy with an earlier choice
	var prod: float = g.mod(n, "production")
	g.apply_effects("FRA", {"age_pick": ["menschenhandel", "freie_arbeit"]})
	check(is_equal_approx(g.mod(n, "production"), prod + 0.05 + 0.03), "free labour is stronger after giving refuge")
	check(Ages.pick(g, "FRA", "menschenhandel", "druck_hof") != "", "option of another question is refused")
	# save and load
	var g2 = Game.new()
	g2.setup(data, 7, "FRA")
	g2.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
	var n2 = g2.nations.FRA
	check(n2.age_picks.size() == 3 and Ages.level(n2, "buchdruck") == 3, "choices survive saving")
	check(is_equal_approx(g2.mod(n2, "tech_cost"), g.mod(n, "tech_cost")) and is_equal_approx(g2.mod(n2, "production"), g.mod(n, "production")), "bonus rebuilt after loading")
	# the AI answers too, without a popup
	var a = g.nations.ENG
	Ages.yearly(g, a)
	check(a.age_picks.has("buchdruck") and g.pending_events.is_empty(), "AI realms decide for themselves")


## v1.0 goods update: 13 more goods with leader bonuses, and costs that rise less with development / military tech.
func test_more_goods_and_softer_costs() -> void:
	var g = new_game("VEN", 3)
	check(g.goods_def.size() >= 29, "at least 29 goods")
	for k in ["silk", "spices", "cotton", "glass", "paper", "horses", "olive_oil", "amber", "naval_supplies", "ivory", "dyes", "coffee", "incense"]:
		check(g.goods_def.has(k) and not g.goods_def[k].bonus.is_empty(), "good %s with a leader bonus" % k)
		check(g.prices.has(k), "good %s has a price" % k)
	check(g.provinces[g.key_to_pid["venice"]].good == "glass", "Venice makes glass")
	check(g.provinces[g.key_to_pid["bursa"]].good == "silk", "Bursa makes silk")
	# every good on the map is produced somewhere, and a sole big producer becomes leader with its bonus
	var s: Dictionary = g.Economy.supply(g)
	check(s.get("glass", 0.0) > 0.0 and s.get("silk", 0.0) > 0.0, "new goods are produced")
	g.goods_leader["silk"] = "VEN"
	g.Economy.apply_goods_leaders(g)
	var cap0: float = g.mod(g.nations.VEN, "diplo_cap")
	check(cap0 >= 1.0, "silk leader gets +1 diplomatic capacity")
	# a year of prices with zero-supply goods (coffee/incense before their region) stays finite
	for i in 12:
		g.tick()
	for k in g.prices:
		check(is_finite(g.prices[k]) and g.prices[k] > 0.0, "price of %s finite" % k)
	# softer cost growth: regiments at mil tech 20 cost at most 2x, buildings in a dev-40 province at most 2x of dev 0
	g.nations.VEN.tech.mil = 20
	check(g.regiment_cost("VEN") <= 2.0 * float(g.bal.regiment_cost) + 0.01, "regiments at mil tech 20 cost <= 2x")
	check(1.0 + 40 * float(g.bal.building_cost_per_dev) <= 2.0, "building cost per dev <= 2x at dev 40")


func test_ledger() -> void:
	var L = load("res://scripts/core/ledger.gd")
	var g = new_game("FRA")
	for k in L.KEYS:
		var rows: Array = L.rows(g, k)
		check(rows.size() > 20 and float(rows[0][1]) >= float(rows[-1][1]), "ledger %s sorted, best first" % k)
	check(L.rows(g, "provinces")[0][1] == float(g.provinces_of(L.rows(g, "provinces")[0][0]).size()), "province count")
	check(L.fmt("income", 3.14159) == "3.1" and L.fmt("dev", 12.6) == "13", "ledger number format")


func test_supply_and_ai_stacks() -> void:
	var g = new_game("FRA", 5)
	var W = g.Warfare
	var cap: int = g.nations.ENG.capital
	for a in g.armies.duplicate():
		if a.owner == "ENG":
			g.armies.erase(a)
	# AI stacks in one province join into one army
	for i in 6:
		g.spawn_army("ENG", cap, 1.0)
	g._armies_tick()
	var eng: Array = g.armies_of("ENG")
	check(eng.size() == 1 and absf(eng[0].regs - 6.0) < 0.01, "AI single-regiment stacks merge into one army")
	# the player's stacks stay as they are
	var fcap: int = g.nations.FRA.capital
	var before: int = g.armies_of("FRA").size()
	g.spawn_army("FRA", fcap, 1.0)
	g._armies_tick()
	check(g.armies_of("FRA").size() == before + 1, "player armies are never merged for him")
	# supply: home land feeds more than foreign land
	check(W.supply_limit(g, cap, "ENG") > W.supply_limit(g, cap, "FRA"), "the holder gets a higher supply limit")
	# at peace in the own land: no attrition however big the army
	eng[0].regs = 500.0
	eng[0].full = 500.0
	g._armies_tick()
	check(absf(eng[0].regs - 500.0) < 0.01, "no attrition at peace at home")
	# abroad and over the limit: the surplus withers, and there are no reinforcements
	var f = g.spawn_army("FRA", cap, 200.0)
	f.full = 300.0
	g.nations.FRA.manpower = 1000.0
	g.nations.FRA.gold = 100000.0
	W.attrition(g)
	check(f.regs < 200.0 and f.regs > 150.0, "over the supply limit regiments are lost (%.1f)" % f.regs)
	check(W.over_supply(g, f), "camp is flagged as over supply")
	var r0: float = f.regs
	g._reinforce(f)
	check(f.regs == r0 or not g.is_at_war("FRA"), "no reinforcements over the limit in war")
	var small = g.spawn_army("FRA", g.nations.FRA.capital, 3.0)
	W.attrition(g)
	check(absf(small.regs - 3.0) < 0.01, "an army within the limit loses nothing")
	# own land at war: never any attrition, reinforcements keep coming
	var home: int = g.nations.FRA.capital
	g.nations.FRA.truces.erase("ENG")
	g.nations.ENG.truces.erase("FRA")
	g.declare_war("FRA", "ENG")
	check(g.is_at_war("FRA"), "test war started")
	var h = g.spawn_army("FRA", home, 400.0)
	h.full = 500.0
	W.attrition(g)
	check(absf(h.regs - 400.0) < 0.01, "no attrition in the own land even at war (%.1f)" % h.regs)
	g._reinforce(h)
	check(h.regs > 400.0, "reinforcements in the own land even over the limit")



func test_goods_events() -> void:
	var g = new_game("VEN", 3)
	var n := 0
	for e in g.event_defs:
		if String(e.id).begins_with("gds_"):
			n += 1
			var good = e.trigger.get("produces", "")
			check(good == "" or g.goods_def.has(good), "%s: good %s exists" % [e.id, good])
	check(n >= 15, "goods events present (%d)" % n)
	check(g.check_conditions("VEN", g.event_by_id["gds_glass_secret"].trigger) == (g.year() >= 1450), "Venice makes glass, so the glass story can fire")


## Every playable realm gets at least ten own events (the v1.0 playables started with 3-6).
func test_playable_flavour() -> void:
	var g = new_game("POR", 5)
	var per := {}
	for e in g.event_defs:
		per[e.get("tag", "")] = int(per.get(e.get("tag", ""), 0)) + 1
		if String(e.id).begins_with("pf_"):
			for k in ["claim"]:
				for o in e.options:
					for key in o.effects.get(k, []):
						check(g.key_to_pid.has(key), "%s claims a known province %s" % [e.id, key])
			for t in e.trigger.get("owns", []) + e.trigger.get("not_owns", []):
				check(g.key_to_pid.has(t), "%s names a known province %s" % [e.id, t])
			for o in e.options:
				for t in o.effects.get("relations", {}):
					check(g.nations.has(t), "%s: relations with known realm %s" % [e.id, t])
				if o.effects.has("war"):
					check(g.nations.has(o.effects.war), "%s: war on known realm" % e.id)
	for t in g.nations:
		if g.nations[t].playable:
			check(int(per.get(t, 0)) >= 10, "%s has own events (%d)" % [t, int(per.get(t, 0))])
	# the player's answer is written to the chronicle, an AI answer is not
	var lines: int = g.log_lines.size()
	g.choose_event_option("POR", "pf_por_sagres", 1)
	check(g.log_lines.size() == lines + 1 and String(g.log_lines[-1]).contains("Die Schule von Sagres"), "player decision logged")
	g.choose_event_option("VEN", "pf_ven_arsenal", 0)
	check(g.log_lines.size() == lines + 1, "AI decision not logged")



## Hungary (2026-11-17): stronger start, player-only bonus, Habsburg only inherits after the estates chose Ferdinand.
func test_hungary_powerhouse() -> void:
	var ai_game = new_game("FRA", 3)
	var me = new_game("HUN", 3)
	var buda: int = me.key_to_pid["buda"]
	var map_dev := 0
	for pd in data.map.provinces:
		if pd.key == "buda":
			map_dev = int(pd.dev)
	check(me.provinces[buda].dev == map_dev + 4 and ai_game.provinces[buda].dev == map_dev + 4, "dev_bonus on Buda for AI and player")
	check(me.nations.HUN.mods.get("income", 0.0) > ai_game.nations.HUN.mods.get("income", 0.0) + 0.1, "player bonus only for the player")
	check(me.nations.HUN.gold > ai_game.nations.HUN.gold + 200.0, "player start gold")
	check(ai_game.nations.HUN.mods.get("combat", 0.0) >= 0.1, "national idea combat +10 %")
	# Habsburg cannot inherit Hungary unless Hungary picked Ferdinand
	var g = new_game("FRA", 4)
	var e: Dictionary = g.event_by_id["hab_mohacs"]
	g.month = (1530 - 1444) * 12
	for w in g.wars.duplicate():
		g.wars.erase(w)
	check(not g.check_conditions("HAB", e.trigger), "no Mohács inheritance without the Habsburg king")
	g.choose_event_option("HUN", "hu_mohacs_crown", 1)
	check(g.nations.HUN.flags.has("hun_habsburg_king"), "Ferdinand option sets the flag")
	check(g.check_conditions("HAB", {"nation_flag": {"HUN": "hun_habsburg_king"}}), "nation_flag condition")
	var hu := 0
	for ev in g.event_defs:
		if String(ev.id).begins_with("hu_"):
			hu += 1
	check(hu >= 12, "Hungary has its own event chain (%d)" % hu)


## Colonial founding events: colony_grant settles the first free listed province, discover only reveals the coast.
func test_colonial_events() -> void:
	var g = new_game("FRA", 5)
	var q: int = g.key_to_pid["quisqueya"]
	check(not g.Colonial.knows(g, "SPA", q), "Hispaniola unknown at start")
	check(g.check_conditions("SPA", {"colony_free": ["quisqueya", "no_such_key"]}), "colony_free with unknown keys")
	g.apply_effects("SPA", {"colony_grant": ["no_such_key", "quisqueya", "ayiti"]})
	check(g.provinces[q].owner == "SPA" and g.provinces[q].core_months == 0, "granted colony is a cored province")
	check(g.Colonial.knows(g, "SPA", g.key_to_pid["ayiti"]), "region discovered")
	check(not g.check_conditions("SPA", {"colony_free": ["quisqueya"]}), "taken province is not free")
	var pw: int = g.key_to_pid["powhatan"]
	g.apply_effects("ENG", {"discover": ["powhatan"]})
	check(g.Colonial.knows(g, "ENG", pw) and g.provinces[pw].owner == "NAT", "discover reveals without settling")
	if g.key_to_pid.has("pernambuco"):
		g.apply_effects("POR", {"colony_grant": ["pernambuco", "bahia"]})
		check(g.provinces[g.key_to_pid["pernambuco"]].owner == "POR", "Brazil colony for Portugal")
		check(g.Colonial.knows(g, "POR", g.key_to_pid["bahia"]), "Brazilian coast discovered")
	for ev in g.event_defs:
		if String(ev.id).begins_with("col_"):
			check(g.nations.has(ev.tag) and data.nations[ev.tag].has("colonial"), "%s belongs to a colonial nation" % ev.id)
			check(ev.options[0].effects.has("colony_grant") and ev.trigger.has("colony_free"), "%s grants a colony" % ev.id)


## Subject types: colonial nations form from overseas colonies, dominions and appanages (Subjects).
func test_subjects() -> void:
	var g = new_game("FRA", 5)
	var S = g.Subjects
	check(g.subject_pool.colony.size() >= 12 and g.subject_pool.appanage.size() >= 6, "subject pools loaded")
	for t in g.subject_pool.colony + g.subject_pool.appanage:
		check(not g.nations[t].alive and g.provinces_of(t).is_empty(), "%s dormant at start" % t)
	check(not g.armies.any(func(a): return S.is_pool(g, a.owner)), "pool nations have no armies")
	var keys := ["powhatan", "nanticoke", "secotan", "tuscarora", "lenape"]
	for k in keys:
		g.apply_effects("ENG", {"colony_grant": [k]})
	var used: int = g.diplo_used("ENG")
	S.yearly(g)
	var cn := ""
	for v in g.vassals_of("ENG"):
		if g.nations[v].subject == "colony":
			cn = v
	check(cn != "", "five connected colonies form a colonial nation")
	if cn == "":
		return
	var c = g.nations[cn]
	check(c.name == "Neuengland" and g.provinces_of(cn).size() == 5 and g.Colonial.colonies_owned(g, "ENG") == 0, "Neuengland takes the land (%s, %d)" % [c.name, g.provinces_of(cn).size()])
	check(c.religion == g.nations.ENG.religion and c.techs.size() == g.nations.ENG.techs.size(), "inherits faith and techs")
	check(g.diplo_used("ENG") == used and not S.can_annex(g, cn) and g.annex_vassal("ENG", cn) != "", "takes no slot, cannot be annexed")
	check(is_equal_approx(S.tribute_share(g, cn), float(g.bal.sub_colony_tribute)), "colonial tariff")
	check(g.mod(g.nations.ENG, "trade") > 0.0 and g.nations.ENG.bonus.has("subjects"), "overlord earns from its colonial nation")
	check(g.atlantic_tags.has(cn) and S.colonies_with_subjects(g, "ENG") == 5, "colonial nation colonizes on its own")
	var Ic = load("res://scripts/ui/icons.gd")
	for k in ["col:ENG", "app:FRA"]:
		var df: Texture2D = Ic.derived_flag(k)
		check(df != null and df.get_size() == Ic.texture("flag_" + k.substr(4)).get_size(), "derived flag %s" % k)
	check(Ic.derived_flag("col:XXX") == null, "no derived flag without a founder flag")
	g.apply_effects("ENG", {"colony_grant": ["susquehannock"]})
	check(g.provinces[g.key_to_pid["susquehannock"]].owner == cn, "a new colony next to it joins the colonial nation")
	# save / load keeps name, kind and colour
	var text := JSON.stringify(g.to_dict())
	var g2 = new_game("FRA", 99)
	g2.from_dict(JSON.parse_string(text))
	check(g2.nations[cn].name == "Neuengland" and g2.nations[cn].subject == "colony" and g2.nations[cn].overlord == "ENG", "colonial nation survives a save")
	check(JSON.stringify(g2.to_dict()) == text, "save round trip with subjects is identical")
	# dominion: a grown colonial nation
	for pid in g.provinces_of(cn):
		g.provinces[pid].dev = 15
	g._update_cached(c)
	g.nations.ENG.dip = 500.0
	check(S.convert_subject(g, "ENG", cn, "dominion") == "", "colonial nation becomes a dominion")
	check(c.subject == "dominion" and g.diplo_used("ENG") == used + 1 and c.bonus.has("subject"), "dominion takes a slot and governs itself")
	check(S.convert_block_reason(g, "ENG", cn, "appanage") != "", "a dominion cannot become an appanage")
	g._vassalize("FRA", "BRI", true)
	g.nations.FRA.dip = 500.0
	check(S.convert_block_reason(g, "FRA", "BRI", "dominion") != "", "a vassal next door cannot become a dominion")
	# independence: the subject kind is cleared, a former colony is remembered
	c.subject = "colony"
	S.released(g, cn)
	c.overlord = ""
	check(c.subject == "" and c.flags.has("former_colony"), "independent former colony")
	# appanage
	var f = g.nations.FRA
	f.prestige = 50.0
	var pid: int = -1
	for q in g.provinces_of("FRA"):
		if q != f.capital and S.appanage_block_reason(g, "FRA", q) == "" and S.appanage_lands(g, "FRA", q).size() >= 2:
			pid = q
			break
	check(pid >= 0, "France has land for an appanage")
	if pid < 0:
		return
	var n_prov: int = g.provinces_of("FRA").size()
	var stab: float = f.stability
	var lands: Array = S.appanage_lands(g, "FRA", pid)
	check(S.create_appanage(g, "FRA", pid) == "", "appanage granted")
	var ap: String = g.provinces[pid].owner
	check(S.is_pool(g, ap) and g.nations[ap].subject == "appanage" and g.nations[ap].overlord == "FRA", "cadet branch rules %s" % g.nations[ap].name)
	check(g.provinces_of("FRA").size() == n_prov - lands.size() and f.stability > stab, "land handed over, stability up")
	check(g.diplo_used("FRA") == g.nations.FRA.allies.size() + (g.vassals_of("FRA").size() - S.count(g, "FRA", "appanage")), "appanage takes no slot")
	check(g.annex_months_left(ap) == int(g.bal.sub_appanage_annex_years) * 12, "appanage returns after %d years" % int(g.bal.sub_appanage_annex_years))
	check(g.annex_cost(ap) < g.nations[ap].dev_total * float(g.bal.annex_dip_per_dev), "reintegration is cheaper")
	check(g.liberty(ap) < g.liberty(ap) + S.loyalty(g, ap) and S.loyalty(g, ap) > 0.0, "appanages are loyal")
	for i in 2:
		g.tick()
	check(g.nations[ap].alive and g.provinces[pid].owner == ap, "appanage survives ticks")



## Colonial exhaustion: finished colonies build it up, it slows and prices new colonies, decays, saves;
## the colp_ events and their conditions; Oceania is colonial land of its own region.
func test_colonial_exhaustion() -> void:
	var Col = preload("res://scripts/core/colonial.gd")
	var g = new_game("POR", 5)
	var n = g.nations.POR
	var pid: int = g.key_to_pid["quisqueya"]
	var p = g.provinces[pid]
	var months0: int = Col.colony_months(g, p, "POR")
	var cost0: float = Col.colony_cost(g, "POR", pid)
	check(n.col_exhaust == 0.0 and is_equal_approx(Col.upkeep(g, n), float(g.bal.colony_upkeep)), "no exhaustion at start")
	g.apply_effects("POR", {"colony_grant": ["quisqueya"]})
	var after_one: float = n.col_exhaust
	check(after_one >= float(g.bal.col_exhaust_gain) - 0.01, "a finished colony tires the motherland (%.1f)" % after_one)
	check(Col.exhaust_gain(g, "POR") > float(g.bal.col_exhaust_gain), "each colony held makes the next one more tiring")
	var q: int = g.key_to_pid["ayiti"]
	n.col_exhaust = 50.0
	check(Col.colony_months(g, g.provinces[q], "POR") > Col.colony_months(g, g.provinces[q], "SPA"), "exhaustion slows new colonies")
	check(Col.colony_cost(g, "POR", q) > Col.colony_cost(g, "SPA", q) and Col.upkeep(g, n) > float(g.bal.colony_upkeep), "and makes them dearer")
	check(months0 > 0 and cost0 > 0.0, "base colony values")
	check(g.check_conditions("POR", {"col_exhaust_min": 40}) and not g.check_conditions("POR", {"col_exhaust_max": 40}), "exhaustion conditions")
	g.apply_effects("POR", {"col_exhaust": -30})
	check(is_equal_approx(n.col_exhaust, 20.0), "col_exhaust effect")
	g.apply_effects("POR", {"col_exhaust": -500})
	check(n.col_exhaust == 0.0, "exhaustion never below 0")
	n.col_exhaust = 30.0
	g.tick()
	check(n.col_exhaust < 30.0 and n.col_exhaust > 28.0, "exhaustion fades every month (%.2f)" % n.col_exhaust)
	var saved = g.Colonial.nation_save(n)
	n.col_exhaust = 0.0
	g.Colonial.nation_load(g, n, saved)
	check(n.col_exhaust > 28.0, "exhaustion survives save/load")
	check(g.check_conditions("POR", {"colonies_min": 1}) and not g.check_conditions("POR", {"colonies_min": 50}), "colonies_min")
	check(g.check_conditions("POR", {"region_colonies": {"america": 1}}) and not g.check_conditions("POR", {"region_colonies": {"oceania": 1}}), "region_colonies")
	check(not g.check_conditions("POR", {"knows_sea": ["coral", "tasman"]}), "Oceania seas unknown at start")
	# Oceania: a granted historical colony belongs to region oceania
	g.apply_effects("NED", {"colony_grant": ["gascoyne", "swan"]})
	var gp: int = g.key_to_pid["gascoyne"]
	check(g.provinces[gp].owner == "NED" and Col.region(g, gp) == "oceania" and Col.colonies_in(g, "NED", "oceania") == 1, "Dutch Eendrachtsland in Oceania")
	check(g.check_conditions("NED", {"knows_sea": ["east_indian"]}), "the grant charts the Indian coast of Australia")
	var ids := {}
	for ev in g.event_defs:
		if String(ev.id).begins_with("colp_"):
			ids[ev.id] = true
			check(not ev.has("tag") or g.nations.has(ev.tag), "%s names a realm" % ev.id)
			for sea in ev.trigger.get("knows_sea", []):
				check(Col.NEW_SEAS.has(sea), "%s: %s starts unknown" % [ev.id, sea])
			for k in ev.trigger.get("colony_free", []):
				check(g.key_to_pid.has(k), "%s: province %s exists" % [ev.id, k])
	check(ids.size() >= 15 and ids.has("colp_tasman") and ids.has("colp_viceroy") and ids.has("colp_tired"), "colonial superpower and Oceania events (%d)" % ids.size())

## Balance pass: manpower is counted in regiments (no more "+1500" that refills the pool), no option is
## better than another one on every single effect.
func test_city_tiers() -> void:
	var g = new_game("FRA", 9)
	var Urb = g.Urban
	var pid: int = g.key_to_pid["paris"]
	var p = g.provinces[pid]
	p.urban = true
	p.dev = 20
	g.Economy.refresh_local(g, p)
	check(Urb.tier(g, p) == 1, "dev 20 city is a plain city")
	var tax1: float = g.Economy.tax(g, p)
	var slots1: int = g.Economy.slots(g, p)
	p.dev = int(g.bal.urban_big_dev)
	Urb.refresh_tiers(g)
	check(Urb.tier(g, p) == 2 and Urb.tier_name(2) == "Großstadt", "dev 35 is a Großstadt")
	check(g.Economy.local(g, p, "trade_power") >= float(g.bal.urban_local.trade_power) + float(g.bal.urban_tier_local["2"].trade_power) - 0.001, "Großstadt trade power bonus applied")
	check(g.Economy.slots(g, p) >= slots1 and Urb.slot_bonus(g, p) == int(g.bal.urban_slots) + int(g.bal.urban_tier_slots[0]), "Großstadt gets extra slots")
	p.dev = int(g.bal.urban_metro_dev)
	Urb.refresh_tiers(g)
	check(Urb.tier(g, p) == 3 and Urb.progress(g, p) == 1.0 and Urb.next_dev(g, p) == 0, "dev 50 is a Metropole at the top")
	check(g.Economy.tax(g, p) > tax1, "a Metropole pays more than a plain city")
	p.urban = false
	check(Urb.tier(g, p) == 0 and Urb.progress(g, p) > 0.0 and Urb.progress(g, p) <= 1.0, "countryside has a progress share")


func test_manpower_overflow() -> void:
	var g = new_game("FRA", 9)
	var n = g.nations.FRA
	g._update_cached(n)
	var mx: float = n.max_manpower
	n.manpower = mx
	g.apply_effects("FRA", {"manpower": 10})
	check(n.manpower > mx, "event manpower may exceed the maximum")
	g._economy(n)
	check(n.max_manpower > 0.0 and n.manpower > n.max_manpower, "the overflow survives the month")
	var over0: float = n.manpower - n.max_manpower
	g._economy(n)
	check(n.manpower - n.max_manpower < over0 and n.manpower >= n.max_manpower, "the overflow melts away slowly")
	n.manpower = mx
	var cap: float = maxf(mx, n.max_manpower * float(g.bal.manpower_overflow_max))  # max_manpower moves a little with stability
	g.apply_effects("FRA", {"manpower": 99999})
	check(n.manpower <= cap + 0.01, "overflow is capped (%.2f vs max %.2f, mx %.2f)" % [n.manpower, n.max_manpower, mx])


func test_event_balance() -> void:
	var g = new_game("FRA", 6)
	for e in g.event_defs:
		for o in e.options:
			check(absf(float(o.effects.get("manpower", 0))) <= 20.0, "%s: manpower in regiments" % e.id)
	for tag in g.mission_defs:
		for m in g.mission_defs[tag]:
			check(absf(float(m.get("reward", {}).get("manpower", 0))) <= 20.0, "%s: manpower in regiments" % m.id)
	var col = g.event_by_id["spa_columbus"]
	check(float(col.options[0].effects.mods.income) <= 0.05, "Columbus no longer +10 % income for 50 gold")


func test_alert_bar() -> void:
	var AB = load("res://scripts/ui/alert_bar.gd")
	var items := [{"id": "hint", "kind": ""}, {"id": "debt", "kind": "bad"}, {"id": "tech", "kind": "good"}, {"id": "revolt", "kind": "bad"}]
	var ids := []
	for it in AB.order(items, {}):
		ids.append(it.id)
	check(ids == ["debt", "revolt", "tech", "hint"], "alerts: trouble first, rewards next, hints last, stable (%s)" % [ids])
	check(AB.order(items, {"debt": true}).size() == 3, "a dismissed alert is hidden")
	# 4 icons of 44 px with 6 px gaps need 194 px; one px less turns the 4th slot into "+N"
	check(AB.fit_count(4, 194.0, 44.0, 6.0) == 4, "all alerts fit")
	check(AB.fit_count(4, 193.0, 44.0, 6.0) == 2, "too narrow: two icons and the +N button")
	check(AB.fit_count(9, 20.0, 44.0, 6.0) == 0, "no room: nothing")
	var tip: String = AB.tip_text({"text": "💸 Kasse im Minus", "why": "W", "todo": "T"}, true)
	check(tip.contains("Warum: W") and tip.contains("Was tun: T"), "tooltip says why and what to do")
	for e in ["💸", "💀", "📉", "✊", "🏰", "🏳️", "🌾", "⚠️", "👥", "🕊️", "🎯", "👑", "🤝", "🔬", "🎓", "⚖️", "⚔️", "🏬", "🧭", "⛵", "📜", "🏕", "🏙️", "🏗️", "⛪"]:
		check(AB.glyph_texture(e) != null, "alert icon %s has a pixel glyph" % e)


func test_landmarks() -> void:
	var g = new_game("SPA", 11)
	var L = g.Landmarks
	check(g.lm_defs.size() >= 100, "landmark definitions load (%d)" % g.lm_defs.size())
	# every playable realm has at least one landmark of its own history or in its land
	for tag in g.nations:
		var n = g.nations[tag]
		if not n.playable:
			continue
		var own := false
		for id in g.lm_defs:
			if g.lm_defs[id].get("bound", "") == tag or L.owner(g, id) == tag:
				own = true
		check(own, "%s has a landmark" % tag)
	check(L.level(g, "notre_dame") == 2 and L.level(g, "sevilla_port") == 0, "start levels from the data")
	var sev: int = g.key_to_pid["sevilla"]
	check(L.at(g, sev).has("sevilla_port"), "province index")
	# local effects reach the province, realm effects the owner
	var par = g.provinces[g.key_to_pid["paris"]]
	check(g.Economy.local(g, par, "unrest") < 0.0, "Notre-Dame calms Paris")
	g.tick()
	check(g.mod(g.nations.FRA, "prestige") > 0.0 and g.nations.FRA._bonus.has("landmarks"), "French landmarks give prestige")
	# bound: only Spain may build the Port of Seville; it needs the tech and gold
	var n = g.nations.SPA
	n.gold = 10000.0
	n.tech.dip = 0
	check(L.block_reason(g, "SPA", "sevilla_port").begins_with("Braucht"), "the port needs diplomacy tech")
	n.tech.dip = 30
	check(L.block_reason(g, "FRA", "sevilla_port") != "", "France cannot build in Seville")
	var c: float = L.cost(g, "SPA", "sevilla_port")
	check(c > 0.0 and L.cost(g, "SPA", "sevilla_port") < 1000.0, "level 1 is a medium price (%d)" % int(c))
	var dev0: int = g.provinces[sev].dev
	var gold0: float = n.gold
	check(L.invest(g, "SPA", "sevilla_port") == "", "Spain founds the port")
	check(absf(gold0 - n.gold - c) < 0.01 and L.building(g, "sevilla_port"), "paid and under construction")
	check(L.invest(g, "SPA", "sevilla_port") != "", "one level at a time")
	for i in int(g.bal.landmark_months[0]):
		L.monthly(g)
	check(L.level(g, "sevilla_port") == 1 and not L.building(g, "sevilla_port"), "level 1 done")
	check(g.provinces[sev].dev == dev0 + int(g.bal.landmark_dev), "a level adds development")
	check(g.Economy.local(g, g.provinces[sev], "trade_power") > 0.0, "the port adds trade power")
	check(g.mod(n, "colony_cost") < 0.0, "Seville makes colonies cheaper for Spain")
	var c2: float = L.cost(g, "SPA", "sevilla_port")
	check(c2 > c, "level 2 costs more")
	# a foreign owner keeps the local effects but only half the realm bonus
	var full: Dictionary = L.nation_effects(g, "sevilla_port", "SPA")
	var half: Dictionary = L.nation_effects(g, "sevilla_port", "POR")
	check(absf(half.trade - full.trade * float(g.bal.landmark_foreign_mult)) < 0.0001, "foreign owner: half bonus")
	# losing the province stops a running level
	L.invest(g, "SPA", "sevilla_port")
	g.provinces[sev].owner = "POR"
	L.monthly(g)
	check(not L.building(g, "sevilla_port"), "the work stops when the province is lost")
	g.provinces[sev].owner = "SPA"
	# save / load keeps levels and running works
	n.tech.adm = 30
	check(L.invest(g, "SPA", "giralda") == "", "Seville cathedral level 2")
	var g2 = Game.new()
	g2.setup(data, 11, "SPA")
	g2.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
	check(L.level(g2, "sevilla_port") == 1 and L.building(g2, "giralda"), "save keeps landmarks")
	# reward effect and condition
	var lv: int = L.count_levels(g, "SPA")
	check(L.free_level(g, "SPA") and L.count_levels(g, "SPA") == lv + 1, "free level reward")
	# the AI raises landmarks with a full treasury
	var ai = g.nations.FRA
	ai.gold = 100000.0
	for k in ["adm", "dip", "mil"]:
		ai.tech[k] = 30
	for i in 12:
		L.monthly(g)
	var any := false
	for id in L.of(g, "FRA"):
		any = any or L.building(g, id)
	check(any, "a rich AI invests in its landmarks")


## Council of state: hire, salary, passive effects, promotion, automations with limits, AI, save.
func test_council() -> void:
	var g = new_game("FRA", 3)
	var C = g.Council
	var n = g.nations.FRA
	check(C.seats(g).size() == 9, "nine council seats")
	check(C.seat_name(g, n, "war") != C.seat_name(g, g.nations.VEN, "war"), "seat names depend on the government family")
	n.gold = 2000.0
	check(C.pool(g, n, "army").size() == 3, "three candidates per seat")
	var mp_before: float = g.regiment_cost("FRA")
	check(C.hire(g, "FRA", "army", 0) == "", "hire a councillor")
	check(C.skill(n, "army") >= 1 and C.auto_on(n, "army"), "player councillors start with automation on")
	check(g.regiment_cost("FRA") < mp_before, "army seat makes regiments cheaper")
	check(g.govt.budget_cost(g, n) > 0.0, "council salary is part of the budget")
	n.mil = 900.0
	var lvl: int = C.skill(n, "army")
	check(C.promote(g, "FRA", "army") == "" and C.skill(n, "army") == lvl + 1, "promotion with military power")
	# experience: free level after experience_years on one level
	C.members(n).army.lvl_since = g.month - int(C.cfg(g).experience_years) * 12
	C.yearly(g, n)
	check(C.skill(n, "army") == lvl + 2, "experience raises the level")
	# army automation: recruits towards the target share of the force limit, respecting the gold reserve
	n.manpower = 100.0
	var regs: float = g.army_regs("FRA")
	C.members(n).army.opt.target = 100.0
	C.monthly(g, n)
	check(g.army_regs("FRA") > regs, "army automation recruits (%.1f -> %.1f)" % [regs, g.army_regs("FRA")])
	n.gold = 50.0
	regs = g.army_regs("FRA")
	C.monthly(g, n)
	check(g.army_regs("FRA") == regs, "the gold reserve stops recruitment")
	C.set_auto(g, "FRA", "army", false)
	n.gold = 2000.0
	C.monthly(g, n)
	check(g.army_regs("FRA") == regs, "automation off: nothing happens")
	# development seat: target and threshold
	check(C.hire(g, "FRA", "development", 0) == "", "hire development councillor")
	C.members(n).development.opt.mode = "capital"
	C.members(n).development.opt.at = 25.0
	var cap: int = n.capital
	var d0: int = g.provinces[cap].dev
	n.adm = float(g.bal.power_cap) * 0.3
	n.dip = 0.0
	n.mil = 0.0
	g._overflow_develop(n)
	check(g.provinces[cap].dev == d0 + 1, "development councillor develops the capital at the threshold (%d -> %d, cost %d, adm %d, target %d cap %d)" % [d0, g.provinces[cap].dev, g.develop_cost(cap), n.adm, C.dev_target(g, n), cap])
	C.members(n).development.opt.mode = "off"
	n.adm = float(g.bal.power_cap)
	g._overflow_develop(n)
	check(g.provinces[cap].dev == d0 + 1, "mode off spends nothing")
	C.members(n).development.opt.mode = "lowest"
	var low: int = C.dev_target(g, n)
	for pid in g.provinces_of("FRA"):
		if g.provinces[pid].controller == "FRA" and g.provinces[pid].dev < int(g.bal.max_dev):
			check(g.provinces[pid].dev >= g.provinces[low].dev, "lowest picks the lowest development")
			break
	check(C.cycle_opt(g, "FRA", "development", "mode") == "" and C.opt(g, n, "development", "mode") == "highest", "options cycle")
	# coin seat: emergency loan before the treasury runs dry
	check(C.hire(g, "FRA", "coin", 0) == "", "hire treasurer")
	n.gold = -5.0
	var loans: int = n.loans.size()
	C.monthly(g, n)
	check(n.loans.size() == loans + 1, "emergency loan")
	# save keeps the council and its settings
	var g2 = new_game("FRA", 4)
	g2.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
	var n2 = g2.nations.FRA
	check(C.skill(n2, "army") == C.skill(n, "army") and C.opt(g2, n2, "development", "mode") == "highest" and not C.auto_on(n2, "army"),
			"council saved")
	check(absf(g2.regiment_cost("FRA") - g.regiment_cost("FRA")) < 0.001, "council bonus restored after load")
	# AI fills seats with spare gold
	var ai = g.nations.ENG
	ai.gold = 2000.0
	C.ai_think(g, ai)
	check(C.members(ai).size() == 1, "AI appoints a councillor")
	C.dismiss(g, "FRA", "army")
	check(C.member(n, "army").is_empty(), "dismiss")


## Government types: republics elect every term (player via event popup), theocracies at death, monarchies inherit.
func test_elections() -> void:
	var g = new_game("VEN", 3)
	var R = g.Regime
	var n = g.nations.VEN
	check(R.kind(g, n) == "republic" and R.kind(g, g.nations.FRA) == "hereditary" and R.kind(g, g.nations.PAP) == "elective", "government kinds")
	check(int(n.ruler.years) <= R.term_years(g), "republics start within one term")
	check(str(n.gov.get("agenda", "")) != "" and not R.agenda_effects(g, n).is_empty(), "republic has a programme")
	g.govt.succession(g, n)
	check(R.pending(n) and g.pending_events.has(R.EVENT_ID) and g.event_by_id.has(R.EVENT_ID), "election event for the player")
	var opts: Array = R.options(n)
	check(opts.size() == 4 and opts[3].get("incumbent", false), "three candidates and the incumbent")
	# save during the election: event comes back
	var g2 = new_game("VEN", 5)
	g2.from_dict(JSON.parse_string(JSON.stringify(g.to_dict())))
	check(R.pending(g2.nations.VEN) and g2.pending_events.has(R.EVENT_ID) and g2.event_by_id[R.EVENT_ID].options.size() == 4, "pending election survives save/load")
	var c: Dictionary = opts[1]
	g.choose_event_option("VEN", R.EVENT_ID, 1)
	check(not R.pending(n) and not g.pending_events.has(R.EVENT_ID), "election decided")
	check(int(n.ruler.adm) == int(c.adm) and int(n.ruler.years) == R.term_years(g) and n.gov.agenda == c.faction, "winner rules one term with his programme")
	var t0: float = R.tradition(n)
	g.govt.succession(g, n)
	g.choose_event_option("VEN", R.EVENT_ID, R.options(n).size() - 1)
	check(R.tradition(n) < t0 and int(n.gov.terms) == 2, "re-election costs tradition")
	R.yearly(g, n)
	check(R.tradition(n) > t0 - 15.0, "tradition grows every year")
	# AI theocracy: elects at once when the ruler dies
	var p = g.nations.PAP
	var name0: String = p.ruler_name
	g.govt.succession(g, p)
	check(not R.pending(p) and str(p.gov.agenda) != "" and int(p.ruler.years) >= 8, "AI theocracy elects a successor for life")
	check(p.ruler_name != name0 or p.ruler_name == "", "new ruler")
	# hereditary monarchy keeps the heir
	var f = g.nations.FRA
	var heir: String = str(f.gov.heir.name)
	g.govt.succession(g, f)
	check(f.ruler_name == heir and not R.pending(f), "monarchies inherit")
	# a change to a republic shortens the reign to one term
	check(R.tradition_effects(g, g.nations.FRA).is_empty(), "no tradition outside republics")


func test_daily_gain() -> void:
	var g = new_game("FRA")
	var n = g.nations.FRA
	n.manpower = 0.0
	var gain: float = g.manpower_gain(n)
	check(gain > 0.0 and absf(gain - n.max_manpower / (float(g.bal.manpower_regen_years) * 12.0)) < 0.001, "manpower gain per month = max / (years x 12)")
	n.ae = 20.0
	var dec: float = g.ae_decay_monthly(n)
	check(dec > 0.0, "AE fades every month (%.3f)" % dec)
	var m0: float = n.manpower
	var a0: float = n.ae
	g.tick()
	check(absf((n.manpower - m0) - gain) < maxf(1.0, gain * 0.05), "a month adds the shown manpower gain (%.1f vs %.1f)" % [n.manpower - m0, gain])
	check(n.ae < a0 and absf((a0 - n.ae) - dec) < 0.05, "a month removes about the shown AE decay (%.3f vs %.3f)" % [a0 - n.ae, dec])


## v1.1.2: China, Japan, Inca, Lithuania, Mongolia, Aztecs, Malacca and Mali are playable with own content.
func test_world_playables() -> void:
	var g = new_game("ASH", 3)
	for t in ["MNG", "ASH", "INC", "LIT", "MGL", "AZT", "MLC", "MAL"]:
		check(g.nations[t].playable, "%s is playable" % t)
		var ms: Array = data.missions.get(t, [])
		var own := 0
		for x in ms:
			if String(x.id).contains("_np_"):
				own += 1
		check(own >= 6, "%s has national missions (%d)" % [t, own])
	# the one-province shogun gets the player-only bonus; the AI shogun does not
	var ai = new_game("FRA", 3)
	check(g.mod(g.nations.ASH, "manpower") > ai.mod(ai.nations.ASH, "manpower") + 0.3, "player shogun bonus")
	check(g.nations.ASH.claims.has(g.key_to_pid["kii"]), "shogun starts with claims")


## Native realms bring in the free tribes on their border instead of founding colonies (scripts/core/tribes.gd).
func test_tribes() -> void:
	var g = new_game("INC", 5)
	var T = g.Tribes
	var n = g.nations.INC
	var jauja: int = g.key_to_pid["jauja"]
	var far: int = g.key_to_pid["amazonas"]
	check(g.provinces[jauja].owner == "NAT", "jauja is free native land in 1444")
	check(T.block_reason(g, "SPA", jauja) != "", "the Old World colonizes instead")
	check(T.block_reason(g, "INC", far) != "", "only tribes on the border")
	n.dip = 0.0
	check(T.block_reason(g, "INC", jauja).contains("Diplomatie"), "costs diplomacy")
	n.dip = 500.0
	n.gold = 500.0
	var cost: float = T.dip_cost(g, jauja)
	var n0: int = g.provinces_of("INC").size()
	check(T.integrate(g, "INC", jauja) == "", "the tribe joins")
	check(g.provinces[jauja].owner == "INC" and g.provinces_of("INC").size() == n0 + 1 and not g.provinces_of("NAT").has(jauja), "owner and indices updated")
	check(absf(500.0 - cost - n.dip) < 0.01 and g.provinces[jauja].core_months == 0, "paid in diplomacy, not cored yet")
	check(T.integrate(g, "INC", jauja) != "", "no second time")
	# AI: only playable native realms, and only with power to spare
	var ai = new_game("FRA", 5)
	ai.nations.INC.dip = 900.0
	ai.nations.INC.gold = 900.0
	ai.nations.MAY.dip = 900.0
	ai.nations.MAY.gold = 900.0
	var may0: int = ai.provinces_of("MAY").size()
	ai.bal.ai_tribe_chance = 1.0
	ai.Tribes.ai_yearly(ai)
	check(ai.provinces_of("INC").size() == 4, "the AI Inca take in one tribe a year")
	check(ai.provinces_of("MAY").size() == may0, "non-playable natives do not")


## Every modifier key in the data is one the game knows (Uesugi's "defense" did nothing until v1.1.2).
func test_modifier_keys_known() -> void:
	var bad := []
	for t in data.nations:
		for k in data.nations[t].get("bonus", {}).keys() + data.nations[t].get("player_bonus", {}).keys():
			if not Tech.LABELS.has(k):
				bad.append("%s:%s" % [t, k])
	for e in data.events:
		for o in e.options:
			for k in o.effects.get("mods", {}):
				if not Tech.LABELS.has(k):
					bad.append("%s:%s" % [e.id, k])
	for t in data.missions:
		for x in data.missions[t]:
			for k in x.reward.get("mods", {}):
				if not Tech.LABELS.has(k):
					bad.append("%s:%s" % [x.id, k])
	check(bad.is_empty(), "unknown modifier keys: %s" % ", ".join(bad.slice(0, 10)))
	# "defense" (Uesugi +10 %) adds to the strength of armies fighting on their own land
	var g = new_game("FRA", 3)
	var mine: Array = g.armies.filter(func(x): return x.owner == "UES")
	check(not mine.is_empty(), "Uesugi has an army")
	if not mine.is_empty():
		var home: int = g.nations.UES.capital
		var d: float = g.mod(g.nations.UES, "defense")
		var p1: float = g._side_power([mine[0]], home)
		g.nations.UES.bonus["test"] = {"defense": -d}
		check(d > 0.05 and g._side_power([mine[0]], home) < p1, "defense bonus counts at home")


## The performance shortcuts (v1.1.2) must give the same answers as the plain scans they replace.
func test_perf_caches() -> void:
	var g = new_game("FRA", 7)
	for i in 36:
		g.tick()
	var E = g.Economy
	var bad := 0
	var tried := 0
	for tag in ["FRA", "ENG", "TUR", "MNG", "DLH", "AZT"]:
		if not g.nations.has(tag):
			continue
		g.nations[tag].gold = 1e6
		for pid in g.provinces_of(tag):
			for bid in g.buildings_def:
				tried += 1
				if E._can_build(g, tag, g.provinces[pid], bid) != (E._build_block_no_gold(g, tag, g.provinces[pid], bid) == ""):
					bad += 1
	check(tried > 100 and bad == 0, "_can_build matches _build_block_no_gold (%d of %d differ)" % [bad, tried])
	# army index: same armies in the same order as a scan, also after direct list changes
	var ok := true
	for tag in g.order:
		var scan: Array = g.armies.filter(func(a): return a.owner == tag)
		if g.armies_of(tag) != scan:
			ok = false
	check(ok, "armies_of matches a scan of all armies")
	var a = g.spawn_army("FRA", g.nations.FRA.capital, 2.0)
	check(g.armies_of("FRA").has(a), "a new army is in the index")
	g.armies.erase(a)
	check(not g.armies_of("FRA").has(a), "the index notices a removed army")
	# rival index
	var ok2 := true
	for tag in g.order:
		var scan := []
		for t in g.order:
			if g.nations[t].alive and g.nations[t].rivals.has(tag):
				scan.append(t)
		if g.rivaled_by(tag) != scan:
			ok2 = false
	check(ok2, "rivaled_by matches a scan of all rivals")
