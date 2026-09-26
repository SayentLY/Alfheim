extends Control

@onready var new_game_button = $CenterContainer/VBoxContainer/NewGameButton
@onready var continue_button = $CenterContainer/VBoxContainer/ContinueButton
@onready var settings_button = $CenterContainer/VBoxContainer/SettingsButton
@onready var exit_button = $CenterContainer/VBoxContainer/ExitButton
@onready var fade_overlay = $FadeOverlay

const MENU_FADE_IN_TIME := 0.45
const BUTTON_FADE_TIME := 0.28
const BUTTON_STAGGER := 0.09
const MENU_FADE_OUT_TIME := 0.25
const SCREEN_FADE_OUT_TIME := 0.45

var is_transitioning := false


func _ready() -> void:
	continue_button.disabled = not SaveSystem.has_save()
	continue_button.pressed.connect(_on_continue_button_pressed)

	# При запуске меню сначала виден чёрный экран, затем открывается фон.
	fade_overlay.modulate.a = 1.0
	fade_overlay.show()

	var buttons = [new_game_button, continue_button, settings_button, exit_button]
	for button in buttons:
		button.modulate.a = 0.0
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var screen_tween = create_tween()
	screen_tween.tween_property(fade_overlay, "modulate:a", 0.0, MENU_FADE_IN_TIME)
	await screen_tween.finished
	fade_overlay.hide()

	# Кнопки проявляются последовательно сверху вниз.
	for i in range(buttons.size()):
		var button = buttons[i]
		var tween = create_tween()
		tween.tween_interval(i * BUTTON_STAGGER)
		tween.tween_property(button, "modulate:a", 1.0, BUTTON_FADE_TIME)

	await get_tree().create_timer(BUTTON_FADE_TIME + BUTTON_STAGGER * (buttons.size() - 1)).timeout

	for button in buttons:
		button.mouse_filter = Control.MOUSE_FILTER_STOP


func set_menu_input_enabled(enabled: bool) -> void:
	var buttons = [new_game_button, continue_button, settings_button, exit_button]
	for button in buttons:
		button.mouse_filter = Control.MOUSE_FILTER_STOP if enabled else Control.MOUSE_FILTER_IGNORE


func transition_to_game() -> void:
	if is_transitioning:
		return

	is_transitioning = true
	set_menu_input_enabled(false)

	# Сначала мягко убираем сами кнопки.
	var buttons = [new_game_button, continue_button, settings_button, exit_button]
	var buttons_tween = create_tween().set_parallel(true)
	for button in buttons:
		buttons_tween.tween_property(button, "modulate:a", 0.0, MENU_FADE_OUT_TIME)
	await buttons_tween.finished

	# Затем поверх меню плавно приходит чёрный экран.
	fade_overlay.modulate.a = 0.0
	fade_overlay.show()
	var fade_tween = create_tween()
	fade_tween.tween_property(fade_overlay, "modulate:a", 1.0, SCREEN_FADE_OUT_TIME)
	await fade_tween.finished

	get_tree().change_scene_to_file("res://scenes/chapter_one.tscn")


func _on_new_game_button_pressed() -> void:
	if is_transitioning:
		return

	GameState.reset_game()
	await transition_to_game()


func _on_continue_button_pressed() -> void:
	if is_transitioning:
		return

	if SaveSystem.load_game():
		await transition_to_game()


func _on_settings_button_pressed() -> void:
	pass


func _on_exit_button_pressed() -> void:
	if is_transitioning:
		return

	get_tree().quit()
