# GenosDB for Godot

Serverless **P2P multiplayer** for Godot **Web** exports, powered by
[GenosDB](https://github.com/estebanrfp/GenosDB) (GenosRTC data channels + a
reactive, persistent graph). No backend, no signaling server to run.

## Install

1. Copy `addons/godot_genosdb/` into your project's `addons/` folder.
2. **Project → Project Settings → Plugins → GenosDB for Godot → Enable.**
3. Export to **Web** (renderer: *GL Compatibility* recommended).

That's it — the plugin auto-registers the `Net` autoload and auto-injects the
JS bridge (which loads GenosDB from a CDN) into your exported `index.html`.

## Quickstart

```gdscript
func _ready() -> void:
    Net.peer_joined.connect(func(id): print("joined: ", id))
    Net.peer_left.connect(func(id): print("left: ", id))
    Net.message_received.connect(_on_message)   # ephemeral (fast)
    Net.graph_changed.connect(_on_graph)        # persistent (synced + stored)
    Net.join("my-room")                          # same id = same world

func _physics_process(_d):
    Net.broadcast({ "x": position.x, "y": position.y })   # to all peers

func _on_message(id: String, data: Dictionary): ...        # remote broadcasts

# Persistent shared state (survives reloads, late-joiners get it automatically):
func chop_tree(): Net.db_put("tree_3", { "hp": 0 })
func _on_graph(id, action, data): ...   # action: initial|added|updated|removed
```

## When to use what

| Need | Method | Signal | Notes |
|---|---|---|---|
| Fast, throwaway (positions, cursors) | `broadcast(dict)` | `message_received` | GenosRTC data channel |
| Shared world state (objects, scores) | `db_put(id, dict)` / `db_remove(id)` | `graph_changed` | GenosDB graph: persists + late-joiners get it via the `initial` action |

## API

**Methods** — `join(room_id)`, `broadcast(data)`, `db_put(id, data)`, `db_remove(id)`.
**Signals** — `peer_joined(id)`, `peer_left(id)`, `message_received(id, data)`, `graph_changed(id, action, data)`.

All methods are safe no-ops on non-Web platforms, so the same code runs in the
editor and on desktop (single-player) and lights up P2P only on the Web build.

## Author

Esteban Fuster Pozzi (@estebanrfp) — Full Stack JavaScript Developer

## License

MIT
