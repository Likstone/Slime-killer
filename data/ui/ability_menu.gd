extends CanvasLayer

signal ability_selected(ability_id: int)
signal menu_blocked  # Новый сигнал для случая, когда меню не может открыться

@onready var ability_b_1 = %Ability1
@onready var ability_b_2 = %Ability2
@onready var ability_b_3 = %Ability3

# Настройки способностей
var abilities = {
	1: {
		"name": "Weapon firerate", 
		"description": "Increase firerate", 
		"weight": 10, 
		"max_uses": 8
		},
	2: {
		"name": "Move speed", 
		"description": "Increase move speed", 
		"weight": 10, 
		"max_uses": 8
		},
	3: {
		"name": "Addition orbital gun", 
		"description": "Add addition weapon", 
		"weight": 8, 
		"max_uses": 8
		},
	4: {
		"name": "Health bar attack", 
		"description": "Spine health bar for attack", 
		"weight": 8, 
		"max_uses": 8
		},
	5: {
		"name": "Survivibility", 
		"description": "Add Survivibility", 
		"weight": 10, 
		"max_uses": 8
		},
	6: {
		"name": "Tesla gun", 
		"description": "Add tesla gun", 
		"weight": 8, 
		"max_uses": 8
		},
	7: {
		"name": "Magnit", 
		"description": "Add tesla gun", 
		"weight": 10, 
		"max_uses": 8
		},
}

var ability_usage = {}
var current_abilities = []

func _input(event):
	if event.is_action_pressed("ability_1"):
		ability_b_1.emit_signal("pressed")
	elif event.is_action_pressed("ability_2"):
		ability_b_2.emit_signal("pressed")
	elif event.is_action_pressed("ability_3"):
		ability_b_3.emit_signal("pressed")

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
	get_parent().pause_timer()
	process_mode = Node.PROCESS_MODE_ALWAYS
	return true  # Возвращаем true, если меню успешно открылось

func close_menu():
	hide()
	get_parent().unpause_timer()
	get_tree().paused = false
