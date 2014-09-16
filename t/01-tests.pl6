#!/usr/bin/env perl6

use Pluggable; 
use Test;

plan 8;

class Power does Pluggable {
  has %.testcases = 
    'Power::Plugins::Teaser::Helpers' => True,
    'Power::Plugins::Teaser'          => True,
    'Power::DontMatch'                => False,
  ;

  method test() {
    my @plugins = @( $.plugins );
    my ($test, $count);
    $count = 0;
    for %.testcases.keys -> $k {
      $test = False;
      for @plugins -> $p {
        $test = True, last if $p eq $k;
      }
      $count++ if True ~~ %.testcases{$k};
      is %.testcases{$k}, $test, "Test: $k";
    }
  }
};

class Checker2 does Pluggable {
  has %.testcase1 = 
    'Power::Plugins::Teaser::Helpers' => True,
    'Power::Plugins::Teaser'          => True,
    'Power::DontMatch'                => False,
  ;
  has %.testcase2 = 
    'Checker2::PluginDir::Plugin1'    => True,
    'Checker2::PluginDir::Plugin3'    => True,
  ;

  method test() {
    my @plugins = @( $.plugins(:module('Power'), :plugin('Plugins')) );
    my ($test, $count);
    $count = 0;
    for %.testcase1.keys -> $k {
      $test = False;
      for @plugins -> $p {
        $test = True, last if $p eq $k;
      }
      $count++ if True ~~ %.testcase1{$k};
      is %.testcase1{$k}, $test, "Test: $k";
    }

    @plugins = @( $.plugins(:pattern(/ [ '.pm' | '.pm6' ] $ /), :plugin('PluginDir')) );
    $count = 0;
    for %.testcase2.keys -> $k {
      $test = False;
      for @plugins -> $p {
        $test = True, last if $p eq $k;
      }
      $count++ if True ~~ %.testcase2{$k};
      is %.testcase2{$k}, $test, "Test: $k";
    }
    
  }
};

Power.new.test;
Checker2.new.test;
