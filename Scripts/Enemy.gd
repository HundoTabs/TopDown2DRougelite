extends CharacterBody2D

enum State { IDLE, WANDER, DETECT, CHASE, HURT, DEAD }

@export var health = 12

@export var movement_speed = 75.0
@export var target : Node2D = null
@export var acceleration = 300.0
@export var deceleration = 200.0
var target_velocity = Vector2.ZERO
@export var target_tolerance = 1.0
@export var wander_radius = 50
@export var swing_duration : float = .1
@export var swing_angle_range : float = -140

@onready var sword = preload("res://Resources/Sprites/Weapons/baddie_sword.png")
@onready var smear_weapon = preload("res://Resources/Sprites/Weapons/bassie_sword_swing.png")
@onready var sword_swing_scene = preload("res://Scenes/EnemyWeaponSwing.tscn")

@onready var aggro_sound = preload("res://Resources/Sounds/aggro.mp3")
@onready var hit_sound = preload("res://Resources/Sounds/hit.mp3")

@onready var sprite = $Sprite
@onready var weapon = $Weapon
@onready var navigation_angent = $NavigationAgent
@onready var ray = $"Wall Detection/Ray"
@onready var safety_timer = $SafetyTimer
@onready var sound_player = $AggroSound

var knockback_velocity : Vector2 = Vector2.ZERO
var knockback_strength = 50
var friction = 1000

var wander_time = 2.0
var timer = 0.0
var state = State.IDLE
var spawn_protection = true
var player_detected = false
var is_avoiding = false
var swinging = false
var is_dead = true

func _ready():
	if not Global.player == null:
		target = Global.player
		print("Player has been registered")
		
	await get_tree().create_timer(1.5).timeout
	_handle_wander()

func _physics_process(delta):
	match state:
		State.WANDER:
			_process_wander(delta)
			update_sprite_animation()
		State.CHASE:
			_handle_agro(delta)
			update_sprite_aggro_animation()
		State.DETECT:
			velocity = Vector2.ZERO
			update_sprite_aggro_animation()
		State.HURT:
			move_and_slide()
			
func _process_wander(delta):
	timer -= delta
	if timer <= 0:
		if navigation_angent.is_navigation_finished():
			_handle_wander()
	
	if navigation_angent.avoidance_enabled:
		if not navigation_angent.is_navigation_finished():
			var next_path_position = navigation_angent.get_next_path_position()
			if global_position.distance_to(next_path_position) > target_tolerance:
				target_velocity = global_position.direction_to(next_path_position) * movement_speed
				
				velocity = velocity.move_toward(target_velocity, acceleration * delta)
		else:
			target_velocity = Vector2.ZERO
			velocity = velocity.move_toward(target_velocity, deceleration * delta)
	else:
		if not navigation_angent.is_navigation_finished():
			var next_path_position = navigation_angent.get_next_path_position()
			if global_position.distance_to(next_path_position) > target_tolerance:
				target_velocity = global_position.direction_to(next_path_position) * movement_speed
				
				velocity = velocity.move_toward(target_velocity, acceleration * delta)
		else:
			target_velocity = Vector2.ZERO
			velocity = velocity.move_toward(target_velocity, deceleration * delta)
	
	move_and_slide()

func _handle_agro(delta):
	if target:
		navigation_angent.target_position = target.global_position
	if navigation_angent.is_navigation_finished():
		return
	
	var current_agent_position = global_position
	var next_path_position = navigation_angent.get_next_path_position()

	print("state: " + str(state))
	
	if not navigation_angent.is_navigation_finished():
		if global_position.distance_to(next_path_position) > target_tolerance:
			target_velocity = global_position.direction_to(next_path_position) * movement_speed
				
			velocity = velocity.move_toward(target_velocity, acceleration * delta)
	else:
		target_velocity = Vector2.ZERO
		velocity = velocity.move_toward(target_velocity, deceleration * delta)
	
	if player_detected and not swinging:
		_handle_melee_attack()
	
	move_and_slide()

func enemy_setup():
	await get_tree().physics_frame
	if target:
		navigation_angent.target_position = target.global_position

func _handle_wander():
	var random_point = _get_random_walkable_point()
	navigation_angent.target_position = random_point
	
	if random_point != Vector2.ZERO:
		timer = wander_time
		state = State.WANDER
	else:
		timer = wander_time / 2
		navigation_angent.target_position = _get_random_walkable_point()
		
func _get_random_walkable_point() -> Vector2:
	var attempts = 10
	while attempts > 0:
		attempts -= 1
		
		var random_angle = randf() * TAU
		var random_distance = randf_range(0, wander_radius)
		
		var random_point = global_position + Vector2(cos(random_angle), sin(random_angle)) * random_distance
		
		if navigation_angent.is_target_reachable():
			return random_point
		else: 
			return global_position + Vector2(cos(random_angle), sin(random_angle)) * random_distance
			
	return Vector2.ZERO
		
		
func update_sprite_animation():
	if velocity != Vector2.ZERO:
		if velocity.x < 0:
			sprite.flip_h = true
			weapon.flip_v = true
			weapon.rotation_degrees = -50
		elif velocity.x > 0:
			sprite.flip_h = false
			weapon.flip_v = false
			weapon.rotation_degrees = -140
		sprite.play("run")
	else:
		sprite.play("idle")
		
func _on_wall_detection_body_entered(body):
	if body.is_in_group("walls"):
		enemy_setup()

