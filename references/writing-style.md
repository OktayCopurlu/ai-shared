# Technical Writing Style

Prose quality rules for all agent-written text: documentation, PR descriptions, commit messages, ticket descriptions, and review comments. These rules apply whenever the agent writes for a human audience, not just code.

## Core Principles

- **Active voice, present tense.** One sentence communicates one idea.
- **Plain language over jargon.** Write for a mixed audience where half are non-native English speakers.
- **Concise over comprehensive.** Shorter text gets read. Longer text gets skimmed or skipped.

## Sentence Structure

- Keep sentences under 25 words when possible
- Limit embedded clauses to one level — do not nest subclauses inside subclauses
- Keep noun phrases short — avoid stacking three or more modifiers before a noun
- Use transition words (`however`, `therefore`, `because`, `instead`) to show logic rather than expecting readers to infer it
- Spread new ideas across sentences — do not pack multiple concepts into one

## Word Choice

- Prefer common words over technical synonyms (`use` not `utilize`, `start` not `initialize`, `show` not `render` in user-facing text)
- Do not use contractions in documentation (`do not` not `don't`) — contractions are fine in casual text like commit messages
- Avoid hedge words (`somewhat`, `fairly`, `quite`, `relatively`) — either the statement is true or qualify it precisely
- Avoid filler phrases (`it should be noted that`, `in order to`, `the fact that`, `at this point in time`) — cut them

## Formatting

- **Bold** for UI elements, key terms on first use, and emphasis — not for decoration
- `Monospace` for code, file paths, commands, environment variables, HTTP methods, and status codes
- Use numbered lists for sequential steps, bullet lists for unordered items
- Do not end list items with a period unless they are complete sentences
- Headings must be sequential — H2 then H3 then H4, never skip levels
- Descriptive link text — never use "here", "click here", or "this page"

## Audience-Specific Rules

### PR Descriptions and Changesets

- Describe user-facing behavior changes in plain language
- Do not reference internal implementation details (function names, class names, variable names) unless they are part of the public API
- Lead with what changed and why, not how

### Commit Messages

- Imperative mood (`Add`, `Fix`, `Remove` — not `Added`, `Fixes`, `Removing`)
- First line under 72 characters
- Body explains why, not what — the diff shows what

### Documentation

- Lead with the most useful information — do not bury the answer after three paragraphs of context
- Use code blocks for commands — do not describe commands in prose
- Placeholder values: use `example.com` for domains, `192.0.2.0/24` for IPs, `<YOUR_VALUE>` for user-supplied values

### Review Comments

- Concise, technical, actionable
- Suggest a fix, not just a problem
- No style opinions when linters or formatters already cover it

## Common Rationalizations

| Rationalization | Reality |
|---|---|
| "More detail is always better" | Detail without structure is noise. Readers stop reading. |
| "The audience is technical, they'll figure it out" | Technical readers still prefer clear prose. Ambiguity wastes their time. |
| "I need passive voice to sound professional" | Passive voice hides the actor and adds words. Active voice is clearer and shorter. |

## Red Flags

- Sentences over 40 words
- Three or more stacked adjectives before a noun
- Paragraphs with no line breaks in PR descriptions
- Link text that says "here" or "this"
- Commit messages that only say "fix" or "update"
