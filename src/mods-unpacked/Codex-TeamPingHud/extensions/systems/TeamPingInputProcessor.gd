extends InputProcessor

var state_path: NodePath
var state: Node
var config: Dictionary = {}
var action_name: String = ""
var pressed_at_msec_by_device: Dictionary = {}

func _ready() -> void:
	stopWithPredecessor = false
	stopSuccessors = false

func setup(in_state_path: NodePath, in_config: Dictionary, in_action_name: String) -> void:
	state_path = in_state_path
	config = in_config.duplicate(true)
	action_name = in_action_name

func configure(in_config: Dictionary) -> void:
	config = in_config.duplicate(true)

func buttonEvent(event: InputEvent) -> bool:
	if not bool(config.get("enabled", true)):
		return false
	if not (StageManager.isInLoadout() or StageManager.isInLevel()) or GameWorld.paused:
		return false
	if not InputMap.event_is_action(event, action_name):
		return false

	if event is InputEventKey and event.echo:
		return true

	var device_id: int = InputSystem.getDeviceIndex(event)
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton:
		if event.pressed:
			pressed_at_msec_by_device[device_id] = Time.get_ticks_msec()
		else:
			var started_at: int = int(pressed_at_msec_by_device.get(device_id, Time.get_ticks_msec()))
			pressed_at_msec_by_device.erase(device_id)
			var held_seconds: float = float(Time.get_ticks_msec() - started_at) / 1000.0
			ModLoaderLog.debug(
				"Ping key released by device %s after %.2fs" % [device_id, held_seconds],
				"Codex-TeamPingHud"
			)
			_request_ping(device_id, held_seconds >= float(config.get("hold_threshold_seconds", 0.45)))
		return true

	return false

func stick_move(_event: InputEventJoypadMotion) -> bool:
	return false

func _request_ping(device_id: int, is_long_ping: bool) -> void:
	var keeper: Keeper = Keepers.getLocalKeeperByDeviceId(device_id)
	if not keeper and Keepers.local.getCount() == 1:
		keeper = Keepers.local.first()
	if not is_instance_valid(keeper):
		ModLoaderLog.warning("Ping input had no matching local keeper for device id %s" % device_id, "Codex-TeamPingHud")
		return

	_resolve_state()
	if not is_instance_valid(state):
		ModLoaderLog.warning("Ping input could not resolve synchronizer", "Codex-TeamPingHud")
		return

	state.request_ping(keeper.playerId, keeper.global_position, is_long_ping)

func _resolve_state() -> void:
	if is_instance_valid(state):
		return
	state = get_node_or_null(state_path)

func clearInput() -> void:
	pressed_at_msec_by_device.clear()
