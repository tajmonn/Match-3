extends Node2D

# Grid Variables
@export var width: int
@export var height: int
@export var x_start: int
@export var y_start: int
@export var offset: int
@export var y_offset: int

# Obstacle Stuff
@export var empty_spaces: PackedVector2Array
@export var moon_spaces: PackedVector2Array
@export var barrier_spaces: PackedVector2Array
@export var asteroid_spaces: PackedVector2Array
@export var alien_spaces: PackedVector2Array
var damaged_alien = false

# Obstacle signals
signal make_moon
signal damage_moon
signal make_barrier
signal damage_barrier
signal make_asteroid
signal damage_asteroid
signal make_alien
signal damage_alien

# The piece array
var possible_pieces = [
preload("res://Scenes/blue_piece.tscn"),
preload("res://Scenes/brown_piece.tscn"),
preload("res://Scenes/green_piece.tscn"),
preload("res://Scenes/purple_piece.tscn"),
preload("res://Scenes/red_piece.tscn"),
preload("res://Scenes/white_piece.tscn")	
]
# The current pieces in the scene
var all_pieces = []
var current_matches = []

# Touch variables
var first_touch
var final_touch
var controlling = false

# Variables for swapping back
var piece_one = null
var piece_two = null
var last_place = Vector2(0, 0)
var last_direction = Vector2(0, 0)
var move_checked = false

# function to update those variables
func store_info(first_piece, other_piece, place, direction):
	piece_one = first_piece
	piece_two = other_piece
	last_place = place
	last_direction = direction

# State machine
enum {WAIT, MOVE}
var state

# Helping functions for grid and pixels
func grid_to_pixel(column, row):
	var new_x = x_start + offset * column
	var new_y = y_start + -offset * row
	return Vector2(new_x, new_y)

func pixel_to_grid(pixel_pos):
	var new_column = round((pixel_pos.x - x_start) / offset)
	var new_row = round((pixel_pos.y - y_start) / -offset)
	return Vector2(new_column, new_row)

# Called when the node enters the scene tree for the first time.
func _ready():
	state = MOVE
	randomize()
	all_pieces = make_2d_array()
	spawn_pieces()
	spawn_moon()
	spawn_barrier()
	spawn_asteroid()
	spawn_alien()
func make_2d_array():
	var array = []
	for column in width:
		array.append([])
		for row in height:
			array[column].append(null)
	return array
func spawn_pieces():
	for column in width:
		for row in height:
			if restricted_fill(Vector2(column, row)):
				continue
			# choose a random number and store it
			var rand = randi_range(0, possible_pieces.size() - 1)
			var piece = possible_pieces[rand].instantiate()
			var loops = 0
			while(match_at(column, row, piece.color) && loops < 100):
				rand = floor(randi_range(0, possible_pieces.size() - 1))
				loops += 1
				piece = possible_pieces[rand].instantiate()
			
			add_child(piece)
			piece.position = grid_to_pixel(column, row)
			all_pieces[column][row] = piece
func spawn_moon():
	for moon_space in moon_spaces:
		emit_signal("make_moon", moon_space)
func spawn_barrier():
	for barrier_space in barrier_spaces:
		emit_signal("make_barrier", barrier_space)
func spawn_asteroid():
	for asteroid_space in asteroid_spaces:
		emit_signal("make_asteroid", asteroid_space)
func spawn_alien():
	for alien_space in alien_spaces:
		emit_signal("make_alien", alien_space)

func restricted_fill(place):
	if place in empty_spaces:
		return true
	if place in asteroid_spaces:
		return true
	if place in alien_spaces:
		return true
	return false

func restricted_move(place):
	if place in barrier_spaces:
		return true
	return false

func match_at(column, row, color):
	if column > 1:
		if all_pieces[column - 1][row] != null && all_pieces[column - 2][row] != null:
			if all_pieces[column - 1][row].color == color && all_pieces[column - 2][row].color == color:
				return true
	if row > 1:
		if all_pieces[column][row - 1] != null && all_pieces[column][row - 2] != null:
			if all_pieces[column][row - 1].color == color && all_pieces[column][row - 2].color == color:
				return true

# Helping function to check if click is in grid (planets)
func is_in_grid(grid_position):
	if grid_position.x >= 0 && grid_position.x < width && grid_position.y >= 0 && grid_position.y < height:
		return true
	return false

func remove_from_array(array, item):
	for i in range(array.size() - 1, -1, -1):
		if array[i] == item:
			array.remove_at(i)
			break

