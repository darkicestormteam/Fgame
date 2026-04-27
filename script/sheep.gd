extends CharacterBody2D

const SPEED = 150.0
const EXPLOSION_RADIUS = 100.0

var _target_enemy: Node2D = null
var _player: Node2D = null

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var damage_zone: Area2D = $damage_zone

func _ready() -> void:
	add_to_group("sheep")
	_player = get_tree().get_first_node_in_group("player")
	damage_zone.body_entered.connect(_on_damage_zone_body_entered)
	# Запускаем анимацию ходьбы
	animated_sprite.play("walk")

func _physics_process(delta: float) -> void:
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
	
	# Ищем ближайшего врага
	_find_nearest_enemy()
	
	if _target_enemy and is_instance_valid(_target_enemy):
		var direction: Vector2 = (_target_enemy.global_position - global_position).normalized()
		velocity = direction * SPEED
		
		# Поворот спрайта
		if velocity.x > 0:
			animated_sprite.flip_h = false
		elif velocity.x < 0:
			animated_sprite.flip_h = true
	else:
		# Если нет врагов, бежим в случайном направлении или стоим
		velocity = Vector2.ZERO
	
	move_and_slide()

func _find_nearest_enemy() -> void:
	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.is_empty():
		_target_enemy = null
		return
	
	var nearest_distance = INF
	for enemy in enemies:
		if is_instance_valid(enemy):
			var distance = global_position.distance_to(enemy.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				_target_enemy = enemy

func _on_damage_zone_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemy"):
		_explode()

func _explode() -> void:
	# Воспроизводим анимацию взрыва
	animated_sprite.play("explosion")
	
	# Увеличиваем зону урона на время взрыва
	damage_zone.monitoring = true
	
	# Получаем всех врагов в радиусе взрыва
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if is_instance_valid(enemy):
			var distance = global_position.distance_to(enemy.global_position)
			if distance <= EXPLOSION_RADIUS:
				enemy.queue_free()
	
	# Ждем окончания анимации взрыва и удаляем овцу
	await animated_sprite.animation_finished
	queue_free()

func set_target(player_pos: Vector2) -> void:
	# Можно использовать для установки начальной позиции относительно игрока
	pass