extends Node2D

@onready var enemy_spawn_point: Marker2D = $EnemySpawnDebug
var enemy_scene: PackedScene

func _ready():
	# Load the enemy scene
	enemy_scene = preload("res://Scenes/Enemies/EnemyBase.tscn")
	
	# Start spawning enemies every 5 seconds
	spawn_enemy()
	var timer = Timer.new()
	timer.wait_time = 5.0
	timer.timeout.connect(spawn_enemy)
	timer.autostart = true
	add_child(timer)

func spawn_enemy():
	var enemy = enemy_scene.instantiate()
	add_child(enemy)
	enemy.global_position = enemy_spawn_point.global_position
