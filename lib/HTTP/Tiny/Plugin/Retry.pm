package HTTP::Tiny::Plugin::Retry;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

use Time::HiRes qw(sleep);

sub after_request {
    my ($self, $r) = @_;

    $r->{config}{max_attempts} //=
        $ENV{HTTP_TINY_PLUGIN_RETRY_MAX_ATTEMPTS} // 3;
    $r->{config}{delay}        //=
        $ENV{HTTP_TINY_PLUGIN_RETRY_DELAY}        // 2;

    return -1 if $r->{response}{status} !~ /\A[5]/;
    $r->{retries} //= 0;
    return 0 if $r->{config}{max_attempts} &&
        $r->{retries} >= $r->{config}{max_attempts};
    $r->{retries}++;
    my ($http, $method, $url, $options) = @{ $r->{argv} };
    log_trace "Failed requesting %s (%s - %s), retrying in %.1f second(s) (%d of %d) ...",
        $url,
        $r->{response}{status},
        $r->{response}{reason},
        $r->{config}{delay},
        $r->{retries},
        $r->{config}{max_attempts};
    sleep $r->{config}{delay};
    98; # repeat request()
}

1;
# ABSTRACT: Retry failed request

=for Pod::Coverage .+

=head1 SYNOPSIS

 use HTTP::Tiny::Plugin 'Retry' => {
     max_attempts => 3, # optional, default 3
     delay        => 2, # optional, default 2
     retry_if     => qr/^[45]/, # optional, default is only 5xx errors are retried
 };

 my $res  = HTTP::Tiny::Plugin->new->get("http://www.example.com/");


=head1 DESCRIPTION

This plugin retries failed response. By default only retries 5xx failures, as
4xx are considered to be client's fault (but you can configure it with
L</retry_if>).


=head1 CONFIGURATION

=head2 max_attempts

Int.

=head2 delay

Float.

=head2 retry_if

Regex or code. If regex, then will be matched against response status. If code,
will be called with arguments: C<< ($self, $response) >>.


=head1 ENVIRONMENT

=head2 HTTP_TINY_PLUGIN_RETRY_MAX_ATTEMPTS

Int.

=head2 HTTP_TINY_PLUGIN_RETRY_DELAY

Int.


=head1 SEE ALSO

L<HTTP::Tiny::Plugin>
