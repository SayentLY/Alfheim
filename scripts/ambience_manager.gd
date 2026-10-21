extends Node

# Environmental audio is independent of the existing music system.
# Two players let locations fade into each other without interrupting the music.
const FADE_TIME := 1.5
const AMBIENCE_VOLUME_DB := -18.0

const FOREST: AudioStream = preload("res://assets/audio/ambience/forest_ambience.ogg")
const VILLAGE: AudioStream = preload("res://assets/audio/ambience/village_ambience.ogg")
const NIGHT: AudioStream = preload("res://assets/audio/ambience/night_ambience.ogg")
const FIRE: AudioStream = preload("res://assets/audio/ambience/fire_ambience.ogg")

const HORSE: AudioStream = preload("res://assets/audio/sfx/horse_neigh.wav")
const ANVIL_1: AudioStream = preload("res://assets/audio/sfx/anvil_hit_01.wav")
const ANVIL_2: AudioStream = preload("res://assets/audio/sfx/anvil_hit_02.wav")
const BELL: AudioStream = preload("res://assets/audio/sfx/village_bell.wav")
const WOOD_CREAK: AudioStream = preload("res://assets/audio/sfx/wood_creak.wav")

var current_ambience := ""
var current_effect_profile := ""

var active_ambience_player: AudioStreamPlayer
var standby_ambience_player: AudioStreamPlayer
var ambience_fade: Tween
var effect_player: AudioStreamPlayer
var bell_player: AudioStreamPlayer
var effect_timer: Timer
var bell_timer: Timer


func _ready() -> void:
	randomize()

	active_ambience_player = AudioStreamPlayer.new()
	standby_ambience_player = AudioStreamPlayer.new()
	effect_player = AudioStreamPlayer.new()
	bell_player = AudioStreamPlayer.new()

	add_child(active_ambience_player)
	add_child(standby_ambience_player)
	add_child(effect_player)
	add_child(bell_player)

	active_ambience_player.volume_db = -80.0
	standby_ambience_player.volume_db = -80.0

	effect_timer = Timer.new()
	effect_timer.one_shot = true
	add_child(effect_timer)
	effect_timer.timeout.connect(_on_effect_timer_timeout)

	bell_timer = Timer.new()
	bell_timer.one_shot = true
	add_child(bell_timer)
	bell_timer.timeout.connect(_on_bell_timer_timeout)


# Called whenever the current story event changes, including when loading a save.
func enter_event(event_id: String) -> void:
	_set_ambience(_ambience_for_event(event_id))
	_set_effect_profile(_effect_profile_for_event(event_id))


func stop_all() -> void:
	_set_effect_profile("")
	_set_ambience("none")


func _ambience_for_event(event_id: String) -> String:
	# Initial raid and the final burning village.
	if event_id == "prologue_raid" or event_id in [
		"village_night_approach", "village_night_thieves",
		"final_choice_robber", "final_choice_outsider",
		"chapter_end_bandits", "chapter_end_village"
	]:
		return "fire"

	# Outside in the countryside, including the road leading to the old mill.
	if event_id in [
		"prologue_meadow", "meadow_start", "meadow_path", "meadow_cross",
		"crossroads", "thief_encounter", "thief_silent", "thief_nosy",
		"mill_after_crackdown", "mill_after_escape", "mill_after_lie"
	]:
		return "forest"

	# Night air is heard outside the manor and at the mill at night.
	if event_id in [
		"robbery_start", "robbery_locked_door", "robbery_lock_opened",
		"robbery_escape_door", "robbery_escape_window", "robbery_escape",
		"mill_night_wakeup"
	]:
		return "night"

	# Quiet interiors: no unrelated outdoor ambience.
	if event_id in ["robbery_inside", "robbery_owner", "old_mill"]:
		return "none"

	# Every other chapter I event is in a settlement or near its buildings.
	return "village"


