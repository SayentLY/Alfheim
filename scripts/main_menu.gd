extends Control

@onready var continue_button = $CenterContainer/VBoxContainer/ContinueButton


func _ready() -> void:
	continue_button.disabled = not SaveSystem.has_save()
	continue_button.pressed.connect(_on_continue_button_pressed)


func _on_new_game_button_pressed() -> void:
	GameState.reset_game()

	get_tree().change_scene_to_file("res://scenes/chapter_one.tscn")


func _on_continue_button_pressed() -> void:
	if SaveSystem.load_game():
		get_tree().change_scene_to_file("res://scenes/chapter_one.tscn")
