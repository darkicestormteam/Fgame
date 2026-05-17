extends StaticBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var treedei: AudioStreamPlayer2D = $treedei

var is_disabled: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
		add_to_group("Tree")

# Вызывается при взаимодействии с врагом - отключает анимацию и коллизию, включает статичный спрайт
func disable_tree() -> void:
		if is_disabled:
				return
		is_disabled = true
		if treedei:
				treedei.play()
		if animated_sprite:
				animated_sprite.visible = false
		if collision_shape:
				collision_shape.set_deferred("disabled", true)
				# Дополнительно убираем форму для гарантии
				collision_shape.shape = null
		if sprite:
				sprite.visible = true
		# Также отключаем коллизии на самом StaticBody2D
		collision_layer = 0
		collision_mask = 0


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
		pass
