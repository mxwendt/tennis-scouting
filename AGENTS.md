# Development philosophy

- Prefer simple solutions over clever ones.
- Write code that is clear and self-explanatory.
- Build with the long term in mind.

# Stack

All application and test code is written in **Elm**.  Elm is a purely
functional language with no runtime exceptions, strict immutability, and an
enforced Model-Update-View architecture (The Elm Architecture, TEA).

For styling use the **Tailwind CSS** framework.

# Conventions

- Use a pure functional paradigm, strong static types, no side-effects in business logic.
- No `null` / `undefined`. Use `Maybe` and `Result` instead.
- No runtime exceptions. Compiler guarantees eliminate whole classes of bugs.
- Data is immutable. All updates return new values; records use `{ record \| field = value }` syntax.
- Use `case … of` everywhere for pattern matching; the compiler forces exhaustive branches
- Each file is one module; explicit `exposing` controls public API
- The entry point is `src/Main.elm`

# Verification

After making changes, always run the following checks and fix any issues before considering work complete:

1. **Format**: `npm run format` (elm-format)
1. **Review**: `npm run review:fix` (elm-review)
3. **Tests**: `npm test` (elm-test)
