use v6.*;

use App::IRC::Log:ver<0.0.1>:auth<cpan:ELIZABETH>;
use IRC::Channel::Log:ver<0.0.24>:auth<cpan:ELIZABETH>;
use JSON::Fast:ver<0.15>;
use RandomColor;

#-------------------------------------------------------------------------------
# Stuff for creating values for templates

# Hash for humanizing dates
my constant @human-months = <?
  January February March April May June July
  August September October November December
>;

# Turn a YYYY-MM-DD date into a human readable date
sub human-date(str $date, str $del = ' ', :$short) {
    if $date {
        my $chars := $short ?? 3 !! *;
        $date.substr(8,2).Int
          ~ $del
          ~ @human-months[$date.substr(5,2)].substr(0,$chars)
          ~ $del
          ~ $date.substr(0,4)
    }
}

# Turn a YYYY-MM-DD date into a human readable month
sub human-month(str $date, str $del = ' ', :$short) {
    if $date {
        my $chars := $short ?? 3 !! *;
        @human-months[$date.substr(5,2)].substr(0,$chars)
          ~ $del
          ~ $date.substr(0,4)
    }
}

# Month pulldown
my constant @template-months =
   1 => "Jan",
   2 => "Feb",
   3 => "Mar",
   4 => "Apr",
   5 => "May",
   6 => "Jun",
   7 => "Jul",
   8 => "Aug",
   9 => "Sep",
  10 => "Oct",
  11 => "Nov",
  12 => "Dec";

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

# Default color generator
sub generator($) {
    RandomColor.new(:luminosity<bright>).list.head
}

