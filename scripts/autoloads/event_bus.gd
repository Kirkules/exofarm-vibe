extends Node
class_name EventBus

# Grid events
signal piece_placed(piece_id: int, row: int, col: int)
signal piece_removed(piece_id: int)
signal piece_picked_up(piece_id: int)

# Season events
signal season_confirmed()
signal simulation_complete()
signal simulation_started()
signal simulation_ended()
signal merge_grid_opened(grid: GameGrid)
signal merge_grid_closed()

# UI overlay events
signal log_overlay_opened()
signal log_overlay_closed()

# State events
signal morale_changed(new_value: int)
signal settler_count_changed(new_count: int)
