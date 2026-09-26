extends Control

@onready var background = $Background
@onready var background_transition = $BackgroundTransition
@onready var character_portrait = $CharacterPortrait
@onready var event_text = $StoryArea/EventText
@onready var choice_button_1 = $ChoiceButton1
@onready var choice_button_2 = $ChoiceButton2
@onready var choice_button_3 = $ChoiceButton3
@onready var skills_button = $SkillsButton
@onready var skills_panel = $SkillsPanel
@onready var skills_modal_blocker = $SkillsModalBlocker
@onready var empty_skills_label = $SkillsPanel/PanelMargin/SkillsVBox/SkillsTopArea/EmptySkillsLabel
@onready var skills_grid = $SkillsPanel/PanelMargin/SkillsVBox/SkillsTopArea/SkillsGrid
@onready var skill_name = $SkillsPanel/SkillInfoArea/SkillNameArea/SkillName
@onready var skill_description = $SkillsPanel/SkillInfoArea/SkillDescriptionArea/SkillDescription
@onready var skills_close_button = $SkillsPanel/PanelMargin/SkillsVBox/CloseButton
@onready var menu_button = $MenuButton
@onready var game_menu_panel = $GameMenuPanel
@onready var menu_modal_blocker = $MenuModalBlocker
@onready var menu_continue_button = $GameMenuPanel/PanelMargin/MenuVBox/ContinueButton
@onready var menu_settings_button = $GameMenuPanel/PanelMargin/MenuVBox/SettingsButton
@onready var menu_exit_button = $GameMenuPanel/PanelMargin/MenuVBox/ExitButton
@onready var hp_hearts: Array[TextureRect] = [$HPHeart1, $HPHeart2, $HPHeart3]
var hp_full_texture: Texture2D = preload("res://assets/ui/hp_full.png")
var hp_empty_texture: Texture2D = preload("res://assets/ui/hp_empty.png")
var lockpicking_texture: Texture2D = preload("res://assets/ui/skill_lockpicking.png")
var home_village_day_texture: Texture2D = preload("res://assets/ui/home_village_day.png")
var home_forge_day_texture: Texture2D = preload("res://assets/ui/home_forge_day.png")
var home_village_burning_night_texture: Texture2D = preload("res://assets/ui/home_village_burning_night.png")
var forest_escape_dawn_texture: Texture2D = preload("res://assets/ui/forest_escape_dawn.png")
var meadow_morning_texture: Texture2D = preload("res://assets/ui/meadow_morning.png")
var crossroads_morning_texture: Texture2D = preload("res://assets/ui/crossroads_morning.png")
var new_village_outskirts_day_texture: Texture2D = preload("res://assets/ui/new_village_outskirts_day.png")
var forest_path_day_texture: Texture2D = preload("res://assets/ui/forest_path_day.png")
var village_market_day_texture: Texture2D = preload("res://assets/ui/village_market_day.png")
var village_street_day_texture: Texture2D = preload("res://assets/ui/village_street_day.png")
var village_forge_day_texture: Texture2D = preload("res://assets/ui/village_forge_day.png")
var village_well_day_texture: Texture2D = preload("res://assets/ui/village_well_day.png")
var village_barn_alley_day_texture: Texture2D = preload("res://assets/ui/village_barn_alley_day.png")
var bandit_hideout_evening_texture: Texture2D = preload("res://assets/ui/bandit_hideout_evening.png")
var manor_exterior_night_texture: Texture2D = preload("res://assets/ui/manor_exterior_night.png")
var manor_interior_night_texture: Texture2D = preload("res://assets/ui/manor_interior_night.png")
var village_dawn_texture: Texture2D = preload("res://assets/ui/village_dawn.png")
var old_mill_evening_texture: Texture2D = preload("res://assets/ui/old_mill_evening.png")
var old_mill_interior_sunset_texture: Texture2D = preload("res://assets/ui/old_mill_interior_sunset.png")
var village_fire_night_texture: Texture2D = preload("res://assets/ui/village_fire_night.png")
var boy_pleading_texture: Texture2D = preload("res://assets/ui/boy_pleading.png")
var boy_friendly_texture: Texture2D = preload("res://assets/ui/boy_friendly.png")
var boy_angry_texture: Texture2D = preload("res://assets/ui/boy_angry.png")
var thief_neutral_texture: Texture2D = preload("res://assets/ui/thief_neutral.png")
var thief_angry_texture: Texture2D = preload("res://assets/ui/thief_angry.png")
var thief_friendly_texture: Texture2D = preload("res://assets/ui/thief_friendly.png")
var fortune_teller_texture: Texture2D = preload("res://assets/ui/fortune_teller.png")
var guard_texture: Texture2D = preload("res://assets/ui/guard.png")
var peasant_grumpy_texture: Texture2D = preload("res://assets/ui/peasant_grumpy.png")
var peasant_pleading_texture: Texture2D = preload("res://assets/ui/peasant_pleading.png")

