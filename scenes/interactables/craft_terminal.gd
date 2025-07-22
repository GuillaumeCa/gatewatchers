extends StaticBody3D

@export var station: Station

func _ready() -> void:
	$UIViewport/Crafting.hub_name = station.hub_name()
