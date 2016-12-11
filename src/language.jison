%left GROUP END_GROUP '.' CHARACTER_SET NOT_CHARACTER_SET '"'
%left MINIMUM MAXIMUM FROM TO FOR REPETITION OPTIONAL_REPETITION ONE_OR_MORE_REPETITION ZERO_OR_ONE_REPETITION
%left FOLLOWED_BY NOT_FOLLOWED_BY AND THEN ','
%left STARTS_WITH ENDS_WITH
%left OR

%start file

%%

file
    : EOF
        { return ""; }
    | e EOF
        { return $1; }
    ;

e
    : e '.'
        { $$ = $1; }
    | e '.' e
        { $$ = $1 + $3; }
    | e AND e
        { $$ = $1 + $3; }
    | e ',' e
        { $$ = $1 + $3; }
    | e THEN e
        { $$ = $1 + $3; }
    | e ',' THEN e
        { $$ = $1 + $4; }
    | e AND THEN e
        { $$ = $1 + $4; }
    | STARTS_WITH e
        { $$ = "^(?:" + $2 + ")"; }
    | ENDS_WITH e
        { $$ = $2 + "$"; }
    | GROUP e END_GROUP
        { $$ = "(" + $2 + ")"; }
    | CHARACTER_SET charset ';'
        { $$ = "[" + $2 + "]"; }
    | NOT_CHARACTER_SET charset ';'
        { $$ = "[^" + $2 + "]"; }
    | e OR e
        { $$ = "(?:" + $1 + "|" + $3 + ")"; }
    | e FOLLOWED_BY e
        { $$ = $1 + "(?=" + $3 + ")"; }
    | e NOT_FOLLOWED_BY e
        { $$ = $1 + "(?!" + $3 + ")"; }
    | e repetition
        { $$ = $1 + $2; }
    | range
        { $$ = "[" + $1 + "]" }
    | ESCAPED
        {
          $$ = yytext
                    .substring(1, yytext.length - 1)
                    .replace(/\s/g, '\\s');
        }
    | separatorcharacter
    | hexcharacter
    | specialcharacter
    | word
    | helper
    ;

range
    : FROM character TO character
        { $$ = $2 + "-" + $4; }
    | FROM number TO number
        { $$ = $2 + "-" + $4; }
    ;

repetition
    : repetition SMALLEST
        { $$ = $1 + "?"; }
    | OPTIONAL_REPETITION
        { $$ = "*"; }
    | ONE_OR_MORE_REPETITION
        { $$ = "+"; }
    | ZERO_OR_ONE_REPETITION
        { $$ = "?"; }
    | FROM number TO number REPETITION
        { $$ = "{" + $2 + "," + $4 + "}"; }
    | MINIMUM number REPETITION
        { $$ = "{" + $2 + ",}"; }
    | MAXIMUM number REPETITION
        { $$ = "{1," + $2 + "}"; }
    | FOR number REPETITION
        { $$ = "{" + $2 + "}"; }
    ;

word
    : simplecharacter
    | NUMBER
    | simplecharacter word
        { $$ = $1 + $2 }
    | NUMBER word
        { $$ = String($1) + $2 }
    ;

charset
    : character
    | hexcharacter
    | specialcharacter
    | range
    | charset ',' charset
        { $$ = $1 + $3 }
    | charset AND charset
        { $$ = $1 + $3 }
    ;

character
    : simplecharacter
    | separators
    ;

separatorcharacter
    : '.'
        { $$ = "\\."; }
    | ','
        { $$ = "\\,"; }
    ;

simplecharacter
    : CHARACTER
    | '_'
        { $$ = "_"; }
    | ';'
        { $$ = ";"; }
    | '-'
        { $$ = "\\-"; }
    | '^'
        { $$ = "\\^"; }
    | '+'
        { $$ = "\\+"; }
    | '*'
        { $$ = "\\*"; }
    | '?'
        { $$ = "\\?"; }
    | '('
        { $$ = "\\("; }
    | ')'
        { $$ = "\\)"; }
    | '{'
        { $$ = "\\{"; }
    | '}'
        { $$ = "\\}"; }
    | '['
        { $$ = "\\["; }
    | ']'
        { $$ = "\\]"; }
    | ':'
        { $$ = "\\:"; }
    | '!'
        { $$ = "\\!"; }
    | '$'
        { $$ = "\\$"; }
    | '|'
        { $$ = "\\|"; }
    | '\\'
        { $$ = "\\\\"; }
    | '/'
        { $$ = "\\/"; }
    ;

