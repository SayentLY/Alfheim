extends Control

@onready var background = $Background
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


func _ready() -> void:
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
	var choices = event["choices"]

	event_text.text = event["text"]
	update_background(event_id)
	update_character_portrait(event_id)

	# Каждый раз создаём новый список доступных вариантов.
	available_choices.clear()

	for choice in choices:
		if check_conditions(choice):
			available_choices.append(choice)

	if available_choices.size() > 3:
		push_error(
			"CHOICE LIMIT ERROR: Event '%s' has %d available choices. Maximum allowed is 3."
			% [event_id, available_choices.size()]
		)

	choice_button_1.hide()
	choice_button_2.hide()
	choice_button_3.hide()

	if available_choices.size() >= 1:
		choice_button_1.text = available_choices[0]["text"]
		choice_button_1.show()

	if available_choices.size() >= 2:
		choice_button_2.text = available_choices[1]["text"]
		choice_button_2.show()

	if available_choices.size() >= 3:
		choice_button_3.text = available_choices[2]["text"]
		choice_button_3.show()


func update_character_portrait(event_id: String) -> void:
	match event_id:
		"boy_encounter":
			character_portrait.texture = boy_pleading_texture
			character_portrait.show()
		"boy_helped", "boy_return_positive", "boy_lockpicking_learned", "boy_lockpicking_refused":
			character_portrait.texture = boy_friendly_texture
			character_portrait.show()
		"boy_ignored", "boy_return_negative":
			character_portrait.texture = boy_angry_texture
			character_portrait.show()
		"thief_encounter":
			character_portrait.texture = thief_neutral_texture
			character_portrait.show()
		"thief_silent", "bandit_thief_positive", "bandit_thief_join", "bandit_thief_training", "bandit_thief_refuse", "bandit_thief_refuse_training", "bandit_thief_leave":
			character_portrait.texture = thief_friendly_texture
			character_portrait.show()
		"thief_nosy", "bandit_thief_negative", "bandit_thief_driven_away":
			character_portrait.texture = thief_angry_texture
			character_portrait.show()
		"fortune_teller", "fortune_teller_accept", "fortune_teller_refuse":
			character_portrait.texture = fortune_teller_texture
			character_portrait.show()
		"guard_questions_robber", "guard_arrest_escape", "guard_questions_innocent", "guard_crackdown", "guard_escape", "guard_lie", "guard_lie_leave":
			character_portrait.texture = guard_texture
			character_portrait.show()
		"bread_theft_failed", "bread_ask_failed":
			character_portrait.texture = peasant_grumpy_texture
			character_portrait.show()
		"village_cart_help", "village_cart_leave":
			character_portrait.texture = peasant_pleading_texture
			character_portrait.show()
		_:
			character_portrait.hide()


