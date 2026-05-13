class_name Localization
extends Node

var current_locale: String = "ru"  # Default to Russian
var translations: Dictionary = {}

func _ready() -> void:
	load_translations()

func load_translations() -> void:
	var file = FileAccess.open("res://Locales/locales.csv", FileAccess.READ)
	if not file:
		push_error("Failed to open Locales/locales.csv")
		return
	
	# Skip header line
	file.get_line()
	
	while not file.eof_reached():
		var line = file.get_line()
		if line.strip_edges().is_empty():
			continue
		
		var parts = parse_csv_line(line)
		if parts.size() >= 3:
			var key = parts[0].strip_edges()
			var en_value = parts[1].strip_edges()
			var ru_value = parts[2].strip_edges()
			
			translations[key] = {
				"en": unescape_string(en_value),
				"ru": unescape_string(ru_value)
			}
	
	file.close()

func parse_csv_line(line: String) -> Array:
	var result = []
	var current = ""
	var in_quotes = false
	
	for i in range(line.length()):
		var char = line[i]
		
		if char == '"':
			in_quotes = !in_quotes
		elif char == ',' and not in_quotes:
			result.append(current)
			current = ""
		else:
			current += char
	
	result.append(current)
	return result

func unescape_string(s: String) -> String:
	s = s.strip_edges()
	if s.begins_with('"') and s.ends_with('"'):
		s = s.substr(1, s.length() - 2)
	return s.replace('""', '"')

func get_text(key: String) -> String:
	if translations.has(key):
		if translations[key].has(current_locale):
			return translations[key][current_locale]
		elif translations[key].has("en"):
			return translations[key]["en"]
	return key

func set_locale(locale: String) -> void:
	current_locale = locale

func get_locale() -> String:
	return current_locale
