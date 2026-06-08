# GenosDB for Godot

Serverless **P2P multiplayer** for Godot **Web** exports, powered by
[GenosDB](https://github.com/estebanrfp/GenosDB) (GenosRTC data channels + a
reactive, persistent graph). No backend, no signaling server to run.

The API **mirrors GenosDB on purpose** — using this plugin teaches you the real
GenosDB API.

## Install

1. Copy `addons/godot_genosdb/` into your project's `addons/` folder.
2. **Project → Project Settings → Plugins → GenosDB for Godot → Enable.**
3. Export to **Web** (renderer: *GL Compatibility* recommended).

The plugin auto-registers the `Net` autoload and auto-injects the JS bridge
(which loads GenosDB from a CDN) into your exported `index.html`.

## Quickstart

```gdscript
func _ready() -> void:
    Net.peer_join.connect(func(id): print("joined: ", id))
    Net.peer_leave.connect(func(id): print("left: ", id))
    Net.message.connect(_on_message)          # ephemeral (fast)
    Net.graph_changed.connect(_on_graph)      # persistent (synced + stored)
    Net.join("my-room")                        # same id = same world
    Net.map({})                                # subscribe to the shared graph

func _physics_process(_d):
    Net.send({ "x": position.x, "y": position.y })   # broadcast to all peers

func _on_message(id: String, data: Dictionary): ...   # remote broadcasts

# Persistent shared state (survives reloads; late-joiners get it via 'initial'):
func chop_tree(): Net.put({ "type": "tree", "hp": 0 }, "tree_3")
func _on_graph(id, action, data): ...   # action: initial|added|updated|removed
```

## It mirrors GenosDB

| GenosDB (JS) | `Net` (Godot) | Layer |
|---|---|---|
| `await gdb(name, {rtc:true})` | `Net.join(name)` | room |
| `room.on('peer:join' / 'peer:leave')` | signal `peer_join(id)` / `peer_leave(id)` | room |
| `channel.send(data)` | `Net.send(data)` | ephemeral |
| `channel.on('message', cb)` | signal `message(id, data)` | ephemeral |
| `db.put(node, id)` | `Net.put(data, id)` | graph |
| `db.remove(id)` | `Net.remove(id)` | graph |
| `db.map(query, cb)` | `Net.map(query)` + signal `graph_changed(id, action, data)` | graph |

> `db.get()` isn't exposed because Godot's `Object.get()` would collide — use a
> `map()` subscription for reads (it also covers late-joiners automatically).

## Pick the right layer

| Need | Use |
|---|---|
| Fast, throwaway (positions, cursors) | `Net.send(dict)` → `message` |
| Shared world state (objects, scores) | `Net.put(dict, id)` / `Net.remove(id)` → `graph_changed` |

All methods are safe no-ops off the Web, so the same code runs in the editor and
on desktop (single-player) and lights up P2P only on the Web build.

## Author

Esteban Fuster Pozzi (@estebanrfp) — Full Stack JavaScript Developer

## License

MIT
