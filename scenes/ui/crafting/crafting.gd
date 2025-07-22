extends Control

class_name CraftingUI

@export var hub_name: String

@export var recipe_list_container: VBoxContainer
@export var recipe_item_container: VBoxContainer

var recipe_list_template: Button
var recipe_item_template: PanelContainer

func _ready() -> void:
	$Panel/M/VBoxContainer/Title.text = hub_name + " - FabPrinter™"
	
	recipe_list_template = recipe_list_container.get_child(0).duplicate()
	recipe_item_template = recipe_item_container.get_child(0).duplicate()
	
	for recipe in SimulationManager.RECIPE_DB:
		var rl = recipe_list_template.duplicate() as Button
		rl.text = recipe.output.name
		rl.pressed.connect(on_recipe_selected.bind(recipe))
		
		recipe_list_container.add_child(rl)
		
	recipe_list_container.get_child(0).free()
	recipe_item_container.get_child(0).free()
	
	recipe_list_container.get_child(0).grab_focus()
	recipe_list_container.get_child(0).emit_signal("pressed")
	

func on_recipe_selected(recipe: SimulationManager.CommodityRecipe):
	for child in recipe_item_container.get_children():
		child.queue_free()
	
	$Panel/M/VBoxContainer/Table/HB/Panel/M/VB/VB/RecipeName.text = recipe.output.name
	$Panel/M/VBoxContainer/Table/HB/Panel/M/VB/HBoxContainer/Energy.text = str(recipe.energy) + " GW"
	$Panel/M/VBoxContainer/Table/HB/Panel/M/VB/HBoxContainer/Time.text = str(recipe.time) + " H"
	for ingredient in recipe.inputs:
		var ing_item = recipe_item_template.duplicate()
		recipe_item_container.add_child(ing_item)
		ing_item.get_node("HB/Name").text = ingredient.name
		ing_item.get_node("HB/Quantity").text =  "x" + str(recipe.inputs[ingredient])
	
