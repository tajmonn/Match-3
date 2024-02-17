extends Node2D

var alien_pieces = []
var width = 15
var height = 10
var alien = preload("res://Scenes/alien.tscn")

signal alien_destroyed


func make_2d_array():
	var array = []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	return array

func _on_grid_make_alien(board_position):
	if alien_pieces.size() == 0:
		alien_pieces = make_2d_array()
	var current = alien.instantiate()
	add_child(current)
	current.position = Vector2(board_position.x * 100 + 430, -board_position.y * 100 + 990)
	alien_pieces[board_position.x][board_position.y] = current

func _on_grid_damage_alien(board_position):
	if alien_pieces.size() == 0:
		return
	if alien_pieces[board_position.x][board_position.y] == null:
		return
	alien_pieces[board_position.x][board_position.y].take_damage(1)
	if alien_pieces[board_position.x][board_position.y].health <= 0:
		alien_pieces[board_position.x][board_position.y].queue_free()
		alien_pieces[board_position.x][board_position.y] = null
		emit_signal("alien_destroyed", board_position)
