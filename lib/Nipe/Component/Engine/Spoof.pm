package Nipe::Component::Engine::Spoof;

use strict;
use warnings;


sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub start {
    my $self = shift;
    
    print "[+] Initiating God Mode (Spoofing)...\n";
    $self->backup();
    
    if ($^O eq 'darwin') {
        $self->spoof_mac_macos();
        $self->spoof_hostname_macos();
    }
    elsif ($^O eq 'linux') {
        $self->spoof_mac_linux();
        $self->spoof_hostname_linux();
    }
    
    return 1;
}

sub stop {
    my $self = shift;
    
    print "[+] Disabling God Mode (Restoring Identity)...\n";
    
    if ($^O eq 'darwin') {
        $self->restore_mac_macos();
        $self->restore_hostname_macos();
    }
    elsif ($^O eq 'linux') {
        $self->restore_mac_linux();
        $self->restore_hostname_linux();
    }
    
    return 1;
}

sub get_interface {
    my $interface;
    if ($^O eq 'darwin') {
        $interface = `route get default | grep interface | awk '{print \$2}'`;
    } else {
        $interface = `ip route show default | awk '/default/ {print \$5}'`;
    }
    chomp($interface);
    return $interface || 'en0'; # Fallback
}

sub backup {
    my $self = shift;
    my $interface = $self->get_interface();

    # Backup MAC
    my $current_mac;
    if ($^O eq 'darwin') {
        $current_mac = `ifconfig $interface | grep ether | awk '{print \$2}'`;
    } else {
        $current_mac = `cat /sys/class/net/$interface/address`;
    }
    chomp($current_mac);
    
    if ($current_mac) {
        open(my $fh, '>', '/tmp/nipe_mac.bak');
        print $fh "$current_mac";
        close $fh;
    }

    # Backup Hostname
    if ($^O eq 'darwin') {
        my $comp_name = `scutil --get ComputerName`;
        my $host_name = `scutil --get HostName`;
        my $local_name = `scutil --get LocalHostName`;
        open(my $fh_host, '>', '/tmp/nipe_host.bak');
        print $fh_host "ComputerName:$comp_name";
        print $fh_host "HostName:$host_name";
        print $fh_host "LocalHostName:$local_name";
        close $fh_host;
    } else {
        my $hostname = `hostname`;
        if ($hostname) {
            open(my $fh_host, '>', '/tmp/nipe_host.bak');
            print $fh_host "$hostname";
            close $fh_host;
        }
    }
}

# --- macOS Methods ---
sub spoof_mac_macos {
    my $self = shift;
    my $interface = $self->get_interface();
    # Reuse previous logic...
    my $current_mac = `ifconfig $interface | grep ether | awk '{print \$2}'`;
    chomp($current_mac);
    my @parts = split(/:/, $current_mac);
    
    if (scalar(@parts) == 6) {
        my @hex = ('0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f');
        my $mac = sprintf("%s:%s:%s:%s%s:%s%s:%s%s", $parts[0], $parts[1], $parts[2], $hex[rand(16)], $hex[rand(16)], $hex[rand(16)], $hex[rand(16)], $hex[rand(16)], $hex[rand(16)]);

        print "[+] Spoofing MAC Address on $interface -> $mac\n";
        system "sudo /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -z 2>/dev/null";
        my $res = `sudo ifconfig $interface ether $mac 2>&1`;
        
        if ($? == 0 && $res eq '') { print "[+] MAC Spoofed Successfully.\n"; } 
        else { print "[!] Notice: MAC Change Rejected by Hardware (Apple Silicon Protection).\n"; }
    }
}

sub spoof_hostname_macos {
    my $self = shift;
    my @names = ('iPad', 'iPhone', 'Windows-PC', 'Office-Desktop', 'Guest-Laptop', 'Printer');
    my $new_name = $names[rand @names];
    print "[+] Sanitizing Hostname -> $new_name\n";
    system "sudo scutil --set ComputerName $new_name";
    system "sudo scutil --set HostName $new_name";
    system "sudo scutil --set LocalHostName $new_name";
}

sub restore_mac_macos {
    my $self = shift;
    my $interface = $self->get_interface();
    if (-f '/tmp/nipe_mac.bak') {
        open(my $fh, '<', '/tmp/nipe_mac.bak');
        my $original_mac = <$fh>;
        close $fh;
        chomp($original_mac);
        print "[+] Restoring Original MAC ($original_mac)...\n";
        system "sudo ifconfig $interface ether $original_mac";
        unlink '/tmp/nipe_mac.bak';
    }
}

sub restore_hostname_macos {
    my $self = shift;
    if (-f '/tmp/nipe_host.bak') {
        print "[+] Restoring Original Hostnames...\n";
        open(my $fh, '<', '/tmp/nipe_host.bak');
        while (my $line = <$fh>) {
            chomp($line);
            if ($line =~ /^ComputerName:(.*)/) { system "sudo scutil --set ComputerName \"$1\""; }
            if ($line =~ /^HostName:(.*)/) { system "sudo scutil --set HostName \"$1\""; }
            if ($line =~ /^LocalHostName:(.*)/) { system "sudo scutil --set LocalHostName \"$1\""; }
        }
        close $fh;
        unlink '/tmp/nipe_host.bak';
    }
}

# --- Linux Methods ---
sub spoof_mac_linux {
    my $self = shift;
    my $interface = $self->get_interface();
    print "[+] Spoofing MAC on Linux ($interface)...\n";
    
    # Simple random MAC
    my @hex = ('0','1','2','3','4','5','6','7','8','9','a','b','c','d','e','f');
    my $mac = sprintf("02:%s%s:%s%s:%s%s:%s%s:%s%s", $hex[rand(16)], $hex[rand(16)], $hex[rand(16)], $hex[rand(16)], $hex[rand(16)], $hex[rand(16)], $hex[rand(16)], $hex[rand(16)], $hex[rand(16)], $hex[rand(16)]);
    
    system "ip link set dev $interface down";
    system "ip link set dev $interface address $mac";
    system "ip link set dev $interface up";
}

sub spoof_hostname_linux {
    my $self = shift;
    my @names = ('debian-server', 'ubuntu-guest', 'fedora-workstation', 'centos-node');
    my $new_name = $names[rand @names];
    print "[+] Sanitizing Hostname -> $new_name\n";
    system "hostnamectl set-hostname $new_name";
}

sub restore_mac_linux {
    my $self = shift;
    my $interface = $self->get_interface();
    if (-f '/tmp/nipe_mac.bak') {
        open(my $fh, '<', '/tmp/nipe_mac.bak');
        my $original_mac = <$fh>;
        close $fh;
        chomp($original_mac);
        print "[+] Restoring MAC ($original_mac)...\n";
        system "ip link set dev $interface down";
        system "ip link set dev $interface address $original_mac";
        system "ip link set dev $interface up";
        unlink '/tmp/nipe_mac.bak';
    }
}

sub restore_hostname_linux {
    my $self = shift;
    if (-f '/tmp/nipe_host.bak') {
        print "[+] Restoring Hostname...\n";
        open(my $fh, '<', '/tmp/nipe_host.bak');
        my $hostname = <$fh>;
        close $fh;
        chomp($hostname);
        system "hostnamectl set-hostname $hostname";
        unlink '/tmp/nipe_host.bak';
    }
}

1;
