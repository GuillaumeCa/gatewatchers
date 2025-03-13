extends Control

class_name TradingUI

var row_scene = preload("res://scenes/ui/trading/trading_table_row.tscn")

@export var hub_id: String

var hub: SimulationManager.Hub

@onready var table_container: VBoxContainer = $Panel/M/VBoxContainer/Table/TableBody/VBoxContainer

func _ready() -> void:
	table_container.get_child(0).queue_free()
	
	hub = SimulationManager.hubs[hub_id]
	
	$Panel/M/VBoxContainer/Title.text = "%s - Trading" % [hub.name]
	
	SimulationManager.simulation_update.connect(update_table)

func update_table():
	for child in table_container.get_children():
		child.queue_free()
	
	for com in hub.commodities:
		var stock = hub.commodities[com]
		var price = hub.prices[com]
		var row = row_scene.instantiate() as TradingTableRow
		row.item_name = com.name
		row.item_count = stock
		row.item_price = price
		table_container.add_child(row)
	
