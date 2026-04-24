extends CanvasLayer

@onready var hbox: HBoxContainer = $HBoxContainer
@onready var heart_scene: PackedScene = preload("res://scenes/heart.tscn")

var max_hearts: int = 3
var heart_nodes: Array = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Создаем максимальное количество сердечек при старте
	for i in range(max_hearts):
		var heart = heart_scene.instantiate()
		hbox.add_child(heart)
		heart_nodes.append(heart)
	
	# Обновляем видимость сердечек
	update_hearts(3)

# Функция для обновления сердечек (вызывается извне)
func update_hearts(lives: int) -> void:
	# Показываем/скрываем сердечки в зависимости от количества жизней
	for i in range(heart_nodes.size()):
		if i < lives:
			heart_nodes[i].visible = true
		else:
			heart_nodes[i].visible = false