# What happens when we move two planets
func click_diff(grid_1, grid_2):
	var vector = false
	var difference = grid_2 - grid_1
	if abs(difference.x) > abs(difference.y):
		if difference.x > 0: # move to the right
			vector = Vector2(1, 0)
		elif difference.x < 0: # move to the left
			vector = Vector2(-1, 0)

	elif abs(difference.x) < abs(difference.y):
		if difference.y > 0: # move down
			vector = Vector2(0, 1)
		elif difference.y < 0: # move up
			vector = Vector2(0, -1)

	if vector and legal_move(grid_1.x, grid_1.y, vector): # if vector changed value from false then swap pieces
		swap_pieces(grid_1.x, grid_1.y, vector)
	else:
		state = MOVE
func swap_pieces(column, row, direction):
	var first_piece = all_pieces[column][row]
	var other_piece = all_pieces[column + direction.x][row + direction.y]
	if !first_piece or !other_piece:
		state = MOVE
		return false
	store_info(first_piece, other_piece, Vector2(column, row), direction)
	state = WAIT
	# THERE SHOULD BE ANIMATION SOMEDAY
	all_pieces[column][row] = other_piece
	all_pieces[column + direction.x][row + direction.y] = first_piece
	first_piece.move(grid_to_pixel(column + direction.x, row + direction.y))
	other_piece.move(grid_to_pixel(column, row))
	if not(move_checked):
		find_matches()
# Checking if planet doesn't leave the board
func legal_move(column, row, direction):
	if column == 0 and direction.x == -1:
		return false
	if column == width-1 and direction.x == 1:
		return false
	if row == 0 and direction.y == -1:
		return false
	if row == height-1 and direction.y == 1:
		return false
	if restricted_move(Vector2(column, row)):
		return false
	if restricted_move(Vector2(column + direction.x, row + direction.y)):
		return false
	return true

# Helping function to dim planets and check them as matched
func match_and_dim(pieces):
	for piece in pieces:
		piece.matched = true
		piece.dim()

func are_pieces_color(color, pieces):
	for piece in pieces:
		if piece.color != color:
			return false
	return true

func are_pieces_not_null(pieces):
	for piece in pieces:
		if piece == null:
			return false
	return true

func damage_special(column, row):
	emit_signal("damage_moon", Vector2(column, row))
	emit_signal("damage_barrier", Vector2(column, row))
	check_special_adjacent(column, row, "damage_asteroid")
	check_special_adjacent(column, row, "damage_alien")

func check_special_adjacent(column, row, signal_name):
	if column < width - 1:
		emit_signal(signal_name, Vector2(column + 1, row))
	if column > 0:
		emit_signal(signal_name, Vector2(column - 1, row))
	if row < height - 1:
		emit_signal(signal_name, Vector2(column, row + 1))
	if row > 0:
		emit_signal(signal_name, Vector2(column, row - 1))

# Function checking for matches and running match and dim and starts destroy_timer
func find_matches():
	for column in width:
		for row in height:
			if all_pieces[column][row] == null:
				continue
				
			var current_color = all_pieces[column][row].color
			if column > 0 and column < width - 1:
				var looked_for_pieces = [all_pieces[column - 1][row], all_pieces[column + 1][row]]
				if are_pieces_not_null(looked_for_pieces):
					if are_pieces_color(current_color, looked_for_pieces):
						looked_for_pieces.append(all_pieces[column][row])
						match_and_dim(looked_for_pieces)
						for looked_for_piece in [Vector2(column-1, row), Vector2(column, row), Vector2(column+1,row)]:
							add_to_array(Vector2(looked_for_piece.x, looked_for_piece.y), current_matches)

			if row > 0 and row < height - 1:
				var looked_for_pieces = [all_pieces[column][row - 1], all_pieces[column][row + 1]]
				if are_pieces_not_null(looked_for_pieces):
					if are_pieces_color(current_color, looked_for_pieces):
						looked_for_pieces.append(all_pieces[column][row])
						match_and_dim(looked_for_pieces)
						for looked_for_piece in [Vector2(column, row-1), Vector2(column, row), Vector2(column,row+1)]:
							add_to_array(Vector2(looked_for_piece.x, looked_for_piece.y), current_matches)
	get_bombed_pieces()
	get_parent().get_node("destroy_timer").start()
func get_bombed_pieces():
	for column in width:
		for row in height:
			if all_pieces[column][row] == null:
				continue
			if !all_pieces[column][row].matched:
				continue
			if all_pieces[column][row].is_column_bomb:
				match_all_in_column(column)
			elif all_pieces[column][row].is_row_bomb:
				match_all_in_row(row)
			elif all_pieces[column][row].is_adjacent_bomb:
				match_all_adjacent(Vector2(column, row))
