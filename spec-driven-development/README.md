# Spec-Driven Development Skill

A structured workflow for building production-quality features with AI agents. Transform rough ideas into implemented features through systematic planning, documentation, and execution.

## What This Skill Does

This skill guides Claude through a proven development workflow inspired by [Agent OS](https://github.com/buildermethods/agent-os). Instead of jumping straight into code, it helps you:

1. **Plan your product** — Define mission, roadmap, and tech stack
2. **Shape requirements** — Gather detailed requirements through targeted questions
3. **Write specifications** — Create formal specs that capture exactly what to build
4. **Break down tasks** — Generate strategic, ordered task lists
5. **Generate prompts** — Create implementation prompts for any AI tool
6. **Implement systematically** — Build features with consistent quality
7. **Verify completeness** — Ensure everything works before shipping

**The result:** A well-documented feature built to spec, with clear requirements, organized tasks, and verification reports—not just code thrown together.

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

Copy the `spec-driven-dev` folder to your Claude skills directory:

```bash
# For Claude Desktop / Claude Code
cp -r spec-driven-dev ~/.claude/skills/

# Or wherever your AI tool loads skills from
```

---

## How to Use

### Quick Start

```
You: "Initialize spec-driven development for my project"

Claude: [Creates sdd/ directory structure and progress.yml]

You: "Let's plan the product"

Claude: [Asks about your product, creates mission.md, roadmap.md, tech-stack.md]

You: "Start a new spec for user authentication"

Claude: [Creates spec folder, asks clarifying questions, gathers requirements]

You: "Write the spec"

Claude: [Creates formal specification based on requirements]

You: "Create the task breakdown"

Claude: [Generates ordered tasks with acceptance criteria]

You: "Generate implementation prompts"

Claude: [Creates prompt files for each task group]

You: "Implement the feature"

Claude: [Works through tasks, runs tests, marks complete]

You: "Verify and wrap up"

Claude: [Runs verification, updates roadmap, creates report]

You: "Export everything"

Claude: [Creates zip file with all documents]
```

### Available Commands

| Command | What It Does |
|---------|--------------|
| `/sdd-init` | Initialize project with sdd/ directory |
| `/sdd-plan` | Create mission, roadmap, tech stack |
| `/sdd-shape` | Gather requirements for a feature |
| `/sdd-write` | Write formal specification |
| `/sdd-verify-spec` | Validate spec before implementation |
| `/sdd-tasks` | Create task breakdown |
| `/sdd-prompts` | Generate implementation prompts |
| `/sdd-implement` | Implement in simple mode |
| `/sdd-orchestrate` | Implement with multi-agent orchestration |
| `/sdd-verify` | Final verification |
| `/sdd-status` | Show current progress |
| `/sdd-export` | Zip all documents |

### Natural Language Works Too

You don't have to use commands. Just describe what you want:

- "Help me plan out my todo app"
- "I want to add a comments feature"
- "What's the status of my current spec?"
- "Create tasks for the authentication spec"
- "Generate prompts so I can use Cursor for implementation"

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
    │   ├── global/
    │   ├── backend/
    │   ├── frontend/
    │   └── testing/
    └── specs/
        └── 2024-12-22-user-auth/       # One folder per feature
            ├── planning/
            │   ├── requirements.md     # Gathered requirements
            │   └── visuals/            # Mockups, wireframes
            ├── spec.md                 # Formal specification
            ├── tasks.md                # Task breakdown
            ├── orchestration.yml       # Multi-agent config (optional)
            ├── implementation/
            │   └── prompts/            # Generated prompts
            │       ├── 1-database-layer.md
            │       ├── 2-api-endpoints.md
            │       ├── 3-ui-components.md
            │       └── 4-test-review.md
            └── verification/
                ├── spec-verification.md
                └── final-verification.md
```

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

## Task Group 1: Database Layer
- [ ] 1.1 Write 2-8 focused tests for User model
- [ ] 1.2 Create users migration
- [ ] 1.3 Create User model with validations
...
```

---

## Tips for Best Results

### 1. Don't Skip the Planning Phase

It's tempting to jump straight to "build me X," but spending 10 minutes on product planning saves hours of rework. The mission and roadmap give Claude (and you) context for every decision.

### 2. Provide Visual References

If you have mockups, wireframes, or even screenshots of similar features, add them to `planning/visuals/`. Claude will analyze them and reference specific elements in the spec and tasks.

```
sdd/specs/my-feature/planning/visuals/
├── dashboard-mockup.png
├── mobile-wireframe.jpg
└── lofi-form-sketch.png      # "lofi" in name = treat as wireframe
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

### 6. Generate Prompts for Other Tools

If you prefer Cursor, Copilot, or another AI tool for implementation:

```
You: "Generate implementation prompts for this spec"

Claude: [Creates prompt files in implementation/prompts/]
```

Then copy those prompts into your preferred tool.

---

## Common Gotchas

### 1. "Claude forgot my requirements"

**Problem:** In long conversations, context can get lost.

**Solution:** The skill writes everything to files. If Claude seems confused:
```
"Read sdd/specs/my-feature/planning/requirements.md and continue"
```

### 2. "The spec has features I didn't ask for"

**Problem:** Claude added scope beyond your requirements.

**Solution:** Run spec verification before implementation:
```
"Verify the spec against requirements"
```

This catches scope creep early.

### 3. "Too many tests being written"

**Problem:** The skill limits tests (2-8 per task group, ~16-34 total per feature) but Claude might ignore this.

**Solution:** Be explicit:
```
"Remember: only 2-8 focused tests per task group, not comprehensive coverage"
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

Then regenerate spec, tasks, and prompts.

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
│                    PRODUCT PLANNING                         │
│                     (Run once)                              │
├─────────────────────────────────────────────────────────────┤
│  /sdd-init  →  /sdd-plan                                    │
│                    ↓                                        │
│  Creates: mission.md, roadmap.md, tech-stack.md             │
└─────────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│                 FEATURE DEVELOPMENT                         │
│                (Repeat for each feature)                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  /sdd-shape  →  /sdd-write  →  /sdd-verify-spec             │
│       ↓              ↓               ↓                      │
│  requirements.md   spec.md    spec-verification.md          │
│                                                             │
│       ↓              ↓               ↓                      │
│                                                             │
│  /sdd-tasks  →  /sdd-prompts  →  /sdd-implement             │
│       ↓              ↓               ↓                      │
│   tasks.md      prompts/*.md    [actual code]               │
│                                                             │
│                      ↓                                      │
│                                                             │
│               /sdd-verify  →  /sdd-export                   │
│                    ↓               ↓                        │
│         final-verification.md   sdd-export.zip              │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## FAQ

**Q: Do I have to use all the phases?**

No. If you already have clear requirements, skip `/sdd-shape` and write them directly to `requirements.md`. If you don't need prompts for other tools, skip `/sdd-prompts`.

**Q: Can I use this for existing projects?**

Yes! Run `/sdd-init` in your project, then `/sdd-plan` to document your existing product. The skill works for new features in existing codebases.

**Q: What if I'm working solo, not with a team?**

The skill works great solo. Skip orchestration mode and use simple implementation. The documentation helps future-you remember why decisions were made.

**Q: How do I use the generated prompts?**

Copy the contents of each prompt file (e.g., `1-database-layer.md`) and paste it into your AI tool of choice. Run them in order (1, 2, 3, 4).

**Q: Can I customize the templates?**

Yes! Edit the templates in `references/document-templates.md` or create your own standards in `sdd/standards/`.

---

## Getting Help

- **Check progress:** `/sdd-status` or "What's my current status?"
- **Resume work:** "Continue where we left off on [feature]"
- **See what's next:** "What's the next step for this spec?"
- **Export everything:** `/sdd-export` or "Zip up all my spec documents"

---

## License

This skill is provided as-is for use with Claude.