specialcharacter
    : '"'
        { $$ = "\\\""; }
    | CONTROL_CHARACTER character
        { $$ = "\\c" + $2; }
    | TAB
        { $$ = "\\t"; }
    | VERTICAL_TAB
        { $$ = "\\v"; }
    | ALPHANUMERIC
        { $$ = "\\w"; }
    | NON_WORD
        { $$ = "\\W"; }
    | SPACE
        { $$ = "\\s"; }
    | NON_SPACE
        { $$ = "\\S"; }
    | NULL
        { $$ = "\\0"; }
    | RETURN
        { $$ = "\\r"; }
    | FORM_FEED
        { $$ = "\\f"; }
    | LINE_FEED
        { $$ = "\\n"; }
    | DIGIT
        { $$ = "\\d"; }
    | NON_DIGIT
        { $$ = "\\D"; }
    | BACKSPACE
        { $$ = "[\\b]"; }
    | ANY_CHARACTER
        { $$ = "."; }
    | START
        { $$ = "^"; }
    | END
        { $$ = "$"; }
    ;

hexcharacter
    : HEX hexvalue hexvalue
        { $$ = "\\x" + $2 + $3; }
    | HEX hexvalue hexvalue hexvalue hexvalue
        { $$ = "\\u" + $2 + $3 + $4 + $5; }
    ;

hexvalue
    : NUMBER
    | CHARACTER
        {
            if (!/[a-fA-F]/.test(yytext)) {
                throw new Error('Invalid hex value');
            }
            $$ = $1;
        }
    ;

helper
    : datetime
    | LETTER
        { $$ = "[a-zA-Z]"; }
    | UPPERCASE LETTER
        { $$ = "[A-Z]"; }
    | LOWERCASE LETTER
        { $$ = "[a-z]"; }
    | WORD
        { $$ = "[a-zA-Z]+"; }
    | UPPERCASE WORD
        { $$ = "[A-Z]+"; }
    | LOWERCASE WORD
        { $$ = "[a-z]+"; }
    | TYPE_NUMBER
        { $$ = "\\-?[0-9]+"; }
    | NEGATIVE TYPE_NUMBER
        { $$ = "\\-[0-9]+"; }
    | POSITIVE TYPE_NUMBER
        { $$ = "[0-9]+"; }
    | DECIMAL
        { $$ = "\\-?\\d+(?:\\.\\d{0,2})?" }
    | NEGATIVE DECIMAL
        { $$ = "\\-\\d+(?:\\.\\d{0,2})?"; }
    | POSITIVE DECIMAL
        { $$ = "\\d+(?:\\.\\d{0,2})?"; }
    | HTML_TAG
        { $$ = "<([a-z]+)([^<]+)*(?:>(.*)<\\/\\1>|\\s+\\/>)"; }
    | IP_ADDRESS
        { $$ = "(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)"; }
    | URL
        { $$ = "(https?:\\/\\/)?([\\da-z\\.-]+)\\.([a-z\\.]{2,6})([\\/\\w \\.-]*)*\\/?"; }
    | EMAIL
        { $$ = "([a-z0-9_\\.-]+)@([\\da-z\\.-]+)\\.([a-z\\.]{2,6})"; }
    | SLUG
        { $$ = "[a-z0-9-]+"; }
    | HEX
        { $$ = "#?([a-fA-F0-9]{6}|[a-fA-F0-9]{3})"; }
    | LOCALE
        { $$ = "[a-z]{2}(?:-[A-Z]{2})?"; }
    | ANYTHING
        { $$ = ".*"; }
    ;

datetime
    : date
    | date datetime
        { $$ = $1 + $2 }
    | date simplecharacter datetime
        { $$ = $1 + $2 + $3  }
    | time
    | time datetime
        { $$ = $1 + $2 }
    | time simplecharacter datetime
        { $$ = $1 + $2 + $3  }
    | DATE
        { $$ = "(?:(?:31(\\/|-)(?:0?[13578]|1[02]))\\1|(?:(?:29|30)(\\/|-)(?:0?[1,3-9]|1[0-2])\\2))(?:(?:1[6-9]|[2-9]\\d)?\\d{2})$|^(?:29(\\/|-)0?2\\3(?:(?:(?:1[6-9]|[2-9]\\d)?(?:0[48]|[2468][048]|[13579][26])|(?:(?:16|[2468][048]|[3579][26])00))))$|^(?:0?[1-9]|1\\d|2[0-8])(\\/|-)(?:(?:0?[1-9])|(?:1[0-2]))\\4(?:(?:1[6-9]|[2-9]\\d)?\\d{2})"; }
    ;

date
    : DAY
        { $$ = "(?:0[0-9]|[1-2][0-9]|3[01])"; }
    | MONTH
        { $$ = "(?:0[0-9]|1[0-2])"; }
    | YEAR
        { $$ = "[0-9]{4}"; }
    | yy
        { $$ = "[0-9]{2}"; }
    ;

time
    : HOURS
        { $$ = "(?:0[0-9]|1[0-9]|2[0-4])"; }
    | MINUTES
        { $$ = "(?:0[0-9]|[1-5][0-9])"; }
    | SECONDS
        { $$ = "(?:0[0-9]|[1-5][0-9])"; }
    ;

number
    : NUMBER number
        { $$ = String($1) + $2; }
    | NUMBER
        { $$ = $1; }
    ;