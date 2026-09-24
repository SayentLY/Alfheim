extends Control

@onready var event_text = $MarginContainer/VBoxContainer/EventText
@onready var choice_button_1 = $MarginContainer/VBoxContainer/ChoiceButton1
@onready var choice_button_2 = $MarginContainer/VBoxContainer/ChoiceButton2
@onready var choice_button_3 = $MarginContainer/VBoxContainer/ChoiceButton3

var chapter_data: Dictionary
var current_event_id: String

# Здесь хранятся только те варианты выбора,
# которые сейчас доступны игроку.
var available_choices: Array = []


func _ready() -> void:
	load_chapter_data()

	choice_button_1.pressed.connect(_on_choice_button_1_pressed)
	choice_button_2.pressed.connect(_on_choice_button_2_pressed)
	choice_button_3.pressed.connect(_on_choice_button_3_pressed)


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

	# Каждый раз создаём новый список доступных вариантов.
	available_choices.clear()

	for choice in choices:
		if check_conditions(choice):
			available_choices.append(choice)

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

	# Временная отладка.
	print("--- GAME STATE ---")
	print("HP: ", GameState.health, "/", GameState.max_health)
	print("GOOD: ", GameState.good)
	print("EVIL: ", GameState.evil)
	print("SKILLS: ", GameState.skills)
	print("FLAGS: ", GameState.flags)
	print("NPC RELATIONS: ", GameState.npc_relations)
	print("------------------")


func _on_choice_button_1_pressed() -> void:
	choose(0)


func _on_choice_button_2_pressed() -> void:
	choose(1)


func _on_choice_button_3_pressed() -> void:
	choose(2)
