extends CharacterBody2D

const SPEED = 300.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sword_pivot: Node2D = $SwordPivot  # Ссылка на пивот
@onready var animated_sprite_swordup: AnimatedSprite2D = $SwordPivot/AnimatedSprite2DSwordUP
@onready var attack_area: Area2D = $AttackArea
@onready var splash_collision: CollisionPolygon2D = $AttackArea/Splash
@onready var attack_area_up: Area2D = $SwordPivot/AttackAreaUP
@onready var swordup_collision: CollisionPolygon2D = $SwordPivot/AttackAreaUP/SwordUP
var attack_timer: Timer
@onready var sword_whoosh: AudioStreamPlayer2D = $"Sword Whoosh"
@onready var footstep: AudioStreamPlayer2D = $Footstep
@onready var invincibility_timer: Timer = $InvincibilityTimer
@onready var boundary_zone: Area2D = null  # Ссылка на зону границы (будет найдена в _ready)

var is_attacking: bool = false
var enemies_in_area: Array = []
var last_footstep_time: float = 0.0
const FOOTSTEP_INTERVAL: float = 0.4

# Улучшение атаки SwordUP
var sword_up_unlocked: bool = false
var is_second_attack_active: bool = false
var original_facing_right: bool = true
var is_swordup_playing: bool = false  # Флаг для отслеживания воспроизведения swordUP

# Тип текущей атаки
var attack_type: String = "normal"
var splash_attack_timer: Timer

# Параметры границы
var boundary_center: Vector2
var boundary_radius: float

func _ready() -> void:
	add_to_group("player")
	
	attack_timer = Timer.new()
	attack_timer.wait_time = 2.0
	attack_timer.autostart = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	add_child(attack_timer)
	
	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.frame_changed.connect(_on_frame_changed)
	animated_sprite_swordup.animation_finished.connect(_on_swordup_animation_finished)
	animated_sprite_swordup.frame_changed.connect(_on_swordup_frame_changed)
	
	attack_area.monitoring = false
	splash_collision.disabled = true
	swordup_collision.disabled = true
	
	set_process(true)
	
	await get_tree().process_frame
	hp_bar_node = get_tree().get_first_node_in_group("hp_bar")
	
	# Инициализация параметров границы
	boundary_zone = get_tree().get_first_node_in_group("boundary_zone")
	if boundary_zone and boundary_zone.get_node_or_null("woll"):
		var collision_shape = boundary_zone.get_node("woll") as CollisionShape2D
		if collision_shape and collision_shape.shape is CircleShape2D:
			boundary_center = collision_shape.global_position
			boundary_radius = collision_shape.shape.radius * collision_shape.global_scale.x
			print("Граница установлена в player.gd: центр=", boundary_center, " радиус=", boundary_radius)

func _process(_delta: float) -> void:
	if is_invincible:
		var current_time = Time.get_ticks_msec() / 1000.0
		if fmod(current_time, 0.2) < 0.1:
			animated_sprite.visible = true
			animated_sprite_swordup.visible = animated_sprite_swordup.visible and true
		else:
			animated_sprite.visible = false
			animated_sprite_swordup.visible = false
	else:
		animated_sprite.visible = true

func _on_invincibility_timer_timeout() -> void:
	is_invincible = false
	animated_sprite.visible = true
	collision_layer = 2

func take_damage() -> void:
	if is_invincible:
		return
	
	current_lives -= 1
	
	if hp_bar_node and hp_bar_node.has_method("update_hearts"):
		hp_bar_node.update_hearts(current_lives)
	
	if current_lives <= 0:
		get_tree().paused = true
		var game_over = get_tree().get_first_node_in_group("game_over")
		if not game_over:
			game_over = get_node("/root/GameOver")
		if not game_over:
			game_over = get_tree().current_scene.get_node_or_null("GameOver")
		
		if game_over:
			game_over.visible = true
	else:
		is_invincible = true
		invincibility_timer.start()
		collision_layer = 0

func add_life(amount: int = 1) -> void:
	max_lives += amount
	current_lives = min(current_lives + amount, max_lives)

func unlock_sword_up() -> void:
	sword_up_unlocked = true

func enable_splash_attack() -> void:
	attack_type = "splash"
	attack_timer.stop()
	
	if splash_attack_timer:
		splash_attack_timer.stop()
		splash_attack_timer.queue_free()
	
	splash_collision.disabled = false
	
	splash_attack_timer = Timer.new()
	splash_attack_timer.wait_time = 2.0
	splash_attack_timer.autostart = true
	splash_attack_timer.timeout.connect(_on_splash_attack_timer_timeout)
	add_child(splash_attack_timer)

func _on_splash_attack_timer_timeout() -> void:
	if not is_attacking:
		is_attacking = true
		animated_sprite.play("splash")
		attack_area.monitoring = true

func _on_attack_timer_timeout() -> void:
	if not is_attacking and attack_type == "normal":
		is_attacking = true
		original_facing_right = not animated_sprite.flip_h
		animated_sprite.play("attack")
		attack_area.monitoring = true
		
		# Если swordUP разблокирован, запускаем вторую атаку одновременно с основной
		if sword_up_unlocked:
			_start_second_attack()

func _start_second_attack() -> void:
	is_second_attack_active = true
	is_swordup_playing = true
	
	attack_area_up.scale.x = -1 if original_facing_right else 1
	swordup_collision.disabled = true
	
	animated_sprite_swordup.visible = true
	animated_sprite_swordup.flip_h = not animated_sprite.flip_h
	animated_sprite_swordup.play("swordUP")

