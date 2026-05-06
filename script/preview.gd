extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer(gnom)

var _is_preview_active: bool = false

func _ready() -> void:
	# Скрываем preview изначально
	visible = false
	# Останавливаем анимацию если она автозапускается
	animation_player.stop()
	# Устанавливаем процесс-режим для игнорирования паузы
	process_mode = Node.PROCESS_MODE_ALWAYS
	animation_player.process_mode = Node.PROCESS_MODE_ALWAYS

func play_preview() -> void:
	if _is_preview_active:
		return
	
	_is_preview_active = true
	visible = true
	
	# Сбрасываем анимацию к началу
	animation_player.play("RESET")
	await get_tree().process_frame
	
	# Запускаем анимацию Gnom
	animation_player.play("Gnom")
	
	# Ждем окончания анимации
	await animation_player.animation_finished
	
	# Скрываем preview после завершения
	visible = false
	_is_preview_active = false

func stop_preview() -> void:
	animation_player.stop()
	visible = false
	_is_preview_active = false
