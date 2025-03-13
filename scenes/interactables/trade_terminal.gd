extends StaticBody3D

class_name TradingTerminal

@export var hub_id: String

@onready var trading: TradingUI = $TradingUIViewport/trading

func _ready() -> void:
	trading.hub_id = hub_id
