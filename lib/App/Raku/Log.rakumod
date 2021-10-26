my
class App::Raku::Log:ver<0.0.19>:auth<zef:lizmat> { }  # for Mi6 only

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

# Known top level domains
# https://data.iana.org/TLD/tlds-alpha-by-domain.txt
# Version 2021101701, Last updated Mon Oct 18 07:07:02 2021 UTC
# Excluded because of possible confusion with standard method:
#  new
my constant $tld = set <
aaa aarp abarth abb abbott abbvie abc able abogado abudhabi ac academy
accenture accountant accountants aco actor ad adac ads adult ae aeg aero
aetna af afamilycompany afl africa ag agakhan agency ai aig airbus airforce
airtel akdn al alfaromeo alibaba alipay allfinanz allstate ally alsace
alstom am amazon americanexpress americanfamily amex amfam amica amsterdam
analytics android anquan anz ao aol apartments app apple aq aquarelle ar
arab aramco archi army arpa art arte as asda asia associates at athleta
attorney au auction audi audible audio auspost author auto autos avianca
aw aws ax axa az azure ba baby baidu banamex bananarepublic band bank bar
barcelona barclaycard barclays barefoot bargains baseball basketball
bauhaus bayern bb bbc bbt bbva bcg bcn bd be beats beauty beer bentley
berlin best bestbuy bet bf bg bh bharti bi bible bid bike bing bingo bio
biz bj black blackfriday blockbuster blog bloomberg blue bm bms bmw bn
bnpparibas bo boats boehringer bofa bom bond boo book booking bosch bostik
boston bot boutique box br bradesco bridgestone broadway broker brother
brussels bs bt budapest bugatti build builders business buy buzz bv bw by
bz bzh ca cab cafe cal call calvinklein cam camera camp cancerresearch
canon capetown capital capitalone car caravan cards care career careers
cars casa case cash casino cat catering catholic cba cbn cbre cbs cc cd
center ceo cern cf cfa cfd cg ch chanel channel charity chase chat cheap
chintai christmas chrome church ci cipriani circle cisco citadel citi
citic city cityeats ck cl claims cleaning click clinic clinique clothing
cloud club clubmed cm cn co coach codes coffee college cologne com comcast
commbank community company compare computer comsec condos construction
consulting contact contractors cooking cookingchannel cool coop corsica
country coupon coupons courses cpa cr credit creditcard creditunion
cricket crown crs cruise cruises csc cu cuisinella cv cw cx cy cymru cyou
cz dabur dad dance data date dating datsun day dclk dds de deal dealer
deals degree delivery dell deloitte delta democrat dental dentist desi
design dev dhl diamonds diet digital direct directory discount discover
dish diy dj dk dm dnp do docs doctor dog domains dot download drive dtv
dubai duck dunlop dupont durban dvag dvr dz earth eat ec eco edeka edu
education ee eg email emerck energy engineer engineering enterprises
epson equipment er ericsson erni es esq estate et etisalat eu eurovision
eus events exchange expert exposed express extraspace fage fail fairwinds
faith family fan fans farm farmers fashion fast fedex feedback ferrari
ferrero fi fiat fidelity fido film final finance financial fire firestone
firmdale fish fishing fit fitness fj fk flickr flights flir florist
flowers fly fm fo foo food foodnetwork football ford forex forsale forum
foundation fox fr free fresenius frl frogans frontdoor frontier ftr
fujitsu fun fund furniture futbol fyi ga gal gallery gallo gallup game
games gap garden gay gb gbiz gd gdn ge gea gent genting george gf gg ggee
gh gi gift gifts gives giving gl glade glass gle global globo gm gmail
gmbh gmo gmx gn godaddy gold goldpoint golf goo goodyear goog google gop
got gov gp gq gr grainger graphics gratis green gripe grocery group gs
gt gu guardian gucci guge guide guitars guru gw gy hair hamburg hangout
haus hbo hdfc hdfcbank health healthcare help helsinki here hermes hgtv
hiphop hisamitsu hitachi hiv hk hkt hm hn hockey holdings holiday
homedepot homegoods homes homesense honda horse hospital host hosting
hot hoteles hotels hotmail house how hr hsbc ht hu hughes hyatt hyundai
ibm icbc ice icu id ie ieee ifm ikano il im imamat imdb immo immobilien
in inc industries infiniti info ing ink institute insurance insure int
international intuit investments io ipiranga iq ir irish is ismaili ist
istanbul it itau itv jaguar java jcb je jeep jetzt jewelry jio jll jm
jmp jnj jo jobs joburg jot joy jp jpmorgan jprs juegos juniper kaufen
kddi ke kerryhotels kerrylogistics kerryproperties kfh kg kh ki kia kim
kinder kindle kitchen kiwi km kn koeln komatsu kosher kp kpmg kpn kr krd
kred kuokgroup kw ky kyoto kz la lacaixa lamborghini lamer lancaster
lancia land landrover lanxess lasalle lat latino latrobe law lawyer lb
lc lds lease leclerc lefrak legal lego lexus lgbt li lidl life
lifeinsurance lifestyle lighting like lilly limited limo lincoln linde
link lipsy live living lixil lk llc llp loan loans locker locus loft lol
london lotte lotto love lpl lplfinancial lr ls lt ltd ltda lu lundbeck
luxe luxury lv ly ma macys madrid maif maison makeup man management
mango map market marketing markets marriott marshalls maserati mattel
mba mc mckinsey md me med media meet melbourne meme memorial men menu
merckmsd mg mh miami microsoft mil mini mint mit mitsubishi mk ml mlb
mls mm mma mn mo mobi mobile moda moe moi mom monash money monster
mormon mortgage moscow moto motorcycles mov movie mp mq mr ms msd mt mtn
mtr mu museum mutual mv mw mx my mz na nab nagoya name natura navy nba
nc ne nec net netbank netflix network neustar news next nextdirect
nexus nf nfl ng ngo nhk ni nico nike nikon ninja nissan nissay nl no
nokia northwesternmutual norton now nowruz nowtv np nr nra nrw ntt nu
nyc nz obi observer off office okinawa olayan olayangroup oldnavy ollo
om omega one ong onl online ooo open oracle orange org organic origins
osaka otsuka ott ovh pa page panasonic paris pars partners parts party
passagens pay pccw pe pet pf pfizer pg ph pharmacy phd philips phone
photo photography photos physio pics pictet pictures pid pin ping pink
pioneer pizza pk pl place play playstation plumbing plus pm pn pnc pohl
poker politie porn post pr pramerica praxi press prime pro prod
productions prof progressive promo properties property protection pru
prudential ps pt pub pw pwc py qa qpon quebec quest racing radio raid
re read realestate realtor realty recipes red redstone redumbrella
rehab reise reisen reit reliance ren rent rentals repair report
republican rest restaurant review reviews rexroth rich richardli ricoh
ril rio rip ro rocher rocks rodeo rogers room rs rsvp ru rugby ruhr
run rw rwe ryukyu sa saarland safe safety sakura sale salon samsclub
samsung sandvik sandvikcoromant sanofi sap sarl sas save saxo sb sbi
sbs sc sca scb schaeffler schmidt scholarships school schule schwarz
science scjohnson scot sd se search seat secure security seek select
sener services ses seven sew sex sexy sfr sg sh shangrila sharp shaw
shell shia shiksha shoes shop shopping shouji show showtime si silk
sina singles site sj sk ski skin sky skype sl sling sm smart smile sn
sncf so soccer social softbank software sohu solar solutions song sony
soy spa space sport spot sr srl ss st stada staples star statebank
statefarm stc stcgroup stockholm storage store stream studio study
style su sucks supplies supply support surf surgery suzuki sv swatch
swiss sx sy sydney systems sz tab taipei talk taobao target tatamotors
tatar tattoo tax taxi tc tci td tdk team tech technology tel temasek
tennis teva tf tg th thd theater theatre tiaa tickets tienda tiffany
tips tires tirol tj tjmaxx tjx tk tkmaxx tl tm tmall tn to today tokyo
tools top toray toshiba total tours town toyota toys tr trade trading
training travel travelchannel travelers travelersinsurance trust trv
tt tube tui tunes tushu tv tvs tw tz ua ubank ubs ug uk unicom
university uno uol ups us uy uz va vacations vana vanguard vc ve vegas
ventures verisign versicherung vet vg vi viajes video vig viking
villas vin vip virgin visa vision viva vivo vlaanderen vn vodka
volkswagen volvo vote voting voto voyage vu vuelos wales walmart
walter wang wanggou watch watches weather weatherchannel webcam weber
website wed wedding weibo weir wf whoswho wien wiki williamhill win
windows wine winners wme wolterskluwer woodside work works world wow
ws wtc wtf xbox xerox xfinity xihuan xin xxx xyz yachts yahoo yamaxun
yandex ye yodobashi yoga yokohama you youtube yt yun za zappos zara
zero zip zm zone zuerich zw
>;

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
    my $text = $entry.^name.ends-with('::Topic')
      ?? $entry.text
      !! $entry.message;

    # Something with a text
    if $entry.conversation {
        # escaping <  > and &
        $text = $text
          .subst('&', '&amp;', :global)
          .subst('<', '&lt;',  :global)
          .subst('>', '&gt;',  :global)
        ;

        sub strip-protocol($url) {
            with $url.index('://') {
                $url.substr($_ + 3)
            }
            else {
                $url
            }
        }

        # URLify what looks like a valid domain without protocol
        $text .= subst(/ [^ | \s+] <( \w+ [\. \w+]+ >> /, {
            my $domain := $/.Str;
            $tld{$domain.substr($domain.rindex('.') + 1)}
              ?? "https://$domain"
              !! $domain
        }, :global);

        # URL linking
        $text .= subst( / https? '://' \S+ /, {
            my $link   := $/.Str;
            '<a href="'
              ~ $link
              ~ '">'
              ~ strip-protocol($link.chars > 55
                  ?? "$link.substr(0,42)...$link.substr(*-10)"
                  !! $link
                )
              ~ '</a>'
        }, :global);

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

        # Emotes highlighting
        if $entry.^name.ends-with("Self-Reference") {
            with $text.index('</span>') -> int $index {
                $text = '<em><strong>'
                  ~ $text.substr(0, $index + 7)
                  ~ '</strong>'
                  ~ $text.substr($index + 7)
                  ~ '</em>';
            }
        }
        # Thought highlighting
        elsif $text.starts-with(".oO(") {
            $text = '<div class="thought">' ~ $text ~ '</div>'
        }
    }

    # No text, just do the nick highlighting
    else {
        $text .= subst(/^ \S+ /, { colorize-nick($/, %colors) });

        my str $name = $entry.^name;
        if $name.ends-with("Nick-Change") {
            $text .= subst(/ \S+ $/, { colorize-nick($/, %colors) });
        }
        elsif $name.ends-with("Kick") {
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
                my %params =
                  message => %entry<message>,
                  id      => %entry<relative-target>,
                ;
                with %entry<hh-mm> {
                    %params<hh-mm> = $_;
                }
                else {
                    $merging<control-events>.tail<message> ~= ',';
                }

                $merging<control-events>.push(%params);
                @entries[$index] = Any;
            }
            else {
                $merging := @entries[$index] := Map.new((
                  initial         => True,
                  control-events  => [{
                    hh-mm   => %entry<hh-mm>,
                    message => %entry<message>,
                    id      => %entry<relative-target>,
                  }, ],
                ));
            }
        }
        elsif $merging {
            $merging := Any;
        }
    }
    @entries.grep(*.defined);
}

