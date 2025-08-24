extends StaticBody2D

enum BoundaryType { FLOOR, LEFT_WALL, RIGHT_WALL }

@export var expand_to_viewport = true
@export var boundary_type: BoundaryType = BoundaryType.FLOOR
@export var boundary_thickness = 32.0
@export var position_at_edge = true
@export var viewport_padding = 16.0

func _ready():
	if expand_to_viewport:
		# Wait one frame to ensure viewport is ready
		await get_tree().process_frame
		resize_to_viewport()
		
		# Connect to viewport size changes
		get_viewport().size_changed.connect(resize_to_viewport)

func resize_to_viewport():
	var viewport_size = get_viewport().get_visible_rect().size
	
	# Get the collision shape to determine base dimensions
	var collision_shape = $CollisionShape2D
	if not collision_shape or not collision_shape.shape:
		return
	
	var shape = collision_shape.shape
	var base_width = 64.0  # Default width if not set
	var base_height = boundary_thickness
	
	# If it's a RectangleShape2D, use its actual size
	if shape is RectangleShape2D:
		base_width = shape.size.x
		base_height = shape.size.y
	
	match boundary_type:
		BoundaryType.FLOOR:
			# Expand horizontally to fill viewport width
			var scale_x = viewport_size.x / base_width
			var scale_y = boundary_thickness / base_height
			scale = Vector2(scale_x, scale_y)
			
			if position_at_edge:
				position = Vector2(viewport_size.x / 2, viewport_size.y - (boundary_thickness * scale_y) / 2)
			else:
				position.x = viewport_size.x / 2
				
		BoundaryType.LEFT_WALL:
			# Expand vertically to fill viewport height
			var scale_x = boundary_thickness / base_width
			var scale_y = viewport_size.y / base_height
			scale = Vector2(scale_x, scale_y)
			
			if position_at_edge:
				position = Vector2(viewport_padding + (boundary_thickness * scale_x) / 2, viewport_size.y / 2)
			else:
				position.y = viewport_size.y / 2
				
		BoundaryType.RIGHT_WALL:
			# Expand vertically to fill viewport height
			var scale_x = boundary_thickness / base_width
			var scale_y = viewport_size.y / base_height
			scale = Vector2(scale_x, scale_y)
			
			if position_at_edge:
				position = Vector2(viewport_size.x - viewport_padding - (boundary_thickness * scale_x) / 2, viewport_size.y / 2)
			else:
				position.y = viewport_size.y / 2
