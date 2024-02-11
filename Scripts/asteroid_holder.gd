extends Node2D

var asteroid_pieces = []
var width = 15
var height = 10
var asteroid = preload("res://Scenes/asteroid.tscn")

signal asteroid_destroyed

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func make_2d_array():
	var array = []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	return array


func _on_grid_make_asteroid(board_position):
	if asteroid_pieces.size() == 0:
		asteroid_pieces = make_2d_array()
	var current = asteroid.instantiate()
	add_child(current)
	current.position = Vector2(board_position.x * 100 + 430, -board_position.y * 100 + 990)
	asteroid_pieces[board_position.x][board_position.y] = current


func _on_grid_damage_asteroid(board_position):
	if asteroid_pieces[board_position.x][board_position.y] == null:
		return
	asteroid_pieces[board_position.x][board_position.y].take_damage(1)
	if asteroid_pieces[board_position.x][board_position.y].health <= 0:
		asteroid_pieces[board_position.x][board_position.y].queue_free()
		asteroid_pieces[board_position.x][board_position.y] == null
		emit_signal("asteroid_destroyed", board_position)
