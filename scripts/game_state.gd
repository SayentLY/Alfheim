extends Node


signal health_changed(current_health: int, max_health: int)
signal skill_unlocked(skill_id: String)
signal health_depleted


# Версия формата сохранения.
# В будущем позволит обновлять игру, не ломая старые сохранения.
const SAVE_VERSION: int = 1


# Текущее событие
var current_event_id: String = ""


# Основные характеристики
var max_health: int = 3
var health: int = 3


# Скрытая мораль
var good: int = 0
var evil: int = 0


# Навыки
var skills: Array[String] = []


# Сюжетные флаги
var flags: Dictionary = {}


# Отношения с NPC
var npc_relations: Dictionary = {}


# =========================
# НАВЫКИ
# =========================

func has_skill(skill_id: String) -> bool:
	return skill_id in skills


func add_skill(skill_id: String) -> void:
	if not has_skill(skill_id):
		skills.append(skill_id)
		skill_unlocked.emit(skill_id)


# =========================
# ФЛАГИ
# =========================

func set_flag(flag_id: String, value = true) -> void:
	flags[flag_id] = value


func get_flag(flag_id: String, default_value = false):
	return flags.get(flag_id, default_value)


# =========================
# ОТНОШЕНИЯ NPC
# =========================

func set_npc_relation(npc_id: String, relation: String) -> void:
	npc_relations[npc_id] = relation


func get_npc_relation(npc_id: String) -> String:
	return npc_relations.get(npc_id, "neutral")


# =========================
# ЗДОРОВЬЕ
# =========================

func damage(amount: int) -> void:
	var previous_health = health
	health = max(health - amount, 0)

	if health != previous_health:
		health_changed.emit(health, max_health)

	if previous_health > 0 and health == 0:
		health_depleted.emit()


func heal(amount: int) -> void:
	var previous_health = health
	health = min(health + amount, max_health)

	if health != previous_health:
		health_changed.emit(health, max_health)


# =========================
# НОВАЯ ИГРА
# =========================

func reset_game() -> void:
	current_event_id = ""

	health = max_health
	good = 0
	evil = 0

	skills.clear()
	flags.clear()
	npc_relations.clear()


# =========================
# ДАННЫЕ ДЛЯ СОХРАНЕНИЯ
# =========================

func get_save_data() -> Dictionary:
	return {
		"save_version": SAVE_VERSION,
		"current_event_id": current_event_id,
		"max_health": max_health,
		"health": health,
		"good": good,
		"evil": evil,
		"skills": skills.duplicate(),
		"flags": flags.duplicate(true),
		"npc_relations": npc_relations.duplicate(true)
	}