var chapter_data: Dictionary
var current_event_id: String

# Здесь хранятся только те варианты выбора,
# которые сейчас доступны игроку.
var available_choices: Array = []

# Общие параметры анимаций. Меняем их здесь, чтобы весь Chapter I
# оставался визуально единообразным.
const INPUT_LOCK_TIME := 0.65
const TEXT_FADE_TIME := 0.20
const LOCATION_FADE_OUT := 0.24
const LOCATION_FADE_IN := 0.32
const LOCATION_FADE_NIGHT := 0.40
const CHARACTER_FADE_TIME := 0.35
const CHOICE_FADE_TIME := 0.264
const CHOICE_STAGGER := 0.084
const PANEL_ANIMATION_TIME := 0.20
const HP_PULSE_TIME := 0.12

var is_transitioning := false
var character_base_position := Vector2.ZERO


func _ready() -> void:
	# Фиксируем исходную позицию портрета ДО первой загрузки события.
	# Иначе первое show_event() успевало записать Vector2.ZERO и уводило всех NPC влево-вверх.
	character_base_position = character_portrait.position
	load_chapter_data()

	GameState.health_changed.connect(_on_health_changed)
	update_health_display(GameState.health, GameState.max_health)

	choice_button_1.pressed.connect(_on_choice_button_1_pressed)
	choice_button_2.pressed.connect(_on_choice_button_2_pressed)
	choice_button_3.pressed.connect(_on_choice_button_3_pressed)
	skills_button.pressed.connect(_on_skills_button_pressed)
	skills_close_button.pressed.connect(_on_skills_close_button_pressed)
	menu_button.pressed.connect(_on_menu_button_pressed)
	menu_continue_button.pressed.connect(_on_menu_continue_button_pressed)
	menu_settings_button.pressed.connect(_on_menu_settings_button_pressed)
	menu_exit_button.pressed.connect(_on_menu_exit_button_pressed)

	skills_panel.pivot_offset = skills_panel.size / 2.0
	game_menu_panel.pivot_offset = game_menu_panel.size / 2.0


func load_chapter_data() -> void:
	var file = FileAccess.open("res://data/chapter_01.json", FileAccess.READ)

	if file == null:
		print("ERROR: Не удалось открыть chapter_01.json")
		return

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_text)

	if error != OK:
		print("ERROR JSON: ", json.get_error_message())
		return

	chapter_data = json.data

	# Если загружено сохранение и событие существует,
	# продолжаем с него.
	if GameState.current_event_id != "" and chapter_data["events"].has(GameState.current_event_id):
		current_event_id = GameState.current_event_id
	else:
		# Иначе начинаем главу с начала.
		current_event_id = chapter_data["start_event"]
		GameState.current_event_id = current_event_id

		# Сразу сохраняем чистое начало новой игры.
		# Так старое прохождение не останется в сейве,
		# даже если игрок выйдет до первого выбора.
		SaveSystem.save_game()

	show_event(current_event_id)


func show_event(event_id: String) -> void:
	if not chapter_data["events"].has(event_id):
		print("ERROR: Событие не найдено: ", event_id)
		return

	current_event_id = event_id
	GameState.current_event_id = event_id

	var event = chapter_data["events"][event_id]
	event_text.text = event["text"]
	update_background(event_id)
	update_character_portrait(event_id)
	rebuild_choices(event["choices"])
	show_choices_immediately()