# Return substring that is between two given strings in a string
my sub between(str $string, str $before, str $after) {
    with $string.index($before) -> int $left {
        with $string.index($after, $left) -> int $right {
            my int $offset = $left + $before.chars;
            $string.substr($offset, $right - $offset)
        }
        else {
            $string
        }
    }
    else {
        $string
    }
}

# Return substring that is before a given string in a string
my sub before(str $string, str $before) {
    with $string.index($before) -> int $left {
        $string.substr(0, $left)
    }
    else {
        $string
    }
}

# Actually convert a set of entries into a single commit entry
my sub transmogrify-commit(@indices, @entries, int $offset) {
    my int $index = @indices.shift;
    my %entry    := @entries[$index];
    %entry<targets> := @entries[@indices].map(*<relative-target>).List;

    my str $first = %entry<message>.substr(2);  # drop the '¦ '
    my int $last-index = @indices.pop;
    my str $last = @entries[$last-index]<message>.substr($offset);
    my str $url  = between($last, '<a href="', '">');
    @entries[$last-index] := Any;

    my str @parts;
    if @indices {
        # Multiple commits
        if $first.contains('commits') {
            @parts.push: $first.subst: / \d+ ' ' commits /, {
                '<a href="' ~ $url ~ '">' ~ $/ ~ '</a>'
            }
            @parts.push("<ul>\n");
            my $base-url := before($url, 'compare');
            for @entries[@indices] {
                my ($sha,$description) = .<message>.substr($offset).split(' | ');
                @parts.push:
                  '<li>- <a href="',
                  $base-url,
                  'commit/',
                  $sha,
                  '">',
                  $description.subst(""),
                  "</a></li>\n";
            }
            @parts.push: "</ul>\n";
        }

        # Only a single commit
        else {
            @parts.push:
              $first.subst(/ ': ' <( \w+ )> /, {
                  '<a href="' ~ $url ~ '">' ~ $/ ~ '</a>'
              }),
              "<br/>\n<em>",
              @entries[@indices.head]<message>.substr($offset),
              "</em><br/>\n";

            my str @subparts;
            sub collect-subparts(--> Nil) {
                @parts.push: "<br/>\n", @subparts.join(' ');
                @subparts = ();
            }

            for @entries[@indices.skip(2)].map(*<message>.substr($offset)) {
                if $_ {
                    if .contains(/^ \W/) {
                        if .match(/ 'commit message has ' <( \d+ ' more lines' /) {
                            @subparts.push: "... ($/)";
                        }
                        else {
                            collect-subparts if @subparts;
                            @parts.push: "<br/>\n&nbsp;&nbsp;", $_;
                        }
                    }
                    else {
                        @subparts.push: " ", $_;
                    }
                }
                else {
                    collect-subparts if @subparts;
                }
            }
            collect-subparts if @subparts;
        }
    }

    # A pull request
    elsif $first.contains('created pull request') {
        with $first.index('request #') -> int $left is copy {
            $left = $left + 8;
            with $first.index(':', $left) -> int $right {
                @parts.push:
                  $first.substr(0, $left),
                  '<a href="',
                  $url,
                  '">',
                  $first.substr($left, $right - $left),
                  '</a>:<br/><em>',
                  $first.substr($right + 2),
                  '</em>';
            }
        }
        @parts.push: $first unless @parts;
    }

    # Commit without additional info
    else {
        @parts.push:
          $first.subst(/ ': ' <( \w+ )> /, {
              '<a href="' ~ $url ~ '">' ~ $/ ~ '</a>'
          }),
          "<br/>\n<em>",
          $last,
          "</em>";
    }

    %entry<message> := @parts.join;
    %entry<initial> := True;
    %entry<commit>  := True;

    @entries[$_] := Any for @indices;
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
                while --$i >= 0 && @entries[$i] -> %this-entry {
                    last if %this-entry<commit>;  # ran into previous commit
                    @indices.unshift($i)
                      if !%this-entry<control-events>
                      &&  %this-entry<nick> eq $nick
                      &&  %this-entry<message>.starts-with($prefix);
                }

                transmogrify-commit(@indices, @entries, ++$pos)
                  if @indices > 1;
            }
        }
    }
    @entries.grep(*.defined);
}

