extends CharacterBody2D

const SPEED = 50.0

var _player: Node2D = null
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("enemy")
	_player = get_tree().get_first_node_in_group("player")
	if _player == null:
		print("Предупреждение: Игрок не найден в группе 'player'.")

func _physics_process(delta: float) -> void:
	if _player == null:
		velocity = Vector2.ZERO
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")
		return

	var direction: Vector2 = (_player.global_position - global_position).normalized()
	
	velocity = direction * SPEED
	
	if velocity.x > 0:
		animated_sprite.flip_h = false
	elif velocity.x < 0:
		animated_sprite.flip_h = true

	move_and_slide()

	if velocity.length_squared() > 1.0:
		if animated_sprite.animation != "walk":
			animated_sprite.play("walk")
	else:
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")
