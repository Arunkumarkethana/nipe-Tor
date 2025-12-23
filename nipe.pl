#!/usr/bin/env perl

use 5.030;
use strict;
use warnings;
use Try::Tiny;
use lib './lib/';
use Nipe::Component::Engine::Rotate;
use Nipe::Component::Engine::Stop;
use Nipe::Component::Engine::Start;
use Nipe::Network::Restart;
use Nipe::Component::Utils::Status;
use Nipe::Component::Utils::Helper;
use Nipe::Network::Install;
use English '-no_match_vars';

our $VERSION = '0.0.8';

use Nipe::Component::Utils::Monitor;
use Nipe::Component::Engine::Spoof;

# Start Hooks
sub start_hooks {
    # 1. Check Dependencies (Auto-Install)
    Nipe::Network::Install->new()->check();
}

# Stop Hooks
sub stop_hooks {
    # Cleanup if needed
}

sub main {
    my $argument = $ARGV[0];

    if ($argument) {
		if ($REAL_USER_ID != 0) {
            die "Nipe must be run as root.\n";
        }

        my $commands = {
            stop    => 'Nipe::Component::Engine::Stop',
            start   => 'Nipe::Component::Engine::Start',
            rotate  => 'Nipe::Component::Engine::Rotate',
            monitor => 'Nipe::Component::Utils::Monitor',
            status  => 'Nipe::Component::Utils::Status',
            restart => 'Nipe::Network::Restart',
            install => 'Nipe::Network::Install',
            help    => 'Nipe::Component::Utils::Helper'
        };

        try {
            if ($argument eq 'start') {
                start_hooks();
            }
            if ($argument eq 'stop') {
                stop_hooks();
            }

            my $exec = $commands -> {$argument} -> new();

            if ($exec ne '1') {
                print $exec;
            }
        }

        catch {
            print "\n[!] ERROR: this command could not be run.\n\n";
        };

        return 1;
    }

    return print Nipe::Component::Utils::Helper -> new();
}

main();