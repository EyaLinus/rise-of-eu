extends Node2D
## One piece of the world-space map (a province's fill, the borders, the roads, the cities or the sea
## routes). The pieces sit behind MapView's own drawing inside one container that follows pan and
## zoom through its transform, so panning only moves them. MapView redraws a piece only when what
## it shows has changed (see MapView.refresh() and refresh_after_tick()).

var map
var kind := ""  # "bg", "prov", "borders", "roads", "cities", "sea"
var pid := -1
var sig = null  # what the piece showed when it was last drawn


func _draw() -> void:
	map._draw_layer(self)
