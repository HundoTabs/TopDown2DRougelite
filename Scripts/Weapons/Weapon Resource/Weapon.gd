extends WeaponStats
class_name WeaponResource

@export_group("Weapon Info")
@export var weapon_name : String
@export var sprite : SpriteFrames
@export var weapon_type : WeaponType = WeaponType.MELEE
@export var weapon_swing : WeaponSwingType = WeaponSwingType.LIGHT
@export var weapon_smear_offset : Vector2 = Vector2.ZERO

var damage := 0
var cooldown := 0

func create_instance(name: String) -> Resource:
	var instance : WeaponResource = self.duplicate()
	instance.damage = max_damage
	instance.cooldown = max_cooldown
	return instance
