extends Node2D

var swing_speed = 35
var velocity : Vector2 = Vector2.ZERO
var player_position : Vector2 = Vector2.ZERO

@onready var animated_sprite = $SwingSprite
@onready var area_box = $SwingSprite/Area
@onready var hurtbox = $SwingSprite/Area/Hurtbox
	
func _ready():
	print("initial velocity: " + str(velocity))
	rotate_sprite_in_direction()

func _process(delta):
	global_position += velocity * delta
	
	if global_position.distance_to(player_position) > 200:
		queue_free()
	
	if animated_sprite.frame > 2:
		hurtbox.disabled = true
	
	animated_sprite.play("swing")
	
func rotate_sprite_in_direction():
	var mouse_position = get_global_mouse_position()
	var direction = mouse_position - global_position
	if direction.length() > 0:
		var angle = direction.angle() 
		animated_sprite.rotation = angle + deg_to_rad(0)
		print("Rotating sprite. Angle: ", rad_to_deg(angle))
	
func _on_swing_sprite_animation_finished():
	queue_free()
	print("all done!")
