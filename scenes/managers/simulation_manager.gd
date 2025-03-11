extends Node


var stations = {}
var deposits = {}

var COMMODITY_DB: Dictionary[String, Commodity] = {}
var RECIPE_DB: Array[CommodityRecipe] = []

enum CommodityType {
	COMPONENT,
	ORE,
	GAZ,
	LIQUID
}

## A recipe to create a commodity in exchange of a list of commodities with time and energy
class CommodityRecipe:
	var inputs: Dictionary[Commodity, int]
	var time: int
	var energy: int
	var output: Commodity
	func _init(ouput: Commodity, inputs: Dictionary[Commodity, int], time: int, energy: int) -> void:
		self.inputs = inputs
		self.time = time
		self.energy = energy
		self.output = output

#class ResourceDeposit:
	#var name: String
	#var quantity: int
	#var source: Commodity

class Commodity:
	var name: String
	var type: CommodityType
	# price in unit/g for ores, unit/L for gaz and liquids
	var price_index: int
	
	func _init(name: String, type: CommodityType, price: int) -> void:
		self.name = name
		self.type = type
		self.price_index = price
	
	func _to_string() -> String:
		return self.name + " ["+ CommodityType.keys()[self.type] +"] " + str(self.price_index) + "U"

class Station:
	var id: String
	var name: String
	var money: int
	var prices: Dictionary[Commodity, int] = {}
	var commodities: Dictionary[Commodity, int] = {}
	var max_stock: Dictionary[Commodity, int] = {}
	
	func add_commodity(id: String, count: int):
		var com = SimulationManager.COMMODITY_DB[id]
		self.commodities[com] = count
		self.max_stock[com] = 400
		_compute_price()
	
	func _compute_price():
		for com in self.commodities:
			var maxstock := self.max_stock[com]
			var stock := self.commodities[com]
			var stock_frac = stock / float(maxstock)
			var adjust = 1
			if stock_frac > 0.8:
				adjust = remap(stock_frac, 0.8, 1.0, 1, 1/3.0)
			elif stock_frac < 0.2:
				adjust = remap(stock_frac, 0.0, 0.2, 3, 1)
			
			var base_price = com.price_index
			var adjusted_price = int(base_price * adjust)
			self.prices[com] = adjusted_price
	
	func buy_commodity(id: String, count: int):
		var stock = self.commodities[SimulationManager.COMMODITY_DB[id]]
		if count > stock:
			print("not enough stock")
			return
		self.commodities[SimulationManager.COMMODITY_DB[id]] -= count
		_compute_price()
	
	func debug():
		print(self.name, ":")
		for com in self.commodities:
			print(com)
			prints("sell price: ", self.prices[com])
			prints("stock: ", self.commodities[com])

func _ready() -> void:
	COMMODITY_DB["aluminum"] = Commodity.new("Aluminum", CommodityType.ORE, 10)
	COMMODITY_DB["iron"] = Commodity.new("Iron", CommodityType.ORE, 3)
	COMMODITY_DB["gold"] = Commodity.new("Gold", CommodityType.ORE, 200)
	COMMODITY_DB["silicon"] = Commodity.new("Silicon", CommodityType.ORE, 5)
	COMMODITY_DB["copper"] = Commodity.new("Copper", CommodityType.ORE, 50)
	COMMODITY_DB["titanium"] = Commodity.new("Titanium", CommodityType.ORE, 100)
	COMMODITY_DB["indium"] = Commodity.new("Indium", CommodityType.ORE, 80)
	
	COMMODITY_DB["xenon"] = Commodity.new("Xenon", CommodityType.GAZ, 30)
	
	COMMODITY_DB["fuel"] = Commodity.new("Fuel", CommodityType.LIQUID, 10)
	COMMODITY_DB["water"] = Commodity.new("Water", CommodityType.LIQUID, 30)
	
	COMMODITY_DB["circuitboard"] = Commodity.new("Circuit Board", CommodityType.COMPONENT, 300)
	COMMODITY_DB["generator"] = Commodity.new("Generator", CommodityType.COMPONENT, 1500)
	COMMODITY_DB["shipthruster"] = Commodity.new("Ship Thruster", CommodityType.COMPONENT, 1200)
	COMMODITY_DB["shippower"] = Commodity.new("Ship PowerPlant", CommodityType.COMPONENT, 900)
	COMMODITY_DB["shiplasergun"] = Commodity.new("Ship Laser Gun", CommodityType.COMPONENT, 1800)
	COMMODITY_DB["shiphull"] = Commodity.new("Ship Hull", CommodityType.COMPONENT, 2000)
	
	COMMODITY_DB["solarpanel"] = Commodity.new("Solar Panel", CommodityType.COMPONENT, 800)
	COMMODITY_DB["storage"] = Commodity.new("Storage", CommodityType.COMPONENT, 600)
	
	RECIPE_DB.append(CommodityRecipe.new(COMMODITY_DB["circuitboard"], { COMMODITY_DB["gold"]: 2, COMMODITY_DB["silicon"]: 5 }, 1, 10))
	RECIPE_DB.append(CommodityRecipe.new(COMMODITY_DB["solarpanel"], { COMMODITY_DB["circuitboard"]: 3, COMMODITY_DB["silicon"]: 20, COMMODITY_DB["aluminum"]: 5 }, 1, 10))
	
	generate_stations()
	for s in stations:
		stations[s].debug()

func generate_stations():
	# get the number of stations based on SpaceManager generated stations
	for i in 5:
		var station = Station.new()
		station.id = "S1" + str(i)
		station.name = "Station S1" + str(i)
		station.money = randi_range(300, 800)
		station.add_commodity("water", 40)
		station.add_commodity("fuel", 300)
		station.add_commodity("iron", 10)
		station.add_commodity("aluminum", 10)
		stations[station.id] = station
	
