extends Node2D

var barrier_pieces = []
var width = 15
var height = 10
var barrier = preload("res://Scenes/barrier.tscn")

signal barrier_destroyed

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


func _on_grid_damage_barrier(board_position):
	if barrier_pieces[board_position.x][board_position.y] == null:
		return
	barrier_pieces[board_position.x][board_position.y].take_damage(1)
	if barrier_pieces[board_position.x][board_position.y].health <= 0:
		barrier_pieces[board_position.x][board_position.y].queue_free()
		barrier_pieces[board_position.x][board_position.y] == null
		emit_signal("barrier_destroyed", board_position)


func _on_grid_make_barrier(board_position):
	if barrier_pieces.size() == 0:
		barrier_pieces = make_2d_array()
	var current = barrier.instantiate()
	add_child(current)
	current.position = Vector2(board_position.x * 100 + 430, -board_position.y * 100 + 990)
	barrier_pieces[board_position.x][board_position.y] = current
