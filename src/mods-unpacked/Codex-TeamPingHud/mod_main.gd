extends Node

const MOD_ID := "Codex-TeamPingHud"
const LOG_NAME := "Codex-TeamPingHud"
const INPUT_ACTION := "codex_team_ping"

const INPUT_SCRIPT := "res://mods-unpacked/Codex-TeamPingHud/extensions/systems/TeamPingInputProcessor.gd"
const OVERLAY_SCRIPT := "res://mods-unpacked/Codex-TeamPingHud/extensions/systems/TeamPingOverlay.gd"
const SYNCHRONIZER_SCRIPT := "res://mods-unpacked/Codex-TeamPingHud/extensions/systems/TeamPingSynchronizer.gd"
const KEY_BINDINGS_EXTENSION := "res://mods-unpacked/Codex-TeamPingHud/extensions/systems/options/KeyBindingsPanel.gd"

const DEFAULT_CONFIG := {
	"enabled": true,
	"show_teammate_arrows": true,
	"show_ping_arrows": true,
	"show_on_screen_pings": true,
	"hold_threshold_seconds": 0.45,
	"short_ping_seconds": 60.0,
	"long_ping_seconds": 300.0,
	"cancel_radius_pixels": 48.0,
	"edge_margin_pixels": 24.0,
	"arrow_size_pixels": 20.0
}

var config: Dictionary = DEFAULT_CONFIG.duplicate(true)
var _input_processor: InputProcessor
var _synchronizer: Node
var _overlays_by_player_id: Dictionary = {}
var _bound_stage_instance_id: int = 0
var _input_script: GDScript
var _overlay_script: GDScript
var _synchronizer_script: GDScript

func _init() -> void:
	ModLoaderLog.info("Init", LOG_NAME)
	ModLoaderMod.install_script_extension(KEY_BINDINGS_EXTENSION)

func _ready() -> void:
	ModLoaderLog.info("Ready", LOG_NAME)
	add_to_group("mod_init")
	add_to_group("codex_team_ping_hud_mod")
	_load_config()
	_install_input_action()
	if not _load_runtime_scripts():
		return

	var config_changed: Callable = Callable(self, "_on_current_config_changed")
	if not ModLoader.current_config_changed.is_connected(config_changed):
		ModLoader.current_config_changed.connect(config_changed)

	if not StageManager.level_ready.is_connected(_on_level_ready):
		StageManager.level_ready.connect(_on_level_ready)
	if not StageManager.stage_started.is_connected(_on_stage_started):
		StageManager.stage_started.connect(_on_stage_started)

	if not Keepers.local_keeper_registered.is_connected(_on_local_keeper_registered):
		Keepers.local_keeper_registered.connect(_on_local_keeper_registered)
	if not Keepers.local_keeper_replaced.is_connected(_on_local_keeper_replaced):
		Keepers.local_keeper_replaced.connect(_on_local_keeper_replaced)
	if not Keepers.local_keeper_unregistered.is_connected(_on_local_keeper_unregistered):
		Keepers.local_keeper_unregistered.connect(_on_local_keeper_unregistered)

	_prepare_current_gameplay_stage.call_deferred()

func modInit() -> void:
	pass

func _load_runtime_scripts() -> bool:
	_input_script = load(INPUT_SCRIPT)
	_overlay_script = load(OVERLAY_SCRIPT)
	_synchronizer_script = load(SYNCHRONIZER_SCRIPT)

	var scripts: Dictionary = {
		"input": _input_script,
		"overlay": _overlay_script,
		"synchronizer": _synchronizer_script
	}
	for script_name in scripts:
		var script: GDScript = scripts[script_name]
		if not script or not script.can_instantiate():
			ModLoaderLog.error("Failed to load %s runtime script" % script_name, LOG_NAME)
			return false

	ModLoaderLog.info("Runtime scripts validated", LOG_NAME)
	return true

func _load_config() -> void:
	config = DEFAULT_CONFIG.duplicate(true)
	if not ModLoaderStore.mod_data.has(MOD_ID):
		return

	var mod_config: ModConfig = ModLoaderConfig.get_current_config(MOD_ID)
	if not mod_config:
		return

	for key in DEFAULT_CONFIG.keys():
		if mod_config.data.has(key):
			config[key] = mod_config.data[key]

func _on_current_config_changed(mod_config: ModConfig) -> void:
	if mod_config.mod_id != MOD_ID:
		return
	_load_config()
	if is_instance_valid(_synchronizer):
		_synchronizer.configure(config)
	for overlay in _overlays_by_player_id.values():
		if is_instance_valid(overlay):
			overlay.configure(config)

func _install_input_action(force_defaults: bool = false) -> void:
	_register_options_keybinding()

	if not InputMap.has_action(INPUT_ACTION):
		InputMap.add_action(INPUT_ACTION)

	if force_defaults or InputMap.action_get_events(INPUT_ACTION).is_empty():
		InputMap.action_erase_events(INPUT_ACTION)
		_add_default_input_events()

	if not force_defaults:
		# The Options singleton loaded bindings before this mod action existed.
		# Loading again lets the native keybinding screen remain the source of truth.
		Options.loadKeyBindings()

func _register_options_keybinding() -> void:
	if Options.INPUT_ACTIONS.has("ui") and not Options.INPUT_ACTIONS["ui"].has(INPUT_ACTION):
		Options.INPUT_ACTIONS["ui"].append(INPUT_ACTION)

	# Vanilla lacks labels for stick-click buttons on some controller layouts.
	Options.GamepadTranslationsPs4["7"] = "L3"
	Options.GamepadTranslationsPs4["8"] = "R3"
	Options.GamepadTranslationsSwitchPro["7"] = "LS"
	Options.GamepadTranslationsSwitchPro["8"] = "RS"

