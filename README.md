# OpenC

OpenC is a new open systems language: C-shaped, not C-compatible; safe by default; explicit about unsafe memory; and designed for referenceable rules, strong diagnostics, and executable validation.

This branch implements the first two post-specification milestones for **OpenC Core Candidate 1**:

```text
CC1-M1-parser
CC1-M2-core-syntax
```

The implementation is a standard-library-only, multi-module D lexer and recursive-descent syntax frontend.

CC1-M2 expands the fixed 22-fixture parser gate to every UTF-8 source unit in the Core Candidate 1 source, runtime, and multi-source fixture corpus:

```text
Core UTF-8 source units:      307
expected syntax acceptance:   287
expected syntax rejection:     20
separate malformed UTF-8 case:  1
```

Every accepted unit receives a deterministic structural syntax tree. The gate is executed twice in CI and the complete JSON reports must be byte-identical.

This milestone does **not** claim semantic analysis, type checking, ownership checking, code generation, or Core conformance.

See:

- `docs/CC1_M1_PARSER.md`
- `docs/CC1_M2_CORE_SYNTAX.md`
- `implementation/d/README.md`
- `.github/workflows/cc1-m1-d-parser.yml`
