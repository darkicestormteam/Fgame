extends Node2D

@onready var spellmenu = $Spellmenu
@onready var timer = $SpellTimer

func _ready() -> void:
	# Инициализируем таймер на 3 секунды для теста
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.start()
	
	# Скрываем Spellmenu при старте
	spellmenu.visible = false

func _on_spell_timer_timeout() -> void:
	# Показываем меню улучшений
	spellmenu.show_spellmenu()