func rebuild_choices(choices: Array) -> void:
	available_choices.clear()

	for choice in choices:
		if check_conditions(choice):
			available_choices.append(choice)

	if available_choices.size() > 3:
		push_error(
			"CHOICE LIMIT ERROR: Event '%s' has %d available choices. Maximum allowed is 3."
			% [current_event_id, available_choices.size()]
		)

	var buttons = [choice_button_1, choice_button_2, choice_button_3]
	for button in buttons:
		button.hide()
		button.disabled = true

	for i in range(min(available_choices.size(), 3)):
		buttons[i].text = available_choices[i]["text"]


func show_choices_immediately() -> void:
	var buttons = [choice_button_1, choice_button_2, choice_button_3]
	for i in range(min(available_choices.size(), 3)):
		buttons[i].modulate.a = 1.0
		buttons[i].show()
		buttons[i].disabled = false


func animate_choices_in() -> void:
	var buttons = [choice_button_1, choice_button_2, choice_button_3]

	for i in range(min(available_choices.size(), 3)):
		var button = buttons[i]
		button.modulate.a = 0.0
		button.disabled = false
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.show()
		var tween = create_tween()
		tween.tween_interval(i * CHOICE_STAGGER)
		tween.tween_property(button, "modulate:a", 1.0, CHOICE_FADE_TIME)


func set_choice_input_enabled(enabled: bool) -> void:
	var buttons = [choice_button_1, choice_button_2, choice_button_3]
	for i in range(buttons.size()):
		var is_available = i < available_choices.size()
		buttons[i].disabled = false
		buttons[i].mouse_filter = Control.MOUSE_FILTER_STOP if enabled and is_available else Control.MOUSE_FILTER_IGNORE


func is_night_background(texture: Texture2D) -> bool:
	return texture in [
		home_village_burning_night_texture,
		manor_exterior_night_texture,
		manor_interior_night_texture,
		village_fire_night_texture
	]


func transition_to_event(event_id: String) -> void:
	if not chapter_data["events"].has(event_id):
		print("ERROR: Событие не найдено: ", event_id)
		return

	is_transitioning = true
	set_choice_input_enabled(false)
	skills_button.disabled = true
	menu_button.disabled = true

	var next_background = get_background_texture(event_id)
	var background_changes = next_background != background.texture
	var old_character = character_portrait.texture if character_portrait.visible else null
	var next_character = get_character_texture(event_id)
	var character_changes = old_character != next_character

	# Убираем текст и, если нужно, старого персонажа.
	var out_tween = create_tween().set_parallel(true)
	out_tween.tween_property(event_text, "modulate:a", 0.0, TEXT_FADE_TIME)
	if character_portrait.visible and character_changes:
		out_tween.tween_property(character_portrait, "modulate:a", 0.0, CHARACTER_FADE_TIME)
	await out_tween.finished

	current_event_id = event_id
	GameState.current_event_id = event_id
	var event = chapter_data["events"][event_id]
	event_text.text = event["text"]
	rebuild_choices(event["choices"])

	# Настоящий crossfade через второй полноэкранный слой:
	# старый фон остаётся непрозрачным, новый проявляется поверх него.
	if background_changes:
		if next_background != null:
			background_transition.texture = next_background
			background_transition.modulate.a = 0.0
			background_transition.show()

			var fade_time = LOCATION_FADE_NIGHT if is_night_background(background.texture) or is_night_background(next_background) else LOCATION_FADE_IN
			var background_tween = create_tween()
			background_tween.tween_property(background_transition, "modulate:a", 1.0, fade_time)
			await background_tween.finished

			background.texture = next_background
			background.show()
			background.modulate.a = 1.0
			background_transition.hide()
			background_transition.texture = null
			background_transition.modulate.a = 1.0
		else:
			background.hide()
			background_transition.hide()
			background_transition.texture = null
	background.scale = Vector2.ONE

	# Персонаж всегда остаётся в зафиксированных координатах.
	if character_changes:
		character_portrait.texture = next_character
		character_portrait.visible = next_character != null
	character_portrait.position = character_base_position
	if character_portrait.visible:
		character_portrait.modulate.a = 0.0 if character_changes else 1.0

	event_text.modulate.a = 0.0
	await get_tree().create_timer(0.08).timeout

	var in_tween = create_tween().set_parallel(true)
	in_tween.tween_property(event_text, "modulate:a", 1.0, TEXT_FADE_TIME)
	if character_portrait.visible and character_changes:
		in_tween.tween_property(character_portrait, "modulate:a", 1.0, CHARACTER_FADE_TIME)

	animate_choices_in()

	await get_tree().create_timer(INPUT_LOCK_TIME).timeout
	set_choice_input_enabled(true)
	skills_button.disabled = false
	menu_button.disabled = false
	is_transitioning = false


