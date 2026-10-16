---
name: remember
description: Manages workspaces and memories in the Recuerd0 platform via the recuerd0 CLI. Use PROACTIVELY after architectural decisions, debugging sessions that resolved an issue, when the user states a strong preference, when a non-obvious discovery is made, or at the natural end of a focused working session. Also handles explicit save, search, version, and organize requests.
---

# Recuerd0 Memory

Preserve, version, and organize knowledge from AI conversations using the Recuerd0 CLI (`recuerd0`). Run commands via Bash and interpret the structured JSON output to manage the user's workspaces and memories. The full command catalog, flags, and output format live in `references/cli-reference.md` — read it for exact syntax.

Operate **proactively**: watch the conversation for capture-worthy moments and act on them without waiting to be asked. Operate **with discipline**: write no duplicate memory, always route to the right workspace, and announce every save in one line so the user knows it happened.

**All memory content MUST be Markdown.** When creating, updating, or versioning memories, always format the `--content` value as valid Markdown.

---

## When to Capture

Before capturing anything, apply this gate. It is the single rule that decides whether a candidate earns a memory:

**Only persist a discovery if it would not be obvious from reading the code, contradicts a sane default, or cost real time to find; before creating, search for an existing memory on the topic and version it instead.**

Operationally:

- **Not obvious from the code** — if a competent developer reading the source would arrive at the same conclusion in under a minute, do not persist it. Memories are for what the code *doesn't* tell you: the reason behind a choice, the gotcha that wasted an hour, the constraint that isn't written down.
- **Contradicts a sane default** — capture the surprises. "We deviate from the framework default here, because X" is worth a memory. "We follow the framework default" is not.
- **Cost real time to find** — if it was a fast lookup, it'll be a fast lookup next time. If it took debugging, bisecting, or reading three files to understand, persist it so it never costs that again.
- **Version, don't duplicate** — running the search step (Dedup-Before-Write Protocol) *before* every write is mandatory, not optional. The default action on a topic match is `memory version create`, not `memory create`.

If a candidate fails all three tests, skip it silently — do not announce a non-save.

Capture proactively when any of these signals appear in the conversation:

- **A decision was made** — architecture choice, library choice, tradeoff with stated reasoning ("we picked Postgres because…")
- **A non-obvious bug was diagnosed** — root cause is now understood, not just symptoms
- **The user stated a strong preference** — "I always want X", "never do Y", "from now on…"
- **A breakthrough discovery** — a pattern, library quirk, workaround, or gotcha worth remembering
- **End of a focused session** — natural stopping point on a specific topic, before context shifts

**Do NOT capture** when:

- The conversation is exploratory or chitchat
- Work is in progress — wait until the decision/fix actually lands
- The information is already in the project's `CLAUDE.md` or `AGENTS.md`
- The workspace already contains it (the dedup protocol below catches this)
- The user explicitly says not to remember something

When in doubt, capture. A duplicate prevented by dedup is cheap; a lost decision is expensive.

---

## Workspace Routing

Always resolve the target workspace **before** asking the user. Follow this decision tree:

1. **Identify the project** — run `pwd` and `git config --get remote.origin.url`. The current working directory and git remote are the strongest signals.
2. **Check project-local config** — the CLI walks parent directories looking for `.recuerd0.yaml`. If you can run any `recuerd0` command without `--workspace` and it succeeds, the resolution worked.
3. **Match by name** — run `recuerd0 workspace list --pretty` and look for a workspace whose name matches the project directory or repo name.
4. **Single clear match** — use it without asking. Mention it in your one-line save notice so the user can correct if wrong.
5. **Multiple plausible matches** — pick the closest and confirm in one line ("Saving to workspace 'rails-patterns' (3 candidates) — say so if wrong").
6. **No match at all** — create a new workspace with a name derived from the project: `recuerd0 workspace create --name "<project-name>" --description "<inferred from README or git remote>"`. You may create without asking. Mention it in the save notice.
7. **Never silently dump** into a generic default workspace. Every save must land somewhere semantically correct.

