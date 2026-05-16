extends CharacterBody2D

@export var speed: float = 150.0
@export var spawn_offset: float = 95.0
@export var max_distance: float = 300.0
@export var damage_zone_start_frame: int = 2
@export var damage_zone_end_frame: int = 6
@export var damage: int = 1

var _direction: Vector2 = Vector2.ZERO
var _travelled_distance: float = 0.0
var _is_exploding: bool = false
var _start_position: Vector2 = Vector2.ZERO

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var damage_zone: Area2D = $damage_zone
@onready var explosion_sound: AudioStreamPlayer2D = $explosion

func _ready() -> void:
	damage_zone.monitoring = false
	animated_sprite.play("walk")
	_start_position = global_position

func _physics_process(delta: float) -> void:
	if _is_exploding:
		return
	
	# Движение по прямой
	velocity = _direction * speed
	move_and_slide()
	
	# Проверка коллизий с игроком после движения
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider.is_in_group("player") and not _is_exploding:
			_explode()
			return
	
	# Подсчёт пройденной дистанции
	_travelled_distance += velocity.length() * delta
	
	# Проверка на достижение максимальной дистанции
	if _travelled_distance >= max_distance:
		_explode()

func _on_frame_changed() -> void:
	if _is_exploding and animated_sprite.animation == "explosion":
		var current_frame = animated_sprite.frame
		if current_frame >= damage_zone_start_frame and current_frame < damage_zone_end_frame:
			damage_zone.monitoring = true
		else:
			damage_zone.monitoring = false
		
		# Удаляем снаряд после окончания анимации взрыва
		if current_frame >= animated_sprite.sprite_frames.get_frame_count("explosion") - 1:
			queue_free()

func _explode() -> void:
	if _is_exploding:
		return
	
	_is_exploding = true
	velocity = Vector2.ZERO
	animated_sprite.play("explosion")
	explosion_sound.play()

func set_direction(direction: Vector2) -> void:
	_direction = direction.normalized()
	# Поворачиваем спрайт в направлении полёта
	if _direction.x < 0:
		animated_sprite.flip_h = true
	else:
		animated_sprite.flip_h = false

func get_start_position() -> Vector2:
	return _start_position

func _on_damage_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not _is_exploding:
		body.take_damage()
		_explode()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not _is_exploding:
		_explode()