func get_character_texture(event_id: String) -> Texture2D:
	match event_id:
		"boy_encounter":
			return boy_pleading_texture
		"boy_helped", "boy_return_positive", "boy_lockpicking_learned", "boy_lockpicking_refused":
			return boy_friendly_texture
		"boy_ignored", "boy_return_negative":
			return boy_angry_texture
		"thief_encounter":
			return thief_neutral_texture
		"thief_silent", "bandit_thief_positive", "bandit_thief_join", "bandit_thief_training", "bandit_thief_refuse", "bandit_thief_refuse_training", "bandit_thief_leave":
			return thief_friendly_texture
		"thief_nosy", "bandit_thief_negative", "bandit_thief_driven_away":
			return thief_angry_texture
		"fortune_teller", "fortune_teller_accept", "fortune_teller_refuse":
			return fortune_teller_texture
		"post_cart", "guard_questions_robber", "guard_arrest_escape", "guard_questions_innocent", "guard_crackdown", "guard_escape", "guard_lie", "guard_lie_leave":
			return guard_texture
		"village_arrival", "bread_theft_failed", "bread_ask_failed":
			return peasant_grumpy_texture
		"post_fortune", "village_cart_help", "village_cart_leave":
			return peasant_pleading_texture
		_:
			return null


func update_character_portrait(event_id: String) -> void:
	var texture = get_character_texture(event_id)
	character_portrait.texture = texture
	character_portrait.visible = texture != null
	character_portrait.modulate.a = 1.0
	character_portrait.position = character_base_position


func get_background_texture(event_id: String) -> Texture2D:
	match event_id:
		"prologue_home":
			return home_village_day_texture
		"prologue_forge":
			return home_forge_day_texture
		"prologue_raid":
			return home_village_burning_night_texture
		"prologue_meadow":
			return forest_escape_dawn_texture
		"meadow_start", "meadow_path", "meadow_cross":
			return meadow_morning_texture
		"crossroads":
			return crossroads_morning_texture
		"thief_encounter", "thief_silent", "thief_nosy":
			return forest_path_day_texture
		"boy_encounter", "boy_helped", "boy_ignored":
			return new_village_outskirts_day_texture
		"village_arrival", "bread_theft_failed", "bread_ask_failed", "village_square", "village_square_market":
			return village_market_day_texture
		"leper_encounter", "leper_help", "leper_rejected":
			return village_street_day_texture
		"village_square_forge":
			return village_forge_day_texture
		"village_well", "village_well_listen", "village_well_leave":
			return village_well_day_texture
		"boy_return_positive", "boy_lockpicking_learned", "boy_lockpicking_refused", "boy_return_negative":
			return village_barn_alley_day_texture
		"bandit_route", "bandit_thief_positive", "bandit_thief_join", "bandit_thief_training", "bandit_thief_refuse", "bandit_thief_refuse_training", "bandit_thief_leave", "bandit_thief_negative", "bandit_thief_driven_away", "bandit_boy_skilled", "bandit_boy_join", "bandit_boy_refuse", "bandit_boy_unskilled", "bandit_boy_unskilled_leave":
			return bandit_hideout_evening_texture
		"robbery_start", "robbery_locked_door", "robbery_lock_opened", "robbery_escape_door", "robbery_escape_window", "robbery_escape":
			return manor_exterior_night_texture
		"robbery_inside", "robbery_owner":
			return manor_interior_night_texture
		"morning_start", "morning_after_robbery", "morning_normal", "morning_village", "morning_rumors_participant", "morning_rumors_outsider", "morning_rumors_leave", "fortune_teller", "fortune_teller_accept", "fortune_teller_refuse", "post_fortune", "village_cart_help", "village_cart_leave", "post_cart", "guard_questions_robber", "guard_arrest_escape", "guard_questions_innocent", "guard_crackdown", "guard_escape", "guard_lie", "guard_lie_leave":
			return village_dawn_texture
		"mill_after_crackdown", "mill_after_escape", "mill_after_lie":
			return old_mill_evening_texture
		"old_mill":
			return old_mill_interior_sunset_texture
		"mill_night_wakeup", "village_night_approach", "village_night_thieves", "final_choice_robber", "final_choice_outsider", "chapter_end_bandits", "chapter_end_village":
			return village_fire_night_texture
		_:
			return null


