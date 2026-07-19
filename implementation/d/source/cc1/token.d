module cc1.token;

enum TokenKind {
    word,
    integerLiteral,
    stringLiteral,
    symbol,
    eofToken
}

struct Token {
    TokenKind kind;
    string text;
    size_t line;
    size_t column;
    size_t offset;
}
