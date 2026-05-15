extends CharacterBody2D

@export var speed: float = 50.0
@export var health: int = 1
@export var attack_distance: float = 50.0
@export var attack_collision_start_frame: int = 3
@export var attack_collision_end_frame: int = 6

# Настройки телепортации
@export var teleport_distance: float = 2500.0
@export var camera_buffer: float = 200.0

# Настройки расстояния между врагами
@export var separation_distance: float = 30.0
@export var separation_strength: float = 50.0

var _player: Node2D = null
var _grass_layer: TileMapLayer = null
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $Attack
@onready var attack_sound: AudioStreamPlayer2D = $Attackweapon
var is_knockedback: bool = false
var knockback_timer: float = 0.0
var is_attacking: bool = false
var last_pitch: float = 1.0
var is_flashing: bool = false
var flash_timer: float = 0.0
var flash_duration: float = 0.5
var flash_interval: float = 0.1
var original_modulate: Color = Color.WHITE

func _ready() -> void:
	add_to_group("Enemy")
	_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		print("Предупреждение: Игрок не найден в группе 'player'.")
	
	# Находим слой травы через получение сцены игры
	var game_scene = get_tree().current_scene
	if game_scene:
		var tilemap = game_scene.get_node_or_null("TileMap")
		if tilemap:
			_grass_layer = tilemap.get_node_or_null("Grass") as TileMapLayer
			if _grass_layer == null:
				print("Предупреждение: Слой 'Grass' не найден в TileMap.")
	
	animated_sprite.frame_changed.connect(_on_frame_changed)
	animated_sprite.animation_finished.connect(_on_animation_finished)
	attack_area.monitoring = false
	original_modulate = animated_sprite.modulate

func knockback(direction: Vector2, distance: float) -> void:
	velocity = direction * distance
	is_knockedback = true
	knockback_timer = 0.15

func take_damage(amount: int) -> void:
	health -= amount
	if not is_flashing:
		is_flashing = true
		flash_timer = flash_duration
	if health <= 0:
		queue_free()

func _physics_process(delta: float) -> void:
	# Обработка мигания при получении урона
	if is_flashing:
		flash_timer -= delta
		if flash_timer <= 0.0:
			is_flashing = false
			animated_sprite.modulate = original_modulate
		else:
			var flash_state = int(flash_timer / flash_interval) % 2
			if flash_state == 0:
				animated_sprite.modulate = Color.RED
			else:
				animated_sprite.modulate = original_modulate
	
	if is_knockedback:
		knockback_timer -= delta
		if knockback_timer <= 0.0:
			is_knockedback = false
		move_and_slide()
		return
	
	if _player == null:
		velocity = Vector2.ZERO
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")
		return
	
	# Проверка дистанции для телепортации
	var distance_to_player: float = global_position.distance_to(_player.global_position)
	if distance_to_player > teleport_distance:
		_teleport_to_player()
		return
	
	var distance_to_player_after: float = global_position.distance_to(_player.global_position)
	
	# Проверяем дистанцию до игрока
	if distance_to_player_after <= attack_distance:
		if not is_attacking:
			is_attacking = true
			animated_sprite.play("attack")
		velocity = Vector2.ZERO
		return
	
	# Логика движения
	if not is_attacking:
		var direction: Vector2 = (_player.global_position - global_position).normalized()
		
		# Запоминаем желаемое направление для анимации и логики
		var desired_velocity = direction * speed
		
		# Применяем силу разделения от других врагов
		var separation_force = _calculate_separation()
		desired_velocity += separation_force
		
		if desired_velocity.x > 0:
			animated_sprite.flip_h = false
			attack_area.scale.x = abs(attack_area.scale.x)
		elif desired_velocity.x < 0:
			animated_sprite.flip_h = true
			attack_area.scale.x = -abs(attack_area.scale.x)
		
		velocity = desired_velocity
		
		# Первый проход физики
		move_and_slide()
		
		# --- УЛУЧШЕННАЯ ЛОГИКА СКОЛЬЖЕНИЯ ---
		# Если произошло столкновение
		if get_slide_collision_count() > 0:
			var collision = get_slide_collision(0)
			var normal = collision.get_normal()
			
			# Получаем оставшуюся скорость после удара о стену (она обычно гасится движком)
			# Но мы хотим заставить врага скользить вдоль стены активно
			var tangent = -normal.orthogonal() # Вектор вдоль стены
			
			# Определяем, в какую сторону вдоль стены выгоднее идти (к игроку)
			var to_player = (_player.global_position - global_position).normalized()
			
			# Если касательная направлена от игрока, разворачиваем её
			if tangent.dot(to_player) < 0:
				tangent = -tangent
			
			# ХИТРОСТЬ: Мы смешиваем исходное желание идти к игроку и скольжение.
			# Это предотвращает "прилипание", так как мы не ждем полной остановки.
			# Проекция желаемой скорости на касательную
			var slide_speed = desired_velocity.dot(tangent)
			
			# Если проекция положительная (мы хотим двигаться вдоль стены к игроку)
			if slide_speed > 0:
				# Принудительно задаем скорость скольжения. 
				# Умножаем на 1.05, чтобы быть чуть быстрее обычного трения, пробивая застревание
				velocity = tangent * slide_speed * 1.05
				
				# Второй проход физики для применения нового вектора сразу же
				move_and_slide()

	# Анимация
	if not is_attacking:
		if velocity.length_squared() > 1.0:
			if animated_sprite.animation != "walk":
				animated_sprite.play("walk")
		else:
			if animated_sprite.animation != "idle":
				animated_sprite.play("idle")