func _add_default_input_events() -> void:
	var mouse_event: InputEventMouseButton = InputEventMouseButton.new()
	mouse_event.button_index = MOUSE_BUTTON_MIDDLE
	InputMap.action_add_event(INPUT_ACTION, mouse_event)

	var gamepad_event: InputEventJoypadButton = InputEventJoypadButton.new()
	gamepad_event.device = -1
	gamepad_event.button_index = JOY_BUTTON_RIGHT_STICK
	InputMap.action_add_event(INPUT_ACTION, gamepad_event)

func reset_ping_binding_to_default() -> void:
	_install_input_action(true)

func _on_level_ready() -> void:
	_prepare_current_gameplay_stage()

func _on_stage_started() -> void:
	if not _is_supported_gameplay_stage():
		_bound_stage_instance_id = 0
		_input_processor = null
		_overlays_by_player_id.clear()
		return
	_prepare_current_gameplay_stage.call_deferred()

func _prepare_current_gameplay_stage() -> void:
	if not _is_supported_gameplay_stage():
		return
	if not is_instance_valid(Level.stage) or not is_instance_valid(Level.viewports):
		return

	var stage_instance_id: int = Level.stage.get_instance_id()
	if _bound_stage_instance_id != stage_instance_id:
		_bound_stage_instance_id = stage_instance_id
		_input_processor = null
		_overlays_by_player_id.clear()
		_ensure_synchronizer()
		_synchronizer.reset_for_level(config)
		_install_input_processor()
		ModLoaderLog.info(
			"Bound to gameplay stage %s" % Level.stage.get_script().resource_path,
			LOG_NAME
		)

	_install_overlays.call_deferred()

func _is_supported_gameplay_stage() -> bool:
	return StageManager.isInLoadout() or StageManager.isInLevel()

func _ensure_stage_binding() -> bool:
	if not _is_supported_gameplay_stage():
		return false
	if not is_instance_valid(Level.stage) or not is_instance_valid(Level.viewports):
		return false
	if _bound_stage_instance_id != Level.stage.get_instance_id():
		_prepare_current_gameplay_stage()
	return _bound_stage_instance_id == Level.stage.get_instance_id()

func _ensure_synchronizer() -> void:
	if is_instance_valid(_synchronizer):
		return

	_synchronizer = _synchronizer_script.new()
	_synchronizer.name = "TeamPingSynchronizer"
	add_child(_synchronizer)
	_synchronizer.configure(config)

func _install_input_processor() -> void:
	if is_instance_valid(_input_processor):
		if _input_processor.get_parent() == Level.stage:
			_input_processor.configure(config)
			return
		_input_processor = null

	_input_processor = _input_script.new()
	_input_processor.setup(_synchronizer.get_path(), config, INPUT_ACTION)
	_input_processor.deviceId = -1
	_input_processor.globalInput = true
	_input_processor.integrate(Level.stage)
	ModLoaderLog.info("Installed global ping input processor", LOG_NAME)

func _install_overlays() -> void:
	if not _ensure_stage_binding():
		return

	ModLoaderLog.info("Installing overlays for %s local keeper(s)" % Keepers.local.getCount(), LOG_NAME)
	for keeper: Keeper in Keepers.local.getAll():
		_add_overlay_for_keeper(keeper)

func _add_overlay_for_keeper(keeper: Keeper) -> void:
	if not is_instance_valid(keeper) or not is_instance_valid(Level.viewports):
		return
	if _overlays_by_player_id.has(keeper.playerId) and is_instance_valid(_overlays_by_player_id[keeper.playerId]):
		return

	var viewport_container: ViewportContainer = Level.viewports.getViewportContainer(keeper)
	if not viewport_container:
		ModLoaderLog.warning("No viewport container found for local player %s" % keeper.playerId, LOG_NAME)
		return

	var player_canvas: PlayerCanvas = viewport_container.getPlayerUICanvas()
	if not player_canvas:
		ModLoaderLog.warning("No player canvas found for local player %s" % keeper.playerId, LOG_NAME)
		return

	var overlay: Control = _overlay_script.new()
	overlay.name = "TeamPingOverlay_%s" % keeper.playerId
	overlay.setup(keeper.playerId, keeper.teamId, _synchronizer.get_path(), config)
	player_canvas.add_popup(overlay)
	_overlays_by_player_id[keeper.playerId] = overlay
	ModLoaderLog.info("Installed overlay for local player %s on team %s" % [keeper.playerId, keeper.teamId], LOG_NAME)

func _on_local_keeper_registered(keeper: Keeper) -> void:
	if _is_supported_gameplay_stage():
		_prepare_current_gameplay_stage.call_deferred()
		_add_overlay_for_keeper.call_deferred(keeper)

func _on_local_keeper_replaced(keeper: Keeper) -> void:
	if not _ensure_stage_binding():
		return
	if _overlays_by_player_id.has(keeper.playerId) and is_instance_valid(_overlays_by_player_id[keeper.playerId]):
		_overlays_by_player_id[keeper.playerId].setup(keeper.playerId, keeper.teamId, _synchronizer.get_path(), config)
	else:
		_add_overlay_for_keeper.call_deferred(keeper)

func _on_local_keeper_unregistered(keeper: Keeper) -> void:
	var overlay = _overlays_by_player_id.get(keeper.playerId)
	if is_instance_valid(overlay):
		overlay.queue_free()
	_overlays_by_player_id.erase(keeper.playerId)
