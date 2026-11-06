class_name ShadowBlob
extends Node2D
## Soft contact shadow under a character; sells that they stand on the walkway.

var radius := 13.0
var strength := 0.5


func _ready() -> void:
	z_index = -1


func _draw() -> void:
	PropArt.ellipse(self, Vector2.ZERO, Vector2(radius, radius * 0.28), Color(0, 0, 0, strength))
	PropArt.ellipse(self, Vector2.ZERO, Vector2(radius * 0.6, radius * 0.18), Color(0, 0, 0, strength * 0.6))
