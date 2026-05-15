extends Node

# Сигналы для уведомления об изменении громкости
signal music_volume_changed(value: float)
signal sfx_volume_changed(value: float)

# Константы для ключей настроек
const MUSIC_VOLUME_KEY := "audio/music_volume"
const SFX_VOLUME_KEY := "audio/sfx_volume"

# Значения по умолчанию
const DEFAULT_MUSIC_VOLUME := 0.5  # Начальная громкость музыки потише (30%)
const DEFAULT_SFX_VOLUME := 0.5    # Громкость эффектов по умолчанию (50%)

# Флаг, чтобы применить настройки только один раз
var _settings_applied := false

# Переменные для хранения последней громкости перед выключением
var _last_music_volume := DEFAULT_MUSIC_VOLUME
var _last_sfx_volume := DEFAULT_SFX_VOLUME


func _ready() -> void:
		# Применяем сохранённые настройки при запуске
		_apply_saved_settings()


func _apply_saved_settings() -> void:
		if _settings_applied:
				return

		_settings_applied = true

		# Получаем сохранённые значения или используем значения по умолчанию
		var music_vol = ProjectSettings.get_setting(MUSIC_VOLUME_KEY, DEFAULT_MUSIC_VOLUME)
		var sfx_vol = ProjectSettings.get_setting(SFX_VOLUME_KEY, DEFAULT_SFX_VOLUME)

		# Применяем громкость музыки
		_set_music_volume_internal(music_vol)

		# Применяем громкость эффектов
		_set_sfx_volume_internal(sfx_vol)


func _set_music_volume_internal(value: float) -> void:
		var db: float
		if value == 0:
				db = -80.0
		else:
				db = linear_to_db(value)

		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("music"), db)


func _set_sfx_volume_internal(value: float) -> void:
		var db: float
		if value == 0:
				db = -80.0
		else:
				db = linear_to_db(value)

		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), db)


# Публичный метод для установки громкости музыки
func set_music_volume(value: float) -> void:
		value = clamp(value, 0.0, 1.0)
		
		# Если выключаем звук (value == 0), сохраняем текущую громкость
		if value == 0.0:
				_last_music_volume = get_music_volume()
		else:
				# Если включаем звук, используем сохраненное значение
				_last_music_volume = value
		
		_set_music_volume_internal(value)
		ProjectSettings.set_setting(MUSIC_VOLUME_KEY, value)
		music_volume_changed.emit(value)


# Публичный метод для установки громкости эффектов
func set_sfx_volume(value: float) -> void:
		value = clamp(value, 0.0, 1.0)
		
		# Если выключаем звук (value == 0), сохраняем текущую громкость
		if value == 0.0:
				_last_sfx_volume = get_sfx_volume()
		else:
				# Если включаем звук, используем сохраненное значение
				_last_sfx_volume = value
		
		_set_sfx_volume_internal(value)
		ProjectSettings.set_setting(SFX_VOLUME_KEY, value)
		sfx_volume_changed.emit(value)


# Получить текущую громкость музыки (0.0 - 1.0)
func get_music_volume() -> float:
		return ProjectSettings.get_setting(MUSIC_VOLUME_KEY, DEFAULT_MUSIC_VOLUME)


# Получить текущую громкость эффектов (0.0 - 1.0)
func get_sfx_volume() -> float:
		return ProjectSettings.get_setting(SFX_VOLUME_KEY, DEFAULT_SFX_VOLUME)


# Сохранить настройки в файл (для Godot 4 это происходит автоматически, но можно вызвать явно)
func save_settings() -> void:
		ProjectSettings.save()
