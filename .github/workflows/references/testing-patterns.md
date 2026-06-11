# Testing Patterns

Quick-reference for test structure, naming, and common patterns. Referenced by `reviewing-code` (Layer 2) and `applying-coding-style` (Testing Style).

## Test Pyramid

```
        ╱ E2E ╲              ~5%   — Playwright, Cypress
       ╱───────╲
      ╱ Integr. ╲           ~15%  — Component tests, API tests
     ╱───────────╲
    ╱   Unit Tests ╲         ~80%  — Vitest, Jest
   ╱─────────────────╲
```

Prefer unit tests for logic. Use integration tests for component behavior. Reserve E2E for critical user flows.

## Test Structure

```typescript
describe('ComponentName', () => {
  describe('when condition is met', () => {
    it('does the expected thing', () => {
      // Arrange
      const input = createInput({ overrides });

      // Act
      const result = doThing(input);

      // Assert
      expect(result).toBe(expected);
    });
  });

  describe('when error occurs', () => {
    it('handles the failure gracefully', () => {
      // ...
    });
  });
});
```

## Naming Conventions

- `describe` blocks: noun (component/function name) or `when ...` (scenario)
- `it` blocks: present tense behavior — `it('renders the error message')` not `it('should render error message')`
- Test files: colocated — `Button.test.ts` next to `Button.vue`

## What to Test

| Priority | What | Example |
|----------|------|---------|
| 1 | Happy path | User submits form → success message shown |
| 2 | Business rules / invariants | Discount stacking order, price rounding, inventory never goes negative, auth boundaries |
| 3 | Most likely error | API returns 500 → error state rendered |
| 4 | Input boundaries | Empty string, null, max length |
| 5 | State transitions | Loading → success, loading → error |
| 6 | Edge cases | Only when a bug proves the gap matters |

## LLM Output And Prompt Evals

Use this when the change affects prompts, agent instructions, RAG behavior, tool selection, generated copy, or LLM-mediated decisions.

Start with error analysis, not a generic score. Review real traces or representative examples, identify the failure modes that actually matter, then write the cheapest eval that would catch those failures.

Prefer evals in this order:

1. **Deterministic assertions** — schema validity, required fields, forbidden strings, refusal behavior, tool-call shape, or executable output checks.
2. **Domain-specific pass/fail labels** — one clear quality dimension per label, such as faithfulness, policy compliance, or correct tool choice.
3. **LLM-as-judge** — only when the behavior is subjective or too variable for code assertions; validate the judge against human labels before trusting it.
4. **Experiment harness** — for repeated prompt/model/retrieval changes; run the same labeled examples against each variant and track regressions over time.

Do not start with broad metrics like "helpfulness", "quality", or similarity unless they are only exploration signals for finding traces to inspect. A high generic score is not evidence that the product behavior is correct.

### Eval Data Rules

- Keep labels binary where possible: pass/fail, win/lose/tie, or one failure category at a time.
- Include enough fail cases to stress the behavior; a dataset that mostly passes is weak regression protection.
- Prefer organic failures from production, QA, dogfooding, or smaller-model outputs before relying on synthetic defects.
- When synthetic data is useful, generate structured scenario tuples first, then turn them into natural-language inputs so coverage does not collapse into repetitive examples.
- Hold back a small test set when tuning an LLM judge or prompt, so improvements are not only overfit to the examples used during iteration.

### When To Add An Eval

- Add a cheap deterministic assertion as soon as the success condition is objective.
- Add an LLM judge only after the failure mode recurs and cannot be fixed by clarifying the prompt, schema, retrieval, or tool contract.
- Add a harness when the team expects to compare multiple prompts, models, retrieval settings, or agent policies over time.
- Do not build eval infrastructure for a one-off issue that can be fixed and manually verified faster than the eval can be maintained.

## Accessibility Contracts

When testing rendered UI, prefer queries that prove the user-facing accessibility contract instead of DOM structure.

