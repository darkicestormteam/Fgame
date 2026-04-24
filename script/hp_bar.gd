extends CanvasLayer

@onready var hbox: HBoxContainer = $HBoxContainer
@onready var heart_scene: PackedScene = preload("res://scenes/heart.tscn")

var current_lives_displayed: int = 3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_hearts(3)

# Функция для обновления сердечек (вызывается извне)
func update_hearts(lives: int) -> void:
	# Очищаем все текущие сердечки
	for child in hbox.get_children():
		child.queue_free()
	
	# Добавляем новые сердечки по количеству жизней
	for i in range(lives):
		var heart = heart_scene.instantiate()
		hbox.add_child(heart)
	
	current_lives_displayed = lives
