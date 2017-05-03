unit role Pluggable;

use JSON::Fast;
use File::Find;

# XXX pod

method plugins(:$base = Nil, :$plugins-namespace = 'Plugins', :$name-matcher = Nil) {
    my $class = "{$base.defined ?? $base !! ::?CLASS.^name}";
    return find-modules($class, $plugins-namespace, $name-matcher);
}

# procedural interface
sub plugins($base, :$plugins-namespace = 'Plugins', :$name-matcher = Nil) is export {
    return find-modules($base, $plugins-namespace, $name-matcher);
}

my sub match-try-add-module($module-name, $base, $namespace, $name-matcher, @result) {
    if (   ($module-name.chars > "{$base}::{$namespace}".chars)
        && ($module-name.starts-with("{$base}::{$namespace}")) ) {

        if ((!defined $name-matcher) || ($module-name ~~ $name-matcher)) {
            try {
                CATCH {
                    default {
                         say .WHAT.perl, do given .backtrace[0] { .file, .line, .subname }
                    }
                }
                require ::($module-name);
                @result.push(::($module-name));
            }
        }
    }
}

my sub find-modules($base, $namespace, $name-matcher) {
    my @result = ();

    for $*REPO.repo-chain -> $r {
        given $r.WHAT {
            when CompUnit::Repository::FileSystem { 
                my @files = find(dir => $r.prefix, name => /\.pm6?$/);
                @files = map(-> $s { $s.substr($r.prefix.chars + 1) }, @files);
                @files = map(-> $s { $s.substr(0, $s.rindex('.')) }, @files);
                @files = map(-> $s { $s.subst(/\//, '::', :g) }, @files);
                for @files -> $f {
                    match-try-add-module($f, $base, $namespace, $name-matcher, @result);
                }
            }
            when CompUnit::Repository::Installation {
                # XXX perhaps $r.installed() could be leveraged here, but it
                # seems broken at the moment
                my $dist_dir = $r.prefix.child('dist');
                if ($dist_dir.?e) {
                    for $dist_dir.IO.dir.grep(*.IO.f) -> $idx_file {
                        my $data = from-json($idx_file.IO.slurp);
                        for $data{'provides'}.keys -> $f {
                            match-try-add-module($f, $base, $namespace, $name-matcher, @result);
                        }    
                    }
                }
            }
            # XXX do we need to support more repository types?
        }
    }
    return @result.unique.Array;
}

