extends StaticBody3D

class_name TradingTerminal

@export var station: Station

@onready var trading: TradingUI = $TradingUIViewport/trading

func _ready() -> void:
	trading.hub_id = station.hub_id
