// GenosDB <-> Godot bridge (Web export). Auto-injected into index.html by the
// addon's export plugin. Loads GenosDB from a CDN — nothing to bundle.
//
// Godot (genos.gd) sets window.gdOn* callbacks and calls the Net* functions,
// which map 1:1 onto the real GenosDB API (gdb / channel.send / db.put / db.map).
import { gdb } from "https://cdn.jsdelivr.net/npm/genosdb@latest/dist/index.min.js";

let db = null;
let channel = null;
let pendingMaps = [];

function startMap(query) {
  // db.map(query, cb) — reactive. 'initial' gives a late-joiner the current world.
  db.map(query, ({ id, value, action }) => {
    try { window.gdOnGraph && window.gdOnGraph(id, action, JSON.stringify(value || {})); }
    catch (e) { console.error(e); }
  });
}

window.NetJoin = async (roomId) => {
  try {
    db = await gdb(roomId, { rtc: true });   // the room id is the GenosDB name
    channel = db.room.channel("state");

    db.room.on("peer:join",  (id) => { try { window.gdOnJoin  && window.gdOnJoin(id);  } catch (e) { console.error(e); } });
    db.room.on("peer:leave", (id) => { try { window.gdOnLeave && window.gdOnLeave(id); } catch (e) { console.error(e); } });
    channel.on("message", (data, from) => {
      try { window.gdOnMsg && window.gdOnMsg(from, typeof data === "string" ? data : JSON.stringify(data)); }
      catch (e) { console.error(e); }
    });

    for (const q of pendingMaps) startMap(q);   // apply maps requested before join finished
    pendingMaps = [];
    console.log("[GenosDB] joined room:", roomId);
  } catch (e) { console.error("[GenosDB] join failed:", e); }
};

window.NetSend   = (s)         => { try { if (channel) channel.send(s); } catch (e) {} };
window.NetPut    = (json, id)  => { try { if (db) db.put(JSON.parse(json), id || undefined); } catch (e) { console.error(e); } };
window.NetRemove = (id)        => { try { if (db) db.remove(id); } catch (e) {} };
window.NetMap    = (queryJson) => {
  const q = JSON.parse(queryJson || "{}");
  if (db) startMap(q); else pendingMaps.push(q);
};

// Tell Godot the bridge is ready (fixes the wasm-vs-module boot race).
window.__bridgeReady = true;
console.log("[GenosDB] bridge ready");
