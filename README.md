# **`xypcre`**
**xypcre** is a collection of user-defined functions that provides **PCRE** support to [**XYplorer**][:xy] scripts.

[PCRE][:pcre] is an advanced form of Regular Expressions that allows for many advanced regexp operations
not supported by XYplorer's built-in regexp engine.

xypcre functions allow XYplorer to use an advanced Regular Expression engine instead of the limited
VB implementation of `regexmatches()` and `regereplace()`. This is achieved by offloading regexp operations
to a helper utility, `xypcre.exe` (currently written in [AutoIt3][:au3]).

 :warning: _Please read [reference & usage][:ref] before using these functions in your scripts._
_This may have some complicated or downright weird perks, but I hope this helps in some way. _ :)

[XYplorer Beta Club thread][:xyfc] | [Git Repository][:git]

[:ref]: ./XYPCRE.md
[:xy]: https://www.xyplorer.com
[:pcre]: https://en.wikipedia.org/wiki/Perl_Compatible_Regular_Expressions
[:au3]: https://www.autoitscript.com/site/
[:xyfc]: https://www.xyplorer.com/xyfc/viewtopic.php?f=7&t=14569
[:git]: https://github.com/smsrkr/xypcre