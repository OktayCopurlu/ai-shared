# Testing Patterns

Quick-reference for test structure, naming, and common patterns. Referenced by `code-review` (Layer 2) and `coding-style` (Testing Style).

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
| 2 | Most likely error | API returns 500 → error state rendered |
| 3 | Input boundaries | Empty string, null, max length |
| 4 | State transitions | Loading → success, loading → error |
| 5 | Edge cases | Only when a bug proves the gap matters |

## Anti-Patterns

| Pattern | Problem | Fix |
|---------|---------|-----|
| Snapshot-only tests | Don't verify behavior. Break on any change. | Add behavioral assertions alongside or instead. |
| Testing implementation | Asserting on internal state, method calls, or DOM structure | Test observable output — what the user sees or what the function returns. |
| Mocking everything | Tests pass but prove nothing — they test the mocks. | Mock only external boundaries (APIs, timers). Keep internal logic real. |
| Asserting on mock returns | `expect(mockFn()).toBe(mockReturnValue)` proves nothing. | Assert on the behavior triggered by the mock, not the mock itself. |
| Shared mutable state | Tests depend on execution order. Flaky. | Isolate state per test. Use factory functions. |
| Giant beforeEach | Setup longer than the test. Hard to read, hard to modify. | Extract a factory with sensible defaults. Override per test. |
| No error path tests | Happy path only. Bugs hide in error handling. | Always test the most likely failure mode. |

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
