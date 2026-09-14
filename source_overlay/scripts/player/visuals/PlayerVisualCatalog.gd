extends RefCounted
class_name PlayerVisualCatalog

const CONFIG_PATH := "res://data/player/player_visual.json"

static func config() -> Dictionary:
    if not FileAccess.file_exists(CONFIG_PATH):
        return {}
    var f := FileAccess.open(CONFIG_PATH, FileAccess.READ)
    if f == null:
        return {}
    var parsed = JSON.parse_string(f.get_as_text())
    return parsed if typeof(parsed) == TYPE_DICTIONARY else {}

static func resolve_scene_path() -> String:
    var data := config()
    for path in data.get("candidate_paths", []):
        if ResourceLoader.exists(path):
            return str(path)
    for base in ["res://assets/external/quaternius_character", "res://assets/external/kenney_character"]:
        var found := _find_character_recursive(base)
        if not found.is_empty():
            return found
    return ""

static func _find_character_recursive(base: String) -> String:
    if not DirAccess.dir_exists_absolute(base):
        return ""
    var preferred := ["male", "man", "character", "survivor", "player"]
    var stack: Array[String] = [base]
    var fallback := ""
    while not stack.is_empty():
        var current: String = str(stack.pop_back())
        var dir := DirAccess.open(current)
        if dir == null:
            continue
        dir.list_dir_begin()
        var name := dir.get_next()
        while not name.is_empty():
            if name.begins_with("."):
                name = dir.get_next()
                continue
            var path := current.path_join(name)
            if dir.current_is_dir():
                stack.append(path)
            else:
                var lower := name.to_lower()
                if lower.ends_with(".glb") or lower.ends_with(".gltf"):
                    if fallback.is_empty():
                        fallback = path
                    for token in preferred:
                        if token in lower:
                            dir.list_dir_end()
                            return path
            name = dir.get_next()
        dir.list_dir_end()
    return fallback
