extends CanvasLayer

signal ability_selected(ability_id: int)
signal menu_blocked  # Новый сигнал для случая, когда меню не может открыться

# Настройки способностей
var abilities = {
	1: {
		"name": "Weapon firerate", 
		"description": "Increase firerate", 
		"weight": 10, 
		"max_uses": 0
		},
	2: {
		"name": "Move speed", 
		"description": "Increase move speed", 
		"weight": 10, 
		"max_uses": 0
		},
	3: {
		"name": "Addition orbital gun", 
		"description": "Add addition weapon", 
		"weight": 10, 
		"max_uses": 0
		},
	4: {
		"name": "Health bar attack", 
		"description": "Spine health bar for attack", 
		"weight": 10, 
		"max_uses": 0
		},
	5: {
		"name": "Survivibility", 
		"description": "Add Survivibility", 
		"weight": 10, 
		"max_uses": 0
		},
	6: {
		"name": "Tesla gun", 
		"description": "Add tesla gun", 
		"weight": 10, 
		"max_uses": 8
		},
	# ... остальные способности
}

var ability_usage = {}
var current_abilities = []

func _ready():
	hide()
	randomize()
	
	# Инициализация счетчиков
	for ability_id in abilities:
		ability_usage[ability_id] = 0
	
	# Настройка кнопок
	for i in range(3):
		var button = $Panel.get_child(i) as Button
		if button:
			button.pressed.connect(_on_ability_pressed.bind(i))
			button.focus_mode = Control.FOCUS_NONE

func _on_ability_pressed(button_index: int):
	if button_index < current_abilities.size():
		var ability_id = current_abilities[button_index]
		ability_usage[ability_id] += 1
		ability_selected.emit(ability_id)
		close_menu()

func _get_available_abilities() -> Array:
	var available = []
	for ability_id in abilities:
		var ability = abilities[ability_id]
		if ability["max_uses"] == -1 or ability_usage[ability_id] < ability["max_uses"]:
			available.append(ability_id)
	return available

func _get_random_abilities(count: int) -> Array:
	var available = _get_available_abilities()
	if available.size() <= count:
		return available.duplicate()
	
	var weighted_pool = []
	for id in available:
		for i in range(abilities[id]["weight"]):
			weighted_pool.append(id)
	
	var selected = []
	while selected.size() < count and weighted_pool.size() > 0:
		var index = randi() % weighted_pool.size()
		var chosen_id = weighted_pool[index]
		if not chosen_id in selected:
			selected.append(chosen_id)
		weighted_pool.remove_at(index)
	
	return selected

func open_menu():
	var available = _get_available_abilities()
	
	# Проверяем, есть ли доступные способности
	if available.size() == 0:
		emit_signal("menu_blocked")  # Оповещаем, что меню не может открыться
		return false  # Возвращаем false, если меню не открылось
	
	current_abilities = _get_random_abilities(min(3, available.size()))
	
	# Обновляем кнопки
	for i in range(3):
		var button = $Panel.get_child(i) as Button
		if button:
			if i < current_abilities.size():
				var ability_id = current_abilities[i]
				button.text = abilities[ability_id]["name"]
				button.disabled = false
			else:
				button.text = "N/A"
				button.disabled = true
	
	show()
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	return true  # Возвращаем true, если меню успешно открылось

func close_menu():
	hide()
	get_tree().paused = false
