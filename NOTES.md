# Proofline - state (updated Nov 8, 2026, 05:50 IST)

WeMakeDevs "Flip the Switch" hackathon entry. NOT SUBMITTED before the published Nov 7, 11:59 PM IST deadline: the approval-gated save step could not run on free-tier infrastructure in time, and staging it was not acceptable. All three beats have since been verified live; a late submission is under evaluation (late eligibility unconfirmed).

## What works (verified live)
- Room `proofline-proofline` (Switch room id 21b76abd-2413-4a22-b777-34dfc444bb88) mirrored to a Mattermost channel, two agents (`proofline-checker`, `proofline-editor`) on OpenCode, producer role. The room's message history is the evidence/decision record.
- Beat 1 (Nov 7): checker posts an evidence ledger verdicting every claim in `fixtures/clip-caption.md` against `fixtures/transcript.md` with exact line citations (SUPPORTED / CONTRADICTED / UNVERIFIED). Caught all 4 planted errors (fifty->forty years, thousand->~300 loaves, unverified "oldest bakery", missing sponsor line).
- Beat 2 (Nov 7): editor proposes a minimal diff patch for all four fixes and writes nothing before approval (output/ verified empty).
- Beat 3 (Nov 8, 05:40 IST): after the producer's in-room approval (approving three fixes, rejecting one), the editor wrote the corrected `output/clip-caption.md` - verified to contain exactly the approved changes, with the rejected phrase removed and nothing else touched - and posted a decision log in the room recording what was applied vs dropped and who approved it.

## What blocked beat 3 before the deadline (resolved)
- Beat 3 first failed at the model layer on Nov 7:
  1. OpenRouter free tier daily cap exhausted (50/50 requests; `x-ratelimit-remaining: 0`, `limit_source: openrouter_free_tier_daily`, reset 2026-11-08 00:00 UTC).
  2. Fallback to GitHub Models free tier (same-account PAT, user-approved 22:55 IST): the OpenCode provider integration returned empty 0-token completions in an endless retry loop (observed loop step 255 on gpt-4o-mini, 206 on gpt-4.1, no errors logged). Direct curl to https://models.github.ai/inference/chat/completions with the same key and models returned normal content, so the failure is in the OpenCode <-> GitHub Models path, not the key, quota, or models.
- After the 00:00 UTC reset, the same model used for beats 1-2 (`nvidia/nemotron-3-ultra-550b-a55b:free`) completed beat 3 unchanged. No paid usage at any point.

## Reproduce
1. Start the stack: `cd ~/switch-demo && docker compose --profile collab --profile gateway up -d`, start the controller (`switch-agent-controller run --env-file ~/switch-demo/agent.env`), gateway login uses the admin email (not username).
2. `deploy/provision.sh` creates the two agents; create the room with `proofline.template.yaml` minus the top-level `agents:` key via POST /gateway/rooms/from-yaml (inputs: provider=opencode, location=build-box). Bind agents with model `openrouter/nvidia/nemotron-3-ultra-550b-a55b:free`.
3. In the mirrored Mattermost channel: ask `@checker` to check clip-caption.md against transcript.md; then ask `@editor` for a patch; then approve.

## Fixtures
`fixtures/` is synthetic, clearly labeled sample data with deliberate errors. Not real publication material.