# Constants for test-t testing
my constant @test-t-head = <<
  csv-ip5xs csv-ip5xs-20 csv-parser csv-test-xs-20
  test test-t 'test-t --race' test-t-20 'test-t-20 --race'
>>.sort(-*.chars);
my constant Tux = '[Tux]' | '[TuxCM]' | '|Tux|';
my constant test-t-marker = 'Rakudo v';

sub part-of-test-t($line) {
    @test-t-head.first: { $line.starts-with($_) }
}

# Merge messages of test-t report together
sub merge-test-t-messages(@entries) {
    my constant width = @test-t-head[0].chars;

    for @entries.kv -> $index, \entry {
        # An entry by Tux?
        if entry<conversation>
          && entry<nick> eq Tux
          && entry<message> -> $message {
            my $nick-used := entry<nick>;

            # The start of a test result stream?
            if $message.starts-with(test-t-marker) {

                # Start looking for test result stream.  Allow for up to
                # three messages inbetween.
                my int $i = $index;
                my int $skipped;
                my %tests;
                while @entries[++$i] -> %this-entry {
                    my $this-message := %this-entry<message>;
                    if  !%this-entry<control-events>
                      && %this-entry<nick> eq $nick-used
                      && part-of-test-t($this-message) -> $name {
                        last   # ran into another test result stream
                          if $this-message.starts-with(test-t-marker);
                        %tests{$name} := $this-message.substr(width).words.List;
                        @entries[$i] := Any;
                        $skipped = 0;
                    }
                    elsif ++$skipped == 3 {
                        last;
                    }
                }
                next unless %tests;  # nothing found

                # Synthesize the new message
                entry<message> := '<table><tr colspan="4">'
                  ~ $message
                  ~ "</tr>\n"
                  ~ %tests.sort(*.key).map( -> (:key($name), :value(@times)) {
                    '<tr>'
                      ~ ('<td>' ~ $name ~ '</td>')
                      ~ @times.map({
                          '<td align="right">'
                            ~ $_
                            ~ '</td>'
                        })
                      ~ "</tr>"
                    }).join("\n")
                  ~ '</table>';
                entry<initial> := True;
                entry<test-t>  := True;
            }
        }
    }
    @entries.grep(*.defined);
}