func _on_destroy_timer_timeout(): # runs starts destroy_matched
	destroy_matched()
func destroy_matched(): # destroy_matched at the end runs colapse_timer
	find_bombs()
	var was_matched = false
	for column in width:
		for row in height:
			if all_pieces[column][row] != null:
				if all_pieces[column][row].matched:
					damage_special(column, row)
					was_matched = true
					all_pieces[column][row].queue_free()
					all_pieces[column][row] = null
	move_checked = true
	if was_matched:
		get_parent().get_node("collapse_timer").start()
	else:
		swap_back()
	current_matches.clear()
func _on_collapse_timer_timeout():
	collapse_columns()
func collapse_columns():
	for column in width:
		for row in height:
			if all_pieces[column][row] != null or restricted_fill(Vector2(column, row)): 
				continue # If !restricted_fill and a piece is null then do stuff otherwise go back to loop
			for higher_row in range(row + 1, height):
				if all_pieces[column][higher_row] != null:
					all_pieces[column][higher_row].move(grid_to_pixel(column, row))
					all_pieces[column][row] = all_pieces[column][higher_row]
					all_pieces[column][higher_row] = null
					break
	get_parent().get_node("refill_timer").start()
func _on_refill_timer_timeout():
	refill_columns()
func refill_columns():
	for column in width:
		for row in height:
			if all_pieces[column][row] == null and !restricted_fill(Vector2(column, row)):
				var rand = randi_range(0, possible_pieces.size() - 1)
				var piece = possible_pieces[rand].instantiate()
				add_child(piece)
				piece.position = grid_to_pixel(column, row + y_offset)
				piece.move(grid_to_pixel(column,row))
				all_pieces[column][row] = piece
	after_refill()
func after_refill():
	for column in width:
		for row in height:
			if all_pieces[column][row] != null:
				if match_at(column, row, all_pieces[column][row].color) or all_pieces[column][row].matched:
					find_matches()
					# state = MOVE
					#get_parent().get_node("destroy_timer").start()
					return
	move_checked = false
	if !damaged_alien:
		alien_multiply()
	damaged_alien = false
	state = MOVE
func swap_back():
	# Move the previously swapped pieces back to the previous place.
	if piece_one != null && piece_two != null:
		swap_pieces(last_place.x, last_place.y, last_direction) 
	state = MOVE
	move_checked = false

func add_to_array(value, array):
	if !(value in array):
		array.append(value)

func extend_array(new_array, old_array):
	for thing in new_array:
		add_to_array(thing, old_array)

func find_normal_neighbours(pieces):
	var neighbours = []
	for piece in pieces:
		var directions = [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]
		for direction in directions:
			if is_in_grid(piece + direction):
					if (all_pieces[piece.x + direction.x][piece.y + direction.y] != null):
						add_to_array(Vector2(piece.x + direction.x, piece.y + direction.y), neighbours)
	return neighbours

func generate_alien(neighbours):
	if neighbours.size() <= 0:
		return
	var rand = randi_range(0, neighbours.size() - 1)
	var neighbour = neighbours[rand]
	all_pieces[neighbour.x][neighbour.y].queue_free()
	all_pieces[neighbour.x][neighbour.y] = null
	alien_spaces.append(Vector2(neighbour.x, neighbour.y))
	emit_signal("make_alien", neighbour)

func alien_multiply():
	var alien_neighbours = find_normal_neighbours(alien_spaces)
	generate_alien(alien_neighbours)

func look_in_direction(current_pos, direction, used):
	var current_match = all_pieces[current_pos.x][current_pos.y]
	var current_color = current_match.color
	var next_pos = current_pos + direction
	var new_used = []
	if next_pos in used:
		return new_used
	while is_in_grid(next_pos):
		if next_pos in used:
			break
		if !(next_pos in current_matches):
			break
		if all_pieces[next_pos.x][next_pos.y].color != current_color:
			break
		new_used.append(next_pos)
		next_pos += direction
	return new_used