---

## Dedup-Before-Write Protocol

Before any `memory create`, you MUST:

1. **Load the workspace context** — `recuerd0 workspace context <id> --pretty`. This returns the workspace metadata plus the user's pinned memories filtered to this workspace, in one call. Pinned memories are the most likely candidates for an update vs. a duplicate.
2. **Search for related memories (multi-query).** A single search query finds a memory only when its wording overlaps the recorded wording. Concepts recorded as "boot" won't surface for a query about "startup"; "broadcast" won't surface for "realtime updates". To avoid creating a duplicate of a memory you simply failed to find, search with **several phrasings**, not one.

   Generate **3–5 query variants** for the new content, then run a search for each and union the results before deciding create vs. version vs. update. Construct the variants to span vocabulary, not just restate the title:

   - **One variant from the recorded jargon** — the exact technical terms the memory likely uses (`broadcast_refresh_to`, `Zeitwerk`, `script_name`).
   - **One variant from intent** — how a developer who *doesn't* know the jargon would ask ("send updates to one user only", "autoload fails at boot", "url prefix per account").
   - **One variant swapping synonyms on the key noun/verb** — boot↔startup↔initialization, broadcast↔stream↔push↔realtime, middleware↔rack, locale↔language↔i18n.
   - Optionally one **tag-scoped or category-scoped** pass if the topic maps to a known tag.

   Run each variant intra-workspace, and run at least one variant across all workspaces (no `--workspace`) for the cross-workspace link check:

   ```bash
   recuerd0 search "broadcast_refresh_to per user" --workspace <id> --pretty
   recuerd0 search "send turbo updates to one user" --workspace <id> --pretty
   recuerd0 search "scope realtime stream single account" --workspace <id> --pretty
   recuerd0 search "broadcast_refresh_to per user" --pretty   # cross-workspace
   ```

   Union the hits by memory id (a memory found by any variant counts as found). Then proceed to the decision in step 4 against the unioned candidate set.

   **FTS5 operator hygiene — do not let query words become operators:**

   - `and`, `or`, `not` are FTS5 operators. Never include them as plain search words. "graphics not rendering" is parsed as `graphics NOT rendering` and will silently exclude matches. Drop them or quote the phrase.
   - Quote multi-word phrases that must match as a unit: `'"access request"'`.
   - Keep each variant to 2–4 distinctive terms. Long natural-language sentences fail because every token must match.

   **Retired memories are hidden from these searches.** `search` excludes anything tagged `obsolete`, `superseded`, or `deprecated` by default and reports the count it withheld as `(N obsolete hidden)` in the summary. A non-zero count on a variant means the topic *does* exist in the workspace and was deliberately retired — re-run that variant with `--include obsolete` and read what you find before writing. Creating a fresh memory on a topic someone retired last month is a duplicate the dedup search was built to prevent, and it is the one case where zero visible results is not the same as "nothing here."

   **Stop condition.** If two or more variants return zero results and one returns a weak/unrelated hit, treat the topic as **not found** and create — but log in your reasoning that recall was thin, so a later audit can catch a possible twin. If any variant returns a strong same-topic match, default to `memory version create`.
