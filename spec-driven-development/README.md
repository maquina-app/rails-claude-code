# Spec-Driven Development Skill

A structured workflow for building production-quality features with AI agents. Transform rough ideas into implemented features through systematic planning, documentation, and execution.

## What This Skill Does

This skill guides Claude through a proven development workflow inspired by [Agent OS](https://github.com/buildermethods/agent-os). Instead of jumping straight into code, it helps you:

1. **Plan your product** — Define mission, roadmap, and tech stack (once per project)
2. **Shape the spec** — Gather requirements, search the codebase for reusable code, and inject the standards that apply to the feature
3. **Break down tasks** — Generate ordered task groups (Database → Backend → Frontend → Integration), each with a self-contained Claude Code prompt
4. **Implement systematically** — Hand the spec folder to Claude Code and work through the groups

**The result:** A well-documented feature built to spec — a self-contained spec folder (`spec.md`, `references.md`, `standards.md`, `tasks.md`) that Claude Code can pick up and execute with zero extra context, not just code thrown together.

---

## Before You Start

### Prerequisites

- Claude Desktop, Claude Code, or Claude.ai with computer use
- A project directory where you want to build
- Basic understanding of your tech stack

### What to Prepare

1. **Product Vision** (for new projects)
   - What is your product/app?
   - Who are the target users?
   - What problems does it solve?
   - What are the key features?

2. **Feature Idea** (for each feature)
   - What do you want to build?
   - Any mockups or wireframes? (optional but helpful)
   - Similar features in your codebase to reference?

3. **Tech Stack Knowledge**
   - Frontend framework (React, Vue, Rails views, etc.)
   - Backend framework (Rails, Node, Django, etc.)
   - Database (PostgreSQL, MySQL, etc.)
   - Any key libraries or patterns you use

### Installation

This is a Claude Code plugin distributed through the `maquina` marketplace. Install it from the marketplace, then bootstrap each project:

```bash
# In Claude Code
/plugin install spec-driven-development@maquina

# Then, once per Rails project, bootstrap the sdd/ directory:
/sdd-init
```

`/sdd-init` creates the `sdd/` structure with pre-built Rails standards and a progress tracker. The slash commands are provided by the plugin — no per-project setup beyond `/sdd-init`.

---

## How to Use

### Quick Start

```
You: "Initialize spec-driven development for my project"   (or /sdd-init)

Claude: [Creates sdd/ structure with Rails standards, index.yml, and progress.yml]

You: "Let's plan the product"   (or /sdd-plan)

Claude: [Asks about your product, creates mission.md, roadmap.md, tech-stack.md]

You: "Shape a spec for user authentication"   (or /sdd-shape)

Claude: [Creates the dated spec folder, asks focused questions, searches the
         codebase for reusable code, injects the relevant standards, and writes
         spec.md + references.md + standards.md]

You: "Create the task breakdown"   (or /sdd-tasks)

Claude: [Writes tasks.md — ordered task groups, each a self-contained Claude
         Code prompt]

You: "Implement the feature"

Claude: [Hand the spec folder to Claude Code; it works through the groups,
         runs tests, and marks tasks complete]
```

### Available Commands

| Command | What It Does |
|---------|--------------|
| `/sdd-init` | Bootstrap sdd/ with Rails standards + index.yml + progress tracker |
| `/sdd-plan` | Create/update product mission, roadmap, tech stack |
| `/sdd-shape` | Shape a spec: questions → codebase search → inject standards → write spec.md + references.md + standards.md |
| `/sdd-tasks` | Create task groups with self-contained Claude Code prompts |
| `/sdd-status` | Show progress and the next suggested action |
| `/sdd-discover-standards` | Extract tribal knowledge from an existing codebase into new standards |

### Natural Language Works Too

You don't have to use commands. Just describe what you want:

- "Help me plan out my todo app"
- "I want to add a comments feature"
- "What's the status of my current spec?"
- "Create tasks for the authentication spec"
- "Shape a spec for the notifications feature"

---

## What You'll Get

### Directory Structure

After using the skill, your project will have:

```
your-project/
└── sdd/
    ├── progress.yml                    # Tracks workflow state
    ├── product/
    │   ├── mission.md                  # Product vision & strategy
    │   ├── roadmap.md                  # Prioritized feature list
    │   └── tech-stack.md               # Technology choices
    ├── standards/                      # Your coding standards
    │   ├── index.yml                   # Catalog of all standards
    │   ├── global/
    │   ├── backend/
    │   ├── frontend/
    │   └── testing/
    └── specs/
        └── 2024-12-22-user-auth/       # One folder per feature
            ├── spec.md                 # Requirements, user stories, scope
            ├── references.md           # Existing code to reuse/follow
            ├── standards.md            # Standards injected for THIS feature
            └── tasks.md                # Task groups + self-contained prompts
```

Each spec folder is **self-contained**: `standards.md` holds the full text of every standard that applies to the feature, so a Claude Code agent can implement it with zero dependencies outside the folder.

### Sample Outputs

**mission.md** — Your product vision:
```markdown
# Product Mission

## Pitch
TaskFlow is a project management tool that helps small teams track work
by providing simple, visual task boards without enterprise complexity.

## Users
- Small team leads (5-15 people)
- Freelancers managing multiple clients
...
```

**spec.md** — Formal specification:
```markdown
# Specification: User Authentication

## Goal
Allow users to create accounts and securely log in to access their data.

## User Stories
- As a visitor, I want to create an account so I can save my work
- As a user, I want to log in so I can access my data from any device
...
```

**tasks.md** — Actionable task breakdown:
```markdown
# Tasks: User Authentication

## Group 1: Database
- [ ] Write 2–5 focused tests for the User model
- [ ] Create the users migration
- [ ] Create the User model with validations and associations
...
```

Task groups follow a fixed order: **Database → Backend → Frontend → Integration**.

---

## Tips for Best Results

### 1. Don't Skip the Planning Phase

It's tempting to jump straight to "build me X," but spending 10 minutes on product planning saves hours of rework. The mission and roadmap give Claude (and you) context for every decision.

### 2. Provide Visual References

If you have mockups, wireframes, or even screenshots of similar features, share them during the Shape phase. Claude will analyze them and reference specific elements in the spec and tasks. If none exist and the feature has meaningful UI, Claude can use the `frontend-design` skill to create an HTML mockup.

```
"Here's the dashboard mockup: dashboard-mockup.png — treat lofi-form-sketch.png
as a wireframe, not a pixel-perfect target"
```

### 3. Point to Similar Code

When Claude asks about existing features to reference, provide paths:

```
"We have similar forms at app/views/posts/ and the 
UserService at app/services/user_service.rb follows 
patterns we should reuse"
```

This prevents Claude from reinventing the wheel.

### 4. Add Your Coding Standards

Create standards files in `sdd/standards/` to ensure consistent code:

```
sdd/standards/
├── global/
│   └── naming-conventions.md
├── backend/
│   └── database.md
└── frontend/
    └── components.md
```

These get injected into implementation prompts automatically.

### 5. Use the Progress File

The `progress.yml` file tracks where you are. If you close the chat and come back:

```
You: "What's the status of my spec?"

Claude: [Reads progress.yml, tells you exactly where you left off]
```

### 6. Hand Off Self-Contained Prompts

`tasks.md` embeds a self-contained Claude Code prompt for each task group — the checklist, the scoped standards, the reference file paths, and the verify command, all in one place. You can run all groups in a single Claude Code session, or copy one group's prompt into a fresh session (or another tool) and run them in order.

---

## Common Gotchas

### 1. "Claude forgot my requirements"

**Problem:** In long conversations, context can get lost.

**Solution:** The skill writes everything to files. If Claude seems confused:
```
"Read sdd/specs/my-feature/spec.md and continue"
```

### 2. "The spec has features I didn't ask for"

**Problem:** Claude added scope beyond your requirements.

**Solution:** Review the spec's **Out of Scope** section before implementation:
```
"Check spec.md — the Out of Scope section should list what we're NOT building"
```

This catches scope creep early.

### 3. "Too many tests being written"

**Problem:** The skill limits tests (2–5 per task group, 10–20 total per feature, never more than 8 per group) but Claude might ignore this.

**Solution:** Be explicit:
```
"Remember: only 2–5 focused tests per task group, not comprehensive coverage"
```

### 4. "Progress file is out of sync"

**Problem:** You made changes manually or Claude forgot to update progress.yml.

**Solution:** 
```
"Update progress.yml to reflect current state"
```

Or manually edit the YAML file.

### 5. "I want to change requirements mid-implementation"

**Problem:** Scope changed after tasks were created.

**Solution:** Go back to the appropriate phase:
```
"Let's revise the requirements - I need to add X"
```

Then regenerate the spec and tasks.

### 6. "Claude is implementing differently than spec"

**Problem:** Implementation drifted from specification.

**Solution:** Reference the spec explicitly:
```
"Check spec.md - the requirement says X but you implemented Y"
```

---

## Workflow Cheat Sheet

```
┌─────────────────────────────────────────────────────────────┐
│                    PRODUCT PLANNING                          │
│                     (Run once)                               │
├─────────────────────────────────────────────────────────────┤
│  /sdd-init  →  /sdd-plan                                     │
│                    ↓                                         │
│  Creates: mission.md, roadmap.md, tech-stack.md             │
└─────────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│                 FEATURE DEVELOPMENT                          │
│                (Repeat for each feature)                     │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  /sdd-shape  →  /sdd-tasks  →  hand off to Claude Code      │
│       ↓              ↓                  ↓                    │
│   spec.md        tasks.md          [actual code]            │
│   references.md  (self-contained                            │
│   standards.md    prompts)                                  │
│                                                             │
│  Check progress any time with /sdd-status                   │
└─────────────────────────────────────────────────────────────┘
```

---

## FAQ

**Q: Do I have to use all the phases?**

No. For an existing app you can skip product planning (`/sdd-plan`) and go straight to `/sdd-shape`. If you already have clear requirements, give them to Claude during shaping instead of answering the questions one by one.

**Q: Can I use this for existing projects?**

Yes! Run `/sdd-init` in your project, then `/sdd-discover-standards` to capture the codebase's tribal knowledge as standards. The skill works for new features in existing codebases.

**Q: What if I'm working solo, not with a team?**

The skill works great solo. The self-contained spec folder helps future-you remember why decisions were made and lets you resume work in a fresh session with zero context loss.

**Q: How do I use the task-group prompts?**

Each group in `tasks.md` is a self-contained prompt. Run them all in one Claude Code session, or copy a single group's prompt into a fresh session and run the groups in order (Database → Backend → Frontend → Integration).

**Q: Can I customize the templates?**

Yes! Edit the templates in `references/document-templates.md` or create your own standards in `sdd/standards/` (and register them in `standards/index.yml`).

---

## Getting Help

- **Check progress:** `/sdd-status` or "What's my current status?"
- **Resume work:** "Continue where we left off on [feature]"
- **See what's next:** "What's the next step for this spec?"
- **Discover standards:** `/sdd-discover-standards` to capture an existing codebase's conventions

---

## License

This skill is provided as-is for use with Claude.
