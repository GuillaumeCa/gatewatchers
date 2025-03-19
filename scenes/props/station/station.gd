extends Node3D

class_name Station

@export var hub_id: String

@onready var trade_terminal: TradingTerminal = $TradeTerminal
@onready var station_name_label: Label = $StationNameViewport/StationNameUI/Name

func _ready() -> void:
	trade_terminal.hub_id = hub_id
	station_name_label.text = "Station " + str(hub_id)
