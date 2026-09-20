# AI Agent Obedience Engineering - Make AI Work After Reading a Workflow

> Source: 2026 multi-source synthesis (Anthropic Skill Engineering, Microsoft Code Words, Strands Steering Hooks, Gradient Flow Harness Engineering)
> Applicable scenarios: AI coding agents (Claude Code / Codex / Cursor / Cline / Windsurf / Kiro) that only confirm after reading README/RULES.md, skip steps, or omit key operations without approval.

---

## Core Problem Diagnosis

The root cause of an AI agent reading a workflow but not acting is not model capability. Natural-language instructions leave room for semantic escape.

| Root cause | Explanation |
|------|------|
| **Context attention decay** | In long documents, the LLM gives less weight to content in the middle. The agent mostly sees the start and end. |
| **Semantic override** | When the model optimizes for "helpfulness," it creatively reinterprets explicit instructions. For example, it treats MUST DO X as "suggest doing X." |
| **Passive language treated as optional** | The agent treats "Ready for next step -> invoke X" as a suggestion instead of an instruction. |
| **Stateless enforcement** | Without an external state machine to verify workflow order, the agent can skip steps without detection. |
| **Silent state corruption** | The agent produces a structurally valid but semantically wrong result. The error accumulates silently. |

---

## Technique 1: Critical-First Pattern

**Put the next action first. Put the context after it.**

```
WRONG (Agent ignores it):
  [70 lines of project context and tool list]
  -> "Next step: run bootstrap to install missing tools"

CORRECT (Agent executes it):
  "## Execute now: run `bootstrap-reverse.ps1` to check and install missing tools
   -> After completion, read routing.md to determine which skill to enter"
  [Then provide the project context and tool list]
```

**Principle**: LLMs give the highest attention weight to the start and end of a prompt. They may ignore the middle completely.

**Application to this project**:
- Put the RULES.md "routing entry" section after the trigger keywords and before the execution principles.
- Make the first section of each SKILL.md "Execute now," not "Applicable scenarios."

---

## Technique 2: Replace Suggestive Language with Directives

Replace all suggestive language with RFC 2119-level directives:

| Weak language (the agent may skip it) | Strong language (the agent must execute it) |
|---|---|
| "You can try..." | **MUST**: You must execute... |
| "Ready for next step -> invoke X" | **NOW**: Invoke X now. Do not wait for confirmation. |
| "You should read routing.md first" | **REQUIRED**: Read routing.md before entering any submodule. |
| "You can bootstrap if tools are missing" | **NO EXCUSE**: Call bootstrap when a tool is missing. Do not install tools manually or guess paths. |
| "Remember to update the field journal" | **CHECKLIST ENFORCED**: Check every Checklist item after the task. Do not claim completion before all items are complete. |
| "Should..." | **MUST** / **MUST NOT** |

**Key patterns**:
```
MUST - A violation means task failure.
MUST NOT - A violation means a security violation.
SHOULD - Explain the reason when you do not follow it.
MAY - This is truly optional.
```

---

## Technique 3: Excuse Rebuttal Table

**This is the key patch for this project.** AI agents generate "reasonable excuses" to skip steps when they meet resistance. List common excuses in advance and rebut each one:

