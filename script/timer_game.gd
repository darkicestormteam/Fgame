extends CanvasLayer

@onready var timer_label = $TimerGame
@onready var timer = $Timer

var time_elapsed: float = 0.0

func _ready() -> void:
	# Запускаем таймер (1 секунда интервал)
	timer.wait_time = 1.0
	timer.autostart = true
	timer.timeout.connect(_on_timer_timeout)
	
	# Обновляем метку сразу
	update_label()

func _on_timer_timeout() -> void:
	time_elapsed += 1.0
	update_label()

func update_label() -> void:
	# Форматируем время в минуты:секунды
	var minutes = int(time_elapsed / 60)
	var seconds = int(time_elapsed) % 60
	timer_label.text = "Время жизни: %02d:%02d" % [minutes, seconds]
