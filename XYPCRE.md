# xypcre REFERENCE & USAGE

<sup>- [REFERENCE](#reference) | [REMARKS](#remarks) | [USAGE](#usage) -</sup>

<hr><br>



## **REFERENCE**
_All functions reside within the `xypcre::` namespace._

<sup>- [core functions](#core-functions) | [utility functions](#utility-functions)
     | [helper functions](#helper-functions) -</sup>

<br>


#### Core Functions
_Core functions comprise the principal features of xypcre._

<sup>- [pcrematch()](#pcrematch) | [pcrereplace()](#pcrereplace)
     | [pcrecapture()](#pcrecapture) | [pcresplit()](#pcresplit) -</sup>


1. ##### **`pcrematch()`**
   Finds match(es) of regexp pattern in given string.

   _Syntax_: `pcrematch(string, pattern, sep='||', index=0, format=2)`
   ```
   string   String to work on (haystack).
   pattern  The regexp pattern to match (needle).
   sep      Separator between returned matches, at least two characters long.
   index    1-based index of one match to return when there are multiple matches.
            Ineffective if < 1. returns last match if > total count.
   format   Format of returned data. Can be one of 0, 1, 2. See REMARKS.
   ```
   _Return_: Matching substring(s) in defined **`format`**.


2. ##### **`pcrereplace()`**
   Makes replacements to regexp pattern match(es) in given string.

   _Syntax_: `pcrereplace(string, pattern, replace)`
   ```
   string   String to work on (haystack).
   pattern  The regexp pattern to match (needle).
   replace  The string or pattern to replace match with.
   ```
   _Return_: Resulting string after replacement.


3. ##### **`pcrecapture()`**
   Finds match(es) of specified regexp capture group in given string.

   _Syntax_: `pcrecapture(string, pattern, index=1, sep='||', format=2)`
   ```
   string   String to work on (haystack).
   pattern  The regexp pattern to match (needle), with at least one capture group.
   sep      Separator between returned matches, at least two characters long.
   index    1-based index of the capturing group to return.
            Returns 1st group if < 1, or last one if > total count.
            Pass named groups by their ordinal index.
   format   Format of returned data. Can be one of 0, 1, 2. See REMARKS.
   ```
   _Return_: Matching substring(s) of the group, separated by **`sep`**, in defined **`format`**.


4. ##### **`pcresplit()`**
   Splits given string at each point where regexp pattern matches.

   _Syntax_: `pcresplit(string, pattern, sep='||', format=2)`
   ```
   string   String to work on (haystack).
   pattern  The regexp pattern to split at (needle).
   sep      Separator between returned substrings, at least two characters long.
   format   Format of returned data. Can be one of 0, 1, 2. See REMARKS.
   ```
   _Return_: Split substrings, separated by **`sep`**, in defined **`format`**.

   _Notes_: Matched text is destroyed by split. Use lookaheads/lookbehinds to retain portions.
<br>



#### Utility Functions
_Utility functions are intended to assist in working with core functions._

<sup>- [pcretoken()](#pcretoken) -</sup>

1. ##### **`pcretoken()`**
   Converts a substring/token in the return data of core xypcre functions to its original form.
   This is equivalent to `gettoken()`, but for the special xypcre return formats.

   _Syntax_: `pcretoken(data, index=1, format=2, sep='||')`
   ```
   data     The source tokenlist data.
   index    1-based index of token to return, or total token count if specified as 'count'.
   format   Format of data. Can be 0, 1, or 2. See REMARKS.
   sep      Separator used in data between tokens.
   ```
   _Return_: Specified token, or total count. The token is returned in original _unescaped_ form.
<br>



#### Helper Functions
_Helper functions are required dependencies of Core functions._

<sup>- [xypcrefind()](#xypcrefind) | [xypcrewaiter()](#xypcrewaiter) -</sup>

1. ##### **`xypcrefind()`**
   Finds a valid xypcre.exe (downloaded if not found) and returns its path.
2. ##### **`xypcrewaiter()`**
   Synchronizes communication between xyscript and xypcre.


<hr><br>


## REMARKS

Some functions can return a list of substring or tokens. The following points are relevant in this case:

1. **`sep`** should be at least _2 characters_ long. It is suggested to be the same character, repeated twice. <br>
   the **`sep`** parameter is irrelevant if **`format`** is set to `2`.

2. **`format`** decides the format of returned data. Possible values are one of `0` or `1` or `2` (default).

   * `0`: return tokens are separated by **`sep`**, and not further processed in any way.
          Not even if **`sep`** characters already exist in the strings. Because of this, `gettoken()`
          may fail to retrieve complete tokens. <br>
          But this is the fastest format when the return is known to contain no characters of **`sep`**,
          eg, when **`sep`** is `<crlf 2>`, and the source string is all in one line.
   * `1`: return tokens are separated by **`sep`**, and each **`sep`** character inside tokens are
          surrounded with square brackets. <br>
          For example, if **`sep`** is `<>`, a tokenlist `abc>def<>ghi` becomes `abc[>]def<>ghi`. <br>
          `gettoken()` is able to retrieve a complete token, but it has to be unescaped afterwards.
   * `2`: return is a string constructed as: `<token1 length>+<token2 length>|<token1><token2>` <br>
          Eg, for substrings `'data'`, `''`, `'info|intel'`, the return is: `4+0+10|datainfo|intel` <br>
          As stated before, the **`sep`** parameter is irrelevant if this **`format`** is used.

3. Regardless of which **`format`** and **`sep`** is used, the `pcretoken()` function is able to
   retrieve any one substring/token in its original representation.

The reason for all this elaborate escaping and formatting of return data is to retrieve
complete matches even when the matched text may contain the separator characters.


<hr><br>


## **USAGE**

<sup>- [Misc Usage Notes](#misc-usage-notes) | [Debugging Notes](#debugging-notes) -</sup>


The system is comprised of a xyscript include file: `xypcre.xyi`, and an executable utility: `xypcre.exe`.

* `INCLUDE` the xyi file in your script like this, assuming it's saved as `<xyscripts>\_inc\xypcre.xyi`
  ```
   INCLUDE '_inc\xypcre.xyi';
     text pcretoken(pcrematch('a,b,c,a,bb,d', 'b+(?=,d)'), 1);  // demo, return 1st match of pattern
  ```

* Multiple instances of xypcre can run independently, even from inside another xypcre function.

* The functions look for `xypcre.exe` in these locations, in this order:
  + **`$P_UDF_pcre_xypcre`**, a permanent variable pointing to the executable. then,
  + `<xyscripts>\xypcre.exe`, then,
  + `<xydata>\xypcre.exe`, then,
  + `<xypath>\xypcre.exe`, then,
  + If the utility is not found, it is downloaded from [this page][:url_dl].
    If downloading failed, the parent function aborts and returns an empty string.

* The helper functions must be included with core functions, especially when specific
  core functions are included separately.


### Misc Usage Notes

* Contrary to builtin regexp functions, settings such as multiline and case sensitivity do
  not have dedicated parameters, instead these are controlled by flags in the regexp pattern.

* The functions `pcrematch()`, `pcrecapture()` and `pcresplit()` can return a list of substrings.
  `pcretoken()` is recommended for retrieving a single token (or total count) from such returns. <br>

* Most of PCRE(1) syntax is available. See [here (au3)][:ref_rx1] and [here (pcre)][:ref_rx2]
  for details on supported functionality. (These pages also describe some defaults and quirks.)


### Debugging Notes

* If a malformed or too complex regexp pattern is provided, xypcre.exe might seem to hang or freeze.
  An abort prompt is displayed every 8 seconds (usually plenty of time for a good regexp to finish.) <br>
  If confirmed, this kills the offending xypcre.exe and exits the function with an empty return.

* If the functions still cannot finish properly for some reason:

  + Quit xypcre.exe from explorer taskbar, _Or_
  + Clear any permanent variable named in the form of **`$P_UDF_pcre_IFS#`**, where `#` is any number, _Or_
  + press <kbd>Esc</kbd> repeatedly to stop the entire script stack unconditionally.

* `xypcrefind()` has a commented out section for advanced users to enable use of au3 source script
  instead of compiled exe.


<hr>


Read all that? Really, that entire tower of text? Great! I hope you find it useful. :tup:

[:url_dl]: https://example.com
[:ref_rx1]: https://www.autoitscript.com/autoit3/docs/functions/StringRegExp.htm
[:ref_rx2]: http://www.pcre.org/original/doc/html/pcrepattern.html
