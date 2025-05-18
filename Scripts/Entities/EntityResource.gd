extends EntityStats
class_name EntityResource

@export_subgroup("Entity Stats")
@export var health : int : set = set_health
@export var speed : float : set = set_speed
#TODO: Weapon

func set_health(value: int) -> void:
	health = clampi(value, 0, max_health)

func set_speed(value: float) -> void:
	self.speed = value

func create_instance() -> Resource:
	var instance : EntityResource = self.duplicate()
	instance.health = max_health
	instance.speed = max_speed
	#TODO: instance.weapon = weapon
	return instance
