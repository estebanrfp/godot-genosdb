# 🌾 godot-genosdb — Serverless P2P multiplayer for Godot (Web)

Add **real-time, peer-to-peer multiplayer** to a Godot game exported to the Web
with **zero servers**, using [GenosDB](https://github.com/estebanrfp/GenosDB)
(WebRTC data channels + a reactive, persistent graph database that runs entirely
in the browser). The plugin's API **mirrors GenosDB**, so using it teaches you
the real GenosDB API.

**▶ Live demo:** https://estebanrfp.github.io/godot-genosdb/ — open it in **two
tabs**: each shows the other farmer moving, and **a tree you chop falls in every
window** (and stays fallen, even for someone who joins later).

<!-- ![demo](docs-media/demo.gif) -->

> 🧠 **Powered by [GenosDB](https://github.com/estebanrfp/GenosDB)** — a decentralized graph
> database that runs entirely in your browser (P2P sync + persistence, **no server**). It's
> what makes all of this possible. If this project helps you, please **⭐ [star GenosDB](https://github.com/estebanrfp/GenosDB)** to help it grow.
>
> [![Star GenosDB on GitHub](https://img.shields.io/github/stars/estebanrfp/GenosDB?style=social)](https://github.com/estebanrfp/GenosDB)

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
>
> **Production tip:** pin your own Nostr relays so it keeps working even if the
> defaults change — `Net.join("room", ["wss://your-relay.com"])`. See the
> [plugin docs](addons/godot_genosdb/README.md#custom-nostr-relays-recommended-for-production).

### Use it in code (the API mirrors GenosDB)

```gdscript
func _ready():
    Net.peer_join.connect(func(id): spawn_remote(id))
    Net.peer_leave.connect(func(id): remove_remote(id))
    Net.message.connect(_on_state)        # ephemeral (fast)
    Net.graph_changed.connect(_on_world)  # persistent (synced + stored)
    Net.join("my-room")                    # = gdb("my-room", {rtc:true})
    Net.map({})                            # = db.map({}, cb)  -> graph_changed

func _physics_process(_d):
    Net.send({ "x": position.x, "y": position.y })          # = channel.send(...)

func chop_tree():
    Net.put({ "type": "tree", "hp": 0 }, "tree_3")          # = db.put(node, id)
```

| GenosDB (JS) | `Net` (Godot) | Layer |
|---|---|---|
| `gdb(name, {rtc:true})` | `Net.join(name)` | room |
| `room.on('peer:join'/'leave')` | signal `peer_join` / `peer_leave` | room |
| `channel.send(data)` | `Net.send(data)` | ephemeral |
| `channel.on('message', cb)` | signal `message(id, data)` | ephemeral |
| `db.put(node, id)` | `Net.put(data, id)` | graph |
| `db.remove(id)` | `Net.remove(id)` | graph |
| `db.map(query, cb)` | `Net.map(query)` + signal `graph_changed(id, action, data)` | graph |

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

- **Ephemeral** — player positions over a GenosRTC **data channel** (`Net.send`).
- **Persistent** — tree state in the GenosDB **graph** (`Net.put` / `Net.map`); a
  **late-joiner gets the current world automatically** (via the `initial` action)
  and chops survive reloads.

## 🛠 Tech

- **Godot 4.6** — GL Compatibility, Web export, no threads → any static host.
- **GenosDB / GenosRTC** — loaded from CDN; auto-injected on export.

---

⭐ **Star [GenosDB](https://github.com/estebanrfp/GenosDB)** (and this plugin) if they help you — it's the best, free way to support the project and help it grow.

## Author

Esteban Fuster Pozzi (@estebanrfp) — Full Stack JavaScript Developer

## License

[MIT](LICENSE)
