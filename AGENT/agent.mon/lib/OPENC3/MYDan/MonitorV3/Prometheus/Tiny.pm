package OPENC3::MYDan::MonitorV3::Prometheus::Tiny;
# From module Prometheus::Tiny;
use warnings;
use strict;

use Carp qw(croak);

my $DEFAULT_BUCKETS = [
               0.005,
  0.01, 0.025, 0.05, 0.075,
  0.1,  0.25,  0.5,  0.75,
  1.0,  2.5,   5.0,  7.5,
  10
];

sub new {
  my ($class) = @_;
  return bless {
    metrics => {},
    meta => {},
    time => {},
    lasttime => 0,
  }, $class;
}

sub _format_labels {
  my ($self, $labels) = @_;
  join ',', map {
    my $lv = $labels->{$_};
    $lv =~ s/(["\\])/\\$1/sg;
    $lv =~ s/\n/\\n/sg;
    qq{$_="$lv"}
  } sort keys %$labels;
}

sub set {
  my ($self, $name, $value, $labels, $timestamp, $step ) = @_;
   
  $step //= 60;
  my $f_label = $self->_format_labels($labels);
  $self->{metrics}{$name}{$f_label} = [ $value, $timestamp ];

  #用于清理过期的数据

  $self->{time}{$name}{$f_label} = time + $step + 15;
  $self->_cleartimeout( time );

  return;
}

sub _cleartimeout {
  my ($self, $time ) = @_;

  return if $self->{lasttime} + 5 > $time;

  $self->{lasttime} = $time;

  for my $name ( keys %{$self->{time}} )
  {
      for my $label ( keys %{$self->{time}{$name}} )
      {
          my $t = $self->{time}{$name}{$label};
          if( $t < $time )
          {
              if( $name eq 'node_collector_error' )
              {
                  $self->{metrics}{$name}{$label}[0] = 2;
              }
              else
              {
                  delete $self->{time}{$name}{$label};
                  delete $self->{metrics}{$name}{$label};
              }
          }
      }

      next if $name eq 'node_collector_error';

      unless( keys %{$self->{time}{$name}} )
      {
          delete $self->{time}{$name};
          delete $self->{metrics}{$name};
      }
  }

  return;
}

sub add {
  my ($self, $name, $value, $labels) = @_;
  $self->{metrics}{$name}{$self->_format_labels($labels)}->[0] += $value;
  return;
}

sub inc {
  my ($self, $name, $labels) = @_;
  return $self->add($name, 1, $labels);
}

sub dec {
  my ($self, $name, $labels) = @_;
  return $self->add($name, -1, $labels);
}

sub clear {
  my ($self, $name) = @_;
  $self->{metrics} = {};
  return;
}

sub histogram_observe {
  my ($self, $name, $value, $labels) = @_;

  $self->inc($name.'_count', $labels);
  $self->add($name.'_sum', $value, $labels);

  my @buckets = @{$self->{meta}{$name}{buckets} || $DEFAULT_BUCKETS};

  my $bucket_metric = $name.'_bucket';
  for my $bucket (@buckets) {
    $self->add($bucket_metric, $value <= $bucket ? 1 : 0, { %{$labels || {}} , le => $bucket });
  }
  $self->inc($bucket_metric, { %{$labels || {}}, le => '+Inf' });

  return;
}

sub enum_set {
  my ($self, $name, $value, $labels, $timestamp) = @_;

  my $enum_label = $self->{meta}{$name}{enum} ||
    croak "enum not declared for '$name'";

  for my $ev (@{$self->{meta}{$name}{enum_values} || []}) {
    $self->set($name, $value eq $ev ? 1 : 0, { %{$labels || {}}, $enum_label => $ev }, $timestamp);
  }
}

sub declare {
  my ($self, $name, %meta) = @_;

  if (my $old = $self->{meta}{$name}) {
    if (
      ((exists $old->{type} ^ exists $meta{type}) ||
       (exists $old->{type} && $old->{type} ne $meta{type})) ||
      ((exists $old->{help} ^ exists $meta{help}) ||
       (exists $old->{help} && $old->{help} ne $meta{help})) ||
      ((exists $old->{enum} ^ exists $meta{enum}) ||
       (exists $old->{enum} && $old->{enum} ne $meta{enum})) ||
      ((exists $old->{buckets} ^ exists $meta{buckets}) ||
       (exists $old->{buckets} && (
        @{$old->{buckets}} ne @{$meta{buckets}} ||
        grep { $old->{buckets}[$_] != $meta{buckets}[$_] } (0 .. $#{$meta{buckets}})
       ))
      ) ||
      ((exists $old->{enum_values} ^ exists $meta{enum_values}) ||
       (exists $old->{enum_values} && (
        @{$old->{enum_values}} ne @{$meta{enum_values}} ||
        grep { $old->{enum_values}[$_] ne $meta{enum_values}[$_] } (0 .. $#{$meta{enum_values}})
       ))
      )
    ) {
      croak "redeclaration of '$name' with mismatched meta";
    }
  }

  $self->{meta}{$name} = { %meta };
  return;
}

sub format {
  my ($self) = @_;
  my %names = map { $_ => 1 } (keys %{$self->{metrics}}, keys %{$self->{meta}});
  return join '', map {
    my $name = $_;
    (
      (defined $self->{meta}{$name}{help} ?
        ("# HELP $name $self->{meta}{$name}{help}\n") : ()),
      (defined $self->{meta}{$name}{type} ?
        ("# TYPE $name $self->{meta}{$name}{type}\n") : ()),
      (map {
        my $v = join ' ', grep { defined $_ } @{$self->{metrics}{$name}{$_}};
        $_ ?
          join '', $name, '{', $_, '} ', $v, "\n" :
          join '', $name, ' ', $v, "\n"
      } sort {
        $name =~ m/_bucket$/ ?
          do {
            my $t_a = $a; $t_a =~ s/le="([^"]+)"//; my $le_a = $1;
            my $t_b = $b; $t_b =~ s/le="([^"]+)"//; my $le_b = $1;
            $t_a eq $t_b ?
              do {
                $le_a eq '+Inf' ? 1 :
                $le_b eq '+Inf' ? -1 :
                ($a cmp $b)
              } :
              ($a cmp $b)
          } :
          ($a cmp $b)
      } keys %{$self->{metrics}{$name}}),
    )
  } sort keys %names;
}

1;
