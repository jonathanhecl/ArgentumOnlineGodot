extends Node
class_name ConsoleCommandProcessor

static func process(newText: String) -> bool:
    var text = newText.strip_edges()
    if text.begins_with("/"):
        var parts = text.substr(1).split(" ")
        var cmd = parts[0].to_lower()
        var _args = []
        if parts.size() > 1:
            _args = parts.slice(1, parts.size())
        match cmd:
            "est":
                GameProtocol.WriteRequestStats()
            _:
                return false
        return true
    return false
