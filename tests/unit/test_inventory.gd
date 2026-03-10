# Requires the GUT plugin: https://github.com/bitwes/Gut
extends GutTest

# ---------------------------------------------------------------------------
# Basic add / remove
# ---------------------------------------------------------------------------

func test_empty_inventory_has_zero_items() -> void:
	var inv := Inventory.new(10)
	assert_eq(inv.item_count(), 0)

func test_add_item_increases_count() -> void:
	var inv := Inventory.new(10)
	var item := InventoryItem.new("Widget", 1)
	inv.add(item)
	assert_eq(inv.item_count(), 1)

func test_remove_item_decreases_count() -> void:
	var inv := Inventory.new(10)
	var item := InventoryItem.new("Widget", 1)
	inv.add(item)
	inv.remove(item)
	assert_eq(inv.item_count(), 0)

func test_remove_nonexistent_returns_false() -> void:
	var inv := Inventory.new(10)
	var item := InventoryItem.new("Ghost", 1)
	assert_false(inv.remove(item))

# ---------------------------------------------------------------------------
# Slot accounting
# ---------------------------------------------------------------------------

func test_slots_used_sums_slot_sizes() -> void:
	var inv := Inventory.new(10)
	inv.add(InventoryItem.new("A", 2))
	inv.add(InventoryItem.new("B", 3))
	assert_eq(inv.slots_used(), 5)

func test_not_over_capacity_when_within_limit() -> void:
	var inv := Inventory.new(5)
	inv.add(InventoryItem.new("A", 3))
	assert_false(inv.is_over_capacity())

func test_over_capacity_when_exceeded() -> void:
	var inv := Inventory.new(3)
	inv.add(InventoryItem.new("A", 2))
	inv.add(InventoryItem.new("B", 2))
	assert_true(inv.is_over_capacity())

# ---------------------------------------------------------------------------
# Priority reordering
# ---------------------------------------------------------------------------

func test_send_to_top_moves_item_first() -> void:
	var inv := Inventory.new(10)
	var a := InventoryItem.new("A", 1)
	var b := InventoryItem.new("B", 1)
	var c := InventoryItem.new("C", 1)
	inv.add(a); inv.add(b); inv.add(c)
	inv.send_to_top(c)
	assert_eq(inv.get_items()[0], c)

func test_send_to_bottom_moves_item_last() -> void:
	var inv := Inventory.new(10)
	var a := InventoryItem.new("A", 1)
	var b := InventoryItem.new("B", 1)
	var c := InventoryItem.new("C", 1)
	inv.add(a); inv.add(b); inv.add(c)
	inv.send_to_bottom(a)
	var items := inv.get_items()
	assert_eq(items[items.size() - 1], a)

func test_send_to_top_already_first_is_noop() -> void:
	var inv := Inventory.new(10)
	var a := InventoryItem.new("A", 1)
	var b := InventoryItem.new("B", 1)
	inv.add(a); inv.add(b)
	inv.send_to_top(a)
	assert_eq(inv.get_items()[0], a)
	assert_eq(inv.item_count(), 2)

# ---------------------------------------------------------------------------
# changed signal
# ---------------------------------------------------------------------------

func test_changed_emitted_on_add() -> void:
	var inv := Inventory.new(10)
	watch_signals(inv)
	inv.add(InventoryItem.new("X", 1))
	assert_signal_emitted(inv, "changed")

func test_changed_emitted_on_remove() -> void:
	var inv := Inventory.new(10)
	var item := InventoryItem.new("X", 1)
	inv.add(item)
	watch_signals(inv)
	inv.remove(item)
	assert_signal_emitted(inv, "changed")
