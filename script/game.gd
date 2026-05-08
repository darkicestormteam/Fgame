extends Node2D

@onready var spellmenu = $Spellmenu
@onready var timer = $SpellTimer
@onready var objects_layer: TileMapLayer = $TileMap/Objects

func _ready() -> void:
	# Инициализируем таймер на 3 секунды для теста
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.start()
	
	# Скрываем Spellmenu при старте
	spellmenu.visible = false
	
	# Разсинхронизируем анимацию деревьев в слое Objects
	_desync_tile_animations(objects_layer)

func _desync_tile_animations(layer: TileMapLayer) -> void:
	if not layer:
		return
	
	var used_cells = layer.get_used_cells()
	for cell in used_cells:
		# Получаем текущий источник анимации для клетки
		var source_id = layer.get_cell_source_id(cell)
		if source_id != -1:
			# Устанавливаем случайное смещение кадра анимации
			# Это заставит каждую плитку начинаться с разной фазы анимации
			layer.set_cell_animation_frame_offset(cell, randi() % 100)

func _on_spell_timer_timeout() -> void:
	# Показываем меню улучшений
	spellmenu.show_spellmenu()
