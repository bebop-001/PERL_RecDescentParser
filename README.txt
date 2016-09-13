
== Date: Sun Sep 11 17:25:40 PDT 2016

This code implements a simple recursive descent parser used to
evaluate logical values.  I use it for evaluating the results of
a grep tool that allows conditional matches of variables.

See LogicParser for an interactive Perl script to exercise the function.


== Tue Sep 13 13:21:36 PDT 2016

LogicParser: Changed BEGIN initialization so it could find libs in the
same directory it is in by following its symbolic links.  This simplifies
keeping the development version on different machine by using a
symbolic link.

LogicParser.pm: lots of changes.  Cleaned up some of the POD, fixed several problems with the parser.

t/test_all:  Performs tests on LogicParser.pm.  Has a table of equations and
expected results.  Analyzes the equation and performs a test for all
possible variations of the operands.
