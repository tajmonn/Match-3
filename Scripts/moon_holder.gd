extends Node2D


var moon_pieces = []
var width = 15
var height = 10
var ice = preload("res://Scenes/moon.tscn")

func make_2d_array():
	var array = []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	return array

func _on_grid_make_moon(board_position):
	if moon_pieces.size() == 0:
		moon_pieces = make_2d_array()
	var current = ice.instantiate()
	add_child(current)
	current.position = Vector2(board_position.x * 100 + 430, -board_position.y * 100 + 990)
	moon_pieces[board_position.x][board_position.y] = current

func _on_grid_damage_moon(board_position):
	if moon_pieces.size() == 0:
		return 
	if moon_pieces[board_position.x][board_position.y] == null:
		return
	moon_pieces[board_position.x][board_position.y].take_damage(1)
	if moon_pieces[board_position.x][board_position.y].health <= 0:
		moon_pieces[board_position.x][board_position.y].queue_free()
		moon_pieces[board_position.x][board_position.y] = null
