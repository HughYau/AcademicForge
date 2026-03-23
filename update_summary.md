## Updated Skills

Submodule skills/AI-research-SKILLs 085c480..28d8b96:
  > docs: add contributors widget and clean up contributing section
  > Merge pull request #39 from tang-vu/contribai/fix/security/critical-prompt-injection-in-claude-code
Submodule skills/claude-scientific-skills contains modified content
Submodule skills/claude-scientific-skills 1346c01..1531326:
  > Add K-Dense BYOK AI co-scientist to README with features and links
  > Add writing skills
Submodule skills/humanizer d8085c7..12881ab:
  > Merge pull request #56 from mvanhorn/osc/42-add-hyphenation-pattern
  > Merge pull request #57 from mvanhorn/osc/35-remove-separator-rules
  > Merge pull request #58 from mvanhorn/osc/7-add-license-file
diff --git a/skills/planning-with-files/SKILL.md b/skills/planning-with-files/SKILL.md
index d967199..43672e5 100644
--- a/skills/planning-with-files/SKILL.md
+++ b/skills/planning-with-files/SKILL.md
@@ -7,7 +7,7 @@ hooks:
   UserPromptSubmit:
     - hooks:
         - type: command
-          command: "if [ -f task_plan.md ]; then echo '[planning-with-files] Active plan detected. If you have not read task_plan.md, progress.md, and findings.md in this conversation, read them now before proceeding.'; fi"
+          command: "if [ -f task_plan.md ]; then echo '[planning-with-files] ACTIVE PLAN — current state:'; head -50 task_plan.md; echo ''; echo '=== recent progress ==='; tail -20 progress.md 2>/dev/null; echo ''; echo '[planning-with-files] Read findings.md for research context. Continue from the current phase.'; fi"
   PreToolUse:
     - matcher: "Write|Edit|Bash|Read|Glob|Grep"
       hooks:
@@ -21,7 +21,7 @@ hooks:
   Stop:
     - hooks:
         - type: command
-          command: "SD=\"${OPENCODE_SKILL_ROOT:-$HOME/.config/opencode/skills/planning-with-files}/scripts\"; powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"$SD/check-complete.ps1\" 2>/dev/null || sh \"$SD/check-complete.sh\""
+          command: "SD=\"${SKILL_DIR:-<forge-root>/skills/planning-with-files}/scripts\"; powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"$SD/check-complete.ps1\" 2>/dev/null || sh \"$SD/check-complete.sh\""
 metadata:
   version: "2.23.0"
 ---
@@ -36,12 +36,12 @@ Work like Manus: Use persistent markdown files as your "working memory on disk."
 
 ```bash
 # Linux/macOS (auto-detects python3 or python)
-$(command -v python3 || command -v python) ~/.config/opencode/skills/planning-with-files/scripts/session-catchup.py "$(pwd)"
+$(command -v python3 || command -v python) skills/planning-with-files/scripts/session-catchup.py "$(pwd)"
 ```
 
 ```powershell
 # Windows PowerShell
-python "$env:USERPROFILE\.opencode\skills\planning-with-files\scripts\session-catchup.py" (Get-Location)
+python "skills\planning-with-files\scripts\session-catchup.py" (Get-Location)
 ```
 
 If catchup report shows unsynced context:
@@ -52,12 +52,12 @@ If catchup report shows unsynced context:
 
 ## Important: Where Files Go
 
-- **Templates** are in `~/.config/opencode/skills/planning-with-files/templates/`
+- **Templates** are in `<forge-root>/skills/planning-with-files/templates/`
 - **Your planning files** go in **your project directory**
 
 | Location | What Goes There |
 |----------|-----------------|
-| Skill directory (`~/.config/opencode/skills/planning-with-files/`) | Templates, scripts, reference docs |
+| Skill directory (`<forge-root>/skills/planning-with-files/`) | Templates, scripts, reference docs |
 | Your project directory | `task_plan.md`, `findings.md`, `progress.md` |
 
 ## Quick Start
diff --git a/skills/planning-with-files/scripts/session-catchup.py b/skills/planning-with-files/scripts/session-catchup.py
index 5122b91..b187e83 100644
--- a/skills/planning-with-files/scripts/session-catchup.py
+++ b/skills/planning-with-files/scripts/session-catchup.py
@@ -254,7 +254,7 @@ def main():
             print(f"USER: {msg['content'][:300]}")
         else:
             if msg.get('content'):
