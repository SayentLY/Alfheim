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

	var prepared_data = _prepare_save_data(save_data)

	if prepared_data.is_empty():
		return false

	_apply_save_data(prepared_data)

	return true


func _prepare_save_data(raw_data: Dictionary) -> Dictionary:
	var save_data = raw_data.duplicate(true)
	var save_version = int(save_data.get("save_version", 1))

	if save_version < 1:
		print("LOAD ERROR: Неподдерживаемая версия сохранения: ", save_version)
		return {}

	if save_version > GameState.SAVE_VERSION:
		print("LOAD ERROR: Сохранение создано более новой версией игры.")
		return {}

	# Здесь будут последовательные миграции старых форматов:
	# if save_version == 1:
	#     save_data = _migrate_v1_to_v2(save_data)
	#     save_version = 2

	save_data["save_version"] = save_version

	var loaded_max_health = int(save_data.get("max_health", 3))
	loaded_max_health = max(loaded_max_health, 1)
	save_data["max_health"] = loaded_max_health
	save_data["health"] = clampi(int(save_data.get("health", loaded_max_health)), 0, loaded_max_health)
	save_data["good"] = max(int(save_data.get("good", 0)), 0)
	save_data["evil"] = max(int(save_data.get("evil", 0)), 0)
	save_data["current_event_id"] = str(save_data.get("current_event_id", ""))

	if not save_data.get("skills", []) is Array:
		save_data["skills"] = []

	if not save_data.get("flags", {}) is Dictionary:
		save_data["flags"] = {}

	if not save_data.get("npc_relations", {}) is Dictionary:
		save_data["npc_relations"] = {}

	return save_data


func _apply_save_data(save_data: Dictionary) -> void:
	GameState.current_event_id = str(save_data["current_event_id"])
	GameState.max_health = int(save_data["max_health"])
	GameState.health = int(save_data["health"])
	GameState.good = int(save_data["good"])
	GameState.evil = int(save_data["evil"])

	GameState.skills.clear()

	for skill in save_data["skills"]:
		var skill_id = str(skill)

		if skill_id != "" and not GameState.has_skill(skill_id):
			GameState.skills.append(skill_id)

	GameState.flags = save_data["flags"].duplicate(true)
	GameState.npc_relations = save_data["npc_relations"].duplicate(true)


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