func _on_frame_changed() -> void:
	if animated_sprite.animation == "attack":
		var current_frame = animated_sprite.frame
		if current_frame == attack_collision_start_frame:
			attack_area.monitoring = true
			if attack_sound and not attack_sound.playing:
				last_pitch = randf_range(0.9, 1.2)
				attack_sound.pitch_scale = last_pitch
				attack_sound.play()
		elif current_frame >= attack_collision_end_frame:
			attack_area.monitoring = false
			is_attacking = false

func _on_attack_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_damage()

func _on_animation_finished() -> void:
	if animated_sprite.animation == "attack":
		is_attacking = false

# Функция телепортации врага ближе к игроку
func _teleport_to_player() -> void:
	if _player == null or _grass_layer == null:
		return
	
	# Получаем камеру игрока
	var camera = _player.get_viewport().get_camera_2d()
	if camera == null:
		# Если камеры нет, используем позицию игрока
		_teleport_to_random_grass_position(_player.global_position, camera_buffer)
		return
	
	# Вычисляем целевую точку на расстоянии camera_buffer от края камеры
	var camera_position = camera.global_position
	var viewport_size = get_viewport().get_visible_rect().size
	var half_viewport = viewport_size / 2 * camera.zoom
	
	# Определяем направление от камеры к текущей позиции врага
	var direction_to_enemy = (global_position - camera_position).normalized()
	
	# Если направление нулевое, используем случайное
	if direction_to_enemy == Vector2.ZERO:
		direction_to_enemy = Vector2.RIGHT.rotated(randf() * TAU)
	
	# Целевая позиция на расстоянии buffer от края камеры в направлении врага
	var target_distance_from_camera = min(half_viewport.x, half_viewport.y) + camera_buffer
	var target_position = camera_position + direction_to_enemy * target_distance_from_camera
	
	# Телепортируем на ближайший тайл травы
	_teleport_to_random_grass_position(target_position, camera_buffer * 0.5)

# Поиск и телепортация на случайную позицию с травой рядом с целевой точкой
func _teleport_to_random_grass_position(target_pos: Vector2, search_radius: float) -> void:
	if _grass_layer == null:
		global_position = target_pos
		return
	
	# Получаем размер тайла
	var tile_size = _grass_layer.tile_set.tile_size
	var half_tile = tile_size / 2.0
	
	# Определяем область поиска в тайлах
	var start_tile = _grass_layer.local_to_map(target_pos - Vector2(search_radius, search_radius))
	var end_tile = _grass_layer.local_to_map(target_pos + Vector2(search_radius, search_radius))
	
	var valid_positions: Array[Vector2] = []
	
	# Перебираем все тайлы в области поиска
	for x in range(start_tile.x, end_tile.x + 1):
		for y in range(start_tile.y, end_tile.y + 1):
			# Проверяем, есть ли здесь тайл травы
			var tile_data = _grass_layer.get_cell_tile_data(Vector2i(x, y))
			if tile_data != null:
				# Конвертируем координаты тайла обратно в мировые
				var world_pos = _grass_layer.map_to_local(Vector2i(x, y)) + half_tile
				valid_positions.append(world_pos)
	
	# Если нашли подходящие позиции, выбираем случайную
	if valid_positions.size() > 0:
		var random_index = randi() % valid_positions.size()
		global_position = valid_positions[random_index]
	else:
		# Если не нашли траву, просто телепортируем в целевую точку
		global_position = target_pos

# Вычисляет силу отталкивания от других врагов
func _calculate_separation() -> Vector2:
	var separation_force = Vector2.ZERO
	var enemies = get_tree().get_nodes_in_group("Enemy")
	
	for enemy in enemies:
		if enemy == self:
			continue
		
		var distance = global_position.distance_to(enemy.global_position)
		
		# Если другой враг слишком близко
		if distance > 0 and distance < separation_distance:
			# Вектор отталкивания (от другого врага к нам)
			var push_direction = (global_position - enemy.global_position).normalized()
			
			# Сила отталкивания увеличивается, когда враги ближе друг к другу
			var push_strength = (separation_distance - distance) / separation_distance
			separation_force += push_direction * push_strength * separation_strength
	
	return separation_force
