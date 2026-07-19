module cc1.parser;

import cc1.diagnostic : fail;
import cc1.token : Token, TokenKind;
import std.algorithm.searching : canFind;
import std.ascii : isUpper;

final class Parser {
private:
    Token[] tokens;
    size_t cursor;
    bool[string][] localScopes;

    static immutable string[] builtinTypes = [
        "void", "bool", "byte", "text", "status",
        "i8", "i16", "i32", "i64",
        "u8", "u16", "u32", "u64",
        "isize", "usize", "f32", "f64"
    ];

    static immutable string[] typePrefixes = [
        "ref", "ptr", "optional", "storage", "resource", "out", "own"
    ];

public:
    this(Token[] tokens) {
        this.tokens = tokens;
        this.cursor = 0;
    }

    void parseSource() {
        while (matchText("import")) {
            parseImportTail();
        }

        while (!atEnd()) {
            parseTopLevelDeclaration();
        }
    }

private:
    Token currentToken() const {
        return tokens[cursor];
    }

    Token peekToken(size_t distance = 1) const {
        immutable target = cursor + distance;
        return target < tokens.length ? tokens[target] : tokens[$ - 1];
    }

    bool atEnd() const {
        return currentToken().kind == TokenKind.eofToken;
    }

    bool checkText(string text) const {
        return !atEnd() && currentToken().text == text;
    }

    bool checkKind(TokenKind kind) const {
        return currentToken().kind == kind;
    }

    bool matchText(string text) {
        if (!checkText(text)) {
            return false;
        }
        ++cursor;
        return true;
    }

    Token consumeToken() {
        immutable token = tokens[cursor];
        if (!atEnd()) {
            ++cursor;
        }
        return token;
    }

    Token expectText(string text, string rule, string message) {
        if (!checkText(text)) {
            failAt(currentToken(), rule, message);
        }
        return consumeToken();
    }

    Token expectWord(string rule = "OPENC-SYNTAX-EXPECTED-001", string message = "expected a name") {
        if (!checkKind(TokenKind.word)) {
            failAt(currentToken(), rule, message);
        }
        return consumeToken();
    }

    noreturn failAt(Token token, string rule, string message) const {
        fail(rule, message, token.line, token.column, token.offset);
    }

    void parseImportTail() {
        expectWord("OPENC-MODULE-IMPORT-001", "expected module name after import");
        while (matchText(".")) {
            expectWord("OPENC-MODULE-IMPORT-001", "expected module path segment");
        }
        expectStatementSemicolon();
    }

    void parseTopLevelDeclaration() {
        while (matchText("export")) {
            // Visibility is syntax-only at this milestone.
        }

        if (checkText("func") || checkText("fn")) {
            failAt(
                currentToken(),
                "OPENC-FUNCTION-DIRECT-001",
                "OpenC functions use return-type-first declarations");
        }

        if (matchText("struct")) {
            parseStructDeclaration();
            return;
        }

        if (matchText("enum")) {
            parseEnumDeclaration();
            return;
        }

        parseType();
        immutable name = expectWord(
            "OPENC-DECL-TYPEFIRST-001",
            "expected declaration name after type");

        if (matchText("(")) {
            parseFunctionAfterName(name.text);
            return;
        }

        parseVariableTail(name.text, false);
    }

    void parseStructDeclaration() {
        expectWord("OPENC-STRUCT-DECL-001", "expected struct name");
        expectText("{", "OPENC-STRUCT-DECL-001", "expected '{' after struct name");

        while (!checkText("}") && !atEnd()) {
            parseType();
            expectWord("OPENC-STRUCT-DECL-001", "expected struct field name");
            if (matchText("=")) {
                parseExpression();
            }
            expectStatementSemicolon();
        }

        expectText("}", "OPENC-STRUCT-DECL-001", "expected '}' after struct declaration");
        if (checkText(";")) {
            failAt(
                currentToken(),
                "OPENC-STRUCT-TRAILING-001",
                "struct declarations do not use a trailing semicolon");
        }
    }

