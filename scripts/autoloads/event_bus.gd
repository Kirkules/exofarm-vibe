extends Node

# Grid events
signal piece_placed(piece_id: int, row: int, col: int)
signal piece_removed(piece_id: int)
signal piece_picked_up(piece_id: int)

# Season events
signal season_confirmed()
signal simulation_complete()

# State events
signal morale_changed(new_value: int)
signal settler_count_changed(new_count: int)
