unit role Pluggable;

use JSON::Fast;
use File::Find;

# XXX pod
# XXX README.md

method plugins(:$base = Nil, :$plugins-namespace = 'Plugins', :$matcher = Nil) {
    my $class = "{$base.defined ?? $base !! ::?CLASS.^name}";
    return find-modules($class, $plugins-namespace, $matcher);
}

# procedural interface
sub plugins(:$base = Nil, :$plugins-namespace = 'Plugins', :$matcher = Nil) is export {
    return find-modules($base, $plugins-namespace, $matcher);
}

my sub match-try-add-module($module-name, $base, $namespace, $matcher, @result) {
    # XXX should not match if exactly the starts-with string, test case 02 can
    # be modified to check by removing matcher, or create an extra .pm6 in CaseA
    if ($module-name.starts-with("{$base}::{$namespace}")) {
        if ((!defined $matcher) || ($module-name ~~ $matcher)) {
            try {
                CATCH {
                    default {
                         say .WHAT.perl, do given .backtrace[0] { .file, .line, .subname }
                    }
                }
                require ::($module-name);
                say "!!A!!!!! $module-name";
                my $string = "ofenrohr";
                # XXX we should filtert out non-class units in the
                # oop case...
                # say ::($f).HOW;
                @result.push(::($module-name));
            }
        }
    }
}

# XXX remove debug output
my sub find-modules($base, $namespace, $matcher) {
    my @result = ();
#    say "base: " ~ $base;
#    say "namespace: " ~ $namespace;

    for $*REPO.repo-chain -> $r {
        given $r.WHAT {
            when CompUnit::Repository::FileSystem { 
#                say "  # filesystem {$r.prefix}";
                my @files = find(dir => $r.prefix, name => /\.pm6?$/);
                @files = map(-> $s { $s.substr($r.prefix.chars + 1) }, @files);
                @files = map(-> $s { $s.substr(0, $s.rindex('.')) }, @files);
                @files = map(-> $s { $s.subst(/\//, '::', :g) }, @files);
#                say "    " ~ @files;
                for @files -> $f {
                    match-try-add-module($f, $base, $namespace, $matcher, @result);
                }
            }
            when CompUnit::Repository::Installation {
                # XXX once $r.installed() is fixed, this can get much
                # shorter...
#                say "  # installation {$r.prefix}";
                my $dist_dir = $r.prefix.child('dist');
                if ($dist_dir.?e) {
                    for $dist_dir.IO.dir.grep(*.IO.f) -> $idx_file {
                        my $data = from-json($idx_file.IO.slurp);
#                        say "    " ~ $data{'provides'}.keys.perl;
                        for $data{'provides'}.keys -> $f {
                            match-try-add-module($f, $base, $namespace, $matcher, @result);
                        }    
                    }
                }
                #say "@@@" ~ $r.WHAT;
                #say "@@@" ~ $r.installed();
            }
            default { 
#                say "  # unknown repository type " ~ $r.WHAT.perl; 
            }
        }
    }
    say @result.perl;
    return @result.unique.Array;
}