func update_background(event_id: String) -> void:
	var texture = get_background_texture(event_id)
	background.texture = texture
	background.visible = texture != null
	background.modulate.a = 1.0
	background.scale = Vector2.ONE


func check_conditions(choice: Dictionary) -> bool:
	# Если условий нет — выбор всегда доступен.
	if not choice.has("conditions"):
		return true

	var conditions = choice["conditions"]

	# Проверка навыка.
	if conditions.has("skill"):
		var required_skill = str(conditions["skill"])

		if not GameState.has_skill(required_skill):
			return false

	# Проверка отсутствия навыка.
	if conditions.has("not_skill"):
		var forbidden_skill = str(conditions["not_skill"])

		if GameState.has_skill(forbidden_skill):
			return false

	# Проверка сюжетных флагов.
	if conditions.has("flags"):
		var required_flags = conditions["flags"]

		for flag_id in required_flags:
			var required_value = required_flags[flag_id]

			if GameState.get_flag(flag_id) != required_value:
				return false

	# Проверка отношений с NPC.
	if conditions.has("npc_relation"):
		var required_relations = conditions["npc_relation"]

		for npc_id in required_relations:
			var required_relation = str(required_relations[npc_id])

			if GameState.get_npc_relation(npc_id) != required_relation:
				return false

	# Минимальное количество HP.
	if conditions.has("min_health"):
		var minimum_health = int(conditions["min_health"])

		if GameState.health < minimum_health:
			return false

	# Все условия выполнены.
	return true


func choose(choice_index: int) -> void:
	if is_transitioning or choice_index >= available_choices.size():
		return

	is_transitioning = true
	set_choice_input_enabled(false)

	var selected_choice = available_choices[choice_index]

	if selected_choice.has("effects"):
		apply_effects(selected_choice["effects"])

	if selected_choice.has("next"):
		var next_event_id = str(selected_choice["next"])

		if chapter_data["events"].has(next_event_id):
			await transition_to_event(next_event_id)
			SaveSystem.save_game()
		else:
			is_transitioning = false
			set_choice_input_enabled(true)
			print("ERROR: Следующее событие не найдено: ", next_event_id)
	else:
		is_transitioning = false
		set_choice_input_enabled(true)


func apply_effects(effects: Dictionary) -> void:
	# Здоровье
	if effects.has("health"):
		var health_change = int(effects["health"])

		if health_change < 0:
			GameState.damage(abs(health_change))
		elif health_change > 0:
			GameState.heal(health_change)

	# Добро
	if effects.has("good"):
		GameState.good += int(effects["good"])

	# Зло
	if effects.has("evil"):
		GameState.evil += int(effects["evil"])

	# Добавление навыка
	if effects.has("add_skill"):
		GameState.add_skill(str(effects["add_skill"]))

	# Сюжетные флаги
	if effects.has("flags"):
		var new_flags = effects["flags"]

		for flag_id in new_flags:
			GameState.set_flag(flag_id, new_flags[flag_id])

	# Отношения с NPC
	if effects.has("npc_relation"):
		var relations = effects["npc_relation"]

		for npc_id in relations:
			GameState.set_npc_relation(npc_id, relations[npc_id])


func _on_choice_button_1_pressed() -> void:
	choose(0)


func _on_choice_button_2_pressed() -> void:
	choose(1)


func _on_choice_button_3_pressed() -> void:
	choose(2)


func _on_skills_button_pressed() -> void:
	if is_transitioning or game_menu_panel.visible or skills_panel.visible:
		return

	refresh_skills_panel()
	skills_button.disabled = true
	menu_button.disabled = true
	skills_modal_blocker.show()
	animate_panel_open(skills_panel)


