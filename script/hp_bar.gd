extends CanvasLayer

@onready var hbox: HBoxContainer = $HBoxContainer
@onready var heart_scene: PackedScene = preload("res://scenes/heart.tscn")

var max_hearts: int = 3
var heart_nodes: Array = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Подключаемся к сигналу GameManager для обновления жизней
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		game_manager.lives_changed.connect(_on_lives_changed)
	
	# Создаем максимальное количество сердечек при старте
	for i in range(max_hearts):
		var heart = heart_scene.instantiate()
		hbox.add_child(heart)
		heart_nodes.append(heart)
	
	# Обновляем видимость сердечек (берем из GameManager если есть)
	var lives = 3
	if game_manager and game_manager.has_method("add_life"):
		lives = game_manager.current_lives
	update_hearts(lives)

# Функция для обновления сердечек (вызывается извне или через сигнал)
func update_hearts(lives: int) -> void:
	# Показываем/скрываем сердечки в зависимости от количества жизней
	for i in range(heart_nodes.size()):
		if i < lives:
			heart_nodes[i].visible = true
		else:
			heart_nodes[i].visible = false

# Обработчик изменения жизней из GameManager
func _on_lives_changed(new_lives: int) -> void:
	update_hearts(new_lives)
