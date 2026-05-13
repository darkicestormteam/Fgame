extends CanvasLayer

@onready var tap_sound: AudioStreamPlayer = $Tap

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_reset_game_pressed() -> void:
	get_tree().paused = false
	if tap_sound:
		tap_sound.play()
	await get_tree().create_timer(0.1).timeout
	get_tree().reload_current_scene()
	GameOver.hide()


func _on_texture_button_mouse_entered() -> void:
	pass
