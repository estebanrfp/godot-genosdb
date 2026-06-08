# 🌾 godot-genosdb — Serverless P2P multiplayer for Godot (Web)

Add **real-time, peer-to-peer multiplayer** to a Godot game exported to the Web
with **zero servers**, using [GenosDB](https://github.com/estebanrfp/GenosDB)
(WebRTC data channels + a reactive, persistent graph database that runs entirely
in the browser).

**▶ Live demo:** https://estebanrfp.github.io/godot-genosdb/ — open it in **two
tabs**: each shows the other farmer moving, and **a tree you chop falls in every
window** (and stays fallen, even for someone who joins later).

<!-- ![demo](docs-media/demo.gif) -->

## 📦 What's in this repo

| Path | What |
|---|---|
| **`addons/godot_genosdb/`** | The **plugin** (drop-in Godot 4 addon) → [plugin docs](addons/godot_genosdb/README.md) |
| `scenes/`, `scripts/`, `assets/`, `project.godot` | **The demo's full source** (the co-op farm) |
| **`docs/`** | The **exported Web build** (this is what GitHub Pages serves) |
| `web/build.sh`, `web/serve.py` | Build & local-serve helpers |

---

## 📥 Install the plugin in YOUR game (3 steps)

1. **Copy the folder** `addons/godot_genosdb/` into your own project's `addons/`
   folder (create `addons/` if it doesn't exist).
2. In Godot: **Project → Project Settings → Plugins**, find **“GenosDB for
   Godot”** and switch it to **Enabled**.
3. **Export to Web** (Project → Export → Web; renderer **GL Compatibility**
   recommended). The plugin **auto-injects** the GenosDB bridge into your
   exported `index.html` — you don't edit any HTML.

> No npm, no bundling: the bridge loads GenosDB from a CDN. No signaling server:
> GenosDB uses decentralized Nostr relays.

### Use it in code

```gdscript
func _ready():
    Net.peer_joined.connect(func(id): spawn_remote(id))
    Net.peer_left.connect(func(id): remove_remote(id))
    Net.message_received.connect(_on_state)   # ephemeral (fast)
    Net.graph_changed.connect(_on_world)      # persistent (synced + stored)
    Net.join("my-room")                        # same id = same world

func _physics_process(_d):
    Net.broadcast({ "x": position.x, "y": position.y })   # positions to all peers

func chop_tree():
    Net.db_put("tree_3", { "type": "tree", "hp": 0 })     # shared world state
```

| Need | Method | Signal |
|---|---|---|
| Fast, throwaway (positions, cursors) | `Net.broadcast(dict)` | `message_received(id, data)` |
| Shared world state (objects, scores) | `Net.db_put(id, dict)` / `Net.db_remove(id)` | `graph_changed(id, action, data)` |

Full API: **[addons/godot_genosdb/README.md](addons/godot_genosdb/README.md)**.

---

## ▶ Run the demo

**Editor (single-player):** open the project in **Godot 4.6+** and press ▶.
Move with **WASD/arrows**, chop trees with **E / Space**. (P2P is Web-only, so in
the editor it runs as a normal single-player game.)

**Web (multiplayer), locally:**
```bash
GODOT=/path/to/Godot ./web/build.sh        # exports into docs/
python3 docs/serve.py 8088                 # open http://127.0.0.1:8088 in two tabs
```
Or just open the **live demo** above.

## 🧠 How it works (the hybrid model)

GenosDB isn't only WebRTC — it's a **reactive graph database** that syncs P2P
**and persists**. So the demo uses both layers, the recommended GenosDB pattern:

- **Ephemeral** — player positions over a GenosRTC **data channel** (fast, ~16 Hz).
- **Persistent** — tree state in the GenosDB **graph**; a **late-joiner gets the
  current world automatically** (via the `initial` action) and chops survive reloads.

## 🛠 Tech

- **Godot 4.6** — GL Compatibility, Web export, no threads → any static host.
- **GenosDB / GenosRTC** — loaded from CDN; auto-injected on export.

## Author

Esteban Fuster Pozzi (@estebanrfp) — Full Stack JavaScript Developer

## License

[MIT](LICENSE)