func _effect_profile_for_event(event_id: String) -> String:
	# Forge hits are heard only while viewing the forge itself.
	if event_id in ["prologue_forge", "village_square_forge"]:
		return "forge"

	# Old wooden interiors make occasional subtle creaks.
	if event_id in ["robbery_inside", "robbery_owner", "old_mill"]:
		return "creak"

	# Horse and village bell only while outside in an ordinary village.
	if _ambience_for_event(event_id) == "village" and event_id != "prologue_home":
		return "village"

	return ""


func _track_for_state(state: String) -> AudioStream:
	match state:
		"forest":
			return FOREST
		"village":
			return VILLAGE
		"night":
			return NIGHT
		"fire":
			return FIRE
	return null


func _set_ambience(next_state: String) -> void:
	if next_state == current_ambience:
		return

	if ambience_fade != null and ambience_fade.is_running():
		ambience_fade.kill()

	current_ambience = next_state

	var old_player := active_ambience_player
	active_ambience_player = standby_ambience_player
	standby_ambience_player = old_player

	active_ambience_player.stop()
	var track := _track_for_state(next_state)

	if track != null:
		var loop_track := track.duplicate()
		if loop_track is AudioStreamOggVorbis:
			loop_track.loop = true
		active_ambience_player.stream = loop_track
		active_ambience_player.volume_db = -80.0
		active_ambience_player.play()

	ambience_fade = create_tween().set_parallel(true)

	if old_player.playing:
		ambience_fade.tween_property(old_player, "volume_db", -80.0, FADE_TIME)

	if track != null:
		ambience_fade.tween_property(active_ambience_player, "volume_db", AMBIENCE_VOLUME_DB, FADE_TIME)

	# An empty fade is possible on startup; it doesn't need a tween.
	if not old_player.playing and track == null:
		ambience_fade.kill()
		return

	ambience_fade.finished.connect(func() -> void:
		if old_player != active_ambience_player:
			old_player.stop()
	)


func _set_effect_profile(next_profile: String) -> void:
	if next_profile == current_effect_profile:
		return

	current_effect_profile = next_profile
	effect_timer.stop()
	bell_timer.stop()
	effect_player.stop()
	bell_player.stop()

	if next_profile == "":
		return

	_schedule_effect(true)
	if next_profile == "village":
		_schedule_bell(true)


func _schedule_effect(initial: bool = false) -> void:
	match current_effect_profile:
		"village":
			effect_timer.start(randf_range(25.0, 55.0) if initial else randf_range(60.0, 135.0))
		"forge":
			effect_timer.start(randf_range(3.0, 6.0) if initial else randf_range(7.0, 16.0))
		"creak":
			effect_timer.start(randf_range(8.0, 14.0) if initial else randf_range(18.0, 38.0))


func _schedule_bell(initial: bool = false) -> void:
	if current_effect_profile == "village":
		bell_timer.start(randf_range(90.0, 160.0) if initial else randf_range(180.0, 360.0))


func _on_effect_timer_timeout() -> void:
	if current_effect_profile == "":
		return

	# Don't pile random effects on top of one another.
	if effect_player.playing or bell_player.playing:
		effect_timer.start(randf_range(4.0, 9.0))
		return

	match current_effect_profile:
		"village":
			effect_player.stream = HORSE
			effect_player.volume_db = -23.0
			effect_player.pitch_scale = randf_range(0.94, 1.04)
		"forge":
			effect_player.stream = ANVIL_1 if randf() < 0.5 else ANVIL_2
			effect_player.volume_db = -15.0
			effect_player.pitch_scale = randf_range(0.96, 1.04)
		"creak":
			effect_player.stream = WOOD_CREAK
			effect_player.volume_db = -21.0
			effect_player.pitch_scale = randf_range(0.88, 1.04)
		_:
			return

	effect_player.play()
	_schedule_effect()


func _on_bell_timer_timeout() -> void:
	if current_effect_profile != "village":
		return

	if effect_player.playing or bell_player.playing:
		bell_timer.start(randf_range(5.0, 12.0))
		return

	bell_player.stream = BELL
	bell_player.volume_db = -21.0
	bell_player.pitch_scale = randf_range(0.97, 1.02)
	bell_player.play()
	_schedule_bell()