3. **Search across workspaces** — also run `recuerd0 search "<key terms>" --pretty` *without* `--workspace` to find related memories in other workspaces in the same account. If a strong cross-workspace match exists, after you've created or versioned the new memory, ask the user in one line: `Link this to memory <id> '<title>' in workspace <name>? (y/n)`. On yes, run `recuerd0 memory link add <new_id> --to <other_id>`. On anything else, skip the link. Never link silently.
4. **Decide** based on what you find. **Normalize the id first:** one memory has two ids. `memory list` returns its head (version) id and `search` returns its stable base (root) id. `memory show` resolves either, so check `data.id` before `version create`, `update`, `delete` or `link add`. When citing a memory in docs or a CLAUDE.md, use the root id, since a version id pins to that version's text forever.
   - **Strong match** (same topic, same scope, just evolved): use `recuerd0 memory version create --workspace <id> <memory_id> --title "<current title>" --tags "<current tags>" --source "<source>" --category <category> --content -` to add a new version. Pass all four metadata flags every time, copied from the current head (or changed on purpose): a version created without `--title` takes the **base row's** title, silently undoing every rename since, and tags, source and category get the same treatment. **Default to versioning** — recuerd0's whole versioning model exists for this. Preserve history.
   - **Wrong match** (the existing memory is incorrect, not just outdated): use `recuerd0 memory update --workspace <id> <memory_id>` to overwrite.
   - **Reversed** (the memory was right, and the thing it describes no longer exists or was decided against): retire it with an obsolete tag rather than overwriting it — see **Retiring Memories**. The old rationale stays readable; it just stops surfacing.
   - **No match**: only then call `recuerd0 memory create`.

   If a candidate "duplicate" memory is large, use `recuerd0 memory read grep <id> "<key term>"` to confirm the fact already exists before loading the full body — this is much cheaper than `memory show` for long memories.
5. **Pick a category** from the four values in the Categories section above (`decision`, `discovery`, `preference`, `general`). Pass it via `--category` on create or version create.

### Examples

**Versioning an evolving decision:**

```bash
recuerd0 workspace context 1 --pretty
recuerd0 search "auth strategy" --workspace 1 --pretty
# Finds memory 42: "Auth strategy" — outdated
recuerd0 memory version create --workspace 1 42 \
  --title "Auth strategy" \
  --tags "auth,api,cli" \
  --source "claude-code-session" \
  --category decision \
  --content - <<'EOF'
# Auth strategy v2

We migrated from session-only to session + bearer-token API auth.
Reason: needed programmatic API access for the CLI.
EOF
```

**Fresh capture after dedup miss:**

```bash
recuerd0 workspace context 1 --pretty
recuerd0 search "fts5 tokenizer" --workspace 1 --pretty
# No matches
recuerd0 memory create --workspace 1 \
  --title "FTS5 trigram tokenizer for substring search" \
  --tags "sqlite,fts5,search" \
  --source "claude-code-session" \
  --category discovery \
  --content - <<'EOF'
# FTS5 trigram tokenizer

Substring matching in FTS5 requires the trigram tokenizer…
EOF
```

**Cross-workspace dedup hit with confirmed link:**

Working in the `mobile-app` workspace (id 3), capturing a decision about how the mobile client refreshes OAuth tokens. The intra-workspace search finds nothing, but the cross-workspace search surfaces a clearly related memory in `rails-app`.

```bash
recuerd0 workspace context 3 --pretty
recuerd0 search "oauth refresh token" --workspace 3 --pretty
# No matches in workspace 3
recuerd0 search "oauth refresh token" --pretty
# Strong match: memory 42 "Auth strategy" in workspace rails-app (id 1)
recuerd0 memory create --workspace 3 \
  --title "OAuth refresh on the mobile client" \
  --tags "oauth,mobile,auth" \
  --source "claude-code-session" \
  --category decision \
  --content - <<'EOF'
# OAuth refresh on the mobile client

The mobile client refreshes its OAuth access token in the background…
EOF
# Server returns the new memory id: 118
```

Then ask the user in one line:

```
Link this to memory 42 "Auth strategy" in workspace rails-app? (y/n)
```

On `y`:

```bash
recuerd0 memory link add 118 --to 42
```

Final save notice:

```
✓ Saved to workspace mobile-app (id 3) as "OAuth refresh on the mobile client" [decision] (id 118) [created]
  → linked to "Auth strategy" in workspace rails-app (id 42)
```

---

## Categories