my str @colors = <<
  white black blue green red brown purple orange yellow
  "bright green" teal "bright cyan" "bright blue" pink grey "bright gray"
>>;

# Simple color control code to span handler
sub control2span($text) {
    my str @parts;
    my int $from;  # will never be at 0
    my $in-span := False;
    while (my $index = $text.index("\x[3]", $from)).defined {
        @parts.push($text.substr($from,$index - $from));
        if $in-span {
            @parts.push('</span>');
            $in-span := False;
        }

        my int $advance = 1;
        my $color = $text.substr($index + 1, 1);
        if "0" le $color le "1" {
            with try $text.substr($index + 1, 2).Int {
                $color = @colors[$_] if 0 <= $_ <= 15;
                ++$advance;
            }
            else {
                $color = @colors[$color.ord - "0".ord];
            }
            ++$advance;
        }
        elsif "2" le $color le "9" {
            $color = @colors[$color.ord - "0".ord];
            ++$advance;
        }
        else {
            $color = "";
        }

        if $color {
            @parts.push(qq/<span style="color: $color">/);
            $in-span := True;
        }
        $from = $index + $advance;
    }
    @parts.push($text.substr($from));
    @parts.push('</span>') if $in-span;
    @parts.join
}

# Check for invocations of Camelia, assume it's code
sub mark-camelia-invocations(@entries --> Nil) {
    for @entries.grep(*<conversation>) -> %entry {
        if %entry<message> -> $message {
            if $message.starts-with('m: ') {
                %entry<runcode-link> :=
                  "/" ~ %entry<channel> ~ "/run.html?" ~ %entry<target>;
            }
            else {
                with $message.index(': OUTPUT: «') -> $index {
                    %entry<camelia> := $message.substr(0,$index);
                    my str $output   = $message.substr($index + 11, *-1);
                    $output = $output.chop if $output.ends-with("␤");
                    $output = control2span($output);
                    %entry<message> := $output.subst("␤", "<br/>", :global);
                    %entry<initial> := True;
                }
                orwith $message.index(': ( no output )') -> $index {
                    %entry<camelia> := $message.substr(0,$index);
                    %entry<message> := $message.substr($index + 2);
                    %entry<initial> := True;
                }
            }
        }
    }
}

