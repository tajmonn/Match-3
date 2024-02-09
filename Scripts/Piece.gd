extends Node2D

@export var color: String

var matched = false


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func move(target):
	var tween: Tween = create_tween()
	tween.tween_property(self, "position", target, 0.5).set_trans(Tween.TRANS_CUBIC)#.set_ease(Tween.EASE_OUT)

func dim(): 
	$Sprite2D.modulate.a = 0.5
	## should work the same as:
	#var sprite = get_node("Sprite2D")
	#sprite.modulate = Color(1, 1, 1, .5)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