Every memory carries a `category`, picked from a locked four-value enum. The server defaults new memories to `general` when no category is sent, but you should always pass `--category` explicitly on every `memory create` and `memory version create` so the choice is deliberate.

| Value | Label | When to pick it |
|---|---|---|
| `decision` | Decision | Architecture choices, library picks, tradeoffs with stated reasoning |
| `discovery` | Discovery | Non-obvious findings — gotchas, root causes, patterns, library quirks |
| `preference` | Preference | User-stated rules ("always X", "never Y") |
| `general` | General | Catch-all and default |

**Picking heuristic**: if torn between two, prefer the more specific one — `discovery` over `general`, `decision` over `discovery`. `general` is a fallback, not a default.

**Versions take their metadata from the base row, not the current head.** A `memory version create` without `--title` reuses the base (v1) row's title, so a memory renamed in a later version silently reverts. Pass `--title`, `--tags`, `--source` and `--category` explicitly on every version, copied from the current head unless you mean to change them.

---

## Retiring Memories

Three tags are reserved: `obsolete`, `superseded`, and `deprecated`. Adding any of them to a memory's **current version** drops it out of `search`, `memory list`, and `workspace context` — everywhere retrieval looks for what is true now. Nothing is deleted and the version history stays intact.

This is the tool for knowledge that was *correct and no longer applies*. Distinguish it from the two neighbouring cases:

| Situation | Action |
|---|---|
| The knowledge evolved — same topic, new detail | `memory version create` (the default) |
| The memory was **wrong** when written | `memory update` — correct it in place |
| The memory was **right**, and the thing is gone or reversed | Retire it: version it with an obsolete tag |
| The memory should never have existed | `memory delete` — rare; prefer retiring |

**Retire by versioning, not by updating.** Add the tag through `memory version create` so the retirement is itself a dated entry in the history, and say *what replaced it* in the body:

```bash
recuerd0 memory version create --workspace 1 42 \
  --category decision \
  --tags "auth,rails,superseded" \
  --content - <<'EOF'
# Auth strategy: Devise

**Superseded 2026-09-09** by "Auth strategy: Clave passwordless" (memory 87).

Retained for the rationale below — why Devise was chosen originally, and what
made us reverse it.

<original body>
EOF
```

**Keep the topic tags.** Retiring is additive: keep `auth`, `rails`, and friends so the memory is still findable by an audit that passes `--include obsolete`. Stripping them down to just `superseded` makes it unfindable by any route except its id.

**Point forward.** A retired memory that doesn't name its replacement is a dead end. Lead the body with the supersession line and the new memory's id.

**When to retire proactively.** Same discipline as capture — act without being asked when the conversation makes it unambiguous:

- A decision was explicitly reversed ("we're dropping Sidekiq, moving to Solid Queue")
- The subject was removed from the codebase (the gem is gone, the endpoint is deleted)
- A dedup search surfaced an old memory that flatly contradicts what the session just established — retire the old one *and* create the new one, in that order

Do **not** retire when the memory is merely old, when it still describes something true in a narrower scope, or when you are only guessing that it was replaced. Ask in one line if unsure.

**Auditing.** To see what has been retired in a workspace:

```bash
recuerd0 memory list --workspace 1 --include obsolete --pretty
recuerd0 search "auth" --include obsolete --pretty
```

`memory show` and `memory read` are never filtered — a retired memory is always fetchable by id, so you can read one without any flag.

---

## Memory Links

Memory links — sometimes called *tunnels* — are undirected, unlabeled "see also" connections between two memories within the same account. Unlike tags or workspaces, links cross workspace boundaries: an "auth strategy" memory in the `rails-app` workspace can be linked to "auth strategy" in the `mobile-app` workspace, letting you express that memories in two different projects cover related territory.

**Key constraints:**

