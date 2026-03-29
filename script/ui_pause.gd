extends CanvasLayer

@onready var pause_panel: Panel = $PausePanel
@onready var restart_button: Button = $PausePanel/VBoxContainer/RestartButton

func _ready() -> void:
	# Скрываем панель при старте
	pause_panel.visible = false

func _process(_delta: float) -> void:
	# Проверяем состояние паузы и показываем/скрываем панель
	if get_tree().paused:
		pause_panel.visible = true
	else:
		pause_panel.visible = false

func _on_restart_button_pressed() -> void:
	# Снимаем с паузы
	get_tree().paused = false
	# Перезагружаем текущую сцену
	get_tree().reload_current_scene()
