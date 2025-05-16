extends Node2D

var projectile_speed: float = 500.0
var velocity : Vector2 = Vector2.ZERO
var target_position : Vector2 = Vector2.ZERO

@onready var sprite = $Sprite
@onready var trail = $Sprite/Particles
@onready var destroy = $Sprite/DestroyEffect
@onready var hitbox = $Sprite/HitboxArea/CollisionShape2D
@onready var area = $Sprite/HitboxArea
var collided = false

func _ready():
	rotate_sprite_in_direction()

func _process(delta):
	#NOTE: I'm not sure if I need this?
	global_position += velocity * delta

func rotate_sprite_in_direction():
	var mouse_position = get_global_mouse_position()
	var direction = mouse_position - global_position
	if direction.length() > 0:
		var angle = direction.angle() 
		sprite.rotation = angle + deg_to_rad(0)
		print("Rotating sprite. Angle: ", rad_to_deg(angle))

func _on_hitbox_area_body_entered(body):
	if not body.is_in_group("PlayerCollision"):
		collided = true
		area.set_deferred("monitoring", false)
		area.set_deferred("monitorable", false)
		destroy.emitting = true
		trail.emitting = false
		self.velocity = Vector2.ZERO
		sprite.texture = null
		print(area.monitorable)
		await get_tree().create_timer(2).timeout
		queue_free()