- **Same account only** — both memories must belong to the current account. Cross-account links are rejected by the server.
- **Undirected** — linking A↔B once is enough. You do not need (and cannot create) a reverse link. The server dedupes A→B and B→A.
- **No labels, no metadata** — a link is just a connection. There is no relationship type, no description, no weight.
- **No self-links** — a memory cannot link to itself.
- **Both endpoints must exist** at link time.
- **No automatic linking** — create a link only after explicit user confirmation.

**Commands:**

```bash
recuerd0 memory link list <memory_id> [--workspace ID]                    # List all links for a memory
recuerd0 memory link add <memory_id> --to <other_memory_id> [--workspace ID]    # Create a link
recuerd0 memory link remove <memory_id> --to <other_memory_id> [--workspace ID] # Remove a link
```

The `--workspace` flag refers to the *source* memory's workspace; the target memory may live in any workspace within the same account. The memory show JSON and the workspace context JSON include a `links_count` field, but **don't rely on it**: it has read `0` on memories that demonstrably have links, including version rows whose base row carries them. Check connectivity with `memory link list`. Links carry no label, so write the *reason* for a link into the memory body as a `[[id]]` reference.

**Confirm before linking — always.** Your job is to *suggest* a link when a strong cross-workspace match surfaces during dedup. Ask the user in one line and wait for a one-word approval. Create a link only with that approval. A noisy link graph is worse than no graph.

### When to link

Link when:

- The new memory closely echoes a memory in another workspace — same topic, different project (e.g. "JWT refresh strategy" exists in both the API and mobile workspaces).
- The user explicitly says "this is like that other thing in workspace X" or otherwise points at a cross-workspace relationship.
- The cross-workspace dedup search surfaces a strong match — same or near-identical title, clearly the same subject, just scoped to a different project.

DO NOT link when:

- The connection is weak or speculative ("both about Rails" is too broad — that describes hundreds of memories).
- The other memory lives in an archived workspace.
- The two memories are already linked (check `recuerd0 memory link list` first if unsure).
- The user has not confirmed. No confirmation, no link.

The default is **not** to link. Linking is the exception, reserved for genuine cross-project topic matches that a user would actually want to traverse.

---

## Save Notice Convention

Every successful capture must produce **one line** of user-facing output, in this format:

```
✓ Saved to workspace <name> (id <ws_id>) as "<title>" [<category>] (id <mem_id>) [<action>]
  → linked to "<other_title>" in workspace <other_name> (id <other_id>)
```

Where `<action>` is one of: `created`, `versioned`, `updated`, `retired`. The second indented line is emitted **only when a link was actually created in this capture**. If no link was created, omit the link line entirely — do not say "no links". Examples:

```
✓ Saved to workspace rails-patterns (id 1) as "FTS5 trigram tokenizer for substring search" [discovery] (id 87) [created]

✓ Saved to workspace mobile-app (id 3) as "OAuth refresh on the mobile client" [decision] (id 118) [created]
  → linked to "Auth strategy" in workspace rails-app (id 42)

✓ Saved to workspace rails-patterns (id 1) as "Auth strategy" [decision] (id 42) [versioned]
```

A retirement is announced the same way, and when it accompanies a replacement, announce both — the new memory first, then what it retired:

```
✓ Saved to workspace rails-patterns (id 1) as "Auth strategy: Clave passwordless" [decision] (id 87) [created]
  → retired "Auth strategy: Devise" (id 42) as superseded
```

Do not narrate the dedup process, the search results, or the workspace resolution unless something went wrong or the user asked. The one-liner is enough.

---

## CLI Reference

The command catalog, output format, global flags, breadcrumbs, exit codes, and usage patterns live in `references/cli-reference.md`. Every command emits structured JSON — check `success`, read `data`, follow the suggested `breadcrumbs`, and pass `--pretty` when showing output to the user.

---

## Save Session as Memory

When the user explicitly asks to "save this session", or when you reach the end of a focused working session and detect capture-worthy content (see When to Capture), produce a curated memory.

### Steps

