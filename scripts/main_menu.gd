extends Control

@onready var new_game_button = $CenterContainer/VBoxContainer/NewGameButton
@onready var continue_button = $CenterContainer/VBoxContainer/ContinueButton
@onready var settings_button = $CenterContainer/VBoxContainer/SettingsButton
@onready var exit_button = $CenterContainer/VBoxContainer/ExitButton
@onready var fade_overlay = $FadeOverlay
@onready var loading_overlay = $LoadingOverlay
@onready var loading_label = $LoadingOverlay/LoadingLabel

const MENU_FADE_IN_TIME := 0.45
const BUTTON_FADE_TIME := 0.28
const BUTTON_STAGGER := 0.09
const MENU_FADE_OUT_TIME := 0.25
const SCREEN_FADE_OUT_TIME := 0.25
const GAME_SCENE_PATH := "res://scenes/chapter_one.tscn"

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

	# Кнопки мягко уходят, но мы больше не держим игрока на пустом чёрном экране.
	var buttons = [new_game_button, continue_button, settings_button, exit_button]
	var buttons_tween = create_tween().set_parallel(true)
	for button in buttons:
		buttons_tween.tween_property(button, "modulate:a", 0.0, MENU_FADE_OUT_TIME)
	await buttons_tween.finished

	fade_overlay.modulate.a = 0.0
	fade_overlay.show()
	var fade_tween = create_tween()
	fade_tween.tween_property(fade_overlay, "modulate:a", 1.0, SCREEN_FADE_OUT_TIME)
	await fade_tween.finished

	# Отдельный экран загрузки остаётся отрисованным, пока тяжёлая игровая
	# сцена загружается в фоне. Серый viewport между сценами не показывается.
	loading_overlay.show()
	loading_overlay.move_to_front()
	fade_overlay.hide()

	var request_error = ResourceLoader.load_threaded_request(GAME_SCENE_PATH)
	if request_error != OK:
		push_error("Не удалось начать загрузку Chapter I.")
		is_transitioning = false
		return

	var progress: Array = []
	var dot_step := 0
	while true:
		var status = ResourceLoader.load_threaded_get_status(GAME_SCENE_PATH, progress)

		if status == ResourceLoader.THREAD_LOAD_LOADED:
			break
		if status == ResourceLoader.THREAD_LOAD_FAILED or status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			push_error("Ошибка загрузки Chapter I.")
			is_transitioning = false
			return

		dot_step = (dot_step + 1) % 4
		loading_label.text = "Загрузка" + ".".repeat(dot_step)
		await get_tree().process_frame

	var packed_scene = ResourceLoader.load_threaded_get(GAME_SCENE_PATH) as PackedScene
	if packed_scene == null:
		push_error("Chapter I загрузилась некорректно.")
		is_transitioning = false
		return

	get_tree().change_scene_to_packed(packed_scene)


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
