extends Node

# DBs
var COMMODITY_DB: Dictionary[String, Commodity] = {}
var RECIPE_DB: Array[CommodityRecipe] = []

# Update rates
var update_population = IntervalUpdate.new(10)

# stats
const WATER_PER_PERSON = 1
const HUB_COUNT = 2

const FUEL_SHIP_MAX = 30
const SHIP_MAX_STOCK = 200

# global states
var hubs: Dictionary[String, Hub] = {}
var deposits: Array[ResourceDeposit] = []

signal simulation_update


class IntervalUpdate:
	var current_tick: int
	var interval: int
	func _init(time):
		self.interval = time
	
	func must_update():
		if current_tick >= interval:
			current_tick = 0
			return true
		current_tick += 1
		return false

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
	func _init(output: Commodity, inputs: Dictionary[Commodity, int], time: int, energy: int) -> void:
		self.output = output
		self.inputs = inputs
		self.time = time
		self.energy = energy

class ShipAi:
	var stock: Dictionary[Commodity, int]
	var fuel: int
	var max_cargo: int
	var target_deposit: ResourceDeposit
	var target_commodity: Commodity

	func _to_string() -> String:
		var sid = "none"
		if self.target_deposit:
			sid = self.target_deposit.source_id
		
		return "F:%d MC: %d TD: %s" % [self.fuel, self.max_cargo, self.target_deposit]
	
	func assign_deposit(depo: ResourceDeposit):
		self.target_deposit = depo
	
	func mine():
		if !self.target_deposit or self.target_deposit.is_exhausted():
			self.target_deposit = self.choose_deposit()
		
		if self.target_deposit and !self.is_cargo_full() and self.fuel > 0:
			self.target_deposit.mine()
			if not self.target_deposit.source in self.stock:
				self.stock[self.target_deposit.source] = 0
			
			self.stock[self.target_deposit.source] += 10
			self.fuel -= 1
		
	# TODO: improve based on distance
	func choose_deposit() -> ResourceDeposit:
		SimulationManager.deposits.shuffle()
		if self.target_commodity:
			for dep in SimulationManager.deposits:
				if dep.source == self.target_commodity:
					return dep
		
		return SimulationManager.deposits.pick_random()
	func must_return_home() -> bool:
		return self.is_cargo_full() or self.fuel <= 0
	
	func is_cargo_full() -> bool:
		var total = 0
		for com in stock:
			total += stock[com]
		return total >= max_cargo

class ResourceDeposit:
	var quantity: int
	var source: Commodity
	var source_id: String
	
	func _to_string() -> String:
		return "Depos[name:%s Q:%d]" % [self.source.name, self.quantity] 
	
	func is_exhausted():
		return quantity == 0
	
	func mine():
		if quantity > 0:
			quantity -= 10

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

class Hub:
	var id: String
	var name: String
	var money: int
	var population: int
	
	var prices: Dictionary[Commodity, int] = {}
	var commodities: Dictionary[Commodity, int] = {}

	var max_stock: Dictionary[CommodityType, int] = {}
	var ships: Array[ShipAi] = []
	
	func take_commodity(id: String, count: int):
		var com = SimulationManager.COMMODITY_DB[id]
		
		if not com in self.commodities:
			return 0
		
		if self.commodities[com] >= count:
			self.commodities[com] -= count
			_compute_price()
			return count
		else:
			var taken = self.commodities[com]
			self.commodities[com] -= taken
			_compute_price()
			return taken
	
	func add_commodity(commodity: Commodity, count: int):
		if not commodity in self.commodities:
			self.commodities[commodity] = 0
			
		
		var future_stock = self.commodities[commodity] + count
		if future_stock > self.max_stock[commodity.type]:
			var max = future_stock - self.max_stock[commodity.type]
			self.commodities[commodity] += max
			_compute_price()
			return max
		else:
			self.commodities[commodity] += count
			_compute_price()
			return count
	
	func init_commodity(id: String, count: int):
		var com = SimulationManager.COMMODITY_DB[id]
		self.commodities[com] = count
		_compute_price()
		
	
	func _compute_price():
		for com in self.commodities:
			var maxstock := self.max_stock[com.type]
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
		var com = SimulationManager.COMMODITY_DB[id]
		var stock = self.commodities[com]
		if count > stock:
			print("not enough stock")
			return
		self.commodities[com] -= count
		_compute_price()
		money += count * self.prices[com]
	
	func debug():
		prints("=====",self.name, "=====")
		print("M=",self.money, "U")
		print("P=",self.population)
		for com in self.commodities:
			prints(com, "C:", self.commodities[com])
		
		for ship in self.ships:
			prints(ship)

