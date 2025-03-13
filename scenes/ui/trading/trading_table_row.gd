extends PanelContainer

class_name TradingTableRow

var item_name: String
var item_count: int
var item_price: int

func _ready() -> void:
	$MarginContainer/HBoxContainer/ItemName.text = item_name
	$MarginContainer/HBoxContainer/ItemCount.text = str(item_count)
	$MarginContainer/HBoxContainer/ItemPrice.text = "¤ " + str(item_price)
	
