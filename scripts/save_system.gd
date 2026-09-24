extends Node


const SAVE_PATH: String = "user://save.json"


# =========================
# СОХРАНЕНИЕ
# =========================

func save_game() -> bool:
	var save_data = GameState.get_save_data()
	var json_text = JSON.stringify(save_data)

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)

	if file == null:
		print("SAVE ERROR: Не удалось открыть файл сохранения.")
		return false

	file.store_string(json_text)
	file.close()

	print("--- GAME SAVED ---")
	print("PATH: ", SAVE_PATH)
	print("EVENT: ", GameState.current_event_id)
	print("HP: ", GameState.health, "/", GameState.max_health)
	print("GOOD: ", GameState.good)
	print("EVIL: ", GameState.evil)
	print("SKILLS: ", GameState.skills)
	print("FLAGS: ", GameState.flags)
	print("NPC RELATIONS: ", GameState.npc_relations)
	print("------------------")

	return true


# =========================
# ЗАГРУЗКА
# =========================

func load_game() -> bool:
	if not has_save():
		print("LOAD ERROR: Файл сохранения не найден.")
		return false

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)

	if file == null:
		print("LOAD ERROR: Не удалось открыть файл сохранения.")
		return false

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_text)

	if error != OK:
		print("LOAD ERROR JSON: ", json.get_error_message())
		return false

	var save_data = json.data

	if not save_data is Dictionary:
		print("LOAD ERROR: Некорректный формат сохранения.")
		return false

	GameState.current_event_id = str(save_data.get("current_event_id", ""))

	GameState.max_health = int(save_data.get("max_health", 3))
	GameState.health = int(save_data.get("health", GameState.max_health))

	GameState.good = int(save_data.get("good", 0))
	GameState.evil = int(save_data.get("evil", 0))

	GameState.skills.clear()

	for skill in save_data.get("skills", []):
		GameState.skills.append(str(skill))

	GameState.flags = save_data.get("flags", {}).duplicate(true)
	GameState.npc_relations = save_data.get("npc_relations", {}).duplicate(true)

	print("--- GAME LOADED ---")
	print("VERSION: ", save_data.get("save_version", 0))
	print("EVENT: ", GameState.current_event_id)
	print("HP: ", GameState.health, "/", GameState.max_health)
	print("GOOD: ", GameState.good)
	print("EVIL: ", GameState.evil)
	print("SKILLS: ", GameState.skills)
	print("FLAGS: ", GameState.flags)
	print("NPC RELATIONS: ", GameState.npc_relations)
	print("-------------------")

	return true


# =========================
# ПРОВЕРКА СОХРАНЕНИЯ
# =========================

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


# =========================
# УДАЛЕНИЕ СОХРАНЕНИЯ
# =========================

func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)

	print("SAVE DELETED")
