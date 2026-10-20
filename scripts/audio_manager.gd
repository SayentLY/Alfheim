extends Node

const MUSIC_FADE_TIME := 0.8
const HOME_TRACK: AudioStream = preload("res://assets/audio/music/home.mp3")
const FOREST_TRACK: AudioStream = preload("res://assets/audio/music/forest.mp3")
const VILLAGE_TRACK: AudioStream = preload("res://assets/audio/music/village.mp3")
const NIGHT_TRACK: AudioStream = preload("res://assets/audio/music/night.mp3")
const DANGER_TRACK: AudioStream = preload("res://assets/audio/music/danger.mp3")
const MAIN_MENU_TRACK: AudioStream = preload("res://assets/audio/music/main_menu.mp3")

var current_state := ""
var active_player: AudioStreamPlayer
var standby_player: AudioStreamPlayer
var transition_tween: Tween


func _ready() -> void:
	active_player = AudioStreamPlayer.new()
	standby_player = AudioStreamPlayer.new()
	add_child(active_player)
	add_child(standby_player)
	active_player.volume_db = -80.0
	standby_player.volume_db = -80.0


func play_music(state: String) -> void:
	if state == current_state:
		return

	var track: AudioStream = null
	match state:
		"home":
			track = HOME_TRACK
		"forest":
			track = FOREST_TRACK
		"village":
			track = VILLAGE_TRACK
		"night":
			track = NIGHT_TRACK
		"danger":
			track = DANGER_TRACK
		"main_menu":
			track = MAIN_MENU_TRACK

	if transition_tween != null and transition_tween.is_running():
		transition_tween.kill()

	current_state = state
	var old_player = active_player
	active_player = standby_player
	standby_player = old_player

	active_player.stop()
	if track != null:
		var looping_track = track.duplicate()
		if looping_track is AudioStreamMP3:
			looping_track.loop = true
		active_player.stream = looping_track
		active_player.volume_db = -80.0
		active_player.play()

	transition_tween = create_tween().set_parallel(true)
	transition_tween.tween_property(standby_player, "volume_db", -80.0, MUSIC_FADE_TIME)
	if track != null:
		transition_tween.tween_property(active_player, "volume_db", 0.0, MUSIC_FADE_TIME)
	await transition_tween.finished
	if is_instance_valid(old_player) and old_player != active_player:
		old_player.stop()
