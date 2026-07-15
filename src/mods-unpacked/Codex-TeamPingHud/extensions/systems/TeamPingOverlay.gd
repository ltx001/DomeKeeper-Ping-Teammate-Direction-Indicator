extends Control

const TEAMMATE_COLOR := Color(0.25, 0.82, 1.0, 0.75)
const PING_COLOR := Color(1.0, 0.78, 0.22, 0.75)
const SHADOW_COLOR := Color(0.0, 0.0, 0.0, 0.35)

var player_id: String
var team_id: String
var state_path: NodePath
var state: Node
var config: Dictionary = {}

func setup(in_player_id: String, in_team_id: String, in_state_path: NodePath, in_config: Dictionary) -> void:
	player_id = in_player_id
	team_id = in_team_id
	state_path = in_state_path
	configure(in_config)
	_resolve_state()

func configure(in_config: Dictionary) -> void:
	config = in_config.duplicate(true)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 2000
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_resolve_state()
	set_process(true)

func _process(_delta: float) -> void:
	if is_instance_valid(get_parent()):
		size = get_parent().size
	queue_redraw()

func _draw() -> void:
	if not bool(config.get("enabled", true)):
		return
	if not (StageManager.isInLoadout() or StageManager.isInLevel()):
		return
	if size.x <= 2.0 or size.y <= 2.0:
		return

	if bool(config.get("show_teammate_arrows", true)):
		_draw_teammates()
	if bool(config.get("show_ping_arrows", true)):
		_draw_pings()

func _draw_teammates() -> void:
	for keeper: Keeper in Keepers.getAllOfTeam(team_id):
		if not is_instance_valid(keeper):
			continue
		if keeper.playerId == player_id:
			continue
		_draw_world_target(keeper.global_position, TEAMMATE_COLOR, false)

func _draw_pings() -> void:
	_resolve_state()
	if not is_instance_valid(state):
		return

	for ping in state.get_pings_for_team(team_id):
		_draw_world_target(
			ping.get("position", Vector2.ZERO),
			PING_COLOR,
			bool(config.get("show_on_screen_pings", true))
		)

func _draw_world_target(world_position: Vector2, color: Color, draw_when_on_screen: bool) -> void:
	var screen_position: Vector2 = _world_to_overlay_position(world_position)
	if screen_position == Vector2.INF:
		return

	var visible_rect: Rect2 = Rect2(Vector2.ZERO, size)
	if visible_rect.has_point(screen_position):
		if draw_when_on_screen:
			_draw_ping_marker(screen_position, color)
		return

	var center: Vector2 = size * 0.5
	var direction: Vector2 = screen_position - center
	if direction.length_squared() <= 0.001:
		return

	var arrow_size: float = max(12.0, float(config.get("arrow_size_pixels", 20.0)))
	var margin: float = float(config.get("edge_margin_pixels", 24.0)) + arrow_size * 0.68
	var edge_position: Vector2 = _edge_position(direction, margin)
	_draw_chevron(edge_position, direction.angle(), color)

func _world_to_overlay_position(world_position: Vector2) -> Vector2:
	var cam: Camera2D = _get_player_camera()
	if not is_instance_valid(cam):
		return Vector2.INF

	var ui_scale: float = max(0.01, _get_ui_scale())
	var viewport_position: Vector2 = cam.get_viewport().get_canvas_transform() * world_position
	return viewport_position / ui_scale

func _get_player_camera() -> Camera2D:
	if is_instance_valid(Level.viewports) and Keepers.hasKeeper(player_id):
		var keeper: Keeper = Keepers.getKeeper(player_id)
		var viewport_container = Level.viewports.getViewportContainer(keeper)
		if is_instance_valid(viewport_container) and is_instance_valid(viewport_container.camera):
			return viewport_container.camera
	return InputSystem.getCamera(player_id)

func _get_ui_scale() -> float:
	var area_limiter: Node = get_parent()
	if not area_limiter:
		return 1.0
	var player_canvas: Node = area_limiter.get_parent()
	if not player_canvas:
		return 1.0
	var value = player_canvas.get("scaling")
	if typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT:
		return float(value)
	return 1.0

func _edge_position(direction: Vector2, margin: float) -> Vector2:
	var center: Vector2 = size * 0.5
	var max_margin: float = max(1.0, min(size.x, size.y) * 0.45)
	var safe_margin: float = min(margin, max_margin)
	var half: Vector2 = (size * 0.5) - Vector2(safe_margin, safe_margin)
	var scale_x: float = INF if abs(direction.x) < 0.001 else half.x / abs(direction.x)
	var scale_y: float = INF if abs(direction.y) < 0.001 else half.y / abs(direction.y)
	return center + direction * min(scale_x, scale_y)

func _draw_chevron(position: Vector2, angle: float, color: Color) -> void:
	var arrow_size: float = float(config.get("arrow_size_pixels", 20.0))
	var half_height: float = arrow_size * 0.55
	var half_width: float = arrow_size * 0.45
	var local_points: Array[Vector2] = [
		Vector2(-half_width, -half_height),
		Vector2(half_width, 0.0),
		Vector2(-half_width, half_height)
	]

	var points: PackedVector2Array = PackedVector2Array()
	for point in local_points:
		points.append(position + point.rotated(angle))

	draw_polyline(points, SHADOW_COLOR, 5.0, true)
	draw_polyline(points, color, 3.0, true)

func _draw_ping_marker(position: Vector2, color: Color) -> void:
	var radius: float = max(5.0, float(config.get("arrow_size_pixels", 20.0)) * 0.45)
	var diamond: PackedVector2Array = PackedVector2Array([
		position + Vector2(0.0, -radius),
		position + Vector2(radius, 0.0),
		position + Vector2(0.0, radius),
		position + Vector2(-radius, 0.0)
	])
	var outline: PackedVector2Array = PackedVector2Array(diamond)
	outline.append(diamond[0])
	draw_polyline(outline, SHADOW_COLOR, 4.0, true)
	draw_polyline(outline, color, 2.5, true)

func _resolve_state() -> void:
	if is_instance_valid(state):
		return
	state = get_node_or_null(state_path)