| Common agent excuse | Rebuttal (mandatory action) |
|---|---|
| "I can skip this step and go straight to..." | **Do not skip it.** Every step in the behavior chain is required. If you think you can skip it, give the specific reason first. Let the user decide. |
| "I judge that this is not required." | **Your judgment does not apply here.** List the exact criteria you used. Explain why those criteria permit skipping an explicit step. |
| "The user probably does not need this." | **Never decide for the user.** Present every option. Mark the recommendation, but do not hide alternatives. |
| "I already know how to do this. I do not need to read X." | **Read X before acting.** X may contain constraints for this task. Reading it takes two seconds. |
| "I can skip this step in parallel to save time." | **The correct way to save time is to run independent steps in parallel. Do not skip steps. Run independent steps in parallel. Run dependent steps in order.** |
| "I used this tool before, so I know its path." | **Do not guess paths.** Get the actual path from tool-index. Install locations differ between machines. |
| "The task is almost complete. I do not need the Checklist." | **The only definition of completion is every Checklist item checked.** An unchecked task is not complete. |
| "I could not find tool-index, so I will guess the path." | **A missing file is 100 times safer than a wrong path.** Run refresh-tool-index.ps1 to generate tool-index when it is missing. |
| "The user did not explicitly request a report, so I will not write one." | **A report is the default.** Write a report after every security task unless the user explicitly says "do not write a report." |
| "This task is simple, so I do not need a journal entry." | **Simple tasks still provide useful lessons.** Record the task type, tools used, and unexpected results. One line is enough. |
| "The user asked me to redo the import table or another step, but I did a different useful step." | **Redo means redo the named step** or an approved prerequisite path. Update the matching Evidence. Do not use an unrelated step as a substitute. Do not skip the step silently. Unpacking is a prerequisite for a readable IAT. It is not a substitute for import Evidence. |
| "The user said not to unpack the packed sample yet and to inspect the import table first. I can submit a fake table as complete." | **Feasibility gate:** When X is blocked, state the block and recommend an order. **Ask the user to confirm.** If the user insists, execute and mark `quality=unreadable/packed`. Do not use a fake table to deny capability. |
| "The unpacked sample crashes, so I will keep editing the file on disk." | **Patch 6:** Record E-self-check-crash / E-iat-repair-fail. Switch to dynamic analysis and set breakpoints on CreateFile/GetFileSize. Do not edit the file statically forever. |
| "IAT repair failed, so I will try several more static packer tools." | **IAT repair rule:** Prefer automatic or semi-automatic repair. If the tool errors or the repaired sample does not run, stop static IAT work immediately. Record E-iat-repair-fail. Switch to dynamic API breakpoints and capture imports. Do not continue static work without limit. |
| ".NET has no import table, so the hard gate does not apply. I will skip it." | **An equivalent anchor is still MUST.** For .NET, write a dnSpy/IL/metadata summary into the E-imports semantic slot. List E-exports for DLL/SYS files. Do not pass an empty slot. |

**Use**: Put this table near the end of RULES.md or another instruction file. This is a high-attention area. The agent sees the rebuttal before it creates an excuse.

---

## Technique 4: Five Skill Engineering Modes (Anthropic 2026 Official)

| Mode | Applicable scenario | Key technique |
|---|---|---|
| **Linear Flow** | A clear sequence, such as deployment or installation | Provide safe defaults. Use negative instructions such as "MUST NOT use --force." |
| **Decision Tree** | Platform navigation or fault diagnosis | Use tree navigation and progressive loading from `references/`. |
| **Iterative Loop** | TDD or review-and-fix loops | Put hard rules first. Use the **excuse rebuttal table** to block shortcuts. |
| **Baton Loop** | Multi-session or multi-agent collaboration | Externalize state in `next-prompt.md`. MUST write it before exit. |
| **Multi-Phase + Checkpoints** | A complex workflow over several days | Use a parent skill as the coordinator. Add human Go/No-Go checkpoints and mark time cost. |

**Project mapping**:
- Complete behavior chain = Linear Flow (execute 15 steps in order)
- Routing matrix = Decision Tree (match three dimensions)
- Checklist = Multi-Phase Checkpoint (check every step)
- Field Journal = Baton Loop (externalize state across sessions)

---

## Technique 5: In-Band Validation (Steering Hooks Concept)

Do not rely on AI self-discipline. Embed self-check instructions in the prompt:

```
Before claiming task completion, MUST check:
1. Did I skip any step in the behavior chain? Which step?
2. Did I guess any tool path? If yes, what path does tool-index show?
3. Are all Checklist items checked? Why is any item unchecked?
4. If any answer above is "yes" or "unchecked," the task is not complete.
   Return to the matching step. Execute it again. Do not claim completion.
```

This method makes the agent audit itself before it says "done." It is more immediate than external validation.

---

## Technique 6: Opaque Identifiers (Code Words) for API and Tool Parameters

Microsoft's 2026 research found that semantic parameter names trigger a model's tendency to "optimize" helpfully.