-                print(f"OPENCODE: {msg['content'][:300]}")
+                print(f"ASSISTANT: {msg['content'][:300]}")
             if msg.get('tools'):
                 print(f"  Tools: {', '.join(msg['tools'][:4])}")
 
diff --git a/skills/superpowers/brainstorming/SKILL.md b/skills/superpowers/brainstorming/SKILL.md
index 724dc79..edbc2b5 100644
--- a/skills/superpowers/brainstorming/SKILL.md
+++ b/skills/superpowers/brainstorming/SKILL.md
@@ -27,7 +27,7 @@ You MUST create a task for each of these items and complete them in order:
 4. **Propose 2-3 approaches** — with trade-offs and your recommendation
 5. **Present design** — in sections scaled to their complexity, get user approval after each section
 6. **Write design doc** — save to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` and commit
-7. **Spec review loop** — dispatch spec-document-reviewer subagent with precisely crafted review context (never your session history); fix issues and re-dispatch until approved (max 5 iterations, then surface to human)
+7. **Spec review loop** — dispatch spec-document-reviewer subagent with precisely crafted review context (never your session history); fix issues and re-dispatch until approved (max 3 iterations, then surface to human)
 8. **User reviews written spec** — ask user to review the spec file before proceeding
 9. **Transition to implementation** — invoke writing-plans skill to create implementation plan
 
@@ -121,7 +121,7 @@ After writing the spec document:
 
 1. Dispatch spec-document-reviewer subagent (see spec-document-reviewer-prompt.md)
 2. If Issues Found: fix, re-dispatch, repeat until Approved
-3. If loop exceeds 5 iterations, surface to human for guidance
+3. If loop exceeds 3 iterations, surface to human for guidance
 
 **User Review Gate:**
 After the spec review loop passes, ask the user to review the written spec before proceeding:
diff --git a/skills/superpowers/brainstorming/scripts/server.js b/skills/superpowers/brainstorming/scripts/server.js
deleted file mode 100644
index dec2f7a..0000000
--- a/skills/superpowers/brainstorming/scripts/server.js
+++ /dev/null
@@ -1,338 +0,0 @@
-const crypto = require('crypto');
-const http = require('http');
-const fs = require('fs');
-const path = require('path');
-
-// ========== WebSocket Protocol (RFC 6455) ==========
-
-const OPCODES = { TEXT: 0x01, CLOSE: 0x08, PING: 0x09, PONG: 0x0A };
-const WS_MAGIC = '258EAFA5-E914-47DA-95CA-C5AB0DC85B11';
-
-function computeAcceptKey(clientKey) {
-  return crypto.createHash('sha1').update(clientKey + WS_MAGIC).digest('base64');
-}
-
-function encodeFrame(opcode, payload) {
-  const fin = 0x80;
-  const len = payload.length;
-  let header;
-
-  if (len < 126) {
-    header = Buffer.alloc(2);
-    header[0] = fin | opcode;
-    header[1] = len;
-  } else if (len < 65536) {
-    header = Buffer.alloc(4);
-    header[0] = fin | opcode;
-    header[1] = 126;
-    header.writeUInt16BE(len, 2);
-  } else {
-    header = Buffer.alloc(10);
-    header[0] = fin | opcode;
-    header[1] = 127;
-    header.writeBigUInt64BE(BigInt(len), 2);
-  }
-
-  return Buffer.concat([header, payload]);
-}
-
-function decodeFrame(buffer) {
-  if (buffer.length < 2) return null;
-
-  const secondByte = buffer[1];
-  const opcode = buffer[0] & 0x0F;
-  const masked = (secondByte & 0x80) !== 0;
-  let payloadLen = secondByte & 0x7F;
-  let offset = 2;
-
-  if (!masked) throw new Error('Client frames must be masked');
-
-  if (payloadLen === 126) {
-    if (buffer.length < 4) return null;
-    payloadLen = buffer.readUInt16BE(2);
-    offset = 4;
-  } else if (payloadLen === 127) {
-    if (buffer.length < 10) return null;
-    payloadLen = Number(buffer.readBigUInt64BE(2));
-    offset = 10;
-  }
-
-  const maskOffset = offset;
-  const dataOffset = offset + 4;
-  const totalLen = dataOffset + payloadLen;
-  if (buffer.length < totalLen) return null;
-
-  const mask = buffer.slice(maskOffset, dataOffset);
-  const data = Buffer.alloc(payloadLen);
-  for (let i = 0; i < payloadLen; i++) {
-    data[i] = buffer[dataOffset + i] ^ mask[i % 4];
-  }
-
-  return { opcode, payload: data, bytesConsumed: totalLen };
-}
-
-// ========== Configuration ==========
-
-const PORT = process.env.BRAINSTORM_PORT || (49152 + Math.floor(Math.random() * 16383));
-const HOST = process.env.BRAINSTORM_HOST || '127.0.0.1';
-const URL_HOST = process.env.BRAINSTORM_URL_HOST || (HOST === '127.0.0.1' ? 'localhost' : HOST);
-const SCREEN_DIR = process.env.BRAINSTORM_DIR || '/tmp/brainstorm';
-const OWNER_PID = process.env.BRAINSTORM_OWNER_PID ? Number(process.env.BRAINSTORM_OWNER_PID) : null;
-
-const MIME_TYPES = {
-  '.html': 'text/html', '.css': 'text/css', '.js': 'application/javascript',
-  '.json': 'application/json', '.png': 'image/png', '.jpg': 'image/jpeg',
-  '.jpeg': 'image/jpeg', '.gif': 'image/gif', '.svg': 'image/svg+xml'
-};
-
-// ========== Templates and Constants ==========
-
-const WAITING_PAGE = `<!DOCTYPE html>
-<html>
-<head><meta charset="utf-8"><title>Brainstorm Companion</title>
-<style>body { font-family: system-ui, sans-serif; padding: 2rem; max-width: 800px; margin: 0 auto; }
-h1 { color: #333; } p { color: #666; }</style>
-</head>
-<body><h1>Brainstorm Companion</h1>
-<p>Waiting for Claude to push a screen...</p></body></html>`;
-
-const frameTemplate = fs.readFileSync(path.join(__dirname, 'frame-template.html'), 'utf-8');
-const helperScript = fs.readFileSync(path.join(__dirname, 'helper.js'), 'utf-8');
-const helperInjection = '<script>\n' + helperScript + '\n</script>';
-
-// ========== Helper Functions ==========
-
-function isFullDocument(html) {
-  const trimmed = html.trimStart().toLowerCase();
-  return trimmed.startsWith('<!doctype') || trimmed.startsWith('<html');
-}
-
-function wrapInFrame(content) {
-  return frameTemplate.replace('<!-- CONTENT -->', content);
-}
-
-function getNewestScreen() {
-  const files = fs.readdirSync(SCREEN_DIR)
-    .filter(f => f.endsWith('.html'))
-    .map(f => {
-      const fp = path.join(SCREEN_DIR, f);
-      return { path: fp, mtime: fs.statSync(fp).mtime.getTime() };
-    })
-    .sort((a, b) => b.mtime - a.mtime);
-  return files.length > 0 ? files[0].path : null;
-}
-
-// ========== HTTP Request Handler ==========
-
-function handleRequest(req, res) {
-  touchActivity();
-  if (req.method === 'GET' && req.url === '/') {
-    const screenFile = getNewestScreen();
-    let html = screenFile
-      ? (raw => isFullDocument(raw) ? raw : wrapInFrame(raw))(fs.readFileSync(screenFile, 'utf-8'))
-      : WAITING_PAGE;
-
-    if (html.includes('</body>')) {
-      html = html.replace('</body>', helperInjection + '\n</body>');
-    } else {
-      html += helperInjection;
-    }
-
-    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
-    res.end(html);
-  } else if (req.method === 'GET' && req.url.startsWith('/files/')) {
-    const fileName = req.url.slice(7);
-    const filePath = path.join(SCREEN_DIR, path.basename(fileName));
-    if (!fs.existsSync(filePath)) {
-      res.writeHead(404);
-      res.end('Not found');
-      return;
-    }
-    const ext = path.extname(filePath).toLowerCase();
-    const contentType = MIME_TYPES[ext] || 'application/octet-stream';
-    res.writeHead(200, { 'Content-Type': contentType });
-    res.end(fs.readFileSync(filePath));
-  } else {
-    res.writeHead(404);
-    res.end('Not found');
-  }
-}
-
-// ========== WebSocket Connection Handling ==========
-
-const clients = new Set();
-
-function handleUpgrade(req, socket) {
-  const key = req.headers['sec-websocket-key'];
-  if (!key) { socket.destroy(); return; }
-
-  const accept = computeAcceptKey(key);
-  socket.write(
-    'HTTP/1.1 101 Switching Protocols\r\n' +
-    'Upgrade: websocket\r\n' +
-    'Connection: Upgrade\r\n' +
-    'Sec-WebSocket-Accept: ' + accept + '\r\n\r\n'
-  );
-
-  let buffer = Buffer.alloc(0);
-  clients.add(socket);
-
-  socket.on('data', (chunk) => {
-    buffer = Buffer.concat([buffer, chunk]);
-    while (buffer.length > 0) {
-      let result;
-      try {
-        result = decodeFrame(buffer);
-      } catch (e) {
-        socket.end(encodeFrame(OPCODES.CLOSE, Buffer.alloc(0)));
-        clients.delete(socket);
-        return;
-      }
-      if (!result) break;
-      buffer = buffer.slice(result.bytesConsumed);
-
-      switch (result.opcode) {
-        case OPCODES.TEXT:
-          handleMessage(result.payload.toString());
-          break;
-        case OPCODES.CLOSE:
-          socket.end(encodeFrame(OPCODES.CLOSE, Buffer.alloc(0)));
-          clients.delete(socket);
-          return;
-        case OPCODES.PING:
-          socket.write(encodeFrame(OPCODES.PONG, result.payload));
-          break;
-        case OPCODES.PONG:
-          break;
-        default: {
-          const closeBuf = Buffer.alloc(2);
-          closeBuf.writeUInt16BE(1003);
-          socket.end(encodeFrame(OPCODES.CLOSE, closeBuf));
-          clients.delete(socket);
-          return;
-        }
-      }
-    }
-  });
-
-  socket.on('close', () => clients.delete(socket));
-  socket.on('error', () => clients.delete(socket));
-}
-
-function handleMessage(text) {
-  let event;
-  try {
-    event = JSON.parse(text);
-  } catch (e) {
-    console.error('Failed to parse WebSocket message:', e.message);
-    return;
-  }
-  touchActivity();
-  console.log(JSON.stringify({ source: 'user-event', ...event }));
-  if (event.choice) {
-    const eventsFile = path.join(SCREEN_DIR, '.events');
-    fs.appendFileSync(eventsFile, JSON.stringify(event) + '\n');
-  }
-}
-
-function broadcast(msg) {
-  const frame = encodeFrame(OPCODES.TEXT, Buffer.from(JSON.stringify(msg)));
-  for (const socket of clients) {
-    try { socket.write(frame); } catch (e) { clients.delete(socket); }
-  }
-}
-
-// ========== Activity Tracking ==========
-
-const IDLE_TIMEOUT_MS = 30 * 60 * 1000; // 30 minutes
-let lastActivity = Date.now();
-
-function touchActivity() {
-  lastActivity = Date.now();
-}
-
-// ========== File Watching ==========
-
-const debounceTimers = new Map();
-
-// ========== Server Startup ==========
-
-function startServer() {
-  if (!fs.existsSync(SCREEN_DIR)) fs.mkdirSync(SCREEN_DIR, { recursive: true });
-
-  // Track known files to distinguish new screens from updates.
-  // macOS fs.watch reports 'rename' for both new files and overwrites,
-  // so we can't rely on eventType alone.
-  const knownFiles = new Set(
-    fs.readdirSync(SCREEN_DIR).filter(f => f.endsWith('.html'))
-  );
-
-  const server = http.createServer(handleRequest);
-  server.on('upgrade', handleUpgrade);
-
-  const watcher = fs.watch(SCREEN_DIR, (eventType, filename) => {
-    if (!filename || !filename.endsWith('.html')) return;
-
-    if (debounceTimers.has(filename)) clearTimeout(debounceTimers.get(filename));
-    debounceTimers.set(filename, setTimeout(() => {
-      debounceTimers.delete(filename);
-      const filePath = path.join(SCREEN_DIR, filename);
-
-      if (!fs.existsSync(filePath)) return; // file was deleted
-      touchActivity();
-
-      if (!knownFiles.has(filename)) {
-        knownFiles.add(filename);
-        const eventsFile = path.join(SCREEN_DIR, '.events');
-        if (fs.existsSync(eventsFile)) fs.unlinkSync(eventsFile);
-        console.log(JSON.stringify({ type: 'screen-added', file: filePath }));
-      } else {
-        console.log(JSON.stringify({ type: 'screen-updated', file: filePath }));
-      }
-
-      broadcast({ type: 'reload' });
-    }, 100));
-  });
-  watcher.on('error', (err) => console.error('fs.watch error:', err.message));
-
-  function shutdown(reason) {
-    console.log(JSON.stringify({ type: 'server-stopped', reason }));
-    const infoFile = path.join(SCREEN_DIR, '.server-info');
-    if (fs.existsSync(infoFile)) fs.unlinkSync(infoFile);
-    fs.writeFileSync(
-      path.join(SCREEN_DIR, '.server-stopped'),
-      JSON.stringify({ reason, timestamp: Date.now() }) + '\n'
-    );
-    watcher.close();
-    clearInterval(lifecycleCheck);
-    server.close(() => process.exit(0));
-  }
-
-  function ownerAlive() {
-    if (!OWNER_PID) return true;
-    try { process.kill(OWNER_PID, 0); return true; } catch (e) { return false; }
-  }
-
-  // Check every 60s: exit if owner process died or idle for 30 minutes
-  const lifecycleCheck = setInterval(() => {
-    if (!ownerAlive()) shutdown('owner process exited');
-    else if (Date.now() - lastActivity > IDLE_TIMEOUT_MS) shutdown('idle timeout');
-  }, 60 * 1000);
-  lifecycleCheck.unref();
-
-  server.listen(PORT, HOST, () => {
-    const info = JSON.stringify({
-      type: 'server-started', port: Number(PORT), host: HOST,
-      url_host: URL_HOST, url: 'http://' + URL_HOST + ':' + PORT,
-      screen_dir: SCREEN_DIR
-    });
-    console.log(info);
-    fs.writeFileSync(path.join(SCREEN_DIR, '.server-info'), info + '\n');
-  });
-}
-
-if (require.main === module) {
-  startServer();
-}
-
-module.exports = { computeAcceptKey, encodeFrame, decodeFrame, OPCODES };
diff --git a/skills/superpowers/brainstorming/scripts/start-server.sh b/skills/superpowers/brainstorming/scripts/start-server.sh
index b5f5a75..a0ef299 100755
--- a/skills/superpowers/brainstorming/scripts/start-server.sh
+++ b/skills/superpowers/brainstorming/scripts/start-server.sh
@@ -1,4 +1,4 @@
-#!/bin/bash
+#!/usr/bin/env bash
 # Start the brainstorm server and output connection info
 # Usage: start-server.sh [--project-dir <path>] [--host <bind-host>] [--url-host <display-host>] [--foreground] [--background]
 #
@@ -64,6 +64,16 @@ if [[ -n "${CODEX_CI:-}" && "$FOREGROUND" != "true" && "$FORCE_BACKGROUND" != "t
   FOREGROUND="true"
 fi
 
+# Windows/Git Bash reaps nohup background processes. Auto-foreground when detected.
+if [[ "$FOREGROUND" != "true" && "$FORCE_BACKGROUND" != "true" ]]; then
+  case "${OSTYPE:-}" in
+    msys*|cygwin*|mingw*) FOREGROUND="true" ;;
+  esac
+  if [[ -n "${MSYSTEM:-}" ]]; then
+    FOREGROUND="true"
+  fi
+fi
+
 # Generate unique session directory
 SESSION_ID="$$-$(date +%s)"
 
@@ -96,16 +106,22 @@ if [[ -z "$OWNER_PID" || "$OWNER_PID" == "1" ]]; then
   OWNER_PID="$PPID"
 fi
 
+# On Windows/MSYS2, the MSYS2 PID namespace is invisible to Node.js.
+# Skip owner-PID monitoring — the 30-minute idle timeout prevents orphans.
+case "${OSTYPE:-}" in
+  msys*|cygwin*|mingw*) OWNER_PID="" ;;
+esac
+
 # Foreground mode for environments that reap detached/background processes.
 if [[ "$FOREGROUND" == "true" ]]; then
   echo "$$" > "$PID_FILE"
-  env BRAINSTORM_DIR="$SCREEN_DIR" BRAINSTORM_HOST="$BIND_HOST" BRAINSTORM_URL_HOST="$URL_HOST" BRAINSTORM_OWNER_PID="$OWNER_PID" node server.js
+  env BRAINSTORM_DIR="$SCREEN_DIR" BRAINSTORM_HOST="$BIND_HOST" BRAINSTORM_URL_HOST="$URL_HOST" BRAINSTORM_OWNER_PID="$OWNER_PID" node server.cjs
   exit $?
 fi
 
 # Start server, capturing output to log file
 # Use nohup to survive shell exit; disown to remove from job table
-nohup env BRAINSTORM_DIR="$SCREEN_DIR" BRAINSTORM_HOST="$BIND_HOST" BRAINSTORM_URL_HOST="$URL_HOST" BRAINSTORM_OWNER_PID="$OWNER_PID" node server.js > "$LOG_FILE" 2>&1 &
+nohup env BRAINSTORM_DIR="$SCREEN_DIR" BRAINSTORM_HOST="$BIND_HOST" BRAINSTORM_URL_HOST="$URL_HOST" BRAINSTORM_OWNER_PID="$OWNER_PID" node server.cjs > "$LOG_FILE" 2>&1 &
 SERVER_PID=$!
 disown "$SERVER_PID" 2>/dev/null
 echo "$SERVER_PID" > "$PID_FILE"
diff --git a/skills/superpowers/brainstorming/scripts/stop-server.sh b/skills/superpowers/brainstorming/scripts/stop-server.sh
index c3724de..2e5973d 100755
--- a/skills/superpowers/brainstorming/scripts/stop-server.sh
+++ b/skills/superpowers/brainstorming/scripts/stop-server.sh
@@ -1,4 +1,4 @@
-#!/bin/bash
+#!/usr/bin/env bash
 # Stop the brainstorm server and clean up
 # Usage: stop-server.sh <screen_dir>
 #
@@ -17,7 +17,31 @@ PID_FILE="${SCREEN_DIR}/.server.pid"
 
 if [[ -f "$PID_FILE" ]]; then
   pid=$(cat "$PID_FILE")
-  kill "$pid" 2>/dev/null
+
+  # Try to stop gracefully, fallback to force if still alive
+  kill "$pid" 2>/dev/null || true
+
+  # Wait for graceful shutdown (up to ~2s)
+  for i in {1..20}; do
+    if ! kill -0 "$pid" 2>/dev/null; then
+      break
+    fi
+    sleep 0.1
+  done
+
+  # If still running, escalate to SIGKILL
+  if kill -0 "$pid" 2>/dev/null; then
+    kill -9 "$pid" 2>/dev/null || true
+
+    # Give SIGKILL a moment to take effect
+    sleep 0.1
+  fi
+
+  if kill -0 "$pid" 2>/dev/null; then
+    echo '{"status": "failed", "error": "process still running"}'
+    exit 1
+  fi
+
   rm -f "$PID_FILE" "${SCREEN_DIR}/.server.log"
 
   # Only delete ephemeral /tmp directories
diff --git a/skills/superpowers/brainstorming/spec-document-reviewer-prompt.md b/skills/superpowers/brainstorming/spec-document-reviewer-prompt.md
index 212b36c..35acbb6 100644
--- a/skills/superpowers/brainstorming/spec-document-reviewer-prompt.md
+++ b/skills/superpowers/brainstorming/spec-document-reviewer-prompt.md
@@ -19,32 +19,31 @@ Task tool (general-purpose):
     | Category | What to Look For |
     |----------|------------------|
     | Completeness | TODOs, placeholders, "TBD", incomplete sections |
-    | Coverage | Missing error handling, edge cases, integration points |
     | Consistency | Internal contradictions, conflicting requirements |
-    | Clarity | Ambiguous requirements |
-    | YAGNI | Unrequested features, over-engineering |
+    | Clarity | Requirements ambiguous enough to cause someone to build the wrong thing |
     | Scope | Focused enough for a single plan — not covering multiple independent subsystems |
-    | Architecture | Units with clear boundaries, well-defined interfaces, independently understandable and testable |
+    | YAGNI | Unrequested features, over-engineering |
+
+    ## Calibration
 
-    ## CRITICAL
+    **Only flag issues that would cause real problems during implementation planning.**
+    A missing section, a contradiction, or a requirement so ambiguous it could be
+    interpreted two different ways — those are issues. Minor wording improvements,
+    stylistic preferences, and "sections less detailed than others" are not.
 
-    Look especially hard for:
-    - Any TODO markers or placeholder text
-    - Sections saying "to be defined later" or "will spec when X is done"
-    - Sections noticeably less detailed than others
-    - Units that lack clear boundaries or interfaces — can you understand what each unit does without reading its internals?
+    Approve unless there are serious gaps that would lead to a flawed plan.
 
     ## Output Format
 
     ## Spec Review
 
-    **Status:** ✅ Approved | ❌ Issues Found
+    **Status:** Approved | Issues Found
 
     **Issues (if any):**
-    - [Section X]: [specific issue] - [why it matters]
+    - [Section X]: [specific issue] - [why it matters for planning]
 
-    **Recommendations (advisory):**
-    - [suggestions that don't block approval]
+    **Recommendations (advisory, do not block approval):**
+    - [suggestions for improvement]
 ```
 
 **Reviewer returns:** Status, Issues (if any), Recommendations
diff --git a/skills/superpowers/brainstorming/visual-companion.md b/skills/superpowers/brainstorming/visual-companion.md
index a25e85a..537ed3c 100644
--- a/skills/superpowers/brainstorming/visual-companion.md
+++ b/skills/superpowers/brainstorming/visual-companion.md
@@ -48,12 +48,21 @@ Save `screen_dir` from the response. Tell user to open the URL.
 
 **Launching the server by platform:**
 
-**Claude Code:**
+**Claude Code (macOS / Linux):**
 ```bash
 # Default mode works — the script backgrounds the server itself
 scripts/start-server.sh --project-dir /path/to/project
 ```
 
+**Claude Code (Windows):**
+```bash
+# Windows auto-detects and uses foreground mode, which blocks the tool call.
+# Use run_in_background: true on the Bash tool call so the server survives
+# across conversation turns.
+scripts/start-server.sh --project-dir /path/to/project
+```
+When calling this via the Bash tool, set `run_in_background: true`. Then read `$SCREEN_DIR/.server-info` on the next turn to get the URL and port.
+
 **Codex:**
 ```bash
 # Codex reaps background processes. The script auto-detects CODEX_CI and
diff --git a/skills/superpowers/using-superpowers/references/codex-tools.md b/skills/superpowers/using-superpowers/references/codex-tools.md
index eb23075..86f58fa 100644
--- a/skills/superpowers/using-superpowers/references/codex-tools.md
+++ b/skills/superpowers/using-superpowers/references/codex-tools.md
@@ -13,13 +13,13 @@ Skills use Claude Code tool names. When you encounter these in a skill, use your
 | `Read`, `Write`, `Edit` (files) | Use your native file tools |
 | `Bash` (run commands) | Use your native shell tools |
 
-## Subagent dispatch requires collab
+## Subagent dispatch requires multi-agent support
 
 Add to your Codex config (`~/.codex/config.toml`):
 
 ```toml
 [features]
-collab = true
+multi_agent = true
 ```
 
 This enables `spawn_agent`, `wait`, and `close_agent` for skills like `dispatching-parallel-agents` and `subagent-driven-development`.
diff --git a/skills/superpowers/writing-plans/SKILL.md b/skills/superpowers/writing-plans/SKILL.md
index ed67c5e..60f9834 100644
--- a/skills/superpowers/writing-plans/SKILL.md
+++ b/skills/superpowers/writing-plans/SKILL.md
@@ -49,7 +49,7 @@ This structure informs the task decomposition. Each task should produce self-con
 ```markdown
 # [Feature Name] Implementation Plan
 
-> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.
+> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
 
 **Goal:** [One sentence describing what this builds]
 
@@ -112,36 +112,34 @@ git commit -m "feat: add specific feature"
 
 ## Plan Review Loop
 
-After completing each chunk of the plan:
+After writing the complete plan:
 
-1. Dispatch plan-document-reviewer subagent (see plan-document-reviewer-prompt.md) with precisely crafted review context — never your session history. This keeps the reviewer focused on the plan, not your thought process.
-   - Provide: chunk content, path to spec document
-2. If ❌ Issues Found:
-   - Fix the issues in the chunk
-   - Re-dispatch reviewer for that chunk
-   - Repeat until ✅ Approved
-3. If ✅ Approved: proceed to next chunk (or execution handoff if last chunk)
-
-**Chunk boundaries:** Use `## Chunk N: <name>` headings to delimit chunks. Each chunk should be ≤1000 lines and logically self-contained.
+1. Dispatch a single plan-document-reviewer subagent (see plan-document-reviewer-prompt.md) with precisely crafted review context — never your session history. This keeps the reviewer focused on the plan, not your thought process.
+   - Provide: path to the plan document, path to spec document
+2. If ❌ Issues Found: fix the issues, re-dispatch reviewer for the whole plan
+3. If ✅ Approved: proceed to execution handoff
 
 **Review loop guidance:**
 - Same agent that wrote the plan fixes it (preserves context)
-- If loop exceeds 5 iterations, surface to human for guidance
-- Reviewers are advisory - explain disagreements if you believe feedback is incorrect
+- If loop exceeds 3 iterations, surface to human for guidance
+- Reviewers are advisory — explain disagreements if you believe feedback is incorrect
 
 ## Execution Handoff
 
-After saving the plan:
+After saving the plan, offer execution choice:
+
+**"Plan complete and saved to `docs/superpowers/plans/<filename>.md`. Two execution options:**
+
+**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration
 
-**"Plan complete and saved to `docs/superpowers/plans/<filename>.md`. Ready to execute?"**
+**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints
 
-**Execution path depends on harness capabilities:**
+**Which approach?"**
 
-**If harness has subagents (Claude Code, etc.):**
-- **REQUIRED:** Use superpowers:subagent-driven-development
-- Do NOT offer a choice - subagent-driven is the standard approach
+**If Subagent-Driven chosen:**
+- **REQUIRED SUB-SKILL:** Use superpowers:subagent-driven-development
 - Fresh subagent per task + two-stage review
 
-**If harness does NOT have subagents:**
-- Execute plan in current session using superpowers:executing-plans
+**If Inline Execution chosen:**
+- **REQUIRED SUB-SKILL:** Use superpowers:executing-plans
 - Batch execution with checkpoints for review
diff --git a/skills/superpowers/writing-plans/plan-document-reviewer-prompt.md b/skills/superpowers/writing-plans/plan-document-reviewer-prompt.md
index ce36cba..2db2806 100644
--- a/skills/superpowers/writing-plans/plan-document-reviewer-prompt.md
+++ b/skills/superpowers/writing-plans/plan-document-reviewer-prompt.md
@@ -2,17 +2,17 @@
 
 Use this template when dispatching a plan document reviewer subagent.
 
-**Purpose:** Verify the plan chunk is complete, matches the spec, and has proper task decomposition.
+**Purpose:** Verify the plan is complete, matches the spec, and has proper task decomposition.
 
-**Dispatch after:** Each plan chunk is written
+**Dispatch after:** The complete plan is written.
 
 ```
 Task tool (general-purpose):
-  description: "Review plan chunk N"
+  description: "Review plan document"
   prompt: |
-    You are a plan document reviewer. Verify this plan chunk is complete and ready for implementation.
+    You are a plan document reviewer. Verify this plan is complete and ready for implementation.
 
-    **Plan chunk to review:** [PLAN_FILE_PATH] - Chunk N only
+    **Plan to review:** [PLAN_FILE_PATH]
     **Spec for reference:** [SPEC_FILE_PATH]
 
     ## What to Check
@@ -20,33 +20,30 @@ Task tool (general-purpose):
     | Category | What to Look For |
     |----------|------------------|
     | Completeness | TODOs, placeholders, incomplete tasks, missing steps |
-    | Spec Alignment | Chunk covers relevant spec requirements, no scope creep |
-    | Task Decomposition | Tasks atomic, clear boundaries, steps actionable |
-    | File Structure | Files have clear single responsibilities, split by responsibility not layer |
-    | File Size | Would any new or modified file likely grow large enough to be hard to reason about as a whole? |
-    | Task Syntax | Checkbox syntax (`- [ ]`) on steps for tracking |
-    | Chunk Size | Each chunk under 1000 lines |
-
-    ## CRITICAL
-
-    Look especially hard for:
-    - Any TODO markers or placeholder text
-    - Steps that say "similar to X" without actual content
-    - Incomplete task definitions
-    - Missing verification steps or expected outputs
-    - Files planned to hold multiple responsibilities or likely to grow unwieldy
+    | Spec Alignment | Plan covers spec requirements, no major scope creep |
+    | Task Decomposition | Tasks have clear boundaries, steps are actionable |
+    | Buildability | Could an engineer follow this plan without getting stuck? |
+
+    ## Calibration
+
+    **Only flag issues that would cause real problems during implementation.**
+    An implementer building the wrong thing or getting stuck is an issue.
+    Minor wording, stylistic preferences, and "nice to have" suggestions are not.
+
+    Approve unless there are serious gaps — missing requirements from the spec,
+    contradictory steps, placeholder content, or tasks so vague they can't be acted on.
 
     ## Output Format
 
-    ## Plan Review - Chunk N
+    ## Plan Review
 
     **Status:** Approved | Issues Found
 
     **Issues (if any):**
-    - [Task X, Step Y]: [specific issue] - [why it matters]
+    - [Task X, Step Y]: [specific issue] - [why it matters for implementation]
 
-    **Recommendations (advisory):**
-    - [suggestions that don't block approval]
+    **Recommendations (advisory, do not block approval):**
+    - [suggestions for improvement]
 ```
 
 **Reviewer returns:** Status, Issues (if any), Recommendations
