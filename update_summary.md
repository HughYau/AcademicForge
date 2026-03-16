## Updated Skills

Submodule skills/AI-research-SKILLs 0ae5872..500b267:
  > fix: Remove internal background_docs from repo, add to gitignore
  > fix: Stronger OpenClaw cron instruction — check docs if unsure, must not skip
  > fix: Fall back to copy when symlinks fail on Windows
  > feat: Rename reports/ to to_human/, add git commit + cleanup to loop/cron
  > feat: Add src/ and data/ to workspace, large checkpoints to storage path
  > fix: OpenClaw cron prompt texts user exciting plots immediately
  > fix: Loop prompt now instructs updating findings, log, and state
  > fix: Add explicit fully autonomous mandate at top of SKILL.md
  > fix: Add periodic SKILL.md re-read to loop/cron prompt
  > fix: Add progress reporting to loop/cron prompt
  > feat: Make /loop and cron job mandatory first action, every 10 min
  > docs: Update mission to reflect full research lifecycle, not just engineering
  > fix: Autoresearch first in all tables, fix stale counts across package
  > fix: Add missing ideation category to npm package, fix installer
  > fix: Add PDF fallback when HTML fails to open for progress reports
  > fix: Make findings.md explicit as project memory with Lessons section
  > chore: Update README, marketplace, and npm for autoresearch skill
  > feat: Add autoresearch skill — two-loop autonomous research orchestration
Submodule skills/claude-scientific-skills c84622c..575f1e5:
  > Merge pull request #91 from alif-munim/main
  > Merge pull request #87 from Cervolve/feat/primekg-skill
diff --git a/skills/planning-with-files/SKILL.md b/skills/planning-with-files/SKILL.md
index 33d191d..d967199 100644
--- a/skills/planning-with-files/SKILL.md
+++ b/skills/planning-with-files/SKILL.md
@@ -4,6 +4,10 @@ description: Implements Manus-style file-based planning to organize and track pr
 user-invocable: true
 allowed-tools: "Read, Write, Edit, Bash, Glob, Grep"
 hooks:
+  UserPromptSubmit:
+    - hooks:
+        - type: command
+          command: "if [ -f task_plan.md ]; then echo '[planning-with-files] Active plan detected. If you have not read task_plan.md, progress.md, and findings.md in this conversation, read them now before proceeding.'; fi"
   PreToolUse:
     - matcher: "Write|Edit|Bash|Read|Glob|Grep"
       hooks:
@@ -13,13 +17,13 @@ hooks:
     - matcher: "Write|Edit"
       hooks:
         - type: command
-          command: "echo '[planning-with-files] File updated. If this completes a phase, update task_plan.md status.'"
+          command: "if [ -f task_plan.md ]; then echo '[planning-with-files] Update progress.md with what you just did. If a phase is now complete, update task_plan.md status.'; fi"
   Stop:
     - hooks:
         - type: command
           command: "SD=\"${OPENCODE_SKILL_ROOT:-$HOME/.config/opencode/skills/planning-with-files}/scripts\"; powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"$SD/check-complete.ps1\" 2>/dev/null || sh \"$SD/check-complete.sh\""
 metadata:
-  version: "2.21.0"
+  version: "2.23.0"
 ---
 
 # Planning with Files
diff --git a/skills/superpowers/brainstorming/SKILL.md b/skills/superpowers/brainstorming/SKILL.md
index 460f73a..724dc79 100644
--- a/skills/superpowers/brainstorming/SKILL.md
+++ b/skills/superpowers/brainstorming/SKILL.md
@@ -5,8 +5,6 @@ description: "You MUST use this before any creative work - creating features, bu
 
 # Brainstorming Ideas Into Designs
 
-## Overview
-
 Help turn ideas into fully formed designs and specs through natural collaborative dialogue.
 
 Start by understanding the current project context, then ask questions one at a time to refine the idea. Once you understand what you're building, present the design and get user approval.
@@ -24,31 +22,47 @@ Every project goes through this process. A todo list, a single-function utility,
 You MUST create a task for each of these items and complete them in order:
 
 1. **Explore project context** — check files, docs, recent commits
-2. **Ask clarifying questions** — one at a time, understand purpose/constraints/success criteria
-3. **Propose 2-3 approaches** — with trade-offs and your recommendation
-4. **Present design** — in sections scaled to their complexity, get user approval after each section
-5. **Write design doc** — save to `docs/plans/YYYY-MM-DD-<topic>-design.md` and commit
-6. **Transition to implementation** — invoke writing-plans skill to create implementation plan
+2. **Offer visual companion** (if topic will involve visual questions) — this is its own message, not combined with a clarifying question. See the Visual Companion section below.
+3. **Ask clarifying questions** — one at a time, understand purpose/constraints/success criteria
+4. **Propose 2-3 approaches** — with trade-offs and your recommendation
+5. **Present design** — in sections scaled to their complexity, get user approval after each section
+6. **Write design doc** — save to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` and commit
+7. **Spec review loop** — dispatch spec-document-reviewer subagent with precisely crafted review context (never your session history); fix issues and re-dispatch until approved (max 5 iterations, then surface to human)
+8. **User reviews written spec** — ask user to review the spec file before proceeding
+9. **Transition to implementation** — invoke writing-plans skill to create implementation plan
 
 ## Process Flow
 
 ```dot
 digraph brainstorming {
     "Explore project context" [shape=box];
+    "Visual questions ahead?" [shape=diamond];
+    "Offer Visual Companion\n(own message, no other content)" [shape=box];
     "Ask clarifying questions" [shape=box];
     "Propose 2-3 approaches" [shape=box];
     "Present design sections" [shape=box];
     "User approves design?" [shape=diamond];
     "Write design doc" [shape=box];
+    "Spec review loop" [shape=box];
+    "Spec review passed?" [shape=diamond];
+    "User reviews spec?" [shape=diamond];
     "Invoke writing-plans skill" [shape=doublecircle];
 
-    "Explore project context" -> "Ask clarifying questions";
+    "Explore project context" -> "Visual questions ahead?";
+    "Visual questions ahead?" -> "Offer Visual Companion\n(own message, no other content)" [label="yes"];
+    "Visual questions ahead?" -> "Ask clarifying questions" [label="no"];
+    "Offer Visual Companion\n(own message, no other content)" -> "Ask clarifying questions";
     "Ask clarifying questions" -> "Propose 2-3 approaches";
     "Propose 2-3 approaches" -> "Present design sections";
     "Present design sections" -> "User approves design?";
     "User approves design?" -> "Present design sections" [label="no, revise"];
     "User approves design?" -> "Write design doc" [label="yes"];
-    "Write design doc" -> "Invoke writing-plans skill";
+    "Write design doc" -> "Spec review loop";
+    "Spec review loop" -> "Spec review passed?";
+    "Spec review passed?" -> "Spec review loop" [label="issues found,\nfix and re-dispatch"];
+    "Spec review passed?" -> "User reviews spec?" [label="approved"];
+    "User reviews spec?" -> "Write design doc" [label="changes requested"];
+    "User reviews spec?" -> "Invoke writing-plans skill" [label="approved"];
 }
 ```
 
@@ -57,32 +71,67 @@ digraph brainstorming {
 ## The Process
 
 **Understanding the idea:**
+
 - Check out the current project state first (files, docs, recent commits)
-- Ask questions one at a time to refine the idea
+- Before asking detailed questions, assess scope: if the request describes multiple independent subsystems (e.g., "build a platform with chat, file storage, billing, and analytics"), flag this immediately. Don't spend questions refining details of a project that needs to be decomposed first.
+- If the project is too large for a single spec, help the user decompose into sub-projects: what are the independent pieces, how do they relate, what order should they be built? Then brainstorm the first sub-project through the normal design flow. Each sub-project gets its own spec → plan → implementation cycle.
+- For appropriately-scoped projects, ask questions one at a time to refine the idea
 - Prefer multiple choice questions when possible, but open-ended is fine too
 - Only one question per message - if a topic needs more exploration, break it into multiple questions
 - Focus on understanding: purpose, constraints, success criteria
 
 **Exploring approaches:**
+
 - Propose 2-3 different approaches with trade-offs
 - Present options conversationally with your recommendation and reasoning
 - Lead with your recommended option and explain why
 
 **Presenting the design:**
+
 - Once you believe you understand what you're building, present the design
 - Scale each section to its complexity: a few sentences if straightforward, up to 200-300 words if nuanced
 - Ask after each section whether it looks right so far
 - Cover: architecture, components, data flow, error handling, testing
 - Be ready to go back and clarify if something doesn't make sense
 
+**Design for isolation and clarity:**
+
+- Break the system into smaller units that each have one clear purpose, communicate through well-defined interfaces, and can be understood and tested independently
+- For each unit, you should be able to answer: what does it do, how do you use it, and what does it depend on?
+- Can someone understand what a unit does without reading its internals? Can you change the internals without breaking consumers? If not, the boundaries need work.
+- Smaller, well-bounded units are also easier for you to work with - you reason better about code you can hold in context at once, and your edits are more reliable when files are focused. When a file grows large, that's often a signal that it's doing too much.
+
+**Working in existing codebases:**
+
+- Explore the current structure before proposing changes. Follow existing patterns.
+- Where existing code has problems that affect the work (e.g., a file that's grown too large, unclear boundaries, tangled responsibilities), include targeted improvements as part of the design - the way a good developer improves code they're working in.
+- Don't propose unrelated refactoring. Stay focused on what serves the current goal.
+
 ## After the Design
 
 **Documentation:**
-- Write the validated design to `docs/plans/YYYY-MM-DD-<topic>-design.md`
+
+- Write the validated design (spec) to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`
+  - (User preferences for spec location override this default)
 - Use elements-of-style:writing-clearly-and-concisely skill if available
 - Commit the design document to git
 
