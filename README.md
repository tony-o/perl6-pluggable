# Perl6 'Pluggable'

Automatically find modules or classes under a given namespace. This version
is based on https://github.com/tony-o/perl6-pluggable.

## Features

* Role as well as procedural interface
* Custom perl module matching
* Finding plugins outside of the current modules namespace 

## Example

### Installed Plugins
```
a::Plugins::Plugin1
a::Plugins::Plugin2
a::Plugins::PluginClass1::PluginClass2::Plugin3
```

### Invocation
```perl6
use Pluggable; 

class a does Pluggable {
  method listplugins () {
    @($.plugins).map({.perl}).join("\n").say;
  }
}

a.new.listplugins;
```
### Output
```
a::Plugins::Plugin1
a::Plugins::Plugin2
a::Plugins::PluginClass1::PluginClass2::Plugin3
```

## OO Interface

When "doing" the Pluggable role, a class can use the "plugins" method:

    $.plugins(:$base = Nil, :$plugins-namespace = 'Plugins', :$matcher = Nil)

### :$base (optional)

### :$plugins-namespace (default: 'Plugins')

### :$matcher (optional)

## Procedural Interface

In a similar fashion, the module can be used in a non-OO environment, it exports
a single sub:

    plugins($base, :$plugins-namespace = 'Plugins', :$matcher = Nil)

### $base (required)

### :$plugins-namespace (default: 'Plugins')

### :$matcher (optional)

## License

Released under [Artistic License 2.0](http://www.perlfoundation.org/artistic_license_2_0).

## Authors

- [Robert Lemmen] (mailto:Robert Lemmen <robertle@semistable.com>)
- [@tony-o](https://www.github.com/tony-o/)
