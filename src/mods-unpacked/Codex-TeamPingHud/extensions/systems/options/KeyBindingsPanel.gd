extends "res://systems/options/KeyBindingsPanel.gd"

const PING_ACTION := "codex_team_ping"
const MOD_GROUP := "codex_team_ping_hud_mod"

func _ready() -> void:
	var locale: String = TranslationServer.get_locale().to_lower()
	if locale.begins_with("zh"):
		translations[PING_ACTION] = "队伍标点"
	else:
		translations[PING_ACTION] = "Team Ping"
	super()

func _on_ResetButton_pressed() -> void:
	Audio.sound("gui_select")
	InputMap.load_from_project_settings()
	var mod: Node = get_tree().get_first_node_in_group(MOD_GROUP)
	if is_instance_valid(mod):
		mod.reset_ping_binding_to_default()
	buildBindingUi()
