# Proofline - state at close (Nov 7, 2026, 23:59 IST deadline passed without submission)

WeMakeDevs "Flip the Switch" hackathon entry. NOT SUBMITTED: the approval-gated save step could not be made to run on free-tier infrastructure before the deadline, and staging it was not acceptable.

## What works (verified live, Nov 7)
- Room `proofline-proofline` (Switch room id 21b76abd-2413-4a22-b777-34dfc444bb88) mirrored to a Mattermost channel, two agents (`proofline-checker`, `proofline-editor`) on OpenCode, Ledger doc, producer role.
- Beat 1: checker posts an evidence ledger verdicting every claim in `fixtures/clip-caption.md` against `fixtures/transcript.md` with exact line citations (SUPPORTED / CONTRADICTED / UNVERIFIED). Caught all 4 planted errors (fifty->forty years, thousand->~300 loaves, unverified "oldest bakery", missing sponsor line).
- Beat 2: editor proposes a minimal diff patch for all four fixes and writes nothing before approval (output/ verified empty).

## What failed (the reason there is no entry)
- Beat 3: after producer approval, the editor must write `output/clip-caption.md` and append to the Ledger. This never completed:
  1. OpenRouter free tier daily cap exhausted (50/50 requests; `x-ratelimit-remaining: 0`, `limit_source: openrouter_free_tier_daily`, reset 2026-11-08 00:00 UTC).
  2. Fallback to GitHub Models free tier (same-account PAT, user-approved 22:55 IST): the OpenCode provider integration returned empty 0-token completions in an endless retry loop (observed loop step 255 on gpt-4o-mini, 206 on gpt-4.1, no errors logged). Direct curl to https://models.github.ai/inference/chat/completions with the same key and models returned normal content, so the failure is in the OpenCode <-> GitHub Models path, not the key, quota, or models.

## Reproduce
1. Start the stack: `cd ~/switch-demo && docker compose up -d`, start controller via `/tmp/start-ctrl.sh` (see application-desk/deploy/RUNBOOK.md for gateway auth and agent binding shapes).
2. `deploy/provision.sh` creates the two agents; create the room with `proofline.template.yaml` minus the top-level `agents:` key via POST /gateway/rooms/from-yaml (inputs: provider=opencode, location=build-box).
3. In the mirrored Mattermost channel: ask `@checker` to check clip-caption.md against transcript.md; then ask `@editor` for a patch; then approve.

## Fixtures
`fixtures/` is synthetic, clearly labeled sample data with deliberate errors. Not real publication material.
