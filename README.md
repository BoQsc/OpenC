# Open C Core 0.1 Alpha

**Status:** First runnable open-standard alpha release  
**License intent:** CC0 1.0 Universal for all original text, source code, tests, and metadata in this package  
**Normative authority:** This package is self-contained. Its public specification, rule database, conformance tests, and reference evaluator are the authority for **Open C Core 0.1 Alpha**.

---

## What this is

Open C Core 0.1 Alpha is the first concrete vertical slice of a fully open C-family language project. It is not a commentary on a closed standard and does not require a closed document to verify its behavior.

This package contains:

1. A human-readable normative specification.
2. A machine-readable rule database.
3. A formal-semantics sketch that matches the implemented fragment.
4. A reference evaluator written in Python's standard library only.
5. A public conformance test manifest and runnable test suite.
6. Governance, contribution, and legal-hygiene rules for continuing the project.

---

## Implemented language slice

The alpha defines and executes a deliberately small, coherent C-like subset:

- one program entry point: `int main(void) { ... }`
- local `int` variables
- decimal integer literals
- declarations with optional initializers
- assignment statements
- blocks and nested block scopes
- `return`
- `if` / `else`
- `while`
- arithmetic: `+ - * / %`
- unary: `- !`
- comparisons: `< <= > >= == !=`
- short-circuit logical operators: `&& ||`
- line and block comments
- exact diagnostic categories for lexical, syntax, and static errors
- runtime trap for division or remainder by zero

The value domain in this alpha is **mathematical signed integers** with no overflow. Fixed-width integers and target profiles are explicitly deferred.

---

## Repository layout

```text
open_c_core_0_1_alpha/
├─ README.md
├─ SPEC_OPEN_C_CORE_0_1_ALPHA.md
├─ RULE_DATABASE.json
├─ FORMAL_MODEL_CORE_0_1_ALPHA.md
├─ IMPLEMENTATION_REFERENCE_CORE_0_1_ALPHA.md
├─ CONFORMANCE_CORE_0_1_ALPHA.md
├─ GOVERNANCE.md
├─ CONTRIBUTING.md
├─ DECISION_LOG_CORE_0_1_ALPHA.md
├─ CHANGELOG.md
├─ LICENSE-CC0-NOTICE.txt
├─ reference/
│  ├─ README.md
│  └─ open_c_ref.py
├─ scripts/
│  └─ run_tests.py
└─ tests/
   ├─ manifest.tsv
   └─ cases/
      ├─ valid_return_zero.c
      ├─ valid_expression_precedence.c
      ├─ valid_if_true.c
      ├─ valid_while_countdown.c
      ├─ valid_assignment.c
      ├─ valid_shadowing.c
      ├─ invalid_unterminated_string.c
      ├─ invalid_missing_semicolon.c
      ├─ invalid_undeclared_identifier.c
      ├─ invalid_duplicate_variable.c
      ├─ invalid_bad_main_signature.c
      └─ trap_divide_by_zero.c
```

---

## How to run the reference evaluator

From this folder:

```text
python reference/open_c_ref.py tests/cases/valid_return_zero.c --json
```

Example JSON result:

```json
{"status":"ok","exit_status":0}
```

---

## How to run conformance tests

```text
python scripts/run_tests.py
```

The test runner exits with code `0` when every manifest case matches its expected status, exit result, and diagnostic/trap code.

---

## Authority model

For this alpha:

1. `SPEC_OPEN_C_CORE_0_1_ALPHA.md` is the primary human-readable normative text.
2. `RULE_DATABASE.json` assigns stable rule identifiers and records linked tests.
3. `reference/open_c_ref.py` is a reference evaluator, not a secret authority. If the evaluator conflicts with the spec, that is a public project defect to resolve.
4. `tests/manifest.tsv` records official alpha conformance expectations.

A future mature release should generate more artifacts from a unified structured semantic source, but this alpha already begins the rule-ID discipline needed for that transition.

---

## What this is not

- It is not the complete C language.
- It is not a claim of compatibility with any closed standard.
- It is not yet a production compiler.
- It does not define preprocessing macros, pointers, arrays, structs, functions beyond `main`, linkage, object layout, libraries, concurrency, floating-point, or ABI behavior.

Those are later work packages, to be added only when they can be specified, tested, and modeled openly.

---

## Next engineering milestone

The next milestone after this alpha should be **Open C Core 0.2**, focused on:

1. named helper functions and calls,
2. function parameters of `int` type,
3. `break` and `continue`,
4. a structured source-location model in diagnostics,
5. a stronger executable semantics document tied rule-by-rule to tests,
6. a first generator or linter for `RULE_DATABASE.json` and the test manifest.
