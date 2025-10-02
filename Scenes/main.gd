extends Node2D

@onready var enemy_spawn_point: Marker2D = $EnemySpawnDebug
@onready var background_track: AudioStreamPlayer = $BackgroundTrack

var enemy_scene: PackedScene

func _ready():
	# Load the enemy scene
	enemy_scene = preload("res://Scenes/Enemies/EnemyBase.tscn")
	
	# Start spawning enemies every 15 seconds
	spawn_enemy()
	var timer = Timer.new()
	timer.wait_time = 15.0
	timer.timeout.connect(spawn_enemy)
	timer.autostart = true
	add_child(timer)
	
	# Start playing the background track if it's not already playing
	if not background_track.playing:
		background_track.play()

func spawn_enemy():
	var enemy = enemy_scene.instantiate()
	add_child(enemy)
	enemy.global_position = enemy_spawn_point.global_position
