## no critic (RequireUseStrict)
package Plack::Middleware::Delay;

## use critic (RequireUseStrict)
use strict;
use warnings;
use parent 'Plack::Middleware';

use Plack::Util;

sub call {
    my ( $self, $env ) = @_;

    my $app      = $self->app;
    my $delay    = $self->{'delay'}    || 0;
    my $sleep_fn = $self->{'sleep_fn'} || sub {
        my ( $delay, $invoke ) = @_;

        sleep $delay;

        $invoke->();
    };

    return sub {
        my ( $respond ) = @_;

        $sleep_fn->($delay, sub {
            my $res = $app->($env);

            if(ref($res) eq 'ARRAY') {
                $respond->($res);
            } elsif(ref($res) eq 'CODE') {
                $res->($respond);
            }
        });
    };
}

1;

__END__

# ABSTRACT:  Put delays on your requests

=head1 SYNOPSIS

  use Plack::Builder;

  builder {
      enable 'Delay', delay => 5; # delays the response by five seconds
      $app;
  };

  # or, if you're in an AnyEvent-based PSGI server...

  builder {
      enable 'Delay', delay => 5, sleep_fn => sub {
        my ( $delay, $invoke ) = @_;

        my $timer;
        $timer = AnyEvent->timer(
            after => $delay,
            cb    => sub {
                undef $timer;
                $invoke->();
            },
        );
      };
      $app;
  };

=head1 DESCRIPTION

This middleware imposes an artifical delay on requests, for purposes of
testing.  It could also be used to implement L<http://xkcd.com/862/>.

=head1 OPTIONS

=head2 delay

The number of seconds to sleep.  It can be an integer or a float; however, the
default sleep_fn only works on integers.

=head2 sleep_fn

A subroutine reference that will be called when it's time to go to sleep.  The
subroutine reference will be provided two arguments: the number of seconds to
sleep (ie. the value you provided to L</delay>), and a subroutine reference
that will continue the PSGI application as normal (think of it as a
continuation).

=head1 SEE ALSO

L<Plack>

=cut