# Create HTML to colorize a word as a nick
sub colorize-nick(Str() $nick, %colors) {
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
sub htmlize($entry, %colors) {
    my $text = $entry.message;

    # Something with a text
    if $entry.conversation {

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
        if %entry<ordinal> {
            if %entry<control> {
                if $merging || @entries[$index - 1]<control> {
                    $merging = $index - 1 without $merging;
                    @entries[$merging]<message> ~= ", %entry<message>";
                    @entries[$index] = Any;
                }
            }
            else {
                $merging = Any;
            }
        }
        else {
            $merging = Any;
        }
    }
    @entries.grep(*.defined);
}

# Merge messages of a commit together
sub merge-commit-messages(@entries) {
    for @entries.kv -> $index, %entry {
        if %entry<conversation> {
            with %entry<message>.index(
              ": review:"
            ) -> int $pos is copy {
                my $message := %entry<message>;
                my $prefix  := $message.substr(0,++$pos);
                my int $i    = $index;
                while --$i >= 0 && @entries[$i] -> \entry {
                    last unless entry<message>.starts-with($prefix);
                }

                if ++$i < $index {
                    my int $final = $i;
                    my str $message = @entries[$i]<message>;
                    while ++$i <= $index && @entries[$i] -> \entry {
                        $message = $message
                          ~ '<br/> &nbsp;&nbsp;'
                          ~ entry<message>.substr($pos);
                        entry = Any;
                    }
                    with @entries[$final] -> \entry {
                        entry<message> := $message;
                        entry<commit>  := True;
                    }
                }
            }
        }
    }
    @entries = @entries.grep(*.defined);
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

#-------------------------------------------------------------------------------
# App::Raku::Logs class
#
# Determine default channels from a given directory
my sub default-channels(IO:D $log-dir) {
    $log-dir.dir.map({
      .basename
      if .d
      && !.basename.starts-with('.')
      && .dir(:test(/ ^ \d\d\d\d $ /)).elems
    }).sort
}

class App::Raku::Log:ver<0.0.1>:auth<cpan:ELIZABETH> {
    has         $.log-class     is required is built(:bind);
    has IO()    $.log-dir       is required;
    has IO()    $.html-dir      is required;
    has IO()    $.templates-dir is required;
    has IO()    $.state-dir     is required;
    has         &.htmlize is built(:bind) = &htmlize;
    has Instant $.liftoff is built(:bind) = $?FILE.words.head.IO.modified;
    has str     @.channels    = default-channels($!log-dir);
    has         @.day-plugins = (&merge-control-messages,
                                 &merge-commit-messages,
                                 &mark-camelia-invocations
                                ).Slip;
    has         %!channels;

    my constant $nick-colors-json = 'nicks.json';

    # Start loading the logs asynchronously.  No need to be thread-safe
    # here as here will only be the thread creating the object.
    submethod TWEAK(--> Nil) {
        %!channels{$_} := start {
            my $clog := IRC::Channel::Log.new:
              logdir    => $!log-dir.add($_),
              class     => $!log-class,
              generator => &generator,
              state     => $!state-dir.add($_),
              name      => $_;
            $clog.watch-and-update if $clog.active;
            $clog;
        } for @!channels;
    }

    # Perform all actions associated with shutting down.
    # Expected to be run *after* the application has stopped.
    method shutdown(App::IRC::Log:D: --> Nil) {
        self.clog($_).shutdown for @!channels;
    }

    # Return IRC::Channel::Log object for given channel
    method clog(App::IRC::Log:D: str $channel --> IRC::Channel::Log:D) {

        # Even though this could be called from several threads
        # simultaneously, the key should always exist, so there
        # is no danger of messing up the hash.  The only thing
        # that can happen, is binding the result of the Promise
        # more than once to the hash.
        given %!channels{$channel} {
            if $_ ~~ Promise {
                %!channels{$channel} := .result  # not ready yet
            }
            else {
                $_ // Nil                        # ready, so go!
            }
        }
    }

    # Set up entries for use in template
    method !ready-entries-for-template(\entries, $channel, %colors, :$short) {
        my str $last-date = "";
        my str $last-hhmm = "";
        my str $last-nick = "";
        my int $last-type = -1;
        entries.map: {
            my str $date = .date.Str;
            my str $hhmm = .hh-mm;
            my str $nick = .sender;
            my int $type = .control.Int;
            my $hash := Hash.new((
              channel         => $channel,
              control         => .control,
              conversation    => .conversation,
              date            => $date,
              hh-mm           => $hhmm eq $last-hhmm
                                   && $type == $last-type
                                   ?? ""
                                   !! $hhmm,
              hour            => .hour,
              human-date      => $date eq $last-date
                                   ?? ""
                                   !! human-date($date, "\xa0", :$short),
              message         => &!htmlize($_, %colors),
              minute          => .minute,
              ordinal         => .ordinal,
              relative-target => .target.substr(11),
              sender          => $nick && $nick eq $last-nick
                                   ?? '"'
                                   !! colorize-nick($nick, %colors),
              target          => .target
            ));
            $last-date = $date;
            $last-hhmm = $hhmm;
            $last-nick = $nick;
            $last-type = $type;
            $hash
        }
    }

    # Return IO object for given channel and day
    method !day($channel, $file --> IO:D) {
        my $date := $file.chop(5);
        my $Date := $date.Date;
        my $dir  := $!html-dir.add($channel).add($Date.year);
        my $html := $dir.add($date ~ '.html');
        my $crot := $!templates-dir.add('day.crotmp');

        # Need to (re-)render
        if !$html.e                           # file does not exist
          || $html.modified < $!liftoff       # file is too old
                            | $crot.modified  # or template changed
        {

            # Fetch the log and nick coloring
            my $clog   := self.clog($channel);
            my $log    := $clog.log($date);
            my %colors := $clog.colors;

            # Set up entries for use in template
            my @entries =
              self!ready-entries-for-template($log.entries, $channel, %colors);

            # Run all the plugins
            for @!day-plugins -> &plugin {
                &plugin.returns ~~ Nil
                  ?? plugin(@entries)
                  !! (@entries = plugin(@entries))
            }

            # Render it!
            $dir.mkdir;
            render $html, $crot, {
              :$channel,
              :@!channels,
              :$date,
              :date-human("$Date.day() @human-months[$Date.month] $Date.year()"),
              :next-date($Date.later(:1day)),
              :next-month($date.substr(0,7).succ),
              :next-year($date.substr(0,4).succ),
              :prev-date($Date.earlier(:1day)),
              :prev-month($clog.is-first-date-of-month($date)
                ?? "this/$Date.earlier(:1month).first-date-in-month()"
                !! $date.substr(0,7)
              ),
              :prev-year($clog.is-first-date-of-year($date)
                ?? 'this/' ~ Date.new($Date.year - 1, 1, 1)
                !! $date.substr(0,4)
              ),
              :@entries
            }
        }
        $html
    }

    # Return an IO object for /home.html
    method !home(--> IO:D) {
        my $html := $!html-dir.add('home.html');
        my $crot := $!templates-dir.add('home.crotmp');

        if !$html.e                           # file does not exist
          || $html.modified < $!liftoff       # file is too old
                            | $crot.modified  # or template changed
        {
            my @channels = @!channels.map: -> $channel {
                my $clog  := self.clog($channel);
                my @dates  = $clog.dates;
                my %months = @dates.categorize: *.substr(0,7);
                my %years  = %months.categorize: *.key.substr(0,4);
                my @years  = %years.sort(*.key).map: {
                    Map.new((
                      channel => $channel,
                      year    => .key,
                      months  => .value.sort(*.key).map: {
                         Map.new((
                            channel     => $channel,
                            month       => .key,
                            human-month =>
                              @human-months[.key.substr(5,2)].substr(0,3),
                         ))
                      },
                    ))
                }
                Map.new((
                  name             => $channel,
                  years            => @years,
                  first-date       => @dates.head,
                  first-human-date => human-date(@dates.head),
                  last-date        => @dates.tail,
                  last-human-date  => human-date(@dates.tail),
                ))
            }

            render $html, $crot, {
              channels => @channels,
            }
        }
        $html
    }

    # Return an IO object for /channel/index.html
    method !index(str $channel --> IO:D) {
        my $html := $!html-dir.add($channel).add('index.html');
        my $crot := $!templates-dir.add($channel).add('index.crotmp');
        $crot := $!templates-dir.add('index.crotmp') unless $crot.e;

        if !$html.e                           # file does not exist
          || $html.modified < $!liftoff       # file is too old
                            | $crot.modified  # or template changed
        {
            my $clog  := self.clog($channel);
            my @dates  = $clog.dates;
            my %months = @dates.categorize: *.substr(0,7);
            my %years  = %months.categorize: *.key.substr(0,4);
            my @years  = %years.sort(*.key).reverse.map: {
                Map.new((
                  channel => $channel,
                  year    => .key,
                  months  => .value.sort(*.key).map: {
                     Map.new((
                        month       => .key,
                        human-month => @human-months[.key.substr(5,2)],
                        dates       => .value.map( -> $date {
                            my $log := $clog.log($date);
                            Map.new((
                              control      => $log.nr-control-entries,
                              conversation => $log.nr-conversation-entries,
                              day          => $date.substr(8,2).Int,
                              date         => $date,
                            ))
                        }).List
                     ))
                  },
                ))
            }

            render $html, $crot, {
              name             => $channel,
              channels         => @!channels,
              years            => @years,
              first-date       => @dates.head,
              first-human-date => human-date(@dates.head),
              last-date        => @dates.tail,
              last-human-date  => human-date(@dates.tail),
            }
        }
        $html
    }

    # Convert a string to a regex that stringifies as the string
    sub string2regex(Str:D $string) {
        if $string.contains('{') {   # XXX naive security check
            Nil
        }
        else {
            my $regex = "/ $string /";
            $regex.EVAL but $regex   # XXX fix after RakuAST lands
        }
    }

    # Return content for around target helper
    method !around(
      :$channel!,
      :$around!,
      :$nr-entries,
      :$conversation,
      :$control,
      :$json,
    ) {
        my $crot := $!templates-dir.add('around.crotmp');
        get-template-repository().refresh($crot.absolute)
          if $crot.modified > $!liftoff;
        my $clog := self.clog($channel);

        my %params;
        %params<channel>       := $channel;
        %params<around-target> := $around;
        %params<nr-entries>    := $nr-entries   if $nr-entries;
        %params<control>       := $control      if $control;
        %params<conversation>  := $conversation if $conversation;

        sub find-em() {
            if $clog.entries(|%params) -> @found {
                self!ready-entries-for-template(
                  @found, $channel, $clog.colors, :short
                )
            }
        }

        my $then    := now;
        my @entries  = find-em;
        my $elapsed := ((now - $then) * 1000).Int;

        .<is-target> := True
          given @entries[@entries.first: *.<target> eq $around, :k];

        %params =
          channel => $channel,
          around  => $around,
          elapsed => $elapsed,
          entries => @entries,
        ;

        $json
          ?? to-json(%params,:!pretty)
          !! render-template($crot, %params)
    }

    # Return content for searches
    method !search(
      :$channel!,
      :$nicks        = "",
      :$entries-pp   = 25,
      :$type         = "words",
      :$message-type = "",  # control | conversation
      :$query,
      :$from-year,
      :$from-month,
      :$from-day,
      :$to-year,
      :$to-month,
      :$to-day,
      :$ignorecase,
      :$all,
      :$include-aliases,
      :$first-target,
      :$last-target,
      :$first,
      :$last,
      :$prev,
      :$next,
      :$json,      # return as JSON instead of HTML
    --> Str:D) {
        my $crot := $!templates-dir.add('search.crotmp');
        get-template-repository().refresh($crot.absolute)
          if $crot.modified > $!liftoff;
        my $clog := self.clog($channel);

        # Initial setup of parameters to clog.entries
        my %params;
        %params<all>           := True if $all;
        %params<ignorecase>    := True if $ignorecase;
        %params{$message-type} := True if $message-type;

        # Handle period limitation
        my $from-date;
        if $from-year && $from-month && $from-day {
            $from-date = Date.new($from-year, $from-month, $from-day) // Nil;
        }
        my $to-date;
        if $to-year && $to-month && $to-day {
            $to-date = Date.new($to-year, $to-month, $to-day) // Nil;
        }
        if $from-date || $to-date {
            $from-date = $clog.dates.head.Date unless $from-date;
            $to-date   = $clog.dates.tail.Date unless $to-date;
            ($from-date, $to-date) = ($to-date, $from-date)
              if $to-date < $from-date;
            %params<dates> := $from-date .. $to-date;
        }

        my $moving;
        my $produces-reversed;
        if $first {
            $moving := True;
        }
        elsif $last {
            %params<reverse>   := True;
            $produces-reversed := True;
            $moving            := True;
        }
        elsif $prev && $first-target {
            %params<before-target> := $first-target;
            $produces-reversed     := True;
            $moving                := True;
        }
        elsif $next && $last-target {
            %params<after-target> := $last-target;
            $moving               := True;
        }
        else {  # bare entry
            %params<reverse>   := True;
            $produces-reversed := True;
        }

        my str @errors;
        if $nicks {
            if $nicks.comb(/ \w+ /) -> @nicks {
                if @nicks.map({ $clog.aliases-for-nick($_).Slip }) -> @aliases {
                    %params<nicks> := $include-aliases ?? @aliases !! @nicks;
                }
                else {
                    @errors.push: "'@nicks' not known as nick(s)";
                }
            }
        }

        if $query && $query.words -> @words {
            if $type eq "words" | "contains" | "starts-with" {
                %params{$type} := @words;
            }
            elsif $type eq 'matches' {
                %params<matches> := $_ with string2regex($query);
            }
        }

        my $more;
        sub find-em() {
            my $fetch = $entries-pp + 1;
            if $clog.entries(|%params).head($fetch) -> @found {
                $more := @found == $fetch;
                self!ready-entries-for-template(
                  $produces-reversed
                    ?? @found.head($fetch).reverse
                    !! @found.head($fetch),
                  $channel,
                  $clog.colors,
                  :short
                )
            }
        }

        my $then    := now;
        my @entries  = find-em;
        my $elapsed := ((now - $then) * 1000).Int;

        if !@entries && $moving {
            response.status = 204;
            return "";
        }

        my $first-date := @entries.head<date> // "";
        my $last-date  := @entries.tail<date> // "";
        my @years      := $clog.years;

        %params =
          all                => $all,
          control            => $message-type eq "control",
          conversation       => $message-type eq "conversation",
          channels           => @!channels,
          days               => 1..31,
          elapsed            => ((now - $then) * 1000).Int,
          entries            => @entries,
          entries-pp         => $entries-pp,
          entries-pp-options => <25 50 100 250 500>,
          first-date         => $first-date,
          first-human-date   => human-date($first-date),
          first-target       => @entries.head<target> // "",
          from-day           => $from-day,
          from-month         => $from-month,
          from-year          => $from-year || @years.head,
          ignorecase         => $ignorecase,
          include-aliases    => $include-aliases,
          last-date          => $last-date,
          last-human-date    => human-date($last-date),
          last-target        => @entries.tail<target> // "",
          message-options    => (""           => "all messages",
                                 conversation => "text only",
                                 control      => "control only",
                                ),
          message-type       => $message-type,
          months             => @template-months,
          more               => $more,
          name               => $channel,
          nicks              => $nicks,
          nr-entries         => +@entries,
          query              => $query || "",
          to-day             => $to-day,
          to-month           => $to-month,
          to-year            => $to-year || @years.tail,
          type               => $type,
          type-options       => (words       => "as word(s)",
                                 contains    => "containing",
                                 starts-with => "starting with",
                                 matches     => "as regex",
                                ),
          years              => @years,
        ;

        $json
          ?? to-json(%params,:!pretty)
          !! render-template($crot, %params)
    }

    proto method html(|) is implementation-detail {*}

    # Return an IO object for other HTML files in a channel
    multi method html($channel, $file --> IO:D) {
        my $template := $file.chop(5) ~ '.crotmp';

        my $dir  := $!html-dir.add($channel);
        my $html := $dir.add($file);
        my $crot := $!templates-dir.add($channel).add($template);
        $crot := $!templates-dir.add($template) unless $crot.e;

        # No template, if there's bare HTML, serve it
        if !$crot.e {
            $html.e ?? $html !! Nil
        }

        # May need to render
        else {
            if !$html.e                           # file does not exist
              || $html.modified < $!liftoff       # file is too old
                                | $crot.modified  # or template changed
            {
                $dir.mkdir;
                render $html, $crot, {
                  :$channel,
                }
            }
            $html
        }
    }

    # Return an IO object for other HTML files in root dir
    multi method html($file --> IO:D) {
        my $template := $file.chop(5) ~ '.crotmp';

        my $html := $!html-dir.add($file);
        my $crot := $!templates-dir.add($template);

        # No template, if there's bare HTML, serve it
        if !$crot.e {
            $html.e ?? $html !! Nil
        }

        # May need to render
        else {
            if !$html.e                           # file does not exist
              || $html.modified < $!liftoff       # file is too old
                                | $crot.modified  # or template changed
            {
                render $html, $crot, {
                  channels => @!channels,
                }
            }
            $html
        }
    }

    # Return the actual Cro application to be served
    method application() {
        subset CHANNEL of Str where { $_ (elem) @!channels }

        route {
#            after { note .Str }   # show response headers
            get -> {
                redirect "/home.html", :permanent
            }
            get -> 'home.html' {
                serve-static self!home
            }
            get -> 'search.html', :%args {
dd %args;
                content 'text/html', self!search(|%args)
            }
            get -> 'search.json', :%args {
                content 'text/json', self!search(:json, |%args)
            }
            get -> 'around.html', :%args {
                content 'text/html', self!around(|%args)
            }
            get -> 'around.json', :%args {
                content 'text/json', self!around(:json, |%args)
            }

            get -> CHANNEL $channel {
                redirect "/$channel/index.html", :permanent
            }
            get -> CHANNEL $channel, 'index.html' {
                serve-static self!index($channel)
            }
            get -> CHANNEL $channel, 'search.html', :%args {
                content
                  'text/html; charset=UTF-8',
                  self!search(:$channel, |%args)
            }

            get -> CHANNEL $channel, 'today' {
                redirect "/$channel/"
                  ~ self.clog($channel).this-date(now.Date.Str)
                  ~ '.html';
            }
            get -> CHANNEL $channel, 'first' {
                redirect "/$channel/"
                  ~ self.clog($channel).dates.head
                  ~ '.html';
            }
            get -> CHANNEL $channel, 'last' {
                redirect "/$channel/"
                  ~ self.clog($channel).dates.tail
                  ~ '.html';
            }
            get -> CHANNEL $channel, 'random' {
                redirect "/$channel/"
                  ~ self.clog($channel).dates.roll
                  ~ '.html';
            }

            get -> CHANNEL $channel, YEAR $year {
                my @dates = self.clog($channel).dates;
                redirect "/$channel/"
                  ~ (@dates[finds @dates, $year] || @dates.tail)
                  ~ '.html';
            }
            get -> CHANNEL $channel, MONTH $month {
                my @dates = self.clog($channel).dates;
                redirect "/$channel/"
                  ~ (@dates[finds @dates, $month] || @dates.tail)
                  ~ '.html';
            }

            get -> CHANNEL $channel, 'prev', DATE $date {
                with self.clog($channel).prev-date($date) -> $prev {
                    redirect "/$channel/$prev.html", :permanent
                }
                else {
                    redirect "/$channel/$date.html"
                }
            }
            get -> CHANNEL $channel, 'this', DATE $date {
                redirect "/$channel/"
                  ~ self.clog($channel).this-date($date.Str)
                  ~ '.html';
            }
            get -> CHANNEL $channel, 'next', DATE $date {
                with self.clog($channel).next-date($date) -> $next {
                    redirect "/$channel/$next.html", :permanent
                }
                else {
                    redirect "/$channel/$date.html"
                }
            }

            get -> CHANNEL $channel, DAY $file {
                serve-static self!day($channel, $file);
            }
            get -> CHANNEL $channel, HTML $file {
dd "static";
                serve-static self.html($channel, $file);
            }
            get -> CHANNEL $channel, CSS $file {
                my $io := $!html-dir.add($channel).add($file);
                serve-static $io.e ?? $io !! $!html-dir.add($file)
            }
            get -> CHANNEL $channel, LOG $file {
                my $io := $!log-dir
                  .add($channel)
                  .add($file.substr(0,4))
                  .add($file.chop(4));

                serve-static $io
            }
            get -> HTML $file {
                serve-static self.html($file)
            }

            get -> $file {
                serve-static $!html-dir.add($file)
            }

            get -> |c {
                dd c;
                not-found
            }
        }
    }
}

=begin pod

=head1 NAME

App::IRC::Log - Cro application for presentating IRC logs

=head1 SYNOPSIS

=begin code :lang<raku>

use App::IRC::Log;

=end code

=head1 DESCRIPTION

App::IRC::Log is ...

=head1 AUTHOR

Elizabeth Mattijsen <liz@wenzperl.nl>

Source can be located at: https://github.com/lizmat/App-IRC-Log . Comments and
Pull Requests are welcome.

=head1 COPYRIGHT AND LICENSE

Copyright 2021 Elizabeth Mattijsen

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

=end pod

# vim: expandtab shiftwidth=4
