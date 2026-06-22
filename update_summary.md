## Updated Skills

Submodule skills/AI-research-SKILLs 28f2d29..773a529:
  > release: v1.7.2 — ship Qoder agent auto-detection to npm
  > feat(agents): add Qoder to supported agents (#29)
  > feat(model-merging): add unsupervised coefficient tuning via generation consistency (#34)
  > fix(release): v1.7.1 — repair lockfile sync and pin deps to patched versions (#62)
  > release: v1.7.0 — inventory consistency, drift guard & security hardening (#61)
  > docs: correct skill/category inventory to 98/23 + add drift guard (#60)
  > fix(security): pin npm dependency versions to exact ranges (#53)
Submodule skills/scientific-agent-skills e6cabc2..ddd2f7f:
  > chore: update security scan report [skip ci]
  > Enhance database lookup skill with deterministic querying and provenance features. Updated documentation to reflect improved API interaction, including retrieval contracts, pagination handling, and untrusted response management. Adjusted README and skills documentation for clarity on database access and usage.
diff --git a/skills/superpowers/brainstorming/SKILL.md b/skills/superpowers/brainstorming/SKILL.md
index 06cd0a2..b0d52b2 100644
--- a/skills/superpowers/brainstorming/SKILL.md
+++ b/skills/superpowers/brainstorming/SKILL.md
@@ -22,7 +22,7 @@ Every project goes through this process. A todo list, a single-function utility,
 You MUST create a task for each of these items and complete them in order:
 
 1. **Explore project context** — check files, docs, recent commits
-2. **Offer visual companion** (if topic will involve visual questions) — this is its own message, not combined with a clarifying question. See the Visual Companion section below.
+2. **Offer the visual companion just-in-time** — NOT upfront. The first time a question would genuinely be clearer shown than described, offer it then (its own message); on approval its browser tab opens for you. If no visual question ever arises, never offer it. See the Visual Companion section below.
 3. **Ask clarifying questions** — one at a time, understand purpose/constraints/success criteria
 4. **Propose 2-3 approaches** — with trade-offs and your recommendation
 5. **Present design** — in sections scaled to their complexity, get user approval after each section
@@ -36,8 +36,6 @@ You MUST create a task for each of these items and complete them in order:
 ```dot
 digraph brainstorming {
     "Explore project context" [shape=box];
-    "Visual questions ahead?" [shape=diamond];
-    "Offer Visual Companion\n(own message, no other content)" [shape=box];
     "Ask clarifying questions" [shape=box];
     "Propose 2-3 approaches" [shape=box];
     "Present design sections" [shape=box];
@@ -47,10 +45,7 @@ digraph brainstorming {
     "User reviews spec?" [shape=diamond];
     "Invoke writing-plans skill" [shape=doublecircle];
 
-    "Explore project context" -> "Visual questions ahead?";
-    "Visual questions ahead?" -> "Offer Visual Companion\n(own message, no other content)" [label="yes"];
-    "Visual questions ahead?" -> "Ask clarifying questions" [label="no"];
-    "Offer Visual Companion\n(own message, no other content)" -> "Ask clarifying questions";
+    "Explore project context" -> "Ask clarifying questions";
     "Ask clarifying questions" -> "Propose 2-3 approaches";
     "Propose 2-3 approaches" -> "Present design sections";
     "Present design sections" -> "User approves design?";
@@ -148,10 +143,10 @@ Wait for the user's response. If they request changes, make them and re-run the
 
 A browser-based companion for showing mockups, diagrams, and visual options during brainstorming. Available as a tool — not a mode. Accepting the companion means it's available for questions that benefit from visual treatment; it does NOT mean every question goes through the browser.
 
-**Offering the companion:** When you anticipate that upcoming questions will involve visual content (mockups, layouts, diagrams), offer it once for consent:
-> "Some of what we're working on might be easier to explain if I can show it to you in a web browser. I can put together mockups, diagrams, comparisons, and other visuals as we go. This feature is still new and can be token-intensive. Want to try it? (Requires opening a local URL)"
+**Offering the companion (just-in-time):** Do NOT offer it upfront. Wait until a question would genuinely be clearer shown than told — a real mockup / layout / diagram question, not merely a UI *topic*. The first time that happens, offer it then, as its own message:
+> "This next part might be easier if I show you — I can put together mockups, diagrams, and comparisons in a browser tab as we go. It's still new and can be token-intensive. Want me to? I'll open it for you."
 
-**This offer MUST be its own message.** Do not combine it with clarifying questions, context summaries, or any other content. The message should contain ONLY the offer above and nothing else. Wait for the user's response before continuing. If they decline, proceed with text-only brainstorming.
+**This offer MUST be its own message.** Only the offer — no clarifying question, summary, or other content. Wait for the user's response. If they accept, start the server with `--open` so their browser opens to the first screen automatically. If they decline, continue text-only and don't offer again unless they raise it.
 
 **Per-question decision:** Even after the user accepts, decide FOR EACH QUESTION whether to use the browser or the terminal. The test: **would the user understand this better by seeing it than reading it?**
 
diff --git a/skills/superpowers/brainstorming/scripts/frame-template.html b/skills/superpowers/brainstorming/scripts/frame-template.html
index dcfe018..f540bb8 100644
--- a/skills/superpowers/brainstorming/scripts/frame-template.html
+++ b/skills/superpowers/brainstorming/scripts/frame-template.html
@@ -9,11 +9,11 @@
      *
      * This template provides a consistent frame with:
      * - OS-aware light/dark theming
-     * - Fixed header and selection indicator bar
+     * - Header branding and connection status
      * - Scrollable main content area
      * - CSS helpers for common UI patterns
      *
-     * Content is injected via placeholder comment in #claude-content.
+     * Content is injected via placeholder comment in #frame-content.
      */
 
     * { box-sizing: border-box; margin: 0; padding: 0; }
@@ -63,34 +63,37 @@
     }
 
     /* ===== FRAME STRUCTURE ===== */
-    .header {
-      background: var(--bg-secondary);
-      padding: 0.5rem 1.5rem;
-      display: flex;
-      justify-content: space-between;
-      align-items: center;
-      border-bottom: 1px solid var(--border);
-      flex-shrink: 0;
+    .brand { display: flex; align-items: center; min-width: 0; overflow: hidden; color: var(--text-secondary); line-height: 1; }
+    .brand a { color: inherit; text-decoration: none; display: flex; align-items: center; gap: 0.5rem; min-width: 0; max-width: 100%; line-height: 1; }
+    .brand-copy { display: block; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; line-height: 1; transform: translateY(-1px); }
+    .brand-logo { display: block; height: 1em; width: auto; max-width: 180px; flex-shrink: 0; filter: invert(1); }
+    @media (prefers-color-scheme: dark) {
+      .brand-logo { filter: none; }
     }
-    .header h1 { font-size: 0.85rem; font-weight: 500; color: var(--text-secondary); }
-    .header .status { font-size: 0.7rem; color: var(--success); display: flex; align-items: center; gap: 0.4rem; }
-    .header .status::before { content: ''; width: 6px; height: 6px; background: var(--success); border-radius: 50%; }
+    .status { font-size: 0.7rem; color: var(--status-color, var(--success)); display: flex; align-items: center; gap: 0.4rem; justify-self: end; white-space: nowrap; line-height: 1; }
+    .status::before { content: ''; width: 6px; height: 6px; background: var(--status-color, var(--success)); border-radius: 50%; }
 
     .main { flex: 1; overflow-y: auto; }
-    #claude-content { padding: 2rem; min-height: 100%; }
+    #frame-content { padding: 2rem; min-height: 100%; }
 
-    .indicator-bar {
+    .header {
       background: var(--bg-secondary);
-      border-top: 1px solid var(--border);
+      border-bottom: 1px solid var(--border);
       padding: 0.5rem 1.5rem;
       flex-shrink: 0;
-      text-align: center;
+      display: grid;
+      grid-template-columns: minmax(0, 1fr) auto;
+      align-items: center;
+      gap: 1rem;
+      min-height: 42px;
     }
-    .indicator-bar span {
+    .header .brand { justify-self: start; width: 100%; font-size: 0.75rem; line-height: 1; }
+    .header .status { grid-column: 2; line-height: 1; }
+    .header span {
       font-size: 0.75rem;
       color: var(--text-secondary);
     }
-    .indicator-bar .selected-text {
+    .header .selected-text {
       color: var(--accent);
       font-weight: 500;
     }
@@ -196,19 +199,15 @@
 </head>
 <body>
   <div class="header">
-    <h1><a href="https://github.com/obra/superpowers" style="color: inherit; text-decoration: none;">Superpowers Brainstorming</a></h1>
-    <div class="status">Connected</div>
+    <!-- BRANDING -->
+    <div class="status">Connecting…</div>
   </div>
 
   <div class="main">
-    <div id="claude-content">
+    <div id="frame-content">
       <!-- CONTENT -->
     </div>
   </div>
 
-  <div class="indicator-bar">
-    <span id="indicator-text">Click an option above, then return to the terminal</span>
-  </div>
-
 </body>
 </html>
diff --git a/skills/superpowers/brainstorming/scripts/helper.js b/skills/superpowers/brainstorming/scripts/helper.js
index 111f97f..e11d264 100644
--- a/skills/superpowers/brainstorming/scripts/helper.js
+++ b/skills/superpowers/brainstorming/scripts/helper.js
@@ -1,26 +1,120 @@
 (function() {
-  const WS_URL = 'ws://' + window.location.host;
+  const MIN_RECONNECT_MS = 500;
+  const MAX_RECONNECT_MS = 30000;
+  const TOMBSTONE_AFTER_MS = 15000; // show the "paused" overlay after this long disconnected
+
+  // Pure: next backoff delay (doubles, capped). Exported for unit tests.
+  function nextReconnectDelay(current, max) {
+    return Math.min(current * 2, max);
+  }
+  if (typeof module !== 'undefined' && module.exports) {
+    module.exports = { nextReconnectDelay, MIN_RECONNECT_MS, MAX_RECONNECT_MS, TOMBSTONE_AFTER_MS };
+  }
+
+  // Everything below is browser-only; bail out when loaded in Node (tests).
+  if (typeof window === 'undefined') return;
+
   let ws = null;
   let eventQueue = [];
+  let reconnectDelay = MIN_RECONNECT_MS;
+  let reconnectTimer = null;
+  let disconnectedSince = null;
+  let everConnected = false;
+  let tombstoneShown = false;
+
+  function sessionKey() {
+    try {
+      return window.sessionStorage && window.sessionStorage.getItem('brainstorm-session-key');
+    } catch (e) {}
+    return null;
+  }
+
+  function websocketUrl() {
+    const key = sessionKey();
+    return 'ws://' + window.location.host + (key ? '/?key=' + encodeURIComponent(key) : '');
+  }
+
+  function reloadAfterRecovery() {
+    const key = sessionKey();
+    if (key) {
+      window.location.replace('/?key=' + encodeURIComponent(key));
+    } else {
+      window.location.reload();
+    }
+  }
+
+  // Reflect connection state in the frame's status pill (absent on full-doc screens).
+  function setStatus(state) {
+    const el = document.querySelector('.status');
+    if (!el) return;
+    const map = {
+      connecting:   ['Connecting…',   'var(--text-tertiary)'],
+      connected:    ['Connected',     'var(--success)'],
+      reconnecting: ['Reconnecting…', 'var(--warning)'],
+      disconnected: ['Disconnected',  'var(--error)']
+    };
+    const [text, color] = map[state] || map.disconnected;
+    el.textContent = text;
+    el.style.setProperty('--status-color', color);
+  }
+
+  // Self-styled so it works on framed and full-document screens alike.
+  function showTombstone() {
+    if (tombstoneShown) return;
+    tombstoneShown = true;
+    const el = document.createElement('div');
+    el.id = 'bs-tombstone';
+    el.style.cssText = 'position:fixed;inset:0;z-index:99999;display:flex;' +
+      'align-items:center;justify-content:center;padding:2rem;text-align:center;' +
+      'background:rgba(20,20,22,0.92);color:#f5f5f7;font-family:system-ui,sans-serif';
+    el.innerHTML = '<div style="max-width:480px">' +
+      '<h2 style="margin:0 0 .5rem;font-weight:600">Companion paused</h2>' +
+      '<p style="margin:0;opacity:.85">This brainstorm companion has stopped. ' +
+      'Ask your coding agent to bring it back — this page reconnects automatically.</p></div>';
+    if (document.body) document.body.appendChild(el);
+  }
 
   function connect() {
-    ws = new WebSocket(WS_URL);
+    if (reconnectTimer) { clearTimeout(reconnectTimer); reconnectTimer = null; }
+    setStatus(everConnected ? 'reconnecting' : 'connecting');
+    ws = new WebSocket(websocketUrl());
 
     ws.onopen = () => {
+      const recovered = tombstoneShown;
+      everConnected = true;
+      disconnectedSince = null;
+      reconnectDelay = MIN_RECONNECT_MS;
+      tombstoneShown = false;
+      setStatus('connected');
       eventQueue.forEach(e => ws.send(JSON.stringify(e)));
       eventQueue = [];
+      // Recovered from a tombstoned outage (e.g. the server restarted on the same
+      // port) — reload through the keyed bootstrap when possible so the cookie is
+      // refreshed before the visible URL returns to bare /.
+      if (recovered) reloadAfterRecovery();
     };
 
     ws.onmessage = (msg) => {
-      const data = JSON.parse(msg.data);
-      if (data.type === 'reload') {
-        window.location.reload();
-      }
+      let data;
+      try { data = JSON.parse(msg.data); } catch (e) { return; }
+      if (data.type === 'reload') window.location.reload();
     };
 
     ws.onclose = () => {
-      setTimeout(connect, 1000);
+      ws = null;
+      if (disconnectedSince === null) disconnectedSince = Date.now();
+      if (Date.now() - disconnectedSince >= TOMBSTONE_AFTER_MS) {
+        setStatus('disconnected');
+        showTombstone();
+      } else {
+        setStatus('reconnecting');
+      }
+      reconnectTimer = setTimeout(connect, reconnectDelay);
+      reconnectDelay = nextReconnectDelay(reconnectDelay, MAX_RECONNECT_MS);
     };
+
+    // Let onclose own reconnection so we don't schedule it twice.
+    ws.onerror = () => { try { ws.close(); } catch (e) {} };
   }
 
   function sendEvent(event) {
@@ -44,21 +138,6 @@
       id: target.id || null
     });
 
-    // Update indicator bar (defer so toggleSelect runs first)
-    setTimeout(() => {
-      const indicator = document.getElementById('indicator-text');
-      if (!indicator) return;
-      const container = target.closest('.options') || target.closest('.cards');
-      const selected = container ? container.querySelectorAll('.selected') : [];
-      if (selected.length === 0) {
-        indicator.textContent = 'Click an option above, then return to the terminal';
-      } else if (selected.length === 1) {
-        const label = selected[0].querySelector('h3, .content h3, .card-body h3')?.textContent?.trim() || selected[0].dataset.choice;
-        indicator.innerHTML = '<span class="selected-text">' + label + ' selected</span> — return to terminal to continue';
-      } else {
-        indicator.innerHTML = '<span class="selected-text">' + selected.length + ' selected</span> — return to terminal to continue';
-      }
-    }, 0);
   });
 
   // Frame UI: selection tracking
diff --git a/skills/superpowers/brainstorming/scripts/server.cjs b/skills/superpowers/brainstorming/scripts/server.cjs
index 562c17f..a828b35 100644
--- a/skills/superpowers/brainstorming/scripts/server.cjs
+++ b/skills/superpowers/brainstorming/scripts/server.cjs
@@ -7,6 +7,7 @@ const path = require('path');
 
 const OPCODES = { TEXT: 0x01, CLOSE: 0x08, PING: 0x09, PONG: 0x0A };
 const WS_MAGIC = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';
+const MAX_FRAME_PAYLOAD_BYTES = 10 * 1024 * 1024;
 
 function computeAcceptKey(clientKey) {
   return crypto.createHash('sha1').update(clientKey + WS_MAGIC).digest('base64');
@@ -53,10 +54,18 @@ function decodeFrame(buffer) {
     offset = 4;
   } else if (payloadLen === 127) {
     if (buffer.length < 10) return null;
-    payloadLen = Number(buffer.readBigUInt64BE(2));
+    const extendedLen = buffer.readBigUInt64BE(2);
+    if (extendedLen > BigInt(MAX_FRAME_PAYLOAD_BYTES)) {
+      throw new Error('WebSocket frame payload exceeds maximum allowed size');
+    }
+    payloadLen = Number(extendedLen);
     offset = 10;
   }
 
+  if (payloadLen > MAX_FRAME_PAYLOAD_BYTES) {
+    throw new Error('WebSocket frame payload exceeds maximum allowed size');
+  }
+
   const maskOffset = offset;
   const dataOffset = offset + 4;
   const totalLen = dataOffset + payloadLen;
@@ -73,14 +82,74 @@ function decodeFrame(buffer) {
 
 // ========== Configuration ==========
 
-const PORT = process.env.BRAINSTORM_PORT || (49152 + Math.floor(Math.random() * 16383));
+const PORT_FILE = process.env.BRAINSTORM_PORT_FILE || null;
+const randomPort = () => 49152 + Math.floor(Math.random() * 16383);
+// Prefer an explicit port, else the port this session last bound (so a restart
+// reuses it and an already-open browser tab reconnects), else a random high port.
+function preferredPort() {
+  if (process.env.BRAINSTORM_PORT) return Number(process.env.BRAINSTORM_PORT);
+  if (PORT_FILE) {
+    try {
+      const p = Number(fs.readFileSync(PORT_FILE, 'utf-8').trim());
+      if (Number.isInteger(p) && p > 1023 && p < 65536) return p;
+    } catch (e) { /* no prior port recorded */ }
+  }
+  return randomPort();
+}
+let PORT = preferredPort();
 const HOST = process.env.BRAINSTORM_HOST || '127.0.0.1';
 const URL_HOST = process.env.BRAINSTORM_URL_HOST || (HOST === '127.0.0.1' ? 'localhost' : HOST);
 const SESSION_DIR = process.env.BRAINSTORM_DIR || '/tmp/brainstorm';
 const CONTENT_DIR = path.join(SESSION_DIR, 'content');
 const STATE_DIR = path.join(SESSION_DIR, 'state');
+const SUPERPOWERS_VERSION = readSuperpowersVersion();
+const SUPERPOWERS_BRAND_IMAGE_URL = 'https://primeradiant.com/brand/superpowers-visual-brainstorming-logo.png';
+const TELEMETRY_DISABLE_ENV_VARS = [
+  'SUPERPOWERS_DISABLE_TELEMETRY',
+  'DISABLE_TELEMETRY',
+  'CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC'
+];
+const SUPERPOWERS_TELEMETRY_DISABLED = TELEMETRY_DISABLE_ENV_VARS.some(name => isTruthyEnv(process.env[name]));
 let ownerPid = process.env.BRAINSTORM_OWNER_PID ? Number(process.env.BRAINSTORM_OWNER_PID) : null;
 
+// Per-session secret key. The companion is reachable by any local browser tab
+// and, when bound to a non-loopback host, by any host that can route to it.
+// The key authenticates the real client uniformly across loopback, tunnel, and
+// remote binds — and defeats DNS rebinding — where a Host/Origin allowlist
+// cannot. It rides the served URL as ?key= and is mirrored into a cookie on
+// first load so same-origin subresources and the WebSocket carry it for free.
+// Persisted alongside the port (BRAINSTORM_TOKEN_FILE) so a restart keeps the
+// same key and an already-open tab's cookie still validates.
+const TOKEN_FILE = process.env.BRAINSTORM_TOKEN_FILE || null;
+function generateToken() {
+  return crypto.randomBytes(32).toString('hex');
+}
+
+function chmodOwnerOnly(file) {
+  try { fs.chmodSync(file, 0o600); } catch (e) { /* best effort */ }
+}
+
+function initialToken() {
+  if (process.env.BRAINSTORM_TOKEN) {
+    return { value: process.env.BRAINSTORM_TOKEN, source: 'env' };
+  }
+  if (TOKEN_FILE) {
+    try {
+      const t = fs.readFileSync(TOKEN_FILE, 'utf-8').trim();
+      if (/^[0-9a-f]{32,}$/i.test(t)) {
+        chmodOwnerOnly(TOKEN_FILE);
+        return { value: t, source: 'file' };
+      }
+    } catch (e) { /* no prior token recorded */ }
+  }
+  return { value: generateToken(), source: 'generated' };
+}
+
+const tokenInfo = initialToken();
+let TOKEN = tokenInfo.value;
+let tokenSource = tokenInfo.source;
+let COOKIE_NAME = 'brainstorm-key-' + PORT; // refined to the actual bound port in onListen
+
 const MIME_TYPES = {
   '.html': 'text/html', '.css': 'text/css', '.js': 'application/javascript',
   '.json': 'application/json', '.png': 'image/png', '.jpg': 'image/jpeg',
@@ -89,14 +158,46 @@ const MIME_TYPES = {
 
 // ========== Templates and Constants ==========
 
-const WAITING_PAGE = `<!DOCTYPE html>
+function waitingPage() {
+  return renderBranding(`<!DOCTYPE html>
 <html>
 <head><meta charset="utf-8"><title>Brainstorm Companion</title>
+<style>
+body { font-family: system-ui, sans-serif; padding: 2rem; max-width: 800px; margin: 0 auto; }
+h1 { color: #333; } p { color: #666; }
+.brand { display: flex; align-items: center; min-width: 0; overflow: hidden; margin-bottom: 1.5rem; color: #666; font-size: 0.9rem; line-height: 1; }
+.brand a { color: inherit; text-decoration: none; display: flex; align-items: center; gap: 0.5rem; min-width: 0; max-width: 100%; line-height: 1; }
+.brand-copy { display: block; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; line-height: 1; transform: translateY(-1px); }
+.brand-logo { display: block; height: 1em; width: auto; max-width: 180px; filter: invert(1); }
+</style>
+</head>
+<body><!-- BRANDING --><h1>Brainstorm Companion</h1>
+<p>Waiting for the agent to push a screen...</p></body></html>`);
+}
+
+const FORBIDDEN_PAGE = `<!DOCTYPE html>
+<html>
+<head><meta charset="utf-8"><title>Session key required</title>
 <style>body { font-family: system-ui, sans-serif; padding: 2rem; max-width: 800px; margin: 0 auto; }
-h1 { color: #333; } p { color: #666; }</style>
+h1 { color: #333; } p { color: #666; } code { background: #f0f0f0; padding: 0.1em 0.3em; border-radius: 4px; }</style>
 </head>
-<body><h1>Brainstorm Companion</h1>
-<p>Waiting for the agent to push a screen...</p></body></html>`;
+<body><h1>Session key required</h1>
+<p>This page needs the full URL your coding agent gave you, including the
+<code>?key=&hellip;</code> part. Copy the complete URL and open it again.</p></body></html>`;
+
+function bootstrapPage(key) {
+  const jsonKey = JSON.stringify(String(key));
+  return `<!DOCTYPE html>
+<html>
+<head><meta charset="utf-8"><title>Opening Brainstorm Companion</title></head>
+<body>
+<script>
+try { sessionStorage.setItem('brainstorm-session-key', ${jsonKey}); } catch (e) {}
+location.replace('/');
+</script>
+</body>
+</html>`;
+}
 
 const frameTemplate = fs.readFileSync(path.join(__dirname, 'frame-template.html'), 'utf-8');
 const helperScript = fs.readFileSync(path.join(__dirname, 'helper.js'), 'utf-8');
@@ -104,35 +205,209 @@ const helperInjection = '<script>\n' + helperScript + '\n</script>';
 
 // ========== Helper Functions ==========
 
+function readSuperpowersVersion() {
+  const root = path.join(__dirname, '../../..');
+  const manifests = [
+    path.join(root, 'package.json'),
+    path.join(root, '.codex-plugin/plugin.json')
+  ];
+
+  for (const manifest of manifests) {
+    try {
+      const data = JSON.parse(fs.readFileSync(manifest, 'utf-8'));
+      if (data.version) return String(data.version);
+    } catch (e) {
+      // Packaged Codex plugins omit package.json; try the next manifest.
+    }
+  }
+
+  return 'unknown';
+}
+
+function isTruthyEnv(value) {
+  if (!value) return false;
+  const normalized = String(value).trim().toLowerCase();
+  if (!normalized) return false;
+  return !['0', 'false', 'no', 'off'].includes(normalized);
+}
+
+function escapeHtmlText(value) {
+  return String(value)
+    .replace(/&/g, '&amp;')
+    .replace(/</g, '&lt;')
+    .replace(/>/g, '&gt;')
+    .replace(/"/g, '&quot;');
+}
+
+function brandMarkup() {
+  const version = escapeHtmlText(SUPERPOWERS_VERSION);
+  const text = SUPERPOWERS_TELEMETRY_DISABLED
+    ? 'Prime Radiant Superpowers v' + version
+    : 'Superpowers v' + version;
+  const logo = SUPERPOWERS_TELEMETRY_DISABLED
+    ? ''
+    : '<img class="brand-logo" src="' + SUPERPOWERS_BRAND_IMAGE_URL + '?v=' + encodeURIComponent(SUPERPOWERS_VERSION) + '" alt="Prime Radiant" referrerpolicy="no-referrer" decoding="async">';
+
+  return '<div class="brand"><a href="https://github.com/obra/superpowers">' + logo + '<span class="brand-copy">' + text + '</span></a></div>';
+}
+
+function renderBranding(html) {
+  return html.split('<!-- BRANDING -->').join(brandMarkup());
+}
+
 function isFullDocument(html) {
   const trimmed = html.trimStart().toLowerCase();
   return trimmed.startsWith('<!doctype') || trimmed.startsWith('<html');
 }
 
 function wrapInFrame(content) {
-  return frameTemplate.replace('<!-- CONTENT -->', content);
+  return renderBranding(frameTemplate).replace('<!-- CONTENT -->', content);
 }
 
 function getNewestScreen() {
   const files = fs.readdirSync(CONTENT_DIR)
-    .filter(f => f.endsWith('.html'))
+    .filter(f => !f.startsWith('.') && f.endsWith('.html'))
     .map(f => {
       const fp = path.join(CONTENT_DIR, f);
+      if (!isRegularFileInsideContentDir(fp)) return null;
       return { path: fp, mtime: fs.statSync(fp).mtime.getTime() };
     })
+    .filter(Boolean)
     .sort((a, b) => b.mtime - a.mtime);
   return files.length > 0 ? files[0].path : null;
 }
 
+function urlHostForHttp(host) {
+  const h = String(host);
+  if (h.startsWith('[') && h.endsWith(']')) return h;
+  return h.includes(':') ? '[' + h + ']' : h;
+}
+
+function companionUrl() {
+  return 'http://' + urlHostForHttp(URL_HOST) + ':' + PORT + '/?key=' + TOKEN;
+}
+
+function browserLauncherForPlatform(url, {
+  platform = process.platform,
+  osRelease = require('os').release(),
+  env = process.env
+} = {}) {
+  const isWSL = platform === 'linux' && /microsoft/i.test(osRelease);
+  if (platform === 'darwin') return { bin: 'open', args: [url] };
+  if (platform === 'win32' || isWSL) {
+    return { bin: 'rundll32.exe', args: ['url.dll,FileProtocolHandler', url] };
+  }
+  if (env.DISPLAY || env.WAYLAND_DISPLAY) return { bin: 'xdg-open', args: [url] };
+  return null;
+}
+
+function isRegularFileInsideContentDir(filePath) {
+  let stat, realContentDir, realFilePath;
+  try {
+    stat = fs.lstatSync(filePath);
+    if (stat.isSymbolicLink()) return false;
+    if (!stat.isFile()) return false;
+    if (stat.nlink !== 1) return false;
+    realContentDir = fs.realpathSync(CONTENT_DIR);
+    realFilePath = fs.realpathSync(filePath);
+  } catch (e) {
+    return false;
+  }
+  return realFilePath.startsWith(realContentDir + path.sep);
+}
+
+// ========== Authentication ==========
+
+function timingSafeEqualStr(a, b) {
+  const ab = Buffer.from(String(a));
+  const bb = Buffer.from(String(b));
+  if (ab.length !== bb.length) return false;
+  return crypto.timingSafeEqual(ab, bb);
+}
+
+function parseCookies(header) {
+  const out = {};
+  if (!header) return out;
+  for (const part of header.split(';')) {
+    const eq = part.indexOf('=');
+    if (eq < 0) continue;
+    out[part.slice(0, eq).trim()] = part.slice(eq + 1).trim();
+  }
+  return out;
+}
+
+// A request is authorized if it carries the session key as ?key= or as the
+// session cookie. Both are compared in constant time.
+function isAuthorized(req) {
+  const q = req.url.indexOf('?');
+  if (q >= 0) {
+    const params = new URLSearchParams(req.url.slice(q + 1));
+    if (params.has('key')) {
+      const key = params.get('key');
+      return Boolean(key && timingSafeEqualStr(key, TOKEN));
+    }
+  }
+  const cookie = parseCookies(req.headers['cookie'])[COOKIE_NAME];
+  if (cookie && timingSafeEqualStr(cookie, TOKEN)) return true;
+  return false;
+}
+
+function pathnameOf(url) {
+  const q = url.indexOf('?');
+  return q >= 0 ? url.slice(0, q) : url;
+}
+
+function queryKey(url) {
+  const q = url.indexOf('?');
+  if (q < 0) return null;
+  return new URLSearchParams(url.slice(q + 1)).get('key');
+}
+
+function securityHeaders(headers = {}) {
+  return {
+    'Referrer-Policy': 'no-referrer',
+    'Cache-Control': 'no-store',
+    'X-Frame-Options': 'DENY',
+    'Content-Security-Policy': "frame-ancestors 'none'",
+    'Cross-Origin-Resource-Policy': 'same-origin',
+    ...headers
+  };
+}
+
+function isAllowedWebSocketOrigin(req) {
+  const origin = req.headers.origin;
+  if (!origin) return true;
+  const host = req.headers.host;
+  if (!host) return false;
+  return origin === 'http://' + host;
+}
+
 // ========== HTTP Request Handler ==========
 
 function handleRequest(req, res) {
-  touchActivity();
-  if (req.method === 'GET' && req.url === '/') {
+  if (!isAuthorized(req)) {
+    res.writeHead(403, securityHeaders({ 'Content-Type': 'text/html; charset=utf-8' }));
+    res.end(FORBIDDEN_PAGE);
+    return;
+  }
+  touchActivity(); // only authorized requests count as activity
+
+  // Mirror the key into a cookie so same-origin subresources (/files/*) can
+  // authenticate after bootstrap. HttpOnly keeps it away from page scripts; the
+  // WebSocket Origin check below is what blocks cross-origin localhost injection.
+  res.setHeader('Set-Cookie',
+    COOKIE_NAME + '=' + TOKEN + '; HttpOnly; SameSite=Strict; Path=/');
+
+  const pathname = pathnameOf(req.url);
+  const keyFromQuery = queryKey(req.url);
+  if (req.method === 'GET' && pathname === '/' && keyFromQuery && timingSafeEqualStr(keyFromQuery, TOKEN)) {
+    res.writeHead(200, securityHeaders({ 'Content-Type': 'text/html; charset=utf-8' }));
+    res.end(bootstrapPage(keyFromQuery));
+  } else if (req.method === 'GET' && pathname === '/') {
     const screenFile = getNewestScreen();
     let html = screenFile
       ? (raw => isFullDocument(raw) ? raw : wrapInFrame(raw))(fs.readFileSync(screenFile, 'utf-8'))
-      : WAITING_PAGE;
+      : waitingPage();
 
     if (html.includes('</body>')) {
       html = html.replace('</body>', helperInjection + '\n</body>');
@@ -140,22 +415,24 @@ function handleRequest(req, res) {
       html += helperInjection;
     }
 
-    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
+    res.writeHead(200, securityHeaders({ 'Content-Type': 'text/html; charset=utf-8' }));
     res.end(html);
-  } else if (req.method === 'GET' && req.url.startsWith('/files/')) {
-    const fileName = req.url.slice(7);
-    const filePath = path.join(CONTENT_DIR, path.basename(fileName));
-    if (!fs.existsSync(filePath)) {
-      res.writeHead(404);
+  } else if (req.method === 'GET' && pathname.startsWith('/files/')) {
+    const fileName = path.basename(pathname.slice(7));
+    const filePath = path.join(CONTENT_DIR, fileName);
+    // Reject empty/dotfile names and anything that isn't a regular file —
+    // `/files/` would otherwise resolve to CONTENT_DIR and crash readFileSync (EISDIR).
+    if (!fileName || fileName.startsWith('.') || !isRegularFileInsideContentDir(filePath)) {
+      res.writeHead(404, securityHeaders());
       res.end('Not found');
       return;
     }
     const ext = path.extname(filePath).toLowerCase();
     const contentType = MIME_TYPES[ext] || 'application/octet-stream';
-    res.writeHead(200, { 'Content-Type': contentType });
+    res.writeHead(200, securityHeaders({ 'Content-Type': contentType }));
     res.end(fs.readFileSync(filePath));
   } else {
-    res.writeHead(404);
+    res.writeHead(404, securityHeaders());
     res.end('Not found');
   }
 }
@@ -165,6 +442,8 @@ function handleRequest(req, res) {
 const clients = new Set();
 
 function handleUpgrade(req, socket) {
+  if (!isAuthorized(req) || !isAllowedWebSocketOrigin(req)) { socket.destroy(); return; }
+
   const key = req.headers['sec-websocket-key'];
   if (!key) { socket.destroy(); return; }
 
@@ -231,7 +510,7 @@ function handleMessage(text) {
   }
   touchActivity();
   console.log(JSON.stringify({ source: 'user-event', ...event }));
-  if (event.choice) {
+  if (event && event.choice) {
     const eventsFile = path.join(STATE_DIR, 'events');
     fs.appendFileSync(eventsFile, JSON.stringify(event) + '\n');
   }
@@ -244,9 +523,44 @@ function broadcast(msg) {
   }
 }
 
+// Best-effort: open the user's browser the first time a screen is actually ready
+// to show. Skips when disabled, on a non-loopback (remote) bind, or when a
+// browser is already connected. Override the launcher with BRAINSTORM_OPEN_CMD.
+let browserOpened = false;
+function maybeOpenBrowser() {
+  if (browserOpened) return;
+  browserOpened = true;
+  if (!process.env.BRAINSTORM_OPEN) return; // opt-in: only after the user approves the companion
+  if (HOST !== '127.0.0.1' && HOST !== 'localhost') return;
+  if (clients.size > 0) return; // the user already opened it
+  const url = companionUrl(); // must carry the key or the gate 403s it
+  const cp = require('child_process');
+  // Operator-provided launcher: run as given (this env var is trusted operator input).
+  if (process.env.BRAINSTORM_OPEN_CMD) {
+    try { cp.exec(process.env.BRAINSTORM_OPEN_CMD + ' ' + JSON.stringify(url), () => {}); } catch (e) { /* best effort */ }
+    return;
+  }
+  // Platform launchers: pass the URL as an argv element via execFile (no shell),
+  // so a url-host containing shell metacharacters can't inject a command.
+  const launcher = browserLauncherForPlatform(url);
+  if (!launcher) return; // headless: nothing to open
+  try { cp.execFile(launcher.bin, launcher.args, () => {}); } catch (e) { /* best effort */ }
+}
+
 // ========== Activity Tracking ==========
 
-const IDLE_TIMEOUT_MS = 30 * 60 * 1000; // 30 minutes
+// Idle timeout: shut down after this long with no activity. Default 4 hours;
+// override with BRAINSTORM_IDLE_TIMEOUT_MS (start-server.sh: --idle-timeout-minutes).
+const IDLE_TIMEOUT_MS = (() => {
+  const ms = Number(process.env.BRAINSTORM_IDLE_TIMEOUT_MS);
+  return Number.isFinite(ms) && ms > 0 ? ms : 4 * 60 * 60 * 1000;
+})();
+// How often the watchdog checks for owner-death / idleness. Configurable mainly
+// so tests can run fast; production default is 60s.
+const LIFECYCLE_CHECK_MS = (() => {
+  const ms = Number(process.env.BRAINSTORM_LIFECYCLE_CHECK_MS);
+  return Number.isFinite(ms) && ms > 0 ? ms : 60 * 1000;
+})();
 let lastActivity = Date.now();
 
 function touchActivity() {
@@ -267,14 +581,14 @@ function startServer() {
   // macOS fs.watch reports 'rename' for both new files and overwrites,
   // so we can't rely on eventType alone.
   const knownFiles = new Set(
-    fs.readdirSync(CONTENT_DIR).filter(f => f.endsWith('.html'))
+    fs.readdirSync(CONTENT_DIR).filter(f => !f.startsWith('.') && f.endsWith('.html'))
   );
 
   const server = http.createServer(handleRequest);
   server.on('upgrade', handleUpgrade);
 
   const watcher = fs.watch(CONTENT_DIR, (eventType, filename) => {
-    if (!filename || !filename.endsWith('.html')) return;
+    if (!filename || filename.startsWith('.') || !filename.endsWith('.html')) return;
 
     if (debounceTimers.has(filename)) clearTimeout(debounceTimers.get(filename));
     debounceTimers.set(filename, setTimeout(() => {
@@ -289,6 +603,7 @@ function startServer() {
         const eventsFile = path.join(STATE_DIR, 'events');
         if (fs.existsSync(eventsFile)) fs.unlinkSync(eventsFile);
         console.log(JSON.stringify({ type: 'screen-added', file: filePath }));
+        maybeOpenBrowser();
       } else {
         console.log(JSON.stringify({ type: 'screen-updated', file: filePath }));
       }
@@ -308,6 +623,11 @@ function startServer() {
     );
     watcher.close();
     clearInterval(lifecycleCheck);
+    // Close any upgraded WebSocket sockets so server.close() can complete and
+    // the process actually exits instead of lingering on an open connection.
+    for (const socket of clients) {
+      try { socket.destroy(); } catch (e) { /* already gone */ }
+    }
     server.close(() => process.exit(0));
   }
 
@@ -316,11 +636,11 @@ function startServer() {
     try { process.kill(ownerPid, 0); return true; } catch (e) { return e.code === 'EPERM'; }
   }
 
-  // Check every 60s: exit if owner process died or idle for 30 minutes
+  // Periodically exit if the owner process died or we've been idle too long.
   const lifecycleCheck = setInterval(() => {
     if (!ownerAlive()) shutdown('owner process exited');
     else if (Date.now() - lastActivity > IDLE_TIMEOUT_MS) shutdown('idle timeout');
-  }, 60 * 1000);
+  }, LIFECYCLE_CHECK_MS);
   lifecycleCheck.unref();
 
   // Validate owner PID at startup. If it's already dead, the PID resolution
@@ -336,19 +656,68 @@ function startServer() {
     }
   }
 
-  server.listen(PORT, HOST, () => {
+  // If the preferred port is already taken (e.g. a previous server is still
+  // alive), fall back to a random port once instead of failing.
+  let triedFallback = false;
+
+  function onListen() {
+    // Cookie name keys on the ACTUAL bound port (may differ from the preferred
+    // one after an EADDRINUSE fallback) so it can't collide with another server's
+    // cookie in the shared localhost jar.
+    COOKIE_NAME = 'brainstorm-key-' + PORT;
+    // Record the bound port AND token so the next restart of this session reuses
+    // them — but ONLY when we got our preferred port. On a fallback we bound a
+    // *different* port because someone else holds the preferred one; persisting
+    // would overwrite the shared files and strand that other session's open tab.
+    if (PORT_FILE && !triedFallback) {
+      try { fs.writeFileSync(PORT_FILE, String(PORT)); } catch (e) { /* best effort */ }
+      if (TOKEN_FILE) {
+        try {
+          fs.writeFileSync(TOKEN_FILE, TOKEN, { mode: 0o600 });
+          chmodOwnerOnly(TOKEN_FILE);
+        } catch (e) { /* best effort */ }
+      }
+    }
     const info = JSON.stringify({
       type: 'server-started', port: Number(PORT), host: HOST,
-      url_host: URL_HOST, url: 'http://' + URL_HOST + ':' + PORT,
-      screen_dir: CONTENT_DIR, state_dir: STATE_DIR
+      url_host: URL_HOST, url: companionUrl(),
+      screen_dir: CONTENT_DIR, state_dir: STATE_DIR, idle_timeout_ms: IDLE_TIMEOUT_MS
     });
     console.log(info);
-    fs.writeFileSync(path.join(STATE_DIR, 'server-info'), info + '\n');
+    // server-info embeds the key — keep it owner-only.
+    fs.writeFileSync(path.join(STATE_DIR, 'server-info'), info + '\n', { mode: 0o600 });
+  }
+
+  server.on('error', (err) => {
+    if (err.code === 'EADDRINUSE' && !triedFallback) {
+      if (tokenSource === 'env') {
+        console.error('Server failed to bind: preferred port is in use and BRAINSTORM_TOKEN is set; refusing fallback with explicit token');
+        process.exit(1);
+      }
+      triedFallback = true;
+      PORT = randomPort();
+      if (tokenSource === 'file') {
+        TOKEN = generateToken();
+        tokenSource = 'generated-fallback';
+      }
+      server.listen(PORT, HOST, onListen);
+    } else {
+      console.error('Server failed to bind:', err.message);
+      process.exit(1);
+    }
   });
+  server.listen(PORT, HOST, onListen);
 }
 
 if (require.main === module) {
   startServer();
 }
 
-module.exports = { computeAcceptKey, encodeFrame, decodeFrame, OPCODES };
+module.exports = {
+  computeAcceptKey,
+  encodeFrame,
+  decodeFrame,
+  browserLauncherForPlatform,
+  OPCODES,
+  MAX_FRAME_PAYLOAD_BYTES
+};
diff --git a/skills/superpowers/brainstorming/scripts/start-server.sh b/skills/superpowers/brainstorming/scripts/start-server.sh
index 9ef6dcb..016a8e4 100755
--- a/skills/superpowers/brainstorming/scripts/start-server.sh
+++ b/skills/superpowers/brainstorming/scripts/start-server.sh
@@ -11,6 +11,9 @@
 #   --host <bind-host>    Host/interface to bind (default: 127.0.0.1).
 #                         Use 0.0.0.0 in remote/containerized environments.
 #   --url-host <host>     Hostname shown in returned URL JSON.
+#   --idle-timeout-minutes <n>  Shut down after n minutes idle (default 240 = 4h).
+#   --open                Auto-open the browser on the first screen (use only
+#                         after the user approves the visual companion).
 #   --foreground          Run server in the current terminal (no backgrounding).
 #   --background          Force background mode (overrides Codex auto-foreground).
 
@@ -22,6 +25,7 @@ FOREGROUND="false"
 FORCE_BACKGROUND="false"
 BIND_HOST="127.0.0.1"
 URL_HOST=""
+IDLE_TIMEOUT_MINUTES=""
 while [[ $# -gt 0 ]]; do
   case "$1" in
     --project-dir)
@@ -36,6 +40,14 @@ while [[ $# -gt 0 ]]; do
       URL_HOST="$2"
       shift 2
       ;;
+    --idle-timeout-minutes)
+      IDLE_TIMEOUT_MINUTES="$2"
+      shift 2
+      ;;
+    --open)
+      export BRAINSTORM_OPEN=1
+      shift
+      ;;
     --foreground|--no-daemon)
       FOREGROUND="true"
       shift
@@ -59,6 +71,29 @@ if [[ -z "$URL_HOST" ]]; then
   fi
 fi
 
+if [[ -n "$IDLE_TIMEOUT_MINUTES" ]]; then
+  if ! [[ "$IDLE_TIMEOUT_MINUTES" =~ ^[0-9]+$ ]] || [[ "$IDLE_TIMEOUT_MINUTES" -lt 1 ]]; then
+    echo "{\"error\": \"--idle-timeout-minutes must be a positive integer\"}"
+    exit 1
+  fi
+  export BRAINSTORM_IDLE_TIMEOUT_MS=$(( IDLE_TIMEOUT_MINUTES * 60 * 1000 ))
+fi
+
+is_windows_like_shell() {
+  case "${OSTYPE:-}" in
+    msys*|cygwin*|mingw*) return 0 ;;
+  esac
+  if [[ -n "${MSYSTEM:-}" ]]; then
+    return 0
+  fi
+  local uname_s
+  uname_s="$(uname -s 2>/dev/null || true)"
+  case "$uname_s" in
+    MSYS*|MINGW*|CYGWIN*) return 0 ;;
+  esac
+  return 1
+}
+
 # Some environments reap detached/background processes. Auto-foreground when detected.
 if [[ -n "${CODEX_CI:-}" && "$FOREGROUND" != "true" && "$FORCE_BACKGROUND" != "true" ]]; then
   FOREGROUND="true"
@@ -66,19 +101,24 @@ fi
 
 # Windows/Git Bash reaps nohup background processes. Auto-foreground when detected.
 if [[ "$FOREGROUND" != "true" && "$FORCE_BACKGROUND" != "true" ]]; then
-  case "${OSTYPE:-}" in
-    msys*|cygwin*|mingw*) FOREGROUND="true" ;;
-  esac
-  if [[ -n "${MSYSTEM:-}" ]]; then
+  if is_windows_like_shell; then
     FOREGROUND="true"
   fi
 fi
 
+# Session files (server.log, server-info, .last-token) embed the session key —
+# keep everything this script and the server create owner-only.
+umask 077
+
 # Generate unique session directory
 SESSION_ID="$$-$(date +%s)"
 
 if [[ -n "$PROJECT_DIR" ]]; then
   SESSION_DIR="${PROJECT_DIR}/.superpowers/brainstorm/${SESSION_ID}"
+  # Persist the bound port and key per project so a restart reuses them and an
+  # already-open browser tab reconnects to the same URL with a valid cookie.
+  export BRAINSTORM_PORT_FILE="${PROJECT_DIR}/.superpowers/brainstorm/.last-port"
+  export BRAINSTORM_TOKEN_FILE="${PROJECT_DIR}/.superpowers/brainstorm/.last-token"
 else
   SESSION_DIR="/tmp/brainstorm-${SESSION_ID}"
 fi
@@ -86,10 +126,21 @@ fi
 STATE_DIR="${SESSION_DIR}/state"
 PID_FILE="${STATE_DIR}/server.pid"
 LOG_FILE="${STATE_DIR}/server.log"
+SERVER_ID_FILE="${STATE_DIR}/server-instance-id"
 
 # Create fresh session directory with content and state peers
 mkdir -p "${SESSION_DIR}/content" "$STATE_DIR"
 
+SERVER_ID=""
+if [[ -r /dev/urandom ]]; then
+  SERVER_ID="$(od -An -N24 -tx1 /dev/urandom 2>/dev/null | tr -d ' \n' || true)"
+fi
+if ! [[ "$SERVER_ID" =~ ^[A-Za-z0-9_-]{32,64}$ ]]; then
+  SERVER_ID="$(printf '%08x%08x%08x%08x' "$$" "$(date +%s)" "${RANDOM:-0}" "${RANDOM:-0}")"
+fi
+printf '%s\n' "$SERVER_ID" > "$SERVER_ID_FILE"
+chmod 600 "$SERVER_ID_FILE" 2>/dev/null || true
+
 # Kill any existing server
 if [[ -f "$PID_FILE" ]]; then
   old_pid=$(cat "$PID_FILE")
@@ -97,7 +148,7 @@ if [[ -f "$PID_FILE" ]]; then
   rm -f "$PID_FILE"
 fi
 
-cd "$SCRIPT_DIR"
+cd "$SCRIPT_DIR" || exit 1
 
 # Resolve the harness PID (grandparent of this script).
 # $PPID is the ephemeral shell the harness spawned to run us — it dies
@@ -107,22 +158,32 @@ if [[ -z "$OWNER_PID" || "$OWNER_PID" == "1" ]]; then
   OWNER_PID="$PPID"
 fi
 
+# Windows/MSYS2: Node.js cannot see POSIX PIDs from the MSYS2 namespace.
+# Passing a PID node cannot verify causes server to log owner-pid-invalid
+# and self-terminate at the 60-second lifecycle check. Clear it so the
+# watchdog is disabled and the idle timeout becomes the only shutdown trigger.
+if is_windows_like_shell; then
+  OWNER_PID=""
+fi
+
 # Foreground mode for environments that reap detached/background processes.
 if [[ "$FOREGROUND" == "true" ]]; then
-  echo "$$" > "$PID_FILE"
-  env BRAINSTORM_DIR="$SESSION_DIR" BRAINSTORM_HOST="$BIND_HOST" BRAINSTORM_URL_HOST="$URL_HOST" BRAINSTORM_OWNER_PID="$OWNER_PID" node server.cjs
+  env BRAINSTORM_DIR="$SESSION_DIR" BRAINSTORM_HOST="$BIND_HOST" BRAINSTORM_URL_HOST="$URL_HOST" BRAINSTORM_OWNER_PID="$OWNER_PID" node server.cjs "--brainstorm-server-id=$SERVER_ID" &
+  SERVER_PID=$!
+  echo "$SERVER_PID" > "$PID_FILE"
+  wait "$SERVER_PID"
   exit $?
 fi
 
 # Start server, capturing output to log file
 # Use nohup to survive shell exit; disown to remove from job table
-nohup env BRAINSTORM_DIR="$SESSION_DIR" BRAINSTORM_HOST="$BIND_HOST" BRAINSTORM_URL_HOST="$URL_HOST" BRAINSTORM_OWNER_PID="$OWNER_PID" node server.cjs > "$LOG_FILE" 2>&1 &
+nohup env BRAINSTORM_DIR="$SESSION_DIR" BRAINSTORM_HOST="$BIND_HOST" BRAINSTORM_URL_HOST="$URL_HOST" BRAINSTORM_OWNER_PID="$OWNER_PID" node server.cjs "--brainstorm-server-id=$SERVER_ID" > "$LOG_FILE" 2>&1 &
 SERVER_PID=$!
 disown "$SERVER_PID" 2>/dev/null
 echo "$SERVER_PID" > "$PID_FILE"
 
 # Wait for server-started message (check log file)
-for i in {1..50}; do
+for _ in {1..50}; do
   if grep -q "server-started" "$LOG_FILE" 2>/dev/null; then
     # Verify server is still alive after a short window (catches process reapers)
     alive="true"
diff --git a/skills/superpowers/brainstorming/scripts/stop-server.sh b/skills/superpowers/brainstorming/scripts/stop-server.sh
index a6b94e6..7cacfe9 100755
--- a/skills/superpowers/brainstorming/scripts/stop-server.sh
+++ b/skills/superpowers/brainstorming/scripts/stop-server.sh
@@ -15,15 +15,78 @@ fi
 
 STATE_DIR="${SESSION_DIR}/state"
 PID_FILE="${STATE_DIR}/server.pid"
+SERVER_ID_FILE="${STATE_DIR}/server-instance-id"
+
+mark_stopped() {
+  local reason="$1"
+  rm -f "${STATE_DIR}/server-info"
+  printf '{"reason":"%s","timestamp":%s}\n' "$reason" "$(date +%s)" > "${STATE_DIR}/server-stopped"
+}
+
+read_expected_server_id() {
+  [[ -f "$SERVER_ID_FILE" ]] || return 1
+  local id
+  id="$(tr -d '\r\n' < "$SERVER_ID_FILE" 2>/dev/null || true)"
+  [[ "$id" =~ ^[A-Za-z0-9_-]{32,64}$ ]] || return 1
+  printf '%s\n' "$id"
+}
+
+command_line_for_pid() {
+  local pid="$1"
+  if [[ -r "/proc/$pid/cmdline" ]]; then
+    tr '\0' '\n' < "/proc/$pid/cmdline" 2>/dev/null || true
+    return 0
+  fi
+  ps -ww -p "$pid" -o command= 2>/dev/null || ps -f -p "$pid" 2>/dev/null | sed '1d' || true
+}
+
+command_has_server_id() {
+  local pid="$1"
+  local expected="$2"
+  local expected_arg="--brainstorm-server-id=$expected"
+  if [[ -r "/proc/$pid/cmdline" ]]; then
+    local arg
+    while IFS= read -r -d '' arg || [[ -n "$arg" ]]; do
+      [[ "$arg" == "$expected_arg" ]] && return 0
+    done < "/proc/$pid/cmdline"
+    return 1
+  fi
+  local command_line
+  command_line="$(command_line_for_pid "$pid")"
+  [[ -n "$command_line" ]] || return 1
+  case " $command_line " in
+    *" $expected_arg "*) return 0 ;;
+    *) return 1 ;;
+  esac
+}
+
+# Confirm a PID has this session's per-start instance id, not just a familiar
+# process name. Ambiguous or legacy metadata fails closed as stale_pid.
+is_brainstorm_server() {
+  kill -0 "$1" 2>/dev/null || return 1
+  local expected_id
+  expected_id="$(read_expected_server_id)" || return 1
+  command_has_server_id "$1" "$expected_id" || return 1
+  return 0
+}
 
 if [[ -f "$PID_FILE" ]]; then
   pid=$(cat "$PID_FILE")
 
+  # Refuse to signal a PID we can't prove is our server. A stale pid file may
+  # point at an unrelated process after a reboot/PID wraparound.
+  if ! is_brainstorm_server "$pid"; then
+    rm -f "$PID_FILE" "$SERVER_ID_FILE"
+    mark_stopped "stale_pid"
+    echo '{"status": "stale_pid"}'
+    exit 0
+  fi
+
   # Try to stop gracefully, fallback to force if still alive
   kill "$pid" 2>/dev/null || true
 
   # Wait for graceful shutdown (up to ~2s)
-  for i in {1..20}; do
+  for _ in {1..20}; do
     if ! kill -0 "$pid" 2>/dev/null; then
       break
     fi
@@ -43,7 +106,8 @@ if [[ -f "$PID_FILE" ]]; then
     exit 1
   fi
 
-  rm -f "$PID_FILE" "${STATE_DIR}/server.log"
+  rm -f "$PID_FILE" "$SERVER_ID_FILE" "${STATE_DIR}/server.log"
+  mark_stopped "stop-server.sh"
 
   # Only delete ephemeral /tmp directories
   if [[ "$SESSION_DIR" == /tmp/* ]]; then
diff --git a/skills/superpowers/brainstorming/spec-document-reviewer-prompt.md b/skills/superpowers/brainstorming/spec-document-reviewer-prompt.md
index 35acbb6..6099312 100644
--- a/skills/superpowers/brainstorming/spec-document-reviewer-prompt.md
+++ b/skills/superpowers/brainstorming/spec-document-reviewer-prompt.md
@@ -7,7 +7,7 @@ Use this template when dispatching a spec document reviewer subagent.
 **Dispatch after:** Spec document is written to docs/superpowers/specs/
 
 ```
-Task tool (general-purpose):
+Subagent (general-purpose):
   description: "Review spec document"
   prompt: |
     You are a spec document reviewer. Verify this spec is complete and ready for planning.
diff --git a/skills/superpowers/brainstorming/visual-companion.md b/skills/superpowers/brainstorming/visual-companion.md
index 2113863..906c9ac 100644
--- a/skills/superpowers/brainstorming/visual-companion.md
+++ b/skills/superpowers/brainstorming/visual-companion.md
@@ -28,20 +28,30 @@ A question *about* a UI topic is not automatically a visual question. "What kind
 
 The server watches a directory for HTML files and serves the newest one to the browser. You write HTML content to `screen_dir`, the user sees it in their browser and can click to select options. Selections are recorded to `state_dir/events` that you read on your next turn.
 
-**Content fragments vs full documents:** If your HTML file starts with `<!DOCTYPE` or `<html`, the server serves it as-is (just injects the helper script). Otherwise, the server automatically wraps your content in the frame template — adding the header, CSS theme, selection indicator, and all interactive infrastructure. **Write content fragments by default.** Only write full documents when you need complete control over the page.
+**Content fragments vs full documents:** If your HTML file starts with `<!DOCTYPE` or `<html`, the server serves it as-is (just injects the helper script). Otherwise, the server automatically wraps your content in the frame template — adding the header, CSS theme, connection status, and all interactive infrastructure. **Write content fragments by default.** Only write full documents when you need complete control over the page.
 
 ## Starting a Session
 
 ```bash
-# Start server with persistence (mockups saved to project)
-scripts/start-server.sh --project-dir /path/to/project
+# Start AFTER the user approves the companion. --open auto-opens their browser on
+# the first screen; --project-dir persists mockups and enables same-port restart.
+scripts/start-server.sh --project-dir /path/to/project --open
 
-# Returns: {"type":"server-started","port":52341,"url":"http://localhost:52341",
+# Returns: {"type":"server-started","port":52341,
+#           "url":"http://localhost:52341/?key=ab12…",
 #           "screen_dir":"/path/to/project/.superpowers/brainstorm/12345-1706000000/content",
 #           "state_dir":"/path/to/project/.superpowers/brainstorm/12345-1706000000/state"}
 ```
 
-Save `screen_dir` and `state_dir` from the response. Tell user to open the URL.
+Save `screen_dir` and `state_dir` from the response. With `--open`, the browser opens itself when you push the first screen — you don't need to ask the user to open it, but still share the URL as a fallback (headless/remote setups won't auto-open).
+
+**The URL contains a session key (`?key=…`).** The server rejects any request
+without it, so always give the user the **complete** URL from the `url` field —
+never strip the query string, and never hand out a bare `http://host:port`. The
+key gates HTTP and WebSocket access so a stray browser tab or another machine on
+the network can't read the screens or inject events. After the first load the
+browser remembers the key via a cookie, so reloads and `/files/*` assets work
+without repeating it.
 
 **Finding connection info:** The server writes its startup JSON to `$STATE_DIR/server-info`. If you launched the server in the background and didn't capture stdout, read that file to get the URL and port. When using `--project-dir`, check `<project>/.superpowers/brainstorm/` for the session directory.
 
@@ -49,33 +59,34 @@ Save `screen_dir` and `state_dir` from the response. Tell user to open the URL.
 
 **Launching the server by platform:**
 
-**Claude Code (macOS / Linux):**
+**Claude Code:**
 ```bash
-# Default mode works — the script backgrounds the server itself
-scripts/start-server.sh --project-dir /path/to/project
+# Default mode works — the script backgrounds the server itself.
+scripts/start-server.sh --project-dir /path/to/project --open
 ```
 
-**Claude Code (Windows):**
-```bash
-# Windows auto-detects and uses foreground mode, which blocks the tool call.
-# Use run_in_background: true on the Bash tool call so the server survives
-# across conversation turns.
-scripts/start-server.sh --project-dir /path/to/project
-```
-When calling this via the Bash tool, set `run_in_background: true`. Then read `$STATE_DIR/server-info` on the next turn to get the URL and port.
+On Windows, the script auto-detects and switches to foreground mode (which blocks the tool call). Use `run_in_background: true` on the Bash tool call so the server survives across conversation turns, then read `$STATE_DIR/server-info` on the next turn to get the URL and port.
 
 **Codex:**
 ```bash
 # Codex reaps background processes. The script auto-detects CODEX_CI and
 # switches to foreground mode. Run it normally — no extra flags needed.
-scripts/start-server.sh --project-dir /path/to/project
+scripts/start-server.sh --project-dir /path/to/project --open
 ```
 
 **Gemini CLI:**
 ```bash
 # Use --foreground and set is_background: true on your shell tool call
 # so the process survives across turns
-scripts/start-server.sh --project-dir /path/to/project --foreground
+scripts/start-server.sh --project-dir /path/to/project --open --foreground
+```
+
+**Copilot CLI:**
+```bash
+# Use --foreground and start the server via the bash tool with mode: "async"
+# so the process survives across turns. Capture the returned shellId for
+# read_bash / stop_bash if you need to interact with it later.
+scripts/start-server.sh --project-dir /path/to/project --open --foreground
 ```
 
 **Other environments:** The server must keep running in the background across conversation turns. If your environment reaps detached processes, use `--foreground` and launch the command with your platform's background execution mechanism.
@@ -94,10 +105,10 @@ Use `--url-host` to control what hostname is printed in the returned URL JSON.
 ## The Loop
 
 1. **Check server is alive**, then **write HTML** to a new file in `screen_dir`:
-   - Before each write, check that `$STATE_DIR/server-info` exists. If it doesn't (or `$STATE_DIR/server-stopped` exists), the server has shut down — restart it with `start-server.sh` before continuing. The server auto-exits after 30 minutes of inactivity.
+   - **Required: confirm the server is alive before referring to the URL or pushing a screen.** Check that `$STATE_DIR/server-info` exists and `$STATE_DIR/server-stopped` does not. If it has shut down, restart it with `start-server.sh` using the **same `--project-dir`** — it reuses the same port, so the user's open tab reconnects on its own (it shows a "paused" overlay while the server is down) and you don't need to send a new URL. The server auto-exits after 4 hours idle (configurable with `--idle-timeout-minutes`).
    - Use semantic filenames: `platform.html`, `visual-style.html`, `layout.html`
    - **Never reuse filenames** — each screen gets a fresh file
-   - Use Write tool — **never use cat/heredoc** (dumps noise into terminal)
+   - Use your file-creation tool — **never use cat/heredoc** (dumps noise into terminal)
    - Server automatically serves the newest file
 
 2. **Tell user what to expect and end your turn:**
@@ -127,7 +138,7 @@ Use `--url-host` to control what hostname is printed in the returned URL JSON.
 
 ## Writing Content Fragments
 
-Write just the content that goes inside the page. The server wraps it in the frame template automatically (header, theme CSS, selection indicator, and all interactive infrastructure).
+Write just the content that goes inside the page. The server wraps it in the frame template automatically (header, theme CSS, connection status, and all interactive infrastructure).
 
 **Minimal example:**
 
@@ -173,7 +184,7 @@ The frame template provides these CSS classes for your content:
 </div>
 ```
 
-**Multi-select:** Add `data-multiselect` to the container to let users select multiple options. Each click toggles the item. The indicator bar shows the count.
+**Multi-select:** Add `data-multiselect` to the container to let users select multiple options. Each click toggles the item's selected styling.
 
 ```html
 <div class="options" data-multiselect>
diff --git a/skills/superpowers/dispatching-parallel-agents/SKILL.md b/skills/superpowers/dispatching-parallel-agents/SKILL.md
index a6a3f5a..75e7e22 100644
--- a/skills/superpowers/dispatching-parallel-agents/SKILL.md
+++ b/skills/superpowers/dispatching-parallel-agents/SKILL.md
@@ -65,14 +65,17 @@ Each agent gets:
 
 ### 3. Dispatch in Parallel
 
-```typescript
-// In Claude Code / AI environment
-Task("Fix agent-tool-abort.test.ts failures")
-Task("Fix batch-completion-behavior.test.ts failures")
-Task("Fix tool-approval-race-conditions.test.ts failures")
-// All three run concurrently
+Issue all three subagent dispatches in the same response — they run in parallel:
+
+```text
+Subagent (general-purpose): "Fix agent-tool-abort.test.ts failures"
+Subagent (general-purpose): "Fix batch-completion-behavior.test.ts failures"
+Subagent (general-purpose): "Fix tool-approval-race-conditions.test.ts failures"
+# All three run concurrently.
 ```
 
+Multiple dispatch calls in one response = parallel execution. One per response = sequential.
+
 ### 4. Review and Integrate
 
 When agents return:
diff --git a/skills/superpowers/executing-plans/SKILL.md b/skills/superpowers/executing-plans/SKILL.md
index a591862..78d8854 100644
--- a/skills/superpowers/executing-plans/SKILL.md
+++ b/skills/superpowers/executing-plans/SKILL.md
@@ -11,7 +11,7 @@ Load plan, review critically, execute all tasks, report when complete.
 
 **Announce at start:** "I'm using the executing-plans skill to implement this plan."
 
-**Note:** Tell your human partner that Superpowers works much better with access to subagents. The quality of its work will be significantly higher if run on a platform with subagent support (such as Claude Code or Codex). If subagents are available, use superpowers:subagent-driven-development instead of this skill.
+**Note:** Tell your human partner that Superpowers works much better with access to subagents. The quality of its work will be significantly higher if run on a platform with subagent support (Claude Code, Codex CLI, Codex App, Copilot CLI, and Gemini CLI all qualify; see the per-platform tool refs in `../using-superpowers/references/`). If subagents are available, use superpowers:subagent-driven-development instead of this skill.
 
 ## The Process
 
@@ -19,7 +19,7 @@ Load plan, review critically, execute all tasks, report when complete.
 1. Read plan file
 2. Review critically - identify any questions or concerns about the plan
 3. If concerns: Raise them with your human partner before starting
-4. If no concerns: Create TodoWrite and proceed
+4. If no concerns: Create todos for the plan items and proceed
 
 ### Step 2: Execute Tasks
 
diff --git a/skills/superpowers/finishing-a-development-branch/SKILL.md b/skills/superpowers/finishing-a-development-branch/SKILL.md
index 43da0ae..7f5337a 100644
--- a/skills/superpowers/finishing-a-development-branch/SKILL.md
+++ b/skills/superpowers/finishing-a-development-branch/SKILL.md
@@ -123,16 +123,6 @@ git branch -d <feature-branch>
 ```bash
 # Push branch
 git push -u origin <feature-branch>
-
-# Create PR
-gh pr create --title "<title>" --body "$(cat <<'EOF'
-## Summary
-<2-3 bullets of what changed>
-
-## Test Plan
-- [ ] <verification steps>
-EOF
-)"
 ```
 
 **Do NOT clean up worktree** — user needs it alive to iterate on PR feedback.
@@ -180,7 +170,7 @@ WORKTREE_PATH=$(git rev-parse --show-toplevel)
 
 **If `GIT_DIR == GIT_COMMON`:** Normal repo, no worktree to clean up. Done.
 
-**If worktree path is under `.worktrees/`, `worktrees/`, or `~/.config/superpowers/worktrees/`:** Superpowers created this worktree — we own cleanup.
+**If worktree path is under `.worktrees/` or `worktrees/`:** Superpowers created this worktree — we own cleanup.
 
 ```bash
 MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
@@ -224,7 +214,7 @@ git worktree prune  # Self-healing: clean up any stale registrations
 
 **Cleaning up harness-owned worktrees**
 - **Problem:** Removing a worktree the harness created causes phantom state
-- **Fix:** Only clean up worktrees under `.worktrees/`, `worktrees/`, or `~/.config/superpowers/worktrees/`
+- **Fix:** Only clean up worktrees under `.worktrees/` or `worktrees/`
 
 **No confirmation for discard**
 - **Problem:** Accidentally delete work
diff --git a/skills/superpowers/receiving-code-review/SKILL.md b/skills/superpowers/receiving-code-review/SKILL.md
index 4ea72cd..4c77a10 100644
--- a/skills/superpowers/receiving-code-review/SKILL.md
+++ b/skills/superpowers/receiving-code-review/SKILL.md
@@ -27,7 +27,7 @@ WHEN receiving code review feedback:
 ## Forbidden Responses
 
 **NEVER:**
-- "You're absolutely right!" (explicit CLAUDE.md violation)
+- "You're absolutely right!" (explicit instruction-file violation)
 - "Great point!" / "Excellent feedback!" (performative)
 - "Let me implement that now" (before verification)
 
@@ -126,7 +126,7 @@ Push back when:
 - Reference working tests/code
 - Involve your human partner if architectural
 
-**Signal if uncomfortable pushing back out loud:** "Strange things are afoot at the Circle K"
+**If you're uncomfortable pushing back out loud:** Name that tension, then tell your partner about the issue you've seen. They'll appreciate your honesty.
 
 ## Acknowledging Correct Feedback
 
diff --git a/skills/superpowers/requesting-code-review/SKILL.md b/skills/superpowers/requesting-code-review/SKILL.md
index 34b8340..4b8aa60 100644
--- a/skills/superpowers/requesting-code-review/SKILL.md
+++ b/skills/superpowers/requesting-code-review/SKILL.md
@@ -31,7 +31,7 @@ HEAD_SHA=$(git rev-parse HEAD)
 
 **2. Dispatch code reviewer subagent:**
 
-Use Task tool with `general-purpose` type, fill template at `code-reviewer.md`
+Dispatch a `general-purpose` subagent, filling the template at [code-reviewer.md](code-reviewer.md)
 
 **Placeholders:**
 - `{DESCRIPTION}` - Brief summary of what you built
@@ -100,4 +100,4 @@ You: [Fix progress indicators]
 - Show code/tests that prove it works
 - Request clarification
 
-See template at: requesting-code-review/code-reviewer.md
+See template at: [code-reviewer.md](code-reviewer.md)
diff --git a/skills/superpowers/requesting-code-review/code-reviewer.md b/skills/superpowers/requesting-code-review/code-reviewer.md
index 525e4b4..db84ae2 100644
--- a/skills/superpowers/requesting-code-review/code-reviewer.md
+++ b/skills/superpowers/requesting-code-review/code-reviewer.md
@@ -5,7 +5,7 @@ Use this template when dispatching a code reviewer subagent.
 **Purpose:** Review completed work against requirements and code quality standards before it cascades into more work.
 
 ```
-Task tool (general-purpose):
+Subagent (general-purpose):
   description: "Review code changes"
   prompt: |
     You are a Senior Code Reviewer with expertise in software architecture,
@@ -14,22 +14,26 @@ Task tool (general-purpose):
 
     ## What Was Implemented
 
-    {DESCRIPTION}
+    [DESCRIPTION]
 
     ## Requirements / Plan
 
-    {PLAN_OR_REQUIREMENTS}
+    [PLAN_OR_REQUIREMENTS]
 
     ## Git Range to Review
 
-    **Base:** {BASE_SHA}
-    **Head:** {HEAD_SHA}
+    **Base:** [BASE_SHA]
+    **Head:** [HEAD_SHA]
 
     ```bash
-    git diff --stat {BASE_SHA}..{HEAD_SHA}
-    git diff {BASE_SHA}..{HEAD_SHA}
+    git diff --stat [BASE_SHA]..[HEAD_SHA]
+    git diff [BASE_SHA]..[HEAD_SHA]
     ```
 
+    ## Read-Only Review
+
+    Your review is read-only on this checkout. Do not mutate the working tree, the index, HEAD, or branch state in any way. Use tools like `git show`, `git diff`, and `git log` to inspect history. If you need a working copy of a different revision, check it out into a separate temporary directory (e.g. `git worktree add /tmp/review-[SHA] [SHA]`) — never move HEAD on this checkout.
+
     ## What to Check
 
     **Plan alignment:**
@@ -122,10 +126,10 @@ Task tool (general-purpose):
 ```
 
 **Placeholders:**
-- `{DESCRIPTION}` — brief summary of what was built
-- `{PLAN_OR_REQUIREMENTS}` — what it should do (plan file path, task text, or requirements)
-- `{BASE_SHA}` — starting commit
-- `{HEAD_SHA}` — ending commit
+- `[DESCRIPTION]` — brief summary of what was built
+- `[PLAN_OR_REQUIREMENTS]` — what it should do (plan file path, task text, or requirements)
+- `[BASE_SHA]` — starting commit
+- `[HEAD_SHA]` — ending commit
 
 **Reviewer returns:** Strengths, Issues (Critical / Important / Minor), Recommendations, Assessment
 
diff --git a/skills/superpowers/subagent-driven-development/SKILL.md b/skills/superpowers/subagent-driven-development/SKILL.md
index ea7ac8f..d8ca081 100644
--- a/skills/superpowers/subagent-driven-development/SKILL.md
+++ b/skills/superpowers/subagent-driven-development/SKILL.md
@@ -5,11 +5,14 @@ description: Use when executing implementation plans with independent tasks in t
 
 # Subagent-Driven Development
 
-Execute plan by dispatching fresh subagent per task, with two-stage review after each: spec compliance review first, then code quality review.
+Execute plan by dispatching a fresh implementer subagent per task, a task review (spec compliance + code quality) after each, and a broad whole-branch review at the end.
 
 **Why subagents:** You delegate tasks to specialized agents with isolated context. By precisely crafting their instructions and context, you ensure they stay focused and succeed at their task. They should never inherit your session's context or history — you construct exactly what they need. This also preserves your own context for coordination work.
 
-**Core principle:** Fresh subagent per task + two-stage review (spec then quality) = high quality, fast iteration
+**Core principle:** Fresh subagent per task + task review (spec + quality) + broad final review = high quality, fast iteration
+
+**Narration:** between tool calls, narrate at most one short line — the
+ledger and the tool results carry the record.
 
 **Continuous execution:** Do not pause to check in with your human partner between tasks. Execute all tasks from the plan without stopping. The only reasons to stop are: BLOCKED status you cannot resolve, ambiguity that genuinely prevents progress, or all tasks complete. "Should I continue?" prompts and progress summaries waste their time — they asked you to execute the plan, so execute it.
 
@@ -36,7 +39,7 @@ digraph when_to_use {
 **vs. Executing Plans (parallel session):**
 - Same session (no context switch)
 - Fresh subagent per task (no context pollution)
-- Two-stage review after each task: spec compliance first, then code quality
+- Review after each task (spec compliance + code quality), broad review at the end
 - Faster iteration (no human-in-loop between tasks)
 
 ## The Process
@@ -51,41 +54,48 @@ digraph process {
         "Implementer subagent asks questions?" [shape=diamond];
         "Answer questions, provide context" [shape=box];
         "Implementer subagent implements, tests, commits, self-reviews" [shape=box];
-        "Dispatch spec reviewer subagent (./spec-reviewer-prompt.md)" [shape=box];
-        "Spec reviewer subagent confirms code matches spec?" [shape=diamond];
-        "Implementer subagent fixes spec gaps" [shape=box];
-        "Dispatch code quality reviewer subagent (./code-quality-reviewer-prompt.md)" [shape=box];
-        "Code quality reviewer subagent approves?" [shape=diamond];
-        "Implementer subagent fixes quality issues" [shape=box];
-        "Mark task complete in TodoWrite" [shape=box];
+        "Write diff file, dispatch task reviewer subagent (./task-reviewer-prompt.md)" [shape=box];
+        "Task reviewer reports spec ✅ and quality approved?" [shape=diamond];
+        "Dispatch fix subagent for Critical/Important findings" [shape=box];
+        "Mark task complete in todo list and progress ledger" [shape=box];
     }
 
-    "Read plan, extract all tasks with full text, note context, create TodoWrite" [shape=box];
+    "Read plan, note context and global constraints, create todos" [shape=box];
     "More tasks remain?" [shape=diamond];
-    "Dispatch final code reviewer subagent for entire implementation" [shape=box];
+    "Dispatch final code reviewer subagent (../requesting-code-review/code-reviewer.md)" [shape=box];
     "Use superpowers:finishing-a-development-branch" [shape=box style=filled fillcolor=lightgreen];
 
-    "Read plan, extract all tasks with full text, note context, create TodoWrite" -> "Dispatch implementer subagent (./implementer-prompt.md)";
+    "Read plan, note context and global constraints, create todos" -> "Dispatch implementer subagent (./implementer-prompt.md)";
     "Dispatch implementer subagent (./implementer-prompt.md)" -> "Implementer subagent asks questions?";
     "Implementer subagent asks questions?" -> "Answer questions, provide context" [label="yes"];
     "Answer questions, provide context" -> "Dispatch implementer subagent (./implementer-prompt.md)";
     "Implementer subagent asks questions?" -> "Implementer subagent implements, tests, commits, self-reviews" [label="no"];
-    "Implementer subagent implements, tests, commits, self-reviews" -> "Dispatch spec reviewer subagent (./spec-reviewer-prompt.md)";
-    "Dispatch spec reviewer subagent (./spec-reviewer-prompt.md)" -> "Spec reviewer subagent confirms code matches spec?";
-    "Spec reviewer subagent confirms code matches spec?" -> "Implementer subagent fixes spec gaps" [label="no"];
-    "Implementer subagent fixes spec gaps" -> "Dispatch spec reviewer subagent (./spec-reviewer-prompt.md)" [label="re-review"];
-    "Spec reviewer subagent confirms code matches spec?" -> "Dispatch code quality reviewer subagent (./code-quality-reviewer-prompt.md)" [label="yes"];
-    "Dispatch code quality reviewer subagent (./code-quality-reviewer-prompt.md)" -> "Code quality reviewer subagent approves?";
-    "Code quality reviewer subagent approves?" -> "Implementer subagent fixes quality issues" [label="no"];
-    "Implementer subagent fixes quality issues" -> "Dispatch code quality reviewer subagent (./code-quality-reviewer-prompt.md)" [label="re-review"];
-    "Code quality reviewer subagent approves?" -> "Mark task complete in TodoWrite" [label="yes"];
-    "Mark task complete in TodoWrite" -> "More tasks remain?";
+    "Implementer subagent implements, tests, commits, self-reviews" -> "Write diff file, dispatch task reviewer subagent (./task-reviewer-prompt.md)";
+    "Write diff file, dispatch task reviewer subagent (./task-reviewer-prompt.md)" -> "Task reviewer reports spec ✅ and quality approved?";
+    "Task reviewer reports spec ✅ and quality approved?" -> "Dispatch fix subagent for Critical/Important findings" [label="no"];
+    "Dispatch fix subagent for Critical/Important findings" -> "Write diff file, dispatch task reviewer subagent (./task-reviewer-prompt.md)" [label="re-review"];
+    "Task reviewer reports spec ✅ and quality approved?" -> "Mark task complete in todo list and progress ledger" [label="yes"];
+    "Mark task complete in todo list and progress ledger" -> "More tasks remain?";
     "More tasks remain?" -> "Dispatch implementer subagent (./implementer-prompt.md)" [label="yes"];
-    "More tasks remain?" -> "Dispatch final code reviewer subagent for entire implementation" [label="no"];
-    "Dispatch final code reviewer subagent for entire implementation" -> "Use superpowers:finishing-a-development-branch";
+    "More tasks remain?" -> "Dispatch final code reviewer subagent (../requesting-code-review/code-reviewer.md)" [label="no"];
+    "Dispatch final code reviewer subagent (../requesting-code-review/code-reviewer.md)" -> "Use superpowers:finishing-a-development-branch";
 }
 ```
 
+## Pre-Flight Plan Review
+
+Before dispatching Task 1, scan the plan once for conflicts:
+
+- tasks that contradict each other or the plan's Global Constraints
+- anything the plan explicitly mandates that the review rubric treats as a
+  defect (a test that asserts nothing, verbatim duplication of a logic block)
+
+Present everything you find to your human partner as one batched question —
+each finding beside the plan text that mandates it, asking which governs —
+before execution begins, not one interrupt per discovery mid-plan. If the
+scan is clean, proceed without comment. The review loop remains the net for
+conflicts that only emerge from implementation.
+
 ## Model Selection
 
 Use the least powerful model that can handle each role to conserve cost and increase speed.
@@ -94,9 +104,27 @@ Use the least powerful model that can handle each role to conserve cost and incr
 
 **Integration and judgment tasks** (multi-file coordination, pattern matching, debugging): use a standard model.
 
-**Architecture, design, and review tasks**: use the most capable available model.
+**Architecture and design tasks**: use the most capable available model.
+The final whole-branch review is one of these — dispatch it on the most
+capable available model, not the session default.
+
+**Review tasks**: choose the model with the same judgment, scaled to the
+diff's size, complexity, and risk. A small mechanical diff does not need the
+most capable model; a subtle concurrency change does.
+
+**Always specify the model explicitly when dispatching a subagent.** An
+omitted model inherits your session's model — often the most capable and
+most expensive — which silently defeats this section.
 
-**Task complexity signals:**
+**Turn count beats token price.** Wall-clock and context cost scale with how
+many turns a subagent takes, and the cheapest models routinely take 2-3× the
+turns on multi-step work — costing more overall. Use a mid-tier model as the
+floor for reviewers and for implementers working from prose descriptions.
+When the task's plan text contains the complete code to write, the
+implementation is transcription plus testing: use the cheapest tier for
+that implementer. Single-file mechanical fixes also take the cheapest tier.
+
+**Task complexity signals (implementation tasks):**
 - Touches 1-2 files with a complete spec → cheap model
 - Touches multiple files with integration concerns → standard model
 - Requires design judgment or broad codebase understanding → most capable model
@@ -105,7 +133,7 @@ Use the least powerful model that can handle each role to conserve cost and incr
 
 Implementer subagents report one of four statuses. Handle each appropriately:
 
-**DONE:** Proceed to spec compliance review.
+**DONE:** Generate the review package (`scripts/review-package BASE HEAD`, from this skill's directory — it prints the unique file path it wrote; BASE is the commit you recorded before dispatching the implementer — never `HEAD~1`, which silently drops all but the last commit of a multi-commit task), then dispatch the task reviewer with the printed path.
 
 **DONE_WITH_CONCERNS:** The implementer completed the work but flagged doubts. Read the concerns before proceeding. If the concerns are about correctness or scope, address them before review. If they're observations (e.g., "this file is getting large"), note them and proceed to review.
 
@@ -119,11 +147,127 @@ Implementer subagents report one of four statuses. Handle each appropriately:
 
 **Never** ignore an escalation or force the same model to retry without changes. If the implementer said it's stuck, something needs to change.
 
+## Handling Reviewer ⚠️ Items
+
+The task reviewer may report "⚠️ Cannot verify from diff" items — requirements
+that live in unchanged code or span tasks. These do not block the rest of the
+review, but you must resolve each one yourself before marking the task
+complete: you hold the plan and cross-task context the reviewer
+lacks. If you confirm an item is a real gap, treat it as a failed spec
+review — send it back to the implementer and re-review.
+
+## Constructing Reviewer Prompts
+
+Per-task reviews are task-scoped gates. The broad review happens once, at the
+final whole-branch review. When you fill a reviewer template:
+
+- Do not add open-ended directives like "check all uses" or "run race tests
+  if useful" without a concrete, task-specific reason
+- Do not ask a reviewer to re-run tests the implementer already ran on the
+  same code — the implementer's report carries the test evidence
+- Do not pre-judge findings for the reviewer — never instruct a reviewer to
+  ignore or not flag a specific issue. If you believe a finding would be a
+  false positive, let the reviewer raise it and adjudicate it in the review
+  loop. If the prompt you are writing contains "do not flag," "don't treat X
+  as a defect," "at most Minor," or "the plan chose" — stop: you are
+  pre-judging, usually to spare yourself a review loop.
+- The global-constraints block you hand the reviewer is its attention
+  lens. Copy the binding requirements verbatim from the plan's Global
+  Constraints section or the spec: exact values, exact formats, and the
+  stated relationships between components ("same layout as X", "matches
+  Y"). The reviewer's template already carries the process rules (YAGNI,
+  test hygiene, review method) — the constraints block is for what THIS
+  project's spec demands.
+- Hand the reviewer its diff as a file: run this skill's
+  `scripts/review-package BASE HEAD` and pass the reviewer the file path
+  it prints (or, without bash: `git log --oneline`, `git diff --stat`,
+  and `git diff -U10` for the range, redirected to one uniquely named
+  file). The output never enters your own context, and the reviewer sees
+  the commit list, stat summary, and full diff with context in one Read
+  call. Use the BASE you recorded before dispatching the implementer —
+  never `HEAD~1`, which silently truncates multi-commit tasks.
+- A dispatch prompt describes one task, not the session's history. Do not
+  paste accumulated prior-task summaries ("state after Tasks 1-3") into
+  later dispatches — a real session's dispatch hit 42k chars of which 99%
+  was pasted history. A fresh subagent needs its task, the interfaces it
+  touches, and the global constraints. Nothing else.
+- Dispatch fix subagents for Critical and Important findings. Record Minor
+  findings in the progress ledger as you go, and point the final
+  whole-branch review at that list so it can triage which must be fixed
+  before merge. A roll-up nobody reads is a silent discard.
+- A finding labeled plan-mandated — or any finding that conflicts with
+  what the plan's text requires — is the human's decision, like any plan
+  contradiction: present the finding and the plan text, ask which governs.
+  Do not dismiss the finding because the plan mandates it, and do not
+  dispatch a fix that contradicts the plan without asking.
+- The final whole-branch review gets a package too: run
+  `scripts/review-package MERGE_BASE HEAD` (MERGE_BASE = the commit the
+  branch started from, e.g. `git merge-base main HEAD`) and include the
+  printed path in the final review dispatch, so the final reviewer reads
+  one file instead of re-deriving the branch diff with git commands.
+- Every fix dispatch carries the implementer contract: the fix subagent
+  re-runs the tests covering its change and reports the results. Name the
+  covering test files in the dispatch — a one-line fix does not need the
+  whole suite. Before re-dispatching the reviewer, confirm the fix report
+  contains the covering tests, the command run, and the output; dispatch
+  the re-review once all three are present.
+- If the final whole-branch review returns findings, dispatch ONE fix
+  subagent with the complete findings list — not one fixer per finding.
+  Per-finding fixers each rebuild context and re-run suites; a real
+  session's final-review fix wave cost more than all its tasks combined.
+
+## File Handoffs
+
+Everything you paste into a dispatch prompt — and everything a subagent
+prints back — stays resident in your context for the rest of the session
+and is re-read on every later turn. Hand artifacts over as files:
+
+- **Task brief:** before dispatching an implementer, run this skill's
+  `scripts/task-brief PLAN_FILE N` — it extracts the task's full text to a
+  uniquely named file and prints the path. Compose the dispatch so the
+  brief stays the single source of requirements. Your dispatch should
+  contain: (1) one line on where this task fits in the project; (2) the
+  brief path, introduced as "read this first — it is your requirements,
+  with the exact values to use verbatim"; (3) interfaces and decisions
+  from earlier tasks that the brief cannot know; (4) your resolution of
+  any ambiguity you noticed in the brief; (5) the report-file path and
+  report contract. Exact values (numbers, magic strings, signatures, test
+  cases) appear only in the brief.
+- **Report file:** name the implementer's report file after the brief
+  (brief `…/task-N-brief.md` → report `…/task-N-report.md`) and put it in
+  the dispatch prompt. The implementer writes the full report there and
+  returns only status, commits, a one-line test summary, and concerns.
+- **Reviewer inputs:** the task reviewer gets three paths — the same brief
+  file, the report file, and the review package — plus the global
+  constraints that bind the task.
+- Fix dispatches append their fix report (with test results) to the same
+  report file and return a short summary; re-reviews read the updated file.
+
+## Durable Progress
+
+Conversation memory does not survive compaction. In real sessions,
+controllers that lost their place have re-dispatched entire completed task
+sequences — the single most expensive failure observed. Track progress in
+a ledger file, not only in todos.
+
+- At skill start, check for a ledger:
+  `cat "$(git rev-parse --show-toplevel)/.superpowers/sdd/progress.md"`. Tasks listed there
+  as complete are DONE — do not re-dispatch them; resume at the first task
+  not marked complete.
+- When a task's review comes back clean, append one line to the ledger in
+  the same message as your other bookkeeping:
+  `Task N: complete (commits <base7>..<head7>, review clean)`.
+- The ledger is your recovery map: the commits it names exist in git even
+  when your context no longer remembers creating them. After compaction,
+  trust the ledger and `git log` over your own recollection.
+- `git clean -fdx` will destroy the ledger (it's git-ignored scratch); if
+  that happens, recover from `git log`.
+
 ## Prompt Templates
 
-- `./implementer-prompt.md` - Dispatch implementer subagent
-- `./spec-reviewer-prompt.md` - Dispatch spec compliance reviewer subagent
-- `./code-quality-reviewer-prompt.md` - Dispatch code quality reviewer subagent
+- [implementer-prompt.md](implementer-prompt.md) - Dispatch implementer subagent
+- [task-reviewer-prompt.md](task-reviewer-prompt.md) - Dispatch task reviewer subagent (spec compliance + code quality)
+- Final whole-branch review: use superpowers:requesting-code-review's [code-reviewer.md](../requesting-code-review/code-reviewer.md)
 
 ## Example Workflow
 
@@ -131,13 +275,11 @@ Implementer subagents report one of four statuses. Handle each appropriately:
 You: I'm using Subagent-Driven Development to execute this plan.
 
 [Read plan file once: docs/superpowers/plans/feature-plan.md]
-[Extract all 5 tasks with full text and context]
-[Create TodoWrite with all tasks]
+[Create todos for all tasks]
 
 Task 1: Hook installation script
 
-[Get Task 1 text and context (already extracted)]
-[Dispatch implementation subagent with full task text + context]
+[Run task-brief for Task 1; dispatch implementer with brief + report paths + context]
 
 Implementer: "Before I begin - should the hook be installed at user or system level?"
 
@@ -150,18 +292,15 @@ Implementer: "Got it. Implementing now..."
   - Self-review: Found I missed --force flag, added it
   - Committed
 
-[Dispatch spec compliance reviewer]
-Spec reviewer: ✅ Spec compliant - all requirements met, nothing extra
-
-[Get git SHAs, dispatch code quality reviewer]
-Code reviewer: Strengths: Good test coverage, clean. Issues: None. Approved.
+[Run review-package, dispatch task reviewer with the printed path]
+Task reviewer: Spec ✅ - all requirements met, nothing extra.
+  Strengths: Good test coverage, clean. Issues: None. Task quality: Approved.
 
 [Mark Task 1 complete]
 
 Task 2: Recovery modes
 
-[Get Task 2 text and context (already extracted)]
-[Dispatch implementation subagent with full task text + context]
+[Run task-brief for Task 2; dispatch implementer with brief + report paths + context]
 
 Implementer: [No questions, proceeds]
 Implementer:
@@ -170,25 +309,17 @@ Implementer:
   - Self-review: All good
   - Committed
 
-[Dispatch spec compliance reviewer]
-Spec reviewer: ❌ Issues:
+[Run review-package, dispatch task reviewer with the printed path]
+Task reviewer: Spec ❌:
   - Missing: Progress reporting (spec says "report every 100 items")
   - Extra: Added --json flag (not requested)
+  Issues (Important): Magic number (100)
 
-[Implementer fixes issues]
-Implementer: Removed --json flag, added progress reporting
-
-[Spec reviewer reviews again]
-Spec reviewer: ✅ Spec compliant now
-
-[Dispatch code quality reviewer]
-Code reviewer: Strengths: Solid. Issues (Important): Magic number (100)
-
-[Implementer fixes]
-Implementer: Extracted PROGRESS_INTERVAL constant
+[Dispatch fix subagent with all findings]
+Fixer: Removed --json flag, added progress reporting, extracted PROGRESS_INTERVAL constant
 
-[Code reviewer reviews again]
-Code reviewer: ✅ Approved
+[Task reviewer reviews again]
+Task reviewer: Spec ✅. Task quality: Approved.
 
 [Mark Task 2 complete]
 
@@ -215,20 +346,20 @@ Done!
 - Review checkpoints automatic
 
 **Efficiency gains:**
-- No file reading overhead (controller provides full text)
-- Controller curates exactly what context is needed
+- Controller curates exactly what context is needed; bulk artifacts move
+  as files, not pasted text
 - Subagent gets complete information upfront
 - Questions surfaced before work begins (not after)
 
 **Quality gates:**
 - Self-review catches issues before handoff
-- Two-stage review: spec compliance, then code quality
+- Task review carries two verdicts: spec compliance and code quality
 - Review loops ensure fixes actually work
 - Spec compliance prevents over/under-building
 - Code quality ensures implementation is well-built
 
 **Cost:**
-- More subagent invocations (implementer + 2 reviewers per task)
+- More subagent invocations (implementer + reviewer per task)
 - Controller does more prep work (extracting all tasks upfront)
 - Review loops add iterations
 - But catches issues early (cheaper than debugging later)
@@ -237,17 +368,25 @@ Done!
 
 **Never:**
 - Start implementation on main/master branch without explicit user consent
-- Skip reviews (spec compliance OR code quality)
+- Skip task review, or accept a report missing either verdict (spec compliance AND task quality are both required)
 - Proceed with unfixed issues
 - Dispatch multiple implementation subagents in parallel (conflicts)
-- Make subagent read plan file (provide full text instead)
+- Make a subagent read the whole plan file (hand it its task brief —
+  `scripts/task-brief` — instead)
 - Skip scene-setting context (subagent needs to understand where task fits)
 - Ignore subagent questions (answer before letting them proceed)
-- Accept "close enough" on spec compliance (spec reviewer found issues = not done)
+- Accept "close enough" on spec compliance (reviewer found spec issues = not done)
 - Skip review loops (reviewer found issues = implementer fixes = review again)
 - Let implementer self-review replace actual review (both are needed)
-- **Start code quality review before spec compliance is ✅** (wrong order)
-- Move to next task while either review has open issues
+- Tell a reviewer what not to flag, or pre-rate a finding's severity in the
+  dispatch prompt ("treat it as Minor at most") — the plan's example code is
+  a starting point, not evidence that its weaknesses were chosen
+- Dispatch a task reviewer without a diff file — generate it first
+  (`scripts/review-package BASE HEAD`) and name the printed path in the
+  prompt
+- Move to next task while the review has open Critical/Important issues
+- Re-dispatch a task the progress ledger already marks complete — check
+  the ledger (and `git log`) after any compaction or resume
 
 **If subagent asks questions:**
 - Answer clearly and completely
@@ -269,7 +408,7 @@ Done!
 **Required workflow skills:**
 - **superpowers:using-git-worktrees** - Ensures isolated workspace (creates one or verifies existing)
 - **superpowers:writing-plans** - Creates the plan this skill executes
-- **superpowers:requesting-code-review** - Code review template for reviewer subagents
+- **superpowers:requesting-code-review** - Code review template for the final whole-branch review
 - **superpowers:finishing-a-development-branch** - Complete development after all tasks
 
 **Subagents should use:**
diff --git a/skills/superpowers/subagent-driven-development/code-quality-reviewer-prompt.md b/skills/superpowers/subagent-driven-development/code-quality-reviewer-prompt.md
deleted file mode 100644
index 51f901a..0000000
--- a/skills/superpowers/subagent-driven-development/code-quality-reviewer-prompt.md
+++ /dev/null
@@ -1,25 +0,0 @@
-# Code Quality Reviewer Prompt Template
-
-Use this template when dispatching a code quality reviewer subagent.
-
-**Purpose:** Verify implementation is well-built (clean, tested, maintainable)
-
-**Only dispatch after spec compliance review passes.**
-
-```
-Task tool (general-purpose):
-  Use template at requesting-code-review/code-reviewer.md
-
-  DESCRIPTION: [task summary, from implementer's report]
-  PLAN_OR_REQUIREMENTS: Task N from [plan-file]
-  BASE_SHA: [commit before task]
-  HEAD_SHA: [current commit]
-```
-
-**In addition to standard code quality concerns, the reviewer should check:**
-- Does each file have one clear responsibility with a well-defined interface?
-- Are units decomposed so they can be understood and tested independently?
-- Is the implementation following the file structure from the plan?
-- Did this implementation create new files that are already large, or significantly grow existing files? (Don't flag pre-existing file sizes — focus on what this change contributed.)
-
-**Code reviewer returns:** Strengths, Issues (Critical/Important/Minor), Assessment
diff --git a/skills/superpowers/subagent-driven-development/implementer-prompt.md b/skills/superpowers/subagent-driven-development/implementer-prompt.md
index 400c103..218fcfe 100644
--- a/skills/superpowers/subagent-driven-development/implementer-prompt.md
+++ b/skills/superpowers/subagent-driven-development/implementer-prompt.md
@@ -3,14 +3,17 @@
 Use this template when dispatching an implementer subagent.
 
 ```
-Task tool (general-purpose):
+Subagent (general-purpose):
   description: "Implement Task N: [task name]"
+  model: [MODEL — REQUIRED: choose per SKILL.md Model Selection; an omitted
+         model silently inherits the session's most expensive one]
   prompt: |
     You are implementing Task N: [task name]
 
     ## Task Description
 
-    [FULL TEXT of task from plan - paste it here, don't make subagent read file]
+    Read your task brief first: [BRIEF_FILE]
+    It contains the full task text from the plan.
 
     ## Context
 
@@ -41,6 +44,9 @@ Task tool (general-purpose):
     **While you work:** If you encounter something unexpected or unclear, **ask questions**.
     It's always OK to pause and clarify. Don't guess or make assumptions.
 
+    While iterating, run the focused test for what you're changing; run the
+    full suite once before committing, not after every edit.
+
     ## Code Organization
 
     You reason best about code you can hold in context at once, and your edits are more
@@ -94,19 +100,39 @@ Task tool (general-purpose):
     - Do tests actually verify behavior (not just mock behavior)?
     - Did I follow TDD if required?
     - Are tests comprehensive?
+    - Is the test output pristine (no stray warnings or noise)?
 
     If you find issues during self-review, fix them now before reporting.
 
+    ## After Review Findings
+
+    If a reviewer finds issues and you fix them, re-run the tests that cover
+    the amended code and append the results to your report file. Reviewers
+    will not re-run tests for you — your report is the test evidence.
+
     ## Report Format
 
-    When done, report:
-    - **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
+    Write your full report to [REPORT_FILE]:
     - What you implemented (or what you attempted, if blocked)
     - What you tested and test results
+    - **TDD Evidence** (if TDD was required for this task):
+      - RED: command run, relevant failing output before implementation, and why the failure was expected
+      - GREEN: command run and relevant passing output after implementation
     - Files changed
     - Self-review findings (if any)
     - Any issues or concerns
 
+    Then report back with ONLY (under 15 lines — the detail lives in the
+    report file):
+    - **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
+    - Commits created (short SHA + subject)
+    - One-line test summary (e.g. "14/14 passing, output pristine")
+    - Your concerns, if any
+    - The report file path
+
+    If BLOCKED or NEEDS_CONTEXT, put the specifics in the final message
+    itself — the controller acts on it directly.
+
     Use DONE_WITH_CONCERNS if you completed the work but have doubts about correctness.
     Use BLOCKED if you cannot complete the task. Use NEEDS_CONTEXT if you need
     information that wasn't provided. Never silently produce work you're unsure about.
diff --git a/skills/superpowers/subagent-driven-development/spec-reviewer-prompt.md b/skills/superpowers/subagent-driven-development/spec-reviewer-prompt.md
deleted file mode 100644
index ab5ddb8..0000000
--- a/skills/superpowers/subagent-driven-development/spec-reviewer-prompt.md
+++ /dev/null
@@ -1,61 +0,0 @@
-# Spec Compliance Reviewer Prompt Template
-
-Use this template when dispatching a spec compliance reviewer subagent.
-
-**Purpose:** Verify implementer built what was requested (nothing more, nothing less)
-
-```
-Task tool (general-purpose):
-  description: "Review spec compliance for Task N"
-  prompt: |
-    You are reviewing whether an implementation matches its specification.
-
-    ## What Was Requested
-
-    [FULL TEXT of task requirements]
-
-    ## What Implementer Claims They Built
-
-    [From implementer's report]
-
-    ## CRITICAL: Do Not Trust the Report
-
-    The implementer finished suspiciously quickly. Their report may be incomplete,
-    inaccurate, or optimistic. You MUST verify everything independently.
-
-    **DO NOT:**
-    - Take their word for what they implemented
-    - Trust their claims about completeness
-    - Accept their interpretation of requirements
-
-    **DO:**
-    - Read the actual code they wrote
-    - Compare actual implementation to requirements line by line
-    - Check for missing pieces they claimed to implement
-    - Look for extra features they didn't mention
-
-    ## Your Job
-
-    Read the implementation code and verify:
-
-    **Missing requirements:**
-    - Did they implement everything that was requested?
-    - Are there requirements they skipped or missed?
-    - Did they claim something works but didn't actually implement it?
-
-    **Extra/unneeded work:**
-    - Did they build things that weren't requested?
-    - Did they over-engineer or add unnecessary features?
-    - Did they add "nice to haves" that weren't in spec?
-
-    **Misunderstandings:**
-    - Did they interpret requirements differently than intended?
-    - Did they solve the wrong problem?
-    - Did they implement the right feature but wrong way?
-
-    **Verify by reading code, not by trusting report.**
-
-    Report:
-    - ✅ Spec compliant (if everything matches after code inspection)
-    - ❌ Issues found: [list specifically what's missing or extra, with file:line references]
-```
diff --git a/skills/superpowers/systematic-debugging/SKILL.md b/skills/superpowers/systematic-debugging/SKILL.md
index 111d2a9..b0eca38 100644
--- a/skills/superpowers/systematic-debugging/SKILL.md
+++ b/skills/superpowers/systematic-debugging/SKILL.md
@@ -237,7 +237,7 @@ If you catch yourself thinking:
 - "Is that not happening?" - You assumed without verifying
 - "Will it show us...?" - You should have added evidence gathering
 - "Stop guessing" - You're proposing fixes without understanding
-- "Ultrathink this" - Question fundamentals, not just symptoms
+- "Ultra-think this" - Question fundamentals, not just symptoms
 - "We're stuck?" (frustrated) - Your approach isn't working
 
 **When you see these:** STOP. Return to Phase 1.
diff --git a/skills/superpowers/test-driven-development/SKILL.md b/skills/superpowers/test-driven-development/SKILL.md
index 7a751fa..60d2609 100644
--- a/skills/superpowers/test-driven-development/SKILL.md
+++ b/skills/superpowers/test-driven-development/SKILL.md
@@ -356,7 +356,7 @@ Never fix bugs without a test.
 
 ## Testing Anti-Patterns
 
-When adding mocks or test utilities, read @testing-anti-patterns.md to avoid common pitfalls:
+When adding mocks or test utilities, read [testing-anti-patterns.md](testing-anti-patterns.md) to avoid common pitfalls:
 - Testing mock behavior instead of real behavior
 - Adding test-only methods to production classes
 - Mocking without understanding dependencies
diff --git a/skills/superpowers/using-git-worktrees/SKILL.md b/skills/superpowers/using-git-worktrees/SKILL.md
index 134d371..212c569 100644
--- a/skills/superpowers/using-git-worktrees/SKILL.md
+++ b/skills/superpowers/using-git-worktrees/SKILL.md
@@ -30,7 +30,7 @@ BRANCH=$(git branch --show-current)
 git rev-parse --show-superproject-working-tree 2>/dev/null
 ```
 
-**If `GIT_DIR != GIT_COMMON` (and not a submodule):** You are already in a linked worktree. Skip to Step 3 (Project Setup). Do NOT create another worktree.
+**If `GIT_DIR != GIT_COMMON` (and not a submodule):** You are already in a linked worktree. Skip to Step 2 (Project Setup). Do NOT create another worktree.
 
 Report with branch state:
 - On a branch: "Already in isolated workspace at `<path>` on branch `<name>`."
@@ -42,7 +42,7 @@ Has the user already indicated their worktree preference in your instructions? I
 
 > "Would you like me to set up an isolated worktree? It protects your current branch from changes."
 
-Honor any existing declared preference without asking. If the user declines consent, work in place and skip to Step 3.
+Honor any existing declared preference without asking. If the user declines consent, work in place and skip to Step 2.
 
 ## Step 1: Create Isolated Workspace
 
@@ -50,7 +50,7 @@ Honor any existing declared preference without asking. If the user declines cons
 
 ### 1a. Native Worktree Tools (preferred)
 
-The user has asked for an isolated workspace (Step 0 consent). Do you already have a way to create a worktree? It might be a tool with a name like `EnterWorktree`, `WorktreeCreate`, a `/worktree` command, or a `--worktree` flag. If you do, use it and skip to Step 3.
+The user has asked for an isolated workspace (Step 0 consent). Do you already have a way to create a worktree? It might be a tool with a name like `EnterWorktree`, `WorktreeCreate`, a `/worktree` command, or a `--worktree` flag. If you do, use it and skip to Step 2.
 
 Native tools handle directory placement, branch creation, and cleanup automatically. Using `git worktree add` when you have a native tool creates phantom state your harness can't see or manage.
 
@@ -73,14 +73,7 @@ Follow this priority order. Explicit user preference always beats observed files
    ```
    If found, use it. If both exist, `.worktrees` wins.
 
-3. **Check for an existing global directory:**
-   ```bash
-   project=$(basename "$(git rev-parse --show-toplevel)")
-   ls -d ~/.config/superpowers/worktrees/$project 2>/dev/null
-   ```
-   If found, use it (backward compatibility with legacy global path).
-
-4. **If there is no other guidance available**, default to `.worktrees/` at the project root.
+3. **If there is no other guidance available**, default to `.worktrees/` at the project root.
 
 #### Safety Verification (project-local directories only)
 
@@ -94,16 +87,11 @@ git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/d
 
 **Why critical:** Prevents accidentally committing worktree contents to repository.
 
-Global directories (`~/.config/superpowers/worktrees/`) need no verification.
-
 #### Create the Worktree
 
 ```bash
-project=$(basename "$(git rev-parse --show-toplevel)")
-
 # Determine path based on chosen location
-# For project-local: path="$LOCATION/$BRANCH_NAME"
-# For global: path="~/.config/superpowers/worktrees/$project/$BRANCH_NAME"
+path="$LOCATION/$BRANCH_NAME"
 
 git worktree add "$path" -b "$BRANCH_NAME"
 cd "$path"
@@ -111,7 +99,7 @@ cd "$path"
 
 **Sandbox fallback:** If `git worktree add` fails with a permission error (sandbox denial), tell the user the sandbox blocked worktree creation and you're working in the current directory instead. Then run setup and baseline tests in place.
 
-## Step 3: Project Setup
+## Step 2: Project Setup
 
 Auto-detect and run appropriate setup:
 
@@ -130,7 +118,7 @@ if [ -f pyproject.toml ]; then poetry install; fi
 if [ -f go.mod ]; then go mod download; fi
 ```
 
-## Step 4: Verify Clean Baseline
+## Step 3: Verify Clean Baseline
 
 Run tests to ensure workspace starts clean:
 
@@ -163,7 +151,6 @@ Ready to implement <feature-name>
 | `worktrees/` exists | Use it (verify ignored) |
 | Both exist | Use `.worktrees/` |
 | Neither exists | Check instruction file, then default `.worktrees/` |
-| Global path exists | Use it (backward compat) |
 | Directory not ignored | Add to .gitignore + commit |
 | Permission error on create | Sandbox fallback, work in place |
 | Tests fail during baseline | Report failures + ask |
@@ -189,7 +176,7 @@ Ready to implement <feature-name>
 ### Assuming directory location
 
 - **Problem:** Creates inconsistency, violates project conventions
-- **Fix:** Follow priority: existing > global legacy > instruction file > default
+- **Fix:** Follow priority: explicit instructions > existing project-local directory > default
 
 ### Proceeding with failing tests
 
@@ -209,7 +196,7 @@ Ready to implement <feature-name>
 **Always:**
 - Run Step 0 detection first
 - Prefer native tools over git fallback
-- Follow directory priority: existing > global legacy > instruction file > default
+- Follow directory priority: explicit instructions > existing project-local directory > default
 - Verify directory is ignored for project-local
 - Auto-detect and run project setup
 - Verify clean test baseline
diff --git a/skills/superpowers/using-superpowers/SKILL.md b/skills/superpowers/using-superpowers/SKILL.md
index c8a8570..5371221 100644
--- a/skills/superpowers/using-superpowers/SKILL.md
+++ b/skills/superpowers/using-superpowers/SKILL.md
@@ -1,6 +1,6 @@
 ---
 name: using-superpowers
-description: Use when starting any conversation - establishes how to find and use skills, requiring Skill tool invocation before ANY response including clarifying questions
+description: Use when starting any conversation - establishes how to find and use skills, requiring skill invocation before ANY response including clarifying questions
 ---
 
 <SUBAGENT-STOP>
@@ -27,9 +27,13 @@ If CLAUDE.md, GEMINI.md, or AGENTS.md says "don't use TDD" and a skill says "alw
 
 ## How to Access Skills
 
-**In Claude Code:** Use the `Skill` tool. When you invoke a skill, its content is loaded and presented to you—follow it directly. Never use the Read tool on skill files.
+**Never read skill files manually with file tools** — always use your platform's skill-loading mechanism so the skill is properly activated.
 
-**In Copilot CLI:** Use the `skill` tool. Skills are auto-discovered from installed plugins. The `skill` tool works the same as Claude Code's `Skill` tool.
+**In Claude Code:** Use the `Skill` tool. When you invoke a skill, its content is loaded and presented to you — follow it directly.
+
+**In Codex:** Skills load natively. Follow the instructions presented when a skill activates.
+
+**In Copilot CLI:** Use the `skill` tool. Skills are auto-discovered from installed plugins.
 
 **In Gemini CLI:** Skills activate via the `activate_skill` tool. Gemini loads skill metadata at session start and activates the full content on demand.
 
@@ -37,7 +41,7 @@ If CLAUDE.md, GEMINI.md, or AGENTS.md says "don't use TDD" and a skill says "alw
 
 ## Platform Adaptation
 
-Skills use Claude Code tool names. Non-CC platforms: see `references/copilot-tools.md` (Copilot CLI), `references/codex-tools.md` (Codex) for tool equivalents. Gemini CLI users get the tool mapping loaded automatically via GEMINI.md.
+Skills speak in actions ("dispatch a subagent", "create a todo", "read a file") rather than naming any one runtime's tools. For per-platform tool equivalents and instructions-file conventions, see [claude-code-tools.md](references/claude-code-tools.md), [codex-tools.md](references/codex-tools.md), [copilot-tools.md](references/copilot-tools.md), [gemini-tools.md](references/gemini-tools.md), [pi-tools.md](references/pi-tools.md), and [antigravity-tools.md](references/antigravity-tools.md). Gemini CLI users get the tool mapping loaded automatically via GEMINI.md.
 
 # Using Skills
 
@@ -48,30 +52,30 @@ Skills use Claude Code tool names. Non-CC platforms: see `references/copilot-too
 ```dot
 digraph skill_flow {
     "User message received" [shape=doublecircle];
-    "About to EnterPlanMode?" [shape=doublecircle];
+    "About to enter plan mode?" [shape=doublecircle];
     "Already brainstormed?" [shape=diamond];
     "Invoke brainstorming skill" [shape=box];
     "Might any skill apply?" [shape=diamond];
-    "Invoke Skill tool" [shape=box];
+    "Invoke the skill" [shape=box];
     "Announce: 'Using [skill] to [purpose]'" [shape=box];
     "Has checklist?" [shape=diamond];
-    "Create TodoWrite todo per item" [shape=box];
+    "Create a todo per item" [shape=box];
     "Follow skill exactly" [shape=box];
     "Respond (including clarifications)" [shape=doublecircle];
 
-    "About to EnterPlanMode?" -> "Already brainstormed?";
+    "About to enter plan mode?" -> "Already brainstormed?";
     "Already brainstormed?" -> "Invoke brainstorming skill" [label="no"];
     "Already brainstormed?" -> "Might any skill apply?" [label="yes"];
     "Invoke brainstorming skill" -> "Might any skill apply?";
 
     "User message received" -> "Might any skill apply?";
-    "Might any skill apply?" -> "Invoke Skill tool" [label="yes, even 1%"];
+    "Might any skill apply?" -> "Invoke the skill" [label="yes, even 1%"];
     "Might any skill apply?" -> "Respond (including clarifications)" [label="definitely not"];
-    "Invoke Skill tool" -> "Announce: 'Using [skill] to [purpose]'";
+    "Invoke the skill" -> "Announce: 'Using [skill] to [purpose]'";
     "Announce: 'Using [skill] to [purpose]'" -> "Has checklist?";
-    "Has checklist?" -> "Create TodoWrite todo per item" [label="yes"];
+    "Has checklist?" -> "Create a todo per item" [label="yes"];
     "Has checklist?" -> "Follow skill exactly" [label="no"];
-    "Create TodoWrite todo per item" -> "Follow skill exactly";
+    "Create a todo per item" -> "Follow skill exactly";
 }
 ```
 
@@ -98,15 +102,15 @@ These thoughts mean STOP—you're rationalizing:
 
 When multiple skills could apply, use this order:
 
-1. **Process skills first** (brainstorming, debugging) - these determine HOW to approach the task
+1. **Process skills first** (brainstorming, systematic-debugging) - these determine HOW to approach the task
 2. **Implementation skills second** (frontend-design, mcp-builder) - these guide execution
 
 "Let's build X" → brainstorming first, then implementation skills.
-"Fix this bug" → debugging first, then domain-specific skills.
+"Fix this bug" → systematic-debugging first, then domain-specific skills.
 
 ## Skill Types
 
-**Rigid** (TDD, debugging): Follow exactly. Don't adapt away discipline.
+**Rigid** (TDD, systematic-debugging): Follow exactly. Don't adapt away discipline.
 
 **Flexible** (patterns): Adapt principles to context.
 
diff --git a/skills/superpowers/using-superpowers/references/codex-tools.md b/skills/superpowers/using-superpowers/references/codex-tools.md
index f50d40d..1ab253f 100644
--- a/skills/superpowers/using-superpowers/references/codex-tools.md
+++ b/skills/superpowers/using-superpowers/references/codex-tools.md
@@ -1,17 +1,30 @@
 # Codex Tool Mapping
 
-Skills use Claude Code tool names. When you encounter these in a skill, use your platform equivalent:
-
-| Skill references | Codex equivalent |
-|-----------------|------------------|
-| `Task` tool (dispatch subagent) | `spawn_agent` (see [Subagent dispatch requires multi-agent support](#subagent-dispatch-requires-multi-agent-support)) |
-| Multiple `Task` calls (parallel) | Multiple `spawn_agent` calls |
-| Task returns result | `wait_agent` |
-| Task completes automatically | `close_agent` to free slot |
-| `TodoWrite` (task tracking) | `update_plan` |
-| `Skill` tool (invoke a skill) | Skills load natively — just follow the instructions |
-| `Read`, `Write`, `Edit` (files) | Use your native file tools |
-| `Bash` (run commands) | Use your native shell tools |
+Skills speak in actions ("dispatch a subagent", "create a todo", "read a file"). On Codex these resolve to the tools below.
+
+| Action skills request | Codex equivalent |
+|----------------------|------------------|
+| Read a file | `shell` (e.g., `cat`, `head`, `tail`) — Codex reads files via shell |
+| Create / edit / delete a file | `apply_patch` (structured diff for create, update, delete) |
+| Run a shell command | `shell` |
+| Search file contents | `shell` (e.g., `grep`, `rg`) |
+| Find files by name | `shell` (e.g., `find`, `ls`) |
+| Fetch a URL | `shell` with `curl` / `wget` — Codex has no native fetch tool |
+| Search the web | `web_search` (enabled by default; configurable in `config.toml` via the top-level `web_search` setting — `live`, `cached`, or `disabled`) |
+| Invoke a skill | Skills load natively — just follow the instructions |
+| Dispatch a subagent (`Subagent (general-purpose):` template) | `spawn_agent` (see [Subagent dispatch requires multi-agent support](#subagent-dispatch-requires-multi-agent-support)) |
+| Multiple parallel dispatches | Multiple `spawn_agent` calls in one response |
+| Wait for subagent result | `wait_agent` |
+| Free up subagent slot when done | `close_agent` |
+| Task tracking ("create a todo", "mark complete") | `update_plan` |
+
+## Instructions file
+
+When a skill mentions "your instructions file", on Codex this is **`AGENTS.md`** at the project root. Codex also reads `~/.codex/AGENTS.md` for global context, and an `AGENTS.override.md` (in the project tree or `~/.codex/`) takes precedence when present. Codex walks from the project root down to the current working directory, concatenating `AGENTS.md` files it finds along the way, up to `project_doc_max_bytes` (32 KiB by default).
+
+## Personal skills directory
+
+User-level skills live at **`$CODEX_HOME/skills/`** (default `~/.codex/skills/`). Codex also reads the cross-runtime path **`~/.agents/skills/`** (shared with Copilot CLI and Gemini CLI). When both directories exist at the same scope, Codex loads them both as separate skill catalogs — Codex's docs don't currently document a precedence between them. Each skill is a subdirectory containing a `SKILL.md` (with `name` and `description` frontmatter).
 
 ## Subagent dispatch requires multi-agent support
 
diff --git a/skills/superpowers/using-superpowers/references/copilot-tools.md b/skills/superpowers/using-superpowers/references/copilot-tools.md
index ae3cf5a..2cf54a0 100644
--- a/skills/superpowers/using-superpowers/references/copilot-tools.md
+++ b/skills/superpowers/using-superpowers/references/copilot-tools.md
@@ -1,31 +1,38 @@
 # Copilot CLI Tool Mapping
 
-Skills use Claude Code tool names. When you encounter these in a skill, use your platform equivalent:
-
-| Skill references | Copilot CLI equivalent |
-|-----------------|----------------------|
-| `Read` (file reading) | `view` |
-| `Write` (file creation) | `create` |
-| `Edit` (file editing) | `edit` |
-| `Bash` (run commands) | `bash` |
-| `Grep` (search file content) | `grep` |
-| `Glob` (search files by name) | `glob` |
-| `Skill` tool (invoke a skill) | `skill` |
-| `WebFetch` | `web_fetch` |
-| `Task` tool (dispatch subagent) | `task` with `agent_type: "general-purpose"` or `"explore"` |
-| Multiple `Task` calls (parallel) | Multiple `task` calls |
-| Task status/output | `read_agent`, `list_agents` |
-| `TodoWrite` (task tracking) | `sql` with built-in `todos` table |
-| `WebSearch` | No equivalent — use `web_fetch` with a search engine URL |
-| `EnterPlanMode` / `ExitPlanMode` | No equivalent — stay in the main session |
+Skills speak in actions ("dispatch a subagent", "create a todo", "read a file"). On Copilot CLI these resolve to the tools below.
+
+| Action skills request | Copilot CLI equivalent |
+|----------------------|----------------------|
+| Read a file | `view` |
+| Create / edit / delete a file | `apply_patch` (Copilot CLI has no separate create/edit/write tools) |
+| Run a shell command | `bash` |
+| Search file contents | `rg` (ripgrep; Copilot CLI does not expose a `grep` tool) |
+| Find files by name | `glob` |
+| Fetch a URL | `web_fetch` |
+| Search the web | `web_search` |
+| Invoke a skill | `skill` |
+| Dispatch a subagent (`Subagent (general-purpose):` template) | `task` with `agent_type: "general-purpose"` (other accepted types: `explore`, `task`, `code-review`, `research`, `configure-copilot`) |
+| Multiple parallel dispatches | Multiple `task` calls in one response |
+| Subagent status/output/control | `read_agent`, `list_agents`, `write_agent` |
+| Task tracking ("create a todo", "mark complete") | `update_todo` |
+| Enter / exit plan mode | No equivalent — stay in the main session |
+
+## Instructions file
+
+When a skill mentions "your instructions file", on Copilot CLI this is **`AGENTS.md`** at the repository root. If both `AGENTS.md` and `.github/copilot-instructions.md` are present, Copilot reads both.
+
+## Personal skills directory
+
+User-level skills live at **`~/.copilot/skills/`**. Copilot CLI also recognizes the cross-runtime alias **`~/.agents/skills/`**, which is shared with Codex and Gemini CLI. Each skill is a subdirectory containing a `SKILL.md` (with `name` and `description` frontmatter).
 
 ## Async shell sessions
 
-Copilot CLI supports persistent async shell sessions, which have no direct Claude Code equivalent:
+Copilot CLI supports persistent async shell sessions:
 
 | Tool | Purpose |
 |------|---------|
-| `bash` with `async: true` | Start a long-running command in the background |
+| `bash` with `mode: "async"` (and optionally `detach: true`) | Start a long-running command in the background; returns a `shellId` |
 | `write_bash` | Send input to a running async session |
 | `read_bash` | Read output from an async session |
 | `stop_bash` | Terminate an async session |
diff --git a/skills/superpowers/using-superpowers/references/gemini-tools.md b/skills/superpowers/using-superpowers/references/gemini-tools.md
index 91ef404..b01b652 100644
--- a/skills/superpowers/using-superpowers/references/gemini-tools.md
+++ b/skills/superpowers/using-superpowers/references/gemini-tools.md
@@ -1,51 +1,63 @@
 # Gemini CLI Tool Mapping
 
-Skills use Claude Code tool names. When you encounter these in a skill, use your platform equivalent:
-
-| Skill references | Gemini CLI equivalent |
-|-----------------|----------------------|
-| `Read` (file reading) | `read_file` |
-| `Write` (file creation) | `write_file` |
-| `Edit` (file editing) | `replace` |
-| `Bash` (run commands) | `run_shell_command` |
-| `Grep` (search file content) | `grep_search` |
-| `Glob` (search files by name) | `glob` |
-| `TodoWrite` (task tracking) | `write_todos` |
-| `Skill` tool (invoke a skill) | `activate_skill` |
-| `WebSearch` | `google_web_search` |
-| `WebFetch` | `web_fetch` |
-| `Task` tool (dispatch subagent) | `@agent-name` (see [Subagent support](#subagent-support)) |
+Skills speak in actions ("dispatch a subagent", "create a todo", "read a file"). On Gemini CLI these resolve to the tools below.
+
+| Action skills request | Gemini CLI equivalent |
+|----------------------|----------------------|
+| Read a file | `read_file` |
+| Read multiple files at once | `read_many_files` |
+| Create a new file | `write_file` |
+| Edit a file | `replace` |
+| Run a shell command | `run_shell_command` |
+| Search file contents | `grep_search` |
+| Find files by name | `glob` |
+| List files and subdirectories | `list_directory` |
+| Fetch a URL | `web_fetch` |
+| Search the web | `google_web_search` |
+| Invoke a skill | `activate_skill` |
+| Dispatch a subagent (`Subagent (general-purpose):` template) | `invoke_agent` with `agent_name: "generalist"` (invocable via `@generalist` chat syntax — see [Subagent support](#subagent-support)) |
+| Multiple parallel dispatches | Multiple `invoke_agent` calls in the same response |
+| Task tracking ("create a todo", "mark complete") | `write_todos` (statuses: pending, in_progress, completed, cancelled, blocked) |
+
+## Instructions file
+
+When a skill mentions "your instructions file", on Gemini CLI this is **`GEMINI.md`**. Gemini CLI loads `GEMINI.md` hierarchically: global at `~/.gemini/GEMINI.md`, project-level files in workspace directories and their ancestors, and sub-directory `GEMINI.md` files when a tool accesses files in those directories.
+
+## Personal skills directory
+
+User-level skills live at **`~/.gemini/skills/`**, with **`~/.agents/skills/`** as a cross-runtime alias (shared with Codex and Copilot CLI). When both directories exist at the same scope, `.agents/skills/` takes precedence. Each skill is a subdirectory containing a `SKILL.md` (with `name` and `description` frontmatter).
 
 ## Subagent support
 
-Gemini CLI supports subagents natively via the `@` syntax. Use the built-in `@generalist` agent to dispatch any task — it has access to all tools and follows the prompt you provide.
+Gemini CLI dispatches subagents through the `invoke_agent` tool, which takes `agent_name` and `prompt` parameters. The same dispatch is also surfaced as a chat-syntax shortcut: typing `@generalist <prompt>` is equivalent to calling `invoke_agent` with `agent_name: "generalist"`. Built-in agent names include `generalist`, `cli_help`, `codebase_investigator`, and (with browser tooling enabled) `browser_agent`.
 
-When a skill says to dispatch a named agent type, use `@generalist` with the full prompt from the skill's prompt template:
+Skills dispatch with `Subagent (general-purpose):` and either reference a prompt-template file (e.g., `superpowers:subagent-driven-development`'s `./implementer-prompt.md`) or supply an inline prompt. On Gemini CLI:
 
-| Skill instruction | Gemini CLI equivalent |
-|-------------------|----------------------|
-| `Task tool (superpowers:implementer)` | `@generalist` with the filled `implementer-prompt.md` template |
-| `Task tool (superpowers:spec-reviewer)` | `@generalist` with the filled `spec-reviewer-prompt.md` template |
-| `Task tool (superpowers:code-reviewer)` | `@code-reviewer` (bundled agent) or `@generalist` with the filled review prompt |
-| `Task tool (superpowers:code-quality-reviewer)` | `@generalist` with the filled `code-quality-reviewer-prompt.md` template |
-| `Task tool (general-purpose)` with inline prompt | `@generalist` with your inline prompt |
+| Skill dispatch form | Gemini CLI equivalent |
+|---------------------|----------------------|
+| References a `*-prompt.md` template (implementer, task-reviewer, code-reviewer, etc.) | Fill the template, then `invoke_agent` with `agent_name: "generalist"` and the filled prompt |
+| References `superpowers:requesting-code-review`'s `./code-reviewer.md` | `invoke_agent` with `agent_name: "generalist"` and the filled review template |
+| Inline prompt (no template referenced) | `invoke_agent` with `agent_name: "generalist"` and your inline prompt |
 
 ### Prompt filling
 
-Skills provide prompt templates with placeholders like `{WHAT_WAS_IMPLEMENTED}` or `[FULL TEXT of task]`. Fill all placeholders and pass the complete prompt as the message to `@generalist`. The prompt template itself contains the agent's role, review criteria, and expected output format — `@generalist` will follow it.
+Skills provide prompt templates with placeholders like `{WHAT_WAS_IMPLEMENTED}` or `[FULL TEXT of task]`. Fill all placeholders before passing the complete prompt to `invoke_agent`. The prompt template itself contains the agent's role, review criteria, and expected output format — the subagent will follow it.
 
 ### Parallel dispatch
 
-Gemini CLI supports parallel subagent dispatch. When a skill asks you to dispatch multiple independent subagent tasks in parallel, request all of those `@generalist` or named subagent tasks together in the same prompt. Keep dependent tasks sequential, but do not serialize independent subagent tasks just to preserve a simpler history.
+Gemini CLI supports parallel subagent dispatch. Issue multiple `invoke_agent` calls in the same response (or multiple `@generalist` invocations in one prompt) to run independent subagent work in parallel. Keep dependent tasks sequential, but do not serialize independent subagent tasks just to preserve a simpler history.
 
 ## Additional Gemini CLI tools
 
-These tools are available in Gemini CLI but have no Claude Code equivalent:
+These tools are unique to Gemini CLI:
 
 | Tool | Purpose |
 |------|---------|
-| `list_directory` | List files and subdirectories |
-| `save_memory` | Persist facts to GEMINI.md across sessions |
-| `ask_user` | Request structured input from the user |
-| `tracker_create_task` | Rich task management (create, update, list, visualize) |
-| `enter_plan_mode` / `exit_plan_mode` | Switch to read-only research mode before making changes |
+| `save_memory` (legacy) | Persist facts across sessions when `experimental.memoryV2 = false` |
+| `get_internal_docs` | Look up Gemini CLI's bundled documentation |
+| `ask_user` | Pose structured questions to the user (text / single-select / multi-select) |
+| `enter_plan_mode` / `exit_plan_mode` | Switch into and out of read-only plan mode |
+| `update_topic` | Update the current conversation's topic / strategic-intent metadata |
+| `complete_task` | Signal that a Gemini subagent has completed and return its result to the parent agent |
+| `tracker_create_task`, `tracker_update_task`, `tracker_get_task`, `tracker_list_tasks`, `tracker_add_dependency`, `tracker_visualize` | Rich task tracker with dependency and visualization support |
+| `read_mcp_resource`, `list_mcp_resources` | MCP resource access |
diff --git a/skills/superpowers/writing-plans/SKILL.md b/skills/superpowers/writing-plans/SKILL.md
index 847412e..b1613eb 100644
--- a/skills/superpowers/writing-plans/SKILL.md
+++ b/skills/superpowers/writing-plans/SKILL.md
@@ -33,6 +33,15 @@ Before defining tasks, map out which files will be created or modified and what
 
 This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.
 
+## Task Right-Sizing
+
+A task is the smallest unit that carries its own test cycle and is worth a
+fresh reviewer's gate. When drawing task boundaries: fold setup,
+configuration, scaffolding, and documentation steps into the task whose
+deliverable needs them; split only where a reviewer could meaningfully
+reject one task while approving its neighbor. Each task ends with an
+independently testable deliverable.
+
 ## Bite-Sized Task Granularity
 
 **Each step is one action (2-5 minutes):**
@@ -57,6 +66,13 @@ This structure informs the task decomposition. Each task should produce self-con
 
 **Tech Stack:** [Key technologies/libraries]
 
+## Global Constraints
+
+[The spec's project-wide requirements — version floors, dependency limits,
+naming and copy rules, platform requirements — one line each, with exact
+values copied verbatim from the spec. Every task's requirements implicitly
+include this section.]
+
 ---
 ```
 
@@ -70,6 +86,12 @@ This structure informs the task decomposition. Each task should produce self-con
 - Modify: `exact/path/to/existing.py:123-145`
 - Test: `tests/exact/path/to/test.py`
 
+**Interfaces:**
+- Consumes: [what this task uses from earlier tasks — exact signatures]
+- Produces: [what later tasks rely on — exact function names, parameter
+  and return types. A task's implementer sees only their own task; this
+  block is how they learn the names and types neighboring tasks use.]
+
 - [ ] **Step 1: Write the failing test**
 
 ```python
diff --git a/skills/superpowers/writing-plans/plan-document-reviewer-prompt.md b/skills/superpowers/writing-plans/plan-document-reviewer-prompt.md
index 2db2806..1c12c1d 100644
--- a/skills/superpowers/writing-plans/plan-document-reviewer-prompt.md
+++ b/skills/superpowers/writing-plans/plan-document-reviewer-prompt.md
@@ -7,7 +7,7 @@ Use this template when dispatching a plan document reviewer subagent.
 **Dispatch after:** The complete plan is written.
 
 ```
-Task tool (general-purpose):
+Subagent (general-purpose):
   description: "Review plan document"
   prompt: |
     You are a plan document reviewer. Verify this plan is complete and ready for implementation.
diff --git a/skills/superpowers/writing-skills/SKILL.md b/skills/superpowers/writing-skills/SKILL.md
index c3b73d8..8928d44 100644
--- a/skills/superpowers/writing-skills/SKILL.md
+++ b/skills/superpowers/writing-skills/SKILL.md
@@ -9,7 +9,7 @@ description: Use when creating new skills, editing existing skills, or verifying
 
 **Writing skills IS Test-Driven Development applied to process documentation.**
 
-**Personal skills live in agent-specific directories (`~/.claude/skills` for Claude Code, `~/.agents/skills/` for Codex)** 
+**Personal skills live in your runtime's skills directory** — see [claude-code-tools.md](../using-superpowers/references/claude-code-tools.md), [codex-tools.md](../using-superpowers/references/codex-tools.md), [copilot-tools.md](../using-superpowers/references/copilot-tools.md), or [gemini-tools.md](../using-superpowers/references/gemini-tools.md) for the path on your runtime. Codex, Copilot CLI, and Gemini CLI all also recognize `~/.agents/skills/` as a cross-runtime alias.
 
 You write test cases (pressure scenarios with subagents), watch them fail (baseline behavior), write the skill (documentation), watch tests pass (agents comply), and refactor (close loopholes).
 
@@ -21,7 +21,7 @@ You write test cases (pressure scenarios with subagents), watch them fail (basel
 
 ## What is a Skill?
 
-A **skill** is a reference guide for proven techniques, patterns, or tools. Skills help future Claude instances find and apply effective approaches.
+A **skill** is a reference guide for proven techniques, patterns, or tools. Skills help future agents find and apply effective approaches.
 
 **Skills are:** Reusable techniques, patterns, tools, reference guides
 
@@ -55,7 +55,7 @@ The entire skill creation process follows RED-GREEN-REFACTOR.
 **Don't create for:**
 - One-off solutions
 - Standard practices well-documented elsewhere
-- Project-specific conventions (put in CLAUDE.md)
+- Project-specific conventions (put in your instructions file)
 - Mechanical constraints (if it's enforceable with regex/validation, automate it—save documentation for judgment calls)
 
 ## Skill Types
@@ -99,7 +99,7 @@ skills/
 - `description`: Third-person, describes ONLY when to use (NOT what it does)
   - Start with "Use when..." to focus on triggering conditions
   - Include specific symptoms, situations, and contexts
-  - **NEVER summarize the skill's process or workflow** (see CSO section for why)
+  - **NEVER summarize the skill's process or workflow** (see SDO section for why)
   - Keep under 500 characters if possible
 
 ```markdown
@@ -137,13 +137,13 @@ Concrete results
 ```
 
 
-## Claude Search Optimization (CSO)
+## Skill Discovery Optimization (SDO)
 
-**Critical for discovery:** Future Claude needs to FIND your skill
+**Critical for discovery:** Future agents need to FIND your skill
 
 ### 1. Rich Description Field
 
-**Purpose:** Claude reads description to decide which skills to load for a given task. Make it answer: "Should I read this skill right now?"
+**Purpose:** Your agent reads the description to decide which skills to load for a given task. Make it answer: "Should I read this skill right now?"
 
 **Format:** Start with "Use when..." to focus on triggering conditions
 
@@ -151,14 +151,14 @@ Concrete results
 
 The description should ONLY describe triggering conditions. Do NOT summarize the skill's process or workflow in the description.
 
-**Why this matters:** Testing revealed that when a description summarizes the skill's workflow, Claude may follow the description instead of reading the full skill content. A description saying "code review between tasks" caused Claude to do ONE review, even though the skill's flowchart clearly showed TWO reviews (spec compliance then code quality).
+**Why this matters:** Testing revealed that when a description summarizes the skill's workflow, an agent may follow the description instead of reading the full skill content. A description saying "code review between tasks" caused an agent to do ONE review, even though the skill's flowchart clearly showed TWO reviews (spec compliance then code quality).
 
-When the description was changed to just "Use when executing implementation plans with independent tasks" (no workflow summary), Claude correctly read the flowchart and followed the two-stage review process.
+When the description was changed to just "Use when executing implementation plans with independent tasks" (no workflow summary), the agent correctly read the flowchart and followed the two-stage review process.
 
-**The trap:** Descriptions that summarize workflow create a shortcut Claude will take. The skill body becomes documentation Claude skips.
+**The trap:** Descriptions that summarize workflow create a shortcut agents will take. The skill body becomes documentation agents skip.
 
 ```yaml
-# ❌ BAD: Summarizes workflow - Claude may follow this instead of reading skill
+# ❌ BAD: Summarizes workflow - agents may follow this instead of reading skill
 description: Use when executing plans - dispatches subagent per task with code review between tasks
 
 # ❌ BAD: Too much process detail
@@ -198,7 +198,7 @@ description: Use when using React Router and handling authentication redirects
 
 ### 2. Keyword Coverage
 
-Use words Claude would search for:
+Use words an agent would search for:
 - Error messages: "Hook timed out", "ENOTEMPTY", "race condition"
 - Symptoms: "flaky", "hanging", "zombie", "pollution"
 - Synonyms: "timeout/hang/freeze", "cleanup/teardown/afterEach"
@@ -275,7 +275,7 @@ wc -w skills/path/SKILL.md
 - `creating-skills`, `testing-skills`, `debugging-with-logs`
 - Active, describes the action you're taking
 
-### 4. Cross-Referencing Other Skills
+### 5. Cross-Referencing Other Skills
 
 **When writing documentation that references other skills:**
 
@@ -313,7 +313,7 @@ digraph when_flowchart {
 - Linear instructions → Numbered lists
 - Labels without semantic meaning (step1, helper2)
 
-See @graphviz-conventions.dot for graphviz style rules.
+See `graphviz-conventions.dot` in this directory for graphviz style rules.
 
 **Visualizing for your human partner:** Use `render-graphs.js` in this directory to render a skill's flowcharts to SVG:
 ```bash
@@ -456,10 +456,29 @@ Different skill types need different test approaches:
 
 **All of these mean: Test before deploying. No exceptions.**
 
+## Match the Form to the Failure
+
+Before writing guidance, classify the baseline failure. The form that bulletproofs one failure type measurably backfires on another.
+
+| Baseline failure | Right form | Wrong form |
+|---|---|---|
+| Skips/violates a rule under pressure (knows better, does it anyway) | Prohibition + rationalization table + red flags (see Bulletproofing below) | Soft guidance ("prefer...", "consider...") |
+| Complies, but output has the wrong shape (bloated prompt, buried verdict, restated spec) | Positive recipe or contract: state what the output IS — its parts, in order | Prohibition list ("don't restate", "never narrate") |
+| Omits a required element from something they already produce | Structural: REQUIRED field or slot in the template they fill in | Prose reminders near the template |
+| Behavior should depend on a condition | Conditional keyed to an observable predicate ("if the brief exists, reference it") | Unconditional rule + exemption clauses |
+
+**Why prohibitions backfire on shaping problems:** under a competing incentive ("make the prompt self-contained"), agents negotiate with "don't X". In head-to-head wording tests on dispatch-prompt guidance, the prohibition arm produced clearly more of the unwanted content than the recipe arm (fully separated distributions), and trended worse than even the no-guidance control — micro-test your own case rather than assuming, but never reach for the prohibition by default. A recipe leaves nothing to negotiate: the output matches the stated shape or it doesn't.
+
+**Rules for whichever form you pick:**
+- **No nuance clauses.** "Don't X unless it matters" reopens the negotiation — appending a single nuance clause to a winning recipe degraded it from consistent to noisy in the same wording tests. Express a real exception as its own conditional on an observable predicate.
+- **Exemption clauses don't scope.** "This limit doesn't apply to code blocks" still suppresses code blocks. If part of the output must be exempt, restructure so the rule can't reach it.
+
 ## Bulletproofing Skills Against Rationalization
 
 Skills that enforce discipline (like TDD) need to resist rationalization. Agents are smart and will find loopholes when under pressure.
 
+**Scope:** this toolkit is for discipline failures — an agent that knows the rule and skips it under pressure. For wrong-shaped output or omitted elements, prohibition-based bulletproofing backfires; use the forms in Match the Form to the Failure instead.
+
 **Psychology note:** Understanding WHY persuasion techniques work helps you apply them systematically. See persuasion-principles.md for research foundation (Cialdini, 2021; Meincke et al., 2025) on authority, commitment, scarcity, social proof, and unity principles.
 
 ### Close Every Loophole Explicitly
@@ -522,7 +541,7 @@ Make it easy for agents to self-check when rationalizing:
 **All of these mean: Delete code. Start over with TDD.**
 ```
 
-### Update CSO for Violation Symptoms
+### Update SDO for Violation Symptoms
 
 Add to description: symptoms of when you're ABOUT to violate the rule:
 
@@ -553,7 +572,19 @@ Run same scenarios WITH skill. Agent should now comply.
 
 Agent found new rationalization? Add explicit counter. Re-test until bulletproof.
 
-**Testing methodology:** See @testing-skills-with-subagents.md for the complete testing methodology:
+### Micro-Test Wording Before Full Scenarios
+
+Full pressure-scenario runs are the final gate, but they are slow and expensive per iteration. Verify the wording itself first with micro-tests:
+
+1. **One fresh-context sample per call** — a raw API call, or a single-shot subagent if you don't have API access. System prompt = the realistic context the guidance will live in (the full skill or prompt template, not the guidance in isolation); user message = a task that tempts the failure.
+2. **Always include a no-guidance control.** If the control doesn't exhibit the failure, there is nothing to fix — stop, don't author the guidance.
+3. **5+ reps per variant.** Single samples lie.
+4. **Manually read every flagged match.** Score programmatically if you like, but template echoes and quoted counter-examples masquerade as hits; automated counts alone overstate both failure and success.
+5. **Variance is a metric.** When guidance lands, reps converge on the same shape. Five different interpretations across five reps means the wording isn't binding — tighten the form before adding words.
+
+Micro-tests verify wording; they do not replace pressure scenarios for discipline skills.
+
+**Testing methodology:** See [testing-skills-with-subagents.md](testing-skills-with-subagents.md) for the complete testing methodology:
 - How to write pressure scenarios
 - Pressure types (time, sunk cost, authority, exhaustion)
 - Plugging holes systematically
@@ -595,7 +626,7 @@ Deploying untested skills = deploying untested code. It's a violation of quality
 
 ## Skill Creation Checklist (TDD Adapted)
 
-**IMPORTANT: Use TodoWrite to create todos for EACH checklist item below.**
+**IMPORTANT: Create a todo for EACH checklist item below.**
 
 **RED Phase - Write Failing Test:**
 - [ ] Create pressure scenarios (3+ combined pressures for discipline skills)
@@ -610,6 +641,8 @@ Deploying untested skills = deploying untested code. It's a violation of quality
 - [ ] Keywords throughout for search (errors, symptoms, tools)
 - [ ] Clear overview with core principle
 - [ ] Address specific baseline failures identified in RED
+- [ ] Guidance form matches the failure type (see Match the Form to the Failure)
+- [ ] For behavior-shaping guidance: wording micro-tested against a no-guidance control (5+ reps, every flagged match read manually) — N/A for pure reference skills
 - [ ] Code inline OR link to separate file
 - [ ] One excellent example (not multi-language)
 - [ ] Run scenarios WITH skill - verify agents now comply
@@ -634,9 +667,10 @@ Deploying untested skills = deploying untested code. It's a violation of quality
 
 ## Discovery Workflow
 
-How future Claude finds your skill:
+How future agents find your skill:
 
 1. **Encounters problem** ("tests are flaky")
+2. **Searches skills** (greps descriptions, browses categories)
 3. **Finds SKILL** (description matches)
 4. **Scans overview** (is this relevant?)
 5. **Reads patterns** (quick reference table)
diff --git a/skills/superpowers/writing-skills/anthropic-best-practices.md b/skills/superpowers/writing-skills/anthropic-best-practices.md
index 9f3f6ec..15ea9ea 100644
--- a/skills/superpowers/writing-skills/anthropic-best-practices.md
+++ b/skills/superpowers/writing-skills/anthropic-best-practices.md
@@ -1,30 +1,30 @@
 # Skill authoring best practices
 
-> Learn how to write effective Skills that Claude can discover and use successfully.
+> Learn how to write effective Skills that agents can discover and use successfully.
 
-Good Skills are concise, well-structured, and tested with real usage. This guide provides practical authoring decisions to help you write Skills that Claude can discover and use effectively.
+Good Skills are concise, well-structured, and tested with real usage. This guide provides practical authoring decisions to help you write Skills that agents can discover and use effectively.
 
-For conceptual background on how Skills work, see the [Skills overview](/en/docs/agents-and-tools/agent-skills/overview).
+For conceptual background on how Skills work, see the [Skills overview](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview).
 
 ## Core principles
 
 ### Concise is key
 
-The [context window](https://platform.claude.com/docs/en/build-with-claude/context-windows) is a public good. Your Skill shares the context window with everything else Claude needs to know, including:
+The [context window](https://platform.claude.com/docs/en/build-with-claude/context-windows) is a public good. Your Skill shares the context window with everything else your agent needs to know, including:
 
 * The system prompt
 * Conversation history
 * Other Skills' metadata
 * Your actual request
 
-Not every token in your Skill has an immediate cost. At startup, only the metadata (name and description) from all Skills is pre-loaded. Claude reads SKILL.md only when the Skill becomes relevant, and reads additional files only as needed. However, being concise in SKILL.md still matters: once Claude loads it, every token competes with conversation history and other context.
+Not every token in your Skill has an immediate cost. At startup, only the metadata (name and description) from all Skills is pre-loaded. Agents read SKILL.md only when the Skill becomes relevant, and read additional files only as needed. However, being concise in SKILL.md still matters: once an agent loads it, every token competes with conversation history and other context.
 
-**Default assumption**: Claude is already very smart
+**Default assumption**: Agents are already very smart
 
-Only add context Claude doesn't already have. Challenge each piece of information:
+Only add context agents don't already have. Challenge each piece of information:
 
-* "Does Claude really need this explanation?"
-* "Can I assume Claude knows this?"
+* "Does the agent really need this explanation?"
+* "Can I assume the agent knows this?"
 * "Does this paragraph justify its token cost?"
 
 **Good example: Concise** (approximately 50 tokens):
@@ -54,7 +54,7 @@ recommend pdfplumber because it's easy to use and handles most cases well.
 First, you'll need to install it using pip. Then you can use the code below...
 ```
 
-The concise version assumes Claude knows what PDFs are and how libraries work.
+The concise version assumes the agent knows what PDFs are and how libraries work.
 
 ### Set appropriate degrees of freedom
 
@@ -124,10 +124,10 @@ python scripts/migrate.py --verify --backup
 Do not modify the command or add additional flags.
 ````
 
-**Analogy**: Think of Claude as a robot exploring a path:
+**Analogy**: Think of the agent as a robot exploring a path:
 
 * **Narrow bridge with cliffs on both sides**: There's only one safe way forward. Provide specific guardrails and exact instructions (low freedom). Example: database migrations that must run in exact sequence.
-* **Open field with no hazards**: Many paths lead to success. Give general direction and trust Claude to find the best route (high freedom). Example: code reviews where context determines the best approach.
+* **Open field with no hazards**: Many paths lead to success. Give general direction and trust the agent to find the best route (high freedom). Example: code reviews where context determines the best approach.
 
 ### Test with all models you plan to use
 
@@ -149,7 +149,7 @@ What works perfectly for Opus might need more detail for Haiku. If you plan to u
   * `name` - Human-readable name of the Skill (64 characters maximum)
   * `description` - One-line description of what the Skill does and when to use it (1024 characters maximum)
 
-  For complete Skill structure details, see the [Skills overview](/en/docs/agents-and-tools/agent-skills/overview#skill-structure).
+  For complete Skill structure details, see the [Skills overview](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview#skill-structure).
 </Note>
 
 ### Naming conventions
@@ -196,7 +196,7 @@ The `description` field enables Skill discovery and should include both what the
 
 **Be specific and include key terms**. Include both what the Skill does and specific triggers/contexts for when to use it.
 
-Each Skill has exactly one description field. The description is critical for skill selection: Claude uses it to choose the right Skill from potentially 100+ available Skills. Your description must provide enough detail for Claude to know when to select this Skill, while the rest of SKILL.md provides the implementation details.
+Each Skill has exactly one description field. The description is critical for skill selection: agents use it to choose the right Skill from potentially 100+ available Skills. Your description must provide enough detail for an agent to know when to select this Skill, while the rest of SKILL.md provides the implementation details.
 
 Effective examples:
 
@@ -234,7 +234,7 @@ description: Does stuff with files
 
 ### Progressive disclosure patterns
 
-SKILL.md serves as an overview that points Claude to detailed materials as needed, like a table of contents in an onboarding guide. For an explanation of how progressive disclosure works, see [How Skills work](/en/docs/agents-and-tools/agent-skills/overview#how-skills-work) in the overview.
+SKILL.md serves as an overview that points agents to detailed materials as needed, like a table of contents in an onboarding guide. For an explanation of how progressive disclosure works, see [How Skills work](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview#how-skills-work) in the overview.
 
 **Practical guidance:**
 
@@ -248,7 +248,7 @@ A basic Skill starts with just a SKILL.md file containing metadata and instructi
 
 <img src="https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-simple-file.png?fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=87782ff239b297d9a9e8e1b72ed72db9" alt="Simple SKILL.md file showing YAML frontmatter and markdown body" data-og-width="2048" width="2048" data-og-height="1153" height="1153" data-path="images/agent-skills-simple-file.png" data-optimize="true" data-opv="3" srcset="https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-simple-file.png?w=280&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=c61cc33b6f5855809907f7fda94cd80e 280w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-simple-file.png?w=560&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=90d2c0c1c76b36e8d485f49e0810dbfd 560w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-simple-file.png?w=840&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=ad17d231ac7b0bea7e5b4d58fb4aeabb 840w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-simple-file.png?w=1100&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=f5d0a7a3c668435bb0aee9a3a8f8c329 1100w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-simple-file.png?w=1650&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=0e927c1af9de5799cfe557d12249f6e6 1650w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-simple-file.png?w=2500&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=46bbb1a51dd4c8202a470ac8c80a893d 2500w" />
 
-As your Skill grows, you can bundle additional content that Claude loads only when needed:
+As your Skill grows, you can bundle additional content that agents load only when needed:
 
 <img src="https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-bundling-content.png?fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=a5e0aa41e3d53985a7e3e43668a33ea3" alt="Bundling additional reference files like reference.md and forms.md." data-og-width="2048" width="2048" data-og-height="1327" height="1327" data-path="images/agent-skills-bundling-content.png" data-optimize="true" data-opv="3" srcset="https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-bundling-content.png?w=280&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=f8a0e73783e99b4a643d79eac86b70a2 280w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-bundling-content.png?w=560&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=dc510a2a9d3f14359416b706f067904a 560w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-bundling-content.png?w=840&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=82cd6286c966303f7dd914c28170e385 840w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-bundling-content.png?w=1100&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=56f3be36c77e4fe4b523df209a6824c6 1100w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-bundling-content.png?w=1650&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=d22b5161b2075656417d56f41a74f3dd 1650w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-bundling-content.png?w=2500&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=3dd4bdd6850ffcc96c6c45fcb0acd6eb 2500w" />
 
@@ -292,11 +292,11 @@ with pdfplumber.open("file.pdf") as pdf:
 **Examples**: See [EXAMPLES.md](EXAMPLES.md) for common patterns
 ````
 
-Claude loads FORMS.md, REFERENCE.md, or EXAMPLES.md only when needed.
+Agents load FORMS.md, REFERENCE.md, or EXAMPLES.md only when needed.
 
 #### Pattern 2: Domain-specific organization
 
-For Skills with multiple domains, organize content by domain to avoid loading irrelevant context. When a user asks about sales metrics, Claude only needs to read sales-related schemas, not finance or marketing data. This keeps token usage low and context focused.
+For Skills with multiple domains, organize content by domain to avoid loading irrelevant context. When a user asks about sales metrics, the agent only needs to read sales-related schemas, not finance or marketing data. This keeps token usage low and context focused.
 
 ```
 bigquery-skill/
@@ -348,13 +348,13 @@ For simple edits, modify the XML directly.
 **For OOXML details**: See [OOXML.md](OOXML.md)
 ```
 
-Claude reads REDLINING.md or OOXML.md only when the user needs those features.
+Agents read REDLINING.md or OOXML.md only when the user needs those features.
 
 ### Avoid deeply nested references
 
-Claude may partially read files when they're referenced from other referenced files. When encountering nested references, Claude might use commands like `head -100` to preview content rather than reading entire files, resulting in incomplete information.
+Agents may partially read files when they're referenced from other referenced files. When encountering nested references, an agent might use commands like `head -100` to preview content rather than reading entire files, resulting in incomplete information.
 
-**Keep references one level deep from SKILL.md**. All reference files should link directly from SKILL.md to ensure Claude reads complete files when needed.
+**Keep references one level deep from SKILL.md**. All reference files should link directly from SKILL.md to ensure agents read complete files when needed.
 
 **Bad example: Too deep**:
 
@@ -382,7 +382,7 @@ Here's the actual information...
 
 ### Structure longer reference files with table of contents
 
-For reference files longer than 100 lines, include a table of contents at the top. This ensures Claude can see the full scope of available information even when previewing with partial reads.
+For reference files longer than 100 lines, include a table of contents at the top. This ensures agents can see the full scope of available information even when previewing with partial reads.
 
 **Example**:
 
@@ -403,7 +403,7 @@ For reference files longer than 100 lines, include a table of contents at the to
 ...
 ```
 
-Claude can then read the complete file or jump to specific sections as needed.
+Agents can then read the complete file or jump to specific sections as needed.
 
 For details on how this filesystem-based architecture enables progressive disclosure, see the [Runtime environment](#runtime-environment) section in the Advanced section below.
 
@@ -411,7 +411,7 @@ For details on how this filesystem-based architecture enables progressive disclo
 
 ### Use workflows for complex tasks
 
-Break complex operations into clear, sequential steps. For particularly complex workflows, provide a checklist that Claude can copy into its response and check off as it progresses.
+Break complex operations into clear, sequential steps. For particularly complex workflows, provide a checklist that the agent can copy into its response and check off as it progresses.
 
 **Example 1: Research synthesis workflow** (for Skills without code):
 
@@ -498,7 +498,7 @@ Run: `python scripts/verify_output.py output.pdf`
 If verification fails, return to Step 2.
 ````
 
-Clear steps prevent Claude from skipping critical validation. The checklist helps both Claude and you track progress through multi-step workflows.
+Clear steps prevent agents from skipping critical validation. The checklist helps both you and the agent track progress through multi-step workflows.
 
 ### Implement feedback loops
 
@@ -524,7 +524,7 @@ This pattern greatly improves output quality.
 5. Finalize and save the document
 ```
 
-This shows the validation loop pattern using reference documents instead of scripts. The "validator" is STYLE\_GUIDE.md, and Claude performs the check by reading and comparing.
+This shows the validation loop pattern using reference documents instead of scripts. The "validator" is STYLE\_GUIDE.md, and the agent performs the check by reading and comparing.
 
 **Example 2: Document editing process** (for Skills with code):
 
@@ -593,7 +593,7 @@ Choose one term and use it throughout the Skill:
 * Mix "field", "box", "element", "control"
 * Mix "extract", "pull", "get", "retrieve"
 
-Consistency helps Claude understand and follow instructions.
+Consistency helps agents understand and follow instructions.
 
 ## Common patterns
 
@@ -688,11 +688,11 @@ chore: update dependencies and refactor error handling
 Follow this style: type(scope): brief description, then detailed explanation.
 ````
 
-Examples help Claude understand the desired style and level of detail more clearly than descriptions alone.
+Examples help agents understand the desired style and level of detail more clearly than descriptions alone.
 
 ### Conditional workflow pattern
 
-Guide Claude through decision points:
+Guide agents through decision points:
 
 ```markdown  theme={null}
 ## Document modification workflow
@@ -715,7 +715,7 @@ Guide Claude through decision points:
 ```
 
 <Tip>
-  If workflows become large or complicated with many steps, consider pushing them into separate files and tell Claude to read the appropriate file based on the task at hand.
+  If workflows become large or complicated with many steps, consider pushing them into separate files and tell the agent to read the appropriate file based on the task at hand.
 </Tip>
 
 ## Evaluation and iteration
@@ -726,9 +726,9 @@ Guide Claude through decision points:
 
 **Evaluation-driven development:**
 
-1. **Identify gaps**: Run Claude on representative tasks without a Skill. Document specific failures or missing context
+1. **Identify gaps**: Run your agent on representative tasks without a Skill. Document specific failures or missing context
 2. **Create evaluations**: Build three scenarios that test these gaps
-3. **Establish baseline**: Measure Claude's performance without the Skill
+3. **Establish baseline**: Measure the agent's performance without the Skill
 4. **Write minimal instructions**: Create just enough content to address the gaps and pass evaluations
 5. **Iterate**: Execute evaluations, compare against baseline, and refine
 
@@ -753,51 +753,51 @@ This approach ensures you're solving actual problems rather than anticipating re
   This example demonstrates a data-driven evaluation with a simple testing rubric. We do not currently provide a built-in way to run these evaluations. Users can create their own evaluation system. Evaluations are your source of truth for measuring Skill effectiveness.
 </Note>
 
-### Develop Skills iteratively with Claude
+### Develop Skills iteratively with the agent
 
-The most effective Skill development process involves Claude itself. Work with one instance of Claude ("Claude A") to create a Skill that will be used by other instances ("Claude B"). Claude A helps you design and refine instructions, while Claude B tests them in real tasks. This works because Claude models understand both how to write effective agent instructions and what information agents need.
+The most effective Skill development process involves the agent itself. Work with one instance ("Agent A") to create a Skill that will be used by other instances ("Agent B"). Agent A helps you design and refine instructions, while Agent B tests them in real tasks. This works because the underlying models understand both how to write effective agent instructions and what information agents need.
 
 **Creating a new Skill:**
 
-1. **Complete a task without a Skill**: Work through a problem with Claude A using normal prompting. As you work, you'll naturally provide context, explain preferences, and share procedural knowledge. Notice what information you repeatedly provide.
+1. **Complete a task without a Skill**: Work through a problem with Agent A using normal prompting. As you work, you'll naturally provide context, explain preferences, and share procedural knowledge. Notice what information you repeatedly provide.
 
 2. **Identify the reusable pattern**: After completing the task, identify what context you provided that would be useful for similar future tasks.
 
    **Example**: If you worked through a BigQuery analysis, you might have provided table names, field definitions, filtering rules (like "always exclude test accounts"), and common query patterns.
 
-3. **Ask Claude A to create a Skill**: "Create a Skill that captures this BigQuery analysis pattern we just used. Include the table schemas, naming conventions, and the rule about filtering test accounts."
+3. **Ask Agent A to create a Skill**: "Create a Skill that captures this BigQuery analysis pattern we just used. Include the table schemas, naming conventions, and the rule about filtering test accounts."
 
    <Tip>
-     Claude models understand the Skill format and structure natively. You don't need special system prompts or a "writing skills" skill to get Claude to help create Skills. Simply ask Claude to create a Skill and it will generate properly structured SKILL.md content with appropriate frontmatter and body content.
+     Modern agents understand the Skill format and structure natively. You don't need special system prompts or a "writing skills" skill to get help creating Skills. Simply ask the agent to create a Skill and it will generate properly structured SKILL.md content with appropriate frontmatter and body content.
    </Tip>
 
-4. **Review for conciseness**: Check that Claude A hasn't added unnecessary explanations. Ask: "Remove the explanation about what win rate means - Claude already knows that."
+4. **Review for conciseness**: Check that Agent A hasn't added unnecessary explanations. Ask: "Remove the explanation about what win rate means - the agent already knows that."
 
-5. **Improve information architecture**: Ask Claude A to organize the content more effectively. For example: "Organize this so the table schema is in a separate reference file. We might add more tables later."
+5. **Improve information architecture**: Ask Agent A to organize the content more effectively. For example: "Organize this so the table schema is in a separate reference file. We might add more tables later."
 
-6. **Test on similar tasks**: Use the Skill with Claude B (a fresh instance with the Skill loaded) on related use cases. Observe whether Claude B finds the right information, applies rules correctly, and handles the task successfully.
+6. **Test on similar tasks**: Use the Skill with Agent B (a fresh instance with the Skill loaded) on related use cases. Observe whether Agent B finds the right information, applies rules correctly, and handles the task successfully.
 
-7. **Iterate based on observation**: If Claude B struggles or misses something, return to Claude A with specifics: "When Claude used this Skill, it forgot to filter by date for Q4. Should we add a section about date filtering patterns?"
+7. **Iterate based on observation**: If Agent B struggles or misses something, return to Agent A with specifics: "When the agent used this Skill, it forgot to filter by date for Q4. Should we add a section about date filtering patterns?"
 
 **Iterating on existing Skills:**
 
 The same hierarchical pattern continues when improving Skills. You alternate between:
 
-* **Working with Claude A** (the expert who helps refine the Skill)
-* **Testing with Claude B** (the agent using the Skill to perform real work)
-* **Observing Claude B's behavior** and bringing insights back to Claude A
+* **Working with Agent A** (the expert who helps refine the Skill)
+* **Testing with Agent B** (the agent using the Skill to perform real work)
+* **Observing Agent B's behavior** and bringing insights back to Agent A
 
-1. **Use the Skill in real workflows**: Give Claude B (with the Skill loaded) actual tasks, not test scenarios
+1. **Use the Skill in real workflows**: Give Agent B (with the Skill loaded) actual tasks, not test scenarios
 
-2. **Observe Claude B's behavior**: Note where it struggles, succeeds, or makes unexpected choices
+2. **Observe Agent B's behavior**: Note where it struggles, succeeds, or makes unexpected choices
 
-   **Example observation**: "When I asked Claude B for a regional sales report, it wrote the query but forgot to filter out test accounts, even though the Skill mentions this rule."
+   **Example observation**: "When I asked Agent B for a regional sales report, it wrote the query but forgot to filter out test accounts, even though the Skill mentions this rule."
 
-3. **Return to Claude A for improvements**: Share the current SKILL.md and describe what you observed. Ask: "I noticed Claude B forgot to filter test accounts when I asked for a regional report. The Skill mentions filtering, but maybe it's not prominent enough?"
+3. **Return to Agent A for improvements**: Share the current SKILL.md and describe what you observed. Ask: "I noticed Agent B forgot to filter test accounts when I asked for a regional report. The Skill mentions filtering, but maybe it's not prominent enough?"
 
-4. **Review Claude A's suggestions**: Claude A might suggest reorganizing to make rules more prominent, using stronger language like "MUST filter" instead of "always filter", or restructuring the workflow section.
+4. **Review Agent A's suggestions**: Agent A might suggest reorganizing to make rules more prominent, using stronger language like "MUST filter" instead of "always filter", or restructuring the workflow section.
 
-5. **Apply and test changes**: Update the Skill with Claude A's refinements, then test again with Claude B on similar requests
+5. **Apply and test changes**: Update the Skill with Agent A's refinements, then test again with Agent B on similar requests
 
 6. **Repeat based on usage**: Continue this observe-refine-test cycle as you encounter new scenarios. Each iteration improves the Skill based on real agent behavior, not assumptions.
 
@@ -807,18 +807,18 @@ The same hierarchical pattern continues when improving Skills. You alternate bet
 2. Ask: Does the Skill activate when expected? Are instructions clear? What's missing?
 3. Incorporate feedback to address blind spots in your own usage patterns
 
-**Why this approach works**: Claude A understands agent needs, you provide domain expertise, Claude B reveals gaps through real usage, and iterative refinement improves Skills based on observed behavior rather than assumptions.
+**Why this approach works**: Agent A understands agent needs, you provide domain expertise, Agent B reveals gaps through real usage, and iterative refinement improves Skills based on observed behavior rather than assumptions.
 
-### Observe how Claude navigates Skills
+### Observe how agents navigate Skills
 
-As you iterate on Skills, pay attention to how Claude actually uses them in practice. Watch for:
+As you iterate on Skills, pay attention to how agents actually use them in practice. Watch for:
 
-* **Unexpected exploration paths**: Does Claude read files in an order you didn't anticipate? This might indicate your structure isn't as intuitive as you thought
-* **Missed connections**: Does Claude fail to follow references to important files? Your links might need to be more explicit or prominent
-* **Overreliance on certain sections**: If Claude repeatedly reads the same file, consider whether that content should be in the main SKILL.md instead
-* **Ignored content**: If Claude never accesses a bundled file, it might be unnecessary or poorly signaled in the main instructions
+* **Unexpected exploration paths**: Does the agent read files in an order you didn't anticipate? This might indicate your structure isn't as intuitive as you thought
+* **Missed connections**: Does the agent fail to follow references to important files? Your links might need to be more explicit or prominent
+* **Overreliance on certain sections**: If the agent repeatedly reads the same file, consider whether that content should be in the main SKILL.md instead
+* **Ignored content**: If the agent never accesses a bundled file, it might be unnecessary or poorly signaled in the main instructions
 
-Iterate based on these observations rather than assumptions. The 'name' and 'description' in your Skill's metadata are particularly critical. Claude uses these when deciding whether to trigger the Skill in response to the current task. Make sure they clearly describe what the Skill does and when it should be used.
+Iterate based on these observations rather than assumptions. The 'name' and 'description' in your Skill's metadata are particularly critical. Agents use these when deciding whether to trigger the Skill in response to the current task. Make sure they clearly describe what the Skill does and when it should be used.
 
 ## Anti-patterns to avoid
 
@@ -854,7 +854,7 @@ The sections below focus on Skills that include executable scripts. If your Skil
 
 ### Solve, don't punt
 
-When writing scripts for Skills, handle error conditions rather than punting to Claude.
+When writing scripts for Skills, handle error conditions rather than punting to the agent.
 
 **Good example: Handle errors explicitly**:
 
@@ -876,15 +876,15 @@ def process_file(path):
         return ''
 ```
 
-**Bad example: Punt to Claude**:
+**Bad example: Punt to the agent**:
 
 ```python  theme={null}
 def process_file(path):
-    # Just fail and let Claude figure it out
+    # Just fail and let the agent figure it out
     return open(path).read()
 ```
 
-Configuration parameters should also be justified and documented to avoid "voodoo constants" (Ousterhout's law). If you don't know the right value, how will Claude determine it?
+Configuration parameters should also be justified and documented to avoid "voodoo constants" (Ousterhout's law). If you don't know the right value, how will the agent determine it?
 
 **Good example: Self-documenting**:
 
@@ -907,7 +907,7 @@ RETRIES = 5   # Why 5?
 
 ### Provide utility scripts
 
-Even if Claude could write a script, pre-made scripts offer advantages:
+Even if your agent could write a script, pre-made scripts offer advantages:
 
 **Benefits of utility scripts**:
 
@@ -918,9 +918,9 @@ Even if Claude could write a script, pre-made scripts offer advantages:
 
 <img src="https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-executable-scripts.png?fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=4bbc45f2c2e0bee9f2f0d5da669bad00" alt="Bundling executable scripts alongside instruction files" data-og-width="2048" width="2048" data-og-height="1154" height="1154" data-path="images/agent-skills-executable-scripts.png" data-optimize="true" data-opv="3" srcset="https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-executable-scripts.png?w=280&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=9a04e6535a8467bfeea492e517de389f 280w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-executable-scripts.png?w=560&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=e49333ad90141af17c0d7651cca7216b 560w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-executable-scripts.png?w=840&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=954265a5df52223d6572b6214168c428 840w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-executable-scripts.png?w=1100&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=2ff7a2d8f2a83ee8af132b29f10150fd 1100w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-executable-scripts.png?w=1650&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=48ab96245e04077f4d15e9170e081cfb 1650w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-executable-scripts.png?w=2500&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=0301a6c8b3ee879497cc5b5483177c90 2500w" />
 
-The diagram above shows how executable scripts work alongside instruction files. The instruction file (forms.md) references the script, and Claude can execute it without loading its contents into context.
+The diagram above shows how executable scripts work alongside instruction files. The instruction file (forms.md) references the script, and the agent can execute it without loading its contents into context.
 
-**Important distinction**: Make clear in your instructions whether Claude should:
+**Important distinction**: Make clear in your instructions whether the agent should:
 
 * **Execute the script** (most common): "Run `analyze_form.py` to extract fields"
 * **Read it as reference** (for complex logic): "See `analyze_form.py` for the field extraction algorithm"
@@ -962,7 +962,7 @@ python scripts/fill_form.py input.pdf fields.json output.pdf
 
 ### Use visual analysis
 
-When inputs can be rendered as images, have Claude analyze them:
+When inputs can be rendered as images, have the agent analyze them:
 
 ````markdown  theme={null}
 ## Form layout analysis
@@ -973,20 +973,20 @@ When inputs can be rendered as images, have Claude analyze them:
    ```
 
 2. Analyze each page image to identify form fields
-3. Claude can see field locations and types visually
+3. The agent can see field locations and types visually
 ````
 
 <Note>
   In this example, you'd need to write the `pdf_to_images.py` script.
 </Note>
 
-Claude's vision capabilities help understand layouts and structures.
+Agent vision capabilities help understand layouts and structures.
 
 ### Create verifiable intermediate outputs
 
-When Claude performs complex, open-ended tasks, it can make mistakes. The "plan-validate-execute" pattern catches errors early by having Claude first create a plan in a structured format, then validate that plan with a script before executing it.
+When agents perform complex, open-ended tasks, they can make mistakes. The "plan-validate-execute" pattern catches errors early by having the agent first create a plan in a structured format, then validate that plan with a script before executing it.
 
-**Example**: Imagine asking Claude to update 50 form fields in a PDF based on a spreadsheet. Without validation, Claude might reference non-existent fields, create conflicting values, miss required fields, or apply updates incorrectly.
+**Example**: Imagine asking the agent to update 50 form fields in a PDF based on a spreadsheet. Without validation, it might reference non-existent fields, create conflicting values, miss required fields, or apply updates incorrectly.
 
 **Solution**: Use the workflow pattern shown above (PDF form filling), but add an intermediate `changes.json` file that gets validated before applying changes. The workflow becomes: analyze → **create plan file** → **validate plan** → execute → verify.
 
@@ -994,12 +994,12 @@ When Claude performs complex, open-ended tasks, it can make mistakes. The "plan-
 
 * **Catches errors early**: Validation finds problems before changes are applied
 * **Machine-verifiable**: Scripts provide objective verification
-* **Reversible planning**: Claude can iterate on the plan without touching originals
+* **Reversible planning**: The agent can iterate on the plan without touching originals
 * **Clear debugging**: Error messages point to specific problems
 
 **When to use**: Batch operations, destructive changes, complex validation rules, high-stakes operations.
 
-**Implementation tip**: Make validation scripts verbose with specific error messages like "Field 'signature\_date' not found. Available fields: customer\_name, order\_total, signature\_date\_signed" to help Claude fix issues.
+**Implementation tip**: Make validation scripts verbose with specific error messages like "Field 'signature\_date' not found. Available fields: customer\_name, order\_total, signature\_date\_signed" to help the agent fix issues.
 
 ### Package dependencies
 
@@ -1008,32 +1008,32 @@ Skills run in the code execution environment with platform-specific limitations:
 * **claude.ai**: Can install packages from npm and PyPI and pull from GitHub repositories
 * **Anthropic API**: Has no network access and no runtime package installation
 
-List required packages in your SKILL.md and verify they're available in the [code execution tool documentation](/en/docs/agents-and-tools/tool-use/code-execution-tool).
+List required packages in your SKILL.md and verify they're available in the [code execution tool documentation](https://platform.claude.com/docs/en/agents-and-tools/tool-use/code-execution-tool).
 
 ### Runtime environment
 
-Skills run in a code execution environment with filesystem access, bash commands, and code execution capabilities. For the conceptual explanation of this architecture, see [The Skills architecture](/en/docs/agents-and-tools/agent-skills/overview#the-skills-architecture) in the overview.
+Skills run in a code execution environment with filesystem access, bash commands, and code execution capabilities. For the conceptual explanation of this architecture, see [The Skills architecture](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview#the-skills-architecture) in the overview.
 
 **How this affects your authoring:**
 
-**How Claude accesses Skills:**
+**How agents access Skills:**
 
 1. **Metadata pre-loaded**: At startup, the name and description from all Skills' YAML frontmatter are loaded into the system prompt
-2. **Files read on-demand**: Claude uses bash Read tools to access SKILL.md and other files from the filesystem when needed
+2. **Files read on-demand**: Agents use their file-reading tools to access SKILL.md and other files from the filesystem when needed
 3. **Scripts executed efficiently**: Utility scripts can be executed via bash without loading their full contents into context. Only the script's output consumes tokens
 4. **No context penalty for large files**: Reference files, data, or documentation don't consume context tokens until actually read
 
-* **File paths matter**: Claude navigates your skill directory like a filesystem. Use forward slashes (`reference/guide.md`), not backslashes
+* **File paths matter**: Agents navigate your skill directory like a filesystem. Use forward slashes (`reference/guide.md`), not backslashes
 * **Name files descriptively**: Use names that indicate content: `form_validation_rules.md`, not `doc2.md`
 * **Organize for discovery**: Structure directories by domain or feature
   * Good: `reference/finance.md`, `reference/sales.md`
   * Bad: `docs/file1.md`, `docs/file2.md`
 * **Bundle comprehensive resources**: Include complete API docs, extensive examples, large datasets; no context penalty until accessed
-* **Prefer scripts for deterministic operations**: Write `validate_form.py` rather than asking Claude to generate validation code
+* **Prefer scripts for deterministic operations**: Write `validate_form.py` rather than asking the agent to generate validation code
 * **Make execution intent clear**:
   * "Run `analyze_form.py` to extract fields" (execute)
   * "See `analyze_form.py` for the extraction algorithm" (read as reference)
-* **Test file access patterns**: Verify Claude can navigate your directory structure by testing with real requests
+* **Test file access patterns**: Verify the agent can navigate your directory structure by testing with real requests
 
 **Example:**
 
@@ -1046,9 +1046,9 @@ bigquery-skill/
     └── product.md (usage analytics)
 ```
 
-When the user asks about revenue, Claude reads SKILL.md, sees the reference to `reference/finance.md`, and invokes bash to read just that file. The sales.md and product.md files remain on the filesystem, consuming zero context tokens until needed. This filesystem-based model is what enables progressive disclosure. Claude can navigate and selectively load exactly what each task requires.
+When the user asks about revenue, the agent reads SKILL.md, sees the reference to `reference/finance.md`, and invokes bash to read just that file. The sales.md and product.md files remain on the filesystem, consuming zero context tokens until needed. This filesystem-based model is what enables progressive disclosure. Agents can navigate and selectively load exactly what each task requires.
 
-For complete details on the technical architecture, see [How Skills work](/en/docs/agents-and-tools/agent-skills/overview#how-skills-work) in the Skills overview.
+For complete details on the technical architecture, see [How Skills work](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview#how-skills-work) in the Skills overview.
 
 ### MCP tool references
 
@@ -1068,7 +1068,7 @@ Where:
 * `BigQuery` and `GitHub` are MCP server names
 * `bigquery_schema` and `create_issue` are the tool names within those servers
 
-Without the server prefix, Claude may fail to locate the tool, especially when multiple MCP servers are available.
+Without the server prefix, agents may fail to locate the tool, especially when multiple MCP servers are available.
 
 ### Avoid assuming tools are installed
 
@@ -1092,11 +1092,11 @@ reader = PdfReader("file.pdf")
 
 ### YAML frontmatter requirements
 
-The SKILL.md frontmatter requires `name` (64 characters max) and `description` (1024 characters max) fields. See the [Skills overview](/en/docs/agents-and-tools/agent-skills/overview#skill-structure) for complete structure details.
+The SKILL.md frontmatter requires `name` (64 characters max) and `description` (1024 characters max) fields. See the [Skills overview](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview#skill-structure) for complete structure details.
 
 ### Token budgets
 
-Keep SKILL.md body under 500 lines for optimal performance. If your content exceeds this, split it into separate files using the progressive disclosure patterns described earlier. For architectural details, see the [Skills overview](/en/docs/agents-and-tools/agent-skills/overview#how-skills-work).
+Keep SKILL.md body under 500 lines for optimal performance. If your content exceeds this, split it into separate files using the progressive disclosure patterns described earlier. For architectural details, see the [Skills overview](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview#how-skills-work).
 
 ## Checklist for effective Skills
 
@@ -1117,7 +1117,7 @@ Before sharing a Skill, verify:
 
 ### Code and scripts
 
-* [ ] Scripts solve problems rather than punt to Claude
+* [ ] Scripts solve problems rather than punt to the agent
 * [ ] Error handling is explicit and helpful
 * [ ] No "voodoo constants" (all values justified)
 * [ ] Required packages listed in instructions and verified as available
@@ -1136,15 +1136,15 @@ Before sharing a Skill, verify:
 ## Next steps
 
 <CardGroup cols={2}>
-  <Card title="Get started with Agent Skills" icon="rocket" href="/en/docs/agents-and-tools/agent-skills/quickstart">
+  <Card title="Get started with Agent Skills" icon="rocket" href="https://platform.claude.com/docs/en/agents-and-tools/agent-skills/quickstart">
     Create your first Skill
   </Card>
 
-  <Card title="Use Skills in Claude Code" icon="terminal" href="/en/docs/claude-code/skills">
+  <Card title="Use Skills in Claude Code" icon="terminal" href="https://code.claude.com/docs/en/skills">
     Create and manage Skills in Claude Code
   </Card>
 
-  <Card title="Use Skills with the API" icon="code" href="/en/api/skills-guide">
+  <Card title="Use Skills with the API" icon="code" href="https://platform.claude.com/docs/en/build-with-claude/skills-guide">
     Upload and use Skills programmatically
   </Card>
 </CardGroup>
diff --git a/skills/superpowers/writing-skills/persuasion-principles.md b/skills/superpowers/writing-skills/persuasion-principles.md
index 9818a5f..9756416 100644
--- a/skills/superpowers/writing-skills/persuasion-principles.md
+++ b/skills/superpowers/writing-skills/persuasion-principles.md
@@ -33,7 +33,7 @@ LLMs respond to the same persuasion principles as humans. Understanding this psy
 **How it works in skills:**
 - Require announcements: "Announce skill usage"
 - Force explicit choices: "Choose A, B, or C"
-- Use tracking: TodoWrite for checklists
+- Use tracking: todos for checklists
 
 **When to use:**
 - Ensuring skills are actually followed
@@ -80,8 +80,8 @@ LLMs respond to the same persuasion principles as humans. Understanding this psy
 
 **Example:**
 ```markdown
-✅ Checklists without TodoWrite tracking = steps get skipped. Every time.
-❌ Some people find TodoWrite helpful for checklists.
+✅ Checklists without todo tracking = steps get skipped. Every time.
+❌ Some people find a todo list helpful for checklists.
 ```
 
 ### 5. Unity
diff --git a/update_summary.md b/update_summary.md
index 4f0b583..91d4783 100644
--- a/update_summary.md
+++ b/update_summary.md
@@ -1,4169 +1,3248 @@
 ## Updated Skills
 
-Submodule skills/scientific-agent-skills 9881fe4..e6cabc2:
+Submodule skills/AI-research-SKILLs 28f2d29..773a529:
+  > release: v1.7.2 — ship Qoder agent auto-detection to npm
+  > feat(agents): add Qoder to supported agents (#29)
+  > feat(model-merging): add unsupervised coefficient tuning via generation consistency (#34)
+  > fix(release): v1.7.1 — repair lockfile sync and pin deps to patched versions (#62)
+  > release: v1.7.0 — inventory consistency, drift guard & security hardening (#61)
+  > docs: correct skill/category inventory to 98/23 + add drift guard (#60)
+  > fix(security): pin npm dependency versions to exact ranges (#53)
+Submodule skills/scientific-agent-skills e6cabc2..ddd2f7f:
   > chore: update security scan report [skip ci]
-  > Update transformers skill metadata and dependencies; remove uv.lock file
-  > Add arbor skill
-  > Update version to 2.51.0 in pyproject.toml
-  > Update Scanpy skill
-  > Update PyOpenMS skill
-  > Update examples
-  > Update version to 2.50.0 and increment skill count to 146
-  > Update documentation to include NVIDIA NemoClaw and Pi in Agent Skills installation instructions
-  > Enhance skills metadata with required environment variables
-  > Enhance skills metadata with OpenClaw environment variables
-  > Support OpenClaw
-  > Sync citation-management skill with claude-scientific-writer updates (#188)
-  > Update version to 2.48.0 in pyproject.toml and uv.lock; enhance NetworkX skill documentation to reflect changes in API and deprecated features for compatibility with NetworkX 3.x.
-  > Update astropy skill documentation and version; enhance compatibility notes and clarify deprecated features in preparation for Astropy 8.0. Bump astropy version to 1.2 and update dependencies in uv.lock.
-  > Update pi-agent skill
-  > Update README and documentation to reflect the addition of new skills, increasing the total to 144. Adjust badge counts and enhance descriptions for clarity and accuracy.
-  > Add support for Pi
-diff --git a/update_summary.md b/update_summary.md
-index 216ffa9..98b6e19 100644
---- a/update_summary.md
-+++ b/update_summary.md
-@@ -1,4143 +1,2 @@
- ## Updated Skills
- 
--Submodule skills/humanizer a2ace14..9600f2b:
--  > Add style cadence AI tells (v2.8.0)
--Submodule skills/scientific-agent-skills 9312485..9881fe4:
--  > chore: update security scan report [skip ci]
--  > chore: update security scan report [skip ci]
--  > Enhance documentation for cellxgene-census and deepTools skills. Update cellxgene-census to version 1.1, expanding description, compatibility notes, and data structure details for single-cell and spatial transcriptomics. Revise deepTools to version 1.1, improving installation instructions, normalization methods, and adding new features for effective genome size and scaling. Update quick reference and workflow scripts for better usability and clarity.
--  > Update anndata skill documentation to version 1.1, enhancing compatibility notes and installation instructions. Introduce experimental APIs for lazy loading and concatenation, and clarify usage of deprecated methods. Update best practices for I/O operations and metadata handling.
--  > Update LaminDB, Pennylane and Neuropixles skills
--  > Update scanpy skill documentation to include support for R-native single-cell formats. Bump version to 1.2 and enhance conversion instructions for Seurat and SingleCellExperiment files to .h5ad. Add references for R interoperability and clarify usage scenarios.
--diff --git a/update_summary.md b/update_summary.md
--index ef882bb..98b6e19 100644
----- a/update_summary.md
--+++ b/update_summary.md
--@@ -1,4127 +1,2 @@
-- ## Updated Skills
-- 
---Submodule skills/humanizer 8b3a178..a2ace14:
---  > Add em/en dash cut, gap-filling tell, and diff-anchored pattern (v2.7.0)
---  > Cleanup pass: cut bloat and fix the aggressiveness contradiction (v2.6.0)
---  > Replace WARP.md with tool-neutral AGENTS.md
---  > Merge pull request #84 from mvanhorn/fix/78-content-preservation
---  > Merge pull request #113 from philippdubach/detection-guidance
---  > Merge pull request #121 from Longman006/fix/section-26-attributive-vs-predicate-hyphens
---  > Merge pull request #119 from MackDing/mack/pr-20260519-1107-humanizer
---Submodule skills/scientific-agent-skills 5bd00bf..9312485:
---  > chore: update security scan report [skip ci]
---  > Update scvi-tools
---  > Update scikit-bio
---  > Update Modal skill
---  > Add bulk-rnaseq workflow skill
---  > Add pathway-enrichment skill
---  > Bump version
---  > Add support for Nextflow
---  > Bump version
---  > docs: update dependencies and skills documentation for dask, pymoo, and scanpy
---  > docs: update skills documentation for scientific-critical-thinking and stable-baselines3
---  > docs: update scikit-learn skill documentation and references
---  > docs: update research grants skill documentation and templates
---  > docs: update skills documentation for histolab and astropy
---  > docs: enhance README with new star encouragement section
---  > docs: update README to include Star History and refine skills usage descriptions
---  > Update directory for compatibility
---  > Update directory
---  > docs: update SKILL.md for bgpt-paper-search compatibility and usage instructions
---  > docs: update SKILL.md for Adaptyv API enhancements
---  > docs: update SKILL.md and related references for Benchling integration
---  > docs: update README and SKILL.md files for versioning and new features
---  > docs: update README to include Google Antigravity support and enhance follow-up information
---  > chore: keep agent guidance local
---  > docs: enhance README with contribution guidelines and citation practices
---  > chore: update metadata for scientific skills
---  > chore: update documentation and descriptions for scientific skills
---  > chore: update PyTorch Lightning documentation and installation instructions
---  > chore: update scientific-agent-skills version to 2.42.0
---  > Add suppor for LiteParse from LlamaIndex
---  > chore: bump scientific-agent-skills version to 2.41.0
---  > refactor: enhance medchem and esm documentation and functionality
---  > chore: update Biopython and Datamol documentation
---  > chore: update .gitignore and bump scientific-agent-skills version to 2.40.0
---  > Bump version
---diff --git a/update_summary.md b/update_summary.md
---index 7f6f6a1..98b6e19 100644
------ a/update_summary.md
---+++ b/update_summary.md
---@@ -1,4076 +1,2 @@
--- ## Updated Skills
--- 
----Submodule skills/scientific-agent-skills 63de55a..5bd00bf:
----  > chore: update security scan report [skip ci]
----  > Merge pull request #156 from Beifang/feature/pacsomatic
----  > Merge pull request #90 from StevenDillmann/feat/simbad-database-skill
----  > Update README.md for improved link formatting and table of contents consistency
----  > Bump version and added community contributions
----diff --git a/update_summary.md b/update_summary.md
----index e08889b..98b6e19 100644
------- a/update_summary.md
----+++ b/update_summary.md
----@@ -1,4063 +1,2 @@
---- ## Updated Skills
---- 
-----Submodule skills/scientific-agent-skills cbcae7b..63de55a:
-----  > chore: update security scan report [skip ci]
-----  > Merge pull request #116 from robotlearning123/fix/neuropixels-broken-links
-----  > Merge pull request #94 from jiaodu1307/fix/rdkit-skill-gzip-import-clean
-----  > Merge pull request #125 from yarikoptic/enh-bids
-----  > Merge pull request #147 from xiaolai/fix/nlpm-scanpy-license-typo
-----  > Merge pull request #164 from mvanhorn/fix/159-research-lookup-yaml-frontmatter
-----  > Merge pull request #165 from Travisma2233/venue-templates/add-elsarticle
-----diff --git a/update_summary.md b/update_summary.md
-----index d98bc33..98b6e19 100644
-------- a/update_summary.md
-----+++ b/update_summary.md
-----@@ -1,4048 +1,2 @@
----- ## Updated Skills
----- 
------Submodule skills/scientific-agent-skills 37a148b..cbcae7b:
------  > chore: update security scan report [skip ci]
------  > Merge pull request #143 from tgonzalezc5/feat/exa-search-skill
------diff --git a/skills/superpowers/executing-plans/SKILL.md b/skills/superpowers/executing-plans/SKILL.md
------index e67f94c..a591862 100644
--------- a/skills/superpowers/executing-plans/SKILL.md
------+++ b/skills/superpowers/executing-plans/SKILL.md
------@@ -65,6 +65,6 @@ After all tasks complete and verified:
------ ## Integration
------ 
------ **Required workflow skills:**
-------- **superpowers:using-git-worktrees** - REQUIRED: Set up isolated workspace before starting
------+- **superpowers:using-git-worktrees** - Ensures isolated workspace (creates one or verifies existing)
------ - **superpowers:writing-plans** - Creates the plan this skill executes
------ - **superpowers:finishing-a-development-branch** - Complete development after all tasks
------diff --git a/skills/superpowers/finishing-a-development-branch/SKILL.md b/skills/superpowers/finishing-a-development-branch/SKILL.md
------index c308b43..43da0ae 100644
--------- a/skills/superpowers/finishing-a-development-branch/SKILL.md
------+++ b/skills/superpowers/finishing-a-development-branch/SKILL.md
------@@ -9,7 +9,7 @@ description: Use when implementation is complete, all tests pass, and you need t
------ 
------ Guide completion of development work by presenting clear options and handling chosen workflow.
------ 
-------**Core principle:** Verify tests → Present options → Execute choice → Clean up.
------+**Core principle:** Verify tests → Detect environment → Present options → Execute choice → Clean up.
------ 
------ **Announce at start:** "I'm using the finishing-a-development-branch skill to complete this work."
------ 
------@@ -37,7 +37,24 @@ Stop. Don't proceed to Step 2.
------ 
------ **If tests pass:** Continue to Step 2.
------ 
-------### Step 2: Determine Base Branch
------+### Step 2: Detect Environment
------+
------+**Determine workspace state before presenting options:**
------+
------+```bash
------+GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
------+GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
------+```
------+
------+This determines which menu to show and how cleanup works:
------+
------+| State | Menu | Cleanup |
------+|-------|------|---------|
------+| `GIT_DIR == GIT_COMMON` (normal repo) | Standard 4 options | No worktree to clean up |
------+| `GIT_DIR != GIT_COMMON`, named branch | Standard 4 options | Provenance-based (see Step 6) |
------+| `GIT_DIR != GIT_COMMON`, detached HEAD | Reduced 3 options (no merge) | No cleanup (externally managed) |
------+
------+### Step 3: Determine Base Branch
------ 
------ ```bash
------ # Try common base branches
------@@ -46,9 +63,9 @@ git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
------ 
------ Or ask: "This branch split from main - is that correct?"
------ 
-------### Step 3: Present Options
------+### Step 4: Present Options
------ 
-------Present exactly these 4 options:
------+**Normal repo and named-branch worktree — present exactly these 4 options:**
------ 
------ ```
------ Implementation complete. What would you like to do?
------@@ -61,30 +78,45 @@ Implementation complete. What would you like to do?
------ Which option?
------ ```
------ 
------+**Detached HEAD — present exactly these 3 options:**
------+
------+```
------+Implementation complete. You're on a detached HEAD (externally managed workspace).
------+
------+1. Push as new branch and create a Pull Request
------+2. Keep as-is (I'll handle it later)
------+3. Discard this work
------+
------+Which option?
------+```
------+
------ **Don't add explanation** - keep options concise.
------ 
-------### Step 4: Execute Choice
------+### Step 5: Execute Choice
------ 
------ #### Option 1: Merge Locally
------ 
------ ```bash
-------# Switch to base branch
-------git checkout <base-branch>
------+# Get main repo root for CWD safety
------+MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
------+cd "$MAIN_ROOT"
------ 
-------# Pull latest
------+# Merge first — verify success before removing anything
------+git checkout <base-branch>
------ git pull
-------
-------# Merge feature branch
------ git merge <feature-branch>
------ 
------ # Verify tests on merged result
------ <test command>
------ 
-------# If tests pass
-------git branch -d <feature-branch>
------+# Only after merge succeeds: cleanup worktree (Step 6), then delete branch
------ ```
------ 
-------Then: Cleanup worktree (Step 5)
------+Then: Cleanup worktree (Step 6), then delete branch:
------+
------+```bash
------+git branch -d <feature-branch>
------+```
------ 
------ #### Option 2: Push and Create PR
------ 
------@@ -103,7 +135,7 @@ EOF
------ )"
------ ```
------ 
-------Then: Cleanup worktree (Step 5)
------+**Do NOT clean up worktree** — user needs it alive to iterate on PR feedback.
------ 
------ #### Option 3: Keep As-Is
------ 
------@@ -127,36 +159,46 @@ Wait for exact confirmation.
------ 
------ If confirmed:
------ ```bash
-------git checkout <base-branch>
-------git branch -D <feature-branch>
------+MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
------+cd "$MAIN_ROOT"
------ ```
------ 
-------Then: Cleanup worktree (Step 5)
------+Then: Cleanup worktree (Step 6), then force-delete branch:
------+```bash
------+git branch -D <feature-branch>
------+```
------ 
-------### Step 5: Cleanup Worktree
------+### Step 6: Cleanup Workspace
------ 
-------**For Options 1, 2, 4:**
------+**Only runs for Options 1 and 4.** Options 2 and 3 always preserve the worktree.
------ 
-------Check if in worktree:
------ ```bash
-------git worktree list | grep $(git branch --show-current)
------+GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
------+GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
------+WORKTREE_PATH=$(git rev-parse --show-toplevel)
------ ```
------ 
-------If yes:
------+**If `GIT_DIR == GIT_COMMON`:** Normal repo, no worktree to clean up. Done.
------+
------+**If worktree path is under `.worktrees/`, `worktrees/`, or `~/.config/superpowers/worktrees/`:** Superpowers created this worktree — we own cleanup.
------+
------ ```bash
-------git worktree remove <worktree-path>
------+MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
------+cd "$MAIN_ROOT"
------+git worktree remove "$WORKTREE_PATH"
------+git worktree prune  # Self-healing: clean up any stale registrations
------ ```
------ 
-------**For Option 3:** Keep worktree.
------+**Otherwise:** The host environment (harness) owns this workspace. Do NOT remove it. If your platform provides a workspace-exit tool, use it. Otherwise, leave the workspace in place.
------ 
------ ## Quick Reference
------ 
------ | Option | Merge | Push | Keep Worktree | Cleanup Branch |
------ |--------|-------|------|---------------|----------------|
-------| 1. Merge locally | ✓ | - | - | ✓ |
-------| 2. Create PR | - | ✓ | ✓ | - |
-------| 3. Keep as-is | - | - | ✓ | - |
-------| 4. Discard | - | - | - | ✓ (force) |
------+| 1. Merge locally | yes | - | - | yes |
------+| 2. Create PR | - | yes | yes | - |
------+| 3. Keep as-is | - | - | yes | - |
------+| 4. Discard | - | - | - | yes (force) |
------ 
------ ## Common Mistakes
------ 
------@@ -165,13 +207,25 @@ git worktree remove <worktree-path>
------ - **Fix:** Always verify tests before offering options
------ 
------ **Open-ended questions**
-------- **Problem:** "What should I do next?" → ambiguous
-------- **Fix:** Present exactly 4 structured options
------+- **Problem:** "What should I do next?" is ambiguous
------+- **Fix:** Present exactly 4 structured options (or 3 for detached HEAD)
------ 
-------**Automatic worktree cleanup**
-------- **Problem:** Remove worktree when might need it (Option 2, 3)
------+**Cleaning up worktree for Option 2**
------+- **Problem:** Remove worktree user needs for PR iteration
------ - **Fix:** Only cleanup for Options 1 and 4
------ 
------+**Deleting branch before removing worktree**
------+- **Problem:** `git branch -d` fails because worktree still references the branch
------+- **Fix:** Merge first, remove worktree, then delete branch
------+
------+**Running git worktree remove from inside the worktree**
------+- **Problem:** Command fails silently when CWD is inside the worktree being removed
------+- **Fix:** Always `cd` to main repo root before `git worktree remove`
------+
------+**Cleaning up harness-owned worktrees**
------+- **Problem:** Removing a worktree the harness created causes phantom state
------+- **Fix:** Only clean up worktrees under `.worktrees/`, `worktrees/`, or `~/.config/superpowers/worktrees/`
------+
------ **No confirmation for discard**
------ - **Problem:** Accidentally delete work
------ - **Fix:** Require typed "discard" confirmation
------@@ -183,18 +237,15 @@ git worktree remove <worktree-path>
------ - Merge without verifying tests on result
------ - Delete work without confirmation
------ - Force-push without explicit request
------+- Remove a worktree before confirming merge success
------+- Clean up worktrees you didn't create (provenance check)
------+- Run `git worktree remove` from inside the worktree
------ 
------ **Always:**
------ - Verify tests before offering options
-------- Present exactly 4 options
------+- Detect environment before presenting menu
------+- Present exactly 4 options (or 3 for detached HEAD)
------ - Get typed confirmation for Option 4
------ - Clean up worktree for Options 1 & 4 only
-------
-------## Integration
-------
-------**Called by:**
-------- **subagent-driven-development** (Step 7) - After all tasks complete
-------- **executing-plans** (Step 5) - After all batches complete
-------
-------**Pairs with:**
-------- **using-git-worktrees** - Cleans up worktree created by that skill
------+- `cd` to main repo root before worktree removal
------+- Run `git worktree prune` after removal
------diff --git a/skills/superpowers/requesting-code-review/SKILL.md b/skills/superpowers/requesting-code-review/SKILL.md
------index fe7c8d9..34b8340 100644
--------- a/skills/superpowers/requesting-code-review/SKILL.md
------+++ b/skills/superpowers/requesting-code-review/SKILL.md
------@@ -5,7 +5,7 @@ description: Use when completing tasks, implementing major features, or before m
------ 
------ # Requesting Code Review
------ 
-------Dispatch superpowers:code-reviewer subagent to catch issues before they cascade. The reviewer gets precisely crafted context for evaluation — never your session's history. This keeps the reviewer focused on the work product, not your thought process, and preserves your own context for continued work.
------+Dispatch a code reviewer subagent to catch issues before they cascade. The reviewer gets precisely crafted context for evaluation — never your session's history. This keeps the reviewer focused on the work product, not your thought process, and preserves your own context for continued work.
------ 
------ **Core principle:** Review early, review often.
------ 
------@@ -29,16 +29,15 @@ BASE_SHA=$(git rev-parse HEAD~1)  # or origin/main
------ HEAD_SHA=$(git rev-parse HEAD)
------ ```
------ 
-------**2. Dispatch code-reviewer subagent:**
------+**2. Dispatch code reviewer subagent:**
------ 
-------Use Task tool with superpowers:code-reviewer type, fill template at `code-reviewer.md`
------+Use Task tool with `general-purpose` type, fill template at `code-reviewer.md`
------ 
------ **Placeholders:**
-------- `{WHAT_WAS_IMPLEMENTED}` - What you just built
------+- `{DESCRIPTION}` - Brief summary of what you built
------ - `{PLAN_OR_REQUIREMENTS}` - What it should do
------ - `{BASE_SHA}` - Starting commit
------ - `{HEAD_SHA}` - Ending commit
-------- `{DESCRIPTION}` - Brief summary
------ 
------ **3. Act on feedback:**
------ - Fix Critical issues immediately
------@@ -56,12 +55,11 @@ You: Let me request code review before proceeding.
------ BASE_SHA=$(git log --oneline | grep "Task 1" | head -1 | awk '{print $1}')
------ HEAD_SHA=$(git rev-parse HEAD)
------ 
-------[Dispatch superpowers:code-reviewer subagent]
-------  WHAT_WAS_IMPLEMENTED: Verification and repair functions for conversation index
------+[Dispatch code reviewer subagent]
------+  DESCRIPTION: Added verifyIndex() and repairIndex() with 4 issue types
------   PLAN_OR_REQUIREMENTS: Task 2 from docs/superpowers/plans/deployment-plan.md
------   BASE_SHA: a7981ec
------   HEAD_SHA: 3df7661
-------  DESCRIPTION: Added verifyIndex() and repairIndex() with 4 issue types
------ 
------ [Subagent returns]:
------   Strengths: Clean architecture, real tests
------@@ -82,7 +80,7 @@ You: [Fix progress indicators]
------ - Fix before moving to next task
------ 
------ **Executing Plans:**
-------- Review after each batch (3 tasks)
------+- Review after each task or at natural checkpoints
------ - Get feedback, apply, continue
------ 
------ **Ad-Hoc Development:**
------diff --git a/skills/superpowers/requesting-code-review/code-reviewer.md b/skills/superpowers/requesting-code-review/code-reviewer.md
------index 3c427c9..525e4b4 100644
--------- a/skills/superpowers/requesting-code-review/code-reviewer.md
------+++ b/skills/superpowers/requesting-code-review/code-reviewer.md
------@@ -1,111 +1,133 @@
-------# Code Review Agent
------+# Code Reviewer Prompt Template
------ 
-------You are reviewing code changes for production readiness.
------+Use this template when dispatching a code reviewer subagent.
------ 
-------**Your task:**
-------1. Review {WHAT_WAS_IMPLEMENTED}
-------2. Compare against {PLAN_OR_REQUIREMENTS}
-------3. Check code quality, architecture, testing
-------4. Categorize issues by severity
-------5. Assess production readiness
------+**Purpose:** Review completed work against requirements and code quality standards before it cascades into more work.
------ 
-------## What Was Implemented
------+```
------+Task tool (general-purpose):
------+  description: "Review code changes"
------+  prompt: |
------+    You are a Senior Code Reviewer with expertise in software architecture,
------+    design patterns, and best practices. Your job is to review completed work
------+    against its plan or requirements and identify issues before they cascade.
------ 
-------{DESCRIPTION}
------+    ## What Was Implemented
------ 
-------## Requirements/Plan
------+    {DESCRIPTION}
------ 
-------{PLAN_REFERENCE}
------+    ## Requirements / Plan
------ 
-------## Git Range to Review
------+    {PLAN_OR_REQUIREMENTS}
------ 
-------**Base:** {BASE_SHA}
-------**Head:** {HEAD_SHA}
------+    ## Git Range to Review
------ 
-------```bash
-------git diff --stat {BASE_SHA}..{HEAD_SHA}
-------git diff {BASE_SHA}..{HEAD_SHA}
-------```
------+    **Base:** {BASE_SHA}
------+    **Head:** {HEAD_SHA}
------ 
-------## Review Checklist
-------
-------**Code Quality:**
-------- Clean separation of concerns?
-------- Proper error handling?
-------- Type safety (if applicable)?
-------- DRY principle followed?
-------- Edge cases handled?
-------
-------**Architecture:**
-------- Sound design decisions?
-------- Scalability considerations?
-------- Performance implications?
-------- Security concerns?
-------
-------**Testing:**
-------- Tests actually test logic (not mocks)?
-------- Edge cases covered?
-------- Integration tests where needed?
-------- All tests passing?
-------
-------**Requirements:**
-------- All plan requirements met?
-------- Implementation matches spec?
-------- No scope creep?
-------- Breaking changes documented?
-------
-------**Production Readiness:**
-------- Migration strategy (if schema changes)?
-------- Backward compatibility considered?
-------- Documentation complete?
-------- No obvious bugs?
-------
-------## Output Format
------+    ```bash
------+    git diff --stat {BASE_SHA}..{HEAD_SHA}
------+    git diff {BASE_SHA}..{HEAD_SHA}
------+    ```
------ 
-------### Strengths
-------[What's well done? Be specific.]
------+    ## What to Check
------ 
-------### Issues
------+    **Plan alignment:**
------+    - Does the implementation match the plan / requirements?
------+    - Are deviations justified improvements, or problematic departures?
------+    - Is all planned functionality present?
------ 
-------#### Critical (Must Fix)
-------[Bugs, security issues, data loss risks, broken functionality]
------+    **Code quality:**
------+    - Clean separation of concerns?
------+    - Proper error handling?
------+    - Type safety where applicable?
------+    - DRY without premature abstraction?
------+    - Edge cases handled?
------ 
-------#### Important (Should Fix)
-------[Architecture problems, missing features, poor error handling, test gaps]
------+    **Architecture:**
------+    - Sound design decisions?
------+    - Reasonable scalability and performance?
------+    - Security concerns?
------+    - Integrates cleanly with surrounding code?
------ 
-------#### Minor (Nice to Have)
-------[Code style, optimization opportunities, documentation improvements]
------+    **Testing:**
------+    - Tests verify real behavior, not mocks?
------+    - Edge cases covered?
------+    - Integration tests where they matter?
------+    - All tests passing?
------ 
-------**For each issue:**
-------- File:line reference
-------- What's wrong
-------- Why it matters
-------- How to fix (if not obvious)
------+    **Production readiness:**
------+    - Migration strategy if schema changed?
------+    - Backward compatibility considered?
------+    - Documentation complete?
------+    - No obvious bugs?
------ 
-------### Recommendations
-------[Improvements for code quality, architecture, or process]
------+    ## Calibration
------ 
-------### Assessment
------+    Categorize issues by actual severity. Not everything is Critical.
------+    Acknowledge what was done well before listing issues — accurate praise
------+    helps the implementer trust the rest of the feedback.
------+
------+    If you find significant deviations from the plan, flag them specifically
------+    so the implementer can confirm whether the deviation was intentional.
------+    If you find issues with the plan itself rather than the implementation,
------+    say so.
------+
------+    ## Output Format
------+
------+    ### Strengths
------+    [What's well done? Be specific.]
------+
------+    ### Issues
------ 
-------**Ready to merge?** [Yes/No/With fixes]
------+    #### Critical (Must Fix)
------+    [Bugs, security issues, data loss risks, broken functionality]
------ 
-------**Reasoning:** [Technical assessment in 1-2 sentences]
------+    #### Important (Should Fix)
------+    [Architecture problems, missing features, poor error handling, test gaps]
------ 
-------## Critical Rules
------+    #### Minor (Nice to Have)
------+    [Code style, optimization opportunities, documentation polish]
------+
------+    For each issue:
------+    - File:line reference
------+    - What's wrong
------+    - Why it matters
------+    - How to fix (if not obvious)
------+
------+    ### Recommendations
------+    [Improvements for code quality, architecture, or process]
------+
------+    ### Assessment
------+
------+    **Ready to merge?** [Yes | No | With fixes]
------+
------+    **Reasoning:** [1-2 sentence technical assessment]
------+
------+    ## Critical Rules
------+
------+    **DO:**
------+    - Categorize by actual severity
------+    - Be specific (file:line, not vague)
------+    - Explain WHY each issue matters
------+    - Acknowledge strengths
------+    - Give a clear verdict
------+
------+    **DON'T:**
------+    - Say "looks good" without checking
------+    - Mark nitpicks as Critical
------+    - Give feedback on code you didn't actually read
------+    - Be vague ("improve error handling")
------+    - Avoid giving a clear verdict
------+```
------ 
-------**DO:**
-------- Categorize by actual severity (not everything is Critical)
-------- Be specific (file:line, not vague)
-------- Explain WHY issues matter
-------- Acknowledge strengths
-------- Give clear verdict
------+**Placeholders:**
------+- `{DESCRIPTION}` — brief summary of what was built
------+- `{PLAN_OR_REQUIREMENTS}` — what it should do (plan file path, task text, or requirements)
------+- `{BASE_SHA}` — starting commit
------+- `{HEAD_SHA}` — ending commit
------ 
-------**DON'T:**
-------- Say "looks good" without checking
-------- Mark nitpicks as Critical
-------- Give feedback on code you didn't review
-------- Be vague ("improve error handling")
-------- Avoid giving a clear verdict
------+**Reviewer returns:** Strengths, Issues (Critical / Important / Minor), Recommendations, Assessment
------ 
------ ## Example Output
------ 
------diff --git a/skills/superpowers/subagent-driven-development/SKILL.md b/skills/superpowers/subagent-driven-development/SKILL.md
------index 5150b18..ea7ac8f 100644
--------- a/skills/superpowers/subagent-driven-development/SKILL.md
------+++ b/skills/superpowers/subagent-driven-development/SKILL.md
------@@ -11,6 +11,8 @@ Execute plan by dispatching fresh subagent per task, with two-stage review after
------ 
------ **Core principle:** Fresh subagent per task + two-stage review (spec then quality) = high quality, fast iteration
------ 
------+**Continuous execution:** Do not pause to check in with your human partner between tasks. Execute all tasks from the plan without stopping. The only reasons to stop are: BLOCKED status you cannot resolve, ambiguity that genuinely prevents progress, or all tasks complete. "Should I continue?" prompts and progress summaries waste their time — they asked you to execute the plan, so execute it.
------+
------ ## When to Use
------ 
------ ```dot
------@@ -265,7 +267,7 @@ Done!
------ ## Integration
------ 
------ **Required workflow skills:**
-------- **superpowers:using-git-worktrees** - REQUIRED: Set up isolated workspace before starting
------+- **superpowers:using-git-worktrees** - Ensures isolated workspace (creates one or verifies existing)
------ - **superpowers:writing-plans** - Creates the plan this skill executes
------ - **superpowers:requesting-code-review** - Code review template for reviewer subagents
------ - **superpowers:finishing-a-development-branch** - Complete development after all tasks
------diff --git a/skills/superpowers/subagent-driven-development/code-quality-reviewer-prompt.md b/skills/superpowers/subagent-driven-development/code-quality-reviewer-prompt.md
------index a04201a..51f901a 100644
--------- a/skills/superpowers/subagent-driven-development/code-quality-reviewer-prompt.md
------+++ b/skills/superpowers/subagent-driven-development/code-quality-reviewer-prompt.md
------@@ -7,14 +7,13 @@ Use this template when dispatching a code quality reviewer subagent.
------ **Only dispatch after spec compliance review passes.**
------ 
------ ```
-------Task tool (superpowers:code-reviewer):
------+Task tool (general-purpose):
------   Use template at requesting-code-review/code-reviewer.md
------ 
-------  WHAT_WAS_IMPLEMENTED: [from implementer's report]
------+  DESCRIPTION: [task summary, from implementer's report]
------   PLAN_OR_REQUIREMENTS: Task N from [plan-file]
------   BASE_SHA: [commit before task]
------   HEAD_SHA: [current commit]
-------  DESCRIPTION: [task summary]
------ ```
------ 
------ **In addition to standard code quality concerns, the reviewer should check:**
------diff --git a/skills/superpowers/systematic-debugging/CREATION-LOG.md b/skills/superpowers/systematic-debugging/CREATION-LOG.md
------index 024d00a..9aa0309 100644
--------- a/skills/superpowers/systematic-debugging/CREATION-LOG.md
------+++ b/skills/superpowers/systematic-debugging/CREATION-LOG.md
------@@ -4,7 +4,7 @@ Reference example of extracting, structuring, and bulletproofing a critical skil
------ 
------ ## Source Material
------ 
-------Extracted debugging framework from `/Users/jesse/.claude/CLAUDE.md`:
------+Extracted debugging framework from `~/.claude/CLAUDE.md`:
------ - 4-phase systematic process (Investigation → Pattern Analysis → Hypothesis → Implementation)
------ - Core mandate: ALWAYS find root cause, NEVER fix symptoms
------ - Rules designed to resist time pressure and rationalization
------diff --git a/skills/superpowers/systematic-debugging/root-cause-tracing.md b/skills/superpowers/systematic-debugging/root-cause-tracing.md
------index 9484774..12ef522 100644
--------- a/skills/superpowers/systematic-debugging/root-cause-tracing.md
------+++ b/skills/superpowers/systematic-debugging/root-cause-tracing.md
------@@ -33,7 +33,7 @@ digraph when_to_use {
------ 
------ ### 1. Observe the Symptom
------ ```
-------Error: git init failed in /Users/jesse/project/packages/core
------+Error: git init failed in ~/project/packages/core
------ ```
------ 
------ ### 2. Find Immediate Cause
------diff --git a/skills/superpowers/using-git-worktrees/SKILL.md b/skills/superpowers/using-git-worktrees/SKILL.md
------index e153843..134d371 100644
--------- a/skills/superpowers/using-git-worktrees/SKILL.md
------+++ b/skills/superpowers/using-git-worktrees/SKILL.md
------@@ -1,104 +1,117 @@
------ ---
------ name: using-git-worktrees
-------description: Use when starting feature work that needs isolation from current workspace or before executing implementation plans - creates isolated git worktrees with smart directory selection and safety verification
------+description: Use when starting feature work that needs isolation from current workspace or before executing implementation plans - ensures an isolated workspace exists via native tools or git worktree fallback
------ ---
------ 
------ # Using Git Worktrees
------ 
------ ## Overview
------ 
-------Git worktrees create isolated workspaces sharing the same repository, allowing work on multiple branches simultaneously without switching.
------+Ensure work happens in an isolated workspace. Prefer your platform's native worktree tools. Fall back to manual git worktrees only when no native tool is available.
------ 
-------**Core principle:** Systematic directory selection + safety verification = reliable isolation.
------+**Core principle:** Detect existing isolation first. Then use native tools. Then fall back to git. Never fight the harness.
------ 
------ **Announce at start:** "I'm using the using-git-worktrees skill to set up an isolated workspace."
------ 
-------## Directory Selection Process
------+## Step 0: Detect Existing Isolation
------ 
-------Follow this priority order:
-------
-------### 1. Check Existing Directories
------+**Before creating anything, check if you are already in an isolated workspace.**
------ 
------ ```bash
-------# Check in priority order
-------ls -d .worktrees 2>/dev/null     # Preferred (hidden)
-------ls -d worktrees 2>/dev/null      # Alternative
------+GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
------+GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
------+BRANCH=$(git branch --show-current)
------ ```
------ 
-------**If found:** Use that directory. If both exist, `.worktrees` wins.
-------
-------### 2. Check CLAUDE.md
------+**Submodule guard:** `GIT_DIR != GIT_COMMON` is also true inside git submodules. Before concluding "already in a worktree," verify you are not in a submodule:
------ 
------ ```bash
-------grep -i "worktree.*director" CLAUDE.md 2>/dev/null
------+# If this returns a path, you're in a submodule, not a worktree — treat as normal repo
------+git rev-parse --show-superproject-working-tree 2>/dev/null
------ ```
------ 
-------**If preference specified:** Use it without asking.
------+**If `GIT_DIR != GIT_COMMON` (and not a submodule):** You are already in a linked worktree. Skip to Step 3 (Project Setup). Do NOT create another worktree.
------ 
-------### 3. Ask User
------+Report with branch state:
------+- On a branch: "Already in isolated workspace at `<path>` on branch `<name>`."
------+- Detached HEAD: "Already in isolated workspace at `<path>` (detached HEAD, externally managed). Branch creation needed at finish time."
------ 
-------If no directory exists and no CLAUDE.md preference:
------+**If `GIT_DIR == GIT_COMMON` (or in a submodule):** You are in a normal repo checkout.
------ 
-------```
-------No worktree directory found. Where should I create worktrees?
------+Has the user already indicated their worktree preference in your instructions? If not, ask for consent before creating a worktree:
------ 
-------1. .worktrees/ (project-local, hidden)
-------2. ~/.config/superpowers/worktrees/<project-name>/ (global location)
------+> "Would you like me to set up an isolated worktree? It protects your current branch from changes."
------ 
-------Which would you prefer?
-------```
------+Honor any existing declared preference without asking. If the user declines consent, work in place and skip to Step 3.
------+
------+## Step 1: Create Isolated Workspace
------+
------+**You have two mechanisms. Try them in this order.**
------+
------+### 1a. Native Worktree Tools (preferred)
------+
------+The user has asked for an isolated workspace (Step 0 consent). Do you already have a way to create a worktree? It might be a tool with a name like `EnterWorktree`, `WorktreeCreate`, a `/worktree` command, or a `--worktree` flag. If you do, use it and skip to Step 3.
------+
------+Native tools handle directory placement, branch creation, and cleanup automatically. Using `git worktree add` when you have a native tool creates phantom state your harness can't see or manage.
------+
------+Only proceed to Step 1b if you have no native worktree tool available.
------ 
-------## Safety Verification
------+### 1b. Git Worktree Fallback
------ 
-------### For Project-Local Directories (.worktrees or worktrees)
------+**Only use this if Step 1a does not apply** — you have no native worktree tool available. Create a worktree manually using git.
------+
------+#### Directory Selection
------+
------+Follow this priority order. Explicit user preference always beats observed filesystem state.
------+
------+1. **Check your instructions for a declared worktree directory preference.** If the user has already specified one, use it without asking.
------+
------+2. **Check for an existing project-local worktree directory:**
------+   ```bash
------+   ls -d .worktrees 2>/dev/null     # Preferred (hidden)
------+   ls -d worktrees 2>/dev/null      # Alternative
------+   ```
------+   If found, use it. If both exist, `.worktrees` wins.
------+
------+3. **Check for an existing global directory:**
------+   ```bash
------+   project=$(basename "$(git rev-parse --show-toplevel)")
------+   ls -d ~/.config/superpowers/worktrees/$project 2>/dev/null
------+   ```
------+   If found, use it (backward compatibility with legacy global path).
------+
------+4. **If there is no other guidance available**, default to `.worktrees/` at the project root.
------+
------+#### Safety Verification (project-local directories only)
------ 
------ **MUST verify directory is ignored before creating worktree:**
------ 
------ ```bash
-------# Check if directory is ignored (respects local, global, and system gitignore)
------ git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/dev/null
------ ```
------ 
-------**If NOT ignored:**
-------
-------Per Jesse's rule "Fix broken things immediately":
-------1. Add appropriate line to .gitignore
-------2. Commit the change
-------3. Proceed with worktree creation
------+**If NOT ignored:** Add to .gitignore, commit the change, then proceed.
------ 
------ **Why critical:** Prevents accidentally committing worktree contents to repository.
------ 
-------### For Global Directory (~/.config/superpowers/worktrees)
-------
-------No .gitignore verification needed - outside project entirely.
------+Global directories (`~/.config/superpowers/worktrees/`) need no verification.
------ 
-------## Creation Steps
-------
-------### 1. Detect Project Name
------+#### Create the Worktree
------ 
------ ```bash
------ project=$(basename "$(git rev-parse --show-toplevel)")
-------```
------ 
-------### 2. Create Worktree
------+# Determine path based on chosen location
------+# For project-local: path="$LOCATION/$BRANCH_NAME"
------+# For global: path="~/.config/superpowers/worktrees/$project/$BRANCH_NAME"
------ 
-------```bash
-------# Determine full path
-------case $LOCATION in
-------  .worktrees|worktrees)
-------    path="$LOCATION/$BRANCH_NAME"
-------    ;;
-------  ~/.config/superpowers/worktrees/*)
-------    path="~/.config/superpowers/worktrees/$project/$BRANCH_NAME"
-------    ;;
-------esac
-------
-------# Create worktree with new branch
------ git worktree add "$path" -b "$BRANCH_NAME"
------ cd "$path"
------ ```
------ 
-------### 3. Run Project Setup
------+**Sandbox fallback:** If `git worktree add` fails with a permission error (sandbox denial), tell the user the sandbox blocked worktree creation and you're working in the current directory instead. Then run setup and baseline tests in place.
------+
------+## Step 3: Project Setup
------ 
------ Auto-detect and run appropriate setup:
------ 
------@@ -117,23 +130,20 @@ if [ -f pyproject.toml ]; then poetry install; fi
------ if [ -f go.mod ]; then go mod download; fi
------ ```
------ 
-------### 4. Verify Clean Baseline
------+## Step 4: Verify Clean Baseline
------ 
-------Run tests to ensure worktree starts clean:
------+Run tests to ensure workspace starts clean:
------ 
------ ```bash
-------# Examples - use project-appropriate command
-------npm test
-------cargo test
-------pytest
-------go test ./...
------+# Use project-appropriate command
------+npm test / cargo test / pytest / go test ./...
------ ```
------ 
------ **If tests fail:** Report failures, ask whether to proceed or investigate.
------ 
------ **If tests pass:** Report ready.
------ 
-------### 5. Report Location
------+### Report
------ 
------ ```
------ Worktree ready at <full-path>
------@@ -145,16 +155,32 @@ Ready to implement <feature-name>
------ 
------ | Situation | Action |
------ |-----------|--------|
------+| Already in linked worktree | Skip creation (Step 0) |
------+| In a submodule | Treat as normal repo (Step 0 guard) |
------+| Native worktree tool available | Use it (Step 1a) |
------+| No native tool | Git worktree fallback (Step 1b) |
------ | `.worktrees/` exists | Use it (verify ignored) |
------ | `worktrees/` exists | Use it (verify ignored) |
------ | Both exist | Use `.worktrees/` |
-------| Neither exists | Check CLAUDE.md → Ask user |
------+| Neither exists | Check instruction file, then default `.worktrees/` |
------+| Global path exists | Use it (backward compat) |
------ | Directory not ignored | Add to .gitignore + commit |
------+| Permission error on create | Sandbox fallback, work in place |
------ | Tests fail during baseline | Report failures + ask |
------ | No package.json/Cargo.toml | Skip dependency install |
------ 
------ ## Common Mistakes
------ 
------+### Fighting the harness
------+
------+- **Problem:** Using `git worktree add` when the platform already provides isolation
------+- **Fix:** Step 0 detects existing isolation. Step 1a defers to native tools.
------+
------+### Skipping detection
------+
------+- **Problem:** Creating a nested worktree inside an existing one
------+- **Fix:** Always run Step 0 before creating anything
------+
------ ### Skipping ignore verification
------ 
------ - **Problem:** Worktree contents get tracked, pollute git status
------@@ -163,56 +189,27 @@ Ready to implement <feature-name>
------ ### Assuming directory location
------ 
------ - **Problem:** Creates inconsistency, violates project conventions
-------- **Fix:** Follow priority: existing > CLAUDE.md > ask
------+- **Fix:** Follow priority: existing > global legacy > instruction file > default
------ 
------ ### Proceeding with failing tests
------ 
------ - **Problem:** Can't distinguish new bugs from pre-existing issues
------ - **Fix:** Report failures, get explicit permission to proceed
------ 
-------### Hardcoding setup commands
-------
-------- **Problem:** Breaks on projects using different tools
-------- **Fix:** Auto-detect from project files (package.json, etc.)
-------
-------## Example Workflow
-------
-------```
-------You: I'm using the using-git-worktrees skill to set up an isolated workspace.
-------
-------[Check .worktrees/ - exists]
-------[Verify ignored - git check-ignore confirms .worktrees/ is ignored]
-------[Create worktree: git worktree add .worktrees/auth -b feature/auth]
-------[Run npm install]
-------[Run npm test - 47 passing]
-------
-------Worktree ready at /Users/jesse/myproject/.worktrees/auth
-------Tests passing (47 tests, 0 failures)
-------Ready to implement auth feature
-------```
-------
------ ## Red Flags
------ 
------ **Never:**
------+- Create a worktree when Step 0 detects existing isolation
------+- Use `git worktree add` when you have a native worktree tool (e.g., `EnterWorktree`). This is the #1 mistake — if you have it, use it.
------+- Skip Step 1a by jumping straight to Step 1b's git commands
------ - Create worktree without verifying it's ignored (project-local)
------ - Skip baseline test verification
------ - Proceed with failing tests without asking
-------- Assume directory location when ambiguous
-------- Skip CLAUDE.md check
------ 
------ **Always:**
-------- Follow directory priority: existing > CLAUDE.md > ask
------+- Run Step 0 detection first
------+- Prefer native tools over git fallback
------+- Follow directory priority: existing > global legacy > instruction file > default
------ - Verify directory is ignored for project-local
------ - Auto-detect and run project setup
------ - Verify clean test baseline
-------
-------## Integration
-------
-------**Called by:**
-------- **brainstorming** (Phase 4) - REQUIRED when design is approved and implementation follows
-------- **subagent-driven-development** - REQUIRED before executing any tasks
-------- **executing-plans** - REQUIRED before executing any tasks
-------- Any skill needing isolated workspace
-------
-------**Pairs with:**
-------- **finishing-a-development-branch** - REQUIRED for cleanup after work complete
------diff --git a/skills/superpowers/using-superpowers/references/codex-tools.md b/skills/superpowers/using-superpowers/references/codex-tools.md
------index 539b2b1..f50d40d 100644
--------- a/skills/superpowers/using-superpowers/references/codex-tools.md
------+++ b/skills/superpowers/using-superpowers/references/codex-tools.md
------@@ -4,9 +4,9 @@ Skills use Claude Code tool names. When you encounter these in a skill, use your
------ 
------ | Skill references | Codex equivalent |
------ |-----------------|------------------|
-------| `Task` tool (dispatch subagent) | `spawn_agent` (see [Named agent dispatch](#named-agent-dispatch)) |
------+| `Task` tool (dispatch subagent) | `spawn_agent` (see [Subagent dispatch requires multi-agent support](#subagent-dispatch-requires-multi-agent-support)) |
------ | Multiple `Task` calls (parallel) | Multiple `spawn_agent` calls |
-------| Task returns result | `wait` |
------+| Task returns result | `wait_agent` |
------ | Task completes automatically | `close_agent` to free slot |
------ | `TodoWrite` (task tracking) | `update_plan` |
------ | `Skill` tool (invoke a skill) | Skills load natively — just follow the instructions |
------@@ -22,53 +22,12 @@ Add to your Codex config (`~/.codex/config.toml`):
------ multi_agent = true
------ ```
------ 
-------This enables `spawn_agent`, `wait`, and `close_agent` for skills like `dispatching-parallel-agents` and `subagent-driven-development`.
------+This enables `spawn_agent`, `wait_agent`, and `close_agent` for skills like `dispatching-parallel-agents` and `subagent-driven-development`.
------ 
-------## Named agent dispatch
-------
-------Claude Code skills reference named agent types like `superpowers:code-reviewer`.
-------Codex does not have a named agent registry — `spawn_agent` creates generic agents
-------from built-in roles (`default`, `explorer`, `worker`).
-------
-------When a skill says to dispatch a named agent type:
-------
-------1. Find the agent's prompt file (e.g., `agents/code-reviewer.md` or the skill's
-------   local prompt template like `code-quality-reviewer-prompt.md`)
-------2. Read the prompt content
-------3. Fill any template placeholders (`{BASE_SHA}`, `{WHAT_WAS_IMPLEMENTED}`, etc.)
-------4. Spawn a `worker` agent with the filled content as the `message`
-------
-------| Skill instruction | Codex equivalent |
-------|-------------------|------------------|
-------| `Task tool (superpowers:code-reviewer)` | `spawn_agent(agent_type="worker", message=...)` with `code-reviewer.md` content |
-------| `Task tool (general-purpose)` with inline prompt | `spawn_agent(message=...)` with the same prompt |
-------
-------### Message framing
-------
-------The `message` parameter is user-level input, not a system prompt. Structure it
-------for maximum instruction adherence:
-------
-------```
-------Your task is to perform the following. Follow the instructions below exactly.
-------
-------<agent-instructions>
-------[filled prompt content from the agent's .md file]
-------</agent-instructions>
-------
-------Execute this now. Output ONLY the structured response following the format
-------specified in the instructions above.
-------```
-------
-------- Use task-delegation framing ("Your task is...") rather than persona framing ("You are...")
-------- Wrap instructions in XML tags — the model treats tagged blocks as authoritative
-------- End with an explicit execution directive to prevent summarization of the instructions
-------
-------### When this workaround can be removed
-------
-------This approach compensates for Codex's plugin system not yet supporting an `agents`
-------field in `plugin.json`. When `RawPluginManifest` gains an `agents` field, the
-------plugin can symlink to `agents/` (mirroring the existing `skills/` symlink) and
-------skills can dispatch named agent types directly.
------+Legacy note: Codex builds before `rust-v0.115.0` exposed spawned-agent
------+waiting as `wait`. Current Codex uses `wait_agent` for spawned agents. The
------+`wait` name now belongs to code-mode `exec/wait`, which resumes a yielded exec
------+cell by `cell_id`; it is not the spawned-agent result tool.
------ 
------ ## Environment Detection
------ 
------diff --git a/skills/superpowers/using-superpowers/references/copilot-tools.md b/skills/superpowers/using-superpowers/references/copilot-tools.md
------index 4316cdb..ae3cf5a 100644
--------- a/skills/superpowers/using-superpowers/references/copilot-tools.md
------+++ b/skills/superpowers/using-superpowers/references/copilot-tools.md
------@@ -12,23 +12,13 @@ Skills use Claude Code tool names. When you encounter these in a skill, use your
------ | `Glob` (search files by name) | `glob` |
------ | `Skill` tool (invoke a skill) | `skill` |
------ | `WebFetch` | `web_fetch` |
-------| `Task` tool (dispatch subagent) | `task` (see [Agent types](#agent-types)) |
------+| `Task` tool (dispatch subagent) | `task` with `agent_type: "general-purpose"` or `"explore"` |
------ | Multiple `Task` calls (parallel) | Multiple `task` calls |
------ | Task status/output | `read_agent`, `list_agents` |
------ | `TodoWrite` (task tracking) | `sql` with built-in `todos` table |
------ | `WebSearch` | No equivalent — use `web_fetch` with a search engine URL |
------ | `EnterPlanMode` / `ExitPlanMode` | No equivalent — stay in the main session |
------ 
-------## Agent types
-------
-------Copilot CLI's `task` tool accepts an `agent_type` parameter:
-------
-------| Claude Code agent | Copilot CLI equivalent |
-------|-------------------|----------------------|
-------| `general-purpose` | `"general-purpose"` |
-------| `Explore` | `"explore"` |
-------| Named plugin agents (e.g. `superpowers:code-reviewer`) | Discovered automatically from installed plugins |
-------
------ ## Async shell sessions
------ 
------ Copilot CLI supports persistent async shell sessions, which have no direct Claude Code equivalent:
------diff --git a/skills/superpowers/using-superpowers/references/gemini-tools.md b/skills/superpowers/using-superpowers/references/gemini-tools.md
------index f869803..91ef404 100644
--------- a/skills/superpowers/using-superpowers/references/gemini-tools.md
------+++ b/skills/superpowers/using-superpowers/references/gemini-tools.md
------@@ -14,11 +14,29 @@ Skills use Claude Code tool names. When you encounter these in a skill, use your
------ | `Skill` tool (invoke a skill) | `activate_skill` |
------ | `WebSearch` | `google_web_search` |
------ | `WebFetch` | `web_fetch` |
-------| `Task` tool (dispatch subagent) | No equivalent — Gemini CLI does not support subagents |
------+| `Task` tool (dispatch subagent) | `@agent-name` (see [Subagent support](#subagent-support)) |
------ 
-------## No subagent support
------+## Subagent support
------ 
-------Gemini CLI has no equivalent to Claude Code's `Task` tool. Skills that rely on subagent dispatch (`subagent-driven-development`, `dispatching-parallel-agents`) will fall back to single-session execution via `executing-plans`.
------+Gemini CLI supports subagents natively via the `@` syntax. Use the built-in `@generalist` agent to dispatch any task — it has access to all tools and follows the prompt you provide.
------+
------+When a skill says to dispatch a named agent type, use `@generalist` with the full prompt from the skill's prompt template:
------+
------+| Skill instruction | Gemini CLI equivalent |
------+|-------------------|----------------------|
------+| `Task tool (superpowers:implementer)` | `@generalist` with the filled `implementer-prompt.md` template |
------+| `Task tool (superpowers:spec-reviewer)` | `@generalist` with the filled `spec-reviewer-prompt.md` template |
------+| `Task tool (superpowers:code-reviewer)` | `@code-reviewer` (bundled agent) or `@generalist` with the filled review prompt |
------+| `Task tool (superpowers:code-quality-reviewer)` | `@generalist` with the filled `code-quality-reviewer-prompt.md` template |
------+| `Task tool (general-purpose)` with inline prompt | `@generalist` with your inline prompt |
------+
------+### Prompt filling
------+
------+Skills provide prompt templates with placeholders like `{WHAT_WAS_IMPLEMENTED}` or `[FULL TEXT of task]`. Fill all placeholders and pass the complete prompt as the message to `@generalist`. The prompt template itself contains the agent's role, review criteria, and expected output format — `@generalist` will follow it.
------+
------+### Parallel dispatch
------+
------+Gemini CLI supports parallel subagent dispatch. When a skill asks you to dispatch multiple independent subagent tasks in parallel, request all of those `@generalist` or named subagent tasks together in the same prompt. Keep dependent tasks sequential, but do not serialize independent subagent tasks just to preserve a simpler history.
------ 
------ ## Additional Gemini CLI tools
------ 
------diff --git a/skills/superpowers/writing-plans/SKILL.md b/skills/superpowers/writing-plans/SKILL.md
------index 0d9c00b..847412e 100644
--------- a/skills/superpowers/writing-plans/SKILL.md
------+++ b/skills/superpowers/writing-plans/SKILL.md
------@@ -13,7 +13,7 @@ Assume they are a skilled developer, but know almost nothing about our toolset o
------ 
------ **Announce at start:** "I'm using the writing-plans skill to create the implementation plan."
------ 
-------**Context:** This should be run in a dedicated worktree (created by brainstorming skill).
------+**Context:** If working in an isolated worktree, it should have been created via the `superpowers:using-git-worktrees` skill at execution time.
------ 
------ **Save plans to:** `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`
------ - (User preferences for plan location override this default)
------diff --git a/update_summary.md b/update_summary.md
------index adc2819..2ff7b8d 100644
--------- a/update_summary.md
------+++ b/update_summary.md
------@@ -1,1955 +1,1036 @@
------ ## Updated Skills
------ 
-------Submodule skills/AI-research-SKILLs 9aff750..28f2d29:
-------  > feat: add Agent-Native Research Artifact (ARA) category — 23rd, 3 skills
-------Submodule skills/scientific-agent-skills 33b69c5..37a148b:
------+Submodule skills/scientific-agent-skills 37a148b..cbcae7b:
------   > chore: update security scan report [skip ci]
-------  > Merge pull request #141 from renato-umeton/feature/autoskill
-------  > Merge pull request #145 from xiaolai/fix/nlpm-uv-uv-pip-install
-------  > Merge pull request #146 from xiaolai/fix/nlpm-latchbio-uv-install
-------  > Add support of Hugging Science
-------  > Add author
-------  > Bump version
-------  > Update Pyhealth
-------  > docs: remove community section from README
-------  > fix: disclose data transmission to api.parallel.ai and openrouter.ai in research-lookup (#149)
-------  > feat: enhance infographic generation with context image support
-------  > fix: upgrade infographic review to Gemini 3.1 Pro and harden review failure handling (#153)
-------diff --git a/update_summary.md b/update_summary.md
-------index 67c512f..98b6e19 100644
---------- a/update_summary.md
-------+++ b/update_summary.md
-------@@ -1,1933 +1,2 @@
------- ## Updated Skills
------- 
--------Submodule skills/scientific-agent-skills aaf95ee..33b69c5:
--------  > chore: update security scan report [skip ci]
--------  > chore: update security scan report [skip ci]
--------diff --git a/update_summary.md b/update_summary.md
--------index 23c8fb5..98b6e19 100644
----------- a/update_summary.md
--------+++ b/update_summary.md
--------@@ -1,1923 +1,2 @@
-------- ## Updated Skills
-------- 
---------Submodule skills/AI-research-SKILLs 05f1958..9aff750:
---------  > fix: correct welcome screen defaults and sync package-lock.json
---------  > Merge pull request #51 from RUFFY-369/feat/hermes-agent-support
---------Submodule skills/scientific-agent-skills eb20fb0..aaf95ee:
---------  > chore: update version of scientific-agent-skills to 2.37.1
---------  > docs: enhance README with installation options for Scientific Agent Skills
---------  > chore: update security scan report [skip ci]
---------  > enhance: integrate parallel-web skill for literature reviews and research lookups
---------  > refactor: update output file formats in parallel-web references to JSON
---------  > chore: update security scan report [skip ci]
---------diff --git a/update_summary.md b/update_summary.md
---------index 0ed368e..98b6e19 100644
------------ a/update_summary.md
---------+++ b/update_summary.md
---------@@ -1,1906 +1,2 @@
--------- ## Updated Skills
--------- 
----------Submodule skills/AI-research-SKILLs 22bca4d..05f1958:
----------  > Merge pull request #47 from Gitsamshi/main
----------  > Refactor ml-paper-writing: extract systems-paper-writing skill, bump to v1.5.2
----------  > Merge pull request #48 from tianhao909/tianhao909-add-mlsys-260408
----------diff --git a/update_summary.md b/update_summary.md
----------index cf32912..98b6e19 100644
------------- a/update_summary.md
----------+++ b/update_summary.md
----------@@ -1,1895 +1,2 @@
---------- ## Updated Skills
---------- 
-----------Submodule skills/AI-research-SKILLs a728954..22bca4d:
-----------  > Merge pull request #31 from dailycafi/add-ml-training-recipes
-----------  > docs: add citation guidance for researchers using the library
-----------Submodule skills/claude-scientific-skills contains modified content
-----------Submodule skills/claude-scientific-skills 71add64..899a51b:
-----------  > Simplify installation
-----------  > Remove skill that LLMs already know well and some old skills. Also updated Rowan skill.
-----------  > Merge pull request #120 from corinwagen/main
-----------  > Add optimize-for-gpu skill
-----------  > Update Adaptyv Bio skill to use new API
-----------  > Update README, examples and kills list
-----------  > Add paper-lookup skill
-----------  > Remove old literature databases
-----------  > Add combined database-lookup skill
-----------  > Update torch-geometric skill
-----------  > Remove all individual skill databases which are now part of database-lookup
-----------Submodule skills/humanizer 12881ab..8b3a178:
-----------  > Add passive voice rule to humanizer (#80)
-----------  > Integrate remaining prompt updates coherently (#79)
-----------  > feat: add OpenCode support (#47)
-----------  > Merge pull request #77 from spiritualhost/less-actually
-----------  > Merge pull request #74 from marcoenricovd-lang/fix/warp-pattern-count
-----------  > Merge pull request #64 from mvanhorn/feat/voice-calibration
-----------diff --git a/skills/superpowers/using-superpowers/SKILL.md b/skills/superpowers/using-superpowers/SKILL.md
-----------index d813535..c8a8570 100644
-------------- a/skills/superpowers/using-superpowers/SKILL.md
-----------+++ b/skills/superpowers/using-superpowers/SKILL.md
-----------@@ -29,13 +29,15 @@ If CLAUDE.md, GEMINI.md, or AGENTS.md says "don't use TDD" and a skill says "alw
----------- 
----------- **In Claude Code:** Use the `Skill` tool. When you invoke a skill, its content is loaded and presented to you—follow it directly. Never use the Read tool on skill files.
----------- 
-----------+**In Copilot CLI:** Use the `skill` tool. Skills are auto-discovered from installed plugins. The `skill` tool works the same as Claude Code's `Skill` tool.
-----------+
----------- **In Gemini CLI:** Skills activate via the `activate_skill` tool. Gemini loads skill metadata at session start and activates the full content on demand.
----------- 
----------- **In other environments:** Check your platform's documentation for how skills are loaded.
----------- 
----------- ## Platform Adaptation
----------- 
------------Skills use Claude Code tool names. Non-CC platforms: see `references/codex-tools.md` (Codex) for tool equivalents. Gemini CLI users get the tool mapping loaded automatically via GEMINI.md.
-----------+Skills use Claude Code tool names. Non-CC platforms: see `references/copilot-tools.md` (Copilot CLI), `references/codex-tools.md` (Codex) for tool equivalents. Gemini CLI users get the tool mapping loaded automatically via GEMINI.md.
----------- 
----------- # Using Skills
----------- 
-----------diff --git a/update_summary.md b/update_summary.md
-----------index 4db0e51..98b6e19 100644
-------------- a/update_summary.md
-----------+++ b/update_summary.md
-----------@@ -1,1844 +1,2 @@
----------- ## Updated Skills
----------- 
------------Submodule skills/AI-research-SKILLs 085c480..a728954:
------------  > fix: update marketplace.json to include academic-plotting skill
------------  > refactor: restructure ml-paper-writing skill into nested directory
------------  > Merge pull request #41 from Orchestra-Research/add-academic-plotting-skill
------------  > docs: add concrete OpenClaw cron.add instructions to autoresearch skill
------------  > chore: Gitignore marketing drafts and image in autoresearch skill
------------  > docs: add contributors widget and clean up contributing section
------------  > Merge pull request #39 from tang-vu/contribai/fix/security/critical-prompt-injection-in-claude-code
------------Submodule skills/claude-scientific-skills contains modified content
------------Submodule skills/claude-scientific-skills 1346c01..71add64:
------------  > Remove planning with files skill becasue it is specific to Claude Code
------------  > Make writing skills more explicit
------------  > Add Security Disclaimer section to README
------------  > Bump version
------------  > Improve token discovery for Modal
------------  > Update Modal skill
------------  > Add planning with files skill from @OthmanAdi
------------  > Add K-Dense BYOK AI co-scientist to README with features and links
------------  > Add writing skills
------------Submodule skills/humanizer d8085c7..12881ab:
------------  > Merge pull request #56 from mvanhorn/osc/42-add-hyphenation-pattern
------------  > Merge pull request #57 from mvanhorn/osc/35-remove-separator-rules
------------  > Merge pull request #58 from mvanhorn/osc/7-add-license-file
------------Submodule skills/paper-polish-workflow-skill 7e430bd..bb72126:
------------  > fix: track assets/logo.jpg so README logo displays on GitHub
------------  > fix: correct SKILL.md path in CI validation workflow
------------  > fix: remove package.json to prevent recursive npm nesting
------------  > fix: remove duplicate files to fix ENAMETOOLONG on plugin install
------------  > fix: add explicit skills path in plugin.json
------------  > fix: update plugin.json version to 2.3.0
------------  > fix: remove .planning/ from git tracking (136 files)
------------  > fix: use HTTPS git URL instead of GitHub SSH source
------------  > fix: switch marketplace source from npm to GitHub repo
------------  > fix: add explicit npmjs.com registry to marketplace.json
------------  > feat: migrate to official Claude Code plugin marketplace, bump v2.3.0
------------  > feat: add Claude Code plugin format with auto-install postinstall script
------------  > feat: add get-paper skill, bump to v2.2.0
------------diff --git a/skills/superpowers/brainstorming/SKILL.md b/skills/superpowers/brainstorming/SKILL.md
------------index edbc2b5..06cd0a2 100644
--------------- a/skills/superpowers/brainstorming/SKILL.md
------------+++ b/skills/superpowers/brainstorming/SKILL.md
------------@@ -27,7 +27,7 @@ You MUST create a task for each of these items and complete them in order:
------------ 4. **Propose 2-3 approaches** — with trade-offs and your recommendation
------------ 5. **Present design** — in sections scaled to their complexity, get user approval after each section
------------ 6. **Write design doc** — save to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` and commit
-------------7. **Spec review loop** — dispatch spec-document-reviewer subagent with precisely crafted review context (never your session history); fix issues and re-dispatch until approved (max 3 iterations, then surface to human)
------------+7. **Spec self-review** — quick inline check for placeholders, contradictions, ambiguity, scope (see below)
------------ 8. **User reviews written spec** — ask user to review the spec file before proceeding
------------ 9. **Transition to implementation** — invoke writing-plans skill to create implementation plan
------------ 
------------@@ -43,8 +43,7 @@ digraph brainstorming {
------------     "Present design sections" [shape=box];
------------     "User approves design?" [shape=diamond];
------------     "Write design doc" [shape=box];
-------------    "Spec review loop" [shape=box];
-------------    "Spec review passed?" [shape=diamond];
------------+    "Spec self-review\n(fix inline)" [shape=box];
------------     "User reviews spec?" [shape=diamond];
------------     "Invoke writing-plans skill" [shape=doublecircle];
------------ 
------------@@ -57,10 +56,8 @@ digraph brainstorming {
------------     "Present design sections" -> "User approves design?";
------------     "User approves design?" -> "Present design sections" [label="no, revise"];
------------     "User approves design?" -> "Write design doc" [label="yes"];
-------------    "Write design doc" -> "Spec review loop";
-------------    "Spec review loop" -> "Spec review passed?";
-------------    "Spec review passed?" -> "Spec review loop" [label="issues found,\nfix and re-dispatch"];
-------------    "Spec review passed?" -> "User reviews spec?" [label="approved"];
------------+    "Write design doc" -> "Spec self-review\n(fix inline)";
------------+    "Spec self-review\n(fix inline)" -> "User reviews spec?";
------------     "User reviews spec?" -> "Write design doc" [label="changes requested"];
------------     "User reviews spec?" -> "Invoke writing-plans skill" [label="approved"];
------------ }
------------@@ -116,12 +113,15 @@ digraph brainstorming {
------------ - Use elements-of-style:writing-clearly-and-concisely skill if available
------------ - Commit the design document to git
------------ 
-------------**Spec Review Loop:**
-------------After writing the spec document:
------------+**Spec Self-Review:**
------------+After writing the spec document, look at it with fresh eyes:
------------ 
-------------1. Dispatch spec-document-reviewer subagent (see spec-document-reviewer-prompt.md)
-------------2. If Issues Found: fix, re-dispatch, repeat until Approved
-------------3. If loop exceeds 3 iterations, surface to human for guidance
------------+1. **Placeholder scan:** Any "TBD", "TODO", incomplete sections, or vague requirements? Fix them.
------------+2. **Internal consistency:** Do any sections contradict each other? Does the architecture match the feature descriptions?
------------+3. **Scope check:** Is this focused enough for a single implementation plan, or does it need decomposition?
------------+4. **Ambiguity check:** Could any requirement be interpreted two different ways? If so, pick one and make it explicit.
------------+
------------+Fix any issues inline. No need to re-review — just fix and move on.
------------ 
------------ **User Review Gate:**
------------ After the spec review loop passes, ask the user to review the written spec before proceeding:
------------diff --git a/skills/superpowers/brainstorming/scripts/server.cjs b/skills/superpowers/brainstorming/scripts/server.cjs
------------index 86c3080..562c17f 100644
--------------- a/skills/superpowers/brainstorming/scripts/server.cjs
------------+++ b/skills/superpowers/brainstorming/scripts/server.cjs
------------@@ -76,8 +76,10 @@ function decodeFrame(buffer) {
------------ const PORT = process.env.BRAINSTORM_PORT || (49152 + Math.floor(Math.random() * 16383));
------------ const HOST = process.env.BRAINSTORM_HOST || '127.0.0.1';
------------ const URL_HOST = process.env.BRAINSTORM_URL_HOST || (HOST === '127.0.0.1' ? 'localhost' : HOST);
-------------const SCREEN_DIR = process.env.BRAINSTORM_DIR || '/tmp/brainstorm';
-------------const OWNER_PID = process.env.BRAINSTORM_OWNER_PID ? Number(process.env.BRAINSTORM_OWNER_PID) : null;
------------+const SESSION_DIR = process.env.BRAINSTORM_DIR || '/tmp/brainstorm';
------------+const CONTENT_DIR = path.join(SESSION_DIR, 'content');
------------+const STATE_DIR = path.join(SESSION_DIR, 'state');
------------+let ownerPid = process.env.BRAINSTORM_OWNER_PID ? Number(process.env.BRAINSTORM_OWNER_PID) : null;
------------ 
------------ const MIME_TYPES = {
------------   '.html': 'text/html', '.css': 'text/css', '.js': 'application/javascript',
------------@@ -112,10 +114,10 @@ function wrapInFrame(content) {
------------ }
------------ 
------------ function getNewestScreen() {
-------------  const files = fs.readdirSync(SCREEN_DIR)
------------+  const files = fs.readdirSync(CONTENT_DIR)
------------     .filter(f => f.endsWith('.html'))
------------     .map(f => {
-------------      const fp = path.join(SCREEN_DIR, f);
------------+      const fp = path.join(CONTENT_DIR, f);
------------       return { path: fp, mtime: fs.statSync(fp).mtime.getTime() };
------------     })
------------     .sort((a, b) => b.mtime - a.mtime);
------------@@ -142,7 +144,7 @@ function handleRequest(req, res) {
------------     res.end(html);
------------   } else if (req.method === 'GET' && req.url.startsWith('/files/')) {
------------     const fileName = req.url.slice(7);
-------------    const filePath = path.join(SCREEN_DIR, path.basename(fileName));
------------+    const filePath = path.join(CONTENT_DIR, path.basename(fileName));
------------     if (!fs.existsSync(filePath)) {
------------       res.writeHead(404);
------------       res.end('Not found');
------------@@ -230,7 +232,7 @@ function handleMessage(text) {
------------   touchActivity();
------------   console.log(JSON.stringify({ source: 'user-event', ...event }));
------------   if (event.choice) {
-------------    const eventsFile = path.join(SCREEN_DIR, '.events');
------------+    const eventsFile = path.join(STATE_DIR, 'events');
------------     fs.appendFileSync(eventsFile, JSON.stringify(event) + '\n');
------------   }
------------ }
------------@@ -258,32 +260,33 @@ const debounceTimers = new Map();
------------ // ========== Server Startup ==========
------------ 
------------ function startServer() {
-------------  if (!fs.existsSync(SCREEN_DIR)) fs.mkdirSync(SCREEN_DIR, { recursive: true });
------------+  if (!fs.existsSync(CONTENT_DIR)) fs.mkdirSync(CONTENT_DIR, { recursive: true });
------------+  if (!fs.existsSync(STATE_DIR)) fs.mkdirSync(STATE_DIR, { recursive: true });
------------ 
------------   // Track known files to distinguish new screens from updates.
------------   // macOS fs.watch reports 'rename' for both new files and overwrites,
------------   // so we can't rely on eventType alone.
------------   const knownFiles = new Set(
-------------    fs.readdirSync(SCREEN_DIR).filter(f => f.endsWith('.html'))
------------+    fs.readdirSync(CONTENT_DIR).filter(f => f.endsWith('.html'))
------------   );
------------ 
------------   const server = http.createServer(handleRequest);
------------   server.on('upgrade', handleUpgrade);
------------ 
-------------  const watcher = fs.watch(SCREEN_DIR, (eventType, filename) => {
------------+  const watcher = fs.watch(CONTENT_DIR, (eventType, filename) => {
------------     if (!filename || !filename.endsWith('.html')) return;
------------ 
------------     if (debounceTimers.has(filename)) clearTimeout(debounceTimers.get(filename));
------------     debounceTimers.set(filename, setTimeout(() => {
------------       debounceTimers.delete(filename);
-------------      const filePath = path.join(SCREEN_DIR, filename);
------------+      const filePath = path.join(CONTENT_DIR, filename);
------------ 
------------       if (!fs.existsSync(filePath)) return; // file was deleted
------------       touchActivity();
------------ 
------------       if (!knownFiles.has(filename)) {
------------         knownFiles.add(filename);
-------------        const eventsFile = path.join(SCREEN_DIR, '.events');
------------+        const eventsFile = path.join(STATE_DIR, 'events');
------------         if (fs.existsSync(eventsFile)) fs.unlinkSync(eventsFile);
------------         console.log(JSON.stringify({ type: 'screen-added', file: filePath }));
------------       } else {
------------@@ -297,10 +300,10 @@ function startServer() {
------------ 
------------   function shutdown(reason) {
------------     console.log(JSON.stringify({ type: 'server-stopped', reason }));
-------------    const infoFile = path.join(SCREEN_DIR, '.server-info');
------------+    const infoFile = path.join(STATE_DIR, 'server-info');
------------     if (fs.existsSync(infoFile)) fs.unlinkSync(infoFile);
------------     fs.writeFileSync(
-------------      path.join(SCREEN_DIR, '.server-stopped'),
------------+      path.join(STATE_DIR, 'server-stopped'),
------------       JSON.stringify({ reason, timestamp: Date.now() }) + '\n'
------------     );
------------     watcher.close();
------------@@ -309,8 +312,8 @@ function startServer() {
------------   }
------------ 
------------   function ownerAlive() {
-------------    if (!OWNER_PID) return true;
-------------    try { process.kill(OWNER_PID, 0); return true; } catch (e) { return false; }
------------+    if (!ownerPid) return true;
------------+    try { process.kill(ownerPid, 0); return true; } catch (e) { return e.code === 'EPERM'; }
------------   }
------------ 
------------   // Check every 60s: exit if owner process died or idle for 30 minutes
------------@@ -320,14 +323,27 @@ function startServer() {
------------   }, 60 * 1000);
------------   lifecycleCheck.unref();
------------ 
------------+  // Validate owner PID at startup. If it's already dead, the PID resolution
------------+  // was wrong (common on WSL, Tailscale SSH, and cross-user scenarios).
------------+  // Disable monitoring and rely on the idle timeout instead.
------------+  if (ownerPid) {
------------+    try { process.kill(ownerPid, 0); }
------------+    catch (e) {
------------+      if (e.code !== 'EPERM') {
------------+        console.log(JSON.stringify({ type: 'owner-pid-invalid', pid: ownerPid, reason: 'dead at startup' }));
------------+        ownerPid = null;
------------+      }
------------+    }
------------+  }
------------+
------------   server.listen(PORT, HOST, () => {
------------     const info = JSON.stringify({
------------       type: 'server-started', port: Number(PORT), host: HOST,
------------       url_host: URL_HOST, url: 'http://' + URL_HOST + ':' + PORT,
-------------      screen_dir: SCREEN_DIR
------------+      screen_dir: CONTENT_DIR, state_dir: STATE_DIR
------------     });
------------     console.log(info);
-------------    fs.writeFileSync(path.join(SCREEN_DIR, '.server-info'), info + '\n');
------------+    fs.writeFileSync(path.join(STATE_DIR, 'server-info'), info + '\n');
------------   });
------------ }
------------ 
------------diff --git a/skills/superpowers/brainstorming/scripts/start-server.sh b/skills/superpowers/brainstorming/scripts/start-server.sh
------------index a0ef299..9ef6dcb 100755
--------------- a/skills/superpowers/brainstorming/scripts/start-server.sh
------------+++ b/skills/superpowers/brainstorming/scripts/start-server.sh
------------@@ -78,16 +78,17 @@ fi
------------ SESSION_ID="$$-$(date +%s)"
------------ 
------------ if [[ -n "$PROJECT_DIR" ]]; then
-------------  SCREEN_DIR="${PROJECT_DIR}/.superpowers/brainstorm/${SESSION_ID}"
------------+  SESSION_DIR="${PROJECT_DIR}/.superpowers/brainstorm/${SESSION_ID}"
------------ else
-------------  SCREEN_DIR="/tmp/brainstorm-${SESSION_ID}"
------------+  SESSION_DIR="/tmp/brainstorm-${SESSION_ID}"
------------ fi
------------ 
-------------PID_FILE="${SCREEN_DIR}/.server.pid"
-------------LOG_FILE="${SCREEN_DIR}/.server.log"
------------+STATE_DIR="${SESSION_DIR}/state"
------------+PID_FILE="${STATE_DIR}/server.pid"
------------+LOG_FILE="${STATE_DIR}/server.log"
------------ 
-------------# Create fresh session directory
-------------mkdir -p "$SCREEN_DIR"
------------+# Create fresh session directory with content and state peers
------------+mkdir -p "${SESSION_DIR}/content" "$STATE_DIR"
------------ 
------------ # Kill any existing server
------------ if [[ -f "$PID_FILE" ]]; then
------------@@ -106,22 +107,16 @@ if [[ -z "$OWNER_PID" || "$OWNER_PID" == "1" ]]; then
------------   OWNER_PID="$PPID"
------------ fi
------------ 
-------------# On Windows/MSYS2, the MSYS2 PID namespace is invisible to Node.js.
-------------# Skip owner-PID monitoring — the 30-minute idle timeout prevents orphans.
-------------case "${OSTYPE:-}" in
-------------  msys*|cygwin*|mingw*) OWNER_PID="" ;;
-------------esac
-------------
------------ # Foreground mode for environments that reap detached/background processes.
------------ if [[ "$FOREGROUND" == "true" ]]; then
------------   echo "$$" > "$PID_FILE"
-------------  env BRAINSTORM_DIR="$SCREEN_DIR" BRAINSTORM_HOST="$BIND_HOST" BRAINSTORM_URL_HOST="$URL_HOST" BRAINSTORM_OWNER_PID="$OWNER_PID" node server.cjs
------------+  env BRAINSTORM_DIR="$SESSION_DIR" BRAINSTORM_HOST="$BIND_HOST" BRAINSTORM_URL_HOST="$URL_HOST" BRAINSTORM_OWNER_PID="$OWNER_PID" node server.cjs
------------   exit $?
------------ fi
------------ 
------------ # Start server, capturing output to log file
------------ # Use nohup to survive shell exit; disown to remove from job table
-------------nohup env BRAINSTORM_DIR="$SCREEN_DIR" BRAINSTORM_HOST="$BIND_HOST" BRAINSTORM_URL_HOST="$URL_HOST" BRAINSTORM_OWNER_PID="$OWNER_PID" node server.cjs > "$LOG_FILE" 2>&1 &
------------+nohup env BRAINSTORM_DIR="$SESSION_DIR" BRAINSTORM_HOST="$BIND_HOST" BRAINSTORM_URL_HOST="$URL_HOST" BRAINSTORM_OWNER_PID="$OWNER_PID" node server.cjs > "$LOG_FILE" 2>&1 &
------------ SERVER_PID=$!
------------ disown "$SERVER_PID" 2>/dev/null
------------ echo "$SERVER_PID" > "$PID_FILE"
------------diff --git a/skills/superpowers/brainstorming/scripts/stop-server.sh b/skills/superpowers/brainstorming/scripts/stop-server.sh
------------index 2e5973d..a6b94e6 100755
--------------- a/skills/superpowers/brainstorming/scripts/stop-server.sh
------------+++ b/skills/superpowers/brainstorming/scripts/stop-server.sh
------------@@ -1,19 +1,20 @@
------------ #!/usr/bin/env bash
------------ # Stop the brainstorm server and clean up
-------------# Usage: stop-server.sh <screen_dir>
------------+# Usage: stop-server.sh <session_dir>
------------ #
------------ # Kills the server process. Only deletes session directory if it's
------------ # under /tmp (ephemeral). Persistent directories (.superpowers/) are
------------ # kept so mockups can be reviewed later.
------------ 
-------------SCREEN_DIR="$1"
------------+SESSION_DIR="$1"
------------ 
-------------if [[ -z "$SCREEN_DIR" ]]; then
-------------  echo '{"error": "Usage: stop-server.sh <screen_dir>"}'
------------+if [[ -z "$SESSION_DIR" ]]; then
------------+  echo '{"error": "Usage: stop-server.sh <session_dir>"}'
------------   exit 1
------------ fi
------------ 
-------------PID_FILE="${SCREEN_DIR}/.server.pid"
------------+STATE_DIR="${SESSION_DIR}/state"
------------+PID_FILE="${STATE_DIR}/server.pid"
------------ 
------------ if [[ -f "$PID_FILE" ]]; then
------------   pid=$(cat "$PID_FILE")
------------@@ -42,11 +43,11 @@ if [[ -f "$PID_FILE" ]]; then
------------     exit 1
------------   fi
------------ 
-------------  rm -f "$PID_FILE" "${SCREEN_DIR}/.server.log"
------------+  rm -f "$PID_FILE" "${STATE_DIR}/server.log"
------------ 
------------   # Only delete ephemeral /tmp directories
-------------  if [[ "$SCREEN_DIR" == /tmp/* ]]; then
-------------    rm -rf "$SCREEN_DIR"
------------+  if [[ "$SESSION_DIR" == /tmp/* ]]; then
------------+    rm -rf "$SESSION_DIR"
------------   fi
------------ 
------------   echo '{"status": "stopped"}'
------------diff --git a/skills/superpowers/brainstorming/visual-companion.md b/skills/superpowers/brainstorming/visual-companion.md
------------index 537ed3c..2113863 100644
--------------- a/skills/superpowers/brainstorming/visual-companion.md
------------+++ b/skills/superpowers/brainstorming/visual-companion.md
------------@@ -26,7 +26,7 @@ A question *about* a UI topic is not automatically a visual question. "What kind
------------ 
------------ ## How It Works
------------ 
-------------The server watches a directory for HTML files and serves the newest one to the browser. You write HTML content, the user sees it in their browser and can click to select options. Selections are recorded to a `.events` file that you read on your next turn.
------------+The server watches a directory for HTML files and serves the newest one to the browser. You write HTML content to `screen_dir`, the user sees it in their browser and can click to select options. Selections are recorded to `state_dir/events` that you read on your next turn.
------------ 
------------ **Content fragments vs full documents:** If your HTML file starts with `<!DOCTYPE` or `<html`, the server serves it as-is (just injects the helper script). Otherwise, the server automatically wraps your content in the frame template — adding the header, CSS theme, selection indicator, and all interactive infrastructure. **Write content fragments by default.** Only write full documents when you need complete control over the page.
------------ 
------------@@ -37,12 +37,13 @@ The server watches a directory for HTML files and serves the newest one to the b
------------ scripts/start-server.sh --project-dir /path/to/project
------------ 
------------ # Returns: {"type":"server-started","port":52341,"url":"http://localhost:52341",
-------------#           "screen_dir":"/path/to/project/.superpowers/brainstorm/12345-1706000000"}
------------+#           "screen_dir":"/path/to/project/.superpowers/brainstorm/12345-1706000000/content",
------------+#           "state_dir":"/path/to/project/.superpowers/brainstorm/12345-1706000000/state"}
------------ ```
------------ 
-------------Save `screen_dir` from the response. Tell user to open the URL.
------------+Save `screen_dir` and `state_dir` from the response. Tell user to open the URL.
------------ 
-------------**Finding connection info:** The server writes its startup JSON to `$SCREEN_DIR/.server-info`. If you launched the server in the background and didn't capture stdout, read that file to get the URL and port. When using `--project-dir`, check `<project>/.superpowers/brainstorm/` for the session directory.
------------+**Finding connection info:** The server writes its startup JSON to `$STATE_DIR/server-info`. If you launched the server in the background and didn't capture stdout, read that file to get the URL and port. When using `--project-dir`, check `<project>/.superpowers/brainstorm/` for the session directory.
------------ 
------------ **Note:** Pass the project root as `--project-dir` so mockups persist in `.superpowers/brainstorm/` and survive server restarts. Without it, files go to `/tmp` and get cleaned up. Remind the user to add `.superpowers/` to `.gitignore` if it's not already there.
------------ 
------------@@ -61,7 +62,7 @@ scripts/start-server.sh --project-dir /path/to/project
------------ # across conversation turns.
------------ scripts/start-server.sh --project-dir /path/to/project
------------ ```
-------------When calling this via the Bash tool, set `run_in_background: true`. Then read `$SCREEN_DIR/.server-info` on the next turn to get the URL and port.
------------+When calling this via the Bash tool, set `run_in_background: true`. Then read `$STATE_DIR/server-info` on the next turn to get the URL and port.
------------ 
------------ **Codex:**
------------ ```bash
------------@@ -93,7 +94,7 @@ Use `--url-host` to control what hostname is printed in the returned URL JSON.
------------ ## The Loop
------------ 
------------ 1. **Check server is alive**, then **write HTML** to a new file in `screen_dir`:
-------------   - Before each write, check that `$SCREEN_DIR/.server-info` exists. If it doesn't (or `.server-stopped` exists), the server has shut down — restart it with `start-server.sh` before continuing. The server auto-exits after 30 minutes of inactivity.
------------+   - Before each write, check that `$STATE_DIR/server-info` exists. If it doesn't (or `$STATE_DIR/server-stopped` exists), the server has shut down — restart it with `start-server.sh` before continuing. The server auto-exits after 30 minutes of inactivity.
------------    - Use semantic filenames: `platform.html`, `visual-style.html`, `layout.html`
------------    - **Never reuse filenames** — each screen gets a fresh file
------------    - Use Write tool — **never use cat/heredoc** (dumps noise into terminal)
------------@@ -105,9 +106,9 @@ Use `--url-host` to control what hostname is printed in the returned URL JSON.
------------    - Ask them to respond in the terminal: "Take a look and let me know what you think. Click to select an option if you'd like."
------------ 
------------ 3. **On your next turn** — after the user responds in the terminal:
-------------   - Read `$SCREEN_DIR/.events` if it exists — this contains the user's browser interactions (clicks, selections) as JSON lines
------------+   - Read `$STATE_DIR/events` if it exists — this contains the user's browser interactions (clicks, selections) as JSON lines
------------    - Merge with the user's terminal text to get the full picture
-------------   - The terminal message is the primary feedback; `.events` provides structured interaction data
------------+   - The terminal message is the primary feedback; `state_dir/events` provides structured interaction data
------------ 
------------ 4. **Iterate or advance** — if feedback changes current screen, write a new file (e.g., `layout-v2.html`). Only move to the next question when the current step is validated.
------------ 
------------@@ -244,7 +245,7 @@ The frame template provides these CSS classes for your content:
------------ 
------------ ## Browser Events Format
------------ 
-------------When the user clicks options in the browser, their interactions are recorded to `$SCREEN_DIR/.events` (one JSON object per line). The file is cleared automatically when you push a new screen.
------------+When the user clicks options in the browser, their interactions are recorded to `$STATE_DIR/events` (one JSON object per line). The file is cleared automatically when you push a new screen.
------------ 
------------ ```jsonl
------------ {"type":"click","choice":"a","text":"Option A - Simple Layout","timestamp":1706000101}
------------@@ -254,7 +255,7 @@ When the user clicks options in the browser, their interactions are recorded to
------------ 
------------ The full event stream shows the user's exploration path — they may click multiple options before settling. The last `choice` event is typically the final selection, but the pattern of clicks can reveal hesitation or preferences worth asking about.
------------ 
-------------If `.events` doesn't exist, the user didn't interact with the browser — use only their terminal text.
------------+If `$STATE_DIR/events` doesn't exist, the user didn't interact with the browser — use only their terminal text.
------------ 
------------ ## Design Tips
------------ 
------------@@ -275,7 +276,7 @@ If `.events` doesn't exist, the user didn't interact with the browser — use on
------------ ## Cleaning Up
------------ 
------------ ```bash
-------------scripts/stop-server.sh $SCREEN_DIR
------------+scripts/stop-server.sh $SESSION_DIR
------------ ```
------------ 
------------ If the session used `--project-dir`, mockup files persist in `.superpowers/brainstorm/` for later reference. Only `/tmp` sessions get deleted on stop.
------------diff --git a/skills/superpowers/using-superpowers/references/codex-tools.md b/skills/superpowers/using-superpowers/references/codex-tools.md
------------index 86f58fa..539b2b1 100644
--------------- a/skills/superpowers/using-superpowers/references/codex-tools.md
------------+++ b/skills/superpowers/using-superpowers/references/codex-tools.md
------------@@ -4,7 +4,7 @@ Skills use Claude Code tool names. When you encounter these in a skill, use your
------------ 
------------ | Skill references | Codex equivalent |
------------ |-----------------|------------------|
-------------| `Task` tool (dispatch subagent) | `spawn_agent` |
------------+| `Task` tool (dispatch subagent) | `spawn_agent` (see [Named agent dispatch](#named-agent-dispatch)) |
------------ | Multiple `Task` calls (parallel) | Multiple `spawn_agent` calls |
------------ | Task returns result | `wait` |
------------ | Task completes automatically | `close_agent` to free slot |
------------@@ -23,3 +23,78 @@ multi_agent = true
------------ ```
------------ 
------------ This enables `spawn_agent`, `wait`, and `close_agent` for skills like `dispatching-parallel-agents` and `subagent-driven-development`.
------------+
------------+## Named agent dispatch
------------+
------------+Claude Code skills reference named agent types like `superpowers:code-reviewer`.
------------+Codex does not have a named agent registry — `spawn_agent` creates generic agents
------------+from built-in roles (`default`, `explorer`, `worker`).
------------+
------------+When a skill says to dispatch a named agent type:
------------+
------------+1. Find the agent's prompt file (e.g., `agents/code-reviewer.md` or the skill's
------------+   local prompt template like `code-quality-reviewer-prompt.md`)
------------+2. Read the prompt content
------------+3. Fill any template placeholders (`{BASE_SHA}`, `{WHAT_WAS_IMPLEMENTED}`, etc.)
------------+4. Spawn a `worker` agent with the filled content as the `message`
------------+
------------+| Skill instruction | Codex equivalent |
------------+|-------------------|------------------|
------------+| `Task tool (superpowers:code-reviewer)` | `spawn_agent(agent_type="worker", message=...)` with `code-reviewer.md` content |
------------+| `Task tool (general-purpose)` with inline prompt | `spawn_agent(message=...)` with the same prompt |
------------+
------------+### Message framing
------------+
------------+The `message` parameter is user-level input, not a system prompt. Structure it
------------+for maximum instruction adherence:
------------+
------------+```
------------+Your task is to perform the following. Follow the instructions below exactly.
------------+
------------+<agent-instructions>
------------+[filled prompt content from the agent's .md file]
------------+</agent-instructions>
------------+
------------+Execute this now. Output ONLY the structured response following the format
------------+specified in the instructions above.
------------+```
------------+
------------+- Use task-delegation framing ("Your task is...") rather than persona framing ("You are...")
------------+- Wrap instructions in XML tags — the model treats tagged blocks as authoritative
------------+- End with an explicit execution directive to prevent summarization of the instructions
------------+
------------+### When this workaround can be removed
------------+
------------+This approach compensates for Codex's plugin system not yet supporting an `agents`
------------+field in `plugin.json`. When `RawPluginManifest` gains an `agents` field, the
------------+plugin can symlink to `agents/` (mirroring the existing `skills/` symlink) and
------------+skills can dispatch named agent types directly.
------------+
------------+## Environment Detection
------------+
------------+Skills that create worktrees or finish branches should detect their
------------+environment with read-only git commands before proceeding:
------------+
------------+```bash
------------+GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
------------+GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
------------+BRANCH=$(git branch --show-current)
------------+```
------------+
------------+- `GIT_DIR != GIT_COMMON` → already in a linked worktree (skip creation)
------------+- `BRANCH` empty → detached HEAD (cannot branch/push/PR from sandbox)
------------+
------------+See `using-git-worktrees` Step 0 and `finishing-a-development-branch`
------------+Step 1 for how each skill uses these signals.
------------+
------------+## Codex App Finishing
------------+
------------+When the sandbox blocks branch/push operations (detached HEAD in an
------------+externally managed worktree), the agent commits all work and informs
------------+the user to use the App's native controls:
------------+
------------+- **"Create branch"** — names the branch, then commit/push/PR via App UI
------------+- **"Hand off to local"** — transfers work to the user's local checkout
------------+
------------+The agent can still run tests, stage files, and output suggested branch
------------+names, commit messages, and PR descriptions for the user to copy.
------------diff --git a/skills/superpowers/writing-plans/SKILL.md b/skills/superpowers/writing-plans/SKILL.md
------------index 60f9834..0d9c00b 100644
--------------- a/skills/superpowers/writing-plans/SKILL.md
------------+++ b/skills/superpowers/writing-plans/SKILL.md
------------@@ -103,26 +103,33 @@ git commit -m "feat: add specific feature"
------------ ```
------------ ````
------------ 
------------+## No Placeholders
------------+
------------+Every step must contain the actual content an engineer needs. These are **plan failures** — never write them:
------------+- "TBD", "TODO", "implement later", "fill in details"
------------+- "Add appropriate error handling" / "add validation" / "handle edge cases"
------------+- "Write tests for the above" (without actual test code)
------------+- "Similar to Task N" (repeat the code — the engineer may be reading tasks out of order)
------------+- Steps that describe what to do without showing how (code blocks required for code steps)
------------+- References to types, functions, or methods not defined in any task
------------+
------------ ## Remember
------------ - Exact file paths always
-------------- Complete code in plan (not "add validation")
------------+- Complete code in every step — if a step changes code, show the code
------------ - Exact commands with expected output
-------------- Reference relevant skills with @ syntax
------------ - DRY, YAGNI, TDD, frequent commits
------------ 
-------------## Plan Review Loop
------------+## Self-Review
------------+
------------+After writing the complete plan, look at the spec with fresh eyes and check the plan against it. This is a checklist you run yourself — not a subagent dispatch.
------------+
------------+**1. Spec coverage:** Skim each section/requirement in the spec. Can you point to a task that implements it? List any gaps.
------------ 
-------------After writing the complete plan:
------------+**2. Placeholder scan:** Search your plan for red flags — any of the patterns from the "No Placeholders" section above. Fix them.
------------ 
-------------1. Dispatch a single plan-document-reviewer subagent (see plan-document-reviewer-prompt.md) with precisely crafted review context — never your session history. This keeps the reviewer focused on the plan, not your thought process.
-------------   - Provide: path to the plan document, path to spec document
-------------2. If ❌ Issues Found: fix the issues, re-dispatch reviewer for the whole plan
-------------3. If ✅ Approved: proceed to execution handoff
------------+**3. Type consistency:** Do the types, method signatures, and property names you used in later tasks match what you defined in earlier tasks? A function called `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug.
------------ 
-------------**Review loop guidance:**
-------------- Same agent that wrote the plan fixes it (preserves context)
-------------- If loop exceeds 3 iterations, surface to human for guidance
-------------- Reviewers are advisory — explain disagreements if you believe feedback is incorrect
------------+If you find issues, fix them inline. No need to re-review — just fix and move on. If you find a spec requirement with no task, add the task.
------------ 
------------ ## Execution Handoff
------------ 
------------diff --git a/skills/superpowers/writing-skills/SKILL.md b/skills/superpowers/writing-skills/SKILL.md
------------index 4cd8ddf..c3b73d8 100644
--------------- a/skills/superpowers/writing-skills/SKILL.md
------------+++ b/skills/superpowers/writing-skills/SKILL.md
------------@@ -93,7 +93,7 @@ skills/
------------ ## SKILL.md Structure
------------ 
------------ **Frontmatter (YAML):**
-------------- Only two fields supported: `name` and `description`
------------+- Two required fields: `name` and `description` (see [agentskills.io/specification](https://agentskills.io/specification) for all supported fields)
------------ - Max 1024 characters total
------------ - `name`: Use letters, numbers, and hyphens only (no parentheses, special chars)
------------ - `description`: Third-person, describes ONLY when to use (NOT what it does)
------------@@ -604,7 +604,7 @@ Deploying untested skills = deploying untested code. It's a violation of quality
------------ 
------------ **GREEN Phase - Write Minimal Skill:**
------------ - [ ] Name uses only letters, numbers, hyphens (no parentheses/special chars)
-------------- [ ] YAML frontmatter with only name and description (max 1024 chars)
------------+- [ ] YAML frontmatter with required `name` and `description` fields (max 1024 chars; see [spec](https://agentskills.io/specification))
------------ - [ ] Description starts with "Use when..." and includes specific triggers/symptoms
------------ - [ ] Description written in third person
------------ - [ ] Keywords throughout for search (errors, symptoms, tools)
------------diff --git a/skills/superpowers/writing-skills/anthropic-best-practices.md b/skills/superpowers/writing-skills/anthropic-best-practices.md
------------index a5a7d07..9f3f6ec 100644
--------------- a/skills/superpowers/writing-skills/anthropic-best-practices.md
------------+++ b/skills/superpowers/writing-skills/anthropic-best-practices.md
------------@@ -144,7 +144,7 @@ What works perfectly for Opus might need more detail for Haiku. If you plan to u
------------ ## Skill structure
------------ 
------------ <Note>
-------------  **YAML Frontmatter**: The SKILL.md frontmatter supports two fields:
------------+  **YAML Frontmatter**: The SKILL.md frontmatter requires two fields:
------------ 
------------   * `name` - Human-readable name of the Skill (64 characters maximum)
------------   * `description` - One-line description of what the Skill does and when to use it (1024 characters maximum)
------------@@ -1092,7 +1092,7 @@ reader = PdfReader("file.pdf")
------------ 
------------ ### YAML frontmatter requirements
------------ 
-------------The SKILL.md frontmatter includes only `name` (64 characters max) and `description` (1024 characters max) fields. See the [Skills overview](/en/docs/agents-and-tools/agent-skills/overview#skill-structure) for complete structure details.
------------+The SKILL.md frontmatter requires `name` (64 characters max) and `description` (1024 characters max) fields. See the [Skills overview](/en/docs/agents-and-tools/agent-skills/overview#skill-structure) for complete structure details.
------------ 
------------ ### Token budgets
------------ 
------------diff --git a/update_summary.md b/update_summary.md
------------index 358a7c2..b58cd81 100644
--------------- a/update_summary.md
------------+++ b/update_summary.md
------------@@ -1,781 +1,555 @@
------------ ## Updated Skills
------------ 
-------------Submodule skills/AI-research-SKILLs 085c480..28d8b96:
------------+Submodule skills/AI-research-SKILLs 085c480..a728954:
------------+  > fix: update marketplace.json to include academic-plotting skill
------------+  > refactor: restructure ml-paper-writing skill into nested directory
------------+  > Merge pull request #41 from Orchestra-Research/add-academic-plotting-skill
------------+  > docs: add concrete OpenClaw cron.add instructions to autoresearch skill
------------+  > chore: Gitignore marketing drafts and image in autoresearch skill
------------   > docs: add contributors widget and clean up contributing section
------------   > Merge pull request #39 from tang-vu/contribai/fix/security/critical-prompt-injection-in-claude-code
------------ Submodule skills/claude-scientific-skills contains modified content
-------------Submodule skills/claude-scientific-skills 1346c01..1531326:
------------+Submodule skills/claude-scientific-skills 1346c01..71add64:
------------+  > Remove planning with files skill becasue it is specific to Claude Code
------------+  > Make writing skills more explicit
------------+  > Add Security Disclaimer section to README
------------+  > Bump version
------------+  > Improve token discovery for Modal
------------+  > Update Modal skill
------------+  > Add planning with files skill from @OthmanAdi
------------   > Add K-Dense BYOK AI co-scientist to README with features and links
------------   > Add writing skills
------------ Submodule skills/humanizer d8085c7..12881ab:
------------   > Merge pull request #56 from mvanhorn/osc/42-add-hyphenation-pattern
------------   > Merge pull request #57 from mvanhorn/osc/35-remove-separator-rules
------------   > Merge pull request #58 from mvanhorn/osc/7-add-license-file
-------------diff --git a/skills/planning-with-files/SKILL.md b/skills/planning-with-files/SKILL.md
-------------index d967199..43672e5 100644
---------------- a/skills/planning-with-files/SKILL.md
-------------+++ b/skills/planning-with-files/SKILL.md
-------------@@ -7,7 +7,7 @@ hooks:
-------------   UserPromptSubmit:
-------------     - hooks:
-------------         - type: command
--------------          command: "if [ -f task_plan.md ]; then echo '[planning-with-files] Active plan detected. If you have not read task_plan.md, progress.md, and findings.md in this conversation, read them now before proceeding.'; fi"
-------------+          command: "if [ -f task_plan.md ]; then echo '[planning-with-files] ACTIVE PLAN — current state:'; head -50 task_plan.md; echo ''; echo '=== recent progress ==='; tail -20 progress.md 2>/dev/null; echo ''; echo '[planning-with-files] Read findings.md for research context. Continue from the current phase.'; fi"
-------------   PreToolUse:
-------------     - matcher: "Write|Edit|Bash|Read|Glob|Grep"
-------------       hooks:
-------------@@ -21,7 +21,7 @@ hooks:
-------------   Stop:
-------------     - hooks:
-------------         - type: command
--------------          command: "SD=\"${OPENCODE_SKILL_ROOT:-$HOME/.config/opencode/skills/planning-with-files}/scripts\"; powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"$SD/check-complete.ps1\" 2>/dev/null || sh \"$SD/check-complete.sh\""
-------------+          command: "SD=\"${SKILL_DIR:-<forge-root>/skills/planning-with-files}/scripts\"; powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"$SD/check-complete.ps1\" 2>/dev/null || sh \"$SD/check-complete.sh\""
------------- metadata:
-------------   version: "2.23.0"
------------- ---
-------------@@ -36,12 +36,12 @@ Work like Manus: Use persistent markdown files as your "working memory on disk."
------------- 
------------- ```bash
------------- # Linux/macOS (auto-detects python3 or python)
--------------$(command -v python3 || command -v python) ~/.config/opencode/skills/planning-with-files/scripts/session-catchup.py "$(pwd)"
-------------+$(command -v python3 || command -v python) skills/planning-with-files/scripts/session-catchup.py "$(pwd)"
------------- ```
------------- 
------------- ```powershell
------------- # Windows PowerShell
--------------python "$env:USERPROFILE\.opencode\skills\planning-with-files\scripts\session-catchup.py" (Get-Location)
-------------+python "skills\planning-with-files\scripts\session-catchup.py" (Get-Location)
------------- ```
------------- 
------------- If catchup report shows unsynced context:
-------------@@ -52,12 +52,12 @@ If catchup report shows unsynced context:
------------- 
------------- ## Important: Where Files Go
------------- 
--------------- **Templates** are in `~/.config/opencode/skills/planning-with-files/templates/`
-------------+- **Templates** are in `<forge-root>/skills/planning-with-files/templates/`
------------- - **Your planning files** go in **your project directory**
------------- 
------------- | Location | What Goes There |
------------- |----------|-----------------|
--------------| Skill directory (`~/.config/opencode/skills/planning-with-files/`) | Templates, scripts, reference docs |
-------------+| Skill directory (`<forge-root>/skills/planning-with-files/`) | Templates, scripts, reference docs |
------------- | Your project directory | `task_plan.md`, `findings.md`, `progress.md` |
------------- 
------------- ## Quick Start
-------------diff --git a/skills/planning-with-files/scripts/session-catchup.py b/skills/planning-with-files/scripts/session-catchup.py
-------------index 5122b91..b187e83 100644
---------------- a/skills/planning-with-files/scripts/session-catchup.py
-------------+++ b/skills/planning-with-files/scripts/session-catchup.py
-------------@@ -254,7 +254,7 @@ def main():
-------------             print(f"USER: {msg['content'][:300]}")
-------------         else:
-------------             if msg.get('content'):
--------------                print(f"OPENCODE: {msg['content'][:300]}")
-------------+                print(f"ASSISTANT: {msg['content'][:300]}")
-------------             if msg.get('tools'):
-------------                 print(f"  Tools: {', '.join(msg['tools'][:4])}")
------------- 
------------+Submodule skills/paper-polish-workflow-skill 7e430bd..bb72126:
------------+  > fix: track assets/logo.jpg so README logo displays on GitHub
------------+  > fix: correct SKILL.md path in CI validation workflow
------------+  > fix: remove package.json to prevent recursive npm nesting
------------+  > fix: remove duplicate files to fix ENAMETOOLONG on plugin install
------------+  > fix: add explicit skills path in plugin.json
------------+  > fix: update plugin.json version to 2.3.0
------------+  > fix: remove .planning/ from git tracking (136 files)
------------+  > fix: use HTTPS git URL instead of GitHub SSH source
------------+  > fix: switch marketplace source from npm to GitHub repo
------------+  > fix: add explicit npmjs.com registry to marketplace.json
------------+  > feat: migrate to official Claude Code plugin marketplace, bump v2.3.0
------------+  > feat: add Claude Code plugin format with auto-install postinstall script
------------+  > feat: add get-paper skill, bump to v2.2.0
------------ diff --git a/skills/superpowers/brainstorming/SKILL.md b/skills/superpowers/brainstorming/SKILL.md
-------------index 724dc79..edbc2b5 100644
------------+index edbc2b5..06cd0a2 100644
------------ --- a/skills/superpowers/brainstorming/SKILL.md
------------ +++ b/skills/superpowers/brainstorming/SKILL.md
------------ @@ -27,7 +27,7 @@ You MUST create a task for each of these items and complete them in order:
------------  4. **Propose 2-3 approaches** — with trade-offs and your recommendation
------------  5. **Present design** — in sections scaled to their complexity, get user approval after each section
------------  6. **Write design doc** — save to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` and commit
--------------7. **Spec review loop** — dispatch spec-document-reviewer subagent with precisely crafted review context (never your session history); fix issues and re-dispatch until approved (max 5 iterations, then surface to human)
-------------+7. **Spec review loop** — dispatch spec-document-reviewer subagent with precisely crafted review context (never your session history); fix issues and re-dispatch until approved (max 3 iterations, then surface to human)
------------+-7. **Spec review loop** — dispatch spec-document-reviewer subagent with precisely crafted review context (never your session history); fix issues and re-dispatch until approved (max 3 iterations, then surface to human)
------------++7. **Spec self-review** — quick inline check for placeholders, contradictions, ambiguity, scope (see below)
------------  8. **User reviews written spec** — ask user to review the spec file before proceeding
------------  9. **Transition to implementation** — invoke writing-plans skill to create implementation plan
------------  
-------------@@ -121,7 +121,7 @@ After writing the spec document:
------------- 
------------- 1. Dispatch spec-document-reviewer subagent (see spec-document-reviewer-prompt.md)
------------- 2. If Issues Found: fix, re-dispatch, repeat until Approved
--------------3. If loop exceeds 5 iterations, surface to human for guidance
-------------+3. If loop exceeds 3 iterations, surface to human for guidance
------------+@@ -43,8 +43,7 @@ digraph brainstorming {
------------+     "Present design sections" [shape=box];
------------+     "User approves design?" [shape=diamond];
------------+     "Write design doc" [shape=box];
------------+-    "Spec review loop" [shape=box];
------------+-    "Spec review passed?" [shape=diamond];
------------++    "Spec self-review\n(fix inline)" [shape=box];
------------+     "User reviews spec?" [shape=diamond];
------------+     "Invoke writing-plans skill" [shape=doublecircle];
------------+ 
------------+@@ -57,10 +56,8 @@ digraph brainstorming {
------------+     "Present design sections" -> "User approves design?";
------------+     "User approves design?" -> "Present design sections" [label="no, revise"];
------------+     "User approves design?" -> "Write design doc" [label="yes"];
------------+-    "Write design doc" -> "Spec review loop";
------------+-    "Spec review loop" -> "Spec review passed?";
------------+-    "Spec review passed?" -> "Spec review loop" [label="issues found,\nfix and re-dispatch"];
------------+-    "Spec review passed?" -> "User reviews spec?" [label="approved"];
------------++    "Write design doc" -> "Spec self-review\n(fix inline)";
------------++    "Spec self-review\n(fix inline)" -> "User reviews spec?";
------------+     "User reviews spec?" -> "Write design doc" [label="changes requested"];
------------+     "User reviews spec?" -> "Invoke writing-plans skill" [label="approved"];
------------+ }
------------+@@ -116,12 +113,15 @@ digraph brainstorming {
------------+ - Use elements-of-style:writing-clearly-and-concisely skill if available
------------+ - Commit the design document to git
------------+ 
------------+-**Spec Review Loop:**
------------+-After writing the spec document:
------------++**Spec Self-Review:**
------------++After writing the spec document, look at it with fresh eyes:
------------+ 
------------+-1. Dispatch spec-document-reviewer subagent (see spec-document-reviewer-prompt.md)
------------+-2. If Issues Found: fix, re-dispatch, repeat until Approved
------------+-3. If loop exceeds 3 iterations, surface to human for guidance
------------++1. **Placeholder scan:** Any "TBD", "TODO", incomplete sections, or vague requirements? Fix them.
------------++2. **Internal consistency:** Do any sections contradict each other? Does the architecture match the feature descriptions?
------------++3. **Scope check:** Is this focused enough for a single implementation plan, or does it need decomposition?
------------++4. **Ambiguity check:** Could any requirement be interpreted two different ways? If so, pick one and make it explicit.
------------++
------------++Fix any issues inline. No need to re-review — just fix and move on.
------------  
------------  **User Review Gate:**
------------  After the spec review loop passes, ask the user to review the written spec before proceeding:
-------------diff --git a/skills/superpowers/brainstorming/scripts/server.js b/skills/superpowers/brainstorming/scripts/server.js
-------------deleted file mode 100644
-------------index dec2f7a..0000000
---------------- a/skills/superpowers/brainstorming/scripts/server.js
-------------+++ /dev/null
-------------@@ -1,338 +0,0 @@
--------------const crypto = require('crypto');
--------------const http = require('http');
--------------const fs = require('fs');
--------------const path = require('path');
--------------
--------------// ========== WebSocket Protocol (RFC 6455) ==========
--------------
--------------const OPCODES = { TEXT: 0x01, CLOSE: 0x08, PING: 0x09, PONG: 0x0A };
--------------const WS_MAGIC = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';
--------------
--------------function computeAcceptKey(clientKey) {
--------------  return crypto.createHash('sha1').update(clientKey + WS_MAGIC).digest('base64');
--------------}
--------------
--------------function encodeFrame(opcode, payload) {
--------------  const fin = 0x80;
--------------  const len = payload.length;
--------------  let header;
--------------
--------------  if (len < 126) {
--------------    header = Buffer.alloc(2);
--------------    header[0] = fin | opcode;
--------------    header[1] = len;
--------------  } else if (len < 65536) {
--------------    header = Buffer.alloc(4);
--------------    header[0] = fin | opcode;
--------------    header[1] = 126;
--------------    header.writeUInt16BE(len, 2);
--------------  } else {
--------------    header = Buffer.alloc(10);
--------------    header[0] = fin | opcode;
--------------    header[1] = 127;
--------------    header.writeBigUInt64BE(BigInt(len), 2);
--------------  }
--------------
--------------  return Buffer.concat([header, payload]);
--------------}
--------------
--------------function decodeFrame(buffer) {
--------------  if (buffer.length < 2) return null;
--------------
--------------  const secondByte = buffer[1];
--------------  const opcode = buffer[0] & 0x0F;
--------------  const masked = (secondByte & 0x80) !== 0;
--------------  let payloadLen = secondByte & 0x7F;
--------------  let offset = 2;
--------------
--------------  if (!masked) throw new Error('Client frames must be masked');
--------------
--------------  if (payloadLen === 126) {
--------------    if (buffer.length < 4) return null;
--------------    payloadLen = buffer.readUInt16BE(2);
--------------    offset = 4;
--------------  } else if (payloadLen === 127) {
--------------    if (buffer.length < 10) return null;
--------------    payloadLen = Number(buffer.readBigUInt64BE(2));
--------------    offset = 10;
--------------  }
--------------
--------------  const maskOffset = offset;
--------------  const dataOffset = offset + 4;
--------------  const totalLen = dataOffset + payloadLen;
--------------  if (buffer.length < totalLen) return null;
--------------
--------------  const mask = buffer.slice(maskOffset, dataOffset);
--------------  const data = Buffer.alloc(payloadLen);
--------------  for (let i = 0; i < payloadLen; i++) {
--------------    data[i] = buffer[dataOffset + i] ^ mask[i % 4];
--------------  }
--------------
--------------  return { opcode, payload: data, bytesConsumed: totalLen };
--------------}
--------------
--------------// ========== Configuration ==========
--------------
--------------const PORT = process.env.BRAINSTORM_PORT || (49152 + Math.floor(Math.random() * 16383));
--------------const HOST = process.env.BRAINSTORM_HOST || '127.0.0.1';
--------------const URL_HOST = process.env.BRAINSTORM_URL_HOST || (HOST === '127.0.0.1' ? 'localhost' : HOST);
------------+diff --git a/skills/superpowers/brainstorming/scripts/server.cjs b/skills/superpowers/brainstorming/scripts/server.cjs
------------+index 86c3080..562c17f 100644
------------+--- a/skills/superpowers/brainstorming/scripts/server.cjs
------------++++ b/skills/superpowers/brainstorming/scripts/server.cjs
------------+@@ -76,8 +76,10 @@ function decodeFrame(buffer) {
------------+ const PORT = process.env.BRAINSTORM_PORT || (49152 + Math.floor(Math.random() * 16383));
------------+ const HOST = process.env.BRAINSTORM_HOST || '127.0.0.1';
------------+ const URL_HOST = process.env.BRAINSTORM_URL_HOST || (HOST === '127.0.0.1' ? 'localhost' : HOST);
------------ -const SCREEN_DIR = process.env.BRAINSTORM_DIR || '/tmp/brainstorm';
------------ -const OWNER_PID = process.env.BRAINSTORM_OWNER_PID ? Number(process.env.BRAINSTORM_OWNER_PID) : null;
--------------
--------------const MIME_TYPES = {
--------------  '.html': 'text/html', '.css': 'text/css', '.js': 'application/javascript',
--------------  '.json': 'application/json', '.png': 'image/png', '.jpg': 'image/jpeg',
--------------  '.jpeg': 'image/jpeg', '.gif': 'image/gif', '.svg': 'image/svg+xml'
--------------};
--------------
--------------// ========== Templates and Constants ==========
--------------
--------------const WAITING_PAGE = `<!DOCTYPE html>
--------------<html>
--------------<head><meta charset="utf-8"><title>Brainstorm Companion</title>
--------------<style>body { font-family: system-ui, sans-serif; padding: 2rem; max-width: 800px; margin: 0 auto; }
--------------h1 { color: #333; } p { color: #666; }</style>
--------------</head>
--------------<body><h1>Brainstorm Companion</h1>
--------------<p>Waiting for Claude to push a screen...</p></body></html>`;
--------------
--------------const frameTemplate = fs.readFileSync(path.join(__dirname, 'frame-template.html'), 'utf-8');
--------------const helperScript = fs.readFileSync(path.join(__dirname, 'helper.js'), 'utf-8');
--------------const helperInjection = '<script>\n' + helperScript + '\n</script>';
--------------
--------------// ========== Helper Functions ==========
--------------
--------------function isFullDocument(html) {
--------------  const trimmed = html.trimStart().toLowerCase();
--------------  return trimmed.startsWith('<!doctype') || trimmed.startsWith('<html');
--------------}
--------------
--------------function wrapInFrame(content) {
--------------  return frameTemplate.replace('<!-- CONTENT -->', content);
--------------}
--------------
--------------function getNewestScreen() {
------------++const SESSION_DIR = process.env.BRAINSTORM_DIR || '/tmp/brainstorm';
------------++const CONTENT_DIR = path.join(SESSION_DIR, 'content');
------------++const STATE_DIR = path.join(SESSION_DIR, 'state');
------------++let ownerPid = process.env.BRAINSTORM_OWNER_PID ? Number(process.env.BRAINSTORM_OWNER_PID) : null;
------------+ 
------------+ const MIME_TYPES = {
------------+   '.html': 'text/html', '.css': 'text/css', '.js': 'application/javascript',
------------+@@ -112,10 +114,10 @@ function wrapInFrame(content) {
------------+ }
------------+ 
------------+ function getNewestScreen() {
------------ -  const files = fs.readdirSync(SCREEN_DIR)
--------------    .filter(f => f.endsWith('.html'))
--------------    .map(f => {
------------++  const files = fs.readdirSync(CONTENT_DIR)
------------+     .filter(f => f.endsWith('.html'))
------------+     .map(f => {
------------ -      const fp = path.join(SCREEN_DIR, f);
--------------      return { path: fp, mtime: fs.statSync(fp).mtime.getTime() };
--------------    })
--------------    .sort((a, b) => b.mtime - a.mtime);
--------------  return files.length > 0 ? files[0].path : null;
--------------}
--------------
--------------// ========== HTTP Request Handler ==========
--------------
--------------function handleRequest(req, res) {
--------------  touchActivity();
--------------  if (req.method === 'GET' && req.url === '/') {
--------------    const screenFile = getNewestScreen();
--------------    let html = screenFile
--------------      ? (raw => isFullDocument(raw) ? raw : wrapInFrame(raw))(fs.readFileSync(screenFile, 'utf-8'))
--------------      : WAITING_PAGE;
--------------
--------------    if (html.includes('</body>')) {
--------------      html = html.replace('</body>', helperInjection + '\n</body>');
--------------    } else {
--------------      html += helperInjection;
--------------    }
--------------
--------------    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
--------------    res.end(html);
--------------  } else if (req.method === 'GET' && req.url.startsWith('/files/')) {
--------------    const fileName = req.url.slice(7);
------------++      const fp = path.join(CONTENT_DIR, f);
------------+       return { path: fp, mtime: fs.statSync(fp).mtime.getTime() };
------------+     })
------------+     .sort((a, b) => b.mtime - a.mtime);
------------+@@ -142,7 +144,7 @@ function handleRequest(req, res) {
------------+     res.end(html);
------------+   } else if (req.method === 'GET' && req.url.startsWith('/files/')) {
------------+     const fileName = req.url.slice(7);
------------ -    const filePath = path.join(SCREEN_DIR, path.basename(fileName));
--------------    if (!fs.existsSync(filePath)) {
--------------      res.writeHead(404);
--------------      res.end('Not found');
--------------      return;
--------------    }
--------------    const ext = path.extname(filePath).toLowerCase();
--------------    const contentType = MIME_TYPES[ext] || 'application/octet-stream';
--------------    res.writeHead(200, { 'Content-Type': contentType });
--------------    res.end(fs.readFileSync(filePath));
--------------  } else {
--------------    res.writeHead(404);
--------------    res.end('Not found');
--------------  }
--------------}
--------------
--------------// ========== WebSocket Connection Handling ==========
--------------
--------------const clients = new Set();
--------------
--------------function handleUpgrade(req, socket) {
--------------  const key = req.headers['sec-websocket-key'];
--------------  if (!key) { socket.destroy(); return; }
--------------
--------------  const accept = computeAcceptKey(key);
--------------  socket.write(
--------------    'HTTP/1.1 101 Switching Protocols\r\n' +
--------------    'Upgrade: websocket\r\n' +
--------------    'Connection: Upgrade\r\n' +
--------------    'Sec-WebSocket-Accept: ' + accept + '\r\n\r\n'
--------------  );
--------------
--------------  let buffer = Buffer.alloc(0);
--------------  clients.add(socket);
--------------
--------------  socket.on('data', (chunk) => {
--------------    buffer = Buffer.concat([buffer, chunk]);
--------------    while (buffer.length > 0) {
--------------      let result;
--------------      try {
--------------        result = decodeFrame(buffer);
--------------      } catch (e) {
--------------        socket.end(encodeFrame(OPCODES.CLOSE, Buffer.alloc(0)));
--------------        clients.delete(socket);
--------------        return;
--------------      }
--------------      if (!result) break;
--------------      buffer = buffer.slice(result.bytesConsumed);
--------------
--------------      switch (result.opcode) {
--------------        case OPCODES.TEXT:
--------------          handleMessage(result.payload.toString());
--------------          break;
--------------        case OPCODES.CLOSE:
--------------          socket.end(encodeFrame(OPCODES.CLOSE, Buffer.alloc(0)));
--------------          clients.delete(socket);
--------------          return;
--------------        case OPCODES.PING:
--------------          socket.write(encodeFrame(OPCODES.PONG, result.payload));
--------------          break;
--------------        case OPCODES.PONG:
--------------          break;
--------------        default: {
--------------          const closeBuf = Buffer.alloc(2);
--------------          closeBuf.writeUInt16BE(1003);
--------------          socket.end(encodeFrame(OPCODES.CLOSE, closeBuf));
--------------          clients.delete(socket);
--------------          return;
--------------        }
--------------      }
--------------    }
--------------  });
--------------
--------------  socket.on('close', () => clients.delete(socket));
--------------  socket.on('error', () => clients.delete(socket));
--------------}
--------------
--------------function handleMessage(text) {
--------------  let event;
--------------  try {
--------------    event = JSON.parse(text);
--------------  } catch (e) {
--------------    console.error('Failed to parse WebSocket message:', e.message);
--------------    return;
--------------  }
--------------  touchActivity();
--------------  console.log(JSON.stringify({ source: 'user-event', ...event }));
--------------  if (event.choice) {
------------++    const filePath = path.join(CONTENT_DIR, path.basename(fileName));
------------+     if (!fs.existsSync(filePath)) {
------------+       res.writeHead(404);
------------+       res.end('Not found');
------------+@@ -230,7 +232,7 @@ function handleMessage(text) {
------------+   touchActivity();
------------+   console.log(JSON.stringify({ source: 'user-event', ...event }));
------------+   if (event.choice) {
------------ -    const eventsFile = path.join(SCREEN_DIR, '.events');
--------------    fs.appendFileSync(eventsFile, JSON.stringify(event) + '\n');
--------------  }
--------------}
--------------
--------------function broadcast(msg) {
--------------  const frame = encodeFrame(OPCODES.TEXT, Buffer.from(JSON.stringify(msg)));
--------------  for (const socket of clients) {
--------------    try { socket.write(frame); } catch (e) { clients.delete(socket); }
--------------  }
--------------}
--------------
--------------// ========== Activity Tracking ==========
--------------
--------------const IDLE_TIMEOUT_MS = 30 * 60 * 1000; // 30 minutes
--------------let lastActivity = Date.now();
--------------
--------------function touchActivity() {
--------------  lastActivity = Date.now();
--------------}
--------------
--------------// ========== File Watching ==========
--------------
--------------const debounceTimers = new Map();
--------------
--------------// ========== Server Startup ==========
--------------
--------------function startServer() {
------------++    const eventsFile = path.join(STATE_DIR, 'events');
------------+     fs.appendFileSync(eventsFile, JSON.stringify(event) + '\n');
------------+   }
------------+ }
------------+@@ -258,32 +260,33 @@ const debounceTimers = new Map();
------------+ // ========== Server Startup ==========
------------+ 
------------+ function startServer() {
------------ -  if (!fs.existsSync(SCREEN_DIR)) fs.mkdirSync(SCREEN_DIR, { recursive: true });
--------------
--------------  // Track known files to distinguish new screens from updates.
--------------  // macOS fs.watch reports 'rename' for both new files and overwrites,
--------------  // so we can't rely on eventType alone.
--------------  const knownFiles = new Set(
------------++  if (!fs.existsSync(CONTENT_DIR)) fs.mkdirSync(CONTENT_DIR, { recursive: true });
------------++  if (!fs.existsSync(STATE_DIR)) fs.mkdirSync(STATE_DIR, { recursive: true });
------------+ 
------------+   // Track known files to distinguish new screens from updates.
------------+   // macOS fs.watch reports 'rename' for both new files and overwrites,
------------+   // so we can't rely on eventType alone.
------------+   const knownFiles = new Set(
------------ -    fs.readdirSync(SCREEN_DIR).filter(f => f.endsWith('.html'))
--------------  );
--------------
--------------  const server = http.createServer(handleRequest);
--------------  server.on('upgrade', handleUpgrade);
--------------
------------++    fs.readdirSync(CONTENT_DIR).filter(f => f.endsWith('.html'))
------------+   );
------------+ 
------------+   const server = http.createServer(handleRequest);
------------+   server.on('upgrade', handleUpgrade);
------------+ 
------------ -  const watcher = fs.watch(SCREEN_DIR, (eventType, filename) => {
--------------    if (!filename || !filename.endsWith('.html')) return;
--------------
--------------    if (debounceTimers.has(filename)) clearTimeout(debounceTimers.get(filename));
--------------    debounceTimers.set(filename, setTimeout(() => {
--------------      debounceTimers.delete(filename);
------------++  const watcher = fs.watch(CONTENT_DIR, (eventType, filename) => {
------------+     if (!filename || !filename.endsWith('.html')) return;
------------+ 
------------+     if (debounceTimers.has(filename)) clearTimeout(debounceTimers.get(filename));
------------+     debounceTimers.set(filename, setTimeout(() => {
------------+       debounceTimers.delete(filename);
------------ -      const filePath = path.join(SCREEN_DIR, filename);
--------------
--------------      if (!fs.existsSync(filePath)) return; // file was deleted
--------------      touchActivity();
--------------
--------------      if (!knownFiles.has(filename)) {
--------------        knownFiles.add(filename);
------------++      const filePath = path.join(CONTENT_DIR, filename);
------------+ 
------------+       if (!fs.existsSync(filePath)) return; // file was deleted
------------+       touchActivity();
------------+ 
------------+       if (!knownFiles.has(filename)) {
------------+         knownFiles.add(filename);
------------ -        const eventsFile = path.join(SCREEN_DIR, '.events');
--------------        if (fs.existsSync(eventsFile)) fs.unlinkSync(eventsFile);
--------------        console.log(JSON.stringify({ type: 'screen-added', file: filePath }));
--------------      } else {
--------------        console.log(JSON.stringify({ type: 'screen-updated', file: filePath }));
--------------      }
--------------
--------------      broadcast({ type: 'reload' });
--------------    }, 100));
--------------  });
--------------  watcher.on('error', (err) => console.error('fs.watch error:', err.message));
--------------
--------------  function shutdown(reason) {
--------------    console.log(JSON.stringify({ type: 'server-stopped', reason }));
------------++        const eventsFile = path.join(STATE_DIR, 'events');
------------+         if (fs.existsSync(eventsFile)) fs.unlinkSync(eventsFile);
------------+         console.log(JSON.stringify({ type: 'screen-added', file: filePath }));
------------+       } else {
------------+@@ -297,10 +300,10 @@ function startServer() {
------------+ 
------------+   function shutdown(reason) {
------------+     console.log(JSON.stringify({ type: 'server-stopped', reason }));
------------ -    const infoFile = path.join(SCREEN_DIR, '.server-info');
--------------    if (fs.existsSync(infoFile)) fs.unlinkSync(infoFile);
--------------    fs.writeFileSync(
------------++    const infoFile = path.join(STATE_DIR, 'server-info');
------------+     if (fs.existsSync(infoFile)) fs.unlinkSync(infoFile);
------------+     fs.writeFileSync(
------------ -      path.join(SCREEN_DIR, '.server-stopped'),
--------------      JSON.stringify({ reason, timestamp: Date.now() }) + '\n'
--------------    );
--------------    watcher.close();
--------------    clearInterval(lifecycleCheck);
--------------    server.close(() => process.exit(0));
--------------  }
--------------
--------------  function ownerAlive() {
------------++      path.join(STATE_DIR, 'server-stopped'),
------------+       JSON.stringify({ reason, timestamp: Date.now() }) + '\n'
------------+     );
------------+     watcher.close();
------------+@@ -309,8 +312,8 @@ function startServer() {
------------+   }
------------+ 
------------+   function ownerAlive() {
------------ -    if (!OWNER_PID) return true;
------------ -    try { process.kill(OWNER_PID, 0); return true; } catch (e) { return false; }
--------------  }
--------------
--------------  // Check every 60s: exit if owner process died or idle for 30 minutes
--------------  const lifecycleCheck = setInterval(() => {
--------------    if (!ownerAlive()) shutdown('owner process exited');
--------------    else if (Date.now() - lastActivity > IDLE_TIMEOUT_MS) shutdown('idle timeout');
--------------  }, 60 * 1000);
--------------  lifecycleCheck.unref();
--------------
--------------  server.listen(PORT, HOST, () => {
--------------    const info = JSON.stringify({
--------------      type: 'server-started', port: Number(PORT), host: HOST,
--------------      url_host: URL_HOST, url: 'http://' + URL_HOST + ':' + PORT,
------------++    if (!ownerPid) return true;
------------++    try { process.kill(ownerPid, 0); return true; } catch (e) { return e.code === 'EPERM'; }
------------+   }
------------+ 
------------+   // Check every 60s: exit if owner process died or idle for 30 minutes
------------+@@ -320,14 +323,27 @@ function startServer() {
------------+   }, 60 * 1000);
------------+   lifecycleCheck.unref();
------------+ 
------------++  // Validate owner PID at startup. If it's already dead, the PID resolution
------------++  // was wrong (common on WSL, Tailscale SSH, and cross-user scenarios).
------------++  // Disable monitoring and rely on the idle timeout instead.
------------++  if (ownerPid) {
------------++    try { process.kill(ownerPid, 0); }
------------++    catch (e) {
------------++      if (e.code !== 'EPERM') {
------------++        console.log(JSON.stringify({ type: 'owner-pid-invalid', pid: ownerPid, reason: 'dead at startup' }));
------------++        ownerPid = null;
------------++      }
------------++    }
------------++  }
------------++
------------+   server.listen(PORT, HOST, () => {
------------+     const info = JSON.stringify({
------------+       type: 'server-started', port: Number(PORT), host: HOST,
------------+       url_host: URL_HOST, url: 'http://' + URL_HOST + ':' + PORT,
------------ -      screen_dir: SCREEN_DIR
--------------    });
--------------    console.log(info);
------------++      screen_dir: CONTENT_DIR, state_dir: STATE_DIR
------------+     });
------------+     console.log(info);
------------ -    fs.writeFileSync(path.join(SCREEN_DIR, '.server-info'), info + '\n');
--------------  });
--------------}
--------------
--------------if (require.main === module) {
--------------  startServer();
--------------}
--------------
--------------module.exports = { computeAcceptKey, encodeFrame, decodeFrame, OPCODES };
------------++    fs.writeFileSync(path.join(STATE_DIR, 'server-info'), info + '\n');
------------+   });
------------+ }
------------+ 
------------ diff --git a/skills/superpowers/brainstorming/scripts/start-server.sh b/skills/superpowers/brainstorming/scripts/start-server.sh
-------------index b5f5a75..a0ef299 100755
------------+index a0ef299..9ef6dcb 100755
------------ --- a/skills/superpowers/brainstorming/scripts/start-server.sh
------------ +++ b/skills/superpowers/brainstorming/scripts/start-server.sh
-------------@@ -1,4 +1,4 @@
--------------#!/bin/bash
-------------+#!/usr/bin/env bash
------------- # Start the brainstorm server and output connection info
------------- # Usage: start-server.sh [--project-dir <path>] [--host <bind-host>] [--url-host <display-host>] [--foreground] [--background]
------------- #
-------------@@ -64,6 +64,16 @@ if [[ -n "${CODEX_CI:-}" && "$FOREGROUND" != "true" && "$FORCE_BACKGROUND" != "t
-------------   FOREGROUND="true"
------------+@@ -78,16 +78,17 @@ fi
------------+ SESSION_ID="$$-$(date +%s)"
------------+ 
------------+ if [[ -n "$PROJECT_DIR" ]]; then
------------+-  SCREEN_DIR="${PROJECT_DIR}/.superpowers/brainstorm/${SESSION_ID}"
------------++  SESSION_DIR="${PROJECT_DIR}/.superpowers/brainstorm/${SESSION_ID}"
------------+ else
------------+-  SCREEN_DIR="/tmp/brainstorm-${SESSION_ID}"
------------++  SESSION_DIR="/tmp/brainstorm-${SESSION_ID}"
------------  fi
------------  
-------------+# Windows/Git Bash reaps nohup background processes. Auto-foreground when detected.
-------------+if [[ "$FOREGROUND" != "true" && "$FORCE_BACKGROUND" != "true" ]]; then
-------------+  case "${OSTYPE:-}" in
-------------+    msys*|cygwin*|mingw*) FOREGROUND="true" ;;
-------------+  esac
-------------+  if [[ -n "${MSYSTEM:-}" ]]; then
-------------+    FOREGROUND="true"
-------------+  fi
-------------+fi
-------------+
------------- # Generate unique session directory
------------- SESSION_ID="$$-$(date +%s)"
------------+-PID_FILE="${SCREEN_DIR}/.server.pid"
------------+-LOG_FILE="${SCREEN_DIR}/.server.log"
------------++STATE_DIR="${SESSION_DIR}/state"
------------++PID_FILE="${STATE_DIR}/server.pid"
------------++LOG_FILE="${STATE_DIR}/server.log"
------------+ 
------------+-# Create fresh session directory
------------+-mkdir -p "$SCREEN_DIR"
------------++# Create fresh session directory with content and state peers
------------++mkdir -p "${SESSION_DIR}/content" "$STATE_DIR"
------------  
-------------@@ -96,16 +106,22 @@ if [[ -z "$OWNER_PID" || "$OWNER_PID" == "1" ]]; then
------------+ # Kill any existing server
------------+ if [[ -f "$PID_FILE" ]]; then
------------+@@ -106,22 +107,16 @@ if [[ -z "$OWNER_PID" || "$OWNER_PID" == "1" ]]; then
------------    OWNER_PID="$PPID"
------------  fi
------------  
-------------+# On Windows/MSYS2, the MSYS2 PID namespace is invisible to Node.js.
-------------+# Skip owner-PID monitoring — the 30-minute idle timeout prevents orphans.
-------------+case "${OSTYPE:-}" in
-------------+  msys*|cygwin*|mingw*) OWNER_PID="" ;;
-------------+esac
-------------+
------------+-# On Windows/MSYS2, the MSYS2 PID namespace is invisible to Node.js.
------------+-# Skip owner-PID monitoring — the 30-minute idle timeout prevents orphans.
------------+-case "${OSTYPE:-}" in
------------+-  msys*|cygwin*|mingw*) OWNER_PID="" ;;
------------+-esac
------------+-
------------  # Foreground mode for environments that reap detached/background processes.
------------  if [[ "$FOREGROUND" == "true" ]]; then
------------    echo "$$" > "$PID_FILE"
--------------  env BRAINSTORM_DIR="$SCREEN_DIR" BRAINSTORM_HOST="$BIND_HOST" BRAINSTORM_URL_HOST="$URL_HOST" BRAINSTORM_OWNER_PID="$OWNER_PID" node server.js
-------------+  env BRAINSTORM_DIR="$SCREEN_DIR" BRAINSTORM_HOST="$BIND_HOST" BRAINSTORM_URL_HOST="$URL_HOST" BRAINSTORM_OWNER_PID="$OWNER_PID" node server.cjs
------------+-  env BRAINSTORM_DIR="$SCREEN_DIR" BRAINSTORM_HOST="$BIND_HOST" BRAINSTORM_URL_HOST="$URL_HOST" BRAINSTORM_OWNER_PID="$OWNER_PID" node server.cjs
------------++  env BRAINSTORM_DIR="$SESSION_DIR" BRAINSTORM_HOST="$BIND_HOST" BRAINSTORM_URL_HOST="$URL_HOST" BRAINSTORM_OWNER_PID="$OWNER_PID" node server.cjs
------------    exit $?
------------  fi
------------  
------------  # Start server, capturing output to log file
------------  # Use nohup to survive shell exit; disown to remove from job table
--------------nohup env BRAINSTORM_DIR="$SCREEN_DIR" BRAINSTORM_HOST="$BIND_HOST" BRAINSTORM_URL_HOST="$URL_HOST" BRAINSTORM_OWNER_PID="$OWNER_PID" node server.js > "$LOG_FILE" 2>&1 &
-------------+nohup env BRAINSTORM_DIR="$SCREEN_DIR" BRAINSTORM_HOST="$BIND_HOST" BRAINSTORM_URL_HOST="$URL_HOST" BRAINSTORM_OWNER_PID="$OWNER_PID" node server.cjs > "$LOG_FILE" 2>&1 &
------------+-nohup env BRAINSTORM_DIR="$SCREEN_DIR" BRAINSTORM_HOST="$BIND_HOST" BRAINSTORM_URL_HOST="$URL_HOST" BRAINSTORM_OWNER_PID="$OWNER_PID" node server.cjs > "$LOG_FILE" 2>&1 &
------------++nohup env BRAINSTORM_DIR="$SESSION_DIR" BRAINSTORM_HOST="$BIND_HOST" BRAINSTORM_URL_HOST="$URL_HOST" BRAINSTORM_OWNER_PID="$OWNER_PID" node server.cjs > "$LOG_FILE" 2>&1 &
------------  SERVER_PID=$!
------------  disown "$SERVER_PID" 2>/dev/null
------------  echo "$SERVER_PID" > "$PID_FILE"
------------ diff --git a/skills/superpowers/brainstorming/scripts/stop-server.sh b/skills/superpowers/brainstorming/scripts/stop-server.sh
-------------index c3724de..2e5973d 100755
------------+index 2e5973d..a6b94e6 100755
------------ --- a/skills/superpowers/brainstorming/scripts/stop-server.sh
------------ +++ b/skills/superpowers/brainstorming/scripts/stop-server.sh
-------------@@ -1,4 +1,4 @@
--------------#!/bin/bash
-------------+#!/usr/bin/env bash
------------+@@ -1,19 +1,20 @@
------------+ #!/usr/bin/env bash
------------  # Stop the brainstorm server and clean up
------------- # Usage: stop-server.sh <screen_dir>
------------+-# Usage: stop-server.sh <screen_dir>
------------++# Usage: stop-server.sh <session_dir>
------------  #
-------------@@ -17,7 +17,31 @@ PID_FILE="${SCREEN_DIR}/.server.pid"
------------+ # Kills the server process. Only deletes session directory if it's
------------+ # under /tmp (ephemeral). Persistent directories (.superpowers/) are
------------+ # kept so mockups can be reviewed later.
------------+ 
------------+-SCREEN_DIR="$1"
------------++SESSION_DIR="$1"
------------+ 
------------+-if [[ -z "$SCREEN_DIR" ]]; then
------------+-  echo '{"error": "Usage: stop-server.sh <screen_dir>"}'
------------++if [[ -z "$SESSION_DIR" ]]; then
------------++  echo '{"error": "Usage: stop-server.sh <session_dir>"}'
------------+   exit 1
------------+ fi
------------+ 
------------+-PID_FILE="${SCREEN_DIR}/.server.pid"
------------++STATE_DIR="${SESSION_DIR}/state"
------------++PID_FILE="${STATE_DIR}/server.pid"
------------  
------------  if [[ -f "$PID_FILE" ]]; then
------------    pid=$(cat "$PID_FILE")
--------------  kill "$pid" 2>/dev/null
-------------+
-------------+  # Try to stop gracefully, fallback to force if still alive
-------------+  kill "$pid" 2>/dev/null || true
-------------+
-------------+  # Wait for graceful shutdown (up to ~2s)
-------------+  for i in {1..20}; do
-------------+    if ! kill -0 "$pid" 2>/dev/null; then
-------------+      break
-------------+    fi
-------------+    sleep 0.1
-------------+  done
-------------+
-------------+  # If still running, escalate to SIGKILL
-------------+  if kill -0 "$pid" 2>/dev/null; then
-------------+    kill -9 "$pid" 2>/dev/null || true
-------------+
-------------+    # Give SIGKILL a moment to take effect
-------------+    sleep 0.1
-------------+  fi
-------------+
-------------+  if kill -0 "$pid" 2>/dev/null; then
-------------+    echo '{"status": "failed", "error": "process still running"}'
-------------+    exit 1
-------------+  fi
-------------+
-------------   rm -f "$PID_FILE" "${SCREEN_DIR}/.server.log"
------------+@@ -42,11 +43,11 @@ if [[ -f "$PID_FILE" ]]; then
------------+     exit 1
------------+   fi
------------  
-------------   # Only delete ephemeral /tmp directories
-------------diff --git a/skills/superpowers/brainstorming/spec-document-reviewer-prompt.md b/skills/superpowers/brainstorming/spec-document-reviewer-prompt.md
-------------index 212b36c..35acbb6 100644
---------------- a/skills/superpowers/brainstorming/spec-document-reviewer-prompt.md
-------------+++ b/skills/superpowers/brainstorming/spec-document-reviewer-prompt.md
-------------@@ -19,32 +19,31 @@ Task tool (general-purpose):
-------------     | Category | What to Look For |
-------------     |----------|------------------|
-------------     | Completeness | TODOs, placeholders, "TBD", incomplete sections |
--------------    | Coverage | Missing error handling, edge cases, integration points |
-------------     | Consistency | Internal contradictions, conflicting requirements |
--------------    | Clarity | Ambiguous requirements |
--------------    | YAGNI | Unrequested features, over-engineering |
-------------+    | Clarity | Requirements ambiguous enough to cause someone to build the wrong thing |
-------------     | Scope | Focused enough for a single plan — not covering multiple independent subsystems |
--------------    | Architecture | Units with clear boundaries, well-defined interfaces, independently understandable and testable |
-------------+    | YAGNI | Unrequested features, over-engineering |
-------------+
-------------+    ## Calibration
------------+-  rm -f "$PID_FILE" "${SCREEN_DIR}/.server.log"
------------++  rm -f "$PID_FILE" "${STATE_DIR}/server.log"
------------  
--------------    ## CRITICAL
-------------+    **Only flag issues that would cause real problems during implementation planning.**
-------------+    A missing section, a contradiction, or a requirement so ambiguous it could be
-------------+    interpreted two different ways — those are issues. Minor wording improvements,
-------------+    stylistic preferences, and "sections less detailed than others" are not.
------------+   # Only delete ephemeral /tmp directories
------------+-  if [[ "$SCREEN_DIR" == /tmp/* ]]; then
------------+-    rm -rf "$SCREEN_DIR"
------------++  if [[ "$SESSION_DIR" == /tmp/* ]]; then
------------++    rm -rf "$SESSION_DIR"
------------+   fi
------------  
--------------    Look especially hard for:
--------------    - Any TODO markers or placeholder text
--------------    - Sections saying "to be defined later" or "will spec when X is done"
--------------    - Sections noticeably less detailed than others
--------------    - Units that lack clear boundaries or interfaces — can you understand what each unit does without reading its internals?
-------------+    Approve unless there are serious gaps that would lead to a flawed plan.
------------+   echo '{"status": "stopped"}'
------------+diff --git a/skills/superpowers/brainstorming/visual-companion.md b/skills/superpowers/brainstorming/visual-companion.md
------------+index 537ed3c..2113863 100644
------------+--- a/skills/superpowers/brainstorming/visual-companion.md
------------++++ b/skills/superpowers/brainstorming/visual-companion.md
------------+@@ -26,7 +26,7 @@ A question *about* a UI topic is not automatically a visual question. "What kind
------------  
-------------     ## Output Format
------------+ ## How It Works
------------  
-------------     ## Spec Review
------------+-The server watches a directory for HTML files and serves the newest one to the browser. You write HTML content, the user sees it in their browser and can click to select options. Selections are recorded to a `.events` file that you read on your next turn.
------------++The server watches a directory for HTML files and serves the newest one to the browser. You write HTML content to `screen_dir`, the user sees it in their browser and can click to select options. Selections are recorded to `state_dir/events` that you read on your next turn.
------------  
--------------    **Status:** ✅ Approved | ❌ Issues Found
-------------+    **Status:** Approved | Issues Found
------------+ **Content fragments vs full documents:** If your HTML file starts with `<!DOCTYPE` or `<html`, the server serves it as-is (just injects the helper script). Otherwise, the server automatically wraps your content in the frame template — adding the header, CSS theme, selection indicator, and all interactive infrastructure. **Write content fragments by default.** Only write full documents when you need complete control over the page.
------------  
-------------     **Issues (if any):**
--------------    - [Section X]: [specific issue] - [why it matters]
-------------+    - [Section X]: [specific issue] - [why it matters for planning]
------------+@@ -37,12 +37,13 @@ The server watches a directory for HTML files and serves the newest one to the b
------------+ scripts/start-server.sh --project-dir /path/to/project
------------  
--------------    **Recommendations (advisory):**
--------------    - [suggestions that don't block approval]
-------------+    **Recommendations (advisory, do not block approval):**
-------------+    - [suggestions for improvement]
------------+ # Returns: {"type":"server-started","port":52341,"url":"http://localhost:52341",
------------+-#           "screen_dir":"/path/to/project/.superpowers/brainstorm/12345-1706000000"}
------------++#           "screen_dir":"/path/to/project/.superpowers/brainstorm/12345-1706000000/content",
------------++#           "state_dir":"/path/to/project/.superpowers/brainstorm/12345-1706000000/state"}
------------  ```
------------  
------------- **Reviewer returns:** Status, Issues (if any), Recommendations
-------------diff --git a/skills/superpowers/brainstorming/visual-companion.md b/skills/superpowers/brainstorming/visual-companion.md
-------------index a25e85a..537ed3c 100644
---------------- a/skills/superpowers/brainstorming/visual-companion.md
-------------+++ b/skills/superpowers/brainstorming/visual-companion.md
-------------@@ -48,12 +48,21 @@ Save `screen_dir` from the response. Tell user to open the URL.
------------+-Save `screen_dir` from the response. Tell user to open the URL.
------------++Save `screen_dir` and `state_dir` from the response. Tell user to open the URL.
------------  
------------- **Launching the server by platform:**
------------+-**Finding connection info:** The server writes its startup JSON to `$SCREEN_DIR/.server-info`. If you launched the server in the background and didn't capture stdout, read that file to get the URL and port. When using `--project-dir`, check `<project>/.superpowers/brainstorm/` for the session directory.
------------++**Finding connection info:** The server writes its startup JSON to `$STATE_DIR/server-info`. If you launched the server in the background and didn't capture stdout, read that file to get the URL and port. When using `--project-dir`, check `<project>/.superpowers/brainstorm/` for the session directory.
------------  
--------------**Claude Code:**
-------------+**Claude Code (macOS / Linux):**
------------- ```bash
------------- # Default mode works — the script backgrounds the server itself
------------+ **Note:** Pass the project root as `--project-dir` so mockups persist in `.superpowers/brainstorm/` and survive server restarts. Without it, files go to `/tmp` and get cleaned up. Remind the user to add `.superpowers/` to `.gitignore` if it's not already there.
------------+ 
------------+@@ -61,7 +62,7 @@ scripts/start-server.sh --project-dir /path/to/project
------------+ # across conversation turns.
------------  scripts/start-server.sh --project-dir /path/to/project
------------  ```
------------+-When calling this via the Bash tool, set `run_in_background: true`. Then read `$SCREEN_DIR/.server-info` on the next turn to get the URL and port.
------------++When calling this via the Bash tool, set `run_in_background: true`. Then read `$STATE_DIR/server-info` on the next turn to get the URL and port.
------------  
-------------+**Claude Code (Windows):**
-------------+```bash
-------------+# Windows auto-detects and uses foreground mode, which blocks the tool call.
-------------+# Use run_in_background: true on the Bash tool call so the server survives
-------------+# across conversation turns.
-------------+scripts/start-server.sh --project-dir /path/to/project
-------------+```
-------------+When calling this via the Bash tool, set `run_in_background: true`. Then read `$SCREEN_DIR/.server-info` on the next turn to get the URL and port.
-------------+
------------  **Codex:**
------------  ```bash
------------- # Codex reaps background processes. The script auto-detects CODEX_CI and
-------------diff --git a/skills/superpowers/using-superpowers/references/codex-tools.md b/skills/superpowers/using-superpowers/references/codex-tools.md
-------------index eb23075..86f58fa 100644
---------------- a/skills/superpowers/using-superpowers/references/codex-tools.md
-------------+++ b/skills/superpowers/using-superpowers/references/codex-tools.md
-------------@@ -13,13 +13,13 @@ Skills use Claude Code tool names. When you encounter these in a skill, use your
------------- | `Read`, `Write`, `Edit` (files) | Use your native file tools |
------------- | `Bash` (run commands) | Use your native shell tools |
------------+@@ -93,7 +94,7 @@ Use `--url-host` to control what hostname is printed in the returned URL JSON.
------------+ ## The Loop
------------  
--------------## Subagent dispatch requires collab
-------------+## Subagent dispatch requires multi-agent support
------------+ 1. **Check server is alive**, then **write HTML** to a new file in `screen_dir`:
------------+-   - Before each write, check that `$SCREEN_DIR/.server-info` exists. If it doesn't (or `.server-stopped` exists), the server has shut down — restart it with `start-server.sh` before continuing. The server auto-exits after 30 minutes of inactivity.
------------++   - Before each write, check that `$STATE_DIR/server-info` exists. If it doesn't (or `$STATE_DIR/server-stopped` exists), the server has shut down — restart it with `start-server.sh` before continuing. The server auto-exits after 30 minutes of inactivity.
------------+    - Use semantic filenames: `platform.html`, `visual-style.html`, `layout.html`
------------+    - **Never reuse filenames** — each screen gets a fresh file
------------+    - Use Write tool — **never use cat/heredoc** (dumps noise into terminal)
------------+@@ -105,9 +106,9 @@ Use `--url-host` to control what hostname is printed in the returned URL JSON.
------------+    - Ask them to respond in the terminal: "Take a look and let me know what you think. Click to select an option if you'd like."
------------  
------------- Add to your Codex config (`~/.codex/config.toml`):
------------+ 3. **On your next turn** — after the user responds in the terminal:
------------+-   - Read `$SCREEN_DIR/.events` if it exists — this contains the user's browser interactions (clicks, selections) as JSON lines
------------++   - Read `$STATE_DIR/events` if it exists — this contains the user's browser interactions (clicks, selections) as JSON lines
------------+    - Merge with the user's terminal text to get the full picture
------------+-   - The terminal message is the primary feedback; `.events` provides structured interaction data
------------++   - The terminal message is the primary feedback; `state_dir/events` provides structured interaction data
------------  
------------- ```toml
------------- [features]
--------------collab = true
-------------+multi_agent = true
------------- ```
------------+ 4. **Iterate or advance** — if feedback changes current screen, write a new file (e.g., `layout-v2.html`). Only move to the next question when the current step is validated.
------------  
------------- This enables `spawn_agent`, `wait`, and `close_agent` for skills like `dispatching-parallel-agents` and `subagent-driven-development`.
-------------diff --git a/skills/superpowers/writing-plans/SKILL.md b/skills/superpowers/writing-plans/SKILL.md
-------------index ed67c5e..60f9834 100644
---------------- a/skills/superpowers/writing-plans/SKILL.md
-------------+++ b/skills/superpowers/writing-plans/SKILL.md
-------------@@ -49,7 +49,7 @@ This structure informs the task decomposition. Each task should produce self-con
------------- ```markdown
------------- # [Feature Name] Implementation Plan
------------+@@ -244,7 +245,7 @@ The frame template provides these CSS classes for your content:
------------  
--------------> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.
-------------+> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
------------+ ## Browser Events Format
------------  
------------- **Goal:** [One sentence describing what this builds]
------------+-When the user clicks options in the browser, their interactions are recorded to `$SCREEN_DIR/.events` (one JSON object per line). The file is cleared automatically when you push a new screen.
------------++When the user clicks options in the browser, their interactions are recorded to `$STATE_DIR/events` (one JSON object per line). The file is cleared automatically when you push a new screen.
------------  
-------------@@ -112,36 +112,34 @@ git commit -m "feat: add specific feature"
------------+ ```jsonl
------------+ {"type":"click","choice":"a","text":"Option A - Simple Layout","timestamp":1706000101}
------------+@@ -254,7 +255,7 @@ When the user clicks options in the browser, their interactions are recorded to
------------  
------------- ## Plan Review Loop
------------+ The full event stream shows the user's exploration path — they may click multiple options before settling. The last `choice` event is typically the final selection, but the pattern of clicks can reveal hesitation or preferences worth asking about.
------------  
--------------After completing each chunk of the plan:
-------------+After writing the complete plan:
------------+-If `.events` doesn't exist, the user didn't interact with the browser — use only their terminal text.
------------++If `$STATE_DIR/events` doesn't exist, the user didn't interact with the browser — use only their terminal text.
------------  
--------------1. Dispatch plan-document-reviewer subagent (see plan-document-reviewer-prompt.md) with precisely crafted review context — never your session history. This keeps the reviewer focused on the plan, not your thought process.
--------------   - Provide: chunk content, path to spec document
--------------2. If ❌ Issues Found:
--------------   - Fix the issues in the chunk
--------------   - Re-dispatch reviewer for that chunk
--------------   - Repeat until ✅ Approved
--------------3. If ✅ Approved: proceed to next chunk (or execution handoff if last chunk)
--------------
--------------**Chunk boundaries:** Use `## Chunk N: <name>` headings to delimit chunks. Each chunk should be ≤1000 lines and logically self-contained.
-------------+1. Dispatch a single plan-document-reviewer subagent (see plan-document-reviewer-prompt.md) with precisely crafted review context — never your session history. This keeps the reviewer focused on the plan, not your thought process.
-------------+   - Provide: path to the plan document, path to spec document
-------------+2. If ❌ Issues Found: fix the issues, re-dispatch reviewer for the whole plan
-------------+3. If ✅ Approved: proceed to execution handoff
------------- 
------------- **Review loop guidance:**
------------- - Same agent that wrote the plan fixes it (preserves context)
--------------- If loop exceeds 5 iterations, surface to human for guidance
--------------- Reviewers are advisory - explain disagreements if you believe feedback is incorrect
-------------+- If loop exceeds 3 iterations, surface to human for guidance
-------------+- Reviewers are advisory — explain disagreements if you believe feedback is incorrect
------------- 
------------- ## Execution Handoff
------------- 
--------------After saving the plan:
-------------+After saving the plan, offer execution choice:
-------------+
-------------+**"Plan complete and saved to `docs/superpowers/plans/<filename>.md`. Two execution options:**
-------------+
-------------+**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration
------------- 
--------------**"Plan complete and saved to `docs/superpowers/plans/<filename>.md`. Ready to execute?"**
-------------+**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints
------------- 
--------------**Execution path depends on harness capabilities:**
-------------+**Which approach?"**
------------+ ## Design Tips
------------  
--------------**If harness has subagents (Claude Code, etc.):**
--------------- **REQUIRED:** Use superpowers:subagent-driven-development
--------------- Do NOT offer a choice - subagent-driven is the standard approach
-------------+**If Subagent-Driven chosen:**
-------------+- **REQUIRED SUB-SKILL:** Use superpowers:subagent-driven-development
------------- - Fresh subagent per task + two-stage review
------------+@@ -275,7 +276,7 @@ If `.events` doesn't exist, the user didn't interact with the browser — use on
------------+ ## Cleaning Up
------------  
--------------**If harness does NOT have subagents:**
--------------- Execute plan in current session using superpowers:executing-plans
-------------+**If Inline Execution chosen:**
-------------+- **REQUIRED SUB-SKILL:** Use superpowers:executing-plans
------------- - Batch execution with checkpoints for review
-------------diff --git a/skills/superpowers/writing-plans/plan-document-reviewer-prompt.md b/skills/superpowers/writing-plans/plan-document-reviewer-prompt.md
-------------index ce36cba..2db2806 100644
---------------- a/skills/superpowers/writing-plans/plan-document-reviewer-prompt.md
-------------+++ b/skills/superpowers/writing-plans/plan-document-reviewer-prompt.md
-------------@@ -2,17 +2,17 @@
------------- 
------------- Use this template when dispatching a plan document reviewer subagent.
------------- 
--------------**Purpose:** Verify the plan chunk is complete, matches the spec, and has proper task decomposition.
-------------+**Purpose:** Verify the plan is complete, matches the spec, and has proper task decomposition.
------------- 
--------------**Dispatch after:** Each plan chunk is written
-------------+**Dispatch after:** The complete plan is written.
------------+ ```bash
------------+-scripts/stop-server.sh $SCREEN_DIR
------------++scripts/stop-server.sh $SESSION_DIR
------------+ ```
------------  
------------+ If the session used `--project-dir`, mockup files persist in `.superpowers/brainstorm/` for later reference. Only `/tmp` sessions get deleted on stop.
------------+diff --git a/skills/superpowers/using-superpowers/references/codex-tools.md b/skills/superpowers/using-superpowers/references/codex-tools.md
------------+index 86f58fa..539b2b1 100644
------------+--- a/skills/superpowers/using-superpowers/references/codex-tools.md
------------++++ b/skills/superpowers/using-superpowers/references/codex-tools.md
------------+@@ -4,7 +4,7 @@ Skills use Claude Code tool names. When you encounter these in a skill, use your
------------+ 
------------+ | Skill references | Codex equivalent |
------------+ |-----------------|------------------|
------------+-| `Task` tool (dispatch subagent) | `spawn_agent` |
------------++| `Task` tool (dispatch subagent) | `spawn_agent` (see [Named agent dispatch](#named-agent-dispatch)) |
------------+ | Multiple `Task` calls (parallel) | Multiple `spawn_agent` calls |
------------+ | Task returns result | `wait` |
------------+ | Task completes automatically | `close_agent` to free slot |
------------+@@ -23,3 +23,78 @@ multi_agent = true
------------  ```
------------- Task tool (general-purpose):
--------------  description: "Review plan chunk N"
-------------+  description: "Review plan document"
-------------   prompt: |
--------------    You are a plan document reviewer. Verify this plan chunk is complete and ready for implementation.
-------------+    You are a plan document reviewer. Verify this plan is complete and ready for implementation.
------------- 
--------------    **Plan chunk to review:** [PLAN_FILE_PATH] - Chunk N only
-------------+    **Plan to review:** [PLAN_FILE_PATH]
-------------     **Spec for reference:** [SPEC_FILE_PATH]
------------- 
-------------     ## What to Check
-------------@@ -20,33 +20,30 @@ Task tool (general-purpose):
-------------     | Category | What to Look For |
-------------     |----------|------------------|
-------------     | Completeness | TODOs, placeholders, incomplete tasks, missing steps |
--------------    | Spec Alignment | Chunk covers relevant spec requirements, no scope creep |
--------------    | Task Decomposition | Tasks atomic, clear boundaries, steps actionable |
--------------    | File Structure | Files have clear single responsibilities, split by responsibility not layer |
--------------    | File Size | Would any new or modified file likely grow large enough to be hard to reason about as a whole? |
--------------    | Task Syntax | Checkbox syntax (`- [ ]`) on steps for tracking |
--------------    | Chunk Size | Each chunk under 1000 lines |
--------------
--------------    ## CRITICAL
--------------
--------------    Look especially hard for:
--------------    - Any TODO markers or placeholder text
--------------    - Steps that say "similar to X" without actual content
--------------    - Incomplete task definitions
--------------    - Missing verification steps or expected outputs
--------------    - Files planned to hold multiple responsibilities or likely to grow unwieldy
-------------+    | Spec Alignment | Plan covers spec requirements, no major scope creep |
-------------+    | Task Decomposition | Tasks have clear boundaries, steps are actionable |
-------------+    | Buildability | Could an engineer follow this plan without getting stuck? |
------------+ 
------------+ This enables `spawn_agent`, `wait`, and `close_agent` for skills like `dispatching-parallel-agents` and `subagent-driven-development`.
------------ +
-------------+    ## Calibration
------------++## Named agent dispatch
------------ +
-------------+    **Only flag issues that would cause real problems during implementation.**
-------------+    An implementer building the wrong thing or getting stuck is an issue.
-------------+    Minor wording, stylistic preferences, and "nice to have" suggestions are not.
------------++Claude Code skills reference named agent types like `superpowers:code-reviewer`.
------------++Codex does not have a named agent registry — `spawn_agent` creates generic agents
------------++from built-in roles (`default`, `explorer`, `worker`).
------------ +
-------------+    Approve unless there are serious gaps — missing requirements from the spec,
-------------+    contradictory steps, placeholder content, or tasks so vague they can't be acted on.
------------- 
-------------     ## Output Format
------------- 
--------------    ## Plan Review - Chunk N
-------------+    ## Plan Review
------------- 
-------------     **Status:** Approved | Issues Found
------------++When a skill says to dispatch a named agent type:
------------++
------------++1. Find the agent's prompt file (e.g., `agents/code-reviewer.md` or the skill's
------------++   local prompt template like `code-quality-reviewer-prompt.md`)
------------++2. Read the prompt content
------------++3. Fill any template placeholders (`{BASE_SHA}`, `{WHAT_WAS_IMPLEMENTED}`, etc.)
------------++4. Spawn a `worker` agent with the filled content as the `message`
------------++
------------++| Skill instruction | Codex equivalent |
------------++|-------------------|------------------|
------------++| `Task tool (superpowers:code-reviewer)` | `spawn_agent(agent_type="worker", message=...)` with `code-reviewer.md` content |
------------++| `Task tool (general-purpose)` with inline prompt | `spawn_agent(message=...)` with the same prompt |
------------++
------------++### Message framing
------------++
------------++The `message` parameter is user-level input, not a system prompt. Structure it
------------++for maximum instruction adherence:
------------++
------------++```
------------++Your task is to perform the following. Follow the instructions below exactly.
------------++
------------++<agent-instructions>
------------++[filled prompt content from the agent's .md file]
------------++</agent-instructions>
------------++
------------++Execute this now. Output ONLY the structured response following the format
------------++specified in the instructions above.
------------++```
------------++
------------++- Use task-delegation framing ("Your task is...") rather than persona framing ("You are...")
------------++- Wrap instructions in XML tags — the model treats tagged blocks as authoritative
------------++- End with an explicit execution directive to prevent summarization of the instructions
------------++
------------++### When this workaround can be removed
------------++
------------++This approach compensates for Codex's plugin system not yet supporting an `agents`
------------++field in `plugin.json`. When `RawPluginManifest` gains an `agents` field, the
------------++plugin can symlink to `agents/` (mirroring the existing `skills/` symlink) and
------------++skills can dispatch named agent types directly.
------------++
------------++## Environment Detection
------------++
------------++Skills that create worktrees or finish branches should detect their
------------++environment with read-only git commands before proceeding:
------------++
------------++```bash
------------++GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
------------++GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
------------++BRANCH=$(git branch --show-current)
------------++```
------------++
------------++- `GIT_DIR != GIT_COMMON` → already in a linked worktree (skip creation)
------------++- `BRANCH` empty → detached HEAD (cannot branch/push/PR from sandbox)
------------++
------------++See `using-git-worktrees` Step 0 and `finishing-a-development-branch`
------------++Step 1 for how each skill uses these signals.
------------++
------------++## Codex App Finishing
------------++
------------++When the sandbox blocks branch/push operations (detached HEAD in an
------------++externally managed worktree), the agent commits all work and informs
------------++the user to use the App's native controls:
------------++
------------++- **"Create branch"** — names the branch, then commit/push/PR via App UI
------------++- **"Hand off to local"** — transfers work to the user's local checkout
------------++
------------++The agent can still run tests, stage files, and output suggested branch
------------++names, commit messages, and PR descriptions for the user to copy.
------------+diff --git a/skills/superpowers/writing-plans/SKILL.md b/skills/superpowers/writing-plans/SKILL.md
------------+index 60f9834..0d9c00b 100644
------------+--- a/skills/superpowers/writing-plans/SKILL.md
------------++++ b/skills/superpowers/writing-plans/SKILL.md
------------+@@ -103,26 +103,33 @@ git commit -m "feat: add specific feature"
------------+ ```
------------+ ````
------------  
-------------     **Issues (if any):**
--------------    - [Task X, Step Y]: [specific issue] - [why it matters]
-------------+    - [Task X, Step Y]: [specific issue] - [why it matters for implementation]
------------++## No Placeholders
------------++
------------++Every step must contain the actual content an engineer needs. These are **plan failures** — never write them:
------------++- "TBD", "TODO", "implement later", "fill in details"
------------++- "Add appropriate error handling" / "add validation" / "handle edge cases"
------------++- "Write tests for the above" (without actual test code)
------------++- "Similar to Task N" (repeat the code — the engineer may be reading tasks out of order)
------------++- Steps that describe what to do without showing how (code blocks required for code steps)
------------++- References to types, functions, or methods not defined in any task
------------++
------------+ ## Remember
------------+ - Exact file paths always
------------+-- Complete code in plan (not "add validation")
------------++- Complete code in every step — if a step changes code, show the code
------------+ - Exact commands with expected output
------------+-- Reference relevant skills with @ syntax
------------+ - DRY, YAGNI, TDD, frequent commits
------------+ 
------------+-## Plan Review Loop
------------++## Self-Review
------------++
------------++After writing the complete plan, look at the spec with fresh eyes and check the plan against it. This is a checklist you run yourself — not a subagent dispatch.
------------++
------------++**1. Spec coverage:** Skim each section/requirement in the spec. Can you point to a task that implements it? List any gaps.
------------  
--------------    **Recommendations (advisory):**
--------------    - [suggestions that don't block approval]
-------------+    **Recommendations (advisory, do not block approval):**
-------------+    - [suggestions for improvement]
------------- ```
------------+-After writing the complete plan:
------------++**2. Placeholder scan:** Search your plan for red flags — any of the patterns from the "No Placeholders" section above. Fix them.
------------  
------------- **Reviewer returns:** Status, Issues (if any), Recommendations
------------+-1. Dispatch a single plan-document-reviewer subagent (see plan-document-reviewer-prompt.md) with precisely crafted review context — never your session history. This keeps the reviewer focused on the plan, not your thought process.
------------+-   - Provide: path to the plan document, path to spec document
------------+-2. If ❌ Issues Found: fix the issues, re-dispatch reviewer for the whole plan
------------+-3. If ✅ Approved: proceed to execution handoff
------------++**3. Type consistency:** Do the types, m
------------\ No newline at end of file
------+  > Merge pull request #143 from tgonzalezc5/feat/exa-search-skill
------+diff --git a/skills/superpowers/executing-plans/SKILL.md b/skills/superpowers/executing-plans/SKILL.md
------+index e67f94c..a591862 100644
------+--- a/skills/superpowers/executing-plans/SKILL.md
------++++ b/skills/superpowers/executing-plans/SKILL.md
------+@@ -65,6 +65,6 @@ After all tasks complete and verified:
------+ ## Integration
------+ 
------+ **Required workflow skills:**
------+-- **superpowers:using-git-worktrees** - REQUIRED: Set up isolated workspace before starting
------++- **superpowers:using-git-worktrees** - Ensures isolated workspace (creates one or verifies existing)
------+ - **superpowers:writing-plans** - Creates the plan this skill executes
------+ - **superpowers:finishing-a-development-branch** - Complete development after all tasks
------+diff --git a/skills/superpowers/finishing-a-development-branch/SKILL.md b/skills/superpowers/finishing-a-development-branch/SKILL.md
------+index c308b43..43da0ae 100644
------+--- a/skills/superpowers/finishing-a-development-branch/SKILL.md
------++++ b/skills/superpowers/finishing-a-development-branch/SKILL.md
------+@@ -9,7 +9,7 @@ description: Use when implementation is complete, all tests pass, and you need t
------+ 
------+ Guide completion of development work by presenting clear options and handling chosen workflow.
------+ 
------+-**Core principle:** Verify tests → Present options → Execute choice → Clean up.
------++**Core principle:** Verify tests → Detect environment → Present options → Execute choice → Clean up.
------+ 
------+ **Announce at start:** "I'm using the finishing-a-development-branch skill to complete this work."
------+ 
------+@@ -37,7 +37,24 @@ Stop. Don't proceed to Step 2.
------+ 
------+ **If tests pass:** Continue to Step 2.
------+ 
------+-### Step 2: Determine Base Branch
------++### Step 2: Detect Environment
------++
------++**Determine workspace state before presenting options:**
------++
------++```bash
------++GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
------++GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
------++```
------++
------++This determines which menu to show and how cleanup works:
------++
------++| State | Menu | Cleanup |
------++|-------|------|---------|
------++| `GIT_DIR == GIT_COMMON` (normal repo) | Standard 4 options | No worktree to clean up |
------++| `GIT_DIR != GIT_COMMON`, named branch | Standard 4 options | Provenance-based (see Step 6) |
------++| `GIT_DIR != GIT_COMMON`, detached HEAD | Reduced 3 options (no merge) | No cleanup (externally managed) |
------++
------++### Step 3: Determine Base Branch
------+ 
------+ ```bash
------+ # Try common base branches
------+@@ -46,9 +63,9 @@ git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
------+ 
------+ Or ask: "This branch split from main - is that correct?"
------+ 
------+-### Step 3: Present Options
------++### Step 4: Present Options
------+ 
------+-Present exactly these 4 options:
------++**Normal repo and named-branch worktree — present exactly these 4 options:**
------+ 
------+ ```
------+ Implementation complete. What would you like to do?
------+@@ -61,30 +78,45 @@ Implementation complete. What would you like to do?
------+ Which option?
------+ ```
------+ 
------++**Detached HEAD — present exactly these 3 options:**
------++
------++```
------++Implementation complete. You're on a detached HEAD (externally managed workspace).
------++
------++1. Push as new branch and create a Pull Request
------++2. Keep as-is (I'll handle it later)
------++3. Discard this work
------++
------++Which option?
------++```
------++
------+ **Don't add explanation** - keep options concise.
------+ 
------+-### Step 4: Execute Choice
------++### Step 5: Execute Choice
------+ 
------+ #### Option 1: Merge Locally
------+ 
------+ ```bash
------+-# Switch to base branch
------+-git checkout <base-branch>
------++# Get main repo root for CWD safety
------++MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
------++cd "$MAIN_ROOT"
------+ 
------+-# Pull latest
------++# Merge first — verify success before removing anything
------++git checkout <base-branch>
------+ git pull
------+-
------+-# Merge feature branch
------+ git merge <feature-branch>
------+ 
------+ # Verify tests on merged result
------+ <test command>
------+ 
------+-# If tests pass
------+-git branch -d <feature-branch>
------++# Only after merge succeeds: cleanup worktree (Step 6), then delete branch
------+ ```
------+ 
------+-Then: Cleanup worktree (Step 5)
------++Then: Cleanup worktree (Step 6), then delete branch:
------++
------++```bash
------++git branch -d <feature-branch>
------++```
------+ 
------+ #### Option 2: Push and Create PR
------+ 
------+@@ -103,7 +135,7 @@ EOF
------+ )"
------+ ```
------+ 
------+-Then: Cleanup worktree (Step 5)
------++**Do NOT clean up worktree** — user needs it alive to iterate on PR feedback.
------+ 
------+ #### Option 3: Keep As-Is
------+ 
------+@@ -127,36 +159,46 @@ Wait for exact confirmation.
------+ 
------+ If confirmed:
------+ ```bash
------+-git checkout <base-branch>
------+-git branch -D <feature-branch>
------++MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
------++cd "$MAIN_ROOT"
------+ ```
------+ 
------+-Then: Cleanup worktree (Step 5)
------++Then: Cleanup worktree (Step 6), then force-delete branch:
------++```bash
------++git branch -D <feature-branch>
------++```
------+ 
------+-### Step 5: Cleanup Worktree
------++### Step 6: Cleanup Workspace
------+ 
------+-**For Options 1, 2, 4:**
------++**Only runs for Options 1 and 4.** Options 2 and 3 always preserve the worktree.
------+ 
------+-Check if in worktree:
------+ ```bash
------+-git worktree list | grep $(git branch --show-current)
------++GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
------++GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
------++WORKTREE_PATH=$(git rev-parse --show-toplevel)
------+ ```
------+ 
------+-If yes:
------++**If `GIT_DIR == GIT_COMMON`:** Normal repo, no worktree to clean up. Done.
------++
------++**If worktree path is under `.worktrees/`, `worktrees/`, or `~/.config/superpowers/worktrees/`:** Superpowers created this worktree — we own cleanup.
------++
------+ ```bash
------+-git worktree remove <worktree-path>
------++MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
------++cd "$MAIN_ROOT"
------++git worktree remove "$WORKTREE_PATH"
------++git worktree prune  # Self-healing: clean up any stale registrations
------+ ```
------+ 
------+-**For Option 3:** Keep worktree.
------++**Otherwise:** The host environment (harness) owns this workspace. Do NOT remove it. If your platform provides a workspace-exit tool, use it. Otherwise, leave the workspace in place.
------+ 
------+ ## Quick Reference
------+ 
------+ | Option | Merge | Push | Keep Worktree | Cleanup Branch |
------+ |--------|-------|------|---------------|----------------|
------+-| 1. Merge locally | ✓ | - | - | ✓ |
------+-| 2. Create PR | - | ✓ | ✓ | - |
------+-| 3. Keep as-is | - | - | ✓ | - |
------+-| 4. Discard | - | - | - | ✓ (force) |
------++| 1. Merge locally | yes | - | - | yes |
------++| 2. Create PR | - | yes | yes | - |
------++| 3. Keep as-is | - | - | yes | - |
------++| 4. Discard | - | - | - | yes (force) |
------+ 
------+ ## Common Mistakes
------+ 
------+@@ -165,13 +207,25 @@ git worktree remove <worktree-path>
------+ - **Fix:** Always verify tests before offering options
------+ 
------+ **Open-ended questions**
------+-- **Problem:** "What should I do next?" → ambiguous
------+-- **Fix:** Present exactly 4 structured options
------++- **Problem:** "What should I do next?" is ambiguous
------++- **Fix:** Present exactly 4 structured options (or 3 for detached HEAD)
------+ 
------+-**Automatic worktree cleanup**
------+-- **Problem:** Remove worktree when might need it (Option 2, 3)
------++**Cleaning up worktree for Option 2**
------++- **Problem:** Remove worktree user needs for PR iteration
------+ - **Fix:** Only cleanup for Options 1 and 4
------+ 
------++**Deleting branch before removing worktree**
------++- **Problem:** `git branch -d` fails because worktree still references the branch
------++- **Fix:** Merge first, remove worktree, then delete branch
------++
------++**Running git worktree remove from inside the worktree**
------++- **Problem:** Command fails silently when CWD is inside the worktree being removed
------++- **Fix:** Always `cd` to main repo root before `git worktree remove`
------++
------++**Cleaning up harness-owned worktrees**
------++- **Problem:** Removing a worktree the harness created causes phantom state
------++- **Fix:** Only clean up worktrees under `.worktrees/`, `worktrees/`, or `~/.config/superpowers/worktrees/`
------++
------+ **No confirmation for discard**
------+ - **Problem:** Accidentally delete work
------+ - **Fix:** Require typed "discard" confirmation
------+@@ -183,18 +237,15 @@ git worktree remove <worktree-path>
------+ - Merge without verifying tests on result
------+ - Delete work without confirmation
------+ - Force-push without explicit request
------++- Remove a worktree before confirming merge success
------++- Clean up worktrees you didn't create (provenance check)
------++- Run `git worktree remove` from inside the worktree
------+ 
------+ **Always:**
------+ - Verify tests before offering options
------+-- Present exactly 4 options
------++- Detect environment before presenting menu
------++- Present exactly 4 options (or 3 for detached HEAD)
------+ - Get typed confirmation for Option 4
------+ - Clean up worktree for Options 1 & 4 only
------+-
------+-## Integration
------+-
------+-**Called by:**
------+-- **subagent-driven-development** (Step 7) - After all tasks complete
------+-- **executing-plans** (Step 5) - After all batches complete
------+-
------+-**Pairs with:**
------+-- **using-git-worktrees** - Cleans up worktree created by that skill
------++- `cd` to main repo root before worktree removal
------++- Run `git worktree prune` after removal
------+diff --git a/skills/superpowers/requesting-code-review/SKILL.md b/skills/superpowers/requesting-code-review/SKILL.md
------+index fe7c8d9..34b8340 100644
------+--- a/skills/superpowers/requesting-code-review/SKILL.md
------++++ b/skills/superpowers/requesting-code-review/SKILL.md
------+@@ -5,7 +5,7 @@ description: Use when completing tasks, implementing major features, or before m
------+ 
------+ # Requesting Code Review
------+ 
------+-Dispatch superpowers:code-reviewer subagent to catch issues before they cascade. The reviewer gets precisely crafted context for evaluation — never your session's history. This keeps the reviewer focused on the work product, not your thought process, and preserves your own context for continued work.
------++Dispatch a code reviewer subagent to catch issues before they cascade. The reviewer gets precisely crafted context for evaluation — never your session's history. This keeps the reviewer focused on the work product, not your thought process, and preserves your own context for continued work.
------+ 
------+ **Core principle:** Review early, review often.
------+ 
------+@@ -29,16 +29,15 @@ BASE_SHA=$(git rev-parse HEAD~1)  # or origin/main
------+ HEAD_SHA=$(git rev-parse HEAD)
------+ ```
------+ 
------+-**2. Dispatch code-reviewer subagent:**
------++**2. Dispatch code reviewer subagent:**
------+ 
------+-Use Task tool with superpowers:code-reviewer type, fill template at `code-reviewer.md`
------++Use Task tool with `general-purpose` type, fill template at `code-reviewer.md`
------+ 
------+ **Placeholders:**
------+-- `{WHAT_WAS_IMPLEMENTED}` - What you just built
------++- `{DESCRIPTION}` - Brief summary of what you built
------+ - `{PLAN_OR_REQUIREMENTS}` - What it should do
------+ - `{BASE_SHA}` - Starting commit
------+ - `{HEAD_SHA}` - Ending commit
------+-- `{DESCRIPTION}` - Brief summary
------+ 
------+ **3. Act on feedback:**
------+ - Fix Critical issues immediately
------+@@ -56,12 +55,11 @@ You: Let me request code review before proceeding.
------+ BASE_SHA=$(git log --oneline | grep "Task 1" | head -1 | awk '{print $1}')
------+ HEAD_SHA=$(git rev-parse HEAD)
------+ 
------+-[Dispatch superpowers:code-reviewer subagent]
------+-  WHAT_WAS_IMPLEMENTED: Verification and repair functions for conversation index
------++[Dispatch code reviewer subagent]
------++  DESCRIPTION: Added verifyIndex() and repairIndex() with 4 issue types
------+   PLAN_OR_REQUIREMENTS: Task 2 from docs/superpowers/plans/deployment-plan.md
------+   BASE_SHA: a7981ec
------+   HEAD_SHA: 3df7661
------+-  DESCRIPTION: Added verifyIndex() and repairIndex() with 4 issue types
------+ 
------+ [Subagent returns]:
------+   Strengths: Clean architecture, real tests
------+@@ -82,7 +80,7 @@ You: [Fix progress indicators]
------+ - Fix before moving to next task
------+ 
------+ **Executing Plans:**
------+-- Review after each batch (3 tasks)
------++- Review after each task or at natural checkpoints
------+ - Get feedback, apply, continue
------+ 
------+ **Ad-Hoc Development:**
------+diff --git a/skills/superpowers/requesting-code-review/code-reviewer.md b/skills/superpowers/requesting-code-review/code-reviewer.md
------+index 3c427c9..525e4b4 100644
------+--- a/skills/superpowers/requesting-code-review/code-reviewer.md
------++++ b/skills/superpowers/requesting-code-review/code-reviewer.md
------+@@ -1,111 +1,133 @@
------+-# Code Review Agent
------++# Code Reviewer Prompt Template
------+ 
------+-You are reviewing code changes for production readiness.
------++Use this template when dispatching a code reviewer subagent.
------+ 
------+-**Your task:**
------+-1. Review {WHAT_WAS_IMPLEMENTED}
------+-2. Compare against {PLAN_OR_REQUIREMENTS}
------+-3. Check code quality, architecture, testing
------+-4. Categorize issues by severity
------+-5. Assess production readiness
------++**Purpose:** Review completed work against requirements and code quality standards before it cascades into more work.
------+ 
------+-## What Was Implemented
------++```
------++Task tool (general-purpose):
------++  description: "Review code changes"
------++  prompt: |
------++    You are a Senior Code Reviewer with expertise in software architecture,
------++    design patterns, and best practices. Your job is to review completed work
------++    against its plan or requirements and identify issues before they cascade.
------+ 
------+-{DESCRIPTION}
------++    ## What Was Implemented
------+ 
------+-## Requirements/Plan
------++    {DESCRIPTION}
------+ 
------+-{PLAN_REFERENCE}
------++    ## Requirements / Plan
------+ 
------+-## Git Range to Review
------++    {PLAN_OR_REQUIREMENTS}
------+ 
------+-**Base:** {BASE_SHA}
------+-**Head:** {HEAD_SHA}
------++    ## Git Range to Review
------+ 
------+-```bash
------+-git diff --stat {BASE_SHA}..{HEAD_SHA}
------+-git diff {BASE_SHA}..{HEAD_SHA}
------+-```
------++    **Base:** {BASE_SHA}
------++    **Head:** {HEAD_SHA}
------+ 
------+-## Review Checklist
------+-
------+-**Code Quality:**
------+-- Clean separation of concerns?
------+-- Proper error handling?
------+-- Type safety (if applicable)?
------+-- DRY principle followed?
------+-- Edge cases handled?
------+-
------+-**Architecture:**
------+-- Sound design decisions?
------+-- Scalability considerations?
------+-- Performance implications?
------+-- Security concerns?
------+-
------+-**Testing:**
------+-- Tests actually test logic (not mocks)?
------+-- Edge cases covered?
------+-- Integration tests where needed?
------+-- All tests passing?
------+-
------+-**Requirements:**
------+-- All plan requirements met?
------+-- Implementation matches spec?
------+-- No scope creep?
------+-- Breaking changes documented?
------+-
------+-**Production Readiness:**
------+-- Migration strategy (if schema changes)?
------+-- Backward compatibility considered?
------+-- Documentation complete?
------+-- No obvious bugs?
------+-
------+-## Output Format
------++    ```bash
------++    git diff --stat {BASE_SHA}..{HEAD_SHA}
------++    git diff {BASE_SHA}..{HEAD_SHA}
------++    ```
------+ 
------+-### Strengths
------+-[What's well done? Be specific.]
------++    ## What to Check
------+ 
------+-### Issues
------++    **Plan alignment:**
------++    - Does the implementation match the plan / requirements?
------++    - Are deviations justified improvements, or problematic departures?
------++    - Is all planned functionality present?
------+ 
------+-#### Critical (Must Fix)
------+-[Bugs, security issues, data loss risks, broken functionality]
------++    **Code quality:**
------++    - Clean separation of concerns?
------++    - Proper error handling?
------++    - Type safety where applicable?
------++    - DRY without premature abstraction?
------++    - Edge cases handled?
------+ 
------+-#### Important (Should Fix)
------+-[Architecture problems, missing features, poor error handling, test gaps]
------++    **Architecture:**
------++    - Sound design decisions?
------++    - Reasonable scalability and performance?
------++    - Security concerns?
------++    - Integrates cleanly with surrounding code?
------+ 
------+-#### Minor (Nice to Have)
------+-[Code style, optimization opportunities, documentation improvements]
------++    **Testing:**
------++    - Tests verify real behavior, not mocks?
------++    - Edge cases covered?
------++    - Integration tests where they matter?
------++    - All tests passing?
------+ 
------+-**For each issue:**
------+-- File:line reference
------+-- What's wrong
------+-- Why it matters
------+-- How to fix (if not obvious)
------++    **Production readiness:**
------++    - Migration strategy if schema changed?
------++    - Backward compatibility considered?
------++    - Documentation complete?
------++    - No obvious bugs?
------+ 
------+-### Recommendations
------+-[Improvements for code quality, architecture, or process]
------++    ## Calibration
------+ 
------+-### Assessment
------++    Categorize issues by actual severity. Not everything is Critical.
------++    Acknowledge what was done well before listing issues — accurate praise
------++    helps the implementer trust the rest of the feedback.
------++
------++    If you find significant deviations from the plan, flag them specifically
------++    so the implementer can confirm whether the deviation was intentional.
------++    If you find issues with the plan itself rather than the implementation,
------++    say so.
------++
------++    ## Output Format
------++
------++    ### Strengths
------++    [What's well done? Be specific.]
------++
------++    ### Issues
------+ 
------+-**Ready to merge?** [Yes/No/With fixes]
------++    #### Critical (Must Fix)
------++    [Bugs, security issues, data loss risks, broken functionality]
------+ 
------+-**Reasoning:** [Technical assessment in 1-2 sentences]
------++    #### Important (Should Fix)
------++    [Architecture problems, missing features, poor error handling, test gaps]
------+ 
------+-## Critical Rules
------++    #### Minor (Nice to Have)
------++    [Code style, optimization opportunities, documentation polish]
------++
------++    For each issue:
------++    - File:line reference
------++    - What's wrong
------++    - Why it matters
------++    - How to fix (if not obvious)
------++
------++    ### Recommendations
------++    [Improvements for code quality, architecture, or process]
------++
------++    ### Assessment
------++
------++    **Ready to merge?** [Yes | No | With fixes]
------++
------++    **Reasoning:** [1-2 sentence technical assessment]
------++
------++    ## Critical Rules
------++
------++    **DO:**
------++    - Categorize by actual severity
------++    - Be specific (file:line, not vague)
------++    - Explain WHY each issue matters
------++    - Acknowledge strengths
------++    - Give a clear verdict
------++
------++    **DON'T:**
------++    - Say "looks good" without checking
------++    - Mark nitpicks as Critical
------++    - Give feedback on code you didn't actually read
------++    - Be vague ("improve error handling")
------++    - Avoid giving a clear verdict
------++```
------+ 
------+-**DO:**
------+-- Categorize by actual severity (not everything is Critical)
------+-- Be specific (file:line, not vague)
------+-- Explain WHY issues matter
------+-- Acknowledge strengths
------+-- Give clear verdict
------++**Placeholders:**
------++- `{DESCRIPTION}` — brief summary of what was built
------++- `{PLAN_OR_REQUIREMENTS}` — what it should do (plan file path, task text, or requirements)
------++- `{BASE_SHA}` — starting commit
------++- `{HEAD_SHA}` — ending commit
------+ 
------+-**DON'T:**
------+-- Say "looks good" without checking
------+-- Mark nitpicks as Critical
------+-- Give feedback on code you didn't review
------+-- Be vague ("improve error handling")
------+-- Avoid giving a clear verdict
------++**Reviewer returns:** Strengths, Issues (Critical / Important / Minor), Recommendations, Assessment
------+ 
------+ ## Example Output
------+ 
------+diff --git a/skills/superpowers/subagent-driven-development/SKILL.md b/skills/superpowers/subagent-driven-development/SKILL.md
------+index 5150b18..ea7ac8f 100644
------+--- a/skills/superpowers/subagent-driven-development/SKILL.md
------++++ b/skills/superpowers/subagent-driven-development/SKILL.md
------+@@ -11,6 +11,8 @@ Execute plan by dispatching fresh subagent per task, with two-stage review after
------+ 
------+ **Core principle:** Fresh subagent per task + two-stage review (spec then quality) = high quality, fast iteration
------+ 
------++**Continuous execution:** Do not pause to check in with your human partner between tasks. Execute all tasks from the plan without stopping. The only reasons to stop are: BLOCKED status you cannot resolve, ambiguity that genuinely prevents progress, or all tasks complete. "Should I continue?" prompts and progress summaries waste their time — they asked you to execute the plan, so execute it.
------++
------+ ## When to Use
------+ 
------+ ```dot
------+@@ -265,7 +267,7 @@ Done!
------+ ## Integration
------+ 
------+ **Required workflow skills:**
------+-- **superpowers:using-git-worktrees** - REQUIRED: Set up isolated workspace before starting
------++- **superpowers:using-git-worktrees** - Ensures isolated workspace (creates one or verifies existing)
------+ - **superpowers:writing-plans** - Creates the plan this skill executes
------+ - **superpowers:requesting-code-review** - Code review template for reviewer subagents
------+ - **superpowers:finishing-a-development-branch** - Complete development after all tasks
------+diff --git a/skills/superpowers/subagent-driven-development/code-quality-reviewer-prompt.md b/skills/superpowers/subagent-driven-development/code-quality-reviewer-prompt.md
------+index a04201a..51f901a 100644
------+--- a/skills/superpowers/subagent-driven-development/code-quality-reviewer-prompt.md
------++++ b/skills/superpowers/subagent-driven-development/code-quality-reviewer-prompt.md
------+@@ -7,14 +7,13 @@ Use this template when dispatching a code quality reviewer subagent.
------+ **Only dispatch after spec compliance review passes.**
------+ 
------+ ```
------+-Task tool (superpowers:code-reviewer):
------++Task tool (general-purpose):
------+   Use template at requesting-code-review/code-reviewer.md
------+ 
------+-  WHAT_WAS_IMPLEMENTED: [from implementer's report]
------++  DESCRIPTION: [task summary, from implementer's report]
------+   PLAN_OR_REQUIREMENTS: Task N from [plan-file]
------+   BASE_SHA: [commit before task]
------+   HEAD_SHA: [current commit]
------+-  DESCRIPTION: [task summary]
------+ ```
------+ 
------+ **In addition to standard code quality concerns, the reviewer should check:**
------+diff --git a/skills/superpowers/systematic-debugging/CREATION-LOG.md b/skills/superpowers/systematic-debugging/CREATION-LOG.md
------+index 024d00a..9aa0309 100644
------+--- a/skills/superpowers/systematic-debugging/CREATION-LOG.md
------++++ b/skills/superpowers/systematic-debugging/CREATION-LOG.md
------+@@ -4,7 +4,7 @@ Reference example of extracting, structuring, and bulletproofing a critical skil
------+ 
------+ ## Source Material
------+ 
------+-Extracted debugging framework from `/Users/jesse/.claude/CLAUDE.md`:
------++Extracted debugging framework from `~/.claude/CLAUDE.md`:
------+ - 4-phase systematic process (Investigation → Pattern Analysis → Hypothesis → Implementation)
------+ - Core mandate: ALWAYS find root cause, NEVER fix symptoms
------+ - Rules designed to resist time pressure and rationalization
------+diff --git a/skills/superpowers/systematic-debugging/root-cause-tracing.md b/skills/superpowers/systematic-debugging/root-cause-tracing.md
------+index 9484774..12ef522 100644
------+--- a/skills/superpowers/systematic-debugging/root-cause-tracing.md
------++++ b/skills/superpowers/systematic-debugging/root-cause-tracing.md
------+@@ -33,7 +33,7 @@ digraph when_to_use {
------+ 
------+ ### 1. Observe the Symptom
------+ ```
------+-Error: git init failed in /Users/jesse/project/packages/core
------++Error: git init failed in ~/project/packages/core
------+ ```
------+ 
------+ ### 2. Find Immediate Cause
------+diff --git a/skills/superpowers/using-git-worktrees/SKILL.md b/skills/superpowers/using-git-worktrees/SKILL.md
------+index e153843..134d371 100644
------+--- a/skills/superpowers/using-git-worktrees/SKILL.md
------++++ b/skills/superpowers/using-git-worktrees/SKILL.md
------+@@ -1,104 +1,117 @@
------+ ---
------+ name: using-git-worktrees
------+-description: Use when starting feature work that needs isolation from current workspace or before executing implementation plans - creates isolated git worktrees with smart directory selection and safety verification
------++description: Use when starting feature work that needs isolation from current workspace or before executing implementation plans - ensures an isolated workspace exists via native tools or git worktree fallback
------+ ---
------+ 
------+ # Using Git Worktrees
------+ 
------+ ## Overview
------+ 
------+-Git worktrees create isolated workspaces sharing the same repository, allowing work on multiple branches simultaneously without switching.
------++Ensure work happens in an isolated workspace. Prefer your platform's native worktree tools. Fall back to manual git worktrees only when no native tool is available.
------+ 
------+-**Core principle:** Systematic directory selection + safety verification = reliable isolation.
------++**Core principle:** Detect existing isolation first. Then use native tools. Then fall back to git. Never fight the harness.
------+ 
------+ **Announce at start:** "I'm using the using-git-worktrees skill to set up an isolated workspace."
------+ 
------+-## Directory Selection Process
------++## Step 0: Detect Existing Isolation
------+ 
------+-Follow this priority order:
------+-
------+-### 1. Check Existing Directories
------++**Before creating anything, check if you are already in an isolated workspace.**
------+ 
------+ ```bash
------+-# Check in priority order
------+-ls -d .worktrees 2>/dev/null     # Preferred (hidden)
------+-ls -d worktrees 2>/dev/null      # Alternative
------++GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
------++GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
------++BRANCH=$(git branch --show-current)
------+ ```
------+ 
------+-**If found:** Use that directory. If both exist, `.worktrees` wins.
------+-
------+-### 2. Check CLAUDE.md
------++**Submodule guard:** `GIT_DIR != GIT_COMMON` is also true inside git submodules. Before concluding "already in a worktree," verify you are not in a submodule:
------+ 
------+ ```bash
------+-grep -i "worktree.*director" CLAUDE.md 2>/dev/null
------++# If this returns a path, you're in a submodule, not a worktree — treat as normal repo
------++git rev-parse --show-superproject-working-tree 2>/dev/null
------+ ```
------+ 
------+-**If preference specified:** Use it without asking.
------++**If `GIT_DIR != GIT_COMMON` (and not a submodule):** You are already in a linked worktree. Skip to Step 3 (Project Setup). Do NOT create another worktree.
------+ 
------+-### 3. Ask User
------++Report with branch state:
------++- On a branch: "Already in isolated workspace at `<path>` on branch `<name>`."
------++- Detached HEAD: "Already in isolated workspace at `<path>` (detached HEAD, externally managed). Branch creation needed at finish time."
------+ 
------+-If no directory exists and no CLAUDE.md preference:
------++**If `GIT_DIR == GIT_COMMON` (or in a submodule):** You are in a normal repo checkout.
------+ 
------+-```
------+-No worktree directory found. Where should I create worktrees?
------++Has the user already indicated their worktree preference in your instructions? If not, ask for consent before creating a worktree:
------+ 
------+-1. .worktrees/ (project-local, hidden)
------+-2. ~/.config/superpowers/worktrees/<project-name>/ (global location)
------++> "Would you like me to set up an isolated worktree? It protects your current branch from changes."
------+ 
------+-Which would you prefer?
------+-```
------++Honor any existing declared preference without asking. If the user declines consent, work in place and skip to Step 3.
------++
------++## Step 1: Create Isolated Workspace
------++
------++**You have two mechanisms. Try them in this order.**
------++
------++### 1a. Native Worktree Tools (preferred)
------++
------++The user has asked for an isolated workspace (Step 0 consent). Do you already have a way to create a worktree? It might be a tool with a name like `EnterWorktree`, `WorktreeCreate`, a `/worktree` command, or a `--worktree` flag. If you do, use it and skip to Step 3.
------++
------++Native tools handle directory placement, branch creation, and cleanup automatically. Using `git worktree add` when you have a native tool creates phantom state your harness can't see or manage.
------++
------++Only proceed to Step 1b if you have no native worktree tool available.
------+ 
------+-## Safety Verification
------++### 1b. Git Worktree Fallback
------+ 
------+-### For Project-Local Directories (.worktrees or worktrees)
------++**Only use this if Step 1a does not apply** — you have no native worktree tool available. Create a worktree manually using git.
------++
------++#### Directory Selection
------++
------++Follow this priority order. Explicit user preference always beats observed filesystem state.
------++
------++1. **Check your instructions for a declared worktree directory preference.** If the user has already specified one, use it without asking.
------++
------++2. **Check for an existing project-local worktree directory:**
------++   ```bash
------++   ls -d .worktrees 2>/dev/null     # Preferred (hidden)
------++   ls -d worktrees 2>/dev/null      # Alternative
------++   ```
------++   If found, use it. If both exist, `.worktrees` wins.
------++
------++3. **Check for an existing global directory:**
------++   ```bash
------++   project=$(basename "$(git rev-parse --show-toplevel)")
------++   ls -d ~/.config/superpowers/worktrees/$project 2>/dev/null
------++   ```
------++   If found, use it (backward compatibility with legacy global path).
------++
------++4. **If there is no other guidance available**, default to `.worktrees/` at the project root.
------++
------++#### Safety Verification (project-local directories only)
------+ 
------+ **MUST verify directory is ignored before creating worktree:**
------+ 
------+ ```bash
------+-# Check if directory is ignored (respects local, global, and system gitignore)
------+ git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/dev/null
------+ ```
------+ 
------+-**If NOT ignored:**
------+-
------+-Per Jesse's rule "Fix broken things immediately":
------+-1. Add appropriate line to .gitignore
------+-2. Commit the change
------+-3. Proceed with worktree creation
------++**If NOT ignored:** Add to .gitignore, commit the change, then proceed.
------+ 
------+ **Why critical:** Prevents accidentally committing worktree contents to repository.
------+ 
------+-### For Global Directory (~/.config/superpowers/worktrees)
------+-
------+-No .gitignore verification needed - outside project entirely.
------++Global directories (`~/.config/superpowers/worktrees/`) need no verification.
------+ 
------+-## Creation Steps
------+-
------+-### 1. Detect Project Name
------++#### Create the Worktree
------+ 
------+ ```bash
------+ project=$(basename "$(git rev-parse --show-toplevel)")
------+-```
------+ 
------+-### 2. Create Worktree
------++# Determine path based on chosen location
------++# For project-local: path="$LOCATION/$BRANCH_NAME"
------++# For global: path="~/.config/superpowers/worktrees/$project/$BRANCH_NAME"
------+ 
------+-```bash
------+-# Determine full path
------+-case $LOCATION in
------+-  .worktrees|worktrees)
------+-    path="$LOCATION/$BRANCH_NAME"
------+-    ;;
------+-  ~/.config/superpowers/worktrees/*)
------+-    path="~/.config/superpowers/worktrees/$project/$BRANCH_NAME"
------+-    ;;
------+-esac
------+-
------+-# Create worktree with new branch
------+ git worktree add "$path" -b "$BRANCH_NAME"
------+ cd "$path"
------+ ```
------+ 
------+-### 3. Run Project Setup
------++**Sandbox fallback:** If `git worktree add` fails with a permission error (sandbox denial), tell the user the sandbox blocked worktree creation and you're working in the current directory instead. Then run setup and baseline tests in place.
------++
------++## Step 3: Project Setup
------+ 
------+ Auto-detect and run appropriate setup:
------+ 
------+@@ -117,23 +130,20 @@ if [ -f pyproject.toml ]; then poetry install; fi
------+ if [ -f go.mod ]; then go mod download; fi
------+ ```
------+ 
------+-### 4. Verify Clean Baseline
------++## Step 4: Verify Clean Baseline
------+ 
------+-Run tests to ensure worktree starts clean:
------++Run tests to ensure workspace starts clean:
------+ 
------+ ```bash
------+-# Examples - use project-appropriate command
------+-npm test
------+-cargo test
------+-pytest
------+-go test ./...
------++# Use project-appropriate command
------++npm test / cargo test / pytest / go test ./...
------+ ```
------+ 
------+ **If tests fail:** Report failures, ask whether to proceed or investigate.
------+ 
------+ **If tests pass:** Report ready.
------+ 
------+-### 5. Report Location
------++### Report
------+ 
------+ ```
------+ Worktree ready at <full-path>
------+@@ -145,16 +155,32 @@ Ready to implement <feature-name>
------+ 
------+ | Situation | Action |
------+ |-----------|--------|
------++| Already in linked worktree | Skip creation (Step 0) |
------++| In a submodule | Treat as normal repo (Step 0 guard) |
------++| Native worktree tool available | Use it (Step 1a) |
------++| No native tool | Git worktree fallback (Step 1b) |
------+ | `.worktrees/` exists | Use it (verify ignored) |
------+ | `worktrees/` exists | Use it (verify ignored) |
------+ | Both exist | Use `.worktrees/` |
------+-| Neither exists | Check CLAUDE.md → Ask user |
------++| Neither exists | Check instruction file, then default `.worktrees/` |
------++| Global path exists | Use it (backward compat) |
------+ | Directory not ignored | Add to .gitignore + commit |
------++| Permission error on create | Sandbox fallback, work in place |
------+ | Tests fail during baseline | Report failures + ask |
------+ | No package.json/Cargo.toml | Skip dependency install |
------+ 
------+ ## Common Mistakes
------+ 
------++### Fighting the harness
------++
------++- **Problem:** Using `git worktree add` when the platform already provides isolation
------++- **Fix:** Step 0 detects existing isolation. Step 1a defers to native tools.
------++
------++### Skipping detection
------++
------++- **Problem:** Creating a nested worktree inside an existing one
------++- **Fix:** Always run Step 0 before creating anything
------++
------+ ### Skipping ignore verification
------+ 
------+ - **Problem:** Worktree contents get tracked, pollute git status
------+@@ -163,56 +189,27 @@ Ready to implement <feature-name>
------+ ### Assuming directory location
------+ 
------+ - **Problem:** Creates inconsistency, violates project conventions
------+-- **Fix:** Follow priority: existing > CLAUDE.md > ask
------++- **Fix:** Follow priority: existing > global legacy > instruction file > default
------+ 
------+ ### Proceeding with failing tests
------+ 
------+ - **Problem:** Can't distinguish new bugs from pre-existing issues
------+ - **Fix:** Report failures, get explicit permission to proceed
------+ 
------+-### Hardcoding setup commands
------+-
------+-- **Problem:** Breaks on projects using different tools
------+-- **Fix:** Auto-detect from project files (package.json, etc.)
------+-
------+-## Example Workflow
------+-
------+-```
------+-You: I'm using the using-git-worktrees skill to set up an isolated workspace.
------+-
------+-[Check .worktrees/ - exists]
------+-[Verify ignored - git check-ignore confirms .worktrees/ is ignored]
------+-[Create worktree: git worktree add .worktrees/auth -b feature/auth]
------+-[Run npm install]
------+-[Run npm test - 47 passing]
------+-
------+-Worktree ready at /Users/jesse/myproject/.worktrees/auth
------+-Tests passing (47 tests, 0 failures)
------+-Ready to implement auth feature
------+-```
------+-
------+ ## Red Flags
------+ 
------+ **Never:**
------++- Create a worktree when Step 0 detects existing isolation
------++- Use `git worktree add` when you have a native worktree tool (e.g., `EnterWorktree`). This is the #1 mistake — if you have it, use it.
------++- Skip Step 1a by jumping straight to Step 1b's git commands
------+ - Create worktree without verifying it's ignored (project-local)
------+ - Skip baseline test verification
------+ - Proceed with failing tests without asking
------+-- Assume directory location when ambiguous
------+-- Skip CLAUDE.md check
------+ 
------+ **Always:**
------+-- Follow directory priority: existing > CLAUDE.md > ask
------++- Run Step 0 detection first
------++- Prefer native tools over git fallback
------++- Follow directory priority: existing > global legacy > instruction file > default
------+ - Verify directory is ignored for project-local
------+ - Auto-detect and run project setup
------+ - Verify clean test baseline
------+-
------+-## Integration
------+-
------+-**Called by:**
------+-- **brainstorming** (Phase 4) - REQUIRED when design is approved and implementation follows
------+-- **subagent-driven-development** - REQUIRED before executing any tasks
------+-- **executing-plans** - REQUIRED before executing any tasks
------+-- Any skill needing isolated workspace
------+-
------+-**Pairs with:**
------+-- **finishing-a-development-branch** - REQUIRED for cleanup after work complete
------+diff --git a/skills/superpowers/using-superpowers/references/codex-tools.md b/skills/superpowers/using-superpowers/references/codex-tools.md
------+index 539b2b1..f50d40d 100644
------+--- a/skills/superpowers/using-superpowers/references/codex-tools.md
------++++ b/skills/superpowers/using-superpowers/references/codex-tools.md
------+@@ -4,9 +4,9 @@ Skills use Claude Code tool names. When you encounter these in a skill, use your
------+ 
------+ | Skill references | Codex equivalent |
------+ |-----------------|------------------|
------+-| `Task` tool (dispatch subagent) | `spawn_agent` (see [Named agent dispatch](#named-agent-dispatch)) |
------++| `Task` tool (dispatch subagent) | `spawn_agent` (see [Subagent dispatch requires multi-agent support](#subagent-dispatch-requires-multi-agent-support)) |
------+ | Multiple `Task` calls (parallel) | Multiple `spawn_agent` calls |
------+-| Task returns result | `wait` |
------++| Task returns result | `wait_agent` |
------+ | Task completes automatically | `close_agent` to free slot |
------+ | `TodoWrite` (task tracking) | `update_plan` |
------+ | `Skill` tool (invoke a skill) | Skills load natively — just follow the instructions |
------+@@ -22,53 +22,12 @@ Add to your Codex config (`~/.codex/config.toml`):
------+ multi_agent = true
------+ ```
------+ 
------+-This enables `spawn_agent`, `wait`, and `close_agent` for skills like `dispatching-parallel-agents` and `subagent-driven-development`.
------++This enables `spawn_agent`, `wait_agent`, and `close_agent` for skills like `dispatching-parallel-agents` and `subagent-driven-development`.
------+ 
------+-## Named agent dispatch
------+-
------+-Claude Code skills reference named agent types like `superpowers:code-reviewer`.
------+-Codex does not have a named agent registry — `spawn_agent` creates generic agents
------+-from built-in roles (`default`, `explorer`, `worker`).
------+-
------+-When a skill says to dispatch a named agent type:
------+-
------+-1. Find the agent's prompt file (e.g., `agents/code-reviewer.md` or the skill's
------+-   local prompt template like `code-quality-reviewer-prompt.md`)
------+-2. Read the prompt content
------+-3. Fill any template placeholders (`{BASE_SHA}`, `{WHAT_WAS_IMPLEMENTED}`, etc.)
------+-4. Spawn a `worker` agent with the filled content as the `message`
------+-
------+-| Skill instruction | Codex equivalent |
------+-|-------------------|------------------|
------+-| `Task tool (superpowers:code-reviewer)` | `spawn_agent(agent_type="worker", message=...)` with `code-reviewer.md` content |
------+-| `Task tool (general-purpose)` with inline prompt | `spawn_agent(message=...)` with the same prompt |
------+-
------+-### Message framing
------+-
------+-The `message` parameter is user-level input, not a system prompt. Structure it
------+-for maximum instruction adherence:
------+-
------+-```
------+-Your task is to perform the following. Follow the instructions below exactly.
------+-
------+-<agent-instructions>
------+-[filled prompt content from the agent's .md file]
------+-</agent-instructions>
------+-
------+-Execute this now. Output ONLY the structured response following the format
------+-specified in the instructions above.
------+-```
------+-
------+-- Use task-delegation framing ("Your task is...") rather than persona framing ("You are...")
------+-- Wrap instructions in XML tags — the model treats tagged blocks as authoritative
------+-- End with an explicit execution directive to prevent summarization of the instructions
------+-
------+-### When this workaround can be removed
------+-
------+-This approach compensates for Codex's plugin system not yet supporting an `agents`
------+-field in `plugin.json`. When `RawPluginManifest` gains an `agents` field, the
------+-plugin can symlink to `agents/` (mirroring the existing `skills/` symlink) and
------+-skills can dispatch named agent types directly.
------++Legacy note: Codex builds before `rust-v0.115.0` exposed spawned-agent
------++waiting as `wait`. Current Codex uses `wait_agent` for spawned agents. The
------++`wait` name now belongs to code-mode `exec/wait`, which resumes a yielded exec
------++cell by `cell_id`; it is not the spawned-agent result tool.
------+ 
------+ ## Environment Detection
------+ 
------+diff --git a/skills/superpowers/using-superpowers/references/copilot-tools.md b/skills/superpowers/using-superpowers/references/copilot-tools.md
------+index 4316cdb..ae3cf5a 100644
------+--- a/skills/superpowers/using-superpowers/references/copilot-tools.md
------++++ b/skills/superpowers/using-superpowers/references/copilot-tools.md
------+@@ -12,23 +12,13 @@ Skills use Claude Code tool names. When you encounter these in a skill, use your
------+ | `Glob` (search files by name) | `glob` |
------+ | `Skill` tool (invoke a skill) | `skill` |
------+ | `WebFetch` | `web_fetch` |
------+-| `Task` tool (dispatch subagent) | `task` (see [Agent types](#agent-types)) |
------++| `Task` tool (dispatch subagent) | `task` with `agent_type: "general-purpose"` or `"explore"` |
------+ | Multiple `Task` calls (parallel) | Multiple `task` calls |
------+ | Task status/output | `read_agent`, `list_agents` |
------+ | `TodoWrite` (task tracking) | `sql` with built-in `todos` table |
------+ | `WebSearch` | No equivalent — use `web_fetch` with a search engine URL |
------+ | `EnterPlanMode` / `ExitPlanMode` | No equivalent — stay in the main session |
------+ 
------+-## Agent types
------+-
------+-Copilot CLI's `task` tool accepts an `agent_type` parameter:
------+-
------+-| Claude Code agent | Copilot CLI equivalent |
------+-|-------------------|----------------------|
------+-| `general-purpose` | `"general-purpose"` |
------+-| `Explore` | `"explore"` |
------+-| Named plugin agents (e.g. `superpowers:code-reviewer`) | Discovered automatically from installed plugins |
------+-
------+ ## Async shell sessions
------+ 
------+ Copilot CLI supports persistent async shell sessions, which have no direct Claude Code equivalent:
------+diff --git a/skills/superpowers/using-superpowers/references/gemini-tools.md b/skills/superpowers/using-superpowers/references/gemini-tools.md
------+index f869803..91ef404 100644
------+--- a/skills/superpowers/using-superpowers/references/gemini-tools.md
------++++ b/skills/superpowers/using-superpowers/references/gemini-tools.md
------+@@ -14,11 +14,29 @@ Skills use Claude Code tool names. When you encounter these in a skill, use your
------+ | `Skill` tool (invoke a skill) | `activate_skill` |
------+ | `WebSearch` | `google_web_search` |
------+ | `WebFetch` | `web_fetch` |
------+-| `Task` tool (dispatch subagent) | No equivalent — Gemini CLI does not support subagents |
------++| `Task` tool (dispatch subagent) | `@agent-name` (see [Subagent support](#subagent-support)) |
------+ 
------+-## No subagent support
------++## Subagent support
------+ 
------+-Gemini CLI has no equivalent to Claude Code's `Task` tool. Skills that rely on subagent dispatch (`subagent-driven-development`, `dispatching-parallel-agents`) will fall back to single-session execution via `executing-plans`.
------++Gemini CLI supports subagents natively via the `@` syntax. Use the built-in `@generalist` agent to dispatch any task — it has access to all tools and follows the prompt you provide.
------++
------++When a skill says to dispatch a named agent type, use `@generalist` with the full prompt from the skill's prompt template:
------++
------++| Skill instruction | Gemini CLI equivalent |
------++|-------------------|----------------------|
------++| `Task tool (superpowers:implementer)` | `@generalist` with the filled `implementer-prompt.md` template |
------++| `Task tool (superpowers:spec-reviewer)` | `@generalist` with the filled `spec-reviewer-prompt.md` template |
------++| `Task tool (superpowers:code-reviewer)` | `@code-reviewer` (bundled agent) or `@generalist` with the filled review prompt |
------++| `Task tool (superpowers:code-quality-reviewer)` | `@generalist` with the filled `code-quality-reviewer-prompt.md` template |
------++| `Task tool (general-purpose)` with inline prompt | `@generalist` with your inline prompt |
------++
------++### Prompt filling
------++
------++Skills provide prompt templates with placeholders like `{WHAT_WAS_IMPLEMENTED}` or `[FULL TEXT of task]`. Fill all placeholders and pass the complete prompt as the message to `@generalist`. The prompt template itself contains the agent's role, review criteria, and expected output format — `@generalist` will follow it.
------++
------++### Parallel d
------\ No newline at end of file
+  > Enhance database lookup skill with deterministic querying and provenance features. Updated documentation to reflect improved API interaction, including retrieval contracts, pagination handling, and untrusted response management. Adjusted README and skills documentation for clarity on database access and usage.
+diff --git a/skills/superpowers/brainstorming/SKILL.md b/skills/superpowers/brainstorming/SKILL.md
+index 06cd0a2..b0d52b2 100644
+--- a/skills/superpowers/brainstorming/SKILL.md
++++ b/skills/superpowers/brainstorming/SKILL.md
+@@ -22,7 +22,7 @@ Every project goes through this process. A todo list, a single-function utility,
+ You MUST create a task for each of these items and complete them in order:
+ 
+ 1. **Explore project context** — check files, docs, recent commits
+-2. **Offer visual companion** (if topic will involve visual questions) — this is its own message, not combined with a clarifying question. See the Visual Companion section below.
++2. **Offer the visual companion just-in-time** — NOT upfront. The first time a question would genuinely be clearer shown than described, offer it then (its own message); on approval its browser tab opens for you. If no visual question ever arises, never offer it. See the Visual Companion section below.
+ 3. **Ask clarifying questions** — one at a time, understand purpose/constraints/success criteria
+ 4. **Propose 2-3 approaches** — with trade-offs and your recommendation
+ 5. **Present design** — in sections scaled to their complexity, get user approval after each section
+@@ -36,8 +36,6 @@ You MUST create a task for each of these items and complete them in order:
+ ```dot
+ digraph brainstorming {
+     "Explore project context" [shape=box];
+-    "Visual questions ahead?" [shape=diamond];
+-    "Offer Visual Companion\n(own message, no other content)" [shape=box];
+     "Ask clarifying questions" [shape=box];
+     "Propose 2-3 approaches" [shape=box];
+     "Present design sections" [shape=box];
+@@ -47,10 +45,7 @@ digraph brainstorming {
+     "User reviews spec?" [shape=diamond];
+     "Invoke writing-plans skill" [shape=doublecircle];
+ 
+-    "Explore project context" -> "Visual questions ahead?";
+-    "Visual questions ahead?" -> "Offer Visual Companion\n(own message, no other content)" [label="yes"];
+-    "Visual questions ahead?" -> "Ask clarifying questions" [label="no"];
+-    "Offer Visual Companion\n(own message, no other content)" -> "Ask clarifying questions";
++    "Explore project context" -> "Ask clarifying questions";
+     "Ask clarifying questions" -> "Propose 2-3 approaches";
+     "Propose 2-3 approaches" -> "Present design sections";
+     "Present design sections" -> "User approves design?";
+@@ -148,10 +143,10 @@ Wait for the user's response. If they request changes, make them and re-run the
+ 
+ A browser-based companion for showing mockups, diagrams, and visual options during brainstorming. Available as a tool — not a mode. Accepting the companion means it's available for questions that benefit from visual treatment; it does NOT mean every question goes through the browser.
+ 
+-**Offering the companion:** When you anticipate that upcoming questions will involve visual content (mockups, layouts, diagrams), offer it once for consent:
+-> "Some of what we're working on might be easier to explain if I can show it to you in a web browser. I can put together mockups, diagrams, comparisons, and other visuals as we go. This feature is still new and can be token-intensive. Want to try it? (Requires opening a local URL)"
++**Offering the companion (just-in-time):** Do NOT offer it upfront. Wait until a question would genuinely be clearer shown than told — a real mockup / layout / diagram question, not merely a UI *topic*. The first time that happens, offer it then, as its own message:
++> "This next part might be easier if I show you — I can put together mockups, diagrams, and comparisons in a browser tab as we go. It's still new and can be token-intensive. Want me to? I'll open it for you."
+ 
+-**This offer MUST be its own message.** Do not combine it with clarifying questions, context summaries, or any other content. The message should contain ONLY the offer above and nothing else. Wait for the user's response before continuing. If they decline, proceed with text-only brainstorming.
++**This offer MUST be its own message.** Only the offer — no clarifying question, summary, or other content. Wait for the user's response. If they accept, start the server with `--open` so their browser opens to the first screen automatically. If they decline, continue text-only and don't offer again unless they raise it.
+ 
+ **Per-question decision:** Even after the user accepts, decide FOR EACH QUESTION whether to use the browser or the terminal. The test: **would the user understand this better by seeing it than reading it?**
+ 
+diff --git a/skills/superpowers/brainstorming/scripts/frame-template.html b/skills/superpowers/brainstorming/scripts/frame-template.html
+index dcfe018..f540bb8 100644
+--- a/skills/superpowers/brainstorming/scripts/frame-template.html
++++ b/skills/superpowers/brainstorming/scripts/frame-template.html
+@@ -9,11 +9,11 @@
+      *
+      * This template provides a consistent frame with:
+      * - OS-aware light/dark theming
+-     * - Fixed header and selection indicator bar
++     * - Header branding and connection status
+      * - Scrollable main content area
+      * - CSS helpers for common UI patterns
+      *
+-     * Content is injected via placeholder comment in #claude-content.
++     * Content is injected via placeholder comment in #frame-content.
+      */
+ 
+     * { box-sizing: border-box; margin: 0; padding: 0; }
+@@ -63,34 +63,37 @@
+     }
+ 
+     /* ===== FRAME STRUCTURE ===== */
+-    .header {
+-      background: var(--bg-secondary);
+-      padding: 0.5rem 1.5rem;
+-      display: flex;
+-      justify-content: space-between;
+-      align-items: center;
+-      border-bottom: 1px solid var(--border);
+-      flex-shrink: 0;
++    .brand { display: flex; align-items: center; min-width: 0; overflow: hidden; color: var(--text-secondary); line-height: 1; }
++    .brand a { color: inherit; text-decoration: none; display: flex; align-items: center; gap: 0.5rem; min-width: 0; max-width: 100%; line-height: 1; }
++    .brand-copy { display: block; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; line-height: 1; transform: translateY(-1px); }
++    .brand-logo { display: block; height: 1em; width: auto; max-width: 180px; flex-shrink: 0; filter: invert(1); }
++    @media (prefers-color-scheme: dark) {
++      .brand-logo { filter: none; }
+     }
+-    .header h1 { font-size: 0.85rem; font-weight: 500; color: var(--text-secondary); }
+-    .header .status { font-size: 0.7rem; color: var(--success); display: flex; align-items: center; gap: 0.4rem; }
+-    .header .status::before { content: ''; width: 6px; height: 6px; background: var(--success); border-radius: 50%; }
++    .status { font-size: 0.7rem; color: var(--status-color, var(--success)); display: flex; align-items: center; gap: 0.4rem; justify-self: end; white-space: nowrap; line-height: 1; }
++    .status::before { content: ''; width: 6px; height: 6px; background: var(--status-color, var(--success)); border-radius: 50%; }
+ 
+     .main { flex: 1; overflow-y: auto; }
+-    #claude-content { padding: 2rem; min-height: 100%; }
++    #frame-content { padding: 2rem; min-height: 100%; }
+ 
+-    .indicator-bar {
++    .header {
+       background: var(--bg-secondary);
+-      border-top: 1px solid var(--border);
++      border-bottom: 1px solid var(--border);
+       padding: 0.5rem 1.5rem;
+       flex-shrink: 0;
+-      text-align: center;
++      display: grid;
++      grid-template-columns: minmax(0, 1fr) auto;
++      align-items: center;
++      gap: 1rem;
++      min-height: 42px;
+     }
+-    .indicator-bar span {
++    .header .brand { justify-self: start; width: 100%; font-size: 0.75rem; line-height: 1; }
++    .header .status { grid-column: 2; line-height: 1; }
++    .header span {
+       font-size: 0.75rem;
+       color: var(--text-secondary);
+     }
+-    .indicator-bar .selected-text {
++    .header .selected-text {
+       color: var(--accent);
+       font-weight: 500;
+     }
+@@ -196,19 +199,15 @@
+ </head>
+ <body>
+   <div class="header">
+-    <h1><a href="https://github.com/obra/superpowers" style="color: inherit; text-decoration: none;">Superpowers Brainstorming</a></h1>
+-    <div class="status">Connected</div>
++    <!-- BRANDING -->
++    <div class="status">Connecting…</div>
+   </div>
+ 
+   <div class="main">
+-    <div id="claude-content">
++    <div id="frame-content">
+       <!-- CONTENT -->
+     </div>
+   </div>
+ 
+-  <div class="indicator-bar">
+-    <span id="indicator-text">Click an option above, then return to the terminal</span>
+-  </div>
+-
+ </body>
+ </html>
+diff --git a/skills/superpowers/brainstorming/scripts/helper.js b/skills/superpowers/brainstorming/scripts/helper.js
+index 111f97f..e11d264 100644
+--- a/skills/superpowers/brainstorming/scripts/helper.js
++++ b/skills/superpowers/brainstorming/scripts/helper.js
+@@ -1,26 +1,120 @@
+ (function() {
+-  const WS_URL = 'ws://' + window.location.host;
++  const MIN_RECONNECT_MS = 500;
++  const MAX_RECONNECT_MS = 30000;
++  const TOMBSTONE_AFTER_MS = 15000; // show the "paused" overlay after this long disconnected
++
++  // Pure: next backoff delay (doubles, capped). Exported for unit tests.
++  function nextReconnectDelay(current, max) {
++    return Math.min(current * 2, max);
++  }
++  if (typeof module !== 'undefined' && module.exports) {
++    module.exports = { nextReconnectDelay, MIN_RECONNECT_MS, MAX_RECONNECT_MS, TOMBSTONE_AFTER_MS };
++  }
++
++  // Everything below is browser-only; bail out when loaded in Node (tests).
++  if (typeof window === 'undefined') return;
++
+   let ws = null;
+   let eventQueue = [];
++  let reconnectDelay = MIN_RECONNECT_MS;
++  let reconnectTimer = null;
++  let disconnectedSince = null;
++  let everConnected = false;
++  let tombstoneShown = false;
++
++  function sessionKey() {
++    try {
++      return window.sessionStorage && window.sessionStorage.getItem('brainstorm-session-key');
++    } catch (e) {}
++    return null;
++  }
++
++  function websocketUrl() {
++    const key = sessionKey();
++    return 'ws://' + window.location.host + (key ? '/?key=' + encodeURIComponent(key) : '');
++  }
++
++  function reloadAfterRecovery() {
++    const key = sessionKey();
++    if (key) {
++      window.location.replace('/?key=' + encodeURIComponent(key));
++    } else {
++      window.location.reload();
++    }
++  }
++
++  // Reflect connection state in the frame's status pill (absent on full-doc screens).
++  function setStatus(state) {
++    const el = document.querySelector('.status');
++    if (!el) return;
++    const map = {
++      connecting:   ['Connecting…',   'var(--text-tertiary)'],
++      connected:    ['Connected',     'var(--success)'],
++      reconnecting: ['Reconnecting…', 'var(--warning)'],
++      disconnected: ['Disconnected',  'var(--error)']
++    };
++    const [text, color] = map[state] || map.disconnected;
++    el.textContent = text;
++    el.style.setProperty('--status-color', color);
++  }
++
++  // Self-styled so it works on framed and full-document screens alike.
++  function showTombstone() {
++    if (tombstoneShown) return;
++    tombstoneShown = true;
++    const el = document.createElement('div');
++    el.id = 'bs-tombstone';
++    el.style.cssText = 'position:fixed;inset:0;z-index:99999;display:flex;' +
++      'align-items:center;justify-content:center;padding:2rem;text-align:center;' +
++      'background:rgba(20,20,22,0.92);color:#f5f5f7;font-family:system-ui,sans-serif';
++    el.innerHTML = '<div style="max-width:480px">' +
++      '<h2 style="margin:0 0 .5rem;font-weight:600">Companion paused</h2>' +
++      '<p style="margin:0;opacity:.85">This brainstorm companion has stopped. ' +
++      'Ask your coding agent to bring it back — this page reconnects automatically.</p></div>';
++    if (document.body) document.body.appendChild(el);
++  }
+ 
+   function connect() {
+-    ws = new WebSocket(WS_URL);
++    if (reconnectTimer) { clearTimeout(reconnectTimer); reconnectTimer = null; }
++    setStatus(everConnected ? 'reconnecting' : 'connecting');
++    ws = new WebSocket(websocketUrl());
+ 
+     ws.onopen = () => {
++      const recovered = tombstoneShown;
++      everConnected = true;
++      disconnectedSince = null;
++      reconnectDelay = MIN_RECONNECT_MS;
++      tombstoneShown = false;
++      setStatus('connected');
+       eventQueue.forEach(e => ws.send(JSON.stringify(e)));
+       eventQueue = [];
++      // Recovered from a tombstoned outage (e.g. the server restarted on the same
++      // port) — reload through the keyed bootstrap when possible so the cookie is
++      // refreshed before the visible URL returns to bare /.
++      if (recovered) reloadAfterRecovery();
+     };
+ 
+     ws.onmessage = (msg) => {
+-      const data = JSON.parse(msg.data);
+-      if (data.type === 'reload') {
+-        window.location.reload();
+-      }
++      let data;
++      try { data = JSON.parse(msg.data); } catch (e) { return; }
++      if (data.type === 'reload') window.location.reload();
+     };
+ 
+     ws.onclose = () => {
+-      setTimeout(connect, 1000);
++      ws = null;
++      if (disconnectedSince === null) disconnectedSince = Date.now();
++      if (Date.now() - disconnectedSince >= TOMBSTONE_AFTER_MS) {
++        setStatus('disconnected');
++        showTombstone();
++      } else {
++        setStatus('reconnecting');
++      }
++      reconnectTimer = setTimeout(connect, reconnectDelay);
++      reconnectDelay = nextReconnectDelay(reconnectDelay, MAX_RECONNECT_MS);
+     };
++
++    // Let onclose own reconnection so we don't schedule it twice.
++    ws.onerror = () => { try { ws.close(); } catch (e) {} };
+   }
+ 
+   function sendEvent(event) {
+@@ -44,21 +138,6 @@
+       id: target.id || null
+     });
+ 
+-    // Update indicator bar (defer so toggleSelect runs first)
+-    setTimeout(() => {
+-      const indicator = document.getElementById('indicator-text');
+-      if (!indicator) return;
+-      const container = target.closest('.options') || target.closest('.cards');
+-      const selected = container ? container.querySelectorAll('.selected') : [];
+-      if (selected.length === 0) {
+-        indicator.textContent = 'Click an option above, then return to the terminal';
+-      } else if (selected.length === 1) {
+-        const label = selected[0].querySelector('h3, .content h3, .card-body h3')?.textContent?.trim() || selected[0].dataset.choice;
+-        indicator.innerHTML = '<span class="selected-text">' + label + ' selected</span> — return to terminal to continue';
+-      } else {
+-        indicator.innerHTML = '<span class="selected-text">' + selected.length + ' selected</span> — return to terminal to continue';
+-      }
+-    }, 0);
+   });
+ 
+   // Frame UI: selection tracking
+diff --git a/skills/superpowers/brainstorming/scripts/server.cjs b/skills/superpowers/brainstorming/scripts/server.cjs
+index 562c17f..a828b35 100644
+--- a/skills/superpowers/brainstorming/scripts/server.cjs
++++ b/skills/superpowers/brainstorming/scripts/server.cjs
+@@ -7,6 +7,7 @@ const path = require('path');
+ 
+ const OPCODES = { TEXT: 0x01, CLOSE: 0x08, PING: 0x09, PONG: 0x0A };
+ const WS_MAGIC = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';
++const MAX_FRAME_PAYLOAD_BYTES = 10 * 1024 * 1024;
+ 
+ function computeAcceptKey(clientKey) {
+   return crypto.createHash('sha1').update(clientKey + WS_MAGIC).digest('base64');
+@@ -53,10 +54,18 @@ function decodeFrame(buffer) {
+     offset = 4;
+   } else if (payloadLen === 127) {
+     if (buffer.length < 10) return null;
+-    payloadLen = Number(buffer.readBigUInt64BE(2));
++    const extendedLen = buffer.readBigUInt64BE(2);
++    if (extendedLen > BigInt(MAX_FRAME_PAYLOAD_BYTES)) {
++      throw new Error('WebSocket frame payload exceeds maximum allowed size');
++    }
++    payloadLen = Number(extendedLen);
+     offset = 10;
+   }
+ 
++  if (payloadLen > MAX_FRAME_PAYLOAD_BYTES) {
++    throw new Error('WebSocket frame payload exceeds maximum allowed size');
++  }
++
+   const maskOffset = offset;
+   const dataOffset = offset + 4;
+   const totalLen = dataOffset + payloadLen;
+@@ -73,14 +82,74 @@ function decodeFrame(buffer) {
+ 
+ // ========== Configuration ==========
+ 
+-const PORT = process.env.BRAINSTORM_PORT || (49152 + Math.floor(Math.random() * 16383));
++const PORT_FILE = process.env.BRAINSTORM_PORT_FILE || null;
++const randomPort = () => 49152 + Math.floor(Math.random() * 16383);
++// Prefer an explicit port, else the port this session last bound (so a restart
++// reuses it and an already-open browser tab reconnects), else a random high port.
++function preferredPort() {
++  if (process.env.BRAINSTORM_PORT) return Number(process.env.BRAINSTORM_PORT);
++  if (PORT_FILE) {
++    try {
++      const p = Number(fs.readFileSync(PORT_FILE, 'utf-8').trim());
++      if (Number.isInteger(p) && p > 1023 && p < 65536) return p;
++    } catch (e) { /* no prior port recorded */ }
++  }
++  return randomPort();
++}
++let PORT = preferredPort();
+ const HOST = process.env.BRAINSTORM_HOST || '127.0.0.1';
+ const URL_HOST = process.env.BRAINSTORM_URL_HOST || (HOST === '127.0.0.1' ? 'localhost' : HOST);
+ const SESSION_DIR = process.env.BRAINSTORM_DIR || '/tmp/brainstorm';
+ const CONTENT_DIR = path.join(SESSION_DIR, 'content');
+ const STATE_DIR = path.join(SESSION_DIR, 'state');
++const SUPERPOWERS_VERSION = readSuperpowersVersion();
++const SUPERPOWERS_BRAND_IMAGE_URL = 'https://primeradiant.com/brand/superpowers-visual-brainstorming-logo.png';
++const TELEMETRY_DISABLE_ENV_VARS = [
++  'SUPERPOWERS_DISABLE_TELEMETRY',
++  'DISABLE_TELEMETRY',
++  'CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC'
++];
++const SUPERPOWERS_TELEMETRY_DISABLED = TELEMETRY_DISABLE_ENV_VARS.some(name => isTruthyEnv(process.env[name]));
+ let ownerPid = process.env.BRAINSTORM_OWNER_PID ? Number(process.env.BRAINSTORM_OWNER_PID) : null;
+ 
++// Per-session secret key. The companion is reachable by any local browser tab
++// and, when bound to a non-loopback host, by any host that can route to it.
++// The key authenticates the real client uniformly across loopback, tunnel, and
++// remote binds — and defeats DNS rebinding — where a Host/Origin allowlist
++// cannot. It rides the served URL as ?key= and is mirrored into a cookie on
++// first load so same-origin subresources and the WebSocket carry it for free.
++// Persisted alongside the port (BRAINSTORM_TOKEN_FILE) so a restart keeps the
++// same key and an already-open tab's cookie still validates.
++const TOKEN_FILE = process.env.BRAINSTORM_TOKEN_FILE || null;
++function generateToken() {
++  return crypto.randomBytes(32).toString('hex');
++}
++
++function chmodOwnerOnly(file) {
++  try { fs.chmodSync(file, 0o600); } catch (e) { /* best effort */ }
++}
++
++function initialToken() {
++  if (process.env.BRAINSTORM_TOKEN) {
++    return { value: process.env.BRAINSTORM_TOKEN, source: 'env' };
++  }
++  if (TOKEN_FILE) {
++    try {
++      const t = fs.readFileSync(TOKEN_FILE, 'utf-8').trim();
++      if (/^[0-9a-f]{32,}$/i.test(t)) {
++        chmodOwnerOnly(TOKEN_FILE);
++        return { value: t, source: 'file' };
++      }
++    } catch (e) { /* no prior token recorded */ }
++  }
++  return { value: generateToken(), source: 'generated' };
++}
++
++const tokenInfo = initialToken();
++let TOKEN = tokenInfo.value;
++let tokenSource = tokenInfo.source;
++let COOKIE_NAME = 'brainstorm-key-' + PORT; // refined to the actual bound port in onListen
++
+ const MIME_TYPES = {
+   '.html': 'text/html', '.css': 'text/css', '.js': 'application/javascript',
+   '.json': 'application/json', '.png': 'image/png', '.jpg': 'image/jpeg',
+@@ -89,14 +158,46 @@ const MIME_TYPES = {
+ 
+ // ========== Templates and Constants ==========
+ 
+-const WAITING_PAGE = `<!DOCTYPE html>
++function waitingPage() {
++  return renderBranding(`<!DOCTYPE html>
+ <html>
+ <head><meta charset="utf-8"><title>Brainstorm Companion</title>
++<style>
++body { font-family: system-ui, sans-serif; padding: 2rem; max-width: 800px; margin: 0 auto; }
++h1 { color: #333; } p { color: #666; }
++.brand { display: flex; align-items: center; min-width: 0; overflow: hidden; margin-bottom: 1.5rem; color: #666; font-size: 0.9rem; line-height: 1; }
++.brand a { color: inherit; text-decoration: none; display: flex; align-items: center; gap: 0.5rem; min-width: 0; max-width: 100%; line-height: 1; }
++.brand-copy { display: block; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; line-height: 1; transform: translateY(-1px); }
++.brand-logo { display: block; height: 1em; width: auto; max-width: 180px; filter: invert(1); }
++</style>
++</head>
++<body><!-- BRANDING --><h1>Brainstorm Companion</h1>
++<p>Waiting for the agent to push a screen...</p></body></html>`);
++}
++
++const FORBIDDEN_PAGE = `<!DOCTYPE html>
++<html>
++<head><meta charset="utf-8"><title>Session key required</title>
+ <style>body { font-family: system-ui, sans-serif; padding: 2rem; max-width: 800px; margin: 0 auto; }
+-h1 { color: #333; } p { color: #666; }</style>
++h1 { color: #333; } p { color: #666; } code { background: #f0f0f0; padding: 0.1em 0.3em; border-radius: 4px; }</style>
+ </head>
+-<body><h1>Brainstorm Companion</h1>
+-<p>Waiting for the agent to push a screen...</p></body></html>`;
++<body><h1>Session key required</h1>
++<p>This page needs the full URL your coding agent gave you, including the
++<code>?key=&hellip;</code> part. Copy the complete URL and open it again.</p></body></html>`;
++
++function bootstrapPage(key) {
++  const jsonKey = JSON.stringify(String(key));
++  return `<!DOCTYPE html>
++<html>
++<head><meta charset="utf-8"><title>Opening Brainstorm Companion</title></head>
++<body>
++<script>
++try { sessionStorage.setItem('brainstorm-session-key', ${jsonKey}); } catch (e) {}
++location.replace('/');
++</script>
++</body>
++</html>`;
++}
+ 
+ const frameTemplate = fs.readFileSync(path.join(__dirname, 'frame-template.html'), 'utf-8');
+ const helperScript = fs.readFileSync(path.join(__dirname, 'helper.js'), 'utf-8');
+@@ -104,35 +205,209 @@ const helperInjection = '<script>\n' + helperScript + '\n</script>';
+ 
+ // ========== Helper Functions ==========
+ 
++function readSuperpowersVersion() {
++  const root = path.join(__dirname, '../../..');
++  const manifests = [
++    path.join(root, 'package.json'),
++    path.join(root, '.codex-plugin/plugin.json')
++  ];
++
++  for (const manifest of manifests) {
++    try {
++      const data = JSON.parse(fs.readFileSync(manifest, 'utf-8'));
++      if (data.version) return String(data.version);
++    } catch (e) {
++      // Packaged Codex plugins omit package.json; try the next manifest.
++    }
++  }
++
++  return 'unknown';
++}
++
++function isTruthyEnv(value) {
++  if (!value) return false;
++  const normalized = String(value).trim().toLowerCase();
++  if (!normalized) return false;
++  return !['0', 'false', 'no', 'off'].includes(normalized);
++}
++
++function escapeHtmlText(value) {
++  return String(value)
++    .replace(/&/g, '&amp;')
++    .replace(/</g, '&lt;')
++    .replace(/>/g, '&gt;')
++    .replace(/"/g, '&quot;');
++}
++
++function brandMarkup() {
++  const version = escapeHtmlText(SUPERPOWERS_VERSION);
++  const text = SUPERPOWERS_TELEMETRY_DISABLED
++    ? 'Prime Radiant Superpowers v' + version
++    : 'Superpowers v' + version;
++  const logo = SUPERPOWERS_TELEMETRY_DISABLED
++    ? ''
++    : '<img class="brand-logo" src="' + SUPERPOWERS_BRAND_IMAGE_URL + '?v=' + encodeURIComponent(SUPERPOWERS_VERSION) + '" alt="Prime Radiant" referrerpolicy="no-referrer" decoding="async">';
++
++  return '<div class="brand"><a href="https://github.com/obra/superpowers">' + logo + '<span class="brand-copy">' + text + '</span></a></div>';
++}
++
++function renderBranding(html) {
++  return html.split('<!-- BRANDING -->').join(brandMarkup());
++}
++
+ function isFullDocument(html) {
+   const trimmed = html.trimStart().toLowerCase();
+   return trimmed.startsWith('<!doctype') || trimmed.startsWith('<html');
+ }
+ 
+ function wrapInFrame(content) {
+-  return frameTemplate.replace('<!-- CONTENT -->', content);
++  return renderBranding(frameTemplate).replace('<!-- CONTENT -->', content);
+ }
+ 
+ function getNewestScreen() {
+   const files = fs.readdirSync(CONTENT_DIR)
+-    .filter(f => f.endsWith('.html'))
++    .filter(f => !f.startsWith('.') && f.endsWith('.html'))
+     .map(f => {
+       const fp = path.join(CONTENT_DIR, f);
++      if (!isRegularFileInsideContentDir(fp)) return null;
+       return { path: fp, mtime: fs.statSync(fp).mtime.getTime() };
+     })
++    .filter(Boolean)
+     .sort((a, b) => b.mtime - a.mtime);
+   return files.length > 0 ? files[0].path : null;
+ }
+ 
++function urlHostForHttp(host) {
++  const h = String(host);
++  if (h.startsWith('[') && h.endsWith(']')) return h;
++  return h.includes(':') ? '[' + h + ']' : h;
++}
++
++function companionUrl() {
++  return 'http://' + urlHostForHttp(URL_HOST) + ':' + PORT + '/?key=' + TOKEN;
++}
++
++function browserLauncherForPlatform(url, {
++  platform = process.platform,
++  osRelease = require('os').release(),
++  env = process.env
++} = {}) {
++  const isWSL = platform === 'linux' && /microsoft/i.test(osRelease);
++  if (platform === 'darwin') return { bin: 'open', args: [url] };
++  if (platform === 'win32' || isWSL) {
++    return { bin: 'rundll32.exe', args: ['url.dll,FileProtocolHandler', url] };
++  }
++  if (env.DISPLAY || env.WAYLAND_DISPLAY) return { bin: 'xdg-open', args: [url] };
++  return null;
++}
++
++function isRegularFileInsideContentDir(filePath) {
++  let stat, realContentDir, realFilePath;
++  try {
++    stat = fs.lstatSync(filePath);
++    if (stat.isSymbolicLink()) return false;
++    if (!stat.isFile()) return false;
++    if (stat.nlink !== 1) return false;
++    realContentDir = fs.realpathSync(CONTENT_DIR);
++    realFilePath = fs.realpathSync(filePath);
++  } catch (e) {
++    return false;
++  }
++  return realFilePath.startsWith(realContentDir + path.sep);
++}
++
++// ========== Authentication ==========
++
++function timingSafeEqualStr(a, b) {
++  const ab = Buffer.from(String(a));
++  const bb = Buffer.from(String(b));
++  if (ab.length !== bb.length) return false;
++  return crypto.timingSafeEqual(ab, bb);
++}
++
++function parseCookies(header) {
++  const out = {};
++  if (!header) return out;
++  for (const part of header.split(';')) {
++    const eq = part.indexOf('=');
++    if (eq < 0) continue;
++    out[part.slice(0, eq).trim()] = part.slice(eq + 1).trim();
++  }
++  return out;
++}
++
++// A request is authorized if it carries the session key as ?key= or as the
++// session cookie. Both are compared in constant time.
++function isAuthorized(req) {
++  const q = req.url.indexOf('?');
++  if (q >= 0) {
++    const params = new URLSearchParams(req.url.slice(q + 1));
++    if (params.has('key')) {
++      const key = params.get('key');
++      return Boolean(key && timingSafeEqualStr(key, TOKEN));
++    }
++  }
++  const cookie = parseCookies(req.headers['cookie'])[COOKIE_NAME];
++  if (cookie && timingSafeEqualStr(cookie, TOKEN)) return true;
++  return false;
++}
++
++function pathnameOf(url) {
++  const q = url.indexOf('?');
++  return q >= 0 ? url.slice(0, q) : url;
++}
++
++function queryKey(url) {
++  const q = url.indexOf('?');
++  if (q < 0) return null;
++  return new URLSearchParams(url.slice(q + 1)).get('key');
++}
++
++function securityHeaders(headers = {}) {
++  return {
++    'Referrer-Policy': 'no-referrer',
++    'Cache-Control': 'no-store',
++    'X-Frame-Options': 'DENY',
++    'Content-Security-Policy': "frame-ancestors 'none'",
++    'Cross-Origin-Resource-Policy': 'same-origin',
++    ...headers
++  };
++}
++
++function isAllowedWebSocketOrigin(req) {
++  const origin = req.headers.origin;
++  if (!origin) return true;
++  const host = req.headers.host;
++  if (!host) return false;
++  return origin === 'http://' + host;
++}
++
+ // ========== HTTP Request Handler ==========
+ 
+ function handleRequest(req, res) {
+-  touchActivity();
+-  if (req.method === 'GET' && req.url === '/') {
++  if (!isAuthorized(req)) {
++    res.writeHead(403, securityHeaders({ 'Content-Type': 'text/html; charset=utf-8' }));
++    res.end(FORBIDDEN_PAGE);
++    return;
++  }
++  touchActivity(); // only authorized requests count as activity
++
++  // Mirror the key into a cookie so same-origin subresources (/files/*) can
++  // authenticate after bootstrap. HttpOnly keeps it away from page scripts; the
++  // WebSocket Origin check below is what blocks cross-origin localhost injection.
++  res.setHeader('Set-Cookie',
++    COOKIE_NAME + '=' + TOKEN + '; HttpOnly; SameSite=Strict; Path=/');
++
++  const pathname = pathnameOf(req.url);
++  const keyFromQuery = queryKey(req.url);
++  if (req.method === 'GET' && pathname === '/' && keyFromQuery && timingSafeEqualStr(keyFromQuery, TOKEN)) {
++    res.writeHead(200, securityHeaders({ 'Content-Type': 'text/html; charset=utf-8' }));
++    res.end(bootstrapPage(keyFromQuery));
++  } else if (req.method === 'GET' && pathname === '/') {
+     const screenFile = getNewestScreen();
+     let html = screenFile
+       ? (raw => isFullDocument(raw) ? raw : wrapInFrame(raw))(fs.readFileSync(screenFile, 'utf-8'))
+-      : WAITING_PAGE;
++      : waitingPage();
+ 
+     if (html.includes('</body>')) {
+       html = html.replace('</body>', helperInjection + '\n</body>');
+@@ -140,22 +415,24 @@ function handleRequest(req, res) {
+       html += helperInjection;
+     }
+ 
+-    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
++    res.writeHead(200, securityHeaders({ 'Content-Type': 'text/html; charset=utf-8' }));
+     res.end(html);
+-  } else if (req.method === 'GET' && req.url.startsWith('/files/')) {
+-    const fileName = req.url.slice(7);
+-    const filePath = path.join(CONTENT_DIR, path.basename(fileName));
+-    if (!fs.existsSync(filePath)) {
+-      res.writeHead(404);
++  } else if (req.method === 'GET' && pathname.startsWith('/files/')) {
++    const fileName = path.basename(pathname.slice(7));
++    const filePath = path.join(CONTENT_DIR, fileName);
++    // Reject empty/dotfile names and anything that isn't a regular file —
++    // `/files/` would otherwise resolve to CONTENT_DIR and crash readFileSync (EISDIR).
++    if (!fileName || fileName.startsWith('.') || !isRegularFileInsideContentDir(filePath)) {
++      res.writeHead(404, securityHeaders());
+       res.end('Not found');
+       return;
+     }
+     const ext = path.extname(filePath).toLowerCase();
+     const contentType = MIME_TYPES[ext] || 'application/octet-stream';
+-    res.writeHead(200, { 'Content-Type': contentType });
++    res.writeHead(200, securityHeaders({ 'Content-Type': contentType }));
+     res.end(fs.readFileSync(filePath));
+   } else {
+-    res.writeHead(404);
++    res.writeHead(404, securityHeaders());
+     res.end('Not found');
+   }
+ }
+@@ -165,6 +442,8 @@ function handleRequest(req, res) {
+ const clients = new Set();
+ 
+ function handleUpgrade(req, socket) {
++  if (!isAuthorized(req) || !isAllowedWebSocketOrigin(req)) { socket.destroy(); return; }
++
+   const key = req.headers['sec-websocket-key'];
+   if (!key) { socket.destroy(); return; }
+ 
+@@ -231,7 +510,7 @@ function handleMessage(text) {
+   }
+   touchActivity();
+   console.log(JSON.stringify({ source: 'user-event', ...event }));
+-  if (event.choice) {
++  if (event && event.choice) {
+     const eventsFile = path.join(STATE_DIR, 'events');
+     fs.appendFileSync(eventsFile, JSON.stringify(event) + '\n');
+   }
+@@ -244,9 +523,44 @@ function broadcast(msg) {
+   }
+ }
+ 
++// Best-effort: open the user's browser the first time a screen is actually ready
++// to show. Skips when disabled, on a non-loopback (remote) bind, or when a
++// browser is already connected. Override the launcher with BRAINSTORM_OPEN_CMD.
++let browserOpened = false;
++function maybeOpenBrowser() {
++  if (browserOpened) return;
++  browserOpened = true;
++  if (!process.env.BRAINSTORM_OPEN) return; // opt-in: only after the user approves the companion
++  if (HOST !== '127.0.0.1' && HOST !== 'localhost') return;
++  if (clients.size > 0) return; // the user already opened it
++  const url = companionUrl(); // must carry the key or the gate 403s it
++  const cp = require('child_process');
++  // Operator-provided launcher: run as given (this env var is trusted operator input).
++  if (process.env.BRAINSTORM_OPEN_CMD) {
++    try { cp.exec(process.env.BRAINSTORM_OPEN_CMD + ' ' + JSON.stringify(url), () => {}); } catch (e) { /* best effort */ }
++    return;
++  }
++  // Platform launchers: pass the URL as an argv element via execFile (no shell),
++  // so a url-host containing shell metacharacters can't inject a command.
++  const launcher = browserLauncherForPlatform(url);
++  if (!launcher) return; // headless: nothing to open
++  try { cp.execFile(launcher.bin, launcher.args, () => {}); } catch (e) { /* best effort */ }
++}
++
+ // ========== Activity Tracking ==========
+ 
+-const IDLE_TIMEOUT_MS = 30 * 60 * 1000; // 30 minutes
++// Idle timeout: shut down after this long with no activity. Default 4 hours;
++// override with BRAINSTORM_IDLE_TIMEOUT_MS (start-server.sh: --idle-timeout-minutes).
++const IDLE_TIMEOUT_MS = (() => {
++  const ms = Number(process.env.BRAINSTORM_IDLE_TIMEOUT_MS);
++  return Number.isFinite(ms) && ms > 0 ? ms : 4 * 60 * 60 * 1000;
++})();
++// How often the watchdog checks for owner-death / idleness. Configurable mainly
++// so tests can run fast; production default is 60s.
++const LIFECYCLE_CHECK_MS = (() => {
++  const ms = Number(process.env.BRAINSTORM_LIFECYCLE_CHECK_MS);
++  return Number.isFinite(ms) && ms > 0 ? ms : 60 * 1000;
++})();
+ let lastActivity = Date.now();
+ 
+ function touchActivity() {
+@@ -267,14 +581,14 @@ function startServer() {
+   // macOS fs.watch reports 'rename' for both new files and overwrites,
+   // so we can't rely on eventType alone.
+   const knownFiles = new Set(
+-    fs.readdirSync(CONTENT_DIR).filter(f => f.endsWith('.html'))
++    fs.readdirSync(CONTENT_DIR).filter(f => !f.startsWith('.') && f.endsWith('.html'))
+   );
+ 
+   const server = http.createServer(handleRequest);
+   server.on('upgrade', handleUpgrade);
+ 
+   const watcher = fs.watch(CONTENT_DIR, (eventType, filename) => {
+-    if (!filename || !filename.endsWith('.html')) return;
++    if (!filename || filename.startsWith('.') || !filename.endsWith('.html')) return;
+ 
+     if (debounceTimers.has(filename)) clearTimeout(debounceTimers.get(filename));
+     debounceTimers.set(filename, setTimeout(() => {
+@@ -289,6 +603,7 @@ function startServer() {
+         const eventsFile = path.join(STATE_DIR, 'events');
+         if (fs.existsSync(eventsFile)) fs.unlinkSync(eventsFile);
+         console.log(JSON.stringify({ type: 'screen-added', file: filePath }));
++        maybeOpenBrowser();
+       } else {
+         console.log(JSON.stringify({ type: 'screen-updated', file: filePath }));
+       }
+@@ -308,6 +623,11 @@ function startServer() {
+     );
+     watcher.close();
+     clearInterval(lifecycleCheck);
++    // Close any upgraded WebSocket sockets so server.close() can complete and
++    // the process actually exits instead of lingering on an open connection.
++    for (const socket of clients) {
++      try { socket.destroy(); } catch (e) { /* already gone */ }
++    }
+     server.close(() => process.exit(0));
+   }
+ 
+@@ -316,11 +636,11 @@ function startServer() {
+     try { process.kill(ownerPid, 0); return true; } catch (e) { return e.code === 'EPERM'; }
+   }
+ 
+-  // Check every 60s: exit if owner process died or idle for 30 minutes
++  // Periodically exit if the owner process died or we've been idle too long.
+   const lifecycleCheck = setInterval(() => {
+     if (!ownerAlive()) shutdown('owner process exited');
+     else if (Date.now() - lastActivity > IDLE_TIMEOUT_MS) shutdown('idle timeout');
+-  }, 60 * 1000);
++  }, LIFECYCLE_CHECK_MS);
+   lifecycleCheck.unref();
+ 
+   // Validate owner PID at startup. If it's already dead, the PID resolution
+@@ -336,19 +656,68 @@ function startServer() {
+     }
+   }
+ 
+-  server.listen(PORT, HOST, () => {
++  // If the preferred port is already taken (e.g. a previous server is still
++  // alive), fall back to a random port once instead of failing.
++  let triedFallback = false;
++
++  function onListen() {
++    // Cookie name keys on the ACTUAL bound port (may differ from the preferred
++    // one after an EADDRINUSE fallback) so it can't collide with another server's
++    // cookie in the shared localhost jar.
++    COOKIE_NAME = 'brainstorm-key-' + PORT;
++    // Record the bound port AND token so the next restart of this session reuses
++    // them — but ONLY when we got our preferred port. On a fallback we bound a
++    // *different* port because someone else holds the preferred one; persisting
++    // would overwrite the shared files and strand that other session's open tab.
++    if (PORT_FILE && !triedFallback) {
++      try { fs.writeFileSync(PORT_FILE, String(PORT)); } catch (e) { /* best effort */ }
++      if (TOKEN_FILE) {
++        try {
++          fs.writeFileSync(TOKEN_FILE, TOKEN, { mode: 0o600 });
++          chmodOwnerOnly(TOKEN_FILE);
++        } catch (e) { /* best effort */ }
++      }
++    }
+     const info = JSON.stringify({
+       type: 'server-started', port: Number(PORT), host: HOST,
+-      url_host: URL_HOST, url: 'http://' + URL_HOST + ':' + PORT,
+-      screen_dir: CONTENT_DIR, state_dir: STATE_DIR
++      url_host: URL_HOST, url: companionUrl(),
++      screen_dir: CONTENT_DIR, state_dir: STATE_DIR, idle_timeout_ms: IDLE_TIMEOUT_MS
+     });
+     console.log(info);
+-    fs.writeFileSync(path.join(STATE_DIR, 'server-info'), info + '\n');
++    // server-info embeds the key — keep it owner-only.
++    fs.writeFileSync(path.join(STATE_DIR, 'server-info'), info + '\n', { mode: 0o600 });
++  }
++
++  server.on('error', (err) => {
++    if (err.code === 'EADDRINUSE' && !triedFallback) {
++      if (tokenSource === 'env') {
++        console.error('Server failed to bind: preferred port is in use and BRAINSTORM_TOKEN is set; refusing fallback with explicit token');
++        process.exit(1);
++      }
++      triedFallback = true;
++      PORT = randomPort();
++      if (tokenSource === 'file') {
++        TOKEN = generateToken();
++        tokenSource = 'generated-fallback';
++      }
++      server.listen(PORT, HOST, onListen);
++    } else {
++      console.error('Server failed to bind:', err.message);
++      process.exit(1);
++    }
+   });
++  server.listen(PORT, HOST, onListen);
+ }
+ 
+ if (require.main === module) {
+   startServer();
+ }
+ 
+-module.exports = { computeAcceptKey, encodeFrame, decodeFrame, OPCODES };
++module.exports = {
++  computeAcceptKey,
++  encodeFrame,
++  decodeFrame,
++  browserLauncherForPlatform,
++  OPCODES,
++  MAX_FRAME_PAYLOAD_BYTES
++};
+diff --git a/skills/superpowers/brainstorming/scripts/start-server.sh b/skills/superpowers/brainstorming/scripts/start-server.sh
+index 9ef6dcb..016a8e4 100755
+--- a/skills/superpowers/brainstorming/scripts/start-server.sh
++++ b/skills/superpowers/brainstorming/scripts/start-server.sh
+@@ -11,6 +11,9 @@
+ #   --host <bind-host>    Host/interface to bind (default: 127.0.0.1).
+ #                         Use 0.0.0.0 in remote/containerized environments.
+ #   --url-host <host>     Hostname shown in returned URL JSON.
++#   --idle-timeout-minutes <n>  Shut down after n minutes idle (default 240 = 4h).
++#   --open                Auto-open the browser on the first screen (use only
++#                         after the user approves the visual companion).
+ #   --foreground          Run server in the current terminal (no backgrounding).
+ #   --background          Force background mode (overrides Codex auto-foreground).
+ 
+@@ -22,6 +25,7 @@ FOREGROUND="false"
+ FORCE_BACKGROUND="false"
+ BIND_HOST="127.0.0.1"
+ URL_HOST=""
++IDLE_TIMEOUT_MINUTES=""
+ while [[ $# -gt 0 ]]; do
+   case "$1" in
+     --project-dir)
+@@ -36,6 +40,14 @@ while [[ $# -gt 0 ]]; do
+       URL_HOST="$2"
+       shift 2
+       ;;
++    --idle-timeout-minutes)
++      IDLE_TIMEOUT_MINUTES="$2"
++      shift 2
++      ;;
++    --open)
++      export BRAINSTORM_OPEN=1
++      shift
++      ;;
+     --foreground|--no-daemon)
+       FOREGROUND="true"
+       shift
+@@ -59,6 +71,29 @@ if [[ -z "$URL_HOST" ]]; then
+   fi
+ fi
+ 
++if [[ -n "$IDLE_TIMEOUT_MINUTES" ]]; then
++  if ! [[ "$IDLE_TIMEOUT_MINUTES" =~ ^[0-9]+$ ]] || [[ "$IDLE_TIMEOUT_MINUTES" -lt 1 ]]; then
++    echo "{\"error\": \"--idle-timeout-minutes must be a positive integer\"}"
++    exit 1
++  fi
++  export BRAINSTORM_IDLE_TIMEOUT_MS=$(( IDLE_TIMEOUT_MINUTES * 60 * 1000 ))
++fi
++
++is_windows_like_shell() {
++  case "${OSTYPE:-}" in
++    msys*|cygwin*|mingw*) return 0 ;;
++  esac
++  if [[ -n "${MSYSTEM:-}" ]]; then
++    return 0
++  fi
++  local uname_s
++  uname_s="$(uname -s 2>/dev/null || true)"
++  case "$uname_s" in
++    MSYS*|MINGW*|CYGWIN*) return 0 ;;
++  esac
++  return 1
++}
++
+ # Some environments reap detached/background processes. Auto-foreground when detected.
+ if [[ -n "${CODEX_CI:-}" && "$FOREGROUND" != "true" && "$FORCE_BACKGROUND" != "true" ]]; then
+   FOREGROUND="true"
+@@ -66,19 +101,24 @@ fi
+ 
+ # Windows/Git Bash reaps nohup background processes. Auto-foreground when detected.
+ if [[ "$FOREGROUND" != "true" && "$FORCE_BACKGROUND" != "true" ]]; then
+-  case "${OSTYPE:-}" in
+-    msys*|cygwin*|mingw*) FOREGROUND="true" ;;
+-  esac
+-  if [[ -n "${MSYSTEM:-}" ]]; then
++  if is_windows_like_shell; then
+     FOREGROUND="true"
+   fi
+ fi
+ 
++# Session files (server.log, server-info, .last-token) embed the session key —
++# keep everything this script and the server create owner-only.
++umask 077
++
+ # Generate unique session directory
+ SESSION_ID="$$-$(date +%s)"
+ 
+ if [[ -n "$PROJECT_DIR" ]]; then
+   SESSION_DIR="${PROJECT_DIR}/.superpowers/brainstorm/${SESSION_ID}"
++  # Persist the bound port and key per project so a restart reuses them and an
++  # already-open browser tab reconnects to the same URL with a valid cookie.
++  export BRAINSTORM_PORT_FILE="${PROJECT_DIR}/.superpowers/brainstorm/.last-port"
++  export BRAINSTORM_TOKEN_FILE="${PROJECT_DIR}/.superpowers/brainstorm/.last-token"
+ else
+   SESSION_DIR="/tmp/brainstorm-${SESSION_ID}"
+ fi
+@@ -86,10 +126,21 @@ fi
+ STATE_DIR="${SESSION_DIR}/state"
+ PID_FILE="${STATE_DIR}/server.pid"
+ LOG_FILE="${STATE_DIR}/server.log"
++SERVER_ID_FILE="${STATE_DIR}/server-instance-id"
+ 
+ # Create fresh session directory with content and state peers
+ mkdir -p "${SESSION_DIR}/content" "$STATE_DIR"
+ 
++SERVER_ID=""
++if [[ -r /dev/urandom ]]; then
++  SERVER_ID="$(od -An -N24 -tx1 /dev/urandom 2>/dev/null | tr -d ' \n' || true)"
++fi
++if ! [[ "$SERVER_ID" =~ ^[A-Za-z0-9_-]{32,64}$ ]]; then
++  SERVER_ID="$(printf '%08x%08x%08x%08x' "$$" "$(date +%s)" "${RANDOM:-0}" "${RANDOM:-0}")"
++fi
++printf '%s\n' "$SERVER_ID" > "$SERVER_ID_FILE"
++chmod 600 "$SERVER_ID_FILE" 2>/dev/null || true
++
+ # Kill any existing server
+ if [[ -f "$PID_FILE" ]]; then
+   old_pid=$(cat "$PID_FILE")
+@@ -97,7 +148,7 @@ if [[ -f "$PID_FILE" ]]; then
+   rm -f "$PID_FILE"
+ fi
+ 
+-cd "$SCRIPT_DIR"
++cd "$SCRIPT_DIR" || exit 1
+ 
+ # Resolve the harness PID (grandparent of this script).
+ # $PPID is the ephemeral shell the harness spawned to run us — it dies
+@@ -107,22 +158,32 @@ if [[ -z "$OWNER_PID" || "$OWNER_PID" == "1" ]]; then
+   OWNER_PID="$PPID"
+ fi
+ 
++# Windows/MSYS2: Node.js cannot see POSIX PIDs from the MSYS2 namespace.
++# Passing a PID node cannot verify causes server to log owner-pid-invalid
++# and self-terminate at the 60-second lifecycle check. Clear it so the
++# watchdog is disabled and the idle timeout becomes the only shutdown trigger.
++if is_windows_like_shell; then
++  OWNER_PID=""
++fi
++
+ # Foreground mode for environments that reap detached/background processes.
+ if [[ "$FOREGROUND" == "true" ]]; then
+-  echo "$$" > "$PID_FILE"
+-  env BRAINSTORM_DIR="$SESSION_DIR" BRAINSTORM_HOST="$BIND_HOST" BRAINSTORM_URL_HOST="$URL_HOST" BRAINSTORM_OWNER_PID="$OWNER_PID" node server.cjs
++  env BRAINSTORM_DIR="$SESSION_DIR" BRAINSTORM_HOST="$BIND_HOST" BRAINSTORM_URL_HOST="$URL_HOST" BRAINSTORM_OWNER_PID="$OWNER_PID" node server.cjs "--brainstorm-server-id=$SERVER_ID" &
++  SERVER_PID=$!
++  echo "$SERVER_PID" > "$PID_FILE"
++  wait "$SERVER_PID"
+   exit $?
+ fi
+ 
+ # Start server, capturing output to log file
+ # Use nohup to survive shell exit; disown to remove from job table
+-nohup env BRAINSTORM_DIR="$SESSION_DIR" BRAINSTORM_HOST="$BIND_HOST" BRAINSTORM_URL_HOST="$URL_HOST" BRAINSTORM_OWNER_PID="$OWNER_PID" node server.cjs > "$LOG_FILE" 2>&1 &
++nohup env BRAINSTORM_DIR="$SESSION_DIR" BRAINSTORM_HOST="$BIND_HOST" BRAINSTORM_URL_HOST="$URL_HOST" BRAINSTORM_OWNER_PID="$OWNER_PID" node server.cjs "--brainstorm-server-id=$SERVER_ID" > "$LOG_FILE" 2>&1 &
+ SERVER_PID=$!
+ disown "$SERVER_PID" 2>/dev/null
+ echo "$SERVER_PID" > "$PID_FILE"
+ 
+ # Wait for server-started message (check log file)
+-for i in {1..50}; do
++for _ in {1..50}; do
+   if grep -q "server-started" "$LOG_FILE" 2>/dev/null; then
+     # Verify server is still alive after a short window (catches process reapers)
+     alive="true"
+diff --git a/skills/superpowers/brainstorming/scripts/stop-server.sh b/skills/superpowers/brainstorming/scripts/stop-server.sh
+index a6b94e6..7cacfe9 100755
+--- a/skills/superpowers/brainstorming/scripts/stop-server.sh
++++ b/skills/superpowers/brainstorming/scripts/stop-server.sh
+@@ -15,15 +15,78 @@ fi
+ 
+ STATE_DIR="${SESSION_DIR}/state"
+ PID_FILE="${STATE_DIR}/server.pid"
++SERVER_ID_FILE="${STATE_DIR}/server-instance-id"
++
++mark_stopped() {
++  local reason="$1"
++  rm -f "${STATE_DIR}/server-info"
++  printf '{"reason":"%s","timestamp":%s}\n' "$reason" "$(date +%s)" > "${STATE_DIR}/server-stopped"
++}
++
++read_expected_server_id() {
++  [[ -f "$SERVER_ID_FILE" ]] || return 1
++  local id
++  id="$(tr -d '\r\n' < "$SERVER_ID_FILE" 2>/dev/null || true)"
++  [[ "$id" =~ ^[A-Za-z0-9_-]{32,64}$ ]] || return 1
++  printf '%s\n' "$id"
++}
++
++command_line_for_pid() {
++  local pid="$1"
++  if [[ -r "/proc/$pid/cmdline" ]]; then
++    tr '\0' '\n' < "/proc/$pid/cmdline" 2>/dev/null || true
++    return 0
++  fi
++  ps -ww -p "$pid" -o command= 2>/dev/null || ps -f -p "$pid" 2>/dev/null | sed '1d' || true
++}
++
++command_has_server_id() {
++  local pid="$1"
++  local expected="$2"
++  local expected_arg="--brainstorm-server-id=$expected"
++  if [[ -r "/proc/$pid/cmdline" ]]; then
++    local arg
++    while IFS= read -r -d '' arg || [[ -n "$arg" ]]; do
++      [[ "$arg" == "$expected_arg" ]] && return 0
++    done < "/proc/$pid/cmdline"
++    return 1
++  fi
++  local command_line
++  command_line="$(command_line_for_pid "$pid")"
++  [[ -n "$command_line" ]] || return 1
++  case " $command_line " in
++    *" $expected_arg "*) return 0 ;;
++    *) return 1 ;;
++  esac
++}
++
++# Confirm a PID has this session's per-start instance id, not just a familiar
++# process name. Ambiguous or legacy metadata fails closed as stale_pid.
++is_brainstorm_server() {
++  kill -0 "$1" 2>/dev/null || return 1
++  local expected_id
++  expected_id="$(read_expected_server_id)" || return 1
++  command_has_server_id "$1" "$expected_id" || return 1
++  return 0
++}
+ 
+ if [[ -f "$PID_FILE" ]]; then
+   pid=$(cat "$PID_FILE")
+ 
++  # Refuse to signal a PID we can't prove is our server. A stale pid file may
++  # point at an unrelated process after a reboot/PID wraparound.
++  if ! is_brainstorm_server "$pid"; then
++    rm -f "$PID_FILE" "$SERVER_ID_FILE"
++    mark_stopped "stale_pid"
++    echo '{"status": "stale_pid"}'
++    exit 0
++  fi
++
+   # Try to stop gracefully, fallback to force if still alive
+   kill "$pid" 2>/dev/null || true
+ 
+   # Wait for graceful shutdown (up to ~2s)
+-  for i in {1..20}; do
++  for _ in {1..20}; do
+     if ! kill -0 "$pid" 2>/dev/null; then
+       break
+     fi
+@@ -43,7 +106,8 @@ if [[ -f "$PID_FILE" ]]; then
+     exit 1
+   fi
+ 
+-  rm -f "$PID_FILE" "${STATE_DIR}/server.log"
++  rm -f "$PID_FILE" "$SERVER_ID_FILE" "${STATE_DIR}/server.log"
++  mark_stopped "stop-server.sh"
+ 
+   # Only delete ephemeral /tmp directories
+   if [[ "$SESSION_DIR" == /tmp/* ]]; then
+diff --git a/skills/superpowers/brainstorming/spec-document-reviewer-prompt.md b/skills/superpowers/brainstorming/spec-document-reviewer-prompt.md
+index 35acbb6..6099312 100644
+--- a/skills/superpowers/brainstorming/spec-document-reviewer-prompt.md
++++ b/skills/superpowers/brainstorming/spec-document-reviewer-prompt.md
+@@ -7,7 +7,7 @@ Use this template when dispatching a spec document reviewer subagent.
+ **Dispatch after:** Spec document is written to docs/superpowers/specs/
+ 
+ ```
+-Task tool (general-purpose):
++Subagent (general-purpose):
+   description: "Review spec document"
+   prompt: |
+     You are a spec document reviewer. Verify this spec is complete and ready for planning.
+diff --git a/skills/superpowers/brainstorming/visual-companion.md b/skills/superpowers/brainstorming/visual-companion.md
+index 2113863..906c9ac 100644
+--- a/skills/superpowers/brainstorming/visual-companion.md
++++ b/skills/superpowers/brainstorming/visual-companion.md
+@@ -28,20 +28,30 @@ A question *about* a UI topic is not automatically a visual question. "What kind
+ 
+ The server watches a directory for HTML files and serves the newest one to the browser. You write HTML content to `screen_dir`, the user sees it in their browser and can click to select options. Selections are recorded to `state_dir/events` that you read on your next turn.
+ 
+-**Content fragments vs full documents:** If your HTML file starts with `<!DOCTYPE` or `<html`, the server serves it as-is (just injects the helper script). Otherwise, the server automatically wraps your content in the frame template — adding the header, CSS theme, selection indicator, and all interactive infrastructure. **Write content fragments by default.** Only write full documents when you need complete control over the page.
++**Content fragments vs full documents:** If your HTML file starts with `<!DOCTYPE` or `<html`, the server serves it as-is (just injects the helper script). Otherwise, the server automatically wraps your content in the frame template — adding the header, CSS theme, connection status, and all interactive infrastructure. **Write content fragments by default.** Only write full documents when you need complete control over the page.
+ 
+ ## Starting a Session
+ 
+ ```bash
+-# Start server with persistence (mockups saved to project)
+-scripts/start-server.sh --project-dir /path/to/project
++# Start AFTER the user approves the companion. --open auto-opens their browser on
++# the first screen; --project-dir persists mockups and enables same-port restart.
++scripts/start-server.sh --project-dir /path/to/project --open
+ 
+-# Returns: {"type":"server-started","port":52341,"url":"http://localhost:52341",
++# Returns: {"type":"server-started","port":52341,
++#           "url":"http://localhost:52341/?key=ab12…",
+ #           "screen_dir":"/path/to/project/.superpowers/brainstorm/12345-1706000000/content",
+ #           "state_dir":"/path/to/project/.superpowers/brainstorm/12345-1706000000/state"}
+ ```
+ 
+-Save `screen_dir` and `state_dir` from the response. Tell user to open the URL.
++Save `screen_dir` and `state_dir` from the response. With `--open`, the browser opens itself when you push the first screen — you don't need to ask the user to open it, but still share the URL as a fallback (headless/remote setups won't auto-open).
++
++**The URL contains a session key (`?key=…`).** The server rejects any request
++without it, so always give the user the **complete** URL from the `url` field —
++never strip the query string, and never hand out a bare `http://host:port`. The
++key gates HTTP and WebSocket access so a stray browser tab or another machine on
++the network can't read the screens or inject events. After the first load the
++browser remembers the key via a cookie, so reloads and `/files/*` assets work
++without repeating it.
+ 
+ **Finding connection info:** The server writes its startup JSON to `$STATE_DIR/server-info`. If you launched the server in the background and didn't capture stdout, read that file to get the URL and port. When using `--project-dir`, check `<project>/.superpowers/brainstorm/` for the session directory.
+ 
+@@ -49,33 +59,34 @@ Save `screen_dir` and `state_dir` from the response. Tell user to open the URL.
+ 
+ **Launching the server by platform:**
+ 
+-**Claude Code (macOS / Linux):**
++**Claude Code:**
+ ```bash
+-# Default mode works — the script backgrounds the server itself
+-scripts/start-server.sh --project-dir /path/to/project
++# Default mode works — the script backgrounds the server itself.
++scripts/start-server.sh --project-dir /path/to/project --open
+ ```
+ 
+-**Claude Code (Windows):**
+-```bash
+-# Windows auto-detects and uses foreground mode, which blocks the tool call.
+-# Use run_in_background: true on the Bash tool call so the server survives
+-# across conversation turns.
+-scripts/start-server.sh --project-dir /path/to/project
+-```
+-When calling this via the Bash tool, set `run_in_background: true`. Then read `$STATE_DIR/server-info` on the next turn to get the URL and port.
++On Windows, the script auto-detects and switches to foreground mode (which blocks the tool call). Use `run_in_background: true` on the Bash tool call so the server survives across conversation turns, then read `$STATE_DIR/server-info` on the next turn to get the URL and port.
+ 
+ **Codex:**
+ ```bash
+ # Codex reaps background processes. The script auto-detects CODEX_CI and
+ # switches to foreground mode. Run it normally — no extra flags needed.
+-scripts/start-server.sh --project-dir /path/to/project
++scripts/start-server.sh --project-dir /path/to/project --open
+ ```
+ 
+ **Gemini CLI:**
+ ```bash
+ # Use --foreground and set is_background: true on your shell tool call
+ # so the process survives across turns
+-scripts/start-server.sh --project-dir /path/to/project --foreground
++scripts/start-server.sh --project-dir /path/to/project --open --foreground
++```
++
++**Copilot CLI:**
++```bash
++# Use --foreground and start the server via the bash tool with mode: "async"
++# so the process survives across turns. Capture the returned shellId for
++# read_bash / stop_bash if you need to interact with it later.
++scripts/start-server.sh --project-dir /path/to/project --open --foreground
+ ```
+ 
+ **Other environments:** The server must keep running in the background across conversation turns. If your environment reaps detached processes, use `--foreground` and launch the command with your platform's background execution mechanism.
+@@ -94,10 +105,10 @@ Use `--url-host` to control what hostname is printed in the returned URL JSON.
+ ## The Loop
+ 
+ 1. **Check server is alive**, then **write HTML** to a new file in `screen_dir`:
+-   - Before each write, check that `$STATE_DIR/server-info` exists. If it doesn't (or `$STATE_DIR/server-stopped` exists), the server has shut down — restart it with `start-server.sh` before continuing. The server auto-exits after 30 minutes of inactivity.
++   - **Required: confirm the server is alive before referring to the URL or pushing a screen.** Check that `$STATE_DIR/server-info` exists and `$STATE_DIR/server-stopped` does not. If it has shut down, restart it with `start-server.sh` using the **same `--project-dir`** — it reuses the same port, so the user's open tab reconnects on its own (it shows a "paused" overlay while the server is down) and you don't need to send a new URL. The server auto-exits after 4 hours idle (configurable with `--idle-timeout-minutes`).
+    - Use semantic filenames: `platform.html`, `visual-style.html`, `layout.html`
+    - **Never reuse filenames** — each screen gets a fresh file
+-   - Use Write tool — **never use cat/heredoc** (dumps noise into terminal)
++   - Use your file-creation tool — **never use cat/heredoc** (dumps noise into terminal)
+    - Server automatically serves the newest file
+ 
+ 2. **Tell user what to expect and end your turn:**
+@@ -127,7 +138,7 @@ Use `--url-host` to control what hostname is printed in the returned URL JSON.
+ 
+ ## Writing Content Fragments
+ 
+-Write just the content that goes inside the page. The server wraps it in the frame template automatically (header, theme CSS, selection indicator, and all interactive infrastructure).
++Write just the content that goes inside the page. The server wraps it in the frame template automatically (header, theme CSS, connection status, and all interactive infrastructure).
+ 
+ **Minimal example:**
+ 
+@@ -173,7 +184,7 @@ The frame template provides these CSS classes for your content:
+ </div>
+ ```
+ 
+-**Multi-select:** Add `data-multiselect` to the container to let users select multiple options. Each click toggles the item. The indicator bar shows the count.
++**Multi-select:** Add `data-multiselect` to the container to let users select multiple options. Each click toggles the item's selected styling.
+ 
+ ```html
+ <div class="options" data-multiselect>
+diff --git a/skills/superpowers/dispatching-parallel-agents/SKILL.md b/skills/superpowers/dispatching-parallel-agents/SKILL.md
+index a6a3f5a..75e7e22 100644
+--- a/skills/superpowers/dispatching-parallel-agents/SKILL.md
++++ b/skills/superpowers/dispatching-parallel-agents/SKILL.md
+@@ -65,14 +65,17 @@ Each agent gets:
+ 
+ ### 3. Dispatch in Parallel
+ 
+-```typescript
+-// In Claude Code / AI environment
+-Task("Fix agent-tool-abort.test.ts failures")
+-Task("Fix batch-completion-behavior.test.ts failures")
+-Task("Fix tool-approval-race-conditions.test.ts failures")
+-// All three run concurrently
++Issue all three subagent dispatches in the same response — they run in parallel:
++
++```text
++Subagent (general-purpose): "Fix agent-tool-abort.test.ts failures"
++Subagent (general-purpose): "Fix batch-completion-behavior.test.ts failures"
++Subagent (general-purpose): "Fix tool-approval-race-conditions.test.ts failures"
++# All three run concurrently.
+ ```
+ 
++Multiple dispatch calls in one response = parallel execution. One per response = sequential.
++
+ ### 4. Review and Integrate
+ 
+ When agents return:
+diff --git a/skills/superpowers/executing-plans/SKILL.md b/skills/superpowers/executing-plans/SKILL.md
+index a591862..78d8854 100644
+--- a/skills/superpowers/executing-plans/SKILL.md
++++ b/skills/superpowers/executing-plans/SKILL.md
+@@ -11,7 +11,7 @@ Load plan, review critically, execute all tasks, report when complete.
+ 
+ **Announce at start:** "I'm using the executing-plans skill to implement this plan."
+ 
+-**Note:** Tell your human partner that Superpowers works much better with access to subagents. The quality of its work will be significantly higher if run on a platform with subagent support (such as Claude Code or Codex). If subagents are available, use superpowers:subagent-driven-development instead of this skill.
++**Note:** Tell your human partner that Superpowers works much better with access to subagents. The quality of its work will be significantly higher if run on a platform with subagent support (Claude Code, Codex CLI, Codex App, Copilot CLI, and Gemini CLI all qualify; see the per-platform tool refs in `../using-superpowers/references/`). If subagents are available, use superpowers:subagent-driven-development instead of this skill.
+ 
+ ## The Process
+ 
+@@ -19,7 +19,7 @@ Load plan, review critically, execute all tasks, report when complete.
+ 1. Read plan file
+ 2. Review critically - identify any questions or concerns about the plan
+ 3. If concerns: Raise them with your human partner before starting
+-4. If no concerns: Create TodoWrite and proceed
++4. If no concerns: Create todos for the plan items and proceed
+ 
+ ### Step 2: Execute Tasks
+ 
+diff --git a/skills/superpowers/finishing-a-development-branch/SKILL.md b/skills/superpowers/finishing-a-development-branch/SKILL.md
+index 43da0ae..7f5337a 100644
+--- a/skills/superpowers/finishing-a-development-branch/SKILL.md
++++ b/skills/superpowers/finishing-a-development-branch/SKILL.md
+@@ -123,16 +123,6 @@ git branch -d <feature-branch>
+ ```bash
+ # Push branch
+ git push -u origin <feature-branch>
+-
+-# Create PR
+-gh pr create --title "<title>" --body "$(cat <<'EOF'
+-## Summary
+-<2-3 bullets of what changed>
+-
+-## Test Plan
+-- [ ] <verification steps>
+-EOF
+-)"
+ ```
+ 
+ **Do NOT clean up worktree** — user needs it alive to iterate on PR feedback.
+@@ -180,7 +170,7 @@ WORKTREE_PATH=$(git rev-parse --show-toplevel)
+ 
+ **If `GIT_DIR == GIT_COMMON`:** Normal repo, no worktree to clean up. Done.
+ 
+-**If worktree path is under `.worktrees/`, `worktrees/`, or `~/.config/superpowers/worktrees/`:** Superpowers created this worktree — we own cleanup.
++**If worktree path is under `.worktrees/` or `worktrees/`:** Superpowers created this worktree — we own cleanup.
+ 
+ ```bash
+ MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
+@@ -224,7 +214,7 @@ git worktree prune  # Self-healing: clean up any stale registrations
+ 
+ **Cleaning up harness-owned worktrees**
+ - **Problem:** Removing a worktree the harness created causes phantom state
+-- **Fix:** Only clean up worktrees under `.worktrees/`, `worktrees/`, or `~/.config/superpowers/worktrees/`
++- **Fix:** Only clean up worktrees under `.worktrees/` or `worktrees/`
+ 
+ **No confirmation for discard**
+ - **Problem:** Accidentally delete work
+diff --git a/skills/superpowers/receiving-code-review/SKILL.md b/skills/superpowers/receiving-code-review/SKILL.md
+index 4ea72cd..4c77a10 100644
+--- a/skills/superpowers/receiving-code-review/SKILL.md
++++ b/skills/superpowers/receiving-code-review/SKILL.md
+@@ -27,7 +27,7 @@ WHEN receiving code review feedback:
+ ## Forbidden Responses
+ 
+ **NEVER:**
+-- "You're absolutely right!" (explicit CLAUDE.md violation)
++- "You're absolutely right!" (explicit instruction-file violation)
+ - "Great point!" / "Excellent feedback!" (performative)
+ - "Let me implement that now" (before verification)
+ 
+@@ -126,7 +126,7 @@ Push back when:
+ - Reference working tests/code
+ - Involve your human partner if architectural
+ 
+-**Signal if uncomfortable pushing back out loud:** "Strange things are afoot at the Circle K"
++**If you're uncomfortable pushing back out loud:** Name that tension, then tell your partner about the issue you've seen. They'll appreciate your honesty.
+ 
+ ## Acknowledging Correct Feedback
+ 
+diff --git a/skills/superpowers/requesting-code-review/SKILL.md b/skills/superpowers/requesting-code-review/SKILL.md
+index 34b8340..4b8aa60 100644
+--- a/skills/superpowers/requesting-code-review/SKILL.md
++++ b/skills/superpowers/requesting-code-review/SKILL.md
+@@ -31,7 +31,7 @@ HEAD_SHA=$(git rev-parse HEAD)
+ 
+ **2. Dispatch code reviewer subagent:**
+ 
+-Use Task tool with `general-purpose` type, fill template at `code-reviewer.md`
++Dispatch a `general-purpose` subagent, filling the template at [code-reviewer.md](code-reviewer.md)
+ 
+ **Placeholders:**
+ - `{DESCRIPTION}` - Brief summary of what you built
+@@ -100,4 +100,4 @@ You: [Fix progress indicators]
+ - Show code/tests that prove it works
+ - Request clarification
+ 
+-See template at: requesting-code-review/code-reviewer.md
++See template at: [code-reviewer.md](code-reviewer.md)
+diff --git a/skills/superpowers/requesting-code-review/code-reviewer.md b/skills/superpowers/requesting-code-review/code-reviewer.md
+index 525e4b4..db84ae2 100644
+--- a/skills/superpowers/requesting-code-review/code-reviewer.md
++++ b/skills/superpowers/requesting-code-review/code-reviewer.md
+@@ -5,7 +5,7 @@ Use this template when dispatching a code reviewer subagent.
+ **Purpose:** Review completed work against requirements and code quality standards before it cascades into more work.
+ 
+ ```
+-Task tool (general-purpose):
++Subagent (general-purpose):
+   description: "Review code changes"
+   prompt: |
+     You are a Senior Code Reviewer with expertise in software architecture,
+@@ -14,22 +14,26 @@ Task tool (general-purpose):
+ 
+     ## What Was Implemented
+ 
+-    {DESCRIPTION}
++    [DESCRIPTION]
+ 
+     ## Requirements / Plan
+ 
+-    {PLAN_OR_REQUIREMENTS}
++    [PLAN_OR_REQUIREMENTS]
+ 
+     ## Git Range to Review
+ 
+-    **Base:** {BASE_SHA}
+-    **Head:** {HEAD_SHA}
++    **Base:** [BASE_SHA]
++    **Head:** [HEAD_SHA]
+ 
+     ```bash
+-    git diff --stat {BASE_SHA}..{HEAD_SHA}
+-    git diff {BASE_SHA}..{HEAD_SHA}
++    git diff --stat [BASE_SHA]..[HEAD_SHA]
++    git diff [BASE_SHA]..[HEAD_SHA]
+     ```
+ 
++    ## Read-Only Review
++
++    Your review is read-only on this checkout. Do not mutate the working tree, the index, HEAD, or branch state in any way. Use tools like `git show`, `git diff`, and `git log` to inspect history. If you need a working copy of a different revision, check it out into a separate temporary directory (e.g. `git worktree add /tmp/review-[SHA] [SHA]`) — never move HEAD on this checkout.
++
+     ## What to Check
+ 
+     **Plan alignment:**
+@@ -122,10 +126,10 @@ Task tool (general-purpose):
+ ```
+ 
+ **Placeholders:**
+-- `{DESCRIPTION}` — brief summary of what was built
+-- `{PLAN_OR_REQUIREMENTS}` — what it should do (plan file path, task text, or requirements)
+-- `{BASE_SHA}` — starting commit
+-- `{HEAD_SHA}` — ending commit
++- `[DESCRIPTION]` — brief summary of what was built
++- `[PLAN_OR_REQUIREMENTS]` — what it should do (plan file path, task text, or requirements)
++- `[BASE_SHA]` — starting commit
++- `[HEAD_SHA]` — ending commit
+ 
+ **Reviewer returns:** Strengths, Issues (Critical / Important / Minor), Recommendations, Assessment
+ 
+diff --git a/skills/superpowers/subagent-driven-development/SKILL.md b/skills/superpowers/subagent-driven-development/SKILL.md
+index ea7ac8f..d8ca081 100644
+--- a/skills/superpowers/subagent-driven-development/SKILL.md
++++ b/skills/superpowers/subagent-driven-development/SKILL.md
+@@ -5,11 +5,14 @@ description: Use when executing implementation plans with independent tasks in t
+ 
+ # Subagent-Driven Development
+ 
+-Execute plan by dispatching fresh subagent per task, with two-stage review after each: spec compliance review first, then code quality review.
++Execute plan by dispatching a fresh implementer subagent per task, a task review (spec compliance + code quality) after each, and a broad whole-branch review at the end.
+ 
+ **Why subagents:** You delegate tasks to specialized agents with isolated context. By precisely crafting their instructions and context, you ensure they stay focused and succeed at their task. They should never inherit your session's context or history — you construct exactly what they need. This also preserves your own context for coordination work.
+ 
+-**Core principle:** Fresh subagent per task + two-stage review (spec then quality) = high quality, fast iteration
++**Core principle:** Fresh subagent per task + task review (spec + quality) + broad final review = high quality, fast iteration
++
++**Narration:** between tool calls, narrate at most one short line — the
++ledger and the tool results carry the record.
+ 
+ **Continuous execution:** Do not pause to check in with your human partner between tasks. Execute all tasks from the plan without stopping. The only reasons to stop are: BLOCKED status you cannot resolve, ambiguity that genuinely prevents progress, or all tasks complete. "Should I continue?" prompts and progress summaries waste their time — they asked you to execute the plan, so execute it.
+ 
+@@ -36,7 +39,7 @@ digraph when_to_use {
+ **vs. Executing Plans (parallel session):**
+ - Same session (no context switch)
+ - Fresh subagent per task (no context pollution)
+-- Two-stage review after each task: spec compliance first, then code quality
++- Review after each task (spec compliance + code quality), broad review at the end
+ - Faster iteration (no human-in-loop between tasks)
+ 
+ ## The Process
+@@ -51,41 +54,48 @@ digraph process {
+         "Implementer subagent asks questions?" [shape=diamond];
+         "Answer questions, provide context" [shape=box];
+         "Implementer subagent implements, tests, commits, self-reviews" [shape=box];
+-        "Dispatch spec reviewer subagent (./spec-reviewer-prompt.md)" [shape=box];
+-        "Spec reviewer subagent confirms code matches spec?" [shape=diamond];
+-        "Implementer subagent fixes spec gaps" [shape=box];
+-        "Dispatch code quality reviewer subagent (./code-quality-reviewer-prompt.md)" [shape=box];
+-        "Code quality reviewer subagent approves?" [shape=diamond];
+-        "Implementer subagent fixes quality issues" [shape=box];
+-        "Mark task complete in TodoWrite" [shape=box];
++        "Write diff file, dispatch task reviewer subagent (./task-reviewer-prompt.md)" [shape=box];
++        "Task reviewer reports spec ✅ and quality approved?" [shape=diamond];
++        "Dispatch fix subagent for Critical/Important findings" [shape=box];
++        "Mark task complete in todo list and progress ledger" [shape=box];
+     }
+ 
+-    "Read plan, extract all tasks with full text, note context, create TodoWrite" [shape=box];
++    "Read plan, note context and global constraints, create todos" [shape=box];
+     "More tasks remain?" [shape=diamond];
+-    "Dispatch final code reviewer subagent for entire implementation" [shape=box];
++    "Dispatch final code reviewer subagent (../requesting-code-review/code-reviewer.md)" [shape=box];
+     "Use superpowers:finishing-a-development-branch" [shape=box style=filled fillcolor=lightgreen];
+ 
+-    "Read plan, extract all tasks with full text, note context, create TodoWrite" -> "Dispatch implementer subagent (./implementer-prompt.md)";
++    "Read plan, note context and global constraints, create todos" -> "Dispatch implementer subagent (./implementer-prompt.md)";
+     "Dispatch implementer subagent (./implementer-prompt.md)" -> "Implementer subagent asks questions?";
+     "Implementer subagent asks questions?" -> "Answer questions, provide context" [label="yes"];
+     "Answer questions, provide context" -> "Dispatch implementer subagent (./implementer-prompt.md)";
+     "Implementer subagent asks questions?" -> "Implementer subagent implements, tests, commits, self-reviews" [label="no"];
+-    "Implementer subagent implements, tests, commits, self-reviews" -> "Dispatch spec reviewer subagent (./spec-reviewer-prompt.md)";
+-    "Dispatch spec reviewer subagent (./spec-reviewer-prompt.md)" -> "Spec reviewer subagent confirms code matches spec?";
+-    "Spec reviewer subagent confirms code matches spec?" -> "Implementer subagent fixes spec gaps" [label="no"];
+-    "Implementer subagent fixes spec gaps" -> "Dispatch spec reviewer subagent (./spec-reviewer-prompt.md)" [label="re-review"];
+-    "Spec reviewer subagent confirms code matches spec?" -> "Dispatch code quality reviewer subagent (./code-quality-reviewer-prompt.md)" [label="yes"];
+-    "Dispatch code quality reviewer subagent (./code-quality-reviewer-prompt.md)" -> "Code quality reviewer subagent approves?";
+-    "Code quality reviewer subagent approves?" -> "Implementer subagent fixes quality issues" [label="no"];
+-    "Implementer subagent fixes quality issues" -> "Dispatch code quality reviewer subagent (./code-quality-reviewer-prompt.md)" [label="re-review"];
+-    "Code quality reviewer subagent approves?" -> "Mark task complete in TodoWrite" [label="yes"];
+-    "Mark task complete in TodoWrite" -> "More tasks remain?";
++    "Implementer subagent implements, tests, commits, self-reviews" -> "Write diff file, dispatch task reviewer subagent (./task-reviewer-prompt.md)";
++    "Write diff file, dispatch task reviewer subagent (./task-reviewer-prompt.md)" -> "Task reviewer reports spec ✅ and quality approved?";
++    "Task reviewer reports spec ✅ and quality approved?" -> "Dispatch fix subagent for Critical/Important findings" [label="no"];
++    "Dispatch fix subagent for Critical/Important findings" -> "Write diff file, dispatch task reviewer subagent (./task-reviewer-prompt.md)" [label="re-review"];
++    "Task reviewer reports spec ✅ and quality approved?" -> "Mark task complete in todo list and progress ledger" [label="yes"];
++    "Mark task complete in todo list and progress ledger" -> "More tasks remain?";
+     "More tasks remain?" -> "Dispatch implementer subagent (./implementer-prompt.md)" [label="yes"];
+-    "More tasks remain?" -> "Dispatch final code reviewer subagent for entire implementation" [label="no"];
+-    "Dispatch final code reviewer subagent for entire implementation" -> "Use superpowers:finishing-a-development-branch";
++    "More tasks remain?" -> "Dispatch final code reviewer subagent (../requesting-code-review/code-reviewer.md)" [label="no"];
++    "Dispatch final code reviewer subagent (../requesting-code-review/code-reviewer.md)" -> "Use superpowers:finishing-a-development-branch";
+ }
+ ```
+ 
++## Pre-Flight Plan Review
++
++Before dispatching Task 1, scan the plan once for conflicts:
++
++- tasks that contradict each other or the plan's Global Constraints
++- anything the plan explicitly mandates that the review rubric treats as a
++  defect (a test that asserts nothing, verbatim duplication of a logic block)
++
++Present everything you find to your human partner as one batched question —
++each finding beside the plan text that mandates it, asking which governs —
++before execution begins, not one interrupt per discovery mid-plan. If the
++scan is clean, proceed without comment. The review loop remains the net for
++conflicts that only emerge from implementation.
++
+ ## Model Selection
+ 
+ Use the least powerful model that can handle each role to conserve cost and increase speed.
+@@ -94,9 +104,27 @@ Use the least powerful model that can handle each role to conserve cost and incr
+ 
+ **Integration and judgment tasks** (multi-file coordination, pattern matching, debugging): use a standard model.
+ 
+-**Architecture, design, and review tasks**: use the most capable available model.
++**Architecture and design tasks**: use the most capable available model.
++The final whole-branch review is one of these — dispatch it on the most
++capable available model, not the session default.
++
++**Review tasks**: choose the model with the same judgment, scaled to the
++diff's size, complexity, and risk. A small mechanical diff does not need the
++most capable model; a subtle concurrency change does.
++
++**Always specify the model explicitly when dispatching a subagent.** An
++omitted model inherits your session's model — often the most capable and
++most expensive — which silently defeats this section.
+ 
+-**Task complexity signals:**
++**Turn count beats token price.** Wall-clock and context cost scale with how
++many turns a subagent takes, and the cheapest models routinely take 2-3× the
++turns on multi-step work — costing more overall. Use a mid-tier model as the
++floor for reviewers and for implementers working from prose descriptions.
++When the task's plan text contains the complete code to write, the
++implementation is transcription plus testing: use the cheapest tier for
++that implementer. Single-file mechanical fixes also take the cheapest tier.
++
++**Task complexity signals (implementation tasks):**
+ - Touches 1-2 files with a complete spec → cheap model
+ - Touches multiple files with integration concerns → standard model
+ - Requires design judgment or broad codebase understanding → most capable model
+@@ -105,7 +133,7 @@ Use the least powerful model that can handle each role to conserve cost and incr
+ 
+ Implementer subagents report one of four statuses. Handle each appropriately:
+ 
+-**DONE:** Proceed to spec compliance review.
++**DONE:** Generate the review package (`scripts/review-package BASE HEAD`, from this skill's directory — it prints the unique file path it wrote; BASE is the commit you recorded before dispatching the implementer — never `HEAD~1`, which silently drops all but the last commit of a multi-commit task), then dispatch the task reviewer with the printed path.
+ 
+ **DONE_WITH_CONCERNS:** The implementer completed the work but flagged doubts. Read the concerns before proceeding. If the concerns are about correctness or scope, address them before review. If they're observations (e.g., "this file is getting large"), note them and proceed to review.
+ 
+@@ -119,11 +147,127 @@ Implementer subagents report one of four statuses. Handle each appropriately:
+ 
+ **Never** ignore an escalation or force the same model to retry without changes. If the implementer said it's stuck, something needs to change.
+ 
++## Handling Reviewer ⚠️ Items
++
++The task reviewer may report "⚠️ Cannot verify from diff" items — requirements
++that live in unchanged code or span tasks. These do not block the rest of the
++review, but you must resolve each one yourself before marking the task
++complete: you hold the plan and cross-task context the reviewer
++lacks. If you confirm an item is a real gap, treat it as a failed spec
++review — send it back to the implementer and re-review.
++
++## Constructing Reviewer Prompts
++
++Per-task reviews are task-scoped gates. The broad review happens once, at the
++final whole-branch review. When you fill a reviewer template:
++
++- Do not add open-ended directives like "check all uses" or "run race tests
++  if useful" without a concrete, task-specific reason
++- Do not ask a reviewer to re-run tests the implementer already ran on the
++  same code — the implementer's report carries the test evidence
++- Do not pre-judge findings for the reviewer — never instruct a reviewer to
++  ignore or not flag a specific issue. If you believe a finding would be a
++  false positive, let the reviewer raise it and adjudicate it in the review
++  loop. If the prompt you are writing contains "do not flag," "don't treat X
++  as a defect," "at most Minor," or "the plan chose" — stop: you are
++  pre-judging, usually to spare yourself a review loop.
++- The global-constraints block you hand the reviewer is its attention
++  lens. Copy the binding requirements verbatim from the plan's Global
++  Constraints section or the spec: exact values, exact formats, and the
++  stated relationships between components ("same layout as X", "matches
++  Y"). The reviewer's template already carries the process rules (YAGNI,
++  test hygiene, review method) — the constraints block is for what THIS
++  project's spec demands.
++- Hand the reviewer its diff as a file: run this skill's
++  `scripts/review-package BASE HEAD` and pass the reviewer the file path
++  it prints (or, without bash: `git log --oneline`, `git diff --stat`,
++  and `git diff -U10` for the range, redirected to one uniquely named
++  file). The output never enters your own context, and the reviewer sees
++  the commit list, stat summary, and full diff with context in one Read
++  call. Use the BASE you recorded before dispatching the implementer —
++  never `HEAD~1`, which silently truncates multi-commit tasks.
++- A dispatch prompt describes one task, not the session's history. Do not
++  paste accumulated prior-task summaries ("state after Tasks 1-3") into
++  later dispatches — a real session's dispatch hit 42k chars of which 99%
++  was pasted history. A fresh subagent needs its task, the interfaces it
++  touches, and the global constraints. Nothing else.
++- Dispatch fix subagents for Critical and Important findings. Record Minor
++  findings in the progress ledger as you go, and point the final
++  whole-branch review at that list so it can triage which must be fixed
++  before merge. A roll-up nobody reads is a silent discard.
++- A finding labeled plan-mandated — or any finding that conflicts with
++  what the plan's text requires — is the human's decision, like any plan
++  contradiction: present the finding and the plan text, ask which governs.
++  Do not dismiss the finding because the plan mandates it, and do not
++  dispatch a fix that contradicts the plan without asking.
++- The final whole-branch review gets a package too: run
++  `scripts/review-package MERGE_BASE HEAD` (MERGE_BASE = the commit the
++  branch started from, e.g. `git merge-base main HEAD`) and include the
++  printed path in the final review dispatch, so the final reviewer reads
++  one file instead of re-deriving the branch diff with git commands.
++- Every fix dispatch carries the implementer contract: the fix subagent
++  re-runs the tests covering its change and reports the results. Name the
++  covering test files in the dispatch — a one-line fix does not need the
++  whole suite. Before re-dispatching the reviewer, confirm the fix report
++  contains the covering tests, the command run, and the output; dispatch
++  the re-review once all three are present.
++- If the final whole-branch review returns findings, dispatch ONE fix
++  subagent with the complete findings list — not one fixer per finding.
++  Per-finding fixers each rebuild context and re-run suites; a real
++  session's final-review fix wave cost more than all its tasks combined.
++
++## File Handoffs
++
++Everything you paste into a dispatch prompt — and everything a subagent
++prints back — stays resident in your context for the rest of the session
++and is re-read on every later turn. Hand artifacts over as files:
++
++- **Task brief:** before dispatching an implementer, run this skill's
++  `scripts/task-brief PLAN_FILE N` — it extracts the task's full text to a
++  uniquely named file and prints the path. Compose the dispatch so the
++  brief stays the single source of requirements. Your dispatch should
++  contain: (1) one line on where this task fits in the project; (2) the
++  brief path, introduced as "read this first — it is your requirements,
++  with the exact values to use verbatim"; (3) interfaces and decisions
++  from earlier tasks that the brief cannot know; (4) your resolution of
++  any ambiguity you noticed in the brief; (5) the report-file path and
++  report contract. Exact values (numbers, magic strings, signatures, test
++  cases) appear only in the brief.
++- **Report file:** name the implementer's report file after the brief
++  (brief `…/task-N-brief.md` → report `…/task-N-report.md`) and put it in
++  the dispatch prompt. The implementer writes the full report there and
++  returns only status, commits, a one-line test summary, and concerns.
++- **Reviewer inputs:** the task reviewer gets three paths — the same brief
++  file, the report file, and the review package — plus the global
++  constraints that bind the task.
++- Fix dispatches append their fix report (with test results) to the same
++  report file and return a short summary; re-reviews read the updated file.
++
++## Durable Progress
++
++Conversation memory does not survive compaction. In real sessions,
++controllers that lost their place have re-dispatched entire completed task
++sequences — the single most expensive failure observed. Track progress in
++a ledger file, not only in todos.
++
++- At skill start, check for a ledger:
++  `cat "$(git rev-parse --show-toplevel)/.superpowers/sdd/progress.md"`. Tasks listed there
++  as complete are DONE — do not re-dispatch them; resume at the first task
++  not marked complete.
++- When a task's review comes back clean, append one line to the ledger in
++  the same message as your other bookkeeping:
++  `Task N: complete (commits <base7>..<head7>, review clean)`.
++- The ledger is your recovery map: the commits it names exist in git even
++  when your context no longer remembers creating them. After compaction,
++  trust the ledger and `git log` over your own recollection.
++- `git clean -fdx` will destroy the ledger (it's git-ignored scratch); if
++  that happens, recover from `git log`.
++
+ ## Prompt Templates
+ 
+-- `./implementer-prompt.md` - Dispatch implementer subagent
+-- `./spec-reviewer-prompt.md` - Dispatch spec compliance reviewer subagent
+-- `./code-quality-reviewer-prompt.md` - Dispatch code quality reviewer subagent
++- [implementer-prompt.md](implementer-prompt.md) - Dispatch implementer subagent
++- [task-reviewer-prompt.md](task-reviewer-prompt.md) - Dispatch task reviewer subagent (spec compliance + code quality)
++- Final whole-branch review: use superpowers:requesting-code-review's [code-reviewer.md](../requesting-code-review/code-reviewer.md)
+ 
+ ## Example Workflow
+ 
+@@ -131,13 +275,11 @@ Implementer subagents report one of four statuses. Handle each appropriately:
+ You: I'm using Subagent-Driven Development to execute this plan.
+ 
+ [Read plan file once: docs/superpowers/plans/feature-plan.md]
+-[Extract all 5 tasks with full text and context]
+-[Create TodoWrite with all tasks]
++[Create todos for all tasks]
+ 
+ Task 1: Hook installation script
+ 
+-[Get Task 1 text and context (already extracted)]
+-[Dispatch implementation subagent with full task text + context]
++[Run task-brief for Task 1; dispatch implementer with brief + report paths + context]
+ 
+ Implementer: "Before I begin - should the hook be installed at user or system level?"
+ 
+@@ -150,18 +292,15 @@ Implementer: "Got it. Implementing now..."
+   - Self-review: Found I missed --force flag, added it
+   - Committed
+ 
+-[Dispatch spec compliance reviewer]
+-Spec reviewer: ✅ Spec compliant - all requirements met, nothing extra
+-
+-[Get git SHAs, dispatch code quality reviewer]
+-Code reviewer: Strengths: Good test coverage, clean. Issues: None. Approved.
++[Run review-package, dispatch task reviewer with the printed path]
++Task reviewer: Spec ✅ - all requirements met, nothing extra.
++  Strengths: Good test coverage, clean. Issues: None. Task quality: Approved.
+ 
+ [Mark Task 1 complete]
+ 
+ Task 2: Recovery modes
+ 
+-[Get Task 2 text and context (already extracted)]
+-[Dispatch implementation subagent with full task text + context]
++[Run task-brief for Task 2; dispatch implementer with brief + report paths + context]
+ 
+ Implementer: [No questions, proceeds]
+ Implementer:
+@@ -170,25 +309,17 @@ Implementer:
+   - Self-review: All good
+   - Committed
+ 
+-[Dispatch spec compliance reviewer]
+-Spec reviewer: ❌ Issues:
++[Run review-package, dispatch task reviewer with the printed path]
++Task reviewer: Spec ❌:
+   - Missing: Progress reporting (spec says "report every 100 items")
+   - Extra: Added --json flag (not requested)
++  Issues (Important): Magic number (100)
+ 
+-[Implementer fixes issues]
+-Implementer: Removed --json flag, added progress reporting
+-
+-[Spec reviewer reviews again]
+-Spec reviewer: ✅ Spec compliant now
+-
+-[Dispatch code quality reviewer]
+-Code reviewer: Strengths: Solid. Issues (Important): Magic number (100)
+-
+-[Implementer fixes]
+-Implementer: Extracted PROGRESS_INTERVAL constant
++[Dispatch fix subagent with all findings]
++Fixer: Removed --json flag, added progress reporting, extracted PROGRESS_INTERVAL constant
+ 
+-[Code reviewer reviews again]
+-Code reviewer: ✅ Approved
++[Task reviewer reviews again]
++Task reviewer: Spec ✅. Task quality: Approved.
+ 
+ [Mark Task 2 complete]
+ 
+@@ -215,20 +346,20 @@ Done!
+ - Review checkpoints automatic
+ 
+ **Efficiency gains:**
+-- No file reading overhead (controller provides full text)
+-- Controller curates exactly what context is needed
++- Controller curates exactly what context is needed; bulk artifacts move
++  as files, not pasted text
+ - Subagent gets complete information upfront
+ - Questions surfaced before work begins (not after)
+ 
+ **Quality gates:**
+ - Self-review catches issues before handoff
+-- Two-stage review: spec compliance, then code quality
++- Task review carries two verdicts: spec compliance and code quality
+ - Review loops ensure fixes actually work
+ - Spec compliance prevents over/under-building
+ - Code quality ensures implementation is well-built
+ 
+ **Cost:**
+-- More subagent invocations (implementer + 2 reviewers per task)
++- More subagent invocations (implementer + reviewer per task)
+ - Controller does more prep work (extracting all tasks upfront)
+ - Review loops add iterations
+ - But catches issues early (cheaper than debugging later)
+@@ -237,17 +368,25 @@ Done!
+ 
+ **Never:**
+ - Start implementation on main/master branch without explicit user consent
+-- Skip reviews (spec compliance OR code quality)
++- Skip task review, or accept a report missing either verdict (spec compliance AND task quality are both required)
+ - Proceed with unfixed issues
+ - Dispatch multiple implementation subagents in parallel (conflicts)
+-- Make subagent read plan file (provide full text instead)
++- Make a subagent read the whole plan file (hand it its task brief —
++  `scripts/task-brief` — instead)
+ - Skip scene-setting context (subagent needs to understand where task fits)
+ - Ignore subagent questions (answer before letting them proceed)
+-- Accept "close enough" on spec compliance (spec reviewer found issues = not done)
++- Accept "close enough" on spec compliance (reviewer found spec issues = not done)
+ - Skip review loops (reviewer found issues = implementer fixes = review again)
+ - Let implementer self-review replace actual review (both are needed)
+-- **Start code quality review before spec compliance is ✅** (wrong order)
+-- Move to next task while either review has open issues
++- Tell a reviewer what not to flag, or pre-rate a finding's severity in the
++  dispatch prompt ("treat it as Minor at most") — the plan's example code is
++  a starting point, not evidence that its weaknesses were chosen
++- Dispatch a task reviewer without a diff file — generate it first
++  (`scripts/review-package BASE HEAD`) and name the printed path in the
++  prompt
++- Move to next task while the review has open Critical/Important issues
++- Re-dispatch a task the progress ledger already marks complete — check
++  the ledger (and `git log`) after any compaction or resume
+ 
+ **If subagent asks questions:**
+ - Answer clearly and completely
+@@ -269,7 +408,7 @@ Done!
+ **Required workflow skills:**
+ - **superpowers:using-git-worktrees** - Ensures isolated workspace (creates one or verifies existing)
+ - **superpowers:writing-plans** - Creates the plan this skill executes
+-- **superpowers:requesting-code-review** - Code review template for reviewer subagents
++- **superpowers:requesting-code-review** - Code review template for the final whole-branch review
+ - **superpowers:finishing-a-development-branch** - Complete development after all tasks
+ 
+ **Subagents should use:**
+diff --git a/skills/superpowers/subagent-driven-development/code-quality-reviewer-prompt.md b/skills/superpowers/subagent-driven-development/code-quality-reviewer-prompt.md
+deleted file mode 100644
+index 51f901a..0000000
+--- a/skills/superpowers/subagent-driven-development/code-quality-reviewer-prompt.md
++++ /dev/null
+@@ -1,25 +0,0 @@
+-# Code Quality Reviewer Prompt Template
+-
+-Use this template when dispatching a code quality reviewer subagent.
+-
+-**Purpose:** Verify implementation is well-built (clean, tested, maintainable)
+-
+-**Only dispatch after spec compliance review passes.**
+-
+-```
+-Task tool (general-purpose):
+-  Use template at requesting-code-review/code-reviewer.md
+-
+-  DESCRIPTION: [task summary, from implementer's report]
+-  PLAN_OR_REQUIREMENTS: Task N from [plan-file]
+-  BASE_SHA: [commit before task]
+-  HEAD_SHA: [current commit]
+-```
+-
+-**In addition to standard code quality concerns, the reviewer should check:**
+-- Does each file have one clear responsibility with a well-defined interface?
+-- Are units decomposed so they can be understood and tested independently?
+-- Is the implementation following the file structure from the plan?
+-- Did this implementation create new files that are already large, or significantly grow existing files? (Don't flag pre-existing file sizes — focus on what this change contributed.)
+-
+-**Code reviewer returns:** Strengths, Issues (Critical/Important/Minor), Assessment
+diff --git a/skills/superpowers/subagent-driven-development/implementer-prompt.md b/skills/superpowers/subagent-driven-development/implementer-prompt.md
+index 400c103..218fcfe 100644
+--- a/skills/superpowers/subagent-driven-development/implementer-prompt.md
++++ b/skills/superpowers/subagent-driven-development/implementer-prompt.md
+@@ -3,14 +3,17 @@
+ Use this template when dispatching an implementer subagent.
+ 
+ ```
+-Task tool (general-purpose):
++Subagent (general-purpose):
+   description: "Implement Task N: [task name]"
++  model: [MODEL — REQUIRED: choose per SKILL.md Model Selection; an omitted
++         model silently inherits the session's most expensive one]
+   prompt: |
+     You are implementing Task N: [task name]
+ 
+     ## Task Description
+ 
+-    [FULL TEXT of task from plan - paste it here, don't make subagent read file]
++    Read your task brief first: [BRIEF_FILE]
++    It contains the full task text from the plan.
+ 
+     ## Context
+ 
+@@ -41,6 +44,9 @@ Task tool (general-purpose):
+     **While you work:** If you encounter something unexpected or unclear, **ask questions**.
+     It's always OK to pause and clarify. Don't guess or make assumptions.
+ 
++    While iterating, run the focused test for what you're changing; run the
++    full suite once before committing, not after every edit.
++
+     ## Code Organization
+ 
+     You reason best about code you can hold in context at once, and your edits are more
+@@ -94,19 +100,39 @@ Task tool (general-purpose):
+     - Do tests actually verify behavior (not just mock behavior)?
+     - Did I follow TDD if required?
+     - Are tests comprehensive?
++    - Is the test output pristine (no stray warnings or noise)?
+ 
+     If you find issues during self-review, fix them now before reporting.
+ 
++    ## After Review Findings
++
++    If a reviewer finds issues and you fix them, re-run the tests that cover
++    the amended code and append the results to your report file. Reviewers
++    will not re-run tests for you — your report is the test evidence.
++
+     ## Report Format
+ 
+-    When done, report:
+-    - **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
++    Write your full report to [REPORT_FILE]:
+     - What you implemented (or what you attempted, if blocked)
+     - What you tested and test results
++    - **TDD Evidence** (if TDD was required for this task):
++      - RED: command run, relevant failing output before implementation, and why the failure was expected
++      - GREEN: command run and relevant passing output after implementation
+     - Files changed
+     - Self-review findings (if any)
+     - Any issues or concerns
+ 
++    Then report back with ONLY (under 15 lines — the detail lives in the
++    report file):
++    - **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
++    - Commits created (short SHA + subject)
++    - One-line test summary (e.g. "14/14 passing, output pristine")
++    - Your concerns, if any
++    - The report file path
++
++    If BLOCKED or NEEDS_CONTEXT, put the specifics in the final message
++    itself — the controller acts on it directly.
++
+     Use DONE_WITH_CONCERNS if you completed the work but have doubts about correctness.
+     Use BLOCKED if you cannot complete the task. Use NEEDS_CONTEXT if you need
+     information that wasn't provided. Never silently produce work you're unsure about.
+diff --git a/skills/superpowers/subagent-driven-development/spec-reviewer-prompt.md b/skills/superpowers/subagent-driven-development/spec-reviewer-prompt.md
+deleted file mode 100644
+index ab5ddb8..0000000
+--- a/skills/superpowers/subagent-driven-development/spec-reviewer-prompt.md
++++ /dev/null
+@@ -1,61 +0,0 @@
+-# Spec Compliance Reviewer Prompt Template
+-
+-Use this template when dispatching a spec compliance reviewer subagent.
+-
+-**Purpose:** Verify implementer built what was requested (nothing more, nothing less)
+-
+-```
+-Task tool (general-purpose):
+-  description: "Review spec compliance for Task N"
+-  prompt: |
+-    You are reviewing whether an implementation matches its specification.
+-
+-    ## What Was Requested
+-
+-    [FULL TEXT of task requirements]
+-
+-    ## What Implementer Claims They Built
+-
+-    [From implementer's report]
+-
+-    ## CRITICAL: Do Not Trust the Report
+-
+-    The implementer finished suspiciously quickly. Their report may be incomplete,
+-    inaccurate, or optimistic. You MUST verify everything independently.
+-
+-    **DO NOT:**
+-    - Take their word for what they implemented
+-    - Trust their claims about completeness
+-    - Accept their interpretation of requirements
+-
+-    **DO:**
+-    - Read the actual code they wrote
+-    - Compare actual implementation to requirements line by line
+-    - Check for missing pieces they claimed to implement
+-    - Look for extra features they didn't mention
+-
+-    ## Your Job
+-
+-    Read the implementation code and verify:
+-
+-    **Missing requirements:**
+-    - Did they implement everything that was requested?
+-    - Are there requirements they skipped or missed?
+-    - Did they claim something works but didn't actually implement it?
+-
+-    **Extra/unneeded work:**
+-    - Did they build things that weren't requested?
+-    - Did they over-engineer or add unnecessary features?
+-    - Did they add "nice to haves" that weren't in spec?
+-
+-    **Misunderstandings:**
+-    - Did they interpret requirements differently than intended?
+-    - Did they solve the wrong problem?
+-    - Did they implement the right feature but wrong way?
+-
+-    **Verify by reading code, not by trusting report.**
+-
+-    Report:
+-    - ✅ Spec compliant (if everything matches after code inspection)
+-    - ❌ Issues found: [list specifically what's missing or extra, with file:line references]
+-```
+diff --git a/skills/superpowers/systematic-debugging/SKILL.md b/skills/superpowers/systematic-debugging/SKILL.md
+index 111d2a9..b0eca38 100644
+--- a/skills/superpowers/systematic-debugging/SKILL.md
++++ b/skills/superpowers/systematic-debugging/SKILL.md
+@@ -237,7 +237,7 @@ If you catch yourself thinking:
+ - "Is that not happening?" - You assumed without verifying
+ - "Will it show us...?" - You should have added evidence gathering
+ - "Stop guessing" - You're proposing fixes without understanding
+-- "Ultrathink this" - Question fundamentals, not just symptoms
++- "Ultra-think this" - Question fundamentals, not just symptoms
+ - "We're stuck?" (frustrated) - Your approach isn't working
+ 
+ **When you see these:** STOP. Return to Phase 1.
+diff --git a/skills/superpowers/test-driven-development/SKILL.md b/skills/superpowers/test-driven-development/SKILL.md
+index 7a751fa..60d2609 100644
+--- a/skills/superpowers/test-driven-development/SKILL.md
++++ b/skills/superpowers/test-driven-development/SKILL.md
+@@ -356,7 +356,7 @@ Never fix bugs without a test.
+ 
+ ## Testing Anti-Patterns
+ 
+-When adding mocks or test utilities, read @testing-anti-patterns.md to avoid common pitfalls:
++When adding mocks or test utilities, read [testing-anti-patterns.md](testing-anti-patterns.md) to avoid common pitfalls:
+ - Testing mock behavior instead of real behavior
+ - Adding test-only methods to production classes
+ - Mocking without understanding dependencies
+diff --git a/skills/superpowers/using-git-worktrees/SKILL.md b/skills/superpowers/using-git-worktrees/SKILL.md
+index 134d371..212c569 100644
+--- a/skills/superpowers/using-git-worktrees/SKILL.md
++++ b/skills/superpowers/using-git-worktrees/SKILL.md
+@@ -30,7 +30,7 @@ BRANCH=$(git branch --show-current)
+ git rev-parse --show-superproject-working-tree 2>/dev/null
+ ```
+ 
+-**If `GIT_DIR != GIT_COMMON` (and not a submodule):** You are already in a linked worktree. Skip to Step 3 (Project Setup). Do NOT create another worktree.
++**If `GIT_DIR != GIT_COMMON` (and not a submodule):** You are already in a linked worktree. Skip to Step 2 (Project Setup). Do NOT create another worktree.
+ 
+ Report with branch state:
+ - On a branch: "Already in isolated workspace at `<path>` on branch `<name>`."
+@@ -42,7 +42,7 @@ Has the user already indicated their worktree preference in your instructions? I
+ 
+ > "Would you like me to set up an isolated worktree? It protects your current branch from changes."
+ 
+-Honor any existing declared preference without asking. If the user declines consent, work in place and skip to Step 3.
++Honor any existing declared preference without asking. If the user declines consent, work in place and skip to Step 2.
+ 
+ ## Step 1: Create Isolated Workspace
+ 
+@@ -50,7 +50,7 @@ Honor any existing declared preference without asking. If the user declines cons
+ 
+ ### 1a. Native Worktree Tools (preferred)
+ 
+-The user has asked for an isolated workspace (Step 0 consent). Do you already have a way to create a worktree? It might be a tool with a name like `EnterWorktree`, `WorktreeCreate`, a `/worktree` command, or a `--worktree` flag. If you do, use it and skip to Step 3.
++The user has asked for an isolated workspace (Step 0 consent). Do you already have a way to create a worktree? It might be a tool with a name like `EnterWorktree`, `WorktreeCreate`, a `/worktree` command, or a `--worktree` flag. If you do, use it and skip to Step 2.
+ 
+ Native tools handle directory placement, branch creation, and cleanup automatically. Using `git worktree add` when you have a native tool creates phantom state your harness can't see or manage.
+ 
+@@ -73,14 +73,7 @@ Follow this priority order. Explicit user preference always beats observed files
+    ```
+    If found, use it. If both exist, `.worktrees` wins.
+ 
+-3. **Check for an existing global directory:**
+-   ```bash
+-   project=$(basename "$(git rev-parse --show-toplevel)")
+-   ls -d ~/.config/superpowers/worktrees/$project 2>/dev/null
+-   ```
+-   If found, use it (backward compatibility with legacy global path).
+-
+-4. **If there is no other guidance available**, default to `.worktrees/` at the project root.
++3. **If there is no other guidance available**, default to `.worktrees/` at the project root.
+ 
+ #### Safety Verification (project-local directories only)
+ 
+@@ -94,16 +87,11 @@ git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/d
+ 
+ **Why critical:** Prevents accidentally committing worktree contents to repository.
+ 
+-Global directories (`~/.config/superpowers/worktrees/`) need no verification.
+-
+ #### Create the Worktree
+ 
+ ```bash
+-project=$(basename "$(git rev-parse --show-toplevel)")
+-
+ # Determine path based on chosen location
+-# For project-local: path="$LOCATION/$BRANCH_NAME"
+-# For global: path="~/.config/superpowers/worktrees/$project/$BRANCH_NAME"
++path="$LOCATION/$BRANCH_NAME"
+ 
+ git worktree add "$path" -b "$BRANCH_NAME"
+ cd "$path"
+@@ -111,7 +99,7 @@ cd "$path"
+ 
+ **Sandbox fallback:** If `git worktree add` fails with a permission error (sandbox denial), tell the user the sandbox blocked worktree creation and you're working in the current directory instead. Then run setup and baseline tests in place.
+ 
+-## Step 3: Project Setup
++## Step 2: Project Setup
+ 
+ Auto-detect and run appropriate setup:
+ 
+@@ -130,7 +118,7 @@ if [ -f pyproject.toml ]; then poetry install; fi
+ if [ -f go.mod ]; then go mod download; fi
+ ```
+ 
+-## Step 4: Verify Clean Baseline
++## Step 3: Verify Clean Baseline
+ 
+ Run tests to ensure workspace starts clean:
+ 
+@@ -163,7 +151,6 @@ Ready to implement <feature-name>
+ | `worktrees/` exists | Use it (verify ignored) |
+ | Both exist | Use `.worktrees/` |
+ | Neither exists | Check instruction file, then default `.worktrees/` |
+-| Global path exists | Use it (backward compat) |
+ | Directory not ignored | Add to .gitignore + commit |
+ | Permission error on create | Sandbox fallback, work in place |
+ | Tests fail during baseline | Report failures + ask |
+@@ -189,7 +176,7 @@ Ready to implement <feature-name>
+ ### Assuming directory location
+ 
+ - **Problem:** Creates inconsistency, violates project conventions
+-- **Fix:** Follow priority: existing > global legacy > instruction file > default
++- **Fix:** Follow priority: explicit instructions > existing project-local directory > default
+ 
+ ### Proceeding with failing tests
+ 
+@@ -209,7 +196,7 @@ Ready to implement <feature-name>
+ **Always:**
+ - Run Step 0 detection first
+ - Prefer native tools over git fallback
+-- Follow directory priority: existing > global legacy > instruction file > default
++- Follow directory priority: explicit instructions > existing project-local directory > default
+ - Verify directory is ignored for project-local
+ - Auto-detect and run project setup
+ - Verify clean test baseline
+diff --git a/skills/superpowers/using-superpowers/SKILL.md b/skills/superpowers/using-superpowers/SKILL.md
+index c8a8570..5371221 100644
+--- a/skills/superpowers/using-superpowers/SKILL.md
++++ b/skills/superpowers/using-superpowers/SKILL.md
+@@ -1,6 +1,6 @@
+ ---
+ name: using-superpowers
+-description: Use when starting any conversation - establishes how to find and use skills, requiring Skill tool invocation before ANY response including clarifying questions
++description: Use when starting any conversation - establishes how to find and use skills, requiring skill invocation before ANY response including clarifying questions
+ ---
+ 
+ <SUBAGENT-STOP>
+@@ -27,9 +27,13 @@ If CLAUDE.md, GEMINI.md, or AGENTS.md says "don't use TDD" and a skill says "alw
+ 
+ ## How to Access Skills
+ 
+-**In Claude Code:** Use the `Skill` tool. When you invoke a skill, its content is loaded and presented to you—follow it directly. Never use the Read tool on skill files.
++**Never read skill files manually with file tools** — always use your platform's skill-loading mechanism so the skill is properly activated.
+ 
+-**In Copilot CLI:** Use the `skill` tool. Skills are auto-discovered from installed plugins. The `skill` tool works the same as Claude Code's `Skill` tool.
++**In Claude Code:** Use the `Skill` tool. When you invoke a skill, its content is loaded and presented to you — follow it directly.
++
++**In Codex:** Skills load natively. Follow the instructions presented when a skill activates.
++
++**In Copilot CLI:** Use the `skill` tool. Skills are auto-discovered from installed plugins.
+ 
+ **In Gemini CLI:** Skills activate via the `activate_skill` tool. Gemini loads skill metadata at session start and activates the full content on demand.
+ 
+@@ -37,7 +41,7 @@ If CLAUDE.md, GEMINI.md, or AGENTS.md says "don't use TDD" and a skill says "alw
+ 
+ ## Platform Adaptation
+ 
+-Skills use Claude Code tool names. Non-CC platforms: see `references/copilot-tools.md` (Copilot CLI), `references/codex-tools.md` (Codex) for tool equivalents. Gemini CLI users get the tool mapping loaded automatically via GEMINI.md.
++Skills speak in actions ("dispatch a subagent", "create a todo", "read a file") rather than naming any one runtime's tools. For per-platform tool equivalents and instructions-file conventions, see [claude-code-tools.md](references/claude-code-tools.md), [codex-tools.md](references/codex-tools.md), [copilot-tools.md](references/copilot-tools.md), [gemini-tools.md](references/gemini-tools.md), [pi-tools.md](references/pi-tools.md), and [antigravity-tools.md](references/antigravity-tools.md). Gemini CLI users get the tool mapping loaded automatically via GEMINI.md.
+ 
+ # Using Skills
+ 
+@@ -48,30 +52,30 @@ Skills use Claude Code tool names. Non-CC platforms: see `references/copilot-too
+ ```dot
+ digraph skill_flow {
+     "User message received" [shape=doublecircle];
+-    "About to EnterPlanMode?" [shape=doublecircle];
++    "About to enter plan mode?" [shape=doublecircle];
+     "Already brainstormed?" [shape=diamond];
+     "Invoke brainstorming skill" [shape=box];
+     "Might any skill apply?" [shape=diamond];
+-    "Invoke Skill tool" [shape=box];
++    "Invoke the skill" [shape=box];
+     "Announce: 'Using [skill] to [purpose]'" [shape=box];
+     "Has checklist?" [shape=diamond];
+-    "Create TodoWrite todo per item" [shape=box];
++    "Create a todo per item" [shape=box];
+     "Follow skill exactly" [shape=box];
+     "Respond (including clarifications)" [shape=doublecircle];
+ 
+-    "About to EnterPlanMode?" -> "Already brainstormed?";
++    "About to enter plan mode?" -> "Already brainstormed?";
+     "Already brainstormed?" -> "Invoke brainstorming skill" [label="no"];
+     "Already brainstormed?" -> "Might any skill apply?" [label="yes"];
+     "Invoke brainstorming skill" -> "Might any skill apply?";
+ 
+     "User message received" -> "Might any skill apply?";
+-    "Might any skill apply?" -> "Invoke Skill tool" [label="yes, even 1%"];
++    "Might any skill apply?" -> "Invoke the skill" [label="yes, even 1%"];
+     "Might any skill apply?" -> "Respond (including clarifications)" [label="definitely not"];
+-    "Invoke Skill tool" -> "Announce: 'Using [skill] to [purpose]'";
++    "Invoke the skill" -> "Announce: 'Using [skill] to [purpose]'";
+     "Announce: 'Using [skill] to [purpose]'" -> "Has checklist?";
+-    "Has checklist?" -> "Create TodoWrite todo per item" [label="yes"];
++    "Has checklist?" -> "Create a todo per item" [label="yes"];
+     "Has checklist?" -> "Follow skill exactly" [label="no"];
+-    "Create TodoWrite todo per item" -> "Follow skill exactly";
++    "Create a todo per item" -> "Follow skill exactly";
+ }
+ ```
+ 
+@@ -98,15 +102,15 @@ These thoughts mean STOP—you're rationalizing:
+ 
+ When multiple skills could apply, use this order:
+ 
+-1. **Process skills first** (brainstorming, debugging) - these determine HOW to approach the task
++1. **Process skills first** (brainstorming, systematic-debugging) - these determine HOW to approach the task
+ 2. **Implementation skills second** (frontend-design, mcp-builder) - these guide execution
+ 
+ "Let's build X" → brainstorming first, then implementation skills.
+-"Fix this bug" → debugging first, then domain-specific skills.
++"Fix this bug" → systematic-debugging first, then domain-specific skills.
+ 
+ ## Skill Types
+ 
+-**Rigid** (TDD, debugging): Follow exactly. Don't adapt away discipline.
++**Rigid** (TDD, systematic-debugging): Follow exactly. Don't adapt away discipline.
+ 
+ **Flexible** (patterns): Adapt principles to context.
+ 
+diff --git a/skills/superpowers/using-superpowers/references/codex-tools.md b/skills/superpowers/using-superpowers/references/codex-tools.md
+index f50d40d..1ab253f 100644
+--- a/skills/superpowers/using-superpowers/references/codex-tools.md
++++ b/skills/superpowers/using-superpowers/references/codex-tools.md
+@@ -1,17 +1,30 @@
+ # Codex Tool Mapping
+ 
+-Skills use Claude Code tool names. When you encounter these in a skill, use your platform equivalent:
+-
+-| Skill references | Codex equivalent |
+-|-----------------|------------------|
+-| `Task` tool (dispatch subagent) | `spawn_agent` (see [Subagent dispatch requires multi-agent support](#subagent-dispatch-requires-multi-agent-support)) |
+-| Multiple `Task` calls (parallel) | Multiple `spawn_agent` calls |
+-| Task returns result | `wait_agent` |
+-| Task completes automatically | `close_agent` to free slot |
+-| `TodoWrite` (task tracking) | `update_plan` |
+-| `Skill` tool (invoke a skill) | Skills load natively — just follow the instructions |
+-| `Read`, `Write`, `Edit` (files) | Use your native file tools |
+-| `Bash` (run commands) | Use your native shell tools |
++Skills speak in actions ("dispatch a subagent", "create a todo", "read a file"). On Codex these resolve to the tools below.
++
++| Action skills request | Codex equivalent |
++|----------------------|------------------|
++| Read a file | `shell` (e.g., `cat`, `head`, `tail`) — Codex reads files via shell |
++| Create / edit / delete a file | `apply_patch` (structured diff for create, update, delete) |
++| Run a shell command | `shell` |
++| Search file contents | `shell` (e.g., `grep`, `rg`) |
++| Find files by name | `shell` (e.g., `find`, `ls`) |
++| Fetch a URL | `shell` with `curl` / `wget` — Codex has no native fetch tool |
++| Search the web | `web_search` (enabled by default; configurable in `config.toml` via the top-level `web_search` setting — `live`, `cached`, or `disabled`) |
++| Invoke a skill | Skills load natively — just follow the instructions |
++| Dispatch a subagent (`Subagent (general-purpose):` template) | `spawn_agent` (see [Subagent dispatch requires multi-agent support](#subagent-dispatch-requires-multi-agent-support)) |
++| Multiple parallel dispatches | Multiple `spawn_agent` calls in one response |
++| Wait for subagent result | `wait_agent` |
++| Free up subagent slot when done | `close_agent` |
++| Task tracking ("create a todo", "mark complete") | `update_plan` |
++
++## Instructions file
++
++When a skill mentions "your instructions file", on Codex this is **`AGENTS.md`** at the project root. Codex also reads `~/.codex/AGENTS.md` for global context, and an `AGENTS.override.md` (in the project tree or `~/.codex/`) takes precedence when present. Codex walks from the project root down to the current working directory, concatenating `AGENTS.md` files it finds along the way, up to `project_doc_max_bytes` (32 KiB by default).
++
++## Personal skills directory
++
++User-level skills live at **`$CODEX_HOME/skills/`** (default `~/.codex/skills/`). Codex also reads the cross-runtime path **`~/.agents/skills/`** (shared with Copilot CLI and Gemini CLI). When both directories exist at the same scope, Codex loads them both as separate skill catalogs — Codex's docs don't currently document a precedence between them. Each skill is a subdirectory containing a `SKILL.md` (with `name` and `description` frontmatter).
+ 
+ ## Subagent dispatch requires multi-agent support
+ 
+diff --git a/skills/superpowers/using-superpowers/references/copilot-tools.md b/skills/superpowers/using-superpowers/references/copilot-tools.md
+index ae3cf5a..2cf54a0 100644
+--- a/skills/superpowers/using-superpowers/references/copilot-tools.md
++++ b/skills/superpowers/using-superpowers/references/copilot-tools.md
+@@ -1,31 +1,38 @@
+ # Copilot CLI Tool Mapping
+ 
+-Skills use Claude Code tool names. When you encounter these in a skill, use your platform equivalent:
+-
+-| Skill references | Copilot CLI equivalent |
+-|-----------------|----------------------|
+-| `Read` (file reading) | `view` |
+-| `Write` (file creation) | `create` |
+-| `Edit` (file editing) | `edit` |
+-| `Bash` (run commands) | `bash` |
+-| `Grep` (search file content) | `grep` |
+-| `Glob` (search files by name) | `glob` |
+-| `Skill` tool (invoke a skill) | `skill` |
+-| `WebFetch` | `web_fetch` |
+-| `Task` tool (dispatch subagent) | `task` with `agent_type: "general-purpose"` or `"explore"` |
+-| Multiple `Task` calls (parallel) | Multiple `task` calls |
+-| Task status/output | `read_agent`, `list_agents` |
+-| `TodoWrite` (task tracking) | `sql` with built-in `todos` table |
+-| `WebSearch` | No equivalent — use `web_fetch` with a search engine URL |
+-| `EnterPlanMode` / `ExitPlanMode` | No equivalent — stay in the main session |
++Skills speak in actions ("dispatch a subagent", "create a todo", "read a file"). On Copilot CLI these resolve to the tools below.
++
++| Action skills request | Copilot CLI equivalent |
++|----------------------|----------------------|
++| Read a file | `view` |
++| Create / edit / delete a file | `apply_patch` (Copilot CLI has no separate create/edit/write tools) |
++| Run a shell command | `bash` |
++| Search file contents | `rg` (ripgrep; Copilot CLI does not expose a `grep` tool) |
++| Find files by name | `glob` |
++| Fetch a URL | `web_fetch` |
++| Search the web | `web_search` |
++| Invoke a skill | `skill` |
++| Dispatch a subagent (`Subagent (general-purpose):` template) | `task` with `agent_type: "general-purpose"` (other accepted types: `explore`, `task`, `code-review`, `research`, `configure-copilot`) |
++| Multiple parallel dispatches | Multiple `task` calls in one response |
++| Subagent status/output/control | `read_agent`, `list_agents`, `write_agent` |
++| Task tracking ("create a todo", "mark complete") | `update_todo` |
++| Enter / exit plan mode | No equivalent — stay in the main session |
++
++## Instructions file
++
++When a skill mentions "your instructions file", on Copilot CLI this is **`AGENTS.md`** at the repository root. If both `AGENTS.md` and `.github/copilot-instructions.md` are present, Copilot reads both.
++
++## Personal skills directory
++
++User-level skills live at **`~/.copilot/skills/`**. Copilot CLI also recognizes the cross-runtime alias **`~/.agents/skills/`**, which is shared with Codex and Gemini CLI. Each skill is a subdirectory containing a `SKILL.md` (with `name` and `description` frontmatter).
+ 
+ ## Async shell sessions
+ 
+-Copilot CLI supports persistent async shell sessions, which have no direct Claude Code equivalent:
++Copilot CLI supports persistent async shell sessions:
+ 
+ | Tool | Purpose |
+ |------|---------|
+-| `bash` with `async: true` | Start a long-running command in the background |
++| `bash` with `mode: "async"` (and optionally `detach: true`) | Start a long-running command in the background; returns a `shellId` |
+ | `write_bash` | Send input to a running async session |
+ | `read_bash` | Read output from an async session |
+ | `stop_bash` | Terminate an async session |
+diff --git a/skills/superpowers/using-superpowers/references/gemini-tools.md b/skills/superpowers/using-superpowers/references/gemini-tools.md
+index 91ef404..b01b652 100644
+--- a/skills/superpowers/using-superpowers/references/gemini-tools.md
++++ b/skills/superpowers/using-superpowers/references/gemini-tools.md
+@@ -1,51 +1,63 @@
+ # Gemini CLI Tool Mapping
+ 
+-Skills use Claude Code tool names. When you encounter these in a skill, use your platform equivalent:
+-
+-| Skill references | Gemini CLI equivalent |
+-|-----------------|----------------------|
+-| `Read` (file reading) | `read_file` |
+-| `Write` (file creation) | `write_file` |
+-| `Edit` (file editing) | `replace` |
+-| `Bash` (run commands) | `run_shell_command` |
+-| `Grep` (search file content) | `grep_search` |
+-| `Glob` (search files by name) | `glob` |
+-| `TodoWrite` (task tracking) | `write_todos` |
+-| `Skill` tool (invoke a skill) | `activate_skill` |
+-| `WebSearch` | `google_web_search` |
+-| `WebFetch` | `web_fetch` |
+-| `Task` tool (dispatch subagent) | `@agent-name` (see [Subagent support](#subagent-support)) |
++Skills speak in actions ("dispatch a subagent", "create a todo", "read a file"). On Gemini CLI these resolve to the tools below.
++
++| Action skills request | Gemini CLI equivalent |
++|----------------------|----------------------|
++| Read a file | `read_file` |
++| Read multiple files at once | `read_many_files` |
++| Create a new file | `write_file` |
++| Edit a file | `replace` |
++| Run a shell command | `run_shell_command` |
++| Search file contents | `grep_search` |
++| Find files by name | `glob` |
++| List files and subdirectories | `list_directory` |
++| Fetch a URL | `web_fetch` |
++| Search the web | `google_web_search` |
++| Invoke a skill | `activate_skill` |
++| Dispatch a subagent (`Subagent (general-purpose):` template) | `invoke_agent` with `agent_name: "generalist"` (invocable via `@generalist` chat syntax — see [Subagent support](#subagent-support)) |
++| Multiple parallel dispatches | Multiple `invoke_agent` calls in the same response |
++| Task tracking ("create a todo", "mark complete") | `write_todos` (statuses: pending, in_progress, completed, cancelled, blocked) |
++
++## Instructions file
++
++When a skill mentions "your instructions file", on Gemini CLI this is **`GEMINI.md`**. Gemini CLI loads `GEMINI.md` hierarchically: global at `~/.gemini/GEMINI.md`, project-level files in workspace directories and their ancestors, and sub-directory `GEMINI.md` files when a tool accesses files in those directories.
++
++## Personal skills directory
++
++User-level skills live at **`~/.gemini/skills/`**, with **`~/.agents/skills/`** as a cross-runtime alias (shared with Codex and Copilot CLI). When both directories exist at the same scope, `.agents/skills/` takes precedence. Each skill is a subdirectory containing a `SKILL.md` (with `name` and `description` frontmatter).
+ 
+ ## Subagent support
+ 
+-Gemini CLI supports subagents natively via the `@` syntax. Use the built-in `@generalist` agent to dispatch any task — it has access to all tools and follows the prompt you provide.
++Gemini CLI dispatches subagents through the `invoke_agent` tool, which takes `agent_name` and `prompt` parameters. The same dispatch is also surfaced as a chat-syntax shortcut: typing `@generalist <prompt>` is equivalent to calling `invoke_agent` with `agent_name: "generalist"`. Built-in agent names include `generalist`, `cli_help`, `codebase_investigator`, and (with browser tooling enabled) `browser_agent`.
+ 
+-When a skill says to dispatch a named agent type, use `@generalist` with the full prompt from the skill's prompt template:
++Skills dispatch with `Subagent (general-purpose):` and either reference a prompt-template file (e.g., `superpowers:subagent-driven-development`'s `./implementer-prompt.md`) or supply an inline prompt. On Gemini CLI:
+ 
+-| Skill instruction | Gemini CLI equivalent |
+-|-------------------|----------------------|
+-| `Task tool (superpowers:implementer)` | `@generalist` with the filled `implementer-prompt.md` template |
+-| `Task tool (superpowers:spec-reviewer)` | `@generalist` with the filled `spec-reviewer-prompt.md` template |
+-| `Task tool (superpowers:code-reviewer)` | `@code-reviewer` (bundled agent) or `@generalist` with the filled review prompt |
+-| `Task tool (superpowers:code-quality-reviewer)` | `@generalist` with the filled `code-quality-reviewer-prompt.md` template |
+-| `Task tool (general-purpose)` with inline prompt | `@generalist` with your inline prompt |
++| Skill dispatch form | Gemini CLI equivalent |
++|---------------------|----------------------|
++| References a `*-prompt.md` template (implementer, task-reviewer, code-reviewer, etc.) | Fill the template, then `invoke_agent` with `agent_name: "generalist"` and the filled prompt |
++| References `superpowers:requesting-code-review`'s `./code-reviewer.md` | `invoke_agent` with `agent_name: "generalist"` and the filled review template |
++| Inline prompt (no template referenced) | `invoke_agent` with `agent_name: "generalist"` and your inline prompt |
+ 
+ ### Prompt filling
+ 
+-Skills provide prompt templates with placeholders like `{WHAT_WAS_IMPLEMENTED}` or `[FULL TEXT of task]`. Fill all placeholders and pass the complete prompt as the message to `@generalist`. The prompt template itself contains the agent's role, review criteria, and expected output format — `@generalist` will follow it.
++Skills provide prompt templates with placeholders like `{WHAT_WAS_IMPLEMENTED}` or `[FULL TEXT of task]`. Fill all placeholders before passing the complete prompt to `invoke_agent`. The prompt template itself contains the agent's role, review criteria, and expected output format — the subagent will follow it.
+ 
+ ### Parallel dispatch
+ 
+-Gemini CLI supports parallel subagent dispatch. When a skill asks you to dispatch multiple independent subagent tasks in parallel, request all of those `@generalist` or named subagent tasks together in the same prompt. Keep dependent tasks sequential, but do not serialize independent subagent tasks just to preserve a simpler history.
++Gemini CLI supports parallel subagent dispatch. Issue multiple `invoke_agent` calls in the same response (or multiple `@generalist` invocations in one prompt) to run independent subagent work in parallel. Keep dependent tasks sequential, but do not serialize independent subagent tasks just to preserve a simpler history.
+ 
+ ## Additional Gemini CLI tools
+ 
+-These tools are available in Gemini CLI but have no Claude Code equivalent:
++These tools are unique to Gemini CLI:
+ 
+ | Tool | Purpose |
+ |------|---------|
+-| `list_directory` | List files and subdirectories |
+-| `save_memory` | Persist facts to GEMINI.md across sessions |
+-| `ask_user` | Request structured input from the user |
+-| `tracker_create_task` | Rich task management (create, update, list, visualize) |
+-| `enter_plan_mode` / `exit_plan_mode` | Switch to read-only research mode before making changes |
++| `save_memory` (legacy) | Persist facts across sessions when `experimental.memoryV2 = false` |
++| `get_internal_docs` | Look up Gemini CLI's bundled documentation |
++| `ask_user` | Pose structured questions to the user (text / single-select / multi-select) |
++| `enter_plan_mode` / `exit_plan_mode` | Switch into and out of read-only plan mode |
++| `update_topic` | Update the current conversation's topic / strategic-intent metadata |
++| `complete_task` | Signal that a Gemini subagent has completed and return its result to the parent agent |
++| `tracker_create_task`, `tracker_update_task`, `tracker_get_task`, `tracker_list_tasks`, `tracker_add_dependency`, `tracker_visualize` | Rich task tracker with dependency and visualization support |
++| `read_mcp_resource`, `list_mcp_resources` | MCP resource access |
+diff --git a/skills/superpowers/writing-plans/SKILL.md b/skills/superpowers/writing-plans/SKILL.md
+index 847412e..b1613eb 100644
+--- a/skills/superpowers/writing-plans/SKILL.md
++++ b/skills/superpowers/writing-plans/SKILL.md
+@@ -33,6 +33,15 @@ Before defining tasks, map out which files will be created or modified and what
+ 
+ This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.
+ 
++## Task Right-Sizing
++
++A task is the smallest unit that carries its own test cycle and is worth a
++fresh reviewer's gate. When drawing task boundaries: fold setup,
++configuration, scaffolding, and documentation steps into the task whose
++deliverable needs them; split only where a reviewer could meaningfully
++reject one task while approving its neighbor. Each task ends with an
++independently testable deliverable.
++
+ ## Bite-Sized Task Granularity
+ 
+ **Each step is one action (2-5 minutes):**
+@@ -57,6 +66,13 @@ This structure informs the task decomposition. Each task should produce self-con
+ 
+ **Tech Stack:** [Key technologies/libraries]
+ 
++## Global Constraints
++
++[The spec's project-wide requirements — version floors, dependency limits,
++naming and copy rules, platform requirements — one line each, with exact
++values copied verbatim from the spec. Every task's requirements implicitly
++include this section.]
++
+ ---
+ ```
+ 
+@@ -70,6 +86,12 @@ This structure informs the task decomposition. Each task should produce self-con
+ - Modify: `exact/path/to/existing.py:123-145`
+ - Test: `tests/exact/path/to/test.py`
+ 
++**Interfaces:**
++- Consumes: [what this task uses from earlier tasks — exact signatures]
++- Produces: [what later tasks rely on — exact function names, parameter
++  and return types. A task's implementer sees only their own task; this
++  block is how they learn the names and types neighboring tasks use.]
++
+ - [ ] **Step 1: Write the failing test**
+ 
+ ```python
+diff --git a/skills/superpowers/writing-plans/plan-document-reviewer-prompt.md b/skills/superpowers/writing-plans/plan-document-reviewer-prompt.md
+index 2db2806..1c12c1d 100644
+--- a/skills/superpowers/writing-plans/plan-document-reviewer-prompt.md
++++ b/skills/superpowers/writing-plans/plan-document-reviewer-prompt.md
+@@ -7,7 +7,7 @@ Use this template when dispatching a plan document reviewer subagent.
+ **Dispatch after:** The complete plan is written.
+ 
+ ```
+-Task tool (general-purpose):
++Subagent (general-purpose):
+   description: "Review plan document"
+   prompt: |
+     You are a plan document reviewer. Verify this plan is complete and ready for implementation.
+diff --git a/skills/superpowers/writing-skills/SKILL.md b/skills/superpowers/writing-skills/SKILL.md
+index c3b73d8..8928d44 100644
+--- a/skills/superpowers/writing-skills/SKILL.md
++++ b/skills/superpowers/writing-skills/SKILL.md
+@@ -9,7 +9,7 @@ description: Use when creating new skills, editing existing skills, or verifying
+ 
+ **Writing skills IS Test-Driven Development applied to process documentation.**
+ 
+-**Personal skills live in agent-specific directories (`~/.claude/skills` for Claude Code, `~/.agents/skills/` for Codex)** 
++**Personal skills live in your runtime's skills directory** — see [claude-code-tools.md](../using-superpowers/references/claude-code-tools.md), [codex-tools.md](../using-superpowers/references/codex-tools.md), [copilot-tools.md](../using-superpowers/references/copilot-tools.md), or [gemini-tools.md](../using-superpowers/references/gemini-tools.md) for the path on your runtime. Codex, Copilot CLI, and Gemini CLI all also recognize `~/.agents/skills/` as a cross-runtime alias.
+ 
+ You write test cases (pressure scenarios with subagents), watch them fail (baseline behavior), write the skill (documentation), watch tests pass (agents comply), and refactor (close loopholes).
+ 
+@@ -21,7 +21,7 @@ You write test cases (pressure scenarios with subagents), watch them fail (basel
+ 
+ ## What is a Skill?
+ 
+-A **skill** is a reference guide for proven techniques, patterns, or tools. Skills help future Claude instances find and apply effective approaches.
++A **skill** is a reference guide for proven techniques, patterns, or tools. Skills help future agents find and apply effective approaches.
+ 
+ **Skills are:** Reusable techniques, patterns, tools, reference guides
+ 
+@@ -55,7 +55,7 @@ The entire skill creation process follows RED-GREEN-REFACTOR.
+ **Don't create for:**
+ - One-off solutions
+ - Standard practices well-documented elsewhere
+-- Project-specific conventions (put in CLAUDE.md)
++- Project-specific conventions (put in your instructions file)
+ - Mechanical constraints (if it's enforceable with regex/validation, automate it—save documentation for judgment calls)
+ 
+ ## Skill Types
+@@ -99,7 +99,7 @@ skills/
+ - `description`: Third-person, describes ONLY when to use (NOT what it does)
+   - Start with "Use when..." to focus on triggering conditions
+   - Include specific symptoms, situations, and contexts
+-  - **NEVER summarize the skill's process or workflow** (see CSO section for why)
++  - **NEVER summarize the skill's process or workflow** (see SDO section for why)
+   - Keep under 500 characters if possible
+ 
+ ```markdown
+@@ -137,13 +137,13 @@ Concrete results
+ ```
+ 
+ 
+-## Claude Search Optimization (CSO)
++## Skill Discovery Optimization (SDO)
+ 
+-**Critical for discovery:** Future Claude needs to FIND your skill
++**Critical for discovery:** Future agents need to FIND your skill
+ 
+ ### 1. Rich Description Field
+ 
+-**Purpose:** Claude reads description to decide which skills to load for a given task. Make it answer: "Should I read this skill right now?"
++**Purpose:** Your agent reads the description to decide which skills to load for a given task. Make it answer: "Should I read this skill right now?"
+ 
+ **Format:** Start with "Use when..." to focus on triggering conditions
+ 
+@@ -151,14 +151,14 @@ Concrete results
+ 
+ The description should ONLY describe triggering conditions. Do NOT summarize the skill's process or workflow in the description.
+ 
+-**Why this matters:** Testing revealed that when a description summarizes the skill's workflow, Claude may follow the description instead of reading the full skill content. A description saying "code review between tasks" caused Claude to do ONE review, even though the skill's flowchart clearly showed TWO reviews (spec compliance then code quality).
++**Why this matters:** Testing revealed that when a description summarizes the skill's workflow, an agent may follow the description instead of reading the full skill content. A description saying "code review between tasks" caused an agent to do ONE review, even though the skill's flowchart clearly showed TWO reviews (spec compliance then code quality).
+ 
+-When the description was changed to just "Use when executing implementation plans with independent tasks" (no workflow summary), Claude correctly read the flowchart and followed the two-stage review process.
++When the description was changed to just "Use when executing implementation plans with independent tasks" (no workflow summary), the agent correctly read the flowchart and followed the two-stage review process.
+ 
+-**The trap:** Descriptions that summarize workflow create a shortcut Claude will take. The skill body becomes documentation Claude skips.
++**The trap:** Descriptions that summarize workflow create a shortcut agents will take. The skill body becomes documentation agents skip.
+ 
+ ```yaml
+-# ❌ BAD: Summarizes workflow - Claude may follow this instead of reading skill
++# ❌ BAD: Summarizes workflow - agents may follow this instead of reading skill
+ description: Use when executing plans - dispatches subagent per task with code review between tasks
+ 
+ # ❌ BAD: Too much process detail
+@@ -198,7 +198,7 @@ description: Use when using React Router and handling authentication redirects
+ 
+ ### 2. Keyword Coverage
+ 
+-Use words Claude would search for:
++Use words an agent would search for:
+ - Error messages: "Hook timed out", "ENOTEMPTY", "race condition"
+ - Symptoms: "flaky", "hanging", "zombie", "pollution"
+ - Synonyms: "timeout/hang/freeze", "cleanup/teardown/afterEach"
+@@ -275,7 +275,7 @@ wc -w skills/path/SKILL.md
+ - `creating-skills`, `testing-skills`, `debugging-with-logs`
+ - Active, describes the action you're taking
+ 
+-### 4. Cross-Referencing Other Skills
++### 5. Cross-Referencing Other Skills
+ 
+ **When writing documentation that references other skills:**
+ 
+@@ -313,7 +313,7 @@ digraph when_flowchart {
+ - Linear instructions → Numbered lists
+ - Labels without semantic meaning (step1, helper2)
+ 
+-See @graphviz-conventions.dot for graphviz style rules.
++See `graphviz-conventions.dot` in this directory for graphviz style rules.
+ 
+ **Visualizing for your human partner:** Use `render-graphs.js` in this directory to render a skill's flowcharts to SVG:
+ ```bash
+@@ -456,10 +456,29 @@ Different skill types need different test approaches:
+ 
+ **All of these mean: Test before deploying. No exceptions.**
+ 
++## Match the Form to the Failure
++
++Before writing guidance, classify the baseline failure. The form that bulletproofs one failure type measurably backfires on another.
++
++| Baseline failure | Right form | Wrong form |
++|---|---|---|
++| Skips/violates a rule under pressure (knows better, does it anyway) | Prohibition + rationalization table + red flags (see Bulletproofing below) | Soft guidance ("prefer...", "consider...") |
++| Complies, but output has the wrong shape (bloated prompt, buried verdict, restated spec) | Positive recipe or contract: state what the output IS — its parts, in order | Prohibition list ("don't restate", "never narrate") |
++| Omits a required element from something they already produce | Structural: REQUIRED field or slot in the template they fill in | Prose reminders near the template |
++| Behavior should depend on a condition | Conditional keyed to an observable predicate ("if the brief exists, reference it") | Unconditional rule + exemption clauses |
++
++**Why prohibitions backfire on shaping problems:** under a competing incentive ("make the prompt self-contained"), agents negotiate with "don't X". In head-to-head wording tests on dispatch-prompt guidance, the prohibition arm produced clearly more of the unwanted content than the recipe arm (fully separated distributions), and trended worse than even the no-guidance control — micro-test your own case rather than assuming, but never reach for the prohibition by default. A recipe leaves nothing to negotiate: the output matches the stated shape or it doesn't.
++
++**Rules for whichever form you pick:**
++- **No nuance clauses.** "Don't X unless it matters" reopens the negotiation — appending a single nuance clause to a winning recipe degraded it from consistent to noisy in the same wording tests. Express a real exception as its own conditional on an observable predicate.
++- **Exemption clauses don't scope.** "This limit doesn't apply to code blocks" still suppresses code blocks. If part of the output must be exempt, restructure so the rule can't reach it.
++
+ ## Bulletproofing Skills Against Rationalization
+ 
+ Skills that enforce discipline (like TDD) need to resist rationalization. Agents are smart and will find loopholes when under pressure.
+ 
++**Scope:** this toolkit is for discipline failures — an agent that knows the rule and skips it under pressure. For wrong-shaped output or omitted elements, prohibition-based bulletproofing backfires; use the forms in Match the Form to the Failure instead.
++
+ **Psychology note:** Understanding WHY persuasion techniques work helps you apply them systematically. See persuasion-principles.md for research foundation (Cialdini, 2021; Meincke et al., 2025) on authority, commitment, scarcity, social proof, and unity principles.
+ 
+ ### Close Every Loophole Explicitly
+@@ -522,7 +541,7 @@ Make it easy for agents to self-check when rationalizing:
+ **All of these mean: Delete code. Start over with TDD.**
+ ```
+ 
+-### Update CSO for Violation Symptoms
++### Update SDO for Violation Symptoms
+ 
+ Add to description: symptoms of when you're ABOUT to violate the rule:
+ 
+@@ -553,7 +572,19 @@ Run same scenarios WITH skill. Agent should now comply.
+ 
+ Agent found new rationalization? Add explicit counter. Re-test until bulletproof.
+ 
+-**Testing methodology:** See @testing-skills-with-subagents.md for the complete testing methodology:
++### Micro-Test Wording Before Full Scenarios
++
++Full pressure-scenario runs are the final gate, but they are slow and expensive per iteration. Verify the wording itself first with micro-tests:
++
++1. **One fresh-context sample per call** — a raw API call, or a single-shot subagent if you don't have API access. System prompt = the realistic context the guidance will live in (the full skill or prompt template, not the guidance in isolation); user message = a task that tempts the failure.
++2. **Always include a no-guidance control.** If the control doesn't exhibit the failure, there is nothing to fix — stop, don't author the guidance.
++3. **5+ reps per variant.** Single samples lie.
++4. **Manually read every flagged match.** Score programmatically if you like, but template echoes and quoted counter-examples masquerade as hits; automated counts alone overstate both failure and success.
++5. **Variance is a metric.** When guidance lands, reps converge on the same shape. Five different interpretations across five reps means the wording isn't binding — tighten the form before adding words.
++
++Micro-tests verify wording; they do not replace pressure scenarios for discipline skills.
++
++**Testing methodology:** See [testing-skills-with-subagents.md](testing-skills-with-subagents.md) for the complete testing methodology:
+ - How to write pressure scenarios
+ - Pressure types (time, sunk cost, authority, exhaustion)
+ - Plugging holes systematically
+@@ -595,7 +626,7 @@ Deploying untested skills = deploying untested code. It's a violation of quality
+ 
+ ## Skill Creation Checklist (TDD Adapted)
+ 
+-**IMPORTANT: Use TodoWrite to create todos for EACH checklist item below.**
++**IMPORTANT: Create a todo for EACH checklist item below.**
+ 
+ **RED Phase - Write Failing Test:**
+ - [ ] Create pressure scenarios (3+ combined pressures for discipline skills)
+@@ -610,6 +641,8 @@ Deploying untested skills = deploying untested code. It's a violation of quality
+ - [ ] Keywords throughout for search (errors, symptoms, tools)
+ - [ ] Clear overview with core principle
+ - [ ] Address specific baseline failures identified in RED
++- [ ] Guidance form matches the failure type (see Match the Form to the Failure)
++- [ ] For behavior-shaping guidance: wording micro-tested against a no-guidance control (5+ reps, every flagged match read manually) — N/A for pure reference skills
+ - [ ] Code inline OR link to separate file
+ - [ ] One excellent example (not multi-language)
+ - [ ] Run scenarios WITH skill - verify agents now comply
+@@ -634,9 +667,10 @@ Deploying untested skills = deploying untested code. It's a violation of quality
+ 
+ ## Discovery Workflow
+ 
+-How future Claude finds your skill:
++How future agents find your skill:
+ 
+ 1. **Encounters problem** ("tests are flaky")
++2. **Searches skills** (greps descriptions, browses categories)
+ 3. **Finds SKILL** (description matches)
+ 4. **Scans overview** (is this relevant?)
+ 5. **Reads patterns** (quick reference table)
+diff --git a/skills/superpowers/writing-skills/anthropic-best-practices.md b/skills/superpowers/writing-skills/anthropic-best-practices.md
+index 9f3f6ec..15ea9ea 100644
+--- a/skills/superpowers/writing-skills/anthropic-best-practices.md
++++ b/skills/superpowers/writing-skills/anthropic-best-practices.md
+@@ -1,30 +1,30 @@
+ # Skill authoring best practices
+ 
+-> Learn how to write effective Skills that Claude can discover and use successfully.
++> Learn how to write effective Skills that agents can discover and use successfully.
+ 
+-Good Skills are concise, well-structured, and tested with real usage. This guide provides practical authoring decisions to help you write Skills that Claude can discover and use effectively.
++Good Skills are concise, well-structured, and tested with real usage. This guide provides practical authoring decisions to help you write Skills that agents can discover and use effectively.
+ 
+-For conceptual background on how Skills work, see the [Skills overview](/en/docs/agents-and-tools/agent-skills/overview).
++For conceptual background on how Skills work, see the [Skills overview](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview).
+ 
+ ## Core principles
+ 
+ ### Concise is key
+ 
+-The [context window](https://platform.claude.com/docs/en/build-with-claude/context-windows) is a public good. Your Skill shares the context window with everything else Claude needs to know, including:
++The [context window](https://platform.claude.com/docs/en/build-with-claude/context-windows) is a public good. Your Skill shares the context window with everything else your agent needs to know, including:
+ 
+ * The system prompt
+ * Conversation history
+ * Other Skills' metadata
+ * Your actual request
+ 
+-Not every token in your Skill has an immediate cost. At startup, only the metadata (name and description) from all Skills is pre-loaded. Claude reads SKILL.md only when the Skill becomes relevant, and reads additional files only as needed. However, being concise in SKILL.md still matters: once Claude loads it, every token competes with conversation history and other context.
++Not every token in your Skill has an immediate cost. At startup, only the metadata (name and description) from all Skills is pre-loaded. Agents read SKILL.md only when the Skill becomes relevant, and read additional files only as needed. However, being concise in SKILL.md still matters: once an agent loads it, every token competes with conversation history and other context.
+ 
+-**Default assumption**: Claude is already very smart
++**Default assumption**: Agents are already very smart
+ 
+-Only add context Claude doesn't already have. Challenge each piece of information:
++Only add context agents don't already have. Challenge each piece of information:
+ 
+-* "Does Claude really need this explanation?"
+-* "Can I assume Claude knows this?"
++* "Does the agent really need this explanation?"
++* "Can I assume the agent knows this?"
+ * "Does this paragraph justify its token cost?"
+ 
+ **Good example: Concise** (approximately 50 tokens):
+@@ -54,7 +54,7 @@ recommend pdfplumber because it's easy to use and handles most cases well.
+ First, you'll need to install it using pip. Then you can use the code below...
+ ```
+ 
+-The concise version assumes Claude knows what PDFs are and how libraries work.
++The concise version assumes the agent knows what PDFs are and how libraries work.
+ 
+ ### Set appropriate degrees of freedom
+ 
+@@ -124,10 +124,10 @@ python scripts/migrate.py --verify --backup
+ Do not modify the command or add additional flags.
+ ````
+ 
+-**Analogy**: Think of Claude as a robot exploring a path:
++**Analogy**: Think of the agent as a robot exploring a path:
+ 
+ * **Narrow bridge with cliffs on both sides**: There's only one safe way forward. Provide specific guardrails and exact instructions (low freedom). Example: database migrations that must run in exact sequence.
+-* **Open field with no hazards**: Many paths lead to success. Give general direction and trust Claude to find the best route (high freedom). Example: code reviews where context determines the best approach.
++* **Open field with no hazards**: Many paths lead to success. Give general direction and trust the agent to find the best route (high freedom). Example: code reviews where context determines the best approach.
+ 
+ ### Test with all models you plan to use
+ 
+@@ -149,7 +149,7 @@ What works perfectly for Opus might need more detail for Haiku. If you plan to u
+   * `name` - Human-readable name of the Skill (64 characters maximum)
+   * `description` - One-line description of what the Skill does and when to use it (1024 characters maximum)
+ 
+-  For complete Skill structure details, see the [Skills overview](/en/docs/agents-and-tools/agent-skills/overview#skill-structure).
++  For complete Skill structure details, see the [Skills overview](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview#skill-structure).
+ </Note>
+ 
+ ### Naming conventions
+@@ -196,7 +196,7 @@ The `description` field enables Skill discovery and should include both what the
+ 
+ **Be specific and include key terms**. Include both what the Skill does and specific triggers/contexts for when to use it.
+ 
+-Each Skill has exactly one description field. The description is critical for skill selection: Claude uses it to choose the right Skill from potentially 100+ available Skills. Your description must provide enough detail for Claude to know when to select this Skill, while the rest of SKILL.md provides the implementation details.
++Each Skill has exactly one description field. The description is critical for skill selection: agents use it to choose the right Skill from potentially 100+ available Skills. Your description must provide enough detail for an agent to know when to select this Skill, while the rest of SKILL.md provides the implementation details.
+ 
+ Effective examples:
+ 
+@@ -234,7 +234,7 @@ description: Does stuff with files
+ 
+ ### Progressive disclosure patterns
+ 
+-SKILL.md serves as an overview that points Claude to detailed materials as needed, like a table of contents in an onboarding guide. For an explanation of how progressive disclosure works, see [How Skills work](/en/docs/agents-and-tools/agent-skills/overview#how-skills-work) in the overview.
++SKILL.md serves as an overview that points agents to detailed materials as needed, like a table of contents in an onboarding guide. For an explanation of how progressive disclosure works, see [How Skills work](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview#how-skills-work) in the overview.
+ 
+ **Practical guidance:**
+ 
+@@ -248,7 +248,7 @@ A basic Skill starts with just a SKILL.md file containing metadata and instructi
+ 
+ <img src="https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-simple-file.png?fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=87782ff239b297d9a9e8e1b72ed72db9" alt="Simple SKILL.md file showing YAML frontmatter and markdown body" data-og-width="2048" width="2048" data-og-height="1153" height="1153" data-path="images/agent-skills-simple-file.png" data-optimize="true" data-opv="3" srcset="https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-simple-file.png?w=280&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=c61cc33b6f5855809907f7fda94cd80e 280w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-simple-file.png?w=560&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=90d2c0c1c76b36e8d485f49e0810dbfd 560w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-simple-file.png?w=840&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=ad17d231ac7b0bea7e5b4d58fb4aeabb 840w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-simple-file.png?w=1100&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=f5d0a7a3c668435bb0aee9a3a8f8c329 1100w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-simple-file.png?w=1650&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=0e927c1af9de5799cfe557d12249f6e6 1650w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-simple-file.png?w=2500&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=46bbb1a51dd4c8202a470ac8c80a893d 2500w" />
+ 
+-As your Skill grows, you can bundle additional content that Claude loads only when needed:
++As your Skill grows, you can bundle additional content that agents load only when needed:
+ 
+ <img src="https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-bundling-content.png?fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=a5e0aa41e3d53985a7e3e43668a33ea3" alt="Bundling additional reference files like reference.md and forms.md." data-og-width="2048" width="2048" data-og-height="1327" height="1327" data-path="images/agent-skills-bundling-content.png" data-optimize="true" data-opv="3" srcset="https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-bundling-content.png?w=280&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=f8a0e73783e99b4a643d79eac86b70a2 280w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-bundling-content.png?w=560&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=dc510a2a9d3f14359416b706f067904a 560w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-bundling-content.png?w=840&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=82cd6286c966303f7dd914c28170e385 840w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-bundling-content.png?w=1100&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=56f3be36c77e4fe4b523df209a6824c6 1100w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-bundling-content.png?w=1650&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=d22b5161b2075656417d56f41a74f3dd 1650w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-bundling-content.png?w=2500&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=3dd4bdd6850ffcc96c6c45fcb0acd6eb 2500w" />
+ 
+@@ -292,11 +292,11 @@ with pdfplumber.open("file.pdf") as pdf:
+ **Examples**: See [EXAMPLES.md](EXAMPLES.md) for common patterns
+ ````
+ 
+-Claude loads FORMS.md, REFERENCE.md, or EXAMPLES.md only when needed.
++Agents load FORMS.md, REFERENCE.md, or EXAMPLES.md only when needed.
+ 
+ #### Pattern 2: Domain-specific organization
+ 
+-For Skills with multiple domains, organize content by domain to avoid loading irrelevant context. When a user asks about sales metrics, Claude only needs to read sales-related schemas, not finance or marketing data. This keeps token usage low and context focused.
++For Skills with multiple domains, organize content by domain to avoid loading irrelevant context. When a user asks about sales metrics, the agent only needs to read sales-related schemas, not finance or marketing data. This keeps token usage low and context focused.
+ 
+ ```
+ bigquery-skill/
+@@ -348,13 +348,13 @@ For simple edits, modify the XML directly.
+ **For OOXML details**: See [OOXML.md](OOXML.md)
+ ```
+ 
+-Claude reads REDLINING.md or OOXML.md only when the user needs those features.
++Agents read REDLINING.md or OOXML.md only when the user needs those features.
+ 
+ ### Avoid deeply nested references
+ 
+-Claude may partially read files when they're referenced from other referenced files. When encountering nested references, Claude might use commands like `head -100` to preview content rather than reading entire files, resulting in incomplete information.
++Agents may partially read files when they're referenced from other referenced files. When encountering nested references, an agent might use commands like `head -100` to preview content rather than reading entire files, resulting in incomplete information.
+ 
+-**Keep references one level deep from SKILL.md**. All reference files should link directly from SKILL.md to ensure Claude reads complete files when needed.
++**Keep references one level deep from SKILL.md**. All reference files should link directly from SKILL.md to ensure agents read complete files when needed.
+ 
+ **Bad example: Too deep**:
+ 
+@@ -382,7 +382,7 @@ Here's the actual information...
+ 
+ ### Structure longer reference files with table of contents
+ 
+-For reference files longer than 100 lines, include a table of contents at the top. This ensures Claude can see the full scope of available information even when previewing with partial reads.
++For reference files longer than 100 lines, include a table of contents at the top. This ensures agents can see the full scope of available information even when previewing with partial reads.
+ 
+ **Example**:
+ 
+@@ -403,7 +403,7 @@ For reference files longer than 100 lines, include a table of contents at the to
+ ...
+ ```
+ 
+-Claude can then read the complete file or jump to specific sections as needed.
++Agents can then read the complete file or jump to specific sections as needed.
+ 
+ For details on how this filesystem-based architecture enables progressive disclosure, see the [Runtime environment](#runtime-environment) section in the Advanced section below.
+ 
+@@ -411,7 +411,7 @@ For details on how this filesystem-based architecture enables progressive disclo
+ 
+ ### Use workflows for complex tasks
+ 
+-Break complex operations into clear, sequential steps. For particularly complex workflows, provide a checklist that Claude can copy into its response and check off as it progresses.
++Break complex operations into clear, sequential steps. For particularly complex workflows, provide a checklist that the agent can copy into its response and check off as it progresses.
+ 
+ **Example 1: Research synthesis workflow** (for Skills without code):
+ 
+@@ -498,7 +498,7 @@ Run: `python scripts/verify_output.py output.pdf`
+ If verification fails, return to Step 2.
+ ````
+ 
+-Clear steps prevent Claude from skipping critical validation. The checklist helps both Claude and you track progress through multi-step workflows.
++Clear steps prevent agents from skipping critical validation. The checklist helps both you and the agent track progress through multi-step workflows.
+ 
+ ### Implement feedback loops
+ 
+@@ -524,7 +524,7 @@ This pattern greatly improves output quality.
+ 5. Finalize and save the document
+ ```
+ 
+-This shows the validation loop pattern using reference documents instead of scripts. The "validator" is STYLE\_GUIDE.md, and Claude performs the check by reading and comparing.
++This shows the validation loop pattern using reference documents instead of scripts. The "validator" is STYLE\_GUIDE.md, and the agent performs the check by reading and comparing.
+ 
+ **Example 2: Document editing process** (for Skills with code):
+ 
+@@ -593,7 +593,7 @@ Choose one term and use it throughout the Skill:
+ * Mix "field", "box", "element", "control"
+ * Mix "extract", "pull", "get", "retrieve"
+ 
+-Consistency helps Claude understand and follow instructions.
++Consistency helps agents understand and follow instructions.
+ 
+ ## Common patterns
+ 
+@@ -688,11 +688,11 @@ chore: update dependencies and refactor error handling
+ Follow this style: type(scope): brief description, then detailed explanation.
+ ````
+ 
+-Examples help Claude understand the desired style and level of detail more clearly than descriptions alone.
++Examples help agents understand the desired style and level of detail more clearly than descriptions alone.
+ 
+ ### Conditional workflow pattern
+ 
+-Guide Claude through decision points:
++Guide agents through decision points:
+ 
+ ```markdown  theme={null}
+ ## Document modification workflow
+@@ -715,7 +715,7 @@ Guide Claude through decision points:
+ ```
+ 
+ <Tip>
+-  If workflows become large or complicated with many steps, consider pushing them into separate files and tell Claude to read the appropriate file based on the task at hand.
++  If workflows become large or complicated with many steps, consider pushing them into separate files and tell the agent to read the appropriate file based on the task at hand.
+ </Tip>
+ 
+ ## Evaluation and iteration
+@@ -726,9 +726,9 @@ Guide Claude through decision points:
+ 
+ **Evaluation-driven development:**
+ 
+-1. **Identify gaps**: Run Claude on representative tasks without a Skill. Document specific failures or missing context
++1. **Identify gaps**: Run your agent on representative tasks without a Skill. Document specific failures or missing context
+ 2. **Create evaluations**: Build three scenarios that test these gaps
+-3. **Establish baseline**: Measure Claude's performance without the Skill
++3. **Establish baseline**: Measure the agent's performance without the Skill
+ 4. **Write minimal instructions**: Create just enough content to address the gaps and pass evaluations
+ 5. **Iterate**: Execute evaluations, compare against baseline, and refine
+ 
+@@ -753,51 +753,51 @@ This approach ensures you're solving actual problems rather than anticipating re
+   This example demonstrates a data-driven evaluation with a simple testing rubric. We do not currently provide a built-in way to run these evaluations. Users can create their own evaluation system. Evaluations are your source of truth for measuring Skill effectiveness.
+ </Note>
+ 
+-### Develop Skills iteratively with Claude
++### Develop Skills iteratively with the agent
+ 
+-The most effective Skill development process involves Claude itself. Work with one instance of Claude ("Claude A") to create a Skill that will be used by other instances ("Claude B"). Claude A helps you design and refine instructions, while Claude B tests them in real tasks. This works because Claude models understand both how to write effective agent instructions and what information agents need.
++The most effective Skill development process involves the agent itself. Work with one instance ("Agent A") to create a Skill that will be used by other instances ("Agent B"). Agent A helps you design and refine instructions, while Agent B tests them in real tasks. This works because the underlying models understand both how to write effective agent instructions and what information agents need.
+ 
+ **Creating a new Skill:**
+ 
+-1. **Complete a task without a Skill**: Work through a problem with Claude A using normal prompting. As you work, you'll naturally provide context, explain preferences, and share procedural knowledge. Notice what information you repeatedly provide.
++1. **Complete a task without a Skill**: Work through a problem with Agent A using normal prompting. As you work, you'll naturally provide context, explain preferences, and share procedural knowledge. Notice what information you repeatedly provide.
+ 
+ 2. **Identify the reusable pattern**: After completing the task, identify what context you provided that would be useful for similar future tasks.
+ 
+    **Example**: If you worked through a BigQuery analysis, you might have provided table names, field definitions, filtering rules (like "always exclude test accounts"), and common query patterns.
+ 
+-3. **Ask Claude A to create a Skill**: "Create a Skill that captures this BigQuery analysis pattern we just used. Include the table schemas, naming conventions, and the rule about filtering test accounts."
++3. **Ask Agent A to create a Skill**: "Create a Skill that captures this BigQuery analysis pattern we just used. Include the table schemas, naming conventions, and the rule about filtering test accounts."
+ 
+    <Tip>
+-     Claude models understand the Skill format and structure natively. You don't need special system prompts or a "writing skills" skill to get Claude to help create Skills. Simply ask Claude to create a Skill and it will generate properly structured SKILL.md content with appropriate frontmatter and body content.
++     Modern agents understand the Skill format and structure natively. You don't need special system prompts or a "writing skills" skill to get help creating Skills. Simply ask the agent to create a Skill and it will generate properly structured SKILL.md content with appropriate frontmatter and body content.
+    </Tip>
+ 
+-4. **Review for conciseness**: Check that Claude A hasn't added unnecessary explanations. Ask: "Remove the explanation about what win rate means - Claude already knows that."
++4. **Review for conciseness**: Check that Agent A hasn't added unnecessary explanations. Ask: "Remove the explanation about what win rate means - the agent already knows that."
+ 
+-5. **Improve information architecture**: Ask Claude A to organize the content more effectively. For example: "Organize this so the table schema is in a separate reference file. We might add more tables later."
++5. **Improve information architecture**: Ask Agent A to organize the content more effectively. For example: "Organize this so the table schema is in a separate reference file. We might add more tables later."
+ 
+-6. **Test on similar tasks**: Use the Skill with Claude B (a fresh instance with the Skill loaded) on related use cases. Observe whether Claude B finds the right information, applies rules correctly, and handles the task successfully.
++6. **Test on similar tasks**: Use the Skill with Agent B (a fresh instance with the Skill loaded) on related use cases. Observe whether Agent B finds the right information, applies rules correctly, and handles the task successfully.
+ 
+-7. **Iterate based on observation**: If Claude B struggles or misses something, return to Claude A with specifics: "When Claude used this Skill, it forgot to filter by date for Q4. Should we add a section about date filtering patterns?"
++7. **Iterate based on observation**: If Agent B struggles or misses something, return to Agent A with specifics: "When the agent used this Skill, it forgot to filter by date for Q4. Should we add a section about date filtering patterns?"
+ 
+ **Iterating on existing Skills:**
+ 
+ The same hierarchical pattern continues when improving Skills. You alternate between:
+ 
+-* **Working with Claude A** (the expert who helps refine the Skill)
+-* **Testing with Claude B** (the agent using the Skill to perform real work)
+-* **Observing Claude B's behavior** and bringing insights back to Claude A
++* **Working with Agent A** (the expert who helps refine the Skill)
++* **Testing with Agent B** (the agent using the Skill to perform real work)
++* **Observing Agent B's behavior** and bringing insights back to Agent A
+ 
+-1. **Use the Skill in real workflows**: Give Claude B (with the Skill loaded) actual tasks, not test scenarios
++1. **Use the Skill in real workflows**: Give Agent B (with the Skill loaded) actual tasks, not test scenarios
+ 
+-2. **Observe Claude B's behavior**: Note where it struggles, succeeds, or makes unexpected choices
++2. **Observe Agent B's behavior**: Note where it struggles, succeeds, or makes unexpected choices
+ 
+-   **Example observation**: "When I asked Claude B for a regional sales report, it wrote the query but forgot to filter out test accounts, even though the Skill mentions this rule."
++   **Example observation**: "When I asked Agent B for a regional sales report, it wrote the query but forgot to filter out test accounts, even though the Skill mentions this rule."
+ 
+-3. **Return to Claude A for improvements**: Share the current SKILL.md and describe what you observed. Ask: "I noticed Claude B forgot to filter test accounts when I asked for a regional report. The Skill mentions filtering, but maybe it's not prominent enough?"
++3. **Return to Agent A for improvements**: Share the current SKILL.md and describe what you observed. Ask: "I noticed Agent B forgot to filter test accounts when I asked for a regional report. The Skill mentions filtering, but maybe it's not prominent enough?"
+ 
+-4. **Review Claude A's suggestions**: Claude A might suggest reorganizing to make rules more prominent, using stronger language like "MUST filter" instead of "always filter", or restructuring the workflow section.
++4. **Review Agent A's suggestions**: Agent A might suggest reorganizing to make rules more prominent, using stronger language like "MUST filter" instead of "always filter", or restructuring the workflow section.
+ 
+-5. **Apply and test changes**: Update the Skill with Claude A's refinements, then test again with Claude B on similar requests
++5. **Apply and test changes**: Update the Skill with Agent A's refinements, then test again with Agent B on similar requests
+ 
+ 6. **Repeat based on usage**: Continue this observe-refine-test cycle as you encounter new scenarios. Each iteration improves the Skill based on real agent behavior, not assumptions.
+ 
+@@ -807,18 +807,18 @@ The same hierarchical pattern continues when improving Skills. You alternate bet
+ 2. Ask: Does the Skill activate when expected? Are instructions clear? What's missing?
+ 3. Incorporate feedback to address blind spots in your own usage patterns
+ 
+-**Why this approach works**: Claude A understands agent needs, you provide domain expertise, Claude B reveals gaps through real usage, and iterative refinement improves Skills based on observed behavior rather than assumptions.
++**Why this approach works**: Agent A understands agent needs, you provide domain expertise, Agent B reveals gaps through real usage, and iterative refinement improves Skills based on observed behavior rather than assumptions.
+ 
+-### Observe how Claude navigates Skills
++### Observe how agents navigate Skills
+ 
+-As you iterate on Skills, pay attention to how Claude actually uses them in practice. Watch for:
++As you iterate on Skills, pay attention to how agents actually use them in practice. Watch for:
+ 
+-* **Unexpected exploration paths**: Does Claude read files in an order you didn't anticipate? This might indicate your structure isn't as intuitive as you thought
+-* **Missed connections**: Does Claude fail to follow references to important files? Your links might need to be more explicit or prominent
+-* **Overreliance on certain sections**: If Claude repeatedly reads the same file, consider whether that content should be in the main SKILL.md instead
+-* **Ignored content**: If Claude never accesses a bundled file, it might be unnecessary or poorly signaled in the main instructions
++* **Unexpected exploration paths**: Does the agent read files in an order you didn't anticipate? This might indicate your structure isn't as intuitive as you thought
++* **Missed connections**: Does the agent fail to follow references to important files? Your links might need to be more explicit or prominent
++* **Overreliance on certain sections**: If the agent repeatedly reads the same file, consider whether that content should be in the main SKILL.md instead
++* **Ignored content**: If the agent never accesses a bundled file, it might be unnecessary or poorly signaled in the main instructions
+ 
+-Iterate based on these observations rather than assumptions. The 'name' and 'description' in your Skill's metadata are particularly critical. Claude uses these when deciding whether to trigger the Skill in response to the current task. Make sure they clearly describe what the Skill does and when it should be used.
++Iterate based on these observations rather than assumptions. The 'name' and 'description' in your Skill's metadata are particularly critical. Agents use these when deciding whether to trigger the Skill in response to the current task. Make sure they clearly describe what the Skill does and when it should be used.
+ 
+ ## Anti-patterns to avoid
+ 
+@@ -854,7 +854,7 @@ The sections below focus on Skills that include executable scripts. If your Skil
+ 
+ ### Solve, don't punt
+ 
+-When writing scripts for Skills, handle error conditions rather than punting to Claude.
++When writing scripts for Skills, handle error conditions rather than punting to the agent.
+ 
+ **Good example: Handle errors explicitly**:
+ 
+@@ -876,15 +876,15 @@ def process_file(path):
+         return ''
+ ```
+ 
+-**Bad example: Punt to Claude**:
++**Bad example: Punt to the agent**:
+ 
+ ```python  theme={null}
+ def process_file(path):
+-    # Just fail and let Claude figure it out
++    # Just fail and let the agent figure it out
+     return open(path).read()
+ ```
+ 
+-Configuration parameters should also be justified and documented to avoid "voodoo constants" (Ousterhout's law). If you don't know the right value, how will Claude determine it?
++Configuration parameters should also be justified and documented to avoid "voodoo constants" (Ousterhout's law). If you don't know the right value, how will the agent determine it?
+ 
+ **Good example: Self-documenting**:
+ 
+@@ -907,7 +907,7 @@ RETRIES = 5   # Why 5?
+ 
+ ### Provide utility scripts
+ 
+-Even if Claude could write a script, pre-made scripts offer advantages:
++Even if your agent could write a script, pre-made scripts offer advantages:
+ 
+ **Benefits of utility scripts**:
+ 
+@@ -918,9 +918,9 @@ Even if Claude could write a script, pre-made scripts offer advantages:
+ 
+ <img src="https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-executable-scripts.png?fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=4bbc45f2c2e0bee9f2f0d5da669bad00" alt="Bundling executable scripts alongside instruction files" data-og-width="2048" width="2048" data-og-height="1154" height="1154" data-path="images/agent-skills-executable-scripts.png" data-optimize="true" data-opv="3" srcset="https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-executable-scripts.png?w=280&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=9a04e6535a8467bfeea492e517de389f 280w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-executable-scripts.png?w=560&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=e49333ad90141af17c0d7651cca7216b 560w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-executable-scripts.png?w=840&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=954265a5df52223d6572b6214168c428 840w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-executable-scripts.png?w=1100&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=2ff7a2d8f2a83ee8af132b29f10150fd 1100w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-executable-scripts.png?w=1650&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=48ab96245e04077f4d15e9170e081cfb 1650w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-executable-scripts.png?w=2500&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=0301a6c8b3ee879497cc5b5483177c90 2500w" />
+ 
+-The diagram above shows how executable scripts work alongside instruction files. The instruction file (forms.md) references the script, and Claude can execute it without loading its contents into context.
++The diagram above shows how executable scripts work alongside instruction files. The instruction file (forms.md) references the script, and the agent can execute it without loading its contents into context.
+ 
+-**Important distinction**: Make clear in your instructions whether Claude should:
++**Important distinction**: Make clear in your instructions whether the agent should:
+ 
+ * **Execute the script** (most common): "Run `analyze_form.py` to extract fields"
+ * **Read it as reference** (for complex logic): "See `analyze_form.py` for the field extraction algorithm"
+@@ -962,7 +962,7 @@ python scripts/fill_form.py input.pdf fields.json output.pdf
+ 
+ ### Use visual analysis
+ 
+-When inputs can be rendered as images, have Claude analyze them:
++When inputs can be rendered as images, have the agent analyze them:
+ 
+ ````markdown  theme={null}
+ ## Form layout analysis
+@@ -973,20 +973,20 @@ When inputs can be rendered as images, have Claude analyze them:
+    ```
+ 
+ 2. Analyze each page image to identify form fields
+-3. Claude can see field locations and types visually
++3. The agent can see field locations and types visually
+ ````
+ 
+ <Note>
+   In this example, you'd need to write the `pdf_to_images.py` script.
+ </Note>
+ 
+-Claude's vision capabilities help understand layouts and structures.
++Agent vision capabilities help understand layouts and structures.
+ 
+ ### Create verifiable intermediate outputs
+ 
+-When Claude performs complex, open-ended tasks, it can make mistakes. The "plan-validate-execute" pattern catches errors early by having Claude first create a plan in a structured format, then validate that plan with a script before executing it.
++When agents perform complex, open-ended tasks, they can make mistakes. The "plan-validate-execute" pattern catches errors early by having the agent first create a plan in a structured format, then validate that plan with a script before executing it.
+ 
+-**Example**: Imagine asking Claude to update 50 form fields in a PDF based on a spreadsheet. Without validation, Claude might reference non-existent fields, create conflicting values, miss required fields, or apply updates incorrectly.
++**Example**: Imagine asking the agent to update 50 form fields in a PDF based on a spreadsheet. Without validation, it might reference non-existent fields, create conflicting values, miss required fields, or apply updates incorrectly.
+ 
+ **Solution**: Use the workflow pattern shown above (PDF form filling), but add an intermediate `changes.json` file that gets validated before applying changes. The workflow becomes: analyze → **create plan file** → **validate plan** → execute → verify.
+ 
+@@ -994,12 +994,12 @@ When Claude performs complex, open-ended tasks, it can make mistakes. The "plan-
+ 
+ * **Catches errors early**: Validation finds problems before changes are applied
+ * **Machine-verifiable**: Scripts provide objective verification
+-* **Reversible planning**: Claude can iterate on the plan without touching originals
++* **Reversible planning**: The agent can iterate on the plan without touching originals
+ * **Clear debugging**: Error messages point to specific problems
+ 
+ **When to use**: Batch operations, destructive changes, complex validation rules, high-stakes operations.
+ 
+-**Implementation tip**: Make validation scripts verbose with specific error messages like "Field 'signature\_date' not found. Available fields: customer\_name, order\_total, signature\_date\_signed" to help Claude fix issues.
++**Implementation tip**: Make validation scripts verbose with specific error messages like "Field 'signature\_date' not found. Available fields: customer\_name, order\_total, signature\_date\_signed" to help the agent fix issues.
+ 
+ ### Package dependencies
+ 
+@@ -1008,32 +1008,32 @@ Skills run in the code execution environment with platform-specific limitations:
+ * **claude.ai**: Can install packages from npm and PyPI and pull from GitHub repositories
+ * **Anthropic API**: Has no network access and no runtime package installation
+ 
+-List required packages in your SKILL.md and verify they're available in the [code execution tool documentation](/en/docs/agents-and-tools/tool-use/code-execution-tool).
++List required packages in your SKILL.md and verify they're available in the [code execution tool documentation](https://platform.claude.com/docs/en/agents-and-tools/tool-use/code-execution-tool).
+ 
+ ### Runtime environment
+ 
+-Skills run in a code execution environment with filesystem access, bash commands, and code execution capabilities. For the conceptual explanation of this architecture, see [The Skills architecture](/en/docs/agents-and-tools/agent-skills/overview#the-skills-architecture) in the overview.
++Skills run in a code execution environment with filesystem access, bash commands, and code execution capabilities. For the conceptual explanation of this architecture, see [The Skills architecture](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview#the-skills-architecture) in the overview.
+ 
+ **How this affects your authoring:**
+ 
+-**How Claude accesses Skills:**
++**How agents access Skills:**
+ 
+ 1. **Metadata pre-loaded**: At startup, the name and description from all Skills' YAML frontmatter are loaded into the system prompt
+-2. **Files read on-demand**: Claude uses bash Read tools to access SKILL.md and other files from the filesystem when needed
++2. **Files read on-demand**: Agents use their file-reading tools to access SKILL.md and other files from the filesystem when needed
+ 3. **Scripts executed efficiently**: Utility scripts can be executed via bash without loading their full contents into context. Only the script's output consumes tokens
+ 4. **No context penalty for large files**: Reference files, data, or documentation don't consume context tokens until actually read
+ 
+-* **File paths matter**: Claude navigates your skill directory like a filesystem. Use forward slashes (`reference/guide.md`), not backslashes
++* **File paths matter**: Agents navigate your skill directory like a filesystem. Use forward slashes (`reference/guide.md`), not backslashes
+ * **Name files descriptively**: Use names that indicate content: `form_validation_rules.md`, not `doc2.md`
+ * **Organize for discovery**: Structure directories by domain or feature
+   * Good: `reference/finance.md`, `reference/sales.md`
+   * Bad: `docs/file1.md`, `docs/file2.md`
+ * **Bundle comprehensive resources**: Include complete API docs, extensive examples, large datasets; no context penalty until accessed
+-* **Prefer scripts for deterministic operations**: Write `validate_form.py` rather than asking Claude to generate validation code
++* **Prefer scripts for deterministic operations**: Write `validate_form.py` rather than asking the agent to generate validation code
+ * **Make execution intent clear**:
+   * "Run `analyze_form.py` to extract fields" (execute)
+   * "See `analyze_form.py` for the extraction algorithm" (read as reference)
+-* **Test file access patterns**: Verify Claude can navigate your directory structure by testing with real requests
++* **Test file access patterns**: Verify the agent can navigate your directory structure by testing with real requests
+ 
+ **Example:**
+ 
+@@ -1046,9 +1046,9 @@ bigquery-skill/
+     └── product.md (usage analytics)
+ ```
+ 
+-When the user asks about revenue, Claude reads SKILL.md, sees the reference to `reference/finance.md`, and invokes bash to read just that file. The sales.md and product.md files remain on the filesystem, consuming zero context tokens until needed. This filesystem-based model is what enables progressive disclosure. Claude can navigate and selectively load exactly what each task requires.
++When the user asks about revenue, the agent reads SKILL.md, sees the reference to `reference/finance.md`, and invokes bash to read just that file. The sales.md and product.md files remain on the filesystem, consuming zero context tokens until needed. This filesystem-based model is what enables progressive disclosure. Agents can navigate and selectively load exactly what each task requires.
+ 
+-For complete details on the technical architecture, see [How Skills work](/en/docs/agents-and-tools/agent-skills/overview#how-skills-work) in the Skills overview.
++For complete details on the technical architecture, see [How Skills work](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview#how-skills-work) in the Skills overview.
+ 
+ ### MCP tool references
+ 
+@@ -1068,7 +1068,7 @@ Where:
+ * `BigQuery` and `GitHub` are MCP server names
+ * `bigquery_schema` and `create_issue` are the tool names within those servers
+ 
+-Without the server prefix, Claude may fail to locate the tool, especially when multiple MCP servers are available.
++Without the server prefix, agents may fail to locate the tool, especially when multiple MCP servers are available.
+ 
+ ### Avoid assuming tools are installed
+ 
+@@ -1092,11 +1092,11 @@ reader = PdfReader("file.pdf")
+ 
+ ### YAML frontmatter requirements
+ 
+-The SKILL.md frontmatter requires `name` (64 characters max) and `description` (1024 characters max) fields. See the [Skills overview](/en/docs/agents-and-tools/agent-skills/overview#skill-structure) for complete structure details.
++The SKILL.md frontmatter requires `name` (64 characters max) and `description` (1024 characters max) fields. See the [Skills overview](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview#skill-structure) for complete structure details.
+ 
\ No newline at end of file
