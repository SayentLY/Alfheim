extends Control

signal closed

@onready var panel: TextureRect = $SettingsPanel
@onready var close_button: Button = $SettingsPanel/CloseButton
@onready var music_slider: HSlider = $SettingsPanel/MusicSlider
@onready var ambience_slider: HSlider = $SettingsPanel/AmbienceSlider
@onready var sfx_slider: HSlider = $SettingsPanel/SFXSlider
@onready var music_value: Label = $SettingsPanel/MusicValue
@onready var ambience_value: Label = $SettingsPanel/AmbienceValue
@onready var sfx_value: Label = $SettingsPanel/SFXValue

const PANEL_FADE_TIME := 0.20

var closing := false


func _ready() -> void:
	panel.pivot_offset = panel.size / 2.0

	music_slider.value_changed.connect(_on_slider_changed.bind("music"))
	ambience_slider.value_changed.connect(_on_slider_changed.bind("ambience"))
	sfx_slider.value_changed.connect(_on_slider_changed.bind("sfx"))
	close_button.pressed.connect(close_settings)
	_refresh_sliders()


func open_settings() -> void:
	if visible or closing:
		return

	_refresh_sliders()
	modulate.a = 0.0
	show()

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, PANEL_FADE_TIME)
	close_button.grab_focus()


func close_settings() -> void:
	if not visible or closing:
		return

	closing = true
	SoundSettings.save_now()

	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, PANEL_FADE_TIME)
	await tween.finished

	hide()
	modulate.a = 1.0
	closing = false
	closed.emit()


func _refresh_sliders() -> void:
	music_slider.set_value_no_signal(SoundSettings.get_volume_percent("music"))
	ambience_slider.set_value_no_signal(SoundSettings.get_volume_percent("ambience"))
	sfx_slider.set_value_no_signal(SoundSettings.get_volume_percent("sfx"))
	_update_value_labels()


func _on_slider_changed(value: float, category: String) -> void:
	SoundSettings.set_volume_percent(category, roundi(value))
	_update_value_labels()


func _update_value_labels() -> void:
	music_value.text = "%d%%" % roundi(music_slider.value)
	ambience_value.text = "%d%%" % roundi(ambience_slider.value)
	sfx_value.text = "%d%%" % roundi(sfx_slider.value)


func _unhandled_input(event: InputEvent) -> void:
	if visible and not closing and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_settings()