func _on_player_area_body_entered(body):
	if safety_timer.is_stopped():
		spawn_protection = false
		
	if body.is_in_group("PlayerCollision") and not player_detected and not spawn_protection and state != State.DEAD:
		$AggroMark.play("aggro")
		sound_player.stream = aggro_sound
		sound_player.play()
		player_detected = true
		velocity = Vector2.ZERO
		state = State.DETECT
		
		await get_tree().create_timer(1).timeout
		if health <= 0 or state == State.DEAD:
			pass
		else:
			state = State.CHASE
		
func update_sprite_aggro_animation():
	var distance = (Global.player.global_position - global_position).normalized() 
	var angle_of_player = distance.angle()
	
	if angle_of_player > PI / 2 or angle_of_player < -PI / 2:
		sprite.flip_h = true
		update_weapon_rotation()
		if velocity != Vector2.ZERO:
			sprite.play("run")
		else:
			sprite.play("idle")
	else: 
		update_weapon_rotation()
		sprite.flip_h = false
		if velocity != Vector2.ZERO:
			sprite.play("run")
		else:
			sprite.play("idle")
			
func update_weapon_rotation() -> void:
	var angle_threshold = deg_to_rad(-90)
	
	var player_position = Global.player.global_position
	var distance_to_player = (player_position - global_position).normalized()
	var angle_to_player = distance_to_player.angle()
	
	if sprite.flip_v:
		weapon.rotation = angle_to_player + deg_to_rad(140)
		if weapon.rotation > angle_threshold or weapon.rotation < -angle_threshold:
			weapon.flip_v = false
		else:
			weapon.flip_v = true 
	else:
		weapon.rotation = angle_to_player + deg_to_rad(-140)
		if weapon.rotation > angle_threshold or weapon.rotation < -angle_threshold:
			weapon.flip_v = false
		else:
			weapon.flip_v = true
			
func _handle_melee_attack():
	var player_position = Global.player.global_position
	var distance_to_player = global_position.distance_to(player_position)
	
	print("distance: " + str(distance_to_player))
	
	var attack_range = 40.0
	
	if distance_to_player <= attack_range and state != State.DEAD:
		swinging = true
		await get_tree().create_timer(3).timeout
		if state == State.DEAD:
			print("WHY ARE YOU DEAD?")
		else:
			swing_weapon()
	else:
		print("out of range")

func swing_weapon() -> void:
	
	weapon.texture = smear_weapon
	weapon.set_offset(Vector2(4.5, -20))
	
	var sword_swing_instance = sword_swing_scene.instantiate()
	
	sword_swing_instance.position = position
	
	var tween = create_tween()
	
	var player_position = Global.player.global_position
	var distance_to_player = (player_position - global_position).normalized()
	var angle_to_player = distance_to_player.angle()
	
	get_parent().add_child(sword_swing_instance)
	sword_swing_instance.velocity = distance_to_player * sword_swing_instance.swing_speed
	sword_swing_instance.player_position = global_position
	
	var distance = global_position.distance_to(sword_swing_instance.global_position)
	
	var end_angle = angle_to_player + deg_to_rad(swing_angle_range * -1)
	
	tween.tween_property(weapon, "rotation", end_angle, swing_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	
	tween.connect("finished", Callable(self, "_swing_finished"))
	
func _swing_finished():
	weapon.set_offset(Vector2(4.5, -5))
	weapon.texture = sword
	
	var mouse_pos = get_global_mouse_position()
	var direction_to_mouse = (mouse_pos - global_position).normalized()
	
	var timer = Timer.new()
	timer.wait_time = 3
	timer.one_shot = true
	
	timer.connect("timeout", Callable(self, "_on_cooldown_finished")) 
	add_child(timer)
	timer.start()
	
func _on_cooldown_finished():
	swinging = false


func _on_navigation_agent_velocity_computed(safe_velocity):
	if safe_velocity != Vector2.ZERO:
		velocity = velocity.move_toward(safe_velocity.normalized() * movement_speed, acceleration * get_process_delta_time())
	else:
		velocity = velocity.move_toward(Vector2.ZERO, deceleration * get_process_delta_time())
	

func _on_enemy_hitbox_area_entered(area):
	if area.is_in_group("PlayerLightAttack") or area.is_in_group("PlayerProjectileCollision"):
		sprite.play("hurt")
		player_detected = true
		state = State.HURT
		sound_player.stream = hit_sound
		sound_player.play()
		health -= 4
		var hit_direction = (global_position - area.global_position).normalized()
		apply_knockback(hit_direction)
		_handle_death()
		if state == State.DEAD and health <= 0:
			pass
		else:
			#HACK: Maybe get rid of this to stop enemy I-frames?
			await get_tree().create_timer(.5).timeout
			state = State.CHASE
			_handle_death()

func apply_knockback(hit_direction):
	var knockback_duration = 0.3
	var knockback_timer = 0.0
	
	while knockback_timer < knockback_duration:
		knockback_velocity = hit_direction * knockback_strength
		
		velocity = knockback_velocity
		move_and_slide()
		
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, friction * get_process_delta_time())
		
		knockback_timer += get_physics_process_delta_time()
		
		await get_tree().process_frame
		
func _handle_death():
	if health <= 0:
		health = 0
		state = State.DEAD
		sprite.play("death")
		$Hitbox.disabled = true
		set_collision_layer_value(1, false)

func _on_enemy_died():
	if health <= 0:
		is_dead = true

func die():
	emit_signal("enemy_died")
	if health <= 0:
		state = State.DEAD
