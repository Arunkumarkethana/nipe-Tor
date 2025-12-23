package Nipe::Component::Utils::Monitor;

use strict;
use warnings;
use Term::ANSIColor;

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    
    # Hide cursor
    print "\e[?25l";
    
    # Clean exit on Ctrl+C
    $SIG{INT} = sub { 
        print "\e[?25h"; # Show cursor
        print "\n[!] Monitor stopped.\n"; 
        exit; 
    };

    $self->dashboard();
    return $self;
}

sub dashboard {
    my $self = shift;
    
    while (1) {
        system("clear");
        print color('bold blue');
        print "=================================================\n";
        print "          NIPE SPY DASHBOARD (GOD MODE)          \n";
        print "=================================================\n\n";
        print color('reset');

        # 1. Connection Status
        my $status_cmd = ($^O eq 'darwin') 
            ? "curl -s --max-time 2 --socks5-hostname 127.0.0.1:9050 https://check.torproject.org/api/ip"
            : "curl -s --max-time 2 --socks5-hostname 127.0.0.1:9050 https://check.torproject.org/api/ip";
            
        my $status = `$status_cmd`;
        
        if ($status =~ /"IsTor":true,"IP":"(.*?)"/) {
            my $ip = $1;
            print color('bold green');
            print " [STATUS]      : ANONYMOUS (SECURE)\n";
            print " [CURRENT IP]  : $ip\n";
            print color('reset');
        } else {
            print color('bold red');
            print " [STATUS]      : DISCONNECTED / UNSAFE\n";
            print color('reset');
        }

        # 2. Spoofing Status
        if (-f '/tmp/nipe_mac.bak') {
            print color('bold yellow');
            print " [GHOST MODE]  : ACTIVE (MAC Spoofed)\n";
            print color('reset');
        } else {
             print " [GHOST MODE]  : INACTIVE\n";
        }
        
        # 3. Hostname
        my $hostname;
        if ($^O eq 'darwin') {
            $hostname = `scutil --get ComputerName`;
        } else {
            $hostname = `hostname`;
        }
        chomp($hostname);
        print " [IDENTITY]    : $hostname\n";

        print "\n";
        print color('white');
        print " [INFO] IP Automatically rotates every 60s.\n";
        print " [INFO] Press Ctrl+C to exit monitor.\n";
        print color('reset');
        
        sleep 5;
    }
}

1;