+**Spec Review Loop:**
+After writing the spec document:
+
+1. Dispatch spec-document-reviewer subagent (see spec-document-reviewer-prompt.md)
+2. If Issues Found: fix, re-dispatch, repeat until Approved
+3. If loop exceeds 5 iterations, surface to human for guidance
+
+**User Review Gate:**
+After the spec review loop passes, ask the user to review the written spec before proceeding:
+
+> "Spec written and committed to `<path>`. Please review it and let me know if you want to make any changes before we start writing out the implementation plan."
+
+Wait for the user's response. If they request changes, make them and re-run the spec review loop. Only proceed once the user approves.
+
 **Implementation:**
+
 - Invoke the writing-plans skill to create a detailed implementation plan
 - Do NOT invoke any other skill. writing-plans is the next step.
 
@@ -94,3 +143,22 @@ digraph brainstorming {
 - **Explore alternatives** - Always propose 2-3 approaches before settling
 - **Incremental validation** - Present design, get approval before moving on
 - **Be flexible** - Go back and clarify when something doesn't make sense
+
+## Visual Companion
+
+A browser-based companion for showing mockups, diagrams, and visual options during brainstorming. Available as a tool — not a mode. Accepting the companion means it's available for questions that benefit from visual treatment; it does NOT mean every question goes through the browser.
+
+**Offering the companion:** When you anticipate that upcoming questions will involve visual content (mockups, layouts, diagrams), offer it once for consent:
+> "Some of what we're working on might be easier to explain if I can show it to you in a web browser. I can put together mockups, diagrams, comparisons, and other visuals as we go. This feature is still new and can be token-intensive. Want to try it? (Requires opening a local URL)"
+
+**This offer MUST be its own message.** Do not combine it with clarifying questions, context summaries, or any other content. The message should contain ONLY the offer above and nothing else. Wait for the user's response before continuing. If they decline, proceed with text-only brainstorming.
+
+**Per-question decision:** Even after the user accepts, decide FOR EACH QUESTION whether to use the browser or the terminal. The test: **would the user understand this better by seeing it than reading it?**
+
+- **Use the browser** for content that IS visual — mockups, wireframes, layout comparisons, architecture diagrams, side-by-side visual designs
+- **Use the terminal** for content that is text — requirements questions, conceptual choices, tradeoff lists, A/B/C/D text options, scope decisions
+
+A question about a UI topic is not automatically a visual question. "What does personality mean in this context?" is a conceptual question — use the terminal. "Which wizard layout works better?" is a visual question — use the browser.
+
+If they agree to the companion, read the detailed guide before proceeding:
+`skills/brainstorming/visual-companion.md`
diff --git a/skills/superpowers/dispatching-parallel-agents/SKILL.md b/skills/superpowers/dispatching-parallel-agents/SKILL.md
index 33b1485..a6a3f5a 100644
--- a/skills/superpowers/dispatching-parallel-agents/SKILL.md
+++ b/skills/superpowers/dispatching-parallel-agents/SKILL.md
@@ -7,6 +7,8 @@ description: Use when facing 2+ independent tasks that can be worked on without
 
 ## Overview
 
+You delegate tasks to specialized agents with isolated context. By precisely crafting their instructions and context, you ensure they stay focused and succeed at their task. They should never inherit your session's context or history — you construct exactly what they need. This also preserves your own context for coordination work.
+
 When you have multiple unrelated failures (different test files, different subsystems, different bugs), investigating them sequentially wastes time. Each investigation is independent and can happen in parallel.
 
 **Core principle:** Dispatch one agent per independent problem domain. Let them work concurrently.
diff --git a/skills/superpowers/executing-plans/SKILL.md b/skills/superpowers/executing-plans/SKILL.md
index c1b2533..e67f94c 100644
--- a/skills/superpowers/executing-plans/SKILL.md
+++ b/skills/superpowers/executing-plans/SKILL.md
@@ -7,12 +7,12 @@ description: Use when you have a written implementation plan to execute in a sep
 
 ## Overview
 
-Load plan, review critically, execute tasks in batches, report for review between batches.
-
-**Core principle:** Batch execution with checkpoints for architect review.
+Load plan, review critically, execute all tasks, report when complete.
 
 **Announce at start:** "I'm using the executing-plans skill to implement this plan."
 
+**Note:** Tell your human partner that Superpowers works much better with access to subagents. The quality of its work will be significantly higher if run on a platform with subagent support (such as Claude Code or Codex). If subagents are available, use superpowers:subagent-driven-development instead of this skill.
+
 ## The Process
 
 ### Step 1: Load and Review Plan
@@ -21,8 +21,7 @@ Load plan, review critically, execute tasks in batches, report for review betwee
 3. If concerns: Raise them with your human partner before starting
 4. If no concerns: Create TodoWrite and proceed
 
-### Step 2: Execute Batch
-**Default: First 3 tasks**
+### Step 2: Execute Tasks
 
 For each task:
 1. Mark as in_progress
@@ -30,19 +29,7 @@ For each task:
 3. Run verifications as specified
 4. Mark as completed
 
-### Step 3: Report
-When batch complete:
-- Show what was implemented
-- Show verification output
-- Say: "Ready for feedback."
-
-### Step 4: Continue
-Based on feedback:
-- Apply changes if needed
-- Execute next batch
-- Repeat until complete
-
-### Step 5: Complete Development
+### Step 3: Complete Development
 
 After all tasks complete and verified:
 - Announce: "I'm using the finishing-a-development-branch skill to complete this work."
@@ -52,7 +39,7 @@ After all tasks complete and verified:
 ## When to Stop and Ask for Help
 
 **STOP executing immediately when:**
-- Hit a blocker mid-batch (missing dependency, test fails, instruction unclear)
+- Hit a blocker (missing dependency, test fails, instruction unclear)
 - Plan has critical gaps preventing starting
 - You don't understand an instruction
 - Verification fails repeatedly
@@ -72,7 +59,6 @@ After all tasks complete and verified:
 - Follow plan steps exactly
 - Don't skip verifications
 - Reference skills when plan says to
-- Between batches: just report and wait
 - Stop when blocked, don't guess
 - Never start implementation on main/master branch without explicit user consent
 
diff --git a/skills/superpowers/requesting-code-review/SKILL.md b/skills/superpowers/requesting-code-review/SKILL.md
index f0e3395..fe7c8d9 100644
--- a/skills/superpowers/requesting-code-review/SKILL.md
+++ b/skills/superpowers/requesting-code-review/SKILL.md
@@ -5,7 +5,7 @@ description: Use when completing tasks, implementing major features, or before m
 
 # Requesting Code Review
 
-Dispatch superpowers:code-reviewer subagent to catch issues before they cascade.
+Dispatch superpowers:code-reviewer subagent to catch issues before they cascade. The reviewer gets precisely crafted context for evaluation — never your session's history. This keeps the reviewer focused on the work product, not your thought process, and preserves your own context for continued work.
 
 **Core principle:** Review early, review often.
 
@@ -58,7 +58,7 @@ HEAD_SHA=$(git rev-parse HEAD)
 
 [Dispatch superpowers:code-reviewer subagent]
   WHAT_WAS_IMPLEMENTED: Verification and repair functions for conversation index
-  PLAN_OR_REQUIREMENTS: Task 2 from docs/plans/deployment-plan.md
+  PLAN_OR_REQUIREMENTS: Task 2 from docs/superpowers/plans/deployment-plan.md
   BASE_SHA: a7981ec
   HEAD_SHA: 3df7661
   DESCRIPTION: Added verifyIndex() and repairIndex() with 4 issue types
diff --git a/skills/superpowers/subagent-driven-development/SKILL.md b/skills/superpowers/subagent-driven-development/SKILL.md
index b578dfa..5150b18 100644
--- a/skills/superpowers/subagent-driven-development/SKILL.md
+++ b/skills/superpowers/subagent-driven-development/SKILL.md
@@ -7,6 +7,8 @@ description: Use when executing implementation plans with independent tasks in t
 
 Execute plan by dispatching fresh subagent per task, with two-stage review after each: spec compliance review first, then code quality review.
 
+**Why subagents:** You delegate tasks to specialized agents with isolated context. By precisely crafting their instructions and context, you ensure they stay focused and succeed at their task. They should never inherit your session's context or history — you construct exactly what they need. This also preserves your own context for coordination work.
+
 **Core principle:** Fresh subagent per task + two-stage review (spec then quality) = high quality, fast iteration
 
 ## When to Use
@@ -82,6 +84,39 @@ digraph process {
 }
 ```
 
+## Model Selection
+
+Use the least powerful model that can handle each role to conserve cost and increase speed.
+
+**Mechanical implementation tasks** (isolated functions, clear specs, 1-2 files): use a fast, cheap model. Most implementation tasks are mechanical when the plan is well-specified.
+
+**Integration and judgment tasks** (multi-file coordination, pattern matching, debugging): use a standard model.
+
+**Architecture, design, and review tasks**: use the most capable available model.
+
+**Task complexity signals:**
+- Touches 1-2 files with a complete spec → cheap model
+- Touches multiple files with integration concerns → standard model
+- Requires design judgment or broad codebase understanding → most capable model
+
+## Handling Implementer Status
+
+Implementer subagents report one of four statuses. Handle each appropriately:
+
+**DONE:** Proceed to spec compliance review.
+
+**DONE_WITH_CONCERNS:** The implementer completed the work but flagged doubts. Read the concerns before proceeding. If the concerns are about correctness or scope, address them before review. If they're observations (e.g., "this file is getting large"), note them and proceed to review.
+
+**NEEDS_CONTEXT:** The implementer needs information that wasn't provided. Provide the missing context and re-dispatch.
+
+**BLOCKED:** The implementer cannot complete the task. Assess the blocker:
+1. If it's a context problem, provide more context and re-dispatch with the same model
+2. If the task requires more reasoning, re-dispatch with a more capable model
+3. If the task is too large, break it into smaller pieces
+4. If the plan itself is wrong, escalate to the human
+
+**Never** ignore an escalation or force the same model to retry without changes. If the implementer said it's stuck, something needs to change.
+
 ## Prompt Templates
 
 - `./implementer-prompt.md` - Dispatch implementer subagent
@@ -93,7 +128,7 @@ digraph process {
 ```
 You: I'm using Subagent-Driven Development to execute this plan.
 
-[Read plan file once: docs/plans/feature-plan.md]
+[Read plan file once: docs/superpowers/plans/feature-plan.md]
 [Extract all 5 tasks with full text and context]
 [Create TodoWrite with all tasks]
 
diff --git a/skills/superpowers/subagent-driven-development/code-quality-reviewer-prompt.md b/skills/superpowers/subagent-driven-development/code-quality-reviewer-prompt.md
index d029ea2..a04201a 100644
--- a/skills/superpowers/subagent-driven-development/code-quality-reviewer-prompt.md
+++ b/skills/superpowers/subagent-driven-development/code-quality-reviewer-prompt.md
@@ -17,4 +17,10 @@ Task tool (superpowers:code-reviewer):
   DESCRIPTION: [task summary]
 ```
 
+**In addition to standard code quality concerns, the reviewer should check:**
+- Does each file have one clear responsibility with a well-defined interface?
+- Are units decomposed so they can be understood and tested independently?
+- Is the implementation following the file structure from the plan?
+- Did this implementation create new files that are already large, or significantly grow existing files? (Don't flag pre-existing file sizes — focus on what this change contributed.)
+
 **Code reviewer returns:** Strengths, Issues (Critical/Important/Minor), Assessment
diff --git a/skills/superpowers/subagent-driven-development/implementer-prompt.md b/skills/superpowers/subagent-driven-development/implementer-prompt.md
index db5404b..400c103 100644
--- a/skills/superpowers/subagent-driven-development/implementer-prompt.md
+++ b/skills/superpowers/subagent-driven-development/implementer-prompt.md
@@ -41,6 +41,36 @@ Task tool (general-purpose):
     **While you work:** If you encounter something unexpected or unclear, **ask questions**.
     It's always OK to pause and clarify. Don't guess or make assumptions.
 
+    ## Code Organization
+
+    You reason best about code you can hold in context at once, and your edits are more
+    reliable when files are focused. Keep this in mind:
+    - Follow the file structure defined in the plan
+    - Each file should have one clear responsibility with a well-defined interface
+    - If a file you're creating is growing beyond the plan's intent, stop and report
+      it as DONE_WITH_CONCERNS — don't split files on your own without plan guidance
+    - If an existing file you're modifying is already large or tangled, work carefully
+      and note it as a concern in your report
+    - In existing codebases, follow established patterns. Improve code you're touching
+      the way a good developer would, but don't restructure things outside your task.
+
+    ## When You're in Over Your Head
+
+    It is always OK to stop and say "this is too hard for me." Bad work is worse than
+    no work. You will not be penalized for escalating.
+
+    **STOP and escalate when:**
+    - The task requires architectural decisions with multiple valid approaches
+    - You need to understand code beyond what was provided and can't find clarity
+    - You feel uncertain about whether your approach is correct
+    - The task involves restructuring existing code in ways the plan didn't anticipate
+    - You've been reading file after file trying to understand the system without progress
+
+    **How to escalate:** Report back with status BLOCKED or NEEDS_CONTEXT. Describe
+    specifically what you're stuck on, what you've tried, and what kind of help you need.
+    The controller can provide more context, re-dispatch with a more capable model,
+    or break the task into smaller pieces.
+
     ## Before Reporting Back: Self-Review
 
     Review your work with fresh eyes. Ask yourself:
@@ -70,9 +100,14 @@ Task tool (general-purpose):
     ## Report Format
 
     When done, report:
-    - What you implemented
+    - **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
+    - What you implemented (or what you attempted, if blocked)
     - What you tested and test results
     - Files changed
     - Self-review findings (if any)
     - Any issues or concerns
+
+    Use DONE_WITH_CONCERNS if you completed the work but have doubts about correctness.
+    Use BLOCKED if you cannot complete the task. Use NEEDS_CONTEXT if you need
+    information that wasn't provided. Never silently produce work you're unsure about.
 ```
diff --git a/skills/superpowers/using-superpowers/SKILL.md b/skills/superpowers/using-superpowers/SKILL.md
index b227eec..d813535 100644
--- a/skills/superpowers/using-superpowers/SKILL.md
+++ b/skills/superpowers/using-superpowers/SKILL.md
@@ -3,6 +3,10 @@ name: using-superpowers
 description: Use when starting any conversation - establishes how to find and use skills, requiring Skill tool invocation before ANY response including clarifying questions
 ---
 
+<SUBAGENT-STOP>
+If you were dispatched as a subagent to execute a specific task, skip this skill.
+</SUBAGENT-STOP>
+
 <EXTREMELY-IMPORTANT>
 If you think there is even a 1% chance a skill might apply to what you are doing, you ABSOLUTELY MUST invoke the skill.
 
@@ -11,12 +15,28 @@ IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE. YOU MUST USE IT.
 This is not negotiable. This is not optional. You cannot rationalize your way out of this.
 </EXTREMELY-IMPORTANT>
 
+## Instruction Priority
+
+Superpowers skills override default system prompt behavior, but **user instructions always take precedence**:
+
+1. **User's explicit instructions** (CLAUDE.md, GEMINI.md, AGENTS.md, direct requests) — highest priority
+2. **Superpowers skills** — override default system behavior where they conflict
+3. **Default system prompt** — lowest priority
+
+If CLAUDE.md, GEMINI.md, or AGENTS.md says "don't use TDD" and a skill says "always use TDD," follow the user's instructions. The user is in control.
+
 ## How to Access Skills
 
 **In Claude Code:** Use the `Skill` tool. When you invoke a skill, its content is loaded and presented to you—follow it directly. Never use the Read tool on skill files.
 
+**In Gemini CLI:** Skills activate via the `activate_skill` tool. Gemini loads skill metadata at session start and activates the full content on demand.
+
 **In other environments:** Check your platform's documentation for how skills are loaded.
 
+## Platform Adaptation
+
+Skills use Claude Code tool names. Non-CC platforms: see `references/codex-tools.md` (Codex) for tool equivalents. Gemini CLI users get the tool mapping loaded automatically via GEMINI.md.
+
 # Using Skills
 
 ## The Rule
diff --git a/skills/superpowers/writing-plans/SKILL.md b/skills/superpowers/writing-plans/SKILL.md
index 5fc45b6..ed67c5e 100644
--- a/skills/superpowers/writing-plans/SKILL.md
+++ b/skills/superpowers/writing-plans/SKILL.md
@@ -15,7 +15,23 @@ Assume they are a skilled developer, but know almost nothing about our toolset o
 
 **Context:** This should be run in a dedicated worktree (created by brainstorming skill).
 
-**Save plans to:** `docs/plans/YYYY-MM-DD-<feature-name>.md`
+**Save plans to:** `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`
+- (User preferences for plan location override this default)
+
+## Scope Check
+
+If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.
+
+## File Structure
+
+Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.
+
+- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
+- You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Prefer smaller, focused files over large ones that do too much.
+- Files that change together should live together. Split by responsibility, not by technical layer.
+- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure - but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.
+
+This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.
 
 ## Bite-Sized Task Granularity
 
@@ -33,7 +49,7 @@ Assume they are a skilled developer, but know almost nothing about our toolset o
 ```markdown
 # [Feature Name] Implementation Plan
 
-> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.
+> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.
 
 **Goal:** [One sentence describing what this builds]
 
@@ -54,7 +70,7 @@ Assume they are a skilled developer, but know almost nothing about our toolset o
 - Modify: `exact/path/to/existing.py:123-145`
 - Test: `tests/exact/path/to/test.py`
 
-**Step 1: Write the failing test**
+- [ ] **Step 1: Write the failing test**
 
 ```python
 def test_specific_behavior():
@@ -62,24 +78,24 @@ def test_specific_behavior():
     assert result == expected
 ```
 
-**Step 2: Run test to verify it fails**
+- [ ] **Step 2: Run test to verify it fails**
 
 Run: `pytest tests/path/test.py::test_name -v`
 Expected: FAIL with "function not defined"
 
-**Step 3: Write minimal implementation**
+- [ ] **Step 3: Write minimal implementation**
 
 ```python
 def function(input):
     return expected
 ```
 
-**Step 4: Run test to verify it passes**
+- [ ] **Step 4: Run test to verify it passes**
 
 Run: `pytest tests/path/test.py::test_name -v`
 Expected: PASS
 
-**Step 5: Commit**
+- [ ] **Step 5: Commit**
 
 ```bash
 git add tests/path/test.py src/path/file.py
@@ -94,23 +110,38 @@ git commit -m "feat: add specific feature"
 - Reference relevant skills with @ syntax
 - DRY, YAGNI, TDD, frequent commits
 
-## Execution Handoff
+## Plan Review Loop
+
+After completing each chunk of the plan:
+
+1. Dispatch plan-document-reviewer subagent (see plan-document-reviewer-prompt.md) with precisely crafted review context — never your session history. This keeps the reviewer focused on the plan, not your thought process.
+   - Provide: chunk content, path to spec document
+2. If ❌ Issues Found:
+   - Fix the issues in the chunk
+   - Re-dispatch reviewer for that chunk
+   - Repeat until ✅ Approved
+3. If ✅ Approved: proceed to next chunk (or execution handoff if last chunk)
 
-After saving the plan, offer execution choice:
+**Chunk boundaries:** Use `## Chunk N: <name>` headings to delimit chunks. Each chunk should be ≤1000 lines and logically self-contained.
 
-**"Plan complete and saved to `docs/plans/<filename>.md`. Two execution options:**
+**Review loop guidance:**
+- Same agent that wrote the plan fixes it (preserves context)
+- If loop exceeds 5 iterations, surface to human for guidance
+- Reviewers are advisory - explain disagreements if you believe feedback is incorrect
+
+## Execution Handoff
 
-**1. Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration
+After saving the plan:
 
-**2. Parallel Session (separate)** - Open new session with executing-plans, batch execution with checkpoints
+**"Plan complete and saved to `docs/superpowers/plans/<filename>.md`. Ready to execute?"**
 
-**Which approach?"**
+**Execution path depends on harness capabilities:**
 
-**If Subagent-Driven chosen:**
-- **REQUIRED SUB-SKILL:** Use superpowers:subagent-driven-development
-- Stay in this session
-- Fresh subagent per task + code review
+**If harness has subagents (Claude Code, etc.):**
+- **REQUIRED:** Use superpowers:subagent-driven-development
+- Do NOT offer a choice - subagent-driven is the standard approach
+- Fresh subagent per task + two-stage review
 
-**If Parallel Session chosen:**
-- Guide them to open new session in worktree
-- **REQUIRED SUB-SKILL:** New session uses superpowers:executing-plans
+**If harness does NOT have subagents:**
+- Execute plan in current session using superpowers:executing-plans
+- Batch execution with checkpoints for review
diff --git a/update_summary.md b/update_summary.md
index 8b797b7..dea9293 100644
--- a/update_summary.md
+++ b/update_summary.md
@@ -1,92 +1,598 @@
 ## Updated Skills
 
-Submodule skills/claude-scientific-skills f7585b7..b0923b2:
-  > Merge pull request #67 from 04cb/fix/docs-pymatgen-computedentry-energy
-  > Merge pull request #65 from urabbani/feature/geomaster-skill
-  > Enhance README by adding a description of K-Dense Web, clarifying its role as a hosted platform built on the scientific skills collection. This addition aims to promote the platform's features and benefits.
-  > Revise README to streamline content and promote K-Dense Web, highlighting its features and benefits. Remove outdated sections and enhance calls to action for cloud-based execution and publication-ready outputs.
-  > Update README to reflect the increase in scientific skills from 148 to 250+ databases, and enhance descriptions for Python package and integration skills. Adjust badge and feature tables accordingly.
-  > Update README and documentation to reflect the addition of the pyzotero skill and increment skill count from 147 to 148. Bump version to 2.24.0 in marketplace.json.
-  > Use Nano Banana 2
-  > Merge pull request #61 from connerlambden/add-bgpt-skill
-  > Merge pull request #62 from leipzig/feature/add-tiledb-vcf-skill
-  > Merge pull request #60 from renato-umeton/main
-  > Merge pull request #58 from K-Dense-AI/fix-yaml-frontmatter
-  > Support Alpha Advantage for more financial data
-  > Fix version number
-  > Support for Hedge Fund Monitor from the Office of Financial Research
-  > Add support for FiscalData.treasury.gov
-  > Support EdgarTools to access and analyze SEC Edgar filings, XBRL financial statements, 10-K, 10-Q, and 8-K reports
-  > Forecasting examples
-  > Merge pull request #53 from borealBytes/feat/timesfm-forecasting-skill
-  > Merge pull request #57 from renato-umeton/claude/implement-issue-56-tdd-SOjek
-diff --git a/update_summary.md b/update_summary.md
-index 6fea0f5..98b6e19 100644
---- a/update_summary.md
-+++ b/update_summary.md
-@@ -1,65 +1,2 @@
- ## Updated Skills
- 
--Submodule skills/AI-research-SKILLs a9375e3..8a14d26:
--  > Merge pull request #24 from Orchestra-Research/add-research-ideation-skills
--Submodule skills/claude-scientific-skills 3a5f2e2..f7585b7:
--  > Merge pull request #50 from borealBytes/feat/markdown-mermaid-writing-skill
--  > Bump version number to 2.20.0 in marketplace.json
--  > Update readme
--  > Merge pull request #46 from fedorov/update-idc-v1.3.0
--Submodule skills/humanizer c78047b..d8085c7:
--  > chore: sync local skill updates
--diff --git a/update_summary.md b/update_summary.md
--index 85d73b6..98b6e19 100644
----- a/update_summary.md
--+++ b/update_summary.md
--@@ -1,49 +1,2 @@
-- ## Updated Skills
-- 
---Submodule skills/AI-research-SKILLs 891c44d..a9375e3:
---  > Add SkillEvolve Meta-Skill reference and collapsible skills section
---diff --git a/skills/superpowers/systematic-debugging/find-polluter.sh b/skills/superpowers/systematic-debugging/find-polluter.sh
---old mode 100644
---new mode 100755
---diff --git a/skills/superpowers/writing-skills/render-graphs.js b/skills/superpowers/writing-skills/render-graphs.js
---old mode 100644
---new mode 100755
---diff --git a/update_summary.md b/update_summary.md
---index 609cf8e..98b6e19 100644
------ a/update_summary.md
---+++ b/update_summary.md
---@@ -1,34 +1,2 @@
--- ## Updated Skills
--- 
----Submodule skills/AI-research-SKILLs 7cfa204..891c44d:
----  > Update demos README with new demo entries and sync with main README
----  > Add npm publishing guide to CLAUDE.md
----  > Bump to v1.3.6 to test trusted publishing with fixed repo casing
----  > Bump to v1.3.5 to test trusted publishing
----  > Fix OIDC publish: clear .npmrc auth token before publish
----  > Fix OIDC publish: restore registry-url, unset NODE_AUTH_TOKEN
----  > Fix npm publish: remove token auth, use pure OIDC trusted publishing
----  > Bump version to 1.3.1 to trigger npm publish
----  > Sync package-lock.json with package.json v1.3.0
----  > Merge pull request #22 from Orchestra-Research/claude/local-skill-installation-tc0HO
----  > Add Claude Code GitHub Actions workflow
----diff --git a/update_summary.md b/update_summary.md
----index 88dcca9..98b6e19 100644
------- a/update_summary.md
----+++ b/update_summary.md
----@@ -1,15 +1,2 @@
---- ## Updated Skills
---- 
-----Submodule skills/AI-research-SKILLs eaf2c75..7cfa204:
-----  > Update docs and package for prompt-guard skill (82 → 83 skills)
-----  > Merge pull request #19 from WangCheng0116/prompt-guard-skill
-----  > Add FAISS cross-lingual alignment demo to demos table
-----  > Merge branch 'main' of https://github.com/Orchestra-Research/AI-research-SKILLs
-----  > Merge branch 'main' of https://github.com/Orchestra-Research/AI-research-SKILLs
-----  > 1.0.1
-----  > checked-agents
-----  > checked-agents
-----Submodule skills/claude-scientific-skills 4902409..3a5f2e2:
-----  > Bump version number
-----  > Merge pull request #41 from K-Dense-AI/update-writing-skills
-----  > Merge pull request #42 from fedorov/update-idc-skill-to-v1.2.0
+Submodule skills/AI-research-SKILLs 0ae5872..500b267:
+  > fix: Remove internal background_docs from repo, add to gitignore
+  > fix: Stronger OpenClaw cron instruction — check docs if unsure, must not skip
+  > fix: Fall back to copy when symlinks fail on Windows
+  > feat: Rename reports/ to to_human/, add git commit + cleanup to loop/cron
+  > feat: Add src/ and data/ to workspace, large checkpoints to storage path
+  > fix: OpenClaw cron prompt texts user exciting plots immediately
+  > fix: Loop prompt now instructs updating findings, log, and state
+  > fix: Add explicit fully autonomous mandate at top of SKILL.md
+  > fix: Add periodic SKILL.md re-read to loop/cron prompt
+  > fix: Add progress reporting to loop/cron prompt
+  > feat: Make /loop and cron job mandatory first action, every 10 min
+  > docs: Update mission to reflect full research lifecycle, not just engineering
+  > fix: Autoresearch first in all tables, fix stale counts across package
+  > fix: Add missing ideation category to npm package, fix installer
+  > fix: Add PDF fallback when HTML fails to open for progress reports
+  > fix: Make findings.md explicit as project memory with Lessons section
+  > chore: Update README, marketplace, and npm for autoresearch skill
+  > feat: Add autoresearch skill — two-loop autonomous research orchestration
+Submodule skills/claude-scientific-skills c84622c..575f1e5:
+  > Merge pull request #91 from alif-munim/main
+  > Merge pull request #87 from Cervolve/feat/primekg-skill
+diff --git a/skills/planning-with-files/SKILL.md b/skills/planning-with-files/SKILL.md
+index 33d191d..d967199 100644
+--- a/skills/planning-with-files/SKILL.md
++++ b/skills/planning-with-files/SKILL.md
+@@ -4,6 +4,10 @@ description: Implements Manus-style file-based planning to organize and track pr
+ user-invocable: true
+ allowed-tools: "Read, Write, Edit, Bash, Glob, Grep"
+ hooks:
++  UserPromptSubmit:
++    - hooks:
++        - type: command
++          command: "if [ -f task_plan.md ]; then echo '[planning-with-files] Active plan detected. If you have not read task_plan.md, progress.md, and findings.md in this conversation, read them now before proceeding.'; fi"
+   PreToolUse:
+     - matcher: "Write|Edit|Bash|Read|Glob|Grep"
+       hooks:
+@@ -13,13 +17,13 @@ hooks:
+     - matcher: "Write|Edit"
+       hooks:
+         - type: command
+-          command: "echo '[planning-with-files] File updated. If this completes a phase, update task_plan.md status.'"
++          command: "if [ -f task_plan.md ]; then echo '[planning-with-files] Update progress.md with what you just did. If a phase is now complete, update task_plan.md status.'; fi"
+   Stop:
+     - hooks:
+         - type: command
+           command: "SD=\"${OPENCODE_SKILL_ROOT:-$HOME/.config/opencode/skills/planning-with-files}/scripts\"; powershell.exe -NoProfile -ExecutionPolicy Bypass -File \"$SD/check-complete.ps1\" 2>/dev/null || sh \"$SD/check-complete.sh\""
+ metadata:
+-  version: "2.21.0"
++  version: "2.23.0"
+ ---
+ 
+ # Planning with Files
+diff --git a/skills/superpowers/brainstorming/SKILL.md b/skills/superpowers/brainstorming/SKILL.md
+index 460f73a..724dc79 100644
+--- a/skills/superpowers/brainstorming/SKILL.md
++++ b/skills/superpowers/brainstorming/SKILL.md
+@@ -5,8 +5,6 @@ description: "You MUST use this before any creative work - creating features, bu
+ 
+ # Brainstorming Ideas Into Designs
+ 
+-## Overview
+-
+ Help turn ideas into fully formed designs and specs through natural collaborative dialogue.
+ 
+ Start by understanding the current project context, then ask questions one at a time to refine the idea. Once you understand what you're building, present the design and get user approval.
+@@ -24,31 +22,47 @@ Every project goes through this process. A todo list, a single-function utility,
+ You MUST create a task for each of these items and complete them in order:
+ 
+ 1. **Explore project context** — check files, docs, recent commits
+-2. **Ask clarifying questions** — one at a time, understand purpose/constraints/success criteria
+-3. **Propose 2-3 approaches** — with trade-offs and your recommendation
+-4. **Present design** — in sections scaled to their complexity, get user approval after each section
+-5. **Write design doc** — save to `docs/plans/YYYY-MM-DD-<topic>-design.md` and commit
+-6. **Transition to implementation** — invoke writing-plans skill to create implementation plan
++2. **Offer visual companion** (if topic will involve visual questions) — this is its own message, not combined with a clarifying question. See the Visual Companion section below.
++3. **Ask clarifying questions** — one at a time, understand purpose/constraints/success criteria
++4. **Propose 2-3 approaches** — with trade-offs and your recommendation
++5. **Present design** — in sections scaled to their complexity, get user approval after each section
++6. **Write design doc** — save to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` and commit
++7. **Spec review loop** — dispatch spec-document-reviewer subagent with precisely crafted review context (never your session history); fix issues and re-dispatch until approved (max 5 iterations, then surface to human)
++8. **User reviews written spec** — ask user to review the spec file before proceeding
++9. **Transition to implementation** — invoke writing-plans skill to create implementation plan
+ 
+ ## Process Flow
+ 
+ ```dot
+ digraph brainstorming {
+     "Explore project context" [shape=box];
++    "Visual questions ahead?" [shape=diamond];
++    "Offer Visual Companion\n(own message, no other content)" [shape=box];
+     "Ask clarifying questions" [shape=box];
+     "Propose 2-3 approaches" [shape=box];
+     "Present design sections" [shape=box];
+     "User approves design?" [shape=diamond];
+     "Write design doc" [shape=box];
++    "Spec review loop" [shape=box];
++    "Spec review passed?" [shape=diamond];
++    "User reviews spec?" [shape=diamond];
+     "Invoke writing-plans skill" [shape=doublecircle];
+ 
+-    "Explore project context" -> "Ask clarifying questions";
++    "Explore project context" -> "Visual questions ahead?";
++    "Visual questions ahead?" -> "Offer Visual Companion\n(own message, no other content)" [label="yes"];
++    "Visual questions ahead?" -> "Ask clarifying questions" [label="no"];
++    "Offer Visual Companion\n(own message, no other content)" -> "Ask clarifying questions";
+     "Ask clarifying questions" -> "Propose 2-3 approaches";
+     "Propose 2-3 approaches" -> "Present design sections";
+     "Present design sections" -> "User approves design?";
+     "User approves design?" -> "Present design sections" [label="no, revise"];
+     "User approves design?" -> "Write design doc" [label="yes"];
+-    "Write design doc" -> "Invoke writing-plans skill";
++    "Write design doc" -> "Spec review loop";
++    "Spec review loop" -> "Spec review passed?";
++    "Spec review passed?" -> "Spec review loop" [label="issues found,\nfix and re-dispatch"];
++    "Spec review passed?" -> "User reviews spec?" [label="approved"];
++    "User reviews spec?" -> "Write design doc" [label="changes requested"];
++    "User reviews spec?" -> "Invoke writing-plans skill" [label="approved"];
+ }
+ ```
+ 
+@@ -57,32 +71,67 @@ digraph brainstorming {
+ ## The Process
+ 
+ **Understanding the idea:**
++
+ - Check out the current project state first (files, docs, recent commits)
+-- Ask questions one at a time to refine the idea
++- Before asking detailed questions, assess scope: if the request describes multiple independent subsystems (e.g., "build a platform with chat, file storage, billing, and analytics"), flag this immediately. Don't spend questions refining details of a project that needs to be decomposed first.
++- If the project is too large for a single spec, help the user decompose into sub-projects: what are the independent pieces, how do they relate, what order should they be built? Then brainstorm the first sub-project through the normal design flow. Each sub-project gets its own spec → plan → implementation cycle.
++- For appropriately-scoped projects, ask questions one at a time to refine the idea
+ - Prefer multiple choice questions when possible, but open-ended is fine too
+ - Only one question per message - if a topic needs more exploration, break it into multiple questions
+ - Focus on understanding: purpose, constraints, success criteria
+ 
+ **Exploring approaches:**
++
+ - Propose 2-3 different approaches with trade-offs
+ - Present options conversationally with your recommendation and reasoning
+ - Lead with your recommended option and explain why
+ 
+ **Presenting the design:**
++
+ - Once you believe you understand what you're building, present the design
+ - Scale each section to its complexity: a few sentences if straightforward, up to 200-300 words if nuanced
+ - Ask after each section whether it looks right so far
+ - Cover: architecture, components, data flow, error handling, testing
+ - Be ready to go back and clarify if something doesn't make sense
+ 
++**Design for isolation and clarity:**
++
++- Break the system into smaller units that each have one clear purpose, communicate through well-defined interfaces, and can be understood and tested independently
++- For each unit, you should be able to answer: what does it do, how do you use it, and what does it depend on?
++- Can someone understand what a unit does without reading its internals? Can you change the internals without breaking consumers? If not, the boundaries need work.
++- Smaller, well-bounded units are also easier for you to work with - you reason better about code you can hold in context at once, and your edits are more reliable when files are focused. When a file grows large, that's often a signal that it's doing too much.
++
++**Working in existing codebases:**
++
++- Explore the current structure before proposing changes. Follow existing patterns.
++- Where existing code has problems that affect the work (e.g., a file that's grown too large, unclear boundaries, tangled responsibilities), include targeted improvements as part of the design - the way a good developer improves code they're working in.
++- Don't propose unrelated refactoring. Stay focused on what serves the current goal.
++
+ ## After the Design
+ 
+ **Documentation:**
+-- Write the validated design to `docs/plans/YYYY-MM-DD-<topic>-design.md`
++
++- Write the validated design (spec) to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`
++  - (User preferences for spec location override this default)
+ - Use elements-of-style:writing-clearly-and-concisely skill if available
+ - Commit the design document to git
+ 
++**Spec Review Loop:**
++After writing the spec document:
++
++1. Dispatch spec-document-reviewer subagent (see spec-document-reviewer-prompt.md)
++2. If Issues Found: fix, re-dispatch, repeat until Approved
++3. If loop exceeds 5 iterations, surface to human for guidance
++
++**User Review Gate:**
++After the spec review loop passes, ask the user to review the written spec before proceeding:
++
++> "Spec written and committed to `<path>`. Please review it and let me know if you want to make any changes before we start writing out the implementation plan."
++
++Wait for the user's response. If they request changes, make them and re-run the spec review loop. Only proceed once the user approves.
++
+ **Implementation:**
++
+ - Invoke the writing-plans skill to create a detailed implementation plan
+ - Do NOT invoke any other skill. writing-plans is the next step.
+ 
+@@ -94,3 +143,22 @@ digraph brainstorming {
+ - **Explore alternatives** - Always propose 2-3 approaches before settling
+ - **Incremental validation** - Present design, get approval before moving on
+ - **Be flexible** - Go back and clarify when something doesn't make sense
++
++## Visual Companion
++
++A browser-based companion for showing mockups, diagrams, and visual options during brainstorming. Available as a tool — not a mode. Accepting the companion means it's available for questions that benefit from visual treatment; it does NOT mean every question goes through the browser.
++
++**Offering the companion:** When you anticipate that upcoming questions will involve visual content (mockups, layouts, diagrams), offer it once for consent:
++> "Some of what we're working on might be easier to explain if I can show it to you in a web browser. I can put together mockups, diagrams, comparisons, and other visuals as we go. This feature is still new and can be token-intensive. Want to try it? (Requires opening a local URL)"
++
++**This offer MUST be its own message.** Do not combine it with clarifying questions, context summaries, or any other content. The message should contain ONLY the offer above and nothing else. Wait for the user's response before continuing. If they decline, proceed with text-only brainstorming.
++
++**Per-question decision:** Even after the user accepts, decide FOR EACH QUESTION whether to use the browser or the terminal. The test: **would the user understand this better by seeing it than reading it?**
++
++- **Use the browser** for content that IS visual — mockups, wireframes, layout comparisons, architecture diagrams, side-by-side visual designs
++- **Use the terminal** for content that is text — requirements questions, conceptual choices, tradeoff lists, A/B/C/D text options, scope decisions
++
++A question about a UI topic is not automatically a visual question. "What does personality mean in this context?" is a conceptual question — use the terminal. "Which wizard layout works better?" is a visual question — use the browser.
++
++If they agree to the companion, read the detailed guide before proceeding:
++`skills/brainstorming/visual-companion.md`
+diff --git a/skills/superpowers/dispatching-parallel-agents/SKILL.md b/skills/superpowers/dispatching-parallel-agents/SKILL.md
+index 33b1485..a6a3f5a 100644
+--- a/skills/superpowers/dispatching-parallel-agents/SKILL.md
++++ b/skills/superpowers/dispatching-parallel-agents/SKILL.md
+@@ -7,6 +7,8 @@ description: Use when facing 2+ independent tasks that can be worked on without
+ 
+ ## Overview
+ 
++You delegate tasks to specialized agents with isolated context. By precisely crafting their instructions and context, you ensure they stay focused and succeed at their task. They should never inherit your session's context or history — you construct exactly what they need. This also preserves your own context for coordination work.
++
+ When you have multiple unrelated failures (different test files, different subsystems, different bugs), investigating them sequentially wastes time. Each investigation is independent and can happen in parallel.
+ 
+ **Core principle:** Dispatch one agent per independent problem domain. Let them work concurrently.
+diff --git a/skills/superpowers/executing-plans/SKILL.md b/skills/superpowers/executing-plans/SKILL.md
+index c1b2533..e67f94c 100644
+--- a/skills/superpowers/executing-plans/SKILL.md
++++ b/skills/superpowers/executing-plans/SKILL.md
+@@ -7,12 +7,12 @@ description: Use when you have a written implementation plan to execute in a sep
+ 
+ ## Overview
+ 
+-Load plan, review critically, execute tasks in batches, report for review between batches.
+-
+-**Core principle:** Batch execution with checkpoints for architect review.
++Load plan, review critically, execute all tasks, report when complete.
+ 
+ **Announce at start:** "I'm using the executing-plans skill to implement this plan."
+ 
++**Note:** Tell your human partner that Superpowers works much better with access to subagents. The quality of its work will be significantly higher if run on a platform with subagent support (such as Claude Code or Codex). If subagents are available, use superpowers:subagent-driven-development instead of this skill.
++
+ ## The Process
+ 
+ ### Step 1: Load and Review Plan
+@@ -21,8 +21,7 @@ Load plan, review critically, execute tasks in batches, report for review betwee
+ 3. If concerns: Raise them with your human partner before starting
+ 4. If no concerns: Create TodoWrite and proceed
+ 
+-### Step 2: Execute Batch
+-**Default: First 3 tasks**
++### Step 2: Execute Tasks
+ 
+ For each task:
+ 1. Mark as in_progress
+@@ -30,19 +29,7 @@ For each task:
+ 3. Run verifications as specified
+ 4. Mark as completed
+ 
+-### Step 3: Report
+-When batch complete:
+-- Show what was implemented
+-- Show verification output
+-- Say: "Ready for feedback."
+-
+-### Step 4: Continue
+-Based on feedback:
+-- Apply changes if needed
+-- Execute next batch
+-- Repeat until complete
+-
+-### Step 5: Complete Development
++### Step 3: Complete Development
+ 
+ After all tasks complete and verified:
+ - Announce: "I'm using the finishing-a-development-branch skill to complete this work."
+@@ -52,7 +39,7 @@ After all tasks complete and verified:
+ ## When to Stop and Ask for Help
+ 
+ **STOP executing immediately when:**
+-- Hit a blocker mid-batch (missing dependency, test fails, instruction unclear)
++- Hit a blocker (missing dependency, test fails, instruction unclear)
+ - Plan has critical gaps preventing starting
+ - You don't understand an instruction
+ - Verification fails repeatedly
+@@ -72,7 +59,6 @@ After all tasks complete and verified:
+ - Follow plan steps exactly
+ - Don't skip verifications
+ - Reference skills when plan says to
+-- Between batches: just report and wait
+ - Stop when blocked, don't guess
+ - Never start implementation on main/master branch without explicit user consent
+ 
+diff --git a/skills/superpowers/requesting-code-review/SKILL.md b/skills/superpowers/requesting-code-review/SKILL.md
+index f0e3395..fe7c8d9 100644
+--- a/skills/superpowers/requesting-code-review/SKILL.md
++++ b/skills/superpowers/requesting-code-review/SKILL.md
+@@ -5,7 +5,7 @@ description: Use when completing tasks, implementing major features, or before m
+ 
+ # Requesting Code Review
+ 
+-Dispatch superpowers:code-reviewer subagent to catch issues before they cascade.
++Dispatch superpowers:code-reviewer subagent to catch issues before they cascade. The reviewer gets precisely crafted context for evaluation — never your session's history. This keeps the reviewer focused on the work product, not your thought process, and preserves your own context for continued work.
+ 
+ **Core principle:** Review early, review often.
+ 
+@@ -58,7 +58,7 @@ HEAD_SHA=$(git rev-parse HEAD)
+ 
+ [Dispatch superpowers:code-reviewer subagent]
+   WHAT_WAS_IMPLEMENTED: Verification and repair functions for conversation index
+-  PLAN_OR_REQUIREMENTS: Task 2 from docs/plans/deployment-plan.md
++  PLAN_OR_REQUIREMENTS: Task 2 from docs/superpowers/plans/deployment-plan.md
+   BASE_SHA: a7981ec
+   HEAD_SHA: 3df7661
+   DESCRIPTION: Added verifyIndex() and repairIndex() with 4 issue types
+diff --git a/skills/superpowers/subagent-driven-development/SKILL.md b/skills/superpowers/subagent-driven-development/SKILL.md
+index b578dfa..5150b18 100644
+--- a/skills/superpowers/subagent-driven-development/SKILL.md
++++ b/skills/superpowers/subagent-driven-development/SKILL.md
+@@ -7,6 +7,8 @@ description: Use when executing implementation plans with independent tasks in t
+ 
+ Execute plan by dispatching fresh subagent per task, with two-stage review after each: spec compliance review first, then code quality review.
+ 
++**Why subagents:** You delegate tasks to specialized agents with isolated context. By precisely crafting their instructions and context, you ensure they stay focused and succeed at their task. They should never inherit your session's context or history — you construct exactly what they need. This also preserves your own context for coordination work.
++
+ **Core principle:** Fresh subagent per task + two-stage review (spec then quality) = high quality, fast iteration
+ 
+ ## When to Use
+@@ -82,6 +84,39 @@ digraph process {
+ }
+ ```
+ 
++## Model Selection
++
++Use the least powerful model that can handle each role to conserve cost and increase speed.
++
++**Mechanical implementation tasks** (isolated functions, clear specs, 1-2 files): use a fast, cheap model. Most implementation tasks are mechanical when the plan is well-specified.
++
++**Integration and judgment tasks** (multi-file coordination, pattern matching, debugging): use a standard model.
++
++**Architecture, design, and review tasks**: use the most capable available model.
++
++**Task complexity signals:**
++- Touches 1-2 files with a complete spec → cheap model
++- Touches multiple files with integration concerns → standard model
++- Requires design judgment or broad codebase understanding → most capable model
++
++## Handling Implementer Status
++
++Implementer subagents report one of four statuses. Handle each appropriately:
++
++**DONE:** Proceed to spec compliance review.
++
++**DONE_WITH_CONCERNS:** The implementer completed the work but flagged doubts. Read the concerns before proceeding. If the concerns are about correctness or scope, address them before review. If they're observations (e.g., "this file is getting large"), note them and proceed to review.
++
++**NEEDS_CONTEXT:** The implementer needs information that wasn't provided. Provide the missing context and re-dispatch.
++
++**BLOCKED:** The implementer cannot complete the task. Assess the blocker:
++1. If it's a context problem, provide more context and re-dispatch with the same model
++2. If the task requires more reasoning, re-dispatch with a more capable model
++3. If the task is too large, break it into smaller pieces
++4. If the plan itself is wrong, escalate to the human
++
++**Never** ignore an escalation or force the same model to retry without changes. If the implementer said it's stuck, something needs to change.
++
+ ## Prompt Templates
+ 
+ - `./implementer-prompt.md` - Dispatch implementer subagent
+@@ -93,7 +128,7 @@ digraph process {
+ ```
+ You: I'm using Subagent-Driven Development to execute this plan.
+ 
+-[Read plan file once: docs/plans/feature-plan.md]
++[Read plan file once: docs/superpowers/plans/feature-plan.md]
+ [Extract all 5 tasks with full text and context]
+ [Create TodoWrite with all tasks]
+ 
+diff --git a/skills/superpowers/subagent-driven-development/code-quality-reviewer-prompt.md b/skills/superpowers/subagent-driven-development/code-quality-reviewer-prompt.md
+index d029ea2..a04201a 100644
+--- a/skills/superpowers/subagent-driven-development/code-quality-reviewer-prompt.md
++++ b/skills/superpowers/subagent-driven-development/code-quality-reviewer-prompt.md
+@@ -17,4 +17,10 @@ Task tool (superpowers:code-reviewer):
+   DESCRIPTION: [task summary]
+ ```
+ 
++**In addition to standard code quality concerns, the reviewer should check:**
++- Does each file have one clear responsibility with a well-defined interface?
++- Are units decomposed so they can be understood and tested independently?
++- Is the implementation following the file structure from the plan?
++- Did this implementation create new files that are already large, or significantly grow existing files? (Don't flag pre-existing file sizes — focus on what this change contributed.)
++
+ **Code reviewer returns:** Strengths, Issues (Critical/Important/Minor), Assessment
+diff --git a/skills/superpowers/subagent-driven-development/implementer-prompt.md b/skills/superpowers/subagent-driven-development/implementer-prompt.md
+index db5404b..400c103 100644
+--- a/skills/superpowers/subagent-driven-development/implementer-prompt.md
++++ b/skills/superpowers/subagent-driven-development/implementer-prompt.md
+@@ -41,6 +41,36 @@ Task tool (general-purpose):
+     **While you work:** If you encounter something unexpected or unclear, **ask questions**.
+     It's always OK to pause and clarify. Don't guess or make assumptions.
+ 
++    ## Code Organization
++
++    You reason best about code you can hold in context at once, and your edits are more
++    reliable when files are focused. Keep this in mind:
++    - Follow the file structure defined in the plan
++    - Each file should have one clear responsibility with a well-defined interface
++    - If a file you're creating is growing beyond the plan's intent, stop and report
++      it as DONE_WITH_CONCERNS — don't split files on your own without plan guidance
++    - If an existing file you're modifying is already large or tangled, work carefully
++      and note it as a concern in your report
++    - In existing codebases, follow established patterns. Improve code you're touching
++      the way a good developer would, but don't restructure things outside your task.
++
++    ## When You're in Over Your Head
++
++    It is always OK to stop and say "this is too hard for me." Bad work is worse than
++    no work. You will not be penalized for escalating.
++
++    **STOP and escalate when:**
++    - The task requires architectural decisions with multiple valid approaches
++    - You need to understand code beyond what was provided and can't find clarity
++    - You feel uncertain about whether your approach is correct
++    - The task involves restructuring existing code in ways the plan didn't anticipate
++    - You've been reading file after file trying to understand the system without progress
++
++    **How to escalate:** Report back with status BLOCKED or NEEDS_CONTEXT. Describe
++    specifically what you're stuck on, what you've tried, and what kind of help you need.
++    The controller can provide more context, re-dispatch with a more capable model,
++    or break the task into smaller pieces.
++
+     ## Before Reporting Back: Self-Review
+ 
+     Review your work with fresh eyes. Ask yourself:
+@@ -70,9 +100,14 @@ Task tool (general-purpose):
+     ## Report Format
+ 
+     When done, report:
+-    - What you implemented
++    - **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED | NEEDS_CONTEXT
++    - What you implemented (or what you attempted, if blocked)
+     - What you tested and test results
+     - Files changed
+     - Self-review findings (if any)
+     - Any issues or concerns
++
++    Use DONE_WITH_CONCERNS if you completed the work but have doubts about correctness.
++    Use BLOCKED if you cannot complete the task. Use NEEDS_CONTEXT if you need
++    information that wasn't provided. Never silently produce work you're unsure about.
+ ```
+diff --git a/skills/superpowers/using-superpowers/SKILL.md b/skills/superpowers/using-superpowers/SKILL.md
+index b227eec..d813535 100644
+--- a/skills/superpowers/using-superpowers/SKILL.md
++++ b/skills/superpowers/using-superpowers/SKILL.md
+@@ -3,6 +3,10 @@ name: using-superpowers
+ description: Use when starting any conversation - establishes how to find and use skills, requiring Skill tool invocation before ANY response including clarifying questions
+ ---
+ 
++<SUBAGENT-STOP>
++If you were dispatched as a subagent to execute a specific task, skip this skill.
++</SUBAGENT-STOP>
++
+ <EXTREMELY-IMPORTANT>
+ If you think there is even a 1% chance a skill might apply to what you are doing, you ABSOLUTELY MUST invoke the skill.
+ 
+@@ -11,12 +15,28 @@ IF A SKILL APPLIES TO YOUR TASK, YOU DO NOT HAVE A CHOICE. YOU MUST USE IT.
+ This is not negotiable. This is not optional. You cannot rationalize your way out of this.
+ </EXTREMELY-IMPORTANT>
+ 
++## Instruction Priority
++
++Superpowers skills override default system prompt behavior, but **user instructions always take precedence**:
++
++1. **User's explicit instructions** (CLAUDE.md, GEMINI.md, AGENTS.md, direct requests) — highest priority
++2. **Superpowers skills** — override default system behavior where they conflict
++3. **Default system prompt** — lowest priority
++
++If CLAUDE.md, GEMINI.md, or AGENTS.md says "don't use TDD" and a skill says "always use TDD," follow the user's instructions. The user is in control.
++
+ ## How to Access Skills
+ 
+ **In Claude Code:** Use the `Skill` tool. When you invoke a skill, its content is loaded and presented to you—follow it directly. Never use the Read tool on skill files.
+ 
++**In Gemini CLI:** Skills activate via the `activate_skill` tool. Gemini loads skill metadata at session start and activates the full content on demand.
++
+ **In other environments:** Check your platform's documentation for how skills are loaded.
+ 
++## Platform Adaptation
++
++Skills use Claude Code tool names. Non-CC platforms: see `references/codex-tools.md` (Codex) for tool equivalents. Gemini CLI users get the tool mapping loaded automatically via GEMINI.md.
++
+ # Using Skills
+ 
+ ## The Rule
+diff --git a/skills/superpowers/writing-plans/SKILL.md b/skills/superpowers/writing-plans/SKILL.md
+index 5fc45b6..ed67c5e 100644
+--- a/skills/superpowers/writing-plans/SKILL.md
++++ b/skills/superpowers/writing-plans/SKILL.md
+@@ -15,7 +15,23 @@ Assume they are a skilled developer, but know almost nothing about our toolset o
+ 
+ **Context:** This should be run in a dedicated worktree (created by brainstorming skill).
+ 
+-**Save plans to:** `docs/plans/YYYY-MM-DD-<feature-name>.md`
++**Save plans to:** `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`
++- (User preferences for plan location override this default)
++
++## Scope Check
++
++If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.
++
++## File Structure
++
++Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.
++
++- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
++- You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Prefer smaller, focused files over large ones that do too much.
++- Files that change together should live together. Split by responsibility, not by technical layer.
++- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure - but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.
++
++This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.
+ 
+ ## Bite-Sized Task Granularity
+ 
+@@ -33,7 +49,7 @@ Assume they are a skilled developer, but know almost nothing about our toolset o
+ ```markdown
+ # [Feature Name] Implementation Plan
+ 
+-> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.
++> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.
+ 
+ **Goal:** [One sentence describing what this builds]
+ 
+@@ -54,7 +70,7 @@ Assume they are a skilled developer, but know almost nothing about our toolset o
+ - Modify: `exact/path/to/existing.py:123-145`
+ - Test: `tests/exact/path/to/test.py`
+ 
+-**Step 1: Write the failing test**
++- [ ] **Step 1: Write the failing test**
+ 
+ ```python
+ def test_specific_behavior():
+@@ -62,24 +78,24 @@ def test_specific_behavior():
+     assert result == expected
+ ```
+ 
+-**Step 2: Run test to verify it fails**
++- [ ] **Step 2: Run test to verify it fails**
+ 
+ Run: `pytest tests/path/test.py::test_name -v`
+ Expected: FAIL with "function not defined"
+ 
+-**Step 3: Write minimal implementation**
++- [ ] **Step 3: Write minimal implementation**
+ 
+ ```python
+ def function(input):
+     return expected
+ ```
+ 
+-**Step 4: Run test to verify it passes**
++- [ ] **Step 4: Run test to verify it passes**
+ 
+ Run: `pytest tests/path/test.py::test_name -v`
+ Expected: PASS
+ 
+-**Step 5: Commit**
++- [ ] **Step 5: Commit**
+ 
+ ```bash
+ git add tests/path/test.py src/path/file.py
+@@ -94,23 +110,38 @@ git commit -m "feat: add specific feature"
+ - Reference relevant skills with @ syntax
+ - DRY, YAGNI, TDD, frequent commits
+ 
+-## Execution Handoff
++## Plan Review Loop
++
++After completing each chunk of the plan:
++
++1. Dispatch plan-document-reviewer subagent (see plan-document-reviewer-prompt.md) with precisely crafted review context — never your session history. This keeps the reviewer focused on the plan, not your thought process.
++   - Provide: chunk content, path to spec document
++2. If ❌ Issues Found:
++   - Fix the issues in the chunk
++   - Re-dispatch reviewer for that chunk
++   - Repeat until ✅ Approved
++3. If ✅ Approved: proceed to next chunk (or execution handoff if last chunk)
+ 
+-After saving the plan, offer execution choice:
++**Chunk boundaries:** Use `## Chunk N: <name>` headings to delimit chunks. Each chunk should be ≤1000 lines and logically self-contained.
+ 
+-**"Plan complete and saved to `docs/plans/<filename>.md`. Two execution options:**
++**Review loop guidance:**
++- Same agent that wrote the plan fixes it (preserves context)
++- If loop exceeds 5 iterations, surface to human for guidance
++- Reviewers are advisory - explain disagreements if you believe
\ No newline at end of file
