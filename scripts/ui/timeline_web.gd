extends Control

func _ready() -> void:
	GameManager.state_changed.connect(queue_redraw)

func _draw() -> void:
	_draw_connection("antiquity", "middle_ages")
	_draw_connection("middle_ages", "industrial")
	_draw_connection("industrial", "future")

func _draw_connection(from_id: String, to_id: String) -> void:
	var from_node = _get_node_by_id(from_id)
	var to_node = _get_node_by_id(to_id)

	if from_node and to_node:
		var from_pos = from_node.position + from_node.size / 2
		var to_pos = to_node.position + to_node.size / 2

		var stability = GameManager.state.nodes[from_id].stability
		var color = Color(0, 1, 0, 0.5) # Green
		if GameManager.state.nodes[from_id].is_mutated:
			color = Color(1, 0, 0, 0.8) # Red
		elif stability < 50:
			color = Color(1, 1, 0, 0.5) # Yellow

		draw_line(from_pos, to_pos, color, 4.0)

func _get_node_by_id(id: String) -> Control:
	for child in $Nodes.get_children():
		if child.has_method("get") and child.get("node_id") == id:
			return child
	return null
