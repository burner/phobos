// Written in the D programming language.

/++
    $(P The `std.uni` module provides an implementation
    of fundamental Unicode algorithms and data structures.
    This doesn't include UTF encoding and decoding primitives,
    see $(REF decode, std,_utf) and $(REF encode, std,_utf) in $(MREF std, utf)
    for this functionality. )

$(SCRIPT inhibitQuickIndex = 1;)
$(DIVC quickindex,
$(BOOKTABLE,
$(TR $(TH Category) $(TH Functions))
$(TR $(TD Decode) $(TD
    $(LREF byCodePoint)
    $(LREF byGrapheme)
    $(LREF decodeGrapheme)
    $(LREF graphemeStride)
    $(LREF popGrapheme)
))
$(TR $(TD Comparison) $(TD
    $(LREF icmp)
    $(LREF sicmp)
))
$(TR $(TD Classification) $(TD
    $(LREF isAlpha)
    $(LREF isAlphaNum)
    $(LREF isCodepointSet)
    $(LREF isControl)
    $(LREF isFormat)
    $(LREF isGraphical)
    $(LREF isIntegralPair)
    $(LREF isMark)
    $(LREF isNonCharacter)
    $(LREF isNumber)
    $(LREF isPrivateUse)
    $(LREF isPunctuation)
    $(LREF isSpace)
    $(LREF isSurrogate)
    $(LREF isSurrogateHi)
    $(LREF isSurrogateLo)
    $(LREF isSymbol)
    $(LREF isWhite)
))
$(TR $(TD Normalization) $(TD
    $(LREF NFC)
    $(LREF NFD)
    $(LREF NFKD)
    $(LREF NormalizationForm)
    $(LREF normalize)
))
$(TR $(TD Decompose) $(TD
    $(LREF decompose)
    $(LREF decomposeHangul)
    $(LREF UnicodeDecomposition)
))
$(TR $(TD Compose) $(TD
    $(LREF compose)
    $(LREF composeJamo)
))
$(TR $(TD Sets) $(TD
    $(LREF CodepointInterval)
    $(LREF CodepointSet)
    $(LREF InversionList)
    $(LREF unicode)
))
$(TR $(TD Trie) $(TD
    $(LREF codepointSetTrie)
    $(LREF CodepointSetTrie)
    $(LREF codepointTrie)
    $(LREF CodepointTrie)
    $(LREF toTrie)
    $(LREF toDelegate)
))
$(TR $(TD Casing) $(TD
    $(LREF asCapitalized)
    $(LREF asLowerCase)
    $(LREF asUpperCase)
    $(LREF isLower)
    $(LREF isUpper)
    $(LREF toLower)
    $(LREF toLowerInPlace)
    $(LREF toUpper)
    $(LREF toUpperInPlace)
))
$(TR $(TD Utf8Matcher) $(TD
    $(LREF isUtfMatcher)
    $(LREF MatcherConcept)
    $(LREF utfMatcher)
))
$(TR $(TD Separators) $(TD
    $(LREF lineSep)
    $(LREF nelSep)
    $(LREF paraSep)
))
$(TR $(TD Building blocks) $(TD
    $(LREF allowedIn)
    $(LREF combiningClass)
    $(LREF Grapheme)
))
))

    $(P All primitives listed operate on Unicode characters and
        sets of characters. For functions which operate on ASCII characters
        and ignore Unicode $(CHARACTERS), see $(MREF std, ascii).
        For definitions of Unicode $(CHARACTER), $(CODEPOINT) and other terms
        used throughout this module see the $(S_LINK Terminology, terminology) section
        below.
    )
    $(P The focus of this module is the core needs of developing Unicode-aware
        applications. To that effect it provides the following optimized primitives:
    )
    $(UL
        $(LI Character classification by category and common properties:
            $(LREF isAlpha), $(LREF isWhite) and others.
        )
        $(LI
            Case-insensitive string comparison ($(LREF sicmp), $(LREF icmp)).
        )
        $(LI
            Converting text to any of the four normalization forms via $(LREF normalize).
        )
        $(LI
            Decoding ($(LREF decodeGrapheme))  and iteration ($(LREF byGrapheme), $(LREF graphemeStride))
            by user-perceived characters, that is by $(LREF Grapheme) clusters.
        )
        $(LI
            Decomposing and composing of individual character(s) according to canonical
            or compatibility rules, see $(LREF compose) and $(LREF decompose),
            including the specific version for Hangul syllables $(LREF composeJamo)
            and $(LREF decomposeHangul).
        )
    )
    $(P It's recognized that an application may need further enhancements
        and extensions, such as less commonly known algorithms,
        or tailoring existing ones for region specific needs. To help users
        with building any extra functionality beyond the core primitives,
        the module provides:
    )
    $(UL
        $(LI
            $(LREF CodepointSet), a type for easy manipulation of sets of characters.
            Besides the typical set algebra it provides an unusual feature:
            a D source code generator for detection of $(CODEPOINTS) in this set.
            This is a boon for meta-programming parser frameworks,
            and is used internally to power classification in small
            sets like $(LREF isWhite).
        )
        $(LI
            A way to construct optimal packed multi-stage tables also known as a
            special case of $(LINK2 https://en.wikipedia.org/wiki/Trie, Trie).
            The functions $(LREF codepointTrie), $(LREF codepointSetTrie)
            construct custom tries that map dchar to value.
            The end result is a fast and predictable $(BIGOH 1) lookup that powers
            functions like $(LREF isAlpha) and $(LREF combiningClass),
            but for user-defined data sets.
        )
        $(LI
            A useful technique for Unicode-aware parsers that perform
            character classification of encoded $(CODEPOINTS)
            is to avoid unnecassary decoding at all costs.
            $(LREF utfMatcher) provides an improvement over the usual workflow
            of decode-classify-process, combining the decoding and classification
            steps. By extracting necessary bits directly from encoded
            $(S_LINK Code unit, code units) matchers achieve
            significant performance improvements. See $(LREF MatcherConcept) for
            the common interface of UTF matchers.
        )
        $(LI
            Generally useful building blocks for customized normalization:
            $(LREF combiningClass) for querying combining class
            and $(LREF allowedIn) for testing the Quick_Check
            property of a given normalization form.
        )
        $(LI
            Access to a large selection of commonly used sets of $(CODEPOINTS).
            $(S_LINK Unicode properties, Supported sets) include Script,
            Block and General Category. The exact contents of a set can be
            observed in the CLDR utility, on the
            $(HTTP www.unicode.org/cldr/utility/properties.jsp, property index) page
            of the Unicode website.
            See $(LREF unicode) for easy and (optionally) compile-time checked set
            queries.
        )
    )
    $(SECTION Synopsis)
    ---
    import std.uni;
    void main()
    {
        // initialize code point sets using script/block or property name
        // now 'set' contains code points from both scripts.
        auto set = unicode("Cyrillic") | unicode("Armenian");
        // same thing but simpler and checked at compile-time
        auto ascii = unicode.ASCII;
        auto currency = unicode.Currency_Symbol;

        // easy set ops
        auto a = set & ascii;
        assert(a.empty); // as it has no intersection with ascii
        a = set | ascii;
        auto b = currency - a; // subtract all ASCII, Cyrillic and Armenian

        // some properties of code point sets
        assert(b.length > 45); // 46 items in Unicode 6.1, even more in 6.2
        // testing presence of a code point in a set
        // is just fine, it is O(logN)
        assert(!b['$']);
        assert(!b['\u058F']); // Armenian dram sign
        assert(b['¥']);

        // building fast lookup tables, these guarantee O(1) complexity
        // 1-level Trie lookup table essentially a huge bit-set ~262Kb
        auto oneTrie = toTrie!1(b);
        // 2-level far more compact but typically slightly slower
        auto twoTrie = toTrie!2(b);
        // 3-level even smaller, and a bit slower yet
        auto threeTrie = toTrie!3(b);
        assert(oneTrie['£']);
        assert(twoTrie['£']);
        assert(threeTrie['£']);

        // build the trie with the most sensible trie level
        // and bind it as a functor
        auto cyrillicOrArmenian = toDelegate(set);
        auto balance = find!(cyrillicOrArmenian)("Hello ընկեր!");
        assert(balance == "ընկեր!");
        // compatible with bool delegate(dchar)
        bool delegate(dchar) bindIt = cyrillicOrArmenian;

        // Normalization
        string s = "Plain ascii (and not only), is always normalized!";
        assert(s is normalize(s));// is the same string

        string nonS = "A\u0308ffin"; // A ligature
        auto nS = normalize(nonS); // to NFC, the W3C endorsed standard
        assert(nS == "Äffin");
        assert(nS != nonS);
        string composed = "Äffin";

        assert(normalize!NFD(composed) == "A\u0308ffin");
        // to NFKD, compatibility decomposition useful for fuzzy matching/searching
        assert(normalize!NFKD("2¹⁰") == "210");
    }
    ---
    $(SECTION Terminology)
    $(P The following is a list of important Unicode notions
    and definitions. Any conventions used specifically in this
    module alone are marked as such. The descriptions are based on the formal
    definition as found in $(HTTP www.unicode.org/versions/Unicode6.2.0/ch03.pdf,
    chapter three of The Unicode Standard Core Specification.)
    )
    $(P $(DEF Abstract character) A unit of information used for the organization,
        control, or representation of textual data.
        Note that:
        $(UL
            $(LI When representing data, the nature of that data
                is generally symbolic as opposed to some other
                kind of data (for example, visual).
            )
             $(LI An abstract character has no concrete form
                and should not be confused with a $(S_LINK Glyph, glyph).
            )
            $(LI An abstract character does not necessarily
                correspond to what a user thinks of as a “character”
                and should not be confused with a $(LREF Grapheme).
            )
            $(LI The abstract characters encoded (see Encoded character)
                are known as Unicode abstract characters.
            )
            $(LI Abstract characters not directly
                encoded by the Unicode Standard can often be
                represented by the use of combining character sequences.
            )
        )
    )
    $(P $(DEF Canonical decomposition)
        The decomposition of a character or character sequence
        that results from recursively applying the canonical
        mappings found in the Unicode Character Database
        and these described in Conjoining Jamo Behavior
        (section 12 of
        $(HTTP www.unicode.org/uni2book/ch03.pdf, Unicode Conformance)).
    )
    $(P $(DEF Canonical composition)
        The precise definition of the Canonical composition
        is the algorithm as specified in $(HTTP www.unicode.org/uni2book/ch03.pdf,
        Unicode Conformance) section 11.
        Informally it's the process that does the reverse of the canonical
        decomposition with the addition of certain rules
        that e.g. prevent legacy characters from appearing in the composed result.
    )
    $(P $(DEF Canonical equivalent)
        Two character sequences are said to be canonical equivalents if
        their full canonical decompositions are identical.
    )
    $(P $(DEF Character) Typically differs by context.
        For the purpose of this documentation the term $(I character)
        implies $(I encoded character), that is, a code point having
        an assigned abstract character (a symbolic meaning).
    )
    $(P $(DEF Code point) Any value in the Unicode codespace;
        that is, the range of integers from 0 to 10FFFF (hex).
        Not all code points are assigned to encoded characters.
    )
    $(P $(DEF Code unit) The minimal bit combination that can represent
        a unit of encoded text for processing or interchange.
        Depending on the encoding this could be:
        8-bit code units in the UTF-8 (`char`),
        16-bit code units in the UTF-16 (`wchar`),
        and 32-bit code units in the UTF-32 (`dchar`).
        $(I Note that in UTF-32, a code unit is a code point
        and is represented by the D `dchar` type.)
    )
    $(P $(DEF Combining character) A character with the General Category
        of Combining Mark(M).
        $(UL
            $(LI All characters with non-zero canonical combining class
            are combining characters, but the reverse is not the case:
            there are combining characters with a zero combining class.
            )
            $(LI These characters are not normally used in isolation
            unless they are being described. They include such characters
            as accents, diacritics, Hebrew points, Arabic vowel signs,
            and Indic matras.
            )
        )
    )
    $(P $(DEF Combining class)
        A numerical value used by the Unicode Canonical Ordering Algorithm
        to determine which sequences of combining marks are to be
        considered canonically equivalent and  which are not.
    )
    $(P $(DEF Compatibility decomposition)
        The decomposition of a character or character sequence that results
        from recursively applying both the compatibility mappings and
        the canonical mappings found in the Unicode Character Database, and those
        described in Conjoining Jamo Behavior no characters
        can be further decomposed.
    )
    $(P $(DEF Compatibility equivalent)
        Two character sequences are said to be compatibility
        equivalents if their full compatibility decompositions are identical.
    )
    $(P $(DEF Encoded character) An association (or mapping)
        between an abstract character and a code point.
    )
    $(P $(DEF Glyph) The actual, concrete image of a glyph representation
        having been rasterized or otherwise imaged onto some display surface.
    )
    $(P $(DEF Grapheme base) A character with the property
        Grapheme_Base, or any standard Korean syllable block.
    )
    $(P $(DEF Grapheme cluster) Defined as the text between
        grapheme boundaries  as specified by Unicode Standard Annex #29,
        $(HTTP www.unicode.org/reports/tr29/, Unicode text segmentation).
        Important general properties of a grapheme:
        $(UL
            $(LI The grapheme cluster represents a horizontally segmentable
            unit of text, consisting of some grapheme base (which may
            consist of a Korean syllable) together with any number of
            nonspacing marks applied to it.
            )
            $(LI  A grapheme cluster typically starts with a grapheme base
            and then extends across any subsequent sequence of nonspacing marks.
            A grapheme cluster is most directly relevant to text rendering and
            processes such as cursor placement and text selection in editing,
            but may also be relevant to comparison and searching.
            )
            $(LI For many processes, a grapheme cluster behaves as if it was a
            single character with the same properties as its grapheme base.
            Effectively, nonspacing marks apply $(I graphically) to the base,
            but do not change its properties.
            )
        )
        $(P This module defines a number of primitives that work with graphemes:
        $(LREF Grapheme), $(LREF decodeGrapheme) and $(LREF graphemeStride).
        All of them are using $(I extended grapheme) boundaries
        as defined in the aforementioned standard annex.
        )
    )
    $(P $(DEF Nonspacing mark) A combining character with the
        General Category of Nonspacing Mark (Mn) or Enclosing Mark (Me).
    )
    $(P $(DEF Spacing mark) A combining character that is not a nonspacing mark.
    )
    $(SECTION Normalization)
    $(P The concepts of $(S_LINK Canonical equivalent, canonical equivalent)
        or $(S_LINK Compatibility equivalent, compatibility equivalent)
        characters in the Unicode Standard make it necessary to have a full, formal
        definition of equivalence for Unicode strings.
        String equivalence is determined by a process called normalization,
        whereby strings are converted into forms which are compared
        directly for identity. This is the primary goal of the normalization process,
        see the function $(LREF normalize) to convert into any of
        the four defined forms.
    )
    $(P A very important attribute of the Unicode Normalization Forms
        is that they must remain stable between versions of the Unicode Standard.
        A Unicode string normalized to a particular Unicode Normalization Form
        in one version of the standard is guaranteed to remain in that Normalization
        Form for implementations of future versions of the standard.
    )
    $(P The Unicode Standard specifies four normalization forms.
        Informally, two of these forms are defined by maximal decomposition
        of equivalent sequences, and two of these forms are defined
        by maximal $(I composition) of equivalent sequences.
            $(UL
            $(LI Normalization Form D (NFD): The $(S_LINK Canonical decomposition,
                canonical decomposition) of a character sequence.)
            $(LI Normalization Form KD (NFKD): The $(S_LINK Compatibility decomposition,
                compatibility decomposition) of a character sequence.)
            $(LI Normalization Form C (NFC): The canonical composition of the
                $(S_LINK Canonical decomposition, canonical decomposition)
                of a coded character sequence.)
            $(LI Normalization Form KC (NFKC): The canonical composition
            of the $(S_LINK Compatibility decomposition,
                compatibility decomposition) of a character sequence)
            )
    )
    $(P The choice of the normalization form depends on the particular use case.
        NFC is the best form for general text, since it's more compatible with
        strings converted from legacy encodings. NFKC is the preferred form for
        identifiers, especially where there are security concerns. NFD and NFKD
        are the most useful for internal processing.
    )
    $(SECTION Construction of lookup tables)
    $(P The Unicode standard describes a set of algorithms that
        depend on having the ability to quickly look up various properties
        of a code point. Given the codespace of about 1 million $(CODEPOINTS),
        it is not a trivial task to provide a space-efficient solution for
        the multitude of properties.
    )
    $(P Common approaches such as hash-tables or binary search over
        sorted code point intervals (as in $(LREF InversionList)) are insufficient.
        Hash-tables have enormous memory footprint and binary search
        over intervals is not fast enough for some heavy-duty algorithms.
    )
    $(P The recommended solution (see Unicode Implementation Guidelines)
        is using multi-stage tables that are an implementation of the
        $(HTTP en.wikipedia.org/wiki/Trie, Trie) data structure with integer
        keys and a fixed number of stages. For the remainder of the section
        this will be called a fixed trie. The following describes a particular
        implementation that is aimed for the speed of access at the expense
        of ideal size savings.
    )
    $(P Taking a 2-level Trie as an example the principle of operation is as follows.
        Split the number of bits in a key (code point, 21 bits) into 2 components
        (e.g. 15 and 8).  The first is the number of bits in the index of the trie
         and the other is number of bits in each page of the trie.
        The layout of the trie is then an array of size 2^^bits-of-index followed
        an array of memory chunks of size 2^^bits-of-page/bits-per-element.
    )
    $(P The number of pages is variable (but not less then 1)
        unlike the number of entries in the index. The slots of the index
        all have to contain a number of a page that is present. The lookup is then
        just a couple of operations - slice the upper bits,
        lookup an index for these, take a page at this index and use
        the lower bits as an offset within this page.

        Assuming that pages are laid out consequently
        in one array at `pages`, the pseudo-code is:
    )
    ---
    auto elemsPerPage = (2 ^^ bits_per_page) / Value.sizeOfInBits;
    pages[index[n >> bits_per_page]][n & (elemsPerPage - 1)];
    ---
    $(P Where if `elemsPerPage` is a power of 2 the whole process is
        a handful of simple instructions and 2 array reads. Subsequent levels
        of the trie are introduced by recursing on this notion - the index array
        is treated as values. The number of bits in index is then again
        split into 2 parts, with pages over 'current-index' and the new 'upper-index'.
    )

    $(P For completeness a level 1 trie is simply an array.
        The current implementation takes advantage of bit-packing values
        when the range is known to be limited in advance (such as `bool`).
        See also $(LREF BitPacked) for enforcing it manually.
        The major size advantage however comes from the fact
        that multiple $(B identical pages on every level are merged) by construction.
    )
    $(P The process of constructing a trie is more involved and is hidden from
        the user in a form of the convenience functions $(LREF codepointTrie),
        $(LREF codepointSetTrie) and the even more convenient $(LREF toTrie).
        In general a set or built-in AA with `dchar` type
        can be turned into a trie. The trie object in this module
        is read-only (immutable); it's effectively frozen after construction.
    )
    $(SECTION Unicode properties)
    $(P This is a full list of Unicode properties accessible through $(LREF unicode)
        with specific helpers per category nested within. Consult the
        $(HTTP www.unicode.org/cldr/utility/properties.jsp, CLDR utility)
        when in doubt about the contents of a particular set.
    )
    $(P General category sets listed below are only accessible with the
        $(LREF unicode) shorthand accessor.)
        $(BOOKTABLE $(B General category ),
             $(TR $(TH Abb.) $(TH Long form)
                $(TH Abb.) $(TH Long form)$(TH Abb.) $(TH Long form))
            $(TR $(TD L) $(TD Letter)
                $(TD Cn) $(TD Unassigned)  $(TD Po) $(TD Other_Punctuation))
            $(TR $(TD Ll) $(TD Lowercase_Letter)
                $(TD Co) $(TD Private_Use) $(TD Ps) $(TD Open_Punctuation))
            $(TR $(TD Lm) $(TD Modifier_Letter)
                $(TD Cs) $(TD Surrogate)   $(TD S) $(TD Symbol))
            $(TR $(TD Lo) $(TD Other_Letter)
                $(TD N) $(TD Number)  $(TD Sc) $(TD Currency_Symbol))
            $(TR $(TD Lt) $(TD Titlecase_Letter)
              $(TD Nd) $(TD Decimal_Number)  $(TD Sk) $(TD Modifier_Symbol))
            $(TR $(TD Lu) $(TD Uppercase_Letter)
              $(TD Nl) $(TD Letter_Number)   $(TD Sm) $(TD Math_Symbol))
            $(TR $(TD M) $(TD Mark)
              $(TD No) $(TD Other_Number)    $(TD So) $(TD Other_Symbol))
            $(TR $(TD Mc) $(TD Spacing_Mark)
              $(TD P) $(TD Punctuation) $(TD Z) $(TD Separator))
            $(TR $(TD Me) $(TD Enclosing_Mark)
              $(TD Pc) $(TD Connector_Punctuation)   $(TD Zl) $(TD Line_Separator))
            $(TR $(TD Mn) $(TD Nonspacing_Mark)
              $(TD Pd) $(TD Dash_Punctuation)    $(TD Zp) $(TD Paragraph_Separator))
            $(TR $(TD C) $(TD Other)
              $(TD Pe) $(TD Close_Punctuation) $(TD Zs) $(TD Space_Separator))
            $(TR $(TD Cc) $(TD Control) $(TD Pf)
              $(TD Final_Punctuation)   $(TD -) $(TD Any))
            $(TR $(TD Cf) $(TD Format)
              $(TD Pi) $(TD Initial_Punctuation) $(TD -) $(TD ASCII))
    )
    $(P Sets for other commonly useful properties that are
        accessible with $(LREF unicode):)
        $(BOOKTABLE $(B Common binary properties),
            $(TR $(TH Name) $(TH Name) $(TH Name))
            $(TR $(TD Alphabetic)  $(TD Ideographic) $(TD Other_Uppercase))
            $(TR $(TD ASCII_Hex_Digit) $(TD IDS_Binary_Operator) $(TD Pattern_Syntax))
            $(TR $(TD Bidi_Control)    $(TD ID_Start)    $(TD Pattern_White_Space))
            $(TR $(TD Cased)   $(TD IDS_Trinary_Operator)    $(TD Quotation_Mark))
            $(TR $(TD Case_Ignorable)  $(TD Join_Control)    $(TD Radical))
            $(TR $(TD Dash)    $(TD Logical_Order_Exception) $(TD Soft_Dotted))
            $(TR $(TD Default_Ignorable_Code_Point)    $(TD Lowercase)   $(TD STerm))
            $(TR $(TD Deprecated)  $(TD Math)    $(TD Terminal_Punctuation))
            $(TR $(TD Diacritic)   $(TD Noncharacter_Code_Point) $(TD Unified_Ideograph))
            $(TR $(TD Extender)    $(TD Other_Alphabetic)    $(TD Uppercase))
            $(TR $(TD Grapheme_Base)   $(TD Other_Default_Ignorable_Code_Point)  $(TD Variation_Selector))
            $(TR $(TD Grapheme_Extend) $(TD Other_Grapheme_Extend)   $(TD White_Space))
            $(TR $(TD Grapheme_Link)   $(TD Other_ID_Continue)   $(TD XID_Continue))
            $(TR $(TD Hex_Digit)   $(TD Other_ID_Start)  $(TD XID_Start))
            $(TR $(TD Hyphen)  $(TD Other_Lowercase) )
            $(TR $(TD ID_Continue) $(TD Other_Math)  )
    )
    $(P Below is the table with block names accepted by $(LREF unicode.block).
        Note that the shorthand version $(LREF unicode) requires "In"
        to be prepended to the names of blocks so as to disambiguate
        scripts and blocks.
    )
    $(BOOKTABLE $(B Blocks),
        $(TR $(TD Aegean Numbers)    $(TD Ethiopic Extended) $(TD Mongolian))
        $(TR $(TD Alchemical Symbols)    $(TD Ethiopic Extended-A)   $(TD Musical Symbols))
        $(TR $(TD Alphabetic Presentation Forms) $(TD Ethiopic Supplement)   $(TD Myanmar))
        $(TR $(TD Ancient Greek Musical Notation)    $(TD General Punctuation)   $(TD Myanmar Extended-A))
        $(TR $(TD Ancient Greek Numbers) $(TD Geometric Shapes)  $(TD New Tai Lue))
        $(TR $(TD Ancient Symbols)   $(TD Georgian)  $(TD NKo))
        $(TR $(TD Arabic)    $(TD Georgian Supplement)   $(TD Number Forms))
        $(TR $(TD Arabic Extended-A) $(TD Glagolitic)    $(TD Ogham))
        $(TR $(TD Arabic Mathematical Alphabetic Symbols)    $(TD Gothic)    $(TD Ol Chiki))
        $(TR $(TD Arabic Presentation Forms-A)   $(TD Greek and Coptic)  $(TD Old Italic))
        $(TR $(TD Arabic Presentation Forms-B)   $(TD Greek Extended)    $(TD Old Persian))
        $(TR $(TD Arabic Supplement) $(TD Gujarati)  $(TD Old South Arabian))
        $(TR $(TD Armenian)  $(TD Gurmukhi)  $(TD Old Turkic))
        $(TR $(TD Arrows)    $(TD Halfwidth and Fullwidth Forms) $(TD Optical Character Recognition))
        $(TR $(TD Avestan)   $(TD Hangul Compatibility Jamo) $(TD Oriya))
        $(TR $(TD Balinese)  $(TD Hangul Jamo)   $(TD Osmanya))
        $(TR $(TD Bamum) $(TD Hangul Jamo Extended-A)    $(TD Phags-pa))
        $(TR $(TD Bamum Supplement)  $(TD Hangul Jamo Extended-B)    $(TD Phaistos Disc))
        $(TR $(TD Basic Latin)   $(TD Hangul Syllables)  $(TD Phoenician))
        $(TR $(TD Batak) $(TD Hanunoo)   $(TD Phonetic Extensions))
        $(TR $(TD Bengali)   $(TD Hebrew)    $(TD Phonetic Extensions Supplement))
        $(TR $(TD Block Elements)    $(TD High Private Use Surrogates)   $(TD Playing Cards))
        $(TR $(TD Bopomofo)  $(TD High Surrogates)   $(TD Private Use Area))
        $(TR $(TD Bopomofo Extended) $(TD Hiragana)  $(TD Rejang))
        $(TR $(TD Box Drawing)   $(TD Ideographic Description Characters)    $(TD Rumi Numeral Symbols))
        $(TR $(TD Brahmi)    $(TD Imperial Aramaic)  $(TD Runic))
        $(TR $(TD Braille Patterns)  $(TD Inscriptional Pahlavi) $(TD Samaritan))
        $(TR $(TD Buginese)  $(TD Inscriptional Parthian)    $(TD Saurashtra))
        $(TR $(TD Buhid) $(TD IPA Extensions)    $(TD Sharada))
        $(TR $(TD Byzantine Musical Symbols) $(TD Javanese)  $(TD Shavian))
        $(TR $(TD Carian)    $(TD Kaithi)    $(TD Sinhala))
        $(TR $(TD Chakma)    $(TD Kana Supplement)   $(TD Small Form Variants))
        $(TR $(TD Cham)  $(TD Kanbun)    $(TD Sora Sompeng))
        $(TR $(TD Cherokee)  $(TD Kangxi Radicals)   $(TD Spacing Modifier Letters))
        $(TR $(TD CJK Compatibility) $(TD Kannada)   $(TD Specials))
        $(TR $(TD CJK Compatibility Forms)   $(TD Katakana)  $(TD Sundanese))
        $(TR $(TD CJK Compatibility Ideographs)  $(TD Katakana Phonetic Extensions)  $(TD Sundanese Supplement))
        $(TR $(TD CJK Compatibility Ideographs Supplement)   $(TD Kayah Li)  $(TD Superscripts and Subscripts))
        $(TR $(TD CJK Radicals Supplement)   $(TD Kharoshthi)    $(TD Supplemental Arrows-A))
        $(TR $(TD CJK Strokes)   $(TD Khmer) $(TD Supplemental Arrows-B))
        $(TR $(TD CJK Symbols and Punctuation)   $(TD Khmer Symbols) $(TD Supplemental Mathematical Operators))
        $(TR $(TD CJK Unified Ideographs)    $(TD Lao)   $(TD Supplemental Punctuation))
        $(TR $(TD CJK Unified Ideographs Extension A)    $(TD Latin-1 Supplement)    $(TD Supplementary Private Use Area-A))
        $(TR $(TD CJK Unified Ideographs Extension B)    $(TD Latin Extended-A)  $(TD Supplementary Private Use Area-B))
        $(TR $(TD CJK Unified Ideographs Extension C)    $(TD Latin Extended Additional) $(TD Syloti Nagri))
        $(TR $(TD CJK Unified Ideographs Extension D)    $(TD Latin Extended-B)  $(TD Syriac))
        $(TR $(TD Combining Diacritical Marks)   $(TD Latin Extended-C)  $(TD Tagalog))
        $(TR $(TD Combining Diacritical Marks for Symbols)   $(TD Latin Extended-D)  $(TD Tagbanwa))
        $(TR $(TD Combining Diacritical Marks Supplement)    $(TD Lepcha)    $(TD Tags))
        $(TR $(TD Combining Half Marks)  $(TD Letterlike Symbols)    $(TD Tai Le))
        $(TR $(TD Common Indic Number Forms) $(TD Limbu) $(TD Tai Tham))
        $(TR $(TD Control Pictures)  $(TD Linear B Ideograms)    $(TD Tai Viet))
        $(TR $(TD Coptic)    $(TD Linear B Syllabary)    $(TD Tai Xuan Jing Symbols))
        $(TR $(TD Counting Rod Numerals) $(TD Lisu)  $(TD Takri))
        $(TR $(TD Cuneiform) $(TD Low Surrogates)    $(TD Tamil))
        $(TR $(TD Cuneiform Numbers and Punctuation) $(TD Lycian)    $(TD Telugu))
        $(TR $(TD Currency Symbols)  $(TD Lydian)    $(TD Thaana))
        $(TR $(TD Cypriot Syllabary) $(TD Mahjong Tiles) $(TD Thai))
        $(TR $(TD Cyrillic)  $(TD Malayalam) $(TD Tibetan))
        $(TR $(TD Cyrillic Extended-A)   $(TD Mandaic)   $(TD Tifinagh))
        $(TR $(TD Cyrillic Extended-B)   $(TD Mathematical Alphanumeric Symbols) $(TD Transport And Map Symbols))
        $(TR $(TD Cyrillic Supplement)   $(TD Mathematical Operators)    $(TD Ugaritic))
        $(TR $(TD Deseret)   $(TD Meetei Mayek)  $(TD Unified Canadian Aboriginal Syllabics))
        $(TR $(TD Devanagari)    $(TD Meetei Mayek Extensions)   $(TD Unified Canadian Aboriginal Syllabics Extended))
        $(TR $(TD Devanagari Extended)   $(TD Meroitic Cursive)  $(TD Vai))
        $(TR $(TD Dingbats)  $(TD Meroitic Hieroglyphs)  $(TD Variation Selectors))
        $(TR $(TD Domino Tiles)  $(TD Miao)  $(TD Variation Selectors Supplement))
        $(TR $(TD Egyptian Hieroglyphs)  $(TD Miscellaneous Mathematical Symbols-A)  $(TD Vedic Extensions))
        $(TR $(TD Emoticons) $(TD Miscellaneous Mathematical Symbols-B)  $(TD Vertical Forms))
        $(TR $(TD Enclosed Alphanumerics)    $(TD Miscellaneous Symbols) $(TD Yijing Hexagram Symbols))
        $(TR $(TD Enclosed Alphanumeric Supplement)  $(TD Miscellaneous Symbols and Arrows)  $(TD Yi Radicals))
        $(TR $(TD Enclosed CJK Letters and Months)   $(TD Miscellaneous Symbols And Pictographs) $(TD Yi Syllables))
        $(TR $(TD Enclosed Ideographic Supplement)   $(TD Miscellaneous Technical)   )
        $(TR $(TD Ethiopic)  $(TD Modifier Tone Letters) )
    )
    $(P Below is the table with script names accepted by $(LREF unicode.script)
        and by the shorthand version $(LREF unicode):)
        $(BOOKTABLE $(B Scripts),
            $(TR $(TD Arabic)  $(TD Hanunoo) $(TD Old_Italic))
            $(TR $(TD Armenian)    $(TD Hebrew)  $(TD Old_Persian))
            $(TR $(TD Avestan) $(TD Hiragana)    $(TD Old_South_Arabian))
            $(TR $(TD Balinese)    $(TD Imperial_Aramaic)    $(TD Old_Turkic))
            $(TR $(TD Bamum)   $(TD Inherited)   $(TD Oriya))
            $(TR $(TD Batak)   $(TD Inscriptional_Pahlavi)   $(TD Osmanya))
            $(TR $(TD Bengali) $(TD Inscriptional_Parthian)  $(TD Phags_Pa))
            $(TR $(TD Bopomofo)    $(TD Javanese)    $(TD Phoenician))
            $(TR $(TD Brahmi)  $(TD Kaithi)  $(TD Rejang))
            $(TR $(TD Braille) $(TD Kannada) $(TD Runic))
            $(TR $(TD Buginese)    $(TD Katakana)    $(TD Samaritan))
            $(TR $(TD Buhid)   $(TD Kayah_Li)    $(TD Saurashtra))
            $(TR $(TD Canadian_Aboriginal) $(TD Kharoshthi)  $(TD Sharada))
            $(TR $(TD Carian)  $(TD Khmer)   $(TD Shavian))
            $(TR $(TD Chakma)  $(TD Lao) $(TD Sinhala))
            $(TR $(TD Cham)    $(TD Latin)   $(TD Sora_Sompeng))
            $(TR $(TD Cherokee)    $(TD Lepcha)  $(TD Sundanese))
            $(TR $(TD Common)  $(TD Limbu)   $(TD Syloti_Nagri))
            $(TR $(TD Coptic)  $(TD Linear_B)    $(TD Syriac))
            $(TR $(TD Cuneiform)   $(TD Lisu)    $(TD Tagalog))
            $(TR $(TD Cypriot) $(TD Lycian)  $(TD Tagbanwa))
            $(TR $(TD Cyrillic)    $(TD Lydian)  $(TD Tai_Le))
            $(TR $(TD Deseret) $(TD Malayalam)   $(TD Tai_Tham))
            $(TR $(TD Devanagari)  $(TD Mandaic) $(TD Tai_Viet))
            $(TR $(TD Egyptian_Hieroglyphs)    $(TD Meetei_Mayek)    $(TD Takri))
            $(TR $(TD Ethiopic)    $(TD Meroitic_Cursive)    $(TD Tamil))
            $(TR $(TD Georgian)    $(TD Meroitic_Hieroglyphs)    $(TD Telugu))
            $(TR $(TD Glagolitic)  $(TD Miao)    $(TD Thaana))
            $(TR $(TD Gothic)  $(TD Mongolian)   $(TD Thai))
            $(TR $(TD Greek)   $(TD Myanmar) $(TD Tibetan))
            $(TR $(TD Gujarati)    $(TD New_Tai_Lue) $(TD Tifinagh))
            $(TR $(TD Gurmukhi)    $(TD Nko) $(TD Ugaritic))
            $(TR $(TD Han) $(TD Ogham)   $(TD Vai))
            $(TR $(TD Hangul)  $(TD Ol_Chiki)    $(TD Yi))
    )
    $(P Below is the table of names accepted by $(LREF unicode.hangulSyllableType).)
        $(BOOKTABLE $(B Hangul syllable type),
            $(TR $(TH Abb.) $(TH Long form))
            $(TR $(TD L)   $(TD Leading_Jamo))
            $(TR $(TD LV)  $(TD LV_Syllable))
            $(TR $(TD LVT) $(TD LVT_Syllable) )
            $(TR $(TD T)   $(TD Trailing_Jamo))
            $(TR $(TD V)   $(TD Vowel_Jamo))
    )
    References:
        $(HTTP www.digitalmars.com/d/ascii-table.html, ASCII Table),
        $(HTTP en.wikipedia.org/wiki/Unicode, Wikipedia),
        $(HTTP www.unicode.org, The Unicode Consortium),
        $(HTTP www.unicode.org/reports/tr15/, Unicode normalization forms),
        $(HTTP www.unicode.org/reports/tr29/, Unicode text segmentation)
        $(HTTP www.unicode.org/uni2book/ch05.pdf,
            Unicode Implementation Guidelines)
        $(HTTP www.unicode.org/uni2book/ch03.pdf,
            Unicode Conformance)
    Trademarks:
        Unicode(tm) is a trademark of Unicode, Inc.

    Copyright: Copyright 2013 -
    License:   $(HTTP www.boost.org/LICENSE_1_0.txt, Boost License 1.0).
    Authors:   Dmitry Olshansky
    Source:    $(PHOBOSSRC std/uni/package.d)
    Standards: $(HTTP www.unicode.org/versions/Unicode6.2.0/, Unicode v6.2)

Macros:

SECTION = <h3><a id="$1">$0</a></h3>
DEF = <div><a id="$1"><i>$0</i></a></div>
S_LINK = <a href="#$1">$+</a>
CODEPOINT = $(S_LINK Code point, code point)
CODEPOINTS = $(S_LINK Code point, code points)
CHARACTER = $(S_LINK Character, character)
CHARACTERS = $(S_LINK Character, characters)
CLUSTER = $(S_LINK Grapheme cluster, grapheme cluster)
+/
module std.uni;
public import std.uni.uni;
