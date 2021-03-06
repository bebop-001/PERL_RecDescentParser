#!/usr/local/bin/perl -w
use warnings;
use strict;

# The MIT License (MIT)
# Copyright (c) 2016 Kana-Tutor (http://www.kana-tutor.com/)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

=head1 NAME
LogicParser::Evaluate

=head1 SYNOPSIS

=over

 require LogicParser;
 
 # this function assigns an equation and loops to allow the
 # user to input tokens.  Any token the user inputs is 
 # evaluated as 'true'.
 my $equation = [qw( ( a AND b ) OR ( c AND NOT d ) ) ];
 my $operands = Evaluate('-o', $equation, []);
 my $in;
 do {
   print "Input key values > ";
   chomp($in = <STDIN>);
   if($in) {
       print(((Evaluate([@ARGV], [$in =~ m{(\S+)}g]))
           ? 'TRUE' : 'FALSE'), "\n");
   }
 } while $in;

=back

=head1 DESCRIPTION

This code implements a simple recursive descent parser used to
evaluate logical values.  I use it for evaluating the results of
a grep tool that allows conditional matches of variables.

See LogicParser for an interactive perl script to exercise the fundtion.

=head1 FUNCTIONS

The library has only one  function: Evaluate();
 my $result = Evaluate($equation, $values);
 --- OR ---
 my $operands = Evaluate('-o', $equation, $values);

* $equation is a list ref containing the tokens that make up the equation.

* $values is a list ref containing the operands the user wants evaluated
as true.

* if '-o' is set the function returns a list ref containing the
operands from the language.

=cut

my @parsed = (); # for error messages...
sub ERROR {
    my ($line, @errors) = @_;
    die "Line $line\nParsed so far:", join(' ', @parsed),
        "\nError: ", join('', @errors), "\n";
}
{
    package tokens;
    sub new     { bless {tokens => $_[1], index => 0}, $_[0];   }
    sub next    { $_[0]->{tokens}[$_[0]->{index}++];            }
    sub peek    { $_[0]->{tokens}[$_[0]->{index}];              }
}
sub Evaluate {
    # if first token is '-o', return a list ref of operators found
    # instead of the result of the evaluation.
    my ($find_operands, %return_operands);
    if ($_[0] eq '-o') {
        $find_operands++;
        shift @_;
    }
    my ($equation, $values) = @_;
    my $tokens = tokens->new($equation);
    @parsed = ();
    # values we're evaluating.  If one of these is encountered in the
    # equation in, the result is 'true'.
    my %values = map {$_, 1} @$values;
    # Track {}'s so we can give an error if they aree unbalenced.
    my $depth = 0;
    # an equation with more than 1 token and no operators is an error.
    my ($tokens_count, $operators_count);
    my ($evaluate, $evaluate_node);
    # evaluate the equation.
    $evaluate = sub {
        my $token;     # Current token
        # Evaluate this node.
        my $ACC;    # the accumulator.
        # Evaluate a node.
        $evaluate_node = sub {
            # Set this on encountering an '}'/
            # Set $TERMINAL on encountering the terminal of a node.
            # For this language it's ')'.
            my $TERMINAL;
            # Each operator has an entry here where it gets evaluated.
            my %logic_tree = (
                AND     => sub {
                    my $L = $ACC;
                    my $R = $evaluate_node->();
                    return ($L && $R);
                },
                OR      => sub {
                    my $L = $ACC;
                    my $R = $evaluate_node->();
                    return ($L || $R);
                },
                XOR      => sub {
                    my $L = $ACC;
                    my $R = $evaluate_node->();
                    return ($L ^ $R);
                },
                NOT     => sub {
                    my $op = shift @_;
                    # bit of a kludge here...  If NOT is
                    # the first token (i.e. ACC is empty),
                    # we need to set ACC # so the next input
                    # is returned instead of assigned to ACC.
                    $ACC = $op unless defined $ACC;
                    my $rv = (! $evaluate_node->()) || 0;
                    $ACC = $rv if ($ACC eq $op);
                    return $rv;
                },
                '('     => sub {
                    $depth++;
                    my $rv =  $evaluate->();
                    $TERMINAL++;
                    return $rv;
                },
                ')'     => sub {
                    $depth--;
                    ERROR(__LINE__, "too many close parens.") if $depth < 0;
                    return $ACC;
                },
            );
            # as long as we have tokens and haven't encountered a node
            # terminal, parse the input tokens.
            while (!$TERMINAL && defined($token = $tokens->next())) {
                push @parsed, $token;  # for error message output.
                if (defined $logic_tree{$token}) {
                    $operators_count++;
                    $ACC = $logic_tree{$token}->($token);
                }
                else {
                    $tokens_count++;
                    if ($find_operands) {
                        $return_operands{$token}++;
                    }
                    my $rv = defined $values{$token} || 0;
                    if (defined $ACC) {
                        return $rv;
                    }
                    else {
                        # First value for a node gets set here.
                        $ACC = $rv;
                    }
                }
            }
            return $ACC;
        };
        # Parsing starts here with a call to evaluate_node
        my $rv = $evaluate_node->();
        ERROR(__LINE__, "depth = $depth: too few close parens.") if $depth;
        return $rv;
    };
    # As long as we have tokens, continue evaluation.
    my $rv;
    while (defined $tokens->peek()) {
        $rv = $evaluate->();
        # after last token, return true, valse or a list ref of operaands.
        if (!defined($tokens->peek())) {
            if ($tokens_count > 1 && ! $operators_count) {
                ERROR(__LINE__, "$tokens_count tokens with no operators.");
            }
            elsif($find_operands) {
                return  [ sort keys %return_operands ];
            }
            else {
                return $rv;
            }
        }
    }
}
1;
