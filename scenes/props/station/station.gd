extends Node3D

class_name Station

@export var hub_id: String

@onready var trade_terminal: TradingTerminal = $TradeTerminal

func _ready() -> void:
	trade_terminal.hub_id = hub_id
