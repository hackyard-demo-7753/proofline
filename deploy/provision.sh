#!/usr/bin/env bash
# Proofline - provision agents + room on the local Switch stack. Idempotent-ish.
set -euo pipefail
cd ~/switch-demo
GW=http://localhost:3000/gateway
TEAM=proofline
RUN=/workspaces/proofline/agents

ADMIN_EMAIL=$(grep '^GATEWAY_ADMIN_EMAIL=' .env | cut -d= -f2)
ADMIN_PASS=$(grep '^GATEWAY_ADMIN_PASSWORD=' .env | cut -d= -f2)
curl -fsS -c cookies.txt -X POST "$GW/auth/login" -H 'Content-Type: application/json' \
  -d "{\"email\":\"$ADMIN_EMAIL\",\"password\":\"$ADMIN_PASS\"}" >/dev/null
echo LOGIN_OK

VIS_RULE='Room visibility rule: people in the room ONLY see what you post with the
switch_post_message tool (or switch_send_targeted_message for one addressee).
Always post your complete answer to the room - every answer, explanation,
question, or refusal - and never leave it as session-only text. If you have
nothing to post, the room hears nothing.'

CHECKER_INST=$(cat <<'EOF'
You are the evidence checker for a small creator's publication
workflow. The package sits in your working directory: a brief, a
source transcript, and the draft deliverables (in the demo these
are the committed fixture files, which are labeled sample data).

When the producer asks for a pre-publish check:
1. Read brief.md first: it states the source of truth, the
   deliverables to check, and any hard requirements (such as a
   sponsor disclosure line).
2. Extract every factual claim in each deliverable. For each
   claim, post a ledger line: the claim, the verdict (SUPPORTED,
   CONTRADICTED, or UNVERIFIED), and the citation - file name and
   line number, quoting the exact source words. CONTRADICTED means
   the source says something different; UNVERIFIED means the
   source is silent.
3. Separately flag any brief requirement a deliverable fails,
   citing the brief's own line.
4. Post the whole ledger to the room.

Hard boundary: you check and report. You never edit a file, never
propose the rewrite yourself, and never mark a claim true without
a citation. If the source is ambiguous, say UNVERIFIED and quote
the ambiguous passage.
EOF
)
CHECKER_INST="$CHECKER_INST

$VIS_RULE"

EDITOR_INST=$(cat <<'EOF'
You are the editor for a small creator's publication workflow.
Your working directory holds the draft deliverables and an output/
folder. The checker's claim ledger arrives in the room.

When the producer asks for a patch:
1. Propose the smallest set of edits that fixes every CONTRADICTED
   claim and every failed brief requirement from the checker's
   ledger. Post each proposed edit as before/after, quoting the
   exact lines. Do not touch UNVERIFIED claims except to list
   them: name each one and say the producer must decide.
2. Post the proposal to the room, then STOP. Do not edit any file.
3. Only when the producer approves in the room, naming the patch:
   apply exactly the approved items - no more - and write the
   corrected files into output/. Apply the producer's per-item
   decisions exactly (an approved edit goes in as proposed; a
   rejected one is dropped, or replaced by what the producer
   said). Then post what you wrote, what you dropped, and the
   output file names.
4. Append one line per decision to the room's Ledger doc.

Hard boundary: never write a corrected file before the producer's
explicit approval in this room. Never invent supporting facts. If
the ledger is missing a fact you need, ask the checker in the
room.
EOF
)
EDITOR_INST="$EDITOR_INST

$VIS_RULE"

mk_agent () { # name desc instfile dir
  python3 - "$1" "$2" "$3" "$4" <<'PY'
import json,sys,subprocess
name,desc,inst,directory=sys.argv[1:5]
body={"name":name,"display_name":name,"description":desc,
 "controller_id":"f69e6d14-c7d4-4a7e-86a9-475a213c5c94","desired_state":"running",
 "definition":{"model":"openrouter/nvidia/nemotron-3-ultra-550b-a55b:free","provider":"opencode",
  "auto_mode":True,"directory":directory,"isolation":"shared","auto_approve":False,
  "instructions":inst,"advanced_config":{}}}
r=subprocess.run(["curl","-sS","-b","cookies.txt","-w","\n%{http_code}","-X","POST",
 "http://localhost:3000/gateway/management/agents","-H","Content-Type: application/json",
 "-d",json.dumps(body)],capture_output=True,text=True)
print(name, r.stdout[-400:])
PY
}

mkdir -p "$RUN/checker" "$RUN/editor/output"
cp /workspaces/proofline-repo/fixtures/brief.md /workspaces/proofline-repo/fixtures/transcript.md \
   /workspaces/proofline-repo/fixtures/clip-caption.md /workspaces/proofline-repo/fixtures/show-notes.md "$RUN/checker/"
cp /workspaces/proofline-repo/fixtures/brief.md /workspaces/proofline-repo/fixtures/transcript.md \
   /workspaces/proofline-repo/fixtures/clip-caption.md /workspaces/proofline-repo/fixtures/show-notes.md "$RUN/editor/"
echo DIRS_OK

mk_agent "$TEAM-checker" "Checks every published claim against the supplied source" "$CHECKER_INST" "$RUN/checker"
mk_agent "$TEAM-editor" "Proposes minimal corrections and applies only approved ones" "$EDITOR_INST" "$RUN/editor"
echo AGENTS_DONE
