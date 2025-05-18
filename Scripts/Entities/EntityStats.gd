extends Resource
class_name EntityStats

signal stats_chagned

@export_subgroup("Entity")
@export var name : String : set = set_character_name
@export var max_health : int
@export var max_speed : float
@export var sprite_frames : SpriteFrames : get = get_sprite

func set_character_name(string: String) -> void:
	name = string

func take_damage(damage: int) -> void:
	if damage <= 0:
		return
	var initial_damage = damage
	self.health -= damage
	
func get_sprite() -> SpriteFrames:
	return sprite_frames
