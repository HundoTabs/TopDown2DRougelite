extends GPUParticles2D


# Called when the node enters the scene tree for the first time.
func _ready():
	emitting = true # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	await get_tree().create_timer(1).timeout
	queue_free()
