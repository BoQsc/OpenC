module cc1.lexer;

import cc1.diagnostic : fail;
import cc1.token : Token, TokenKind;
import std.ascii : isAlpha, isDigit, isAlphaNum;
import std.string : indexOf;

final class Lexer {
private:
    string source;
    size_t index;
    size_t line;
    size_t column;

public:
    this(string source) {
        this.source = source;
        this.index = 0;
        this.line = 1;
        this.column = 1;
    }

    Token[] lex() {
        Token[] tokens;

        while (!atEnd()) {
            skipIgnored();
            if (atEnd()) {
                break;
            }

            immutable startOffset = index;
            immutable startLine = line;
            immutable startColumn = column;
            immutable c = current();

            if (isWordStart(c)) {
                tokens ~= lexWord(startOffset, startLine, startColumn);
                continue;
            }

            if (isDigit(c)) {
                tokens ~= lexNumber(startOffset, startLine, startColumn);
                continue;
            }

            if (c == '"') {
                tokens ~= lexString(startOffset, startLine, startColumn);
                continue;
            }

            tokens ~= lexSymbol(startOffset, startLine, startColumn);
        }

        tokens ~= Token(TokenKind.eofToken, "<eof>", line, column, index);
        return tokens;
    }

private:
    bool atEnd() const {
        return index >= source.length;
    }

    char current() const {
        return source[index];
    }

    char peek(size_t distance = 1) const {
        immutable target = index + distance;
        return target < source.length ? source[target] : '\0';
    }

    void advance() {
        if (atEnd()) {
            return;
        }

        if (source[index] == '\n') {
            ++line;
            column = 1;
        } else {
            ++column;
        }
        ++index;
    }

    bool isWordStart(char c) const {
        return isAlpha(c) || c == '_';
    }

    bool isWordContinue(char c) const {
        return isAlphaNum(c) || c == '_';
    }

    void skipIgnored() {
        bool changed = true;
        while (changed && !atEnd()) {
            changed = false;

            while (!atEnd()) {
                immutable c = current();
                if (c == ' ' || c == '\t' || c == '\r' || c == '\n') {
                    advance();
                    changed = true;
                } else {
                    break;
                }
            }

            if (!atEnd() && current() == '/' && peek() == '/') {
                advance();
                advance();
                while (!atEnd() && current() != '\n') {
                    advance();
                }
                changed = true;
                continue;
            }

            if (!atEnd() && current() == '/' && peek() == '*') {
                immutable startLine = line;
                immutable startColumn = column;
                immutable startOffset = index;
                advance();
                advance();

                while (!atEnd() && !(current() == '*' && peek() == '/')) {
                    advance();
                }

                if (atEnd()) {
                    fail(
                        "OPENC-LEX-COMMENT-001",
                        "unterminated block comment",
                        startLine,
                        startColumn,
                        startOffset);
                }

                advance();
                advance();
                changed = true;
            }
        }
    }

    Token lexWord(size_t startOffset, size_t startLine, size_t startColumn) {
        advance();
        while (!atEnd() && isWordContinue(current())) {
            advance();
        }

        return Token(
            TokenKind.word,
            source[startOffset .. index],
            startLine,
            startColumn,
            startOffset);
    }

    Token lexNumber(size_t startOffset, size_t startLine, size_t startColumn) {
        while (!atEnd() && (isDigit(current()) || current() == '_')) {
            advance();
        }

        immutable text = source[startOffset .. index];
        if (text.length == 0 || text[0] == '_' || text[$ - 1] == '_' || text.indexOf("__") >= 0) {
            fail(
                "OPENC-LITERAL-SEPARATOR-001",
                "numeric separators must occur singly between digits",
                startLine,
                startColumn,
                startOffset);
        }

        if (!atEnd() && isWordStart(current())) {
            while (!atEnd() && isWordContinue(current())) {
                advance();
            }
            fail(
                "OPENC-LITERAL-NOSUFFIX-001",
                "numeric literal suffixes are not part of Core Candidate 1",
                startLine,
                startColumn,
                startOffset);
        }

        return Token(
            TokenKind.integerLiteral,
            text,
            startLine,
            startColumn,
            startOffset);
    }

    Token lexString(size_t startOffset, size_t startLine, size_t startColumn) {
        advance();
        bool escaped = false;

        while (!atEnd()) {
            immutable c = current();
            if (!escaped && c == '"') {
                advance();
                return Token(
                    TokenKind.stringLiteral,
                    source[startOffset .. index],
                    startLine,
                    startColumn,
                    startOffset);
            }

            if (!escaped && c == '\n') {
                fail(
                    "OPENC-LEX-STRING-001",
                    "text literal cannot contain an unescaped newline",
                    startLine,
                    startColumn,
                    startOffset);
            }

            if (!escaped && c == '\\') {
                escaped = true;
                advance();
                continue;
            }

            escaped = false;
            advance();
        }

        fail(
            "OPENC-LEX-STRING-001",
            "unterminated text literal",
            startLine,
            startColumn,
            startOffset);
    }

    Token lexSymbol(size_t startOffset, size_t startLine, size_t startColumn) {
        static immutable string[] twoCharacterSymbols = [
            "->", "==", "!=", "<=", ">=", "&&", "||",
            "+=", "-=", "*=", "/=", "%=", "<<", ">>", ".."
        ];

        if (index + 1 < source.length) {
            immutable pair = source[index .. index + 2];
            foreach (symbol; twoCharacterSymbols) {
                if (pair == symbol) {
                    advance();
                    advance();
                    return Token(
                        TokenKind.symbol,
                        symbol,
                        startLine,
                        startColumn,
                        startOffset);
                }
            }
        }

        immutable c = current();
        switch (c) {
            case '(':
            case ')':
            case '{':
            case '}':
            case '[':
            case ']':
            case ';':
            case ',':
            case '.':
            case ':':
            case '?':
            case '+':
            case '-':
            case '*':
            case '/':
            case '%':
            case '&':
            case '|':
            case '^':
            case '!':
            case '~':
            case '=':
            case '<':
            case '>':
                advance();
                return Token(
                    TokenKind.symbol,
                    source[startOffset .. index],
                    startLine,
                    startColumn,
                    startOffset);
            default:
                fail(
                    "OPENC-LEX-TOKEN-001",
                    "unexpected source character",
                    startLine,
                    startColumn,
                    startOffset);
        }
    }
}

Token[] lexSource(string source) {
    auto lexer = new Lexer(source);
    return lexer.lex();
}
