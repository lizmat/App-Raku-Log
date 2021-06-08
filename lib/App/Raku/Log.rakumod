use v6.*;

use RandomColor;

#-------------------------------------------------------------------------------
# Stuff for creating values for templates

# Nicks that shouldn't be highlighted in text, because they probably
# are *not* related to that nick.
my constant %stop-nicks = <
  afraid agree alias all alpha alright also and anonymous any
  args around audience average banned bash beep beta block
  browser byte camelia cap change channels complex computer
  concerned confused connection con constant could cpan
  curiosity curious dead decent delimited dev did direction echo
  else embed engine everything failure fine finger food for fork
  fun function fwiw get good google grew hawaiian hello help hey
  hide his hmm hmmm hope host huh info interested its java jit
  juicy just keyboard kill lambda last life like literal little
  log looking lost mac man manner match max mental mhm mind moar
  moose name need never new niecza nobody nothing old one oops
  panda parrot partisan partly patch perl perl5 perl6 pizza
  promote programming properly pun python question raku rakudo
  rakudobug really regex register release repl return rid robot
  root sad sat signal simple should some somebody someone soon
  sorry space spam spawn spine spot still stop subroutine
  success such synthetic system systems tag tea test tester
  testing tests the there they think this total trick trigger
  try twigil type undefined unix user usr variable variables
  visiting wake was welcome what when who will writer yes
>.map: { $_ => True }

# Create HTML to colorize a word as a nick
sub colorize-nick(Str() $nick, %colors) is export {
    if %colors{$nick} -> $color {
        '<span style="color: ' ~ $color ~ '">' ~ $nick ~ '</span>'
    }
    else {
        $nick
    }
}

# Delimiters in message to find nicks to highlight
my constant @delimiters = ' ', '<', '>', |< : ; , + >;

# Create HTML version of a given entry
sub htmlize($entry, %colors) is export {
    my $text = $entry.message;

    # Something with a text
    if $entry.conversation {
        # escaping <  > and &
        $text .= subst('&', '&amp;', :global);
        $text .= subst('<', '&lt;',  :global);
        $text .= subst('>', '&gt;',  :global);

        # URL linking
        $text .= subst(
          / https? '://' \S+ /,
          { '<a href="' ~ $/~ '">' ~ $/ ~ '</a>' },
          :global
        );

        # Nick highlighting
        if $entry.^name.ends-with("Topic") {
            $text .= subst(/ ^ \S+ /, { colorize-nick($/, %colors) });
        }
        else {
            my str $last-del = ' ';
            $text = $text.split(@delimiters, :v).map(-> $word, $del = '' {
                my $mapped := $word.chars < 3
                  || %stop-nicks{$word.lc}
                  || $last-del ne ' '
                  ?? $word ~ $del
                  !! colorize-nick($word, %colors) ~ $del;
                $last-del = $del;
                $mapped
            }).join;
        }

        # Thought highlighting
        if $entry.^name.ends-with("Self-Reference")
          || $text.starts-with(".oO(") {
            $text = '<div id="thought">' ~ $text ~ '</div>'
        }
    }

    # No text, just do the nick highlighting
    else {
        $text .= subst(/^ \S+ /, { colorize-nick($/, %colors) });

        if $entry.^name.ends-with("Nick-Change") {
            $text .= subst(/ \S+ $/, { colorize-nick($/, %colors) });
        }
        elsif $entry.^name.ends-with("Kick") {
            $text .= subst(/ \S+ $/, { colorize-nick($/, %colors) }, :5th)
        }
    }
    $text
}

# Merge control messages inside the same minute
sub merge-control-messages(@entries) {
    my $merging;
    for @entries.kv -> $index, %entry {
        if !%entry<conversation> {
            if $merging {
                my @events := $merging<control-events>;
                if %entry<hh-mm> -> $hh-mm {
                    @events.push: $hh-mm => [%entry<message>];
                }
                else {
                    @events.tail.value ~= ", %entry<message>";
                }
                $merging<targets>.push: %entry<relative-target>;
                @entries[$index] = Any;
            }
            else {
                $merging := @entries[$index] := Map.new((
                  control-events  => [ %entry<hh-mm> => %entry<message> ],
                  relative-target => %entry<relative-target>,
                  targets         => (my str @targets),
                ));
            }
        }
        elsif $merging {
            $merging := Any;
        }
    }
    @entries.grep(*.defined);
}

