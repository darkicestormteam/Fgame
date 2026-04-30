extends Control


var is_visible: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Скрываем меню при старте
	visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func show_spellmenu() -> void:
	# Показываем меню и ставим игру на паузу
	visible = true
	is_visible = true
	get_tree().paused = true
