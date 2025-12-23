package Nipe::Component::Engine::Start {
	use strict;
	use warnings;
	use Nipe::Component::Utils::Device;
	use Nipe::Component::Utils::Status;
    use Nipe::Component::Engine::Stop;
    use Nipe::Component::Engine::Spoof;

	our $VERSION = '0.0.7';

	sub new {
        # Activate God Mode (Spoofing)
        Nipe::Component::Engine::Spoof->new()->start();

        my $stop          = Nipe::Component::Engine::Stop -> new();
		my %device        = Nipe::Component::Utils::Device -> new();
		my $dns_port      = '9061';
		my $transfer_port = '9051';
		my @table         = qw(nat filter);
		my $network       = '10.66.0.0/255.255.0.0';
		my $network_ipv6  = 'fd00::/8';
		my $start_tor     = 'systemctl start tor';

		if ($device{distribution} eq 'darwin') {
            my $config_path   = '.configs/darwin-torrc';
            my $tmp_config    = '/tmp/nipe_torrc';
            
            # Copy config to /tmp, removing 'User' line to avoid conflict with sudo -u daemon
            system "grep -v 'User' $config_path > $tmp_config";
            system "chown daemon:daemon $tmp_config";

			system "sudo -u daemon tor -f $tmp_config > /dev/null &";
            
            # Find the active interface (default route)
            my $interface = `route get default | grep interface | awk '{print \$2}'`;
            chomp $interface;
            
            # Find the Service Name for this interface
            my $service = `networksetup -listallhardwareports | grep -B 1 "$interface" | head -n 1 | cut -d: -f2 | xargs`;
            chomp $service;
            
            if ($service) {
                print "[+] Detected active interface: $interface ($service)\n";
                print "[+] Enables macOS System SOCKS Proxy on '$service' -> 127.0.0.1:9050\n";
                system "networksetup -setsocksfirewallproxy \"$service\" 127.0.0.1 9050";
                system "networksetup -setsocksfirewallproxystate \"$service\" on";
                
                # --- KILL SWITCH IMPLEMENTATION ---
                print "[+] Enabling Kill Switch (PF Rules)...\n";
                my $pf_conf = "/tmp/nipe_pf.conf";
                open(my $fh, '>', $pf_conf) or die "Could not open file '$pf_conf' $!";
                
                # Basic macros
                print $fh "ext_if = \"$interface\"\n";
                print $fh "tor_user = \"daemon\"\n"; # User utilized by Tor
                
                # Options
                print $fh "set block-policy drop\n";
                print $fh "set skip on lo0\n";
                
                # Rules - ORDER IS CRITICAL when using 'quick'
                # 1. Allow DNS (UDP 53) - Required for Tor bootstrapping
                print $fh "pass out quick on \$ext_if proto udp from any to any port 53 keep state\n";
                
                # 2. Allow Tor user (TCP) - The only allowed outbound traffic
                print $fh "pass out quick on \$ext_if proto tcp from any to any user \$tor_user keep state\n";

                # 3. Block IPv6 entirely (Leak prevention)
                print $fh "block drop quick inet6 all\n";
                
                # 4. Block EVERYTHING else on external interface
                print $fh "block drop out quick on \$ext_if all\n";
                
                close $fh;
                
                # Load the rules
                system "sudo pfctl -ef $pf_conf 2>/dev/null";
                print "[+] Kill Switch Active: Only 'daemon' user can access internet.\n";
                # ----------------------------------

            } else {
                 print "[!] Could not auto-detect active service. Fallback to 'Wi-Fi'.\n";
                 print "[+] Enables macOS System SOCKS Proxy on 'Wi-Fi' -> 127.0.0.1:9050\n";
                 system "networksetup -setsocksfirewallproxy \"Wi-Fi\" 127.0.0.1 9050";
                 system "networksetup -setsocksfirewallproxystate \"Wi-Fi\" on";
            }
            
            print "[+] Waiting for Tor to bootstrap (15s)...\n";
            sleep 15;
			
			my $status = Nipe::Component::Utils::Status -> new();
			if ($status =~ /true/sm) {
                print "[+] Nipe is running (System Proxy + Kill Switch Active).\n";
				return 1;
			}
            print "[!] Tor started, but connection verification failed. Check logs.\n";
			return $status;
		}

		if ($device{distribution} eq 'void') {
			$start_tor = 'sv start tor > /dev/null';
		}

		elsif (-e '/etc/init.d/tor') {
			$start_tor = '/etc/init.d/tor start > /dev/null';
		}

		system "tor -f .configs/$device{distribution}-torrc > /dev/null";
		system $start_tor;

		foreach my $table (@table) {
			my $target = 'ACCEPT';

			if ($table eq 'nat') {
				$target = 'RETURN';
			}

			system "iptables -t $table -F OUTPUT";
			system "iptables -t $table -A OUTPUT -m state --state ESTABLISHED -j $target";
			system "iptables -t $table -A OUTPUT -m owner --uid $device{username} -j $target";

			my $match_dns_port = $dns_port;

			if ($table eq 'nat') {
				$target = "REDIRECT --to-ports $dns_port";
				$match_dns_port = '53';
			}

			system "iptables -t $table -A OUTPUT -p udp --dport $match_dns_port -j $target";
			system "iptables -t $table -A OUTPUT -p tcp --dport $match_dns_port -j $target";

			if ($table eq 'nat') {
				$target = "REDIRECT --to-ports $transfer_port";
			}

			system "iptables -t $table -A OUTPUT -d $network -p tcp -j $target";

			if ($table eq 'nat') {
				$target = 'RETURN';
			}

			system "iptables -t $table -A OUTPUT -d 127.0.0.1/8    -j $target";
			system "iptables -t $table -A OUTPUT -d 192.168.0.0/16 -j $target";
			system "iptables -t $table -A OUTPUT -d 172.16.0.0/12  -j $target";
			system "iptables -t $table -A OUTPUT -d 10.0.0.0/8     -j $target";

			if ($table eq 'nat') {
				$target = "REDIRECT --to-ports $transfer_port";
			}

			system "iptables -t $table -A OUTPUT -p tcp -j $target";
		}

		system 'iptables -t filter -A OUTPUT -p udp -j REJECT';
		system 'iptables -t filter -A OUTPUT -p icmp -j REJECT';

		if (-d '/proc/sys/net/ipv6') {
			foreach my $table (@table) {
				my $target = 'ACCEPT';

				if ($table eq 'nat') {
					$target = 'RETURN';
				}

				system "ip6tables -t $table -F OUTPUT";
				system "ip6tables -t $table -A OUTPUT -m state --state ESTABLISHED -j $target";
				system "ip6tables -t $table -A OUTPUT -m owner --uid $device{username} -j $target";

				my $match_dns_port = $dns_port;

				if ($table eq 'nat') {
					$target = "REDIRECT --to-ports $dns_port";
					$match_dns_port = '53';
				}

				system "ip6tables -t $table -A OUTPUT -p udp --dport $match_dns_port -j $target";
				system "ip6tables -t $table -A OUTPUT -p tcp --dport $match_dns_port -j $target";

				if ($table eq 'nat') {
					$target = "REDIRECT --to-ports $transfer_port";
				}

				system "ip6tables -t $table -A OUTPUT -d $network_ipv6 -p tcp -j $target";

				if ($table eq 'nat') {
					$target = 'RETURN';
				}

				system "ip6tables -t $table -A OUTPUT -d ::1/128      -j $target";
				system "ip6tables -t $table -A OUTPUT -d fc00::/7     -j $target";
				system "ip6tables -t $table -A OUTPUT -d fe80::/10    -j $target";

				if ($table eq 'nat') {
					$target = "REDIRECT --to-ports $transfer_port";
				}

				system "ip6tables -t $table -A OUTPUT -p tcp -j $target";
			}

			system 'ip6tables -t filter -A OUTPUT -p udp -j REJECT';
			system 'ip6tables -t filter -A OUTPUT -p icmpv6 -j REJECT';
		}

		my $status = Nipe::Component::Utils::Status -> new();

		if ($status =~ /true/sm) {
			return 1;
		}

		return $status;
	}
}

1;