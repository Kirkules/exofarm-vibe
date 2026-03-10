class_name Inventory
extends RefCounted

## General-purpose item pool with slot-based capacity.
## Capacity is the total number of slots available (sum of building contributions).
## Each InventoryItem may occupy more than one slot (slot_size).
## Overflow is allowed but flagged via is_over_capacity().

## Emitted whenever the item list changes.
signal changed

var capacity: int
var _items: Array[InventoryItem] = []

func _init(p_capacity: int = 10) -> void:
	capacity = p_capacity

## Current slots used (sum of all item slot_sizes).
func slots_used() -> int:
	var total := 0
	for item in _items:
		total += item.slot_size
	return total

func is_over_capacity() -> bool:
	return slots_used() > capacity

func get_items() -> Array[InventoryItem]:
	return _items

func item_count() -> int:
	return _items.size()

## Add an item. Returns true on success (always succeeds; overflow is allowed but flagged).
func add(item: InventoryItem) -> bool:
	_items.append(item)
	changed.emit()
	return true

## Remove item by reference. Returns true if found and removed.
func remove(item: InventoryItem) -> bool:
	var idx := _items.find(item)
	if idx == -1:
		return false
	_items.remove_at(idx)
	changed.emit()
	return true

## Move item to the top of the list (index 0 = highest priority).
func send_to_top(item: InventoryItem) -> void:
	var idx := _items.find(item)
	if idx <= 0:
		return
	_items.remove_at(idx)
	_items.insert(0, item)
	changed.emit()

## Move item to the bottom of the list.
func send_to_bottom(item: InventoryItem) -> void:
	var idx := _items.find(item)
	if idx == -1 or idx == _items.size() - 1:
		return
	_items.remove_at(idx)
	_items.append(item)
	changed.emit()
