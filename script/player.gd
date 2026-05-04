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

var is_attacking: bool = false
var enemies_in_area: Array = []
var last_footstep_time: float = 0.0
const FOOTSTEP_INTERVAL: float = 0.4

# Улучшение атаки SwordUP
var sword_up_unlocked: bool = false
var is_second_attack_active: bool = false
var second_attack_direction: float = 0.0
var original_facing_right: bool = true
var second_attack_timer: Timer = null
var is_swordup_playing: bool = false  # Флаг для отслеживания воспроизведения swordUP

# Система жизней
var max_lives: int = 3
var current_lives: int = 3
var is_invincible: bool = false
var blink_visible: bool = true
var hp_bar_node: Node = null

# Тип текущей атаки
var attack_type: String = "normal"
var splash_attack_timer: Timer

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
	
	second_attack_timer = Timer.new()
	second_attack_timer.one_shot = true
	second_attack_timer.timeout.connect(_on_second_attack_delay_timeout)
	add_child(second_attack_timer)

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
	if not is_attacking and not is_second_attack_active and attack_type == "normal":
		is_attacking = true
		is_second_attack_active = false
		original_facing_right = not animated_sprite.flip_h
		animated_sprite.play("attack")
		attack_area.monitoring = true
		
		# Если swordUP разблокирован, запускаем вторую атаку одновременно с основной
		if sword_up_unlocked:
			second_attack_direction = deg_to_rad(180) if original_facing_right else 0.0
			_on_second_attack_delay_timeout()

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
	enemies_in_area.clear()
	animated_sprite_swordup.visible = false
	
	if original_facing_right:
		attack_area.rotation = 0
		animated_sprite.flip_h = false
	else:
		attack_area.rotation = deg_to_rad(180)
		animated_sprite.flip_h = true

func _on_second_attack_delay_timeout() -> void:
	is_second_attack_active = true
	is_swordup_playing = true
	
	attack_area_up.rotation = second_attack_direction
	swordup_collision.disabled = true
	
	animated_sprite_swordup.visible = true
	animated_sprite_swordup.flip_h = not animated_sprite.flip_h
	animated_sprite_swordup.play("swordUP")

func _on_frame_changed() -> void:
	if animated_sprite.animation == "attack" and animated_sprite.frame == 3:
		sword_whoosh.pitch_scale = randf_range(0.9, 1.2)
		sword_whoosh.play()
		for enemy in enemies_in_area:
			if is_instance_valid(enemy):
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
	
	if velocity.length_squared() > 0:
		var is_sword_up_combo_active: bool = (sword_up_unlocked and (not second_attack_timer.is_stopped() or is_second_attack_active))
		
		if not is_sword_up_combo_active:
			if velocity.x > 0:
				# Игрок смотрит ВПРАВО
				animated_sprite.flip_h = false
				attack_area.rotation = 0
				animated_sprite_swordup.flip_h = false
				
				# ЛОГИКА ПОВОРОТА МЕЧА:
				# Если в редакторе стоит -100 (слева), то при взгляде вправо оставляем -100.
				# Мы берем абсолютное значение и ставим минус, чтобы было слева.
				if sword_pivot:
					sword_pivot.position.x = -abs(sword_pivot.position.x)
					
			elif velocity.x < 0:
				# Игрок смотрит ВЛЕВО
				animated_sprite.flip_h = true
				attack_area.rotation = deg_to_rad(180)
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