func _on_animation_finished() -> void:
	if animated_sprite.animation == "attack":
		# Если swordup ещё играет, не завершаем атаку полностью
		if is_swordup_playing:
			return
		# Завершаем атаку (основную или комбо)
		is_attacking = false
		attack_area.monitoring = false
		enemies_in_area.clear()
		return
	
	if animated_sprite.animation == "splash":
		is_attacking = false
		attack_area.monitoring = false
		enemies_in_area.clear()

func _on_swordup_animation_finished() -> void:
	is_second_attack_active = false
	is_swordup_playing = false
	swordup_collision.disabled = true
	animated_sprite_swordup.visible = false
	
	# Если основная атака уже закончилась, завершаем всю комбо-атаку
	if not animated_sprite.is_playing():
		is_attacking = false
		attack_area.monitoring = false
		enemies_in_area.clear()
	
	if original_facing_right:
		attack_area.scale.x = 1
		animated_sprite.flip_h = false
	else:
		attack_area.scale.x = -1
		animated_sprite.flip_h = true

func _on_frame_changed() -> void:
	if animated_sprite.animation == "attack" and animated_sprite.frame == 3:
		sword_whoosh.pitch_scale = randf_range(0.9, 1.2)
		sword_whoosh.play()
		for enemy in enemies_in_area:
			if is_instance_valid(enemy):
				if enemy.has_method("take_damage"):
					enemy.take_damage(1)
				else:
					enemy.queue_free()
		enemies_in_area.clear()
	elif animated_sprite.animation == "splash" and animated_sprite.frame == 3:
		sword_whoosh.pitch_scale = randf_range(0.9, 1.2)
		sword_whoosh.play()
		for enemy in enemies_in_area:
			if is_instance_valid(enemy) and enemy.has_method("knockback"):
				var knockback_direction = (enemy.global_position - global_position).normalized()
				# ИЗМЕНИТЬ ДАЛЬНОСТЬ ОТТАЛКИВАНИЯ ЗДЕСЬ (вместо 300 поставьте свое число)
				enemy.knockback(knockback_direction, 300)
		enemies_in_area.clear()

func _on_swordup_frame_changed() -> void:
	if animated_sprite_swordup.animation == "swordUP" and animated_sprite_swordup.frame == 2:
		swordup_collision.disabled = false
		attack_area_up.monitoring = true
	elif animated_sprite_swordup.animation == "swordUP" and animated_sprite_swordup.frame == 3:
		sword_whoosh.pitch_scale = randf_range(0.9, 1.2)
		sword_whoosh.play()
		for enemy in enemies_in_area:
			if is_instance_valid(enemy):
				enemy.queue_free()
		enemies_in_area.clear()

func _physics_process(_delta: float) -> void:
	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	velocity = input_direction * SPEED
	
	# Проверка и ограничение выхода за границу круга
	if boundary_radius > 0:
		var distance_from_center = global_position.distance_to(boundary_center)
		if distance_from_center > boundary_radius:
			# Вычисляем направление от центра к игроку
			var direction_to_player = (global_position - boundary_center).normalized()
			# Устанавливаем позицию игрока точно на границе круга
			global_position = boundary_center + direction_to_player * boundary_radius
	
	if velocity.length_squared() > 0:
		var is_sword_up_combo_active: bool = (sword_up_unlocked and is_second_attack_active)
		
		if not is_sword_up_combo_active:
			if velocity.x > 0:
				# Игрок смотрит ВПРАВО
				animated_sprite.flip_h = false
				attack_area.scale.x = 1
				animated_sprite_swordup.flip_h = false
				
				# ЛОГИКА ПОВОРОТА МЕЧА:
				# Если в редакторе стоит -100 (слева), то при взгляде вправо оставляем -100.
				# Мы берем абсолютное значение и ставим минус, чтобы было слева.
				if sword_pivot:
					sword_pivot.position.x = -abs(sword_pivot.position.x)
					
			elif velocity.x < 0:
				# Игрок смотрит ВЛЕВО
				animated_sprite.flip_h = true
				attack_area.scale.x = -1
				animated_sprite_swordup.flip_h = true
				
				# ЛОГИКА ПОВОРОТА МЕЧА:
				# При взгляде влево меч должен быть справа (спина).
				# Делаем значение положительным.
				if sword_pivot:
					sword_pivot.position.x = abs(sword_pivot.position.x)
		
		if not is_attacking and animated_sprite.animation != "walk":
			animated_sprite.play("walk")
		
		if not is_attacking and Time.get_ticks_msec() / 1000.0 - last_footstep_time >= FOOTSTEP_INTERVAL:
			last_footstep_time = Time.get_ticks_msec() / 1000.0
			footstep.pitch_scale = randf_range(0.8, 1.2)
			footstep.play()
	else:
		if not is_attacking and animated_sprite.animation != "idle":
			animated_sprite.play("idle")
	
	move_and_slide()

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy"):
		if body not in enemies_in_area:
			enemies_in_area.append(body)

func _on_attack_area_up_body_entered(body: Node2D) -> void:
	if body.is_in_group("Enemy"):
		if body not in enemies_in_area:
			enemies_in_area.append(body)

func _on_attack_area_body_exited(body: Node2D) -> void:
	if body in enemies_in_area:
		enemies_in_area.erase(body)
