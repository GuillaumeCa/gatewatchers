extends Node3D

class_name Station

@export var hub_id: String

@onready var station_name_ui: Label = $StationNameViewport/StationNameUI/Name

func _ready() -> void:
	station_name_ui.text = hub_name()

func hub_name():
	return "Station " + str(hub_id)
