extends Resource
class_name InGameWeapon

enum WeaponType {MELEE = 0, RANGED = 1, MAGIC = 2}
enum WeaponSwingType {LIGHT_SWORD = 0, HEAVY_SWORD = 1}

@export_group("Weapon Info")
@export var weapon_name : String = ""
@export var weapon_texture : Texture2D = null
@export var weapon_smear_texture : Texture2D = null
@export var weapon_type : WeaponType = WeaponType.MELEE
@export var weapon_smear_offset : Vector2 = Vector2.ZERO

@export_group("Weapon Stats")
@export var damage := 0
@export var swing_speed : float = 0
@export var swing_length := 0
@export var weapon_swing_type : WeaponSwingType = WeaponSwingType.LIGHT_SWORD