```
WRONG: { "query": "...", "top": 9 }        -> 68.4% parameter adherence
CORRECT: { "query": "...", "code": "alpha" } -> 100% parameter adherence
```

**Application scenarios**:
- Use short codes instead of semantic parameters when bootstrap scripts need exact configuration.
- Use code words for tool-call parameters that require strict guarantees.

---

## Technique 7: Dual Validation

```
AI A (executor) writes the output
  ↓
AI B (reviewer) checks the rules
  ↓ pass
Send the output to the user
  ↓ fail
Return it to AI A for correction with exact violation references
```

**Application in this project**:
- Embed a "self-review" step in RULES.md. The agent checks every Checklist item against the rules before it outputs a report.
- If the agent finds an incomplete item, it returns to the matching step and completes it.

---

## Technique 8: Optimize Context-Window Layout

LLM attention distribution (high to low):
```
[First 10%] ████████████ <- highest attention; put "execute now" instructions here
[Middle 80%]  ████░░░░░░░░ <- attention declines; put reference material here
[Last 10%] ████████████ <- attention rises; put "do not skip" and the Checklist here
```

**Specific application**:
1. **First 10%**: Execute-now instructions and trigger keywords.
2. **Middle 80%**: Detailed workflow, reference links, and tool list.
3. **Last 10%**: Excuse rebuttal table, hard Checklist, and prohibited actions.

---

## Practical Prompt Templates

### Template A: Forced Start Template (embed at the start of RULES.md)

```markdown
## CRITICAL: Execute these actions immediately after reading this document (do not only confirm; execute them)

1. **NOW**: Detect the directory that contains this file. This is the package root.
2. **NOW**: If this is the first use, write this rule to the global configuration (see the global injection section).
3. **NEXT**: Read `skills/SKILL.md` -> `skills/routing.md`. Determine which sub-skill to enter.
4. **NEXT**: Read `skills/tool-index.md`. Confirm tool status.
5. **THEN**: Start the actual task. Do not stop at an "already read" state.

If you only reply "read," "complete," or "I understand" without executing the actions above,
you have failed. The user needs the tools installed, the code analyzed, and the vulnerabilities verified.
The user does not need a confirmation message.
```

### Template B: Submodule Entry Template (embed at the start of each SKILL.md)

```markdown
## ACTION REQUIRED (execute immediately after reading; do not wait)

After reading this file:
1. Confirm that you understand this skill's applicable scenarios.
2. Check whether this machine has the required tools. Read `../tool-index.md`.
3. If a tool is missing, call bootstrap.
4. If tools are available, start the first workflow step.
5. If you are uncertain, list the exact questions. Do not stay silent.
```

### Template C: Task Completion Self-Check Template (embed at the end of each SKILL.md)

```markdown
## Task Completion Self-Check (MUST confirm every item before claiming completion)

□ I executed every step in the behavior chain. I did not skip any step.
□ I did not guess any tool path. Every path came from tool-index.md.
□ I produced reproducible commands, scripts, or a report. I did not only describe the steps.
□ I updated the field journal when I found a pitfall.
□ I ran the completion Checklist (report, charts, and lessons written back).
```

---

## Prohibited Actions (from the Agent Obedience Perspective)

- Do not read RULES.md and reply only, "Understood. Tell me the specific task."
  -> Correct action: run global injection, read SKILL.md, read routing.md, and determine the entry point.
- Do not say, "Steps 1-4 are complete," when you only read them once.
  -> Correct action: distinguish "document read" from "operation executed." The latter produces an actual side effect.
- Do not claim task completion before running the Checklist.
  -> The Checklist is the only definition of task completion.
- Do not use "based on experience" instead of reading tool-index.
  -> Paths differ between machines. Reading tool-index is the only way to locate a path.

---

## Summary: If You Can Change Only One Thing

**Add an "execute now" instruction at the start of RULES.md.** Use strong directive words such as CRITICAL and NOW.

This change has the best cost-benefit ratio. Most agent inactivity comes from entering "wait for user instructions" mode after reading a file. A forced "execute now" instruction can break that mode.

If you can change a second thing, **add the excuse rebuttal table**. Agents look for excuses at the first obstacle. Block those excuses in advance.