func update_background(event_id: String) -> void:
	match event_id:
		"prologue_home":
			background.texture = home_village_day_texture
			background.show()
		"prologue_forge":
			background.texture = home_forge_day_texture
			background.show()
		"prologue_raid":
			background.texture = home_village_burning_night_texture
			background.show()
		"prologue_meadow":
			background.texture = forest_escape_dawn_texture
			background.show()
		"meadow_start", "meadow_path", "meadow_cross":
			background.texture = meadow_morning_texture
			background.show()
		"crossroads":
			background.texture = crossroads_morning_texture
			background.show()
		"thief_encounter", "thief_silent", "thief_nosy":
			background.texture = forest_path_day_texture
			background.show()
		"boy_encounter", "boy_helped", "boy_ignored":
			background.texture = new_village_outskirts_day_texture
			background.show()
		"village_arrival", "bread_theft_failed", "bread_ask_failed", "village_square", "village_square_market":
			background.texture = village_market_day_texture
			background.show()
		"leper_encounter", "leper_help", "leper_rejected":
			background.texture = village_street_day_texture
			background.show()
		"village_square_forge":
			background.texture = village_forge_day_texture
			background.show()
		"village_well", "village_well_listen", "village_well_leave":
			background.texture = village_well_day_texture
			background.show()
		"boy_return_positive", "boy_lockpicking_learned", "boy_lockpicking_refused", "boy_return_negative":
			background.texture = village_barn_alley_day_texture
			background.show()
		"bandit_route", "bandit_thief_positive", "bandit_thief_join", "bandit_thief_training", "bandit_thief_refuse", "bandit_thief_refuse_training", "bandit_thief_leave", "bandit_thief_negative", "bandit_thief_driven_away", "bandit_boy_skilled", "bandit_boy_join", "bandit_boy_refuse", "bandit_boy_unskilled", "bandit_boy_unskilled_leave":
			background.texture = bandit_hideout_evening_texture
			background.show()
		"robbery_start", "robbery_locked_door", "robbery_lock_opened", "robbery_escape_door", "robbery_escape_window", "robbery_escape":
			background.texture = manor_exterior_night_texture
			background.show()
		"robbery_inside", "robbery_owner":
			background.texture = manor_interior_night_texture
			background.show()
		"morning_start", "morning_after_robbery", "morning_normal", "morning_village", "morning_rumors_participant", "morning_rumors_outsider", "morning_rumors_leave", "fortune_teller", "fortune_teller_accept", "fortune_teller_refuse", "post_fortune", "village_cart_help", "village_cart_leave", "post_cart", "guard_questions_robber", "guard_arrest_escape", "guard_questions_innocent", "guard_crackdown", "guard_escape", "guard_lie", "guard_lie_leave":
			background.texture = village_dawn_texture
			background.show()
		"mill_after_crackdown", "mill_after_escape", "mill_after_lie":
			background.texture = old_mill_evening_texture
			background.show()
		"old_mill":
			background.texture = old_mill_interior_sunset_texture
			background.show()
		"mill_night_wakeup", "village_night_approach", "village_night_thieves", "final_choice_robber", "final_choice_outsider", "chapter_end_bandits", "chapter_end_village":
			background.texture = village_fire_night_texture
			background.show()
		_:
			# Для остальных событий фон будет добавляться по мере готовности арта.
			background.hide()


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
	if choice_index >= available_choices.size():
		return

	var selected_choice = available_choices[choice_index]

	# Сначала применяем последствия выбора.
	if selected_choice.has("effects"):
		apply_effects(selected_choice["effects"])

	# Затем переходим к следующему событию.
	if selected_choice.has("next"):
		var next_event_id = str(selected_choice["next"])

		if chapter_data["events"].has(next_event_id):
			show_event(next_event_id)

			# Сохраняем уже ПОСЛЕ перехода.
			# Поэтому Continue вернёт игрока к новому событию,
			# а не заставит повторять предыдущий выбор.
			SaveSystem.save_game()
		else:
			print("ERROR: Следующее событие не найдено: ", next_event_id)


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
	if game_menu_panel.visible or skills_panel.visible:
		return

	refresh_skills_panel()
	skills_button.disabled = true
	menu_button.disabled = true
	skills_modal_blocker.show()
	skills_panel.show()


func _on_skills_close_button_pressed() -> void:
	skills_panel.hide()
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
	if skills_panel.visible or game_menu_panel.visible:
		return

	skills_button.disabled = true
	menu_button.disabled = true
	menu_modal_blocker.show()
	game_menu_panel.show()


func _on_menu_continue_button_pressed() -> void:
	game_menu_panel.hide()
	menu_modal_blocker.hide()
	skills_button.disabled = false
	menu_button.disabled = false


func _on_menu_settings_button_pressed() -> void:
	# Настройки добавим отдельным этапом вместе с аудио и финальным UI.
	pass


func _on_menu_exit_button_pressed() -> void:
	if SaveSystem.save_game():
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	else:
		print("MENU ERROR: Не удалось сохранить игру перед выходом в главное меню.")


func _on_health_changed(current_health: int, max_health: int) -> void:
	update_health_display(current_health, max_health)


func update_health_display(current_health: int, max_health: int) -> void:
	for i in range(hp_hearts.size()):
		if i < current_health:
			hp_hearts[i].texture = hp_full_texture
		else:
			hp_hearts[i].texture = hp_empty_texture