# Merge messages of a commit together
sub merge-commit-messages(@entries) {
    for @entries.kv -> $index, %entry {
        if %entry<conversation> {
            my $message := %entry<message>;
            with $message.index(": review:")
              // $message.index(": review:") -> int $pos is copy {

                my $prefix := $message.substr(0,++$pos);
                my $nick   := %entry<nick>;
                my int $i   = $index;
                my int @indices = $index;
                while --$i >= 0 && @entries[$i] -> \entry {
                    last if entry<commit>;  # ran into previous commit
                    @indices.unshift($i)
                      if entry<nick> eq $nick
                      && entry<message>.starts-with($prefix);
                }

                if @indices > 1 {
                    my str @targets = @entries[@indices].map: *<relative-target>;
                    my int $first = @indices.shift;
                    with @entries[$first] -> \entry {
                        entry<message> := entry<message>
                          ~  @entries[@indices].map({
                              "<br/>\n&nbsp;&nbsp;" ~ .<message>.substr($pos)
                          }).join;
                        entry<targets> := @targets;
                        entry<commit>  := True;
                    }
                    @entries[$_] := Any for @indices;
                }
            }
        }
    }
    @entries.grep(*.defined);
}

# Merge messages of test-t report together
sub merge-test-t-messages(@entries) {
    my constant %head = Set.new: <
      csv-ip5xs csv-ip5xs-20 csv-parser csv-test-xs-20
      test test-t test-t-20
    >;
    my constant Tux   = '[Tux]' | '[TuxCM]' | '|Tux|';

    for @entries.kv -> $index, \entry {
        # An entry by Tux?
        if entry
          && entry<conversation>
          && entry<nick> eq Tux
          && entry<message> -> \message {
            my $nick-used := entry<nick>;

            # The start of a test result stream?
            with message.index(' ') -> \pos {
                if message.substr(0,pos) eq 'Rakudo' {

                    # Start looking for test result stream.  Allow for up to
                    # three messages inbetween.
                    my int @indices;
                    my int $i = $index;
                    my int $skipped;
                    while @entries[++$i] -> \this-entry {
                        if this-entry<nick> eq $nick-used {
                            last   # ran into another test result stream
                              if this-entry<message>.substr(0,pos) eq 'Rakudo';
                            @indices.push: $i;
                            $skipped = 0;
                        }
                        elsif ++$skipped == 3 {
                            last;
                        }
                    }
                    next unless @indices;  # nothing found

                    # Collect the test-stream, remove entries after collection
                    my %tests;
                    for @entries[@indices] -> \this-entry {
                        given this-entry<message> {
                            %tests{.substr(0, .index(' '))} := $_;
                            this-entry = Any;
                        }
                    }

                    # Synthesize the new message
                    entry<message> := '<table><tr colspan="4">'
                      ~ message
                      ~ "</tr>\n"
                      ~ %tests.sort.map( -> (:key($name), :value($message)) {
                        '<tr>'
                          ~ ('<td>' ~ $name ~ '</td>')
                          ~ $message.words.skip.map({
                              '<td align="right">'
                                ~ $_
                                ~ '</td>'
                            })
                          ~ "</tr>"
                        }).join("\n")
                      ~ '</table>';
                    entry<test-t>  := True;
                }
            }
        }
    }
    @entries.grep(*.defined);
}

# Check for invocations of Camelia, assume it's code
sub mark-camelia-invocations(@entries --> Nil) {
    for @entries -> \entry {
        if entry<conversation> && entry<message> -> \message {
            entry<message> := message.substr(0,3)
              ~ '<div id="code">'
              ~ message.substr(3)
              ~ '</div>'
            if message.starts-with('m: ');
        }
    }
}

sub day-plugins() is export {
    my constant @day-plugins =
      &merge-commit-messages, 
      &merge-test-t-messages, 
      &merge-control-messages,
      &mark-camelia-invocations
    ;
}

=begin pod

=head1 NAME

App::Raku::Log - Cro application for presenting Raku IRC logs

=head1 SYNOPSIS

=begin code :lang<raku>

$ ./start

$ ./start logs base

=end code

=head1 DESCRIPTION

App::Raku::Log is ...

=head1 AUTHOR

Elizabeth Mattijsen <liz@wenzperl.nl>

Source can be located at: https://github.com/lizmat/App-Raku-Log . Comments and
Pull Requests are welcome.

=head1 COPYRIGHT AND LICENSE

Copyright 2021 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod

# vim: expandtab shiftwidth=4