func _on_skills_close_button_pressed() -> void:
	await animate_panel_close(skills_panel)
	skills_modal_blocker.hide()
	skills_button.disabled = false
	menu_button.disabled = false


func refresh_skills_panel() -> void:
	# Перестраиваем список с нуля, чтобы не было пустых фиксированных слотов.
	for child in skills_grid.get_children():
		child.queue_free()

	skill_name.text = ""
	skill_description.text = ""
	empty_skills_label.visible = GameState.skills.is_empty()

	if GameState.skills.is_empty():
		return

	# Каждый полученный навык занимает следующую свободную ячейку GridContainer.
	# Поэтому если какой-то навык пропущен, пробела на его месте не возникает.
	for skill_id in GameState.skills:
		var skill_button = TextureButton.new()
		skill_button.custom_minimum_size = Vector2(136, 136)
		skill_button.ignore_texture_size = true
		skill_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		skill_button.set_meta("skill_id", str(skill_id))

		match str(skill_id):
			"lockpicking":
				skill_button.texture_normal = lockpicking_texture
			_:
				continue

		skill_button.pressed.connect(_on_skill_icon_pressed.bind(str(skill_id)))
		skills_grid.add_child(skill_button)


func _on_skill_icon_pressed(skill_id: String) -> void:
	match skill_id:
		"lockpicking":
			skill_name.text = "Взлом замков"
			skill_description.text = "Вы умеете взламывать замки"
		_:
			skill_name.text = ""
			skill_description.text = ""

func _on_menu_button_pressed() -> void:
	if is_transitioning or skills_panel.visible or game_menu_panel.visible:
		return

	skills_button.disabled = true
	menu_button.disabled = true
	menu_modal_blocker.show()
	animate_panel_open(game_menu_panel)


func _on_menu_continue_button_pressed() -> void:
	await animate_panel_close(game_menu_panel)
	menu_modal_blocker.hide()
	skills_button.disabled = false
	menu_button.disabled = false


func animate_panel_open(panel: Control) -> void:
	panel.scale = Vector2(0.95, 0.95)
	panel.modulate.a = 0.0
	panel.show()
	var tween = create_tween().set_parallel(true)
	tween.tween_property(panel, "scale", Vector2.ONE, PANEL_ANIMATION_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, PANEL_ANIMATION_TIME)


func animate_panel_close(panel: Control) -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(panel, "scale", Vector2(0.95, 0.95), PANEL_ANIMATION_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(panel, "modulate:a", 0.0, PANEL_ANIMATION_TIME)
	await tween.finished
	panel.hide()
	panel.scale = Vector2.ONE
	panel.modulate.a = 1.0


func _on_menu_settings_button_pressed() -> void:
	# Настройки добавим отдельным этапом вместе с аудио и финальным UI.
	pass


func _on_menu_exit_button_pressed() -> void:
	if SaveSystem.save_game():
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	else:
		print("MENU ERROR: Не удалось сохранить игру перед выходом в главное меню.")


func _on_health_changed(current_health: int, max_health: int) -> void:
	var previous_health = 0
	for heart in hp_hearts:
		if heart.texture == hp_full_texture:
			previous_health += 1

	update_health_display(current_health, max_health)

	if current_health == previous_health:
		return

	var changed_index = current_health if current_health < previous_health else current_health - 1
	if changed_index < 0 or changed_index >= hp_hearts.size():
		return

	var heart = hp_hearts[changed_index]
	heart.pivot_offset = heart.size / 2.0
	heart.scale = Vector2.ONE

	var tween = create_tween()
	if current_health < previous_health:
		tween.tween_property(heart, "scale", Vector2(0.78, 0.78), HP_PULSE_TIME)
		tween.tween_property(heart, "scale", Vector2.ONE, HP_PULSE_TIME)
	else:
		tween.tween_property(heart, "scale", Vector2(1.18, 1.18), HP_PULSE_TIME)
		tween.tween_property(heart, "scale", Vector2.ONE, HP_PULSE_TIME)


func update_health_display(current_health: int, max_health: int) -> void:
	for i in range(hp_hearts.size()):
		if i < current_health:
			hp_hearts[i].texture = hp_full_texture
		else:
			hp_hearts[i].texture = hp_empty_texture
