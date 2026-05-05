/++
  $(LINK2 https://en.wikipedia.org/wiki/Regular_expression, Regular expressions)
  are a commonly used method of pattern matching
  on strings, with $(I regex) being a catchy word for a pattern in this domain
  specific language. Typical problems usually solved by regular expressions
  include validation of user input and the ubiquitous find $(AMP) replace
  in text processing utilities.

$(SCRIPT inhibitQuickIndex = 1;)
$(DIVC quickindex,
$(BOOKTABLE,
$(TR $(TH Category) $(TH Functions))
$(TR $(TD Matching) $(TD
        $(LREF bmatch)
        $(LREF match)
        $(LREF matchAll)
        $(LREF matchFirst)
))
$(TR $(TD Building) $(TD
        $(LREF ctRegex)
        $(LREF escaper)
        $(LREF regex)
))
$(TR $(TD Replace) $(TD
        $(LREF replace)
        $(LREF replaceAll)
        $(LREF replaceAllInto)
        $(LREF replaceFirst)
        $(LREF replaceFirstInto)
))
$(TR $(TD Split) $(TD
        $(LREF split)
        $(LREF splitter)
))
$(TR $(TD Objects) $(TD
        $(LREF Captures)
        $(LREF Regex)
        $(LREF RegexException)
        $(LREF RegexMatch)
        $(LREF Splitter)
        $(LREF StaticRegex)
))
))

  $(SECTION Synopsis)

  Create a regex at runtime:
  $(RUNNABLE_EXAMPLE
  $(RUNNABLE_EXAMPLE_STDIN
They met on 24/01/1970.
7/8/99 wasn't as hot as 7/8/2022.
)
      ---
      import std.regex;
      import std.stdio;
      // Print out all possible dd/mm/yy(yy) dates found in user input.
      auto r = regex(r"\b[0-9][0-9]?/[0-9][0-9]?/[0-9][0-9](?:[0-9][0-9])?\b");
      foreach (line; stdin.byLine)
      {
        // matchAll() returns a range that can be iterated
        // to get all subsequent matches.
        foreach (c; matchAll(line, r))
            writeln(c.hit);
      }
      ---
  )
  Create a static regex at compile-time, which contains fast native code:
  $(RUNNABLE_EXAMPLE
  ---
  import std.regex;
  auto ctr = ctRegex!(`^.*/([^/]+)/?$`);

  // It works just like a normal regex:
  auto c2 = matchFirst("foo/bar", ctr);   // First match found here, if any
  assert(!c2.empty);   // Be sure to check if there is a match before examining contents!
  assert(c2[1] == "bar");   // Captures is a range of submatches: 0 = full match.
  ---
  )
  Multi-pattern regex:
  $(RUNNABLE_EXAMPLE
  ---
  import std.regex;
  auto multi = regex([`\d+,\d+`, `([a-z]+):(\d+)`]);
  auto m = "abc:43 12,34".matchAll(multi);
  assert(m.front.whichPattern == 2);
  assert(m.front[1] == "abc");
  assert(m.front[2] == "43");
  m.popFront();
  assert(m.front.whichPattern == 1);
  assert(m.front[0] == "12,34");
  ---
  )
  $(LREF Captures) and `opCast!bool`:
  $(RUNNABLE_EXAMPLE
  ---
  import std.regex;
  // The result of `matchAll/matchFirst` is directly testable with `if/assert/while`,
  // e.g. test if a string consists of letters only:
  assert(matchFirst("LettersOnly", `^\p{L}+$`));

  // And we can take advantage of the ability to define a variable in the IfCondition:
  if (const captures = matchFirst("At l34st one digit, but maybe more...", `((\d)(\d*))`))
  {
      assert(captures[2] == "3");
      assert(captures[3] == "4");
      assert(captures[1] == "34");
  }
  ---
  )
  See_Also: $(LINK2 https://dlang.org/spec/statement.html#IfCondition, `IfCondition`).

  $(SECTION Syntax and general information)
  The general usage guideline is to keep regex complexity on the side of simplicity,
  as its capabilities reside in purely character-level manipulation.
  As such it's ill-suited for tasks involving higher level invariants
  like matching an integer number $(U bounded) in an [a,b] interval.
  Checks of this sort of are better addressed by additional post-processing.

  The basic syntax shouldn't surprise experienced users of regular expressions.
  For an introduction to `std.regex` see a
  $(HTTP dlang.org/regular-expression.html, short tour) of the module API
  and its abilities.

  There are other web resources on regular expressions to help newcomers,
  and a good $(HTTP www.regular-expressions.info, reference with tutorial)
  can easily be found.

  This library uses a remarkably common ECMAScript syntax flavor
  with the following extensions:
  $(UL
    $(LI Named subexpressions, with Python syntax. )
    $(LI Unicode properties such as Scripts, Blocks and common binary properties e.g Alphabetic, White_Space, Hex_Digit etc.)
    $(LI Arbitrary length and complexity lookbehind, including lookahead in lookbehind and vise-versa.)
  )

  $(REG_START Pattern syntax )
  $(I std.regex operates on codepoint level,
    'character' in this table denotes a single Unicode codepoint.)
  $(REG_TABLE
    $(REG_TITLE Pattern element, Semantics )
    $(REG_TITLE Atoms, Match single characters )
    $(REG_ROW any character except [{|*+?()^$, Matches the character itself. )
    $(REG_ROW ., In single line mode matches any character.
      Otherwise it matches any character except '\n' and '\r'. )
    $(REG_ROW [class], Matches a single character
      that belongs to this character class. )
    $(REG_ROW [^class], Matches a single character that
      does $(U not) belong to this character class.)
    $(REG_ROW \cC, Matches the control character corresponding to letter C)
    $(REG_ROW \xXX, Matches a character with hexadecimal value of XX. )
    $(REG_ROW \uXXXX, Matches a character  with hexadecimal value of XXXX. )
    $(REG_ROW \U00YYYYYY, Matches a character with hexadecimal value of YYYYYY. )
    $(REG_ROW \f, Matches a formfeed character. )
    $(REG_ROW \n, Matches a linefeed character. )
    $(REG_ROW \r, Matches a carriage return character. )
    $(REG_ROW \t, Matches a tab character. )
    $(REG_ROW \v, Matches a vertical tab character. )
    $(REG_ROW \d, Matches any Unicode digit. )
    $(REG_ROW \D, Matches any character except Unicode digits. )
    $(REG_ROW \w, Matches any word character (note: this includes numbers).)
    $(REG_ROW \W, Matches any non-word character.)
    $(REG_ROW \s, Matches whitespace, same as \p{White_Space}.)
    $(REG_ROW \S, Matches any character except those recognized as $(I \s ). )
    $(REG_ROW \\\\, Matches \ character. )
    $(REG_ROW \c where c is one of [|*+?(), Matches the character c itself. )
    $(REG_ROW \p{PropertyName}, Matches a character that belongs
        to the Unicode PropertyName set.
      Single letter abbreviations can be used without surrounding {,}. )
    $(REG_ROW  \P{PropertyName}, Matches a character that does not belong
        to the Unicode PropertyName set.
      Single letter abbreviations can be used without surrounding {,}. )
    $(REG_ROW \p{InBasicLatin}, Matches any character that is part of
          the BasicLatin Unicode $(U block).)
    $(REG_ROW \P{InBasicLatin}, Matches any character except ones in
          the BasicLatin Unicode $(U block).)
    $(REG_ROW \p{Cyrillic}, Matches any character that is part of
        Cyrillic $(U script).)
    $(REG_ROW \P{Cyrillic}, Matches any character except ones in
        Cyrillic $(U script).)
    $(REG_TITLE Quantifiers, Specify repetition of other elements)
    $(REG_ROW *, Matches previous character/subexpression 0 or more times.
      Greedy version - tries as many times as possible.)
    $(REG_ROW *?, Matches previous character/subexpression 0 or more times.
      Lazy version  - stops as early as possible.)
    $(REG_ROW +, Matches previous character/subexpression 1 or more times.
      Greedy version - tries as many times as possible.)
    $(REG_ROW +?, Matches previous character/subexpression 1 or more times.
      Lazy version  - stops as early as possible.)
    $(REG_ROW ?, Matches previous character/subexpression 0 or 1 time.
      Greedy version - tries as many times as possible.)
    $(REG_ROW ??, Matches previous character/subexpression 0 or 1 time.
      Lazy version  - stops as early as possible.)
    $(REG_ROW {n}, Matches previous character/subexpression exactly n times. )
    $(REG_ROW {n$(COMMA)}, Matches previous character/subexpression n times or more.
      Greedy version - tries as many times as possible. )
    $(REG_ROW {n$(COMMA)}?, Matches previous character/subexpression n times or more.
      Lazy version - stops as early as possible.)
    $(REG_ROW {n$(COMMA)m}, Matches previous character/subexpression n to m times.
      Greedy version - tries as many times as possible, but no more than m times. )
    $(REG_ROW {n$(COMMA)m}?, Matches previous character/subexpression n to m times.
      Lazy version - stops as early as possible, but no less then n times.)
    $(REG_TITLE Other, Subexpressions $(AMP) alternations )
    $(REG_ROW (regex),  Matches subexpression regex,
      saving matched portion of text for later retrieval. )
    $(REG_ROW (?#comment), An inline comment that is ignored while matching.)
    $(REG_ROW (?:regex), Matches subexpression regex,
      $(U not) saving matched portion of text. Useful to speed up matching. )
    $(REG_ROW A|B, Matches subexpression A, or failing that, matches B. )
    $(REG_ROW (?P$(LT)name$(GT)regex), Matches named subexpression
        regex labeling it with name 'name'.
        When referring to a matched portion of text,
        names work like aliases in addition to direct numbers.
     )
    $(REG_TITLE Assertions, Match position rather than character )
    $(REG_ROW ^, Matches at the beginning of input or line (in multiline mode).)
    $(REG_ROW $, Matches at the end of input or line (in multiline mode). )
    $(REG_ROW \b, Matches at word boundary. )
    $(REG_ROW \B, Matches when $(U not) at word boundary. )
    $(REG_ROW (?=regex), Zero-width lookahead assertion.
        Matches at a point where the subexpression
        regex could be matched starting from the current position.
      )
    $(REG_ROW (?!regex), Zero-width negative lookahead assertion.
        Matches at a point where the subexpression
        regex could $(U not) be matched starting from the current position.
      )
    $(REG_ROW (?<=regex), Zero-width lookbehind assertion. Matches at a point
        where the subexpression regex could be matched ending
        at the current position (matching goes backwards).
      )
    $(REG_ROW  (?<!regex), Zero-width negative lookbehind assertion.
      Matches at a point where the subexpression regex could $(U not)
      be matched ending at the current position (matching goes backwards).
     )
  )

  $(REG_START Character classes )
  $(REG_TABLE
    $(REG_TITLE Pattern element, Semantics )
    $(REG_ROW Any atom, Has the same meaning as outside of a character class,
      except for ] which must be written as \\])
    $(REG_ROW a-z, Includes characters a, b, c, ..., z. )
    $(REG_ROW [a||b]$(COMMA) [a--b]$(COMMA) [a~~b]$(COMMA) [a$(AMP)$(AMP)b],
     Where a, b are arbitrary classes, means union, set difference,
     symmetric set difference, and intersection respectively.
     $(I Any sequence of character class elements implicitly forms a union.) )
  )

  $(REG_START Regex flags )
  $(REG_TABLE
    $(REG_TITLE Flag, Semantics )
    $(REG_ROW g, Global regex, repeat over the whole input. )
    $(REG_ROW i, Case insensitive matching. )
    $(REG_ROW m, Multi-line mode, match ^, $ on start and end line separators
       as well as start and end of input.)
    $(REG_ROW s, Single-line mode, makes . match '\n' and '\r' as well. )
    $(REG_ROW x, Free-form syntax, ignores whitespace in pattern,
      useful for formatting complex regular expressions. )
  )

  $(SECTION Unicode support)

  This library provides full Level 1 support* according to
    $(HTTP unicode.org/reports/tr18/, UTS 18). Specifically:
  $(UL
    $(LI 1.1 Hex notation via any of \uxxxx, \U00YYYYYY, \xZZ.)
    $(LI 1.2 Unicode properties.)
    $(LI 1.3 Character classes with set operations.)
    $(LI 1.4 Word boundaries use the full set of "word" characters.)
    $(LI 1.5 Using simple casefolding to match case
        insensitively across the full range of codepoints.)
    $(LI 1.6 Respecting line breaks as any of
        \u000A | \u000B | \u000C | \u000D | \u0085 | \u2028 | \u2029 | \u000D\u000A.)
    $(LI 1.7 Operating on codepoint level.)
  )
  *With exception of point 1.1.1, as of yet, normalization of input
    is expected to be enforced by user.

    $(SECTION Replace format string)

    A set of functions in this module that do the substitution rely
    on a simple format to guide the process. In particular the table below
    applies to the `format` argument of
    $(LREF replaceFirst) and $(LREF replaceAll).

    The format string can reference parts of match using the following notation.
    $(REG_TABLE
        $(REG_TITLE Format specifier, Replaced by )
        $(REG_ROW $(DOLLAR)$(AMP), the whole match. )
        $(REG_ROW $(DOLLAR)$(BACKTICK), part of input $(I preceding) the match. )
        $(REG_ROW $', part of input $(I following) the match. )
        $(REG_ROW $$, '$' character. )
        $(REG_ROW \c $(COMMA) where c is any character, the character c itself. )
        $(REG_ROW \\\\, '\\' character. )
        $(REG_ROW $(DOLLAR)1 .. $(DOLLAR)99, submatch number 1 to 99 respectively. )
    )

  $(SECTION Slicing and zero memory allocations orientation)

  All matches returned by pattern matching functionality in this library
    are slices of the original input. The notable exception is the `replace`
    family of functions  that generate a new string from the input.

    In cases where producing the replacement is the ultimate goal
    $(LREF replaceFirstInto) and $(LREF replaceAllInto) could come in handy
    as functions that  avoid allocations even for replacement.

    Copyright: Copyright Dmitry Olshansky, 2011-

  License: $(HTTP boost.org/LICENSE_1_0.txt, Boost License 1.0).

  Authors: Dmitry Olshansky,

    API and utility constructs are modeled after the original `std.regex`
  by Walter Bright and Andrei Alexandrescu.

  Source: $(PHOBOSSRC std/regex/package.d)

Macros:
    REG_ROW = $(TR $(TD $(I $1 )) $(TD $+) )
    REG_TITLE = $(TR $(TD $(B $1)) $(TD $(B $2)) )
    REG_TABLE = <table border="1" cellspacing="0" cellpadding="5" > $0 </table>
    REG_START = <h3><div align="center"> $0 </div></h3>
    SECTION = <h3><a id="$1" href="#$1" class="anchor">$0</a></h3>
    S_LINK = <a href="#$1">$+</a>
 +/
module std.regex;
public import std.regex.regex;