    void parseEnumDeclaration() {
        expectWord("OPENC-ENUM-DISTINCT-001", "expected enum name");
        expectText("{", "OPENC-ENUM-DISTINCT-001", "expected '{' after enum name");

        if (!checkText("}")) {
            do {
                expectWord("OPENC-ENUM-DISTINCT-001", "expected enum member name");
                if (matchText("=")) {
                    parseExpression();
                }
            } while (matchText(",") && !checkText("}"));
        }

        expectText("}", "OPENC-ENUM-DISTINCT-001", "expected '}' after enum declaration");
        if (checkText(";")) {
            failAt(
                currentToken(),
                "OPENC-ENUM-DISTINCT-001",
                "enum declarations do not use a trailing semicolon");
        }
    }

    void parseFunctionAfterName(string functionName) {
        string[] parameterNames;

        if (!checkText(")")) {
            do {
                parseType();
                immutable parameter = expectWord(
                    "OPENC-FUNCTION-PARAM-001",
                    "expected parameter name");
                parameterNames ~= parameter.text;
            } while (matchText(","));
        }

        expectText(")", "OPENC-FUNCTION-PARAM-001", "expected ')' after parameters");

        if (checkText("->")) {
            failAt(
                currentToken(),
                "OPENC-FUNCTION-DIRECT-001",
                "arrow return syntax is not OpenC function syntax");
        }

        parseBlock(parameterNames);
    }

    void parseBlock(string[] initialNames = null) {
        expectText("{", "OPENC-BLOCK-BRACES-001", "expected '{' to begin block");
        pushScope();
        foreach (name; initialNames) {
            declareLocal(name);
        }

        while (!checkText("}") && !atEnd()) {
            parseStatement();
        }

        expectText("}", "OPENC-BLOCK-BRACES-001", "expected '}' to end block");
        popScope();
    }

    void parseStatement() {
        if (matchText("return")) {
            if (!checkText(";")) {
                parseExpression();
            }
            expectStatementSemicolon();
            return;
        }

        if (matchText("unsafe")) {
            parseBlock();
            return;
        }

        if (matchText("scope")) {
            parseExpression();
            expectStatementSemicolon();
            return;
        }

        if (matchText("if")) {
            parseExpression();
            if (!checkText("{")) {
                failAt(
                    currentToken(),
                    "OPENC-BLOCK-BRACES-001",
                    "if bodies require explicit braces");
            }
            parseBlock();
            if (matchText("else")) {
                if (checkText("if")) {
                    parseStatement();
                } else {
                    if (!checkText("{")) {
                        failAt(
                            currentToken(),
                            "OPENC-BLOCK-BRACES-001",
                            "else bodies require explicit braces");
                    }
                    parseBlock();
                }
            }
            return;
        }

        if (matchText("while")) {
            parseExpression();
            if (!checkText("{")) {
                failAt(
                    currentToken(),
                    "OPENC-BLOCK-BRACES-001",
                    "while bodies require explicit braces");
            }
            parseBlock();
            return;
        }

        if (matchText("switch")) {
            parseSwitchTail();
            return;
        }

        if (matchText("break") || matchText("continue")) {
            expectStatementSemicolon();
            return;
        }

        if (checkText("{")) {
            parseBlock();
            return;
        }

        if (startsType()) {
            parseType();
            immutable name = expectWord(
                "OPENC-DECL-TYPEFIRST-001",
                "expected declaration name after type");
            parseVariableTail(name.text, true);
            return;
        }

        if (checkKind(TokenKind.word) && peekToken().text == "=" && !isLocalDeclared(currentToken().text)) {
            failAt(
                currentToken(),
                "OPENC-DECL-TYPEFIRST-001",
                "ordinary OpenC declarations require an explicit type");
        }

        parseExpression();
        expectStatementSemicolon();
    }