1. **Resolve the workspace** following the Workspace Routing decision tree above.
2. **Run the dedup protocol** above. Decide whether you're creating, versioning, or updating.
3. **Generate a transcript** in **Markdown** from the current conversation context. All memory content MUST be Markdown. Use this structure:

```markdown
# <Conclusion-first title>

## Goal
What the user set out to accomplish.

## Summary
2-3 paragraph overview of what happened, decisions made, and outcomes.

## Key Changes
- Bullet list of files created, modified, or deleted with brief descriptions

## Decisions & Rationale
- Important choices made and why

## Learnings
- Patterns, gotchas, or insights worth preserving
```

4. **Format guardrails**:
   - **Title**: declarative, scoped, ≤80 chars. Lead with the conclusion ("FTS5 errors surface as ActiveRecord::StatementInvalid"), not the topic ("FTS5 stuff").
   - **Tags**: 3–6, lowercase, hyphenated. Aim for one domain tag (`auth`, `deploy`), one tech tag (`rails`, `sqlite`), one type tag (`decision`, `pattern`, `bugfix`). **Never use `obsolete`, `superseded`, or `deprecated` as topic tags** — they are reserved, and any one of them hides the memory from retrieval the moment it is saved (see **Retiring Memories**). A memory *about* deprecation gets `deprecation`, not `deprecated`.
   - **Source**: `claude-code-session` for proactive captures, `manual` for explicit user requests, `<project>-decision` for architecture-decision memories.
   - **Category**: required. Pick from `decision`, `discovery`, `preference`, `general`. Lean toward the more specific choice — `general` is a fallback, not a default.

5. **Save via the CLI** by piping the transcript through stdin:

```bash
cat <<'TRANSCRIPT' | recuerd0 memory create --workspace <id> --title "<title>" --tags "tag1,tag2,tag3" --source "claude-code-session" --category decision --content -
<transcript content>
TRANSCRIPT
```

6. **Emit the one-line save notice** described in the Save Notice Convention section. No narration of the dedup or routing steps unless something went wrong.

**Important:** Do NOT depend on `/transcript` or any external skill. Generate the transcript yourself from the conversation context you have access to.

---

## Import Context Files as Memories

When the user asks to "import my CLAUDE.md", "scan for context files", "import project context", or similar — find context files in the project (CLAUDE.md, AGENTS.md, .cursorrules, .windsurfrules, etc.), split them into logical sections, check for duplicates, confirm with the user, and create memories.

Tag each memory with `--source "import:<filename>"` for later identification.

See [references/import-context.md](references/import-context.md) for the full workflow, supported files list, splitting guidelines, and re-import logic.

---

## Memory Templates

When the user asks to "document this feature", "analyze the auth system", "create a memory for the API", or similar — read the relevant source code, select an appropriate template (Feature Guide, Architecture Decision, API Reference, Coding Conventions, Debugging, or Onboarding), draft the memory, check for duplicates, and save with `--source "analysis:feature-name"`.

See [references/memory-templates.md](references/memory-templates.md) for the workflow, template selection table, and structure guidance for each template type.

---

## The Core Loop

Each capture follows the same sequence — the detail for every step is in the section named:

1. **Notice** a capture-worthy moment (**When to Capture**) — proactively, without being asked.
2. **Route** to the right workspace (**Workspace Routing**).
3. **Dedup** before writing (**Dedup-Before-Write Protocol**) — default to `version create` on a strong match; check any `(N obsolete hidden)` count before treating a topic as new; search across workspaces and confirm before any link (**Memory Links**).
4. **Categorize** the save (**Categories**) — always pass `--category`.
5. **Retire** anything the save reverses (**Retiring Memories**) — tag the old memory's current version, never delete it.
6. **Announce** in one line (**Save Notice Convention**) — no narration unless something went wrong.

CLI mechanics — JSON parsing, pagination, stdin piping, error handling, reading large memories in windows — are in `references/cli-reference.md`.
