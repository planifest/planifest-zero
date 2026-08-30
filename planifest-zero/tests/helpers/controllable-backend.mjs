#!/usr/bin/env node
/**
 * Controllable HTTP backend for telemetry retry tests (0000028, req-001).
 *
 * Usage: node controllable-backend.mjs <port> <mode> [param]
 *   mode "never"   : never binds a listener. The process just stays alive
 *                     until the test kills it, so a connecting hook always
 *                     sees a network-level failure (ECONNREFUSED).
 *   mode "delayed" : binds <param> ms after this process starts, then
 *                     answers every POST /emit with HTTP 200. Simulates a
 *                     backend daemon whose listener appears mid-restart.
 *   mode "status"  : binds immediately and answers every POST /emit with the
 *                     HTTP status code <param> (default 500).
 *
 * If the REQUEST_LOG env var is set, one line is appended to that file for
 * every request that actually reaches a bound listener, so the test can
 * assert exactly how many attempts were delivered (as opposed to inferring
 * attempt count from elapsed time alone).
 */

import { createServer } from "node:http";
import { appendFileSync } from "node:fs";

const [, , portArg, mode, param] = process.argv;
const port = Number(portArg);
const logPath = process.env.REQUEST_LOG;

function logRequest() {
  if (logPath) appendFileSync(logPath, "1\n");
}

function makeServer(statusCode) {
  return createServer((req, res) => {
    logRequest();
    let body = "";
    req.on("data", (c) => {
      body += c;
    });
    req.on("end", () => {
      res.writeHead(statusCode, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ ok: statusCode < 400, received: body.length }));
    });
  });
}

if (mode === "never") {
  // No server at all. Stay alive so the test harness has a pid to kill.
  setInterval(() => {}, 1_000_000);
} else if (mode === "delayed") {
  const delayMs = Number(param ?? 0);
  const server = makeServer(200);
  setTimeout(() => server.listen(port), delayMs);
} else if (mode === "status") {
  const statusCode = Number(param ?? 500);
  const server = makeServer(statusCode);
  server.listen(port);
} else {
  console.error(`controllable-backend.mjs: unknown mode "${mode}"`);
  process.exit(1);
}
