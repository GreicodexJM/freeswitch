#!/usr/bin/perl
use AnyEvent::RabbitMQ;
use Data::Dumper;

# User Configuration Variables
my $host = 'localhost';
my $port = 5672;
my $user = 'guest';
my $pass = 'guest';
my $exchange = 'TAP.Commands';
my $routing_key = '*.*.*.*.*';


my $cv = AnyEvent->condvar;

my $ar = AnyEvent::RabbitMQ->new->load_xml_spec()->connect(
    host       => $host,
    port       => $port,
    user       => $user,
    pass       => $pass,
    vhost      => '/',
    timeout    => 1,
    tls        => 0, # Or 1 if you'd like SSL
    on_success => sub {
        my $ar = shift;
        $ar->open_channel(
            on_success => sub {
                my $channel = shift;

                $channel->publish(body => $ARGV[1],
                                  header => { content_type => 'text/plain' },
                                  exchange => $exchange,
                                  routing_key => $ARGV[0]);
                $cv->send;
            },
            on_failure => $cv,
            on_close   => sub {
                my $method_frame = shift->method_frame;
                die $method_frame->reply_code, $method_frame->reply_text;
            },
            );
    },
    on_failure => sub {
	$cv;
    },
    on_read_failure => sub {
	die @_ },
    on_return  => sub {
	my $frame = shift;
	die "Unable to deliver ", Dumper($frame);
    },
    on_close   => sub {
	my $why = shift;
	if (ref($why)) {
	    my $method_frame = $why->method_frame;
	    die $method_frame->reply_code, ": ", $method_frame->reply_text;
	}
	else {
	    die $why;
	}
    },
    );

print $cv->recv, "\n";
