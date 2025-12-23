package Nipe::Component::Engine::Stop {
	use strict;
	use warnings;
	use Nipe::Component::Utils::Device;
    use Nipe::Component::Engine::Spoof;

	our $VERSION = '0.0.4';

	sub new {
		my %device  = Nipe::Component::Utils::Device -> new();
		my @table   = qw(nat filter);
		my $stop_tor = 'systemctl stop tor';

		if ($device{distribution} eq 'darwin') {
			# system "pfctl -F all -f /etc/pf.conf"; # No longer used
            
             # Disable proxy for all likely services or detect it?
             # Detection is better.
             my $interface = `route get default | grep interface | awk '{print \$2}'`;
             chomp $interface;
             my $service = `networksetup -listallhardwareports | grep -B 1 "$interface" | head -n 1 | cut -d: -f2 | xargs`;
             chomp $service;
             
             if ($service) {
                 print "[+] Disabling macOS System SOCKS Proxy on '$service'...\n";
                 system "networksetup -setsocksfirewallproxystate \"$service\" off";
             } else {
                 print "[+] Disabling macOS System SOCKS Proxy on 'Wi-Fi'...\n";
                 system "networksetup -setsocksfirewallproxystate \"Wi-Fi\" off";
             }

            print "[+] Disabling Kill Switch (Flushing PF rules)...\n";
            system "sudo pfctl -F all 2>/dev/null"; # Flush rules

            print "[+] Stopping Tor process...\n";
            system "killall tor 2>/dev/null"; 

            # Restore Identity
            Nipe::Component::Engine::Spoof->new()->stop();

            print "[+] Nipe stopped. Connectivity restored.\n";
			return 1;
		}

		if ($device{distribution} eq 'void') {
			$stop_tor = 'sv stop tor > /dev/null';
		}

		foreach my $table (@table) {
			system "iptables -t $table -F OUTPUT";

			if (-d '/proc/sys/net/ipv6') {
				system "ip6tables -t $table -F OUTPUT";
			}
		}

		if ( -e '/etc/init.d/tor' ) {
			$stop_tor = '/etc/init.d/tor stop > /dev/null';
		}

		system $stop_tor;

		return 1;
	}
}

1;