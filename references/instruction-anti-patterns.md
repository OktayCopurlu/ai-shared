# Instruction Anti-Patterns

Things to avoid when writing SKILL.md, .prompt.md, AGENTS.md, or instructions.md. Each anti-pattern has been observed to degrade agent output quality in production.

Load this reference when creating or revising skills, prompts, or agent instructions.

## Hard Length Limits on Reasoning

Never add word or line count limits that constrain the agent's thinking or communication between tool calls.

**Bad:** "Keep text between tool calls to ≤25 words."
**Bad:** "Respond in under 3 sentences."

**Why:** Anthropic's April 2026 postmortem confirmed that adding "keep text between tool calls to ≤25 words" to Claude Code's system prompt caused a measurable 3% intelligence drop across evaluations. Hard limits force the model to compress reasoning rather than think clearly.

**Instead:** Use qualitative guidance: "Be concise," "Avoid filler," or "Focus on the what and why." Let the model decide appropriate length per situation.

## Conflicting or Ambiguous Constraints

Never introduce rules that tension with existing instructions without explicitly resolving the conflict.

**Bad:** Adding "always ask before proceeding" to a skill while global instructions say "search codebase before asking."
**Bad:** "Never use external libraries" alongside "use the best tool for the job."

**Why:** Agents resolve conflicts by picking whichever instruction appears closest in context, or by drifting toward the path of least resistance — silently violating one constraint while appearing to follow the other. This produces inconsistent behavior that is hard to debug.

**Instead:** When adding a rule that could conflict, explicitly state its precedence: "This overrides X when Y condition is met." Remove or update the conflicting rule.

## Vague Behavioral Directives Without Criteria

Never write instructions the agent cannot objectively evaluate.

**Bad:** "Write clean code." (What counts as clean?)
**Bad:** "Use good judgment." (By what standard?)
**Bad:** "Keep it simple." (Relative to what?)

**Why:** Agents cannot introspect on vague quality attributes. They optimize for surface patterns associated with the words rather than the intent behind them. This produces code that looks clean but may not be, or decisions that appear reasonable but miss the actual goal.

**Instead:** Provide concrete, checkable criteria: "Functions ≤40 lines," "No more than 3 parameters," "Each module has one export." The agent can verify compliance.

## Counting and Measurement Instructions

Never ask the agent to count tokens, lines, characters, or complexity metrics while generating output.

**Bad:** "If the file exceeds 200 lines, split it."
**Bad:** "Keep context under 50% of the window."

**Why:** LLMs cannot accurately count during generation. They will either ignore the rule or apply it inconsistently, creating false confidence that a threshold was respected.

**Instead:** Use tooling to measure (linters, validators, CI checks) and instruct the agent to run those tools. Or use qualitative proxies: "If a function requires scrolling to read, it's too long."

## Exhaustive Enumerations That Will Drift

Never maintain a complete list of tool names, API endpoints, or version numbers inline in a skill if the source can change.

**Bad:** Listing all 43 Playwright MCP tools in a skill.
**Bad:** Pinning to "v2.1.4" without a mechanism to detect staleness.

**Why:** Exhaustive lists become stale silently. When reality drifts from documentation, the agent either uses phantom tools (causing errors) or ignores real capabilities.

**Instead:** Document selection heuristics, representative examples, and capability categories. Link to the source of truth for exhaustive details. Use version ranges or "last verified" dates.

## Over-Specifying the Path Instead of the Goal

Never write multi-step recipes for tasks where the model should adapt to context.

**Bad:** "Step 1: open file. Step 2: find the function. Step 3: add the import. Step 4: ..."
**Bad:** Rigid numbered workflows for creative or exploratory tasks.

**Why:** Over-specified paths make the agent follow the recipe even when the situation demands deviation. This is the source of "less human AI agents, please" complaints — the agent negotiates around constraints rather than flagging that the path doesn't fit.

**Instead:** State the goal and constraints. Use steps only when ordering genuinely matters (e.g., "commit before push," "run tests before marking complete"). For everything else, trust the model to find the path.

## Mixing Activation Guidance with Execution Rules

Never put "when to use this skill" logic deep inside the execution body.

**Bad:** Burying "only activate when the user says 'debug'" in paragraph 4 of a skill.

**Why:** Agents discover skills by reading the `description` frontmatter and the first section. If activation conditions are scattered or buried, the skill will be triggered at wrong times or never triggered at all.

**Instead:** Put all activation logic in the frontmatter `description` and the "When to Use" / "When NOT to Use" section at the top. The body should assume the skill is already active.