    void parseSwitchTail() {
        parseExpression();
        expectText("{", "OPENC-SWITCH-ENUM-001", "expected '{' after switch expression");

        while (!checkText("}") && !atEnd()) {
            if (matchText("case")) {
                parseExpression();
                if (!checkText("{")) {
                    failAt(
                        currentToken(),
                        "OPENC-BLOCK-BRACES-001",
                        "case bodies require explicit braces");
                }
                parseBlock();
                continue;
            }

            if (matchText("default")) {
                if (!checkText("{")) {
                    failAt(
                        currentToken(),
                        "OPENC-BLOCK-BRACES-001",
                        "default bodies require explicit braces");
                }
                parseBlock();
                continue;
            }

            failAt(
                currentToken(),
                "OPENC-SWITCH-ENUM-001",
                "expected case or default in switch body");
        }

        expectText("}", "OPENC-SWITCH-ENUM-001", "expected '}' after switch body");
    }

    void parseVariableTail(string name, bool local) {
        if (checkText("[")) {
            failAt(
                currentToken(),
                "OPENC-ARRAY-DECL-001",
                "array length belongs to the type before the variable name");
        }

        if (matchText("=")) {
            parseExpression();
        }
        expectStatementSemicolon();

        if (local) {
            declareLocal(name);
        }
    }

    bool startsType() const {
        if (!checkKind(TokenKind.word)) {
            return false;
        }

        immutable text = currentToken().text;
        if (builtinTypes.canFind(text) || typePrefixes.canFind(text)) {
            return true;
        }

        if (peekToken().kind == TokenKind.word) {
            return true;
        }

        return peekToken().text == "[" ||
            peekToken().text == "?" ||
            peekToken().text == "*" ||
            peekToken().text == "&";
    }

    void parseType() {
        if (matchText("ref")) {
            matchText("const");
            parseType();
            return;
        }

        if (matchText("ptr")) {
            matchText("const");
            parseType();
            return;
        }

        if (matchText("optional") || matchText("storage") || matchText("resource") ||
            matchText("out") || matchText("own")) {
            parseType();
            return;
        }

        if (!checkKind(TokenKind.word)) {
            failAt(
                currentToken(),
                "OPENC-DECL-TYPEFIRST-001",
                "expected an explicit OpenC type");
        }

        consumeToken();

        if (checkText("?")) {
            failAt(
                currentToken(),
                "OPENC-OPTIONAL-NOSHORTHAND-001",
                "optional values use the word-shaped optional type constructor");
        }

        if (checkText("*")) {
            failAt(
                currentToken(),
                "OPENC-PTR-SYMBOL-001",
                "raw pointer declarations use ptr T, not T*");
        }

        if (checkText("&")) {
            failAt(
                currentToken(),
                "OPENC-REF-SYMBOL-001",
                "safe reference declarations use ref T, not T&");
        }

        while (matchText("[")) {
            if (!matchText("]")) {
                if (!checkKind(TokenKind.integerLiteral)) {
                    failAt(
                        currentToken(),
                        "OPENC-ARRAY-TYPE-001",
                        "fixed array type requires an integer length");
                }
                consumeToken();
                expectText("]", "OPENC-ARRAY-TYPE-001", "expected ']' after array length");
            }
        }
    }

    void parseExpression() {
        parseAssignment();
    }

    void parseAssignment() {
        parseBinary(0);
        if (isAssignmentOperator(currentToken().text)) {
            consumeToken();
            parseAssignment();
        }
    }

    void parseBinary(int minimumPrecedence) {
        parseUnary();

        while (true) {
            immutable precedence = binaryPrecedence(currentToken().text);
            if (precedence < minimumPrecedence) {
                break;
            }

            consumeToken();
            parseBinary(precedence + 1);
        }
    }

    void parseUnary() {
        if (checkText("!") || checkText("-") || checkText("+") || checkText("~") ||
            checkText("&") || checkText("*")) {
            consumeToken();
            parseUnary();
            return;
        }

        parsePostfix();
    }

