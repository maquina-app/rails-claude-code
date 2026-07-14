# Morphing: how idiomorph works and how to work with it

Turbo wraps and extends the idiomorph library for `refresh` renders configured with the morph method. Morphing computes the minimal set of DOM changes to make the current page match the server-rendered new page. Benefits over replace: less browser redraw, preserved selections and scroll, and DOM node identity is preserved for in-place-morphed nodes (attached JS references keep working).

## When morphing actually runs

Both must be true for a full-page morph:
1. Visit action is `replace` (form submit → redirect). `advance` (link click) and `restore` (history) never morph.
2. The redirect target URL equals the current URL — including the trailing slash.

Debug which method rendered:

```js
addEventListener("turbo:render", (e) => console.log(e.detail.renderMethod))
```

## Algorithm outline

1. **ID map construction.** For old and new content, every element with an `id` contributes its id to a Set on each of its ancestors. The map answers "do these two nodes share any descendant id?" — the primary matching signal. Consequences:
   - Duplicate ids (tolerated by HTML/CSS) actively break matching. Keep ids truly unique.
   - Put ids on meaningful content. `dom_id(record)` on partials materially improves morph quality.
2. **Head merge (full-page only).** Children compared by full `outerHTML`; kept if in both, removed if only in old, added if only in new; order irrelevant. The merge is async: it waits for newly added assets to fire `load` before morphing the body — so a huge new stylesheet delays the visible morph. Unchanged head tags cost nothing, so front-loading shared assets is a reasonable strategy.
3. **Best-match search for the top-level node.** New top-level candidates are scored: +0.5 for matching node type, +1 per shared id (ids ignored on type mismatch). Highest score wins; no match at all → give up and replace wholesale. Mostly relevant for morphing remote frames where the new content is a node list; full-page always matches `<html>`.
4. **Recursive morph.** For the matched pair: sync attributes (only actually-changed attributes are written, so attribute observers don't fire spuriously); then for each new child, find its match in old children — first by shared id, then by soft (type) match with a bail-out heuristic (if two later siblings would have soft-matched the scanned node, skip morphing this one so the two siblings survive). Matched → everything scanned in between is **removed**, then recurse. No match → insert as new. Leftover old children at the end → removed.
5. Content around the best match (node-list case) is inserted afterwards.

## Practical consequences

- **Never rely on a specific element being morphed in place** in non-trivial layouts; one extra sibling can flip which nodes pair up. If preservation matters, add ids.
- Reordered-but-identical lists partially morph, partially remove+re-add.
- Worst case O(N×M) nodes, amortized linear for typical Rails pages. The browser usually does *less* work overall than a replace.
- If a remote-frame morph behaves oddly, sprinkle ids.

## Excluding elements from morphing

- `data-turbo-permanent`: never added, morphed, or removed — but this also survives frame updates, which often breaks error re-rendering of forms.
- Scoped alternative (preferred for "keep my open edit form during refreshes but let the frame update it"):

```js
addEventListener("turbo:before-morph-element", (event) => {
  if (event.target.hasAttribute("data-turbo-prevent-morph")) {
    event.preventDefault()
  }
})
```

Requirements for this to pair correctly: the protected element needs a stable id matching across old/new, and the frame must contain the same single-child structure in both versions (wrap loose siblings into the protected wrapper) so the morpher pairs the wrappers rather than restructuring around them.

- Broadcast + inline-new-form combo: mark the new-form frame `data: { turbo_prevent_morph: true }` so incoming refreshes don't wipe it, and explicitly clear it on your own success path with `turbo_stream.update <frame_id>, ""` before `turbo_stream.refresh request_id: nil`.

## Morphing + turbo-permanent under broadcast refresh

During refresh renders Turbo configures idiomorph so it will not add/morph/remove nodes that are `data-turbo-permanent` (with an id, already present), and it treats morphing remote frames (`refresh="morph"` on a `src` frame) specially — those are reloaded separately after the body morph completes.
