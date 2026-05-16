extends CharacterBody2D

@export var speed: float = 50.0
@export var health: int = 1
@export var attack_distance: float = 50.0
@export var attack_collision_start_frame: int = 3
@export var attack_collision_end_frame: int = 6
@export var attack_cooldown: float = 1.0
# Галочка для включения взаимодействия со сценой tree
@export var can_interact_with_tree: bool = false

# Настройки телепортации
@export var teleport_distance: float = 2500.0
@export var camera_buffer: float = 200.0

# Настройки расстояния между врагами
@export var separation_distance: float = 30.0
@export var separation_strength: float = 50.0

# Настройки для babka (выстрел снарядом)
@export var boom_scene: PackedScene = null
@export var boom_spawn_offset: float = 95.0
@export var boom_shoot_frame: int = 5

# Настройки способности защиты
@export var has_defense_ability: bool = false
@export var defense_cooldown: float = 5.0
@export var defense_duration: float = 1.0  # Длительность анимации защиты (если нужно)

# Настройки способности рывка (Dash)
@export var enable_dash: bool = false
@export var dash_speed: float = 200.0
@export var dash_range: float = 150.0
@export var dash_duration: float = 0.3  # Длительность рывка в секундах
@export var dash_cooldown: float = 3.0

var _player: Node2D = null
var _grass_layer: TileMapLayer = null
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $Attack
@onready var attack_sound: AudioStreamPlayer2D = $Attackweapon
@onready var def_sound: AudioStreamPlayer2D = $Def
@onready var dash_sound: AudioStreamPlayer2D = $Dash
var is_knockedback: bool = false
var knockback_timer: float = 0.0
var is_attacking: bool = false
var attack_cooldown_timer: float = 0.0
var last_pitch: float = 1.0
var is_flashing: bool = false
var flash_timer: float = 0.0
var flash_duration: float = 0.5
var flash_interval: float = 0.1
var original_modulate: Color = Color.WHITE
var is_defending: bool = false
var defense_cooldown_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO
var original_collision_mask: int = 0

signal died

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
				# Сбрасываем таймер защиты при старте, чтобы защита была доступна с начала игры
				defense_cooldown_timer = 0.0
				
				# Сохраняем оригинальную маску коллизии для восстановления после рывка
				original_collision_mask = collision_mask

				# Проверяем наличие анимации def
				if has_defense_ability:
								var sprite_frames = animated_sprite.sprite_frames
								if sprite_frames and not sprite_frames.has_animation("def"):
												print("Предупреждение: У врага нет анимации 'def', но включена способность защиты!")
												has_defense_ability = false

func knockback(direction: Vector2, distance: float) -> void:
				velocity = direction * distance
				is_knockedback = true
				knockback_timer = 0.15

func take_damage(amount: int) -> void:
				# Если защита активна, блокируем урон
				if is_defending:
								return

				# Проверка способности защиты - не срабатывает во время атаки и если кулдаун еще не прошел
				if has_defense_ability and not is_defending and defense_cooldown_timer <= 0.0 and not is_attacking:
								is_defending = true
								# Сбрасываем анимацию и запускаем защиту
								animated_sprite.stop()
								animated_sprite.play("def")
								if def_sound:
												def_sound.pitch_scale = randf_range(0.9, 1.2)
												def_sound.play()
								# Возвращаемся, чтобы урон не был нанесен (защита активировалась успешно)
								return

				# Наносим урон только если защита не сработала
				health -= amount
				if not is_flashing:
								is_flashing = true
								flash_timer = flash_duration
				if health <= 0:
								remove_from_group("Enemy")
								emit_signal("died")
								queue_free()