    void parsePostfix() {
        bool canInitializeStruct = parsePrimary();

        while (true) {
            if (matchText("(")) {
                if (!checkText(")")) {
                    do {
                        parseExpression();
                    } while (matchText(","));
                }
                expectText(")", "OPENC-CALL-TYPE-001", "expected ')' after arguments");
                canInitializeStruct = false;
                continue;
            }

            if (matchText(".")) {
                expectWord("OPENC-NAME-UNKNOWN-001", "expected member name after '.'");
                canInitializeStruct = false;
                continue;
            }

            if (matchText("[")) {
                parseExpression();
                expectText("]", "OPENC-ARRAY-INDEX-001", "expected ']' after index expression");
                canInitializeStruct = false;
                continue;
            }

            if (checkText("{") && canInitializeStruct) {
                parseStructInitializer();
                canInitializeStruct = false;
                continue;
            }

            break;
        }
    }

    bool parsePrimary() {
        if (matchText("(")) {
            parseExpression();
            expectText(")", "OPENC-SYNTAX-EXPECTED-001", "expected ')' after expression");
            return false;
        }

        if (checkText("{")) {
            parseArrayInitializer();
            return false;
        }

        if (checkKind(TokenKind.integerLiteral) || checkKind(TokenKind.stringLiteral)) {
            consumeToken();
            return false;
        }

        if (checkKind(TokenKind.word)) {
            immutable token = consumeToken();
            if (token.text == "true" || token.text == "false" ||
                token.text == "null" || token.text == "none") {
                return false;
            }

            return token.text.length > 0 && isUpper(token.text[0]);
        }

        failAt(
            currentToken(),
            "OPENC-SYNTAX-EXPRESSION-001",
            "expected expression");
    }

    void parseArrayInitializer() {
        expectText("{", "OPENC-ARRAY-INIT-001", "expected '{' for initializer");
        if (!checkText("}")) {
            do {
                parseExpression();
            } while (matchText(",") && !checkText("}"));
        }
        expectText("}", "OPENC-ARRAY-INIT-001", "expected '}' after initializer");
    }

    void parseStructInitializer() {
        expectText("{", "OPENC-STRUCT-INIT-001", "expected '{' for struct initializer");
        if (matchText("}")) {
            return;
        }

        do {
            if (!checkKind(TokenKind.word) || peekToken().text != "=") {
                failAt(
                    currentToken(),
                    "OPENC-STRUCT-INIT-001",
                    "struct initialization requires named fields");
            }
            consumeToken();
            expectText("=", "OPENC-STRUCT-INIT-001", "expected '=' after field name");
            parseExpression();
        } while (matchText(",") && !checkText("}"));

        expectText("}", "OPENC-STRUCT-INIT-001", "expected '}' after struct initializer");
    }

    bool isAssignmentOperator(string text) const {
        return text == "=" || text == "+=" || text == "-=" || text == "*=" ||
            text == "/=" || text == "%=";
    }

    int binaryPrecedence(string text) const {
        switch (text) {
            case "||": return 1;
            case "&&": return 2;
            case "|": return 3;
            case "^": return 4;
            case "&": return 5;
            case "==":
            case "!=": return 6;
            case "<":
            case "<=":
            case ">":
            case ">=": return 7;
            case "<<":
            case ">>": return 8;
            case "+":
            case "-": return 9;
            case "*":
            case "/":
            case "%": return 10;
            default: return -1;
        }
    }

    void expectStatementSemicolon() {
        if (!matchText(";")) {
            failAt(
                currentToken(),
                "OPENC-STMT-SEMICOLON-001",
                "ordinary statements require a terminating semicolon");
        }
    }

    void pushScope() {
        bool[string] names;
        localScopes ~= names;
    }

    void popScope() {
        if (localScopes.length > 0) {
            localScopes.length = localScopes.length - 1;
        }
    }

    void declareLocal(string name) {
        if (localScopes.length == 0) {
            return;
        }
        localScopes[$ - 1][name] = true;
    }

    bool isLocalDeclared(string name) const {
        foreach_reverse (scopeNames; localScopes) {
            if (name in scopeNames) {
                return true;
            }
        }
        return false;
    }
}

void parseTokens(Token[] tokens) {
    auto parser = new Parser(tokens);
    parser.parseSource();
}
