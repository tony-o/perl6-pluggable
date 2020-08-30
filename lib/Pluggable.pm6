unit role Pluggable;

use JSON::Fast;
use File::Find;

=begin pod

=head1 NAME

Pluggable - dynamically find modules or classes under a given namespace

This is a modified version orginally based on https://github.com/tony-o/perl6-pluggable.

=head1 SYNOPSIS

Given a set of plugins in your library search path:

  a::Plugins::Plugin1
  a::Plugins::Plugin2
  a::Plugins::PluginClass1::PluginClass2::Plugin3

And an invocation of Pluggable like this:

  use Pluggable;

  class a does Pluggable {
    method listplugins () {
      @($.plugins).map({.perl}).join("\n").say;
    }
  }

  a.new.listplugins;

The following output would be produced:

  a::Plugins::Plugin1
  a::Plugins::Plugin2
  a::Plugins::PluginClass1::PluginClass2::Plugin3

=head1 FEATURES

=item Role as well as procedural interface
=item Custom module name matching
=item Finding plugins outside of the current modules namespace

=head1 DESCRIPTION

=head2 Object-Oriented Interface

When "doing" the Pluggable role, a class can use the "plugins" method:

  $.plugins(:$base = Nil, :$plugins-namespace = 'Plugins', :$name-matcher = Nil)

=head3 :$base (optional)

The base namespace to look for plugins under, if not provided then the namespace from which
pluggable is invoked is used.

=head3 :$plugins-namespace (default: 'Plugins')

The name of the namespace within I<$base> that contains plugins.

=head3 :$name-matcher (optional)

If present, the name of any module found will be compared with this and only returned if they match.

=head2 Procedural Interface

In a similar fashion, the module can be used in a non-OO environment, it exports
a single sub:

  plugins($base, :$plugins-namespace = 'Plugins', :$name-matcher = Nil)

=head3 $base (required)

The base namespace to look for plugins under. Unlike in the OO case, this is required in the procedural interface.

=head3 :$plugins-namespace (default: 'Plugins')

The name of the namespace within I<$base> that contains plugins.

=head3 :$name-matcher (optional)

If present, the name of any module found will be compared with this and only returned if they match.

=head1 LICENSE

Released under the Artistic License 2.0 L<http://www.perlfoundation.org/artistic_license_2_0>

=head1 AUTHORS

=item Robert Lemmen L<robertle@semistable.com>
=item tony-o L<https://www.github.com/tony-o/>

=end pod

my sub find-modules($base, $namespace, $name-matcher) {
  my sub matching-namespaces($dist) {
    return $dist.meta.hash<provides>.keys.grep(-> $module-name {
      ($module-name.chars > "{$base}::{$namespace}".chars)
      && ($module-name.starts-with("{$base}::{$namespace}"))
      && ((!defined $name-matcher) || ($module-name ~~ $name-matcher))
    });
  }

  eager gather for $*REPO.repo-chain.grep(CompUnit::Repository::Installation | CompUnit::Repository::FileSystem) -> $repo {
    my $distributions          := $repo ~~ CompUnit::Repository::FileSystem ?? $repo.distribution !! $repo.installed;
    my $matching-distributions := $distributions.grep({ matching-namespaces($_).elems });
    my $matches-to-process     := $matching-distributions.map(-> $dist {
                                    Hash.new({
                                      distribution   => $dist,
                                      matching-specs => matching-namespaces($dist).map(-> $short-name {
                                                        CompUnit::DependencySpecification.new(
                                                          short-name      => $short-name,
                                                          version-matcher => $dist.meta<version> || True,
                                                          api-matcher     => $dist.meta<api>     || True,
                                                          auth-matcher    => $dist.meta<auth>    || True,
                                                        )
                                                      }),
                                    })
                                  });

    for @$matches-to-process -> %_ [:$distribution, :@matching-specs] {
      for @matching-specs -> $matching-spec {
        try {
          # Ideally this .need() would replace the `require` below it since the require
          # cannot take ver/api/auth attributes. However doing so causes 'no such symbol ...'
          # errors when using `::(...)`. I wonder if the way `require` is working is actually
          # a bug (namespace leaking outside of scope?)
          #$repo.need($matching-spec);
          require ::($matching-spec.short-name);
          take ::($matching-spec.short-name);
        }
      }
    }
  }
}

method plugins(:$base = Nil, :$plugins-namespace = 'Plugins', :$name-matcher = Nil) {
  my $class = "{$base.defined ?? $base !! ::?CLASS.^name}";
  return find-modules($class, $plugins-namespace, $name-matcher);
}

sub plugins($base, :$plugins-namespace = 'Plugins', :$name-matcher = Nil) is export {
  return find-modules($base, $plugins-namespace, $name-matcher);
}

