extends CanvasLayer

@onready var tap_sound: AudioStreamPlayer = $Tap
@onready var restart_button: TextureButton = $TextureButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
		add_to_group("game_over")
		hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
		pass


func _input(event: InputEvent) -> void:
		if not visible:
				return

		if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_SPACE):
				_on_reset_game_pressed()


func _on_reset_game_pressed() -> void:
		get_tree().paused = false
		if tap_sound:
				tap_sound.play()
		await get_tree().create_timer(0.1).timeout
		get_tree().reload_current_scene()
		hide()


func _on_texture_button_mouse_entered() -> void:
		pass


func show_game_over() -> void:
		update_all_localized_texts()
		show()


func update_all_localized_texts() -> void:
		_update_node_recursive(self)


func _update_node_recursive(node: Node) -> void:
		if node.has_method("update_text"):
				node.update_text()
		for child in node.get_children():
				_update_node_recursive(child)