# Check for Discord bot bridging
my constant discord-bot = 'discord-raku-bot';
sub identify-discord-bridge-users(@entries --> Nil) {
    my str $last-nick;
    for @entries.grep(*<conversation>) -> %entry {
        if %entry<nick> eq discord-bot {
            my (str $nick, str $after) = %entry<message>.substr(4).split('#',2);
            %entry<nick> := $nick;
            if $nick eq $last-nick {
                %entry<same-nick> := True;
            }
            else {
                %entry<same-nick>:delete;
                %entry<sender> := %entry<sender>.subst(
                  discord-bot,
                  '<em title="on Discord">' ~ $nick ~ '</em>'
                );
                $last-nick      = $nick;
            }
            %entry<message> := $after.substr($after.index('&gt;') + 5);
        }
        elsif $last-nick {
            $last-nick = "";
        }
    }
}

sub linkify-modules(@entries --> Nil) is export {
    for @entries.grep(*<conversation>) -> %entry {
        %entry<message> := %entry<message>
          .subst(/ [^ | \s+] <( \w+ ['::' \w+]+ >> /, {
              '<a href="https://raku.land/?q=' ~ $/ ~ '">' ~ $/ ~ '</a>'
          }, :global);
    }
}

sub special-entry($entry --> Bool:D) is export {
    my $message := $entry.message;
    $message.starts-with('¦ ')
      || (($entry.nick eq Tux).Bool && part-of-test-t($message).Bool)
}

sub live-plugins() is export {
    my constant @live-plugins =
      &merge-commit-messages, 
      &merge-test-t-messages, 
      &mark-camelia-invocations,
      &identify-discord-bridge-users,
      &linkify-modules,
    ;
}

sub day-plugins() is export {
    my constant @day-plugins =
      &merge-control-messages,
      &merge-commit-messages, 
      &merge-test-t-messages, 
      &mark-camelia-invocations,
      &identify-discord-bridge-users,
      &linkify-modules,
    ;
}

sub search-plugins() is export {
    my constant @gist-plugins =
      &mark-camelia-invocations,
      &identify-discord-bridge-users,
      &linkify-modules,
    ;
}

sub gist-plugins() is export {
    my constant @gist-plugins =
      &mark-camelia-invocations,
      &identify-discord-bridge-users,
      &linkify-modules,
    ;
}

sub scrollup-plugins() is export {
    my constant @scrollup-plugins =
      &merge-commit-messages, 
      &merge-test-t-messages, 
      &mark-camelia-invocations,
      &identify-discord-bridge-users,
      &linkify-modules,
    ;
}

sub scrolldown-plugins() is export {
    my constant @scrolldown-plugins =
      &merge-commit-messages, 
      &merge-test-t-messages, 
      &mark-camelia-invocations,
      &identify-discord-bridge-users,
      &linkify-modules,
    ;
}

sub descriptions($io) is export {
    $io.dir.map: {
        .basename => .slurp.chomp
          unless .basename.starts-with(".")
    }
}

sub one-liners($io) is export {
    $io.dir.map: {
        .basename => .slurp.chomp
          unless .basename.starts-with(".")
    }
}

sub channel-ordering(@channels) is export {
    my %channels is SetHash = @channels;
    my @ordered = <
      raku
      raku-beginner
    >.grep: { %channels{$_}:delete }

    if <
      raku-dev
      moarvm
    >.grep({ %channels{$_}:delete }) -> @core {
        @ordered.push("-core");
        @ordered.append(@core);
    }

    if <
      cro
      red
      mugs
      raku-land
      raku-gamedev
    >.grep({ %channels{$_}:delete }) -> @associated {
        @ordered.push("-associated");
        @ordered.append(@associated);
    }

    if <
      raku-conf
      raku-steering-council
    >.grep({ %channels{$_}:delete }) -> @community {
        @ordered.push("-community");
        @ordered.append(@community);
    }

    if <
      perl6
      perl6-dev
      p6dev
      perl6-macros
      perl6-toolchain
    >.grep({ %channels{$_}:delete }) -> @historical {
        @ordered.push("-historical");
        @ordered.append(@historical);
    }

    if %channels.keys -> @additional {
        @ordered.push("-additional");
        @ordered.append(@additional.sort);
    }

    @ordered
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