- Find interactive elements by role and accessible name: `getByRole('button', { name: 'Submit' })`.
- Find form controls by label: `getByLabelText('Email')` or Playwright's `getByLabel('Email')`.
- Use text queries for non-interactive content and `alt` queries for meaningful images.
- Use test IDs only when role, label, text, or alt text cannot express the behavior under test.
- For custom widgets, assert the promised keyboard and focus behavior: Tab reachability, Enter/Space activation for buttons, arrow-key movement for menus/listboxes, and focus return after dialogs close.
- If a role or label query is impossible, treat that as an accessibility smell before adding a test ID.

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Snapshot-only tests | Don't verify behavior. Break on any change. | Add behavioral assertions alongside or instead. |
| Testing implementation | Asserting on internal state, method calls, or DOM structure | Test observable output — what the user sees or what the function returns. |
| CSS/XPath selectors for UI behavior | Ties tests to invisible DOM structure and misses broken accessible names. | Query by role/name, label, text, or alt text first. |
| Test ID as first choice | Test passes even when users or assistive tech cannot find the control. | Use a test ID only after semantic queries cannot express the contract. |
| Mocking everything | Tests pass but prove nothing — they test the mocks. | Mock only external boundaries (APIs, timers). Keep internal logic real. |
| Asserting on mock returns | `expect(mockFn()).toBe(mockReturnValue)` proves nothing. | Assert on the behavior triggered by the mock, not the mock itself. |
| Shared mutable state | Tests depend on execution order. Flaky. | Isolate state per test. Use factory functions. |
| Giant beforeEach | Setup longer than the test. Hard to read, hard to modify. | Extract a factory with sensible defaults. Override per test. |
| No error path tests | Happy path only. Bugs hide in error handling. | Always test the most likely failure mode. |
| Hand-rolled stub components | Stub template duplicates production logic; test verifies the stub, not the real component. | Use `stubs: { Child: true }` and assert on `findComponent({ name }).props(...)`. |
| Many assertions in one `it` | Failure message hides which behavior broke. | One behavior per `it`. Move shared arrange/act into `beforeEach`. |
| Hardcoded values that duplicate the fixture | Fixture changes silently desync from tests. | Derive expected values from the fixture. |
| Optional chaining inside `expect(...).toBe(...)` | `undefined === undefined` passes when the path disappears. | Tighten fixture types, or `expect(value).toBeDefined()` before the equality assertion. |

## Vue Component Testing

```typescript
// Mount with minimal props — override only what the test needs
const wrapper = mount(MyComponent, {
  props: { title: 'Test' },
  global: {
    stubs: { ExternalDep: true },
  },
});

// Assert on user-visible output
expect(wrapper.text()).toContain('Test');

// Simulate user interaction
await wrapper.find('button').trigger('click');
expect(wrapper.emitted('submit')).toHaveLength(1);
```

### Stub Strategy for Child Components

Prefer **auto-stubs** (`stubs: { Child: true }`) over hand-rolled stub components.

| Approach | When to use | Risk |
|---|---|---|
| `stubs: { Child: true }` | Default. Unit-testing the parent in isolation. | None — keeps the boundary clean. |
| Custom stub component | Only when you need the stub to emit events the parent listens to and `vm.$emit` from the test is not enough. | Stub template often duplicates production logic (e.g. `:href="disabled ? undefined : url"`). Test then verifies your stub, not the real component. |

When children are stubbed, assert on the **props passed to the child**, not on text rendered by the stub:

```typescript
// ✅ Tests the real contract: what the parent gives the child
const cta = wrapper.findComponent({ name: 'Button' });
expect(cta.props('url')).toBe(expectedPdpUrl);
expect(cta.props('disabled')).toBe(false);

// ❌ Tests the stub's own template, not the parent's behavior
expect(wrapper.find('[data-test-id="cta"]').attributes('href')).toBe(expectedPdpUrl);
```

Simulate child emits directly when the DOM is stubbed away:

```typescript
await wrapper.findComponent({ name: 'ProductSiblings' })
  .vm.$emit('update:activeSku', '3WG10960200');
```

### One Behavior Per `it`

Split assertions by behavior, not by setup. A test with 10+ assertions hides which contract broke when it fails.

```typescript
// ❌ One it, many unrelated assertions
it('shows the recommended colorway, product scales, and PDP link', () => {
  expect(badge.text()).toBe(...);
  expect(name.text()).toBe(...);
  expect(price).toContain(...);
  expect(image.attributes('src')).toBe(...);
  expect(cta.attributes('href')).toBe(...);
  // ...8 more
});

// ✅ Arrange once, assert one behavior per it
describe('when rendered', () => {
  let wrapper: ReturnType<typeof mountProductResultCard>;

  beforeEach(() => {
    wrapper = mountProductResultCard();
  });

  it('shows the best match badge', () => { /* one assertion group */ });
  it('renders the recommended colorway image', () => { /* ... */ });
  it('renders an enabled PDP link to the recommended colorway', () => { /* ... */ });
});
```

When the test's "act" step is shared (e.g. selecting a sibling), move it into `beforeEach` so each `it` asserts a single outcome of that action.

### Fixture Coupling and False Positives

- **Derive expected values from the fixture**, not from hardcoded duplicates. Hardcoding `'3WG10960106'` next to `PRODUCT_MATCH` means a fixture change has to be mirrored in every test.
- **Optional chaining in expectations silently passes when the path is missing**: `expect(src).toBe(PRODUCT_MATCH.product.items?.[0]?.colorSelector?.url)` becomes `undefined === undefined` if the fixture loses that shape. Either tighten the fixture's type so `?.` is unnecessary, or assert the value is defined first.
- **i18n key assertions** (`expect(...).toBe('shoeFinderBestMatch')`) only prove the `$t` mock returns its key. Acceptable, but it does not prove the user sees the right copy — flag this when the surface is user-facing.

## Factory Pattern

```typescript
function createProps(overrides: Partial<Props> = {}): Props {
  return {
    title: 'Default Title',
    isVisible: true,
    items: [],
    ...overrides,
  };
}

// Each test overrides only what matters
it('hides when not visible', () => {
  const wrapper = mount(Component, {
    props: createProps({ isVisible: false }),
  });
  expect(wrapper.isVisible()).toBe(false);
});
```
