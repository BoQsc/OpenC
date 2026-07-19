module cc1.diagnostic;

import std.format : format;

struct Diagnostic {
    string rule;
    string message;
    size_t line;
    size_t column;
    size_t offset;
}

final class FrontendException : Exception {
    Diagnostic diagnostic;

    this(Diagnostic diagnostic) {
        super("%s at %s:%s: %s".format(
            diagnostic.rule,
            diagnostic.line,
            diagnostic.column,
            diagnostic.message));
        this.diagnostic = diagnostic;
    }
}

noreturn fail(
    string rule,
    string message,
    size_t line,
    size_t column,
    size_t offset
) {
    throw new FrontendException(Diagnostic(rule, message, line, column, offset));
}
