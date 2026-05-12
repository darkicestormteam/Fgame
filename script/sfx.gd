extends HSlider


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Настройка ползунка: от 0 до 1, шаг 0.1, начальное значение 0.5
	min_value = 0.0
	max_value = 1.0
	step = 0.1
	value = 0.5
	
	# Применяем начальную громкость
	_update_sfx_volume()
	
	# Подключаем сигнал изменения значения
	value_changed.connect(_update_sfx_volume)


# Функция для обновления громкости SFX/VFX
func _update_sfx_volume(new_value: float = value) -> void:
	# Преобразуем значение 0-1 в dB (-40dB до 0dB)
	var db: float
	if new_value == 0:
		db = -80.0  # Полная тишина
	else:
		db = linear_to_db(new_value)
	
	# Устанавливаем громкость на шину "SFX"
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), db)