func _physics_process(delta: float) -> void:
				# Обработка таймера перезарядки атаки
				if attack_cooldown_timer > 0.0:
							attack_cooldown_timer -= delta

				# Обработка таймера перезарядки защиты
				if defense_cooldown_timer > 0.0:
								defense_cooldown_timer -= delta

				# Обработка таймера перезарядки рывка
				if dash_cooldown_timer > 0.0:
								dash_cooldown_timer -= delta

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

				# Если враг защищается, он не двигается и не атакует
				if is_defending:
								velocity = Vector2.ZERO
								return

				# Логика рывка (Dash) - если уже идет рывок, обрабатываем его
				if is_dashing:
								dash_timer -= delta
								
								# Движение по сохранённому направлению
								velocity = dash_direction * dash_speed
								move_and_slide()
								
								# Проверка завершения рывка по таймеру
								if dash_timer <= 0.0:
												is_dashing = false
												# Восстанавливаем маску коллизии
												collision_mask = original_collision_mask
												# Выключаем хитбокс атаки после завершения рывка
												attack_area.monitoring = false
												# Устанавливаем кулдаун
												dash_cooldown_timer = dash_cooldown
												# Сбрасываем флаг атаки
												is_attacking = false
												# Возвращаемся к анимации idle
												animated_sprite.play("idle")
 								# Останавливаем звук рывка
								if dash_sound and dash_sound.playing:
										dash_sound.stop()
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
				var is_in_attack_range = distance_to_player_after <= attack_distance

				# Логика активации рывка (Dash)
				if enable_dash and not is_dashing and dash_cooldown_timer <= 0.0 and not is_attacking:
								# Проверяем, находится ли игрок в радиусе активации рывка и дальше чем обычная дистанция атаки
								if distance_to_player_after <= dash_range and distance_to_player_after > attack_distance:
												is_dashing = true
												dash_timer = dash_duration
												# Сохраняем направление к игроку в момент начала рывка
												dash_direction = (_player.global_position - global_position).normalized()
												# Поворачиваем врага по направлению рывка
												if dash_direction.x < 0:
																animated_sprite.flip_h = true
																attack_area.scale.x = -abs(attack_area.scale.x)
												else:
																animated_sprite.flip_h = false
																attack_area.scale.x = abs(attack_area.scale.x)
												# Отключаем коллизию со стенами (бит 4=8) и врагами (бит 3=4), оставляем только для игрока (бит 2=2)
												collision_mask = 2
												# Запускаем анимацию атаки сразу при начале рывка
												animated_sprite.play("attack")
												# Включаем хитбокс атаки сразу
												attack_area.monitoring = true
								# Запускаем звук рывка зацикленно
								if dash_sound:
										dash_sound.loop = true
										dash_sound.play()
						return

				# Логика поведения в зависимости от нахождения игрока в зоне атаки
				if is_in_attack_range:
								# Игрок в зоне атаки
								if attack_cooldown_timer <= 0.0 and not is_attacking:
												# Кулдаун прошел, начинаем атаку
												is_attacking = true
												# Поворачиваем врага к игроку перед атакой
												var direction_to_player = (_player.global_position - global_position).normalized()
												if direction_to_player.x < 0:
																animated_sprite.flip_h = true
																attack_area.scale.x = -abs(attack_area.scale.x)
												else:
																animated_sprite.flip_h = false
																attack_area.scale.x = abs(attack_area.scale.x)
												animated_sprite.play("attack")
												velocity = Vector2.ZERO
												return
								else:
												# Кулдаун еще идет или уже атакуем -> стоим на месте и ждем
												velocity = Vector2.ZERO
												if not is_attacking:
																if animated_sprite.animation != "idle":
																				animated_sprite.play("idle")
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
												attack_cooldown_timer = attack_cooldown

								# Выстрел снарядом на нужном кадре для babka
								if boom_scene != null and current_frame == boom_shoot_frame:
												_spawn_boom()
func _spawn_boom() -> void:
				if boom_scene == null or _player == null:
								return

				# Создаём снаряд
				var boom_instance = boom_scene.instantiate()
				get_tree().current_scene.add_child(boom_instance)

				# Определяем направление к игроку ОТ ПОЗИЦИИ СПАВНА, а не от врага
				# Это гарантирует, что снаряд полетит точно в игрока, даже если спавнится со смещением
				var spawn_position = global_position
				if animated_sprite.flip_h:
								spawn_position.x -= boom_spawn_offset
				else:
								spawn_position.x += boom_spawn_offset

				var direction = (_player.global_position - spawn_position).normalized()

				boom_instance.global_position = spawn_position
				boom_instance.set_direction(direction)

func _on_attack_body_entered(body: Node2D) -> void:
				if body.is_in_group("player"):
								body.take_damage()
				# Взаимодействие с деревом при атаке
				if can_interact_with_tree and body.is_in_group("Tree"):
								var tree = body.get_node_or_null(".") as Node
								if tree and tree.has_method("disable_tree"):
												tree.disable_tree()

func _on_animation_finished() -> void:
				if animated_sprite.animation == "attack":
								is_attacking = false
				elif animated_sprite.animation == "def":
								is_defending = false
								# Запускаем кулдаун только после завершения анимации защиты
								defense_cooldown_timer = defense_cooldown
								# Возвращаемся к анимации idle, но только если мы все еще существуем
								if is_instance_valid(animated_sprite) and animated_sprite.sprite_frames.has_animation("idle") and not is_attacking:
												animated_sprite.play("idle")

				# Очищаем соединение для атаки, чтобы не было конфликтов
				if animated_sprite.animation == "attack":
								attack_area.monitoring = false

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
