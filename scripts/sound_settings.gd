extends Node

# Persistent independent volume controls for the three sound categories.
# Audio buses are created before AudioManager/AmbienceManager start playing.
const SETTINGS_PATH := "user://audio_settings.cfg"
const SAVE_DELAY := 0.35
const DEFAULT_LEVELS := {
	"music": 65,
	"ambience": 100,
	"sfx": 100
}
const BUS_NAMES := {
	"music": "Music",
	"ambience": "Ambience",
	"sfx": "SFX"
}

var levels: Dictionary = DEFAULT_LEVELS.duplicate()
var save_timer: Timer


func _ready() -> void:
	for category in BUS_NAMES:
		_ensure_bus(str(BUS_NAMES[category]))

	_load_saved_levels()
	_apply_all_levels()

	save_timer = Timer.new()
	save_timer.one_shot = true
	save_timer.wait_time = SAVE_DELAY
	add_child(save_timer)
	save_timer.timeout.connect(save_now)


func get_volume_percent(category: String) -> int:
	return int(levels.get(category, 100))


func set_volume_percent(category: String, percent: int) -> void:
	if not BUS_NAMES.has(category):
		return

	var limited_percent := clampi(percent, 0, 100)
	if get_volume_percent(category) == limited_percent:
		return

	levels[category] = limited_percent
	_apply_level(category)
	save_timer.start()


func save_now() -> void:
	if save_timer != null:
		save_timer.stop()

	var config := ConfigFile.new()
	for category in BUS_NAMES:
		config.set_value("audio", str(category), int(levels[category]))

	var error := config.save(SETTINGS_PATH)
	if error != OK:
		push_warning("Не удалось сохранить громкость звука: %s" % error)


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return

	AudioServer.add_bus()
	var new_index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(new_index, bus_name)
	AudioServer.set_bus_send(new_index, "Master")


func _load_saved_levels() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return

	for category in BUS_NAMES:
		var saved_value = config.get_value("audio", str(category), DEFAULT_LEVELS[category])
		if saved_value is int or saved_value is float:
			levels[category] = clampi(int(saved_value), 0, 100)


func _apply_all_levels() -> void:
	for category in BUS_NAMES:
		_apply_level(str(category))


func _apply_level(category: String) -> void:
	var index := AudioServer.get_bus_index(str(BUS_NAMES[category]))
	if index == -1:
		return

	var percent := get_volume_percent(category)
	AudioServer.set_bus_mute(index, percent == 0)
	AudioServer.set_bus_volume_db(
		index,
		linear_to_db(float(percent) / 100.0) if percent > 0 else -80.0
	)
