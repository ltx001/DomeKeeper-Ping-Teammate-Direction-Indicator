extends Synchronizer

signal pings_changed

var pings_by_player_id: Dictionary = {}
var config: Dictionary = {}

func _ready() -> void:
	add_to_group("codex_team_ping_state")
	target_connection_states = [
		Network.ConnectionState.LOADOUT_STAGE_SPAWN,
		Network.ConnectionState.LOADOUT_STAGE_SYNC,
		Network.ConnectionState.LEVEL_STAGE_SPAWN,
		Network.ConnectionState.LEVEL_STAGE_SYNC
	]
	reliable = true
	periodic_full_syncs = true
	ticks_between_full_sync = 180
	super._ready()
	set_process(true)

func configure(in_config: Dictionary) -> void:
	config = in_config.duplicate(true)

func reset_for_level(in_config: Dictionary) -> void:
	configure(in_config)
	pings_by_player_id.clear()
	inital_syncs.clear()
	full_sync_next_tick = true
	pings_changed.emit()

func request_ping(player_id: String, world_position: Vector2, is_long_ping: bool) -> void:
	if not bool(config.get("enabled", true)):
		return

	var duration: float = float(config.get("long_ping_seconds", 300.0) if is_long_ping else config.get("short_ping_seconds", 60.0))
	rpc_server(_server_request_ping.bind(player_id, world_position, duration))

@rpc("reliable", "any_peer")
func _server_request_ping(player_id: String, world_position: Vector2, duration_seconds: float) -> void:
	if not _is_valid_ping_owner(player_id):
		return
	if not Keepers.hasKeeper(player_id):
		return

	var existing: Dictionary = pings_by_player_id.get(player_id, {})
	var cancel_radius: float = float(config.get("cancel_radius_pixels", 48.0))
	if not existing.is_empty() and (existing.get("position", Vector2.INF) as Vector2).distance_to(world_position) <= cancel_radius:
		_broadcast_remove_ping(player_id)
		return

	var keeper: Keeper = Keepers.getKeeper(player_id)
	_broadcast_set_ping(player_id, keeper.teamId, keeper.playerName, world_position, duration_seconds)

func _is_valid_ping_owner(player_id: String) -> bool:
	if not Keepers.hasKeeper(player_id):
		return false
	var keeper: Keeper = Keepers.getKeeper(player_id)
	var sender_peer_id: int = multiplayer.get_remote_sender_id()
	if sender_peer_id != 0 and keeper.peerId != sender_peer_id:
		return false
	return true

func _broadcast_set_ping(player_id: String, team_id: String, player_name: String, world_position: Vector2, duration_seconds: float) -> void:
	network_rpc(_network_set_ping.bind(player_id, team_id, player_name, world_position, duration_seconds), true)

func _broadcast_remove_ping(player_id: String) -> void:
	network_rpc(_network_remove_ping.bind(player_id), true)

@rpc("reliable")
func _network_set_ping(player_id: String, team_id: String, player_name: String, world_position: Vector2, duration_seconds: float) -> void:
	pings_by_player_id[player_id] = {
		"player_id": player_id,
		"team_id": team_id,
		"player_name": player_name,
		"position": world_position,
		"expires_at_msec": Time.get_ticks_msec() + int(max(0.1, duration_seconds) * 1000.0)
	}
	pings_changed.emit()

@rpc("reliable")
func _network_remove_ping(player_id: String) -> void:
	if pings_by_player_id.erase(player_id):
		pings_changed.emit()

func get_pings_for_team(team_id: String) -> Array:
	var out: Array = []
	for ping in pings_by_player_id.values():
		if ping.get("team_id", "") == team_id:
			out.append(ping)
	return out

func get_initial_data(_peer_id: int) -> PackedByteArray:
	var data: Array = []
	var now: int = Time.get_ticks_msec()
	for ping in pings_by_player_id.values():
		var remaining_seconds: float = max(0.0, float(int(ping.get("expires_at_msec", now)) - now) / 1000.0)
		if remaining_seconds <= 0.0:
			continue
		data.append({
			"player_id": ping.get("player_id", ""),
			"team_id": ping.get("team_id", ""),
			"player_name": ping.get("player_name", ""),
			"position": ping.get("position", Vector2.ZERO),
			"duration_seconds": remaining_seconds
		})

	if data.is_empty():
		return PackedByteArray()
	return var_to_bytes(data)

func set_initial_data(buffer: PackedByteArray) -> void:
	pings_by_player_id.clear()
	var data: Array = bytes_to_var(buffer)
	for ping in data:
		_network_set_ping(
			ping.get("player_id", ""),
			ping.get("team_id", ""),
			ping.get("player_name", ""),
			ping.get("position", Vector2.ZERO),
			float(ping.get("duration_seconds", 0.0))
		)
	pings_changed.emit()

func get_full_sync_data(peer_id: int) -> PackedByteArray:
	return get_initial_data(peer_id)

func set_full_sync_data(buffer: PackedByteArray) -> void:
	set_initial_data(buffer)

func _process(_delta: float) -> void:
	if pings_by_player_id.is_empty():
		return

	var now: int = Time.get_ticks_msec()
	var expired: Array[String] = []
	for player_id in pings_by_player_id.keys():
		if int(pings_by_player_id[player_id].get("expires_at_msec", now)) <= now:
			expired.append(player_id)

	if expired.is_empty():
		return

	if multiplayer.is_server():
		for player_id in expired:
			_broadcast_remove_ping(player_id)
	else:
		for player_id in expired:
			pings_by_player_id.erase(player_id)
		pings_changed.emit()
