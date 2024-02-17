extends Node2D

@export var color: String
@export var row_texture: Texture
@export var column_texture: Texture
@export var adjacent_texture: Texture

var is_row_bomb = false
var is_column_bomb = false
var is_adjacent_bomb = false

var matched = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func move(target):
	var tween: Tween = create_tween()
	tween.tween_property(self, "position", target, 0.5).set_trans(Tween.TRANS_CUBIC)#.set_ease(Tween.EASE_OUT)

func dim(): 
	$Sprite2D.modulate.a = 0.5

func make_row_bomb():
	is_row_bomb = true
	$Sprite2D.texture = row_texture
	print("should work")
	$Sprite2D.modulate.a = 1

func make_column_bomb():
	is_column_bomb = true
	$Sprite2D.texture = column_texture
	$Sprite2D.modulate.a = 1

func make_adjacent_bomb():
	is_adjacent_bomb = true
	$Sprite2D.texture = adjacent_texture
	$Sprite2D.modulate.a = 1
