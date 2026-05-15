extends Node2D

@onready var spellmenu = $Spellmenu
@onready var timer = $SpellTimer
@onready var objects_layer: TileMapLayer = $TileMap/Objects

func _ready() -> void:
	# Инициализируем таймер для spellmenu
	timer.wait_time = 10.0
	timer.one_shot = true
	timer.start()
	
	spellmenu.visible = false
	
	# Вызываем разсинхронизацию с задержкой, чтобы сцены успели создаться
	call_deferred("_desync_tile_animations", objects_layer)

func _desync_tile_animations(layer: TileMapLayer) -> void:
	if not layer:
		print("Слой Objects не найден!")
		return
	
	print("Начинаем разсинхронизацию анимации в слое: ", layer.name)
	var count = 0
	
	for child in layer.get_children():
		count += _find_and_desync_animated_sprites(child)
	
	if count == 0:
		print("Warning: Не найдено узлов AnimatedSprite2D в слое Objects.")
	else:
		print("Разсинхронизировано анимаций: ", count)

func _find_and_desync_animated_sprites(node: Node) -> int:
	var found_count = 0
	
	# Проверяем сам узел
	if node is AnimatedSprite2D:
		var anim_name = node.animation
		if anim_name and node.sprite_frames:
			if node.sprite_frames.has_animation(anim_name):
				var frame_count = node.sprite_frames.get_frame_count(anim_name)
				
				if frame_count > 1:
					# 1. Устанавливаем случайный начальный кадр (нормализованный 0.0 - 1.0)
					# randf() возвращает число от 0.0 до 1.0
					node.frame_progress = randf() * frame_count
					
					# 2. Устанавливаем случайную скорость анимации (от 0.8 до 1.2 от нормы)
					# Это критически важно, чтобы они со временем не синхронизировались снова
					node.speed_scale = 0.8 + randf() * 0.4
					
					found_count += 1
	
	# Рекурсивно проверяем всех детей
	for child in node.get_children():
		found_count += _find_and_desync_animated_sprites(child)
	
	return found_count

func _on_spell_timer_timeout() -> void:
	spellmenu.show_spellmenu()
