extends CanvasLayer

@onready var timer_label: Label = $MarginContainer/TimerLabel
@onready var game_timer: Timer = $GameTimerNode

var total_time: float = 0.0

func _ready() -> void:
	game_timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout() -> void:
	total_time += 1.0
	update_label()

func update_label() -> void:
	var minutes: int = int(total_time) / 60
	var seconds: int = int(total_time) % 60
	timer_label.text = "%02d:%02d" % [minutes, seconds]
