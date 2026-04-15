class_name Inventory
extends RefCounted

## General-purpose item pool. Items are stored in display order; groups of items
## sharing the same data reference are always contiguous in the list.

## Emitted whenever the item list changes.
signal changed

var _items: Array[InventoryItem] = []

func get_items() -> Array[InventoryItem]:
	return _items

func item_count() -> int:
	return _items.size()

## Add an item at the end of the list.
func add(item: InventoryItem) -> bool:
	_items.append(item)
	changed.emit()
	return true

## Remove item by reference. Returns true if found and removed.
func remove(item: InventoryItem) -> bool:
	var idx: int = _items.find(item)
	if idx == -1:
		return false
	_items.remove_at(idx)
	changed.emit()
	return true

## Move item (and all items sharing its data reference) to just before ref_item's group.
## If ref_item is null, the group is moved to the end of the list.
## If item is not yet in the list, it is added before repositioning.
func move_group_before(item: InventoryItem, ref_item: InventoryItem) -> void:
	if not item in _items:
		_items.append(item)
	# Collect all members of this group.
	var group: Array[InventoryItem] = []
	for i: InventoryItem in _items:
		if i.data == item.data:
			group.append(i)
	# Find flat insertion index: the position of ref_item, or end-of-list if null.
	var insert_idx: int
	if ref_item == null:
		insert_idx = _items.size()
	else:
		insert_idx = _items.find(ref_item)
		if insert_idx == -1:
			insert_idx = _items.size()
	# Remove group members, adjusting insert_idx for each earlier removal.
	for gi: InventoryItem in group:
		var gi_idx: int = _items.find(gi)
		if gi_idx < insert_idx:
			insert_idx -= 1
		_items.erase(gi)
	insert_idx = clampi(insert_idx, 0, _items.size())
	# Reinsert group at the computed position.
	for i: int in group.size():
		_items.insert(insert_idx + i, group[i])
	changed.emit()
