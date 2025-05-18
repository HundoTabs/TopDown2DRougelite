extends CharacterBody2D
class_name PlayerCharacter

@export var Stats : EntityResource

@onready var sprite = $Sprite
@onready var weapon = $Weapon
@onready var magic_cooldown_timer = $MagicCooldown

@onready var projectile = preload("res://Scenes/PlayerProjectile.tscn")

@onready var smear_texture : Texture2D = preload("res://Resources/Sprites/Weapons/sword_swing.png")
@onready var sword : Texture2D = preload("res://Resources/Sprites/Weapons/sword.png")
@onready var sword_swing_scene = preload("res://Scenes/WeaponSwing.tscn")

@export var weapon_object : Resource = null
var weapon_damage : int = 0
var weapon_smear_offset : Vector2 = Vector2.ZERO
var weapon_swing_speed : float = 0

@export var move_speed : float = 200.0
@export var acceleration : float = 200.0
@export var deceleration : float = 200.0

@export var player_above_z_index = 2
@export var player_below_z_index = 1
@export var y_threshold = 200

@export var swing_duration : float = 10
@export var swing_angle_range : float = -140
var projectile_speed: float = 300.0
var swinging = false
var refreshed = true
var magic_cooldown = false

var collided_with_top = false
var collided_with_bottom = false

func _ready():
	Global.player = self
	weapon_damage = weapon_object.damage
	weapon_smear_offset = weapon_object.weapon_smear_offset
	weapon_swing_speed = weapon_object.swing_speed
	

func get_input_vector() -> Vector2:
	var input_vector = Vector2.ZERO
	
	input_vector.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	input_vector.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	
	if input_vector != Vector2.ZERO:
		input_vector = input_vector.normalized()
	
	return input_vector
	
func _physics_process(_delta: float) -> void:
	
	var input_dir = get_input_vector()
	
	
	
	if input_dir != Vector2.ZERO:
		velocity = velocity.move_toward(input_dir * move_speed, acceleration)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, deceleration)

	if velocity != Vector2.ZERO:
		if velocity.x < 0:
			sprite.flip_h = true
		elif velocity.x > 0:
			sprite.flip_h = false
		sprite.play("run")
	else:
		sprite.play("idle")

	var mouse_pos = get_global_mouse_position()
	var direction_to_mouse = (mouse_pos - global_position).normalized()

	if direction_to_mouse.x < 0:
		sprite.flip_h = true
	else:
		sprite.flip_h = false

	move_and_slide()
	
	if Input.is_action_just_pressed("Attack"):
		if not swinging:
			if refreshed:
				swing_weapon()
				refreshed = false
	
	if not swinging:
		refreshed = true
		update_weapon_rotation()
		
	if Input.is_action_just_pressed("Magic"):
		use_magic()

func update_weapon_rotation() -> void:
	var angle_threshold = deg_to_rad(-90)
	
	var mouse_pos = get_global_mouse_position()
	var direction_to_mouse = (mouse_pos - global_position).normalized()
	var angle_to_mouse = direction_to_mouse.angle()
	
	if sprite.flip_v:
		weapon.rotation = angle_to_mouse + deg_to_rad(140)
		if weapon.rotation > angle_threshold or weapon.rotation < -angle_threshold:
			weapon.flip_v = false
		else:
			weapon.flip_v = true 
	else:
		weapon.rotation = angle_to_mouse + deg_to_rad(-140)
		if weapon.rotation > angle_threshold or weapon.rotation < -angle_threshold:
			weapon.flip_v = false
		else:
			weapon.flip_v = true
		
		
func _on_top_wall_check_body_entered(body):
	if body.is_in_group("walls"):
		z_index = player_above_z_index
		collided_with_top = true


func _on_bottom_wall_check_body_entered(body):
	if body.is_in_group("walls"):
		z_index = player_below_z_index
		
func swing_weapon() -> void:
	swinging = true
	
	weapon.texture = smear_texture
	weapon.set_offset(Vector2(4.5, -20))
	
	var sword_swing_instance = sword_swing_scene.instantiate()
	
	sword_swing_instance.position = position
	
	var tween = create_tween()
	
	var mouse_pos = get_global_mouse_position()
	var direction_to_mouse = (mouse_pos - global_position).normalized()
	var angle_to_mouse = direction_to_mouse.angle()
	
	get_parent().add_child(sword_swing_instance)
	sword_swing_instance.velocity = direction_to_mouse * sword_swing_instance.swing_speed
	sword_swing_instance.player_position = global_position
	
	var distance = global_position.distance_to(sword_swing_instance.global_position)
	
	print("Sword Position: " + str(sword_swing_instance.global_position))
	print("Player Position: " + str(global_position))
	print("Distance Between: " + str(distance))
	
	var end_angle = angle_to_mouse + deg_to_rad(swing_angle_range * -1)
	
	tween.tween_property(weapon, "rotation", end_angle, swing_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	tween.connect("finished", Callable(self, "_swing_finished"))

func use_magic() -> void:
	if not magic_cooldown:
		var projectile_instance = projectile.instantiate()
		var sigil = preload("res://Scenes/PlayerSigil.tscn")
		var sigil_instance = sigil.instantiate()
		add_child(sigil_instance)
		
		var mouse_pos = get_global_mouse_position()
		var direction_to_mouse = (mouse_pos - global_position).normalized()

		
		projectile_instance.position = position
		projectile_instance.velocity = direction_to_mouse * projectile_instance.projectile_speed
	
		get_parent().add_child(projectile_instance)
		
		magic_cooldown = true
		magic_cooldown_timer.start()
	 

func _swing_finished():	
	weapon.set_offset(Vector2(4.5, -5))
	weapon.texture = sword
	
	var mouse_pos = get_global_mouse_position()
	var direction_to_mouse = (mouse_pos - global_position).normalized()
	
	var timer = Timer.new()
	timer.wait_time = weapon_swing_speed
	timer.one_shot = true
	
	timer.connect("timeout", Callable(self, "_on_cooldown_finished")) 
	add_child(timer)
	timer.start()
	
	
func _on_cooldown_finished():
	swinging = false

func _on_magic_cooldown_timeout():
	magic_cooldown = false
