/**
 * Shared hook helper: POST a telemetry envelope to the backend.
 *
 * Extracted per req-002 / 0000028-ADR-002 from the 3 copies of the
 * fetch/AbortController block in context-pressure.mjs, emit-phase-start.mjs
 * and emit-phase-end.mjs.
 *
 * Only the post-event mechanics are shared. Each hook still builds its own
 * event object locally, because the `context_pressure`, `phase_start` and
 * `phase_end` payloads genuinely differ.
 *
 * Bounded network-level retry (req-001, 0000028-ADR-001): a network-level
 * fetch failure (a rejected promise, e.g. a TypeError from ECONNREFUSED) is
 * frequently the signature of a listener gap during a routine backend
 * restart rather than a real failure, so it is retried up to 2 times (3
 * attempts total) with fixed 300ms gaps between attempts. An HTTP error
 * status is a real failure (a listener answered and rejected the event) and
 * is never retried, at any attempt. The hooks already set a synthetic
 * `err.name` of `http_<status>` on a non-ok response, so
 * `!err.name.startsWith("http_")` is the sole retry trigger. Each attempt
 * gets its own AbortController and its own 3s abort timer, so the retry
 * budget adds at most 600ms worst case on top of the existing per-attempt
 * abort. Landing here once, since it lives in the shared module, gives all
 * three callers the retry for free.
 *
 * PLACEMENT: hooks/telemetry/. All 3 callers are telemetry hooks, and
 * setup.sh's Tier 1 telemetry glob was widened to *.mjs (req-002) so Tier 1
 * installs receive this file alongside them.
 */

const ABORT_MS = 3_000;
const RETRY_DELAYS_MS = [300, 300]; // up to 2 retries (3 attempts total)

/**
 * Throws on transport failure (after retries are exhausted) or on a non-ok
 * HTTP status (never retried). The caller's top-level try/catch is what
 * keeps the hook exiting 0 (NFR-001, ADR-005).
 */
export async function postEvent(backendUrl, event) {
  for (let attempt = 0; ; attempt++) {
    const ac = new AbortController();
    const timer = setTimeout(() => ac.abort(), ABORT_MS);
    try {
      const res = await fetch(`${backendUrl}/emit`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(event),
        signal: ac.signal,
      });
      if (!res.ok) {
        const httpErr = new Error(`emission POST failed: HTTP ${res.status}`);
        httpErr.name = `http_${res.status}`;
        throw httpErr;
      }
      return;
    } catch (err) {
      // Only retry a network-level failure. An HTTP error status (the
      // synthetic http_<status> name set above) answered from a real
      // listener and is never a listener-gap symptom, so it is not retried.
      const isNetworkFailure = !(err?.name ?? "").startsWith("http_");
      if (!isNetworkFailure || attempt >= RETRY_DELAYS_MS.length) throw err;
    } finally {
      clearTimeout(timer);
    }
    await new Promise((r) => setTimeout(r, RETRY_DELAYS_MS[attempt]));
  }
}
