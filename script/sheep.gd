extends CharacterBody2D

const SPEED = 150.0
const EXPLOSION_RADIUS = 100.0
const ENEMY_SEARCH_INTERVAL = 0.5 # Искать нового врага раз в 0.5 секунды

var _target_enemy: Node2D = null
var _player: Node2D = null
var _is_exploding: bool = false # Флаг: идет ли уже анимация взрыва
var _explode_triggered: bool = false # Флаг: был ли уже запущен процесс взрыва
var _search_timer: float = 0.0 # Таймер для поиска врагов

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var damage_zone: Area2D = $damage_zone
@onready var sheepsay_sound: AudioStreamPlayer2D = $Sheepsay
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
		add_to_group("sheep")
		_player = get_tree().get_first_node_in_group("player")
		damage_zone.body_entered.connect(_on_damage_zone_body_entered)
		# Запускаем анимацию ходьбы через AnimationPlayer
		animation_player.play("walk")

func _physics_process(delta: float) -> void:
		# Останавливаем движение только если идет сама анимация взрыва
		if _is_exploding:
				velocity = Vector2.ZERO
				move_and_slide()
				return

		if _player == null:
				_player = get_tree().get_first_node_in_group("player")

		# Кэшируем поиск цели: ищем нового врага только раз в ENEMY_SEARCH_INTERVAL секунд
		_search_timer += delta
		if _search_timer >= ENEMY_SEARCH_INTERVAL:
				_search_timer = 0.0
				_find_nearest_enemy()

		if _target_enemy and is_instance_valid(_target_enemy):
				var direction: Vector2 = (_target_enemy.global_position - global_position).normalized()
				velocity = direction * SPEED

				if velocity.x > 0:
						animated_sprite.flip_h = false
				elif velocity.x < 0:
						animated_sprite.flip_h = true
		else:
				# Если текущая цель невалидна, сбрасываем таймер для немедленного поиска
				_search_timer = ENEMY_SEARCH_INTERVAL
				_target_enemy = null
				velocity = Vector2.ZERO

		move_and_slide()

func _find_nearest_enemy() -> void:
		var enemies = get_tree().get_nodes_in_group("Enemy") # Исправлено: "Enemy" вместо "enemy"
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
		if body.is_in_group("Enemy") and not _explode_triggered:
				# Воспроизводим звук Sheepsay при соприкосновении с врагом
				sheepsay_sound.play()
				_explode_triggered = true
				_explode_with_delay()

func _deal_explosion_damage() -> void:
	# Наносим урон всем врагам в зоне урона
	var bodies = damage_zone.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("Enemy") and body.has_method("take_damage"):
			body.take_damage(1)

func _explode_with_delay() -> void:
		# Ждем 0.4 секунды, овца при этом продолжает двигаться в _physics_process
		await get_tree().create_timer(0.4).timeout

		# Только после задержки останавливаем и взрываем
		_is_exploding = true
		velocity = Vector2.ZERO

		# Запускаем анимацию взрыва через AnimationPlayer
		# Анимация сама управляет спрайтами, звуком взрыва и коллизией
		animation_player.play("explosion")

		# Ждем окончания анимации для удаления овцы
		await animation_player.animation_finished
		queue_free()

func set_target(player_pos: Vector2) -> void:
		pass
