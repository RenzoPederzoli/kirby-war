extends Sprite2D

@export var maintain_aspect_ratio := true
@export var fit_mode := "cover" # "cover", "contain", "stretch"

func _ready():
	# Wait one frame to ensure viewport is ready
	await get_tree().process_frame
	resize_to_viewport()
	
	# Connect to viewport size changes
	get_viewport().size_changed.connect(resize_to_viewport)

func resize_to_viewport():
	var viewport_size = get_viewport().get_visible_rect().size
	
	if not texture:
		return
	
	var texture_size = texture.get_size()
	
	match fit_mode:
		"cover":
			# Scale to cover entire viewport (may crop some content)
			var scale_by_width = viewport_size.x / texture_size.x
			var scale_by_height = viewport_size.y / texture_size.y
			scale = Vector2(max(scale_by_width, scale_by_height), max(scale_by_width, scale_by_height))
		
		"contain":
			# Scale to fit entirely within viewport (may have empty space)
			var scale_by_width = viewport_size.x / texture_size.x
			var scale_by_height = viewport_size.y / texture_size.y
			scale = Vector2(min(scale_by_width, scale_by_height), min(scale_by_width, scale_by_height))
		
		"stretch":
			# Stretch to exact viewport size (may distort image)
			scale = Vector2(viewport_size.x / texture_size.x, viewport_size.y / texture_size.y)
	
	# Center the sprite
	position = viewport_size / 2

