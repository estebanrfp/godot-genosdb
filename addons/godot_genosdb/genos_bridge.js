// GenosDB <-> Godot bridge (Web export). Auto-injected into index.html by the
// addon's export plugin. Loads GenosDB from a CDN — nothing to bundle.
//
// Godot (genos.gd) sets window.gdOn* callbacks and calls NetJoin / NetSend /
// NetPut / NetRemove.
import { gdb } from "https://cdn.jsdelivr.net/npm/genosdb@latest/dist/index.min.js";

let channel = null;
let db = null;

window.NetJoin = async (roomId) => {
  try {
    db = await gdb(roomId, { rtc: true });
    channel = db.room.channel("state");

    // Ephemeral: peer presence + broadcasts over the data channel.
    db.room.on("peer:join",  (id) => { try { window.gdOnJoin  && window.gdOnJoin(id);  } catch (e) { console.error(e); } });
    db.room.on("peer:leave", (id) => { try { window.gdOnLeave && window.gdOnLeave(id); } catch (e) { console.error(e); } });
    channel.on("message", (data, from) => {
      try { window.gdOnMsg && window.gdOnMsg(from, typeof data === "string" ? data : JSON.stringify(data)); }
      catch (e) { console.error(e); }
    });

    // Persistent: reactive graph. 'initial' delivers the current world to
    // late-joiners; 'added'/'updated'/'removed' stream live changes.
    await db.map({}, ({ id, value, action }) => {
      try { window.gdOnGraph && window.gdOnGraph(id, action, JSON.stringify(value || {})); }
      catch (e) { console.error(e); }
    });

    console.log("[GenosDB] joined room:", roomId);
  } catch (e) { console.error("[GenosDB] join failed:", e); }
};

window.NetSend   = (s)        => { try { if (channel) channel.send(s); } catch (e) {} };
window.NetPut    = (id, json) => { try { if (db) db.put(JSON.parse(json), id); } catch (e) { console.error(e); } };
window.NetRemove = (id)       => { try { if (db) db.remove(id); } catch (e) {} };

// Tell Godot the bridge is ready (fixes the wasm-vs-module boot race).
window.__bridgeReady = true;
console.log("[GenosDB] bridge ready");