func find_bombs():
	var used = []
	for current_pos in current_matches:
		if current_pos in used:
			continue
		
		var new_used_u = look_in_direction(current_pos, Vector2(0,  1), used)
		var new_used_d = look_in_direction(current_pos, Vector2(0, -1), used)
		var new_used_l = look_in_direction(current_pos, Vector2(-1, 0), used)
		var new_used_r = look_in_direction(current_pos, Vector2( 1, 0), used)

		# check for 5 in line in column
		if new_used_u.size() + new_used_d.size() >= 4 or new_used_r.size() + new_used_l.size() >= 4:
			# make a color bomb !
			extend_array(new_used_u, used)
			extend_array(new_used_d, used)
			extend_array(new_used_r, used)
			extend_array(new_used_l, used)
			add_to_array(current_pos, used)
			make_bomb("color", used)
			continue

		# check for adjacent bombs
		if new_used_u.size() + new_used_d.size() >= 2 and new_used_r.size() + new_used_l.size() >= 2:
			# make an adjacent bomb !
			extend_array(new_used_u, used)
			extend_array(new_used_d, used)
			extend_array(new_used_r, used)
			extend_array(new_used_l, used)
			add_to_array(current_pos, used)
			make_bomb("adjacent", used)
			continue
		# check for column bomb
		if new_used_r.size() + new_used_l.size() >= 3:
			# make a column bomb !
			extend_array(new_used_r, used)
			extend_array(new_used_l, used)
			add_to_array(current_pos, used)
			make_bomb("column", used)
			continue
		# check for row bomb 
		if new_used_u.size() + new_used_d.size() >= 3:
			# make a row bomb !
			extend_array(new_used_u, used)
			extend_array(new_used_d, used)
			add_to_array(current_pos, used)
			make_bomb("row", used)
			continue
		
func make_bomb(bomb_type, used):
	for used_pos in used:
		if all_pieces[used_pos.x][used_pos.y] == piece_one:
			piece_one.matched = false
			change_bomb(bomb_type, piece_one)
			return
		elif all_pieces[used_pos.x][used_pos.y] == piece_two:
			piece_two.matched = false
			change_bomb(bomb_type, piece_two)
			return
	# when bomb is made by freefall - change random piece to bomb
	var rand = randi_range(0, used.size() - 1)
	change_bomb(bomb_type, all_pieces[used[rand].x][used[rand].y])

func change_bomb(bomb_type, piece):
	if bomb_type == "adjacent":
		piece.matched = false
		piece.make_adjacent_bomb()
	elif bomb_type == "row":
		piece.matched = false
		piece.make_row_bomb()
	elif bomb_type == "column":
		piece.matched = false
		piece.make_column_bomb()
	elif bomb_type == "color":
		print("MAKING COLOR BOMB")

func match_all_in_column(column):
	for row in height:
		if all_pieces[column][row] != null and !all_pieces[column][row].matched:
			if all_pieces[column][row].is_row_bomb:
				match_all_in_row(row)
			if all_pieces[column][row].is_adjacent_bomb:
				match_all_adjacent(Vector2(column, row))
			all_pieces[column][row].matched = true

func match_all_in_row(row):
	for column in width:
		if all_pieces[column][row] != null and !all_pieces[column][row].matched:
			if all_pieces[column][row].is_row_bomb:
				match_all_in_column(column)
			if all_pieces[column][row].is_adjacent_bomb:
				match_all_adjacent(Vector2(column, row))
			all_pieces[column][row].matched = true

func match_all_adjacent(piece):
	var directions = [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1), Vector2(1, 1), Vector2(1, -1), Vector2(-1, -1), Vector2(-1, 1)]
	for direction in directions:
		if is_in_grid(piece + direction):
			if all_pieces[piece.x + direction.x][piece.y + direction.y] != null and !all_pieces[piece.x + direction.x][piece.y + direction.y].matched:
				if all_pieces[piece.x + direction.x][piece.y + direction.y].is_row_bomb:
					match_all_in_column(piece.x + direction.x)
				if all_pieces[piece.x + direction.x][piece.y + direction.y].is_row_bomb:
					match_all_in_row(piece.y + direction.y)
				
				all_pieces[piece.x + direction.x][piece.y + direction.y].matched = true

func _input(event):
	if state == MOVE: # move only when you have state move
		if event.is_action_pressed("ui_click"):
			if is_in_grid(pixel_to_grid(get_global_mouse_position())):
				first_touch = pixel_to_grid(get_global_mouse_position())
				controlling = true
		
	if event.is_action_released("ui_click"):
		final_touch = pixel_to_grid(get_global_mouse_position())
		if controlling: # not using it since it takes only direction && is_in_grid(grid_position_release.x, grid_position_release.y):
			controlling = false
			state = WAIT
			click_diff(first_touch, final_touch)

func _on_barrier_holder_barrier_destroyed(place):
	remove_from_array(barrier_spaces, place)

func _on_asteroid_holder_asteroid_destroyed(place):
	remove_from_array(asteroid_spaces, place)

func _on_alien_holder_alien_destroyed(place):
	remove_from_array(alien_spaces, place)
	damaged_alien = true
