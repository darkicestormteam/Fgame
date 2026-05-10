extends Node2D

@onready var spellmenu = $Spellmenu
@onready var timer = $SpellTimer
@onready var objects_layer: TileMapLayer = $TileMap/Objects
@onready var boundary_zone: Area2D = $BoundaryZone

var boundary_center: Vector2
var boundary_radius: float

func _ready() -> void:
	# Инициализируем таймер
	timer.wait_time = 3.0
	timer.one_shot = true
	timer.start()
	
	spellmenu.visible = false
	
	# Вызываем разсинхронизацию с задержкой, чтобы сцены успели создаться
	call_deferred("_desync_tile_animations", objects_layer)
	
	# Инициализируем параметры границы
	if boundary_zone and boundary_zone.get_node_or_null("woll"):
		var collision_shape = boundary_zone.get_node("woll") as CollisionShape2D
		if collision_shape and collision_shape.shape is CircleShape2D:
			boundary_center = collision_shape.global_position
			boundary_radius = collision_shape.shape.radius * collision_shape.global_scale.x
			print("Граница установлена: центр=", boundary_center, " радиус=", boundary_radius)

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

func _on_boundary_zone_body_exited(body: Node2D) -> void:
	# Проверяем, что это игрок
	if body.is_in_group("player") or body is CharacterBody2D:
		var player = body
		# Вычисляем направление от центра границы к игроку
		var direction_to_player = (player.global_position - boundary_center).normalized()
		# Возвращаем игрока обратно в круг, устанавливая позицию на границе
		player.global_position = boundary_center + direction_to_player * boundary_radius
		print("Игрок попытался выйти за границу и был возвращен")

func _process(_delta: float) -> void:
	# Дополнительная проверка позиции игрока каждый кадр для более плавного ограничения
	if boundary_radius > 0:
		var player = get_tree().get_first_node_in_group("player")
		if player and player is CharacterBody2D:
			var distance_from_center = player.global_position.distance_to(boundary_center)
			if distance_from_center > boundary_radius:
				var direction_to_player = (player.global_position - boundary_center).normalized()
				player.global_position = boundary_center + direction_to_player * boundary_radius
