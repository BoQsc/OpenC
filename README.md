# OpenC

OpenC is a new open systems language: C-shaped, not C-compatible; safe by default; explicit about unsafe memory; and designed for referenceable rules, strong diagnostics, and executable validation.

This branch implements the first post-specification milestone for **OpenC Core Candidate 1**:

```text
CC1-M1-parser
```

The milestone compiles a multi-module D lexer and recursive-descent parser, then executes an exact 22-fixture gate through a machine-readable adapter. It is deliberately not a full compiler or conformance claim.

See:

- `docs/CC1_M1_PARSER.md`
- `implementation/d/README.md`
- `.github/workflows/cc1-m1-d-parser.yml`
