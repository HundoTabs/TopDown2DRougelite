extends Resource
class_name WeaponStats

enum WeaponType {MELEE = 0, RANGED = 1, MAGIC = 2}
enum WeaponSwingType {LIGHT = 0, HEAVY = 1}

@export_group("Weapon Stats")
@export var max_damage := 0
@export var max_cooldown := 0
@export var max_swing := 0

var is_equipped : bool : set = set_equipped

func set_equipped(value: bool) -> void:
	is_equipped = value