func _ready() -> void:
	seed(42)
	
	COMMODITY_DB["aluminum"] = Commodity.new("Aluminum", CommodityType.ORE, 10)
	COMMODITY_DB["iron"] = Commodity.new("Iron", CommodityType.ORE, 3)
	COMMODITY_DB["gold"] = Commodity.new("Gold", CommodityType.ORE, 200)
	COMMODITY_DB["silicon"] = Commodity.new("Silicon", CommodityType.ORE, 5)
	COMMODITY_DB["copper"] = Commodity.new("Copper", CommodityType.ORE, 50)
	COMMODITY_DB["titanium"] = Commodity.new("Titanium", CommodityType.ORE, 100)
	COMMODITY_DB["indium"] = Commodity.new("Indium", CommodityType.ORE, 80)
	
	COMMODITY_DB["xenon"] = Commodity.new("Xenon", CommodityType.GAZ, 30)
	
	COMMODITY_DB["fuel"] = Commodity.new("Fuel", CommodityType.LIQUID, 10)
	COMMODITY_DB["water"] = Commodity.new("Water", CommodityType.LIQUID, 5)
	
	COMMODITY_DB["circuitboard"] = Commodity.new("Circuit Board", CommodityType.COMPONENT, 300)
	COMMODITY_DB["generator"] = Commodity.new("Generator", CommodityType.COMPONENT, 1500)
	COMMODITY_DB["shipthruster"] = Commodity.new("Ship Thruster", CommodityType.COMPONENT, 1200)
	COMMODITY_DB["shippower"] = Commodity.new("Ship PowerPlant", CommodityType.COMPONENT, 900)
	COMMODITY_DB["shiplasergun"] = Commodity.new("Ship Laser Gun", CommodityType.COMPONENT, 1800)
	COMMODITY_DB["shiphull"] = Commodity.new("Ship Hull", CommodityType.COMPONENT, 2000)
	
	COMMODITY_DB["solarpanel"] = Commodity.new("Solar Panel", CommodityType.COMPONENT, 800)
	COMMODITY_DB["storage"] = Commodity.new("Storage", CommodityType.COMPONENT, 600)
	
	RECIPE_DB.append(CommodityRecipe.new(COMMODITY_DB["circuitboard"], { COMMODITY_DB["gold"]: 2, COMMODITY_DB["silicon"]: 5 }, 1, 10))
	RECIPE_DB.append(CommodityRecipe.new(COMMODITY_DB["solarpanel"], { COMMODITY_DB["circuitboard"]: 3, COMMODITY_DB["silicon"]: 20, COMMODITY_DB["aluminum"]: 5 }, 4, 40))
	RECIPE_DB.append(CommodityRecipe.new(COMMODITY_DB["shiphull"], { COMMODITY_DB["aluminum"]: 30, COMMODITY_DB["titanium"]: 10, COMMODITY_DB["iron"]: 50 }, 20, 150))
	RECIPE_DB.append(CommodityRecipe.new(COMMODITY_DB["storage"], { COMMODITY_DB["aluminum"]: 4 }, 2, 4))
	RECIPE_DB.append(CommodityRecipe.new(COMMODITY_DB["generator"], { COMMODITY_DB["circuitboard"]: 10, COMMODITY_DB["iron"]: 40, COMMODITY_DB["aluminum"]: 20, COMMODITY_DB["copper"]: 10 }, 10, 100))
	
	generate_hubs()
	generate_deposits()
	

func debug():
	#hubs["S10"].buy_commodity("water", 20)
	for s in hubs:
		hubs[s].debug()

func get_mineable_commodities() -> Array[String]:
	var mineables: Array[String] = []
	for com_id in COMMODITY_DB:
		var com = COMMODITY_DB[com_id]
		if com.type != CommodityType.COMPONENT:
			mineables.append(com_id)
	return mineables

func generate_deposits():
	for i in randi_range(500, 1500):
		var depos = ResourceDeposit.new()
		depos.quantity = randi_range(50, 200000)
		
		var com_id = get_mineable_commodities().pick_random()
		depos.source = COMMODITY_DB[com_id]
		depos.source_id = com_id
		
		deposits.append(depos)
		

func generate_hubs():
	# get the number of stations based on SpaceManager generated stations
	for i in HUB_COUNT:
		var hub = Hub.new()
		hub.id = "S1" + str(i)
		hub.name = "Station S1" + str(i)
		hub.money = 400 #randi_range(300, 800)
		hub.population = 20 #randi_range(10, 50)
		
		hub.max_stock[CommodityType.ORE] = 10000
		hub.max_stock[CommodityType.GAZ] = 30000
		hub.max_stock[CommodityType.LIQUID] = 50000
		hub.max_stock[CommodityType.COMPONENT] = 300
		
		hub.init_commodity("water", randi_range(500, 2000))
		hub.init_commodity("fuel", randi_range(800, 3000))
		hub.init_commodity("iron", randi_range(10, 50))
		hub.init_commodity("aluminum", randi_range(10, 50))
		
		for j in randi_range(5, 10):
			var ship = ShipAi.new()
			ship.max_cargo = SHIP_MAX_STOCK
			ship.fuel = 0
			hub.ships.append(ship)
		
		hubs[hub.id] = hub

func simulate_tick():
	for hub_id in hubs:
		var hub = hubs[hub_id]
		var waterstock = hub.commodities[COMMODITY_DB["water"]]
		var water_low = waterstock < (WATER_PER_PERSON * hub.population)
		
		var fuelstock = hub.commodities[COMMODITY_DB["fuel"]]
		var fuel_low = fuelstock < (FUEL_SHIP_MAX * hub.ships.size())
		
		if update_population.must_update():
			hub.population -= 1 # natural deaths
			hub.population += 1 # births
			if water_low:
				hub.population -= 2
		
			var water_cons = WATER_PER_PERSON * hub.population
			hub.take_commodity("water", water_cons)
		
		
		for ship: ShipAi in hub.ships:
			if ship.must_return_home():
				# reset targets
				ship.target_deposit = null
				ship.target_commodity = null
				
				# ship refuel
				var to_refuel = FUEL_SHIP_MAX - ship.fuel
				ship.fuel = hub.take_commodity("fuel", to_refuel)
				
				# empty cargo
				for cargo in ship.stock:
					if ship.stock[cargo] > 0:
						ship.stock[cargo] -= hub.add_commodity(cargo, ship.stock[cargo])
				
				
				if randf() < 0.4:
					ship.target_commodity = COMMODITY_DB["water"]
				if randf() < 0.3:
					ship.target_commodity = COMMODITY_DB["fuel"]
				
				if water_low:
					ship.target_commodity = COMMODITY_DB["water"]
				if fuel_low:
					ship.target_commodity = COMMODITY_DB["fuel"]
			else:
				ship.mine()
	
	simulation_update.emit()
