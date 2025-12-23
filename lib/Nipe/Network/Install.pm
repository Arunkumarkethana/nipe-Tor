package Nipe::Network::Install {
	use strict;
	use warnings;
	use Nipe::Component::Utils::Device;
	use Nipe::Component::Engine::Stop;

	our $VERSION = '0.0.3';

	sub new {
		my $class = shift;
        my $self = {};
        bless $self, $class;
        return $self;
	}

    sub install {
        my $self = shift;
        my %device  = Nipe::Component::Utils::Device -> new();
        my %install = (
			debian    => 'apt-get install -y tor iptables',
			fedora    => 'dnf install -y tor iptables',
			centos    => 'yum -y install epel-release tor iptables',
			void      => 'xbps-install -y tor iptables',
			arch      => 'pacman -S --noconfirm tor iptables',
			opensuse  => 'zypper install -y tor iptables',
			darwin    => 'brew install tor',
		);
        
        print "[+] Installing dependencies for $device{distribution}...\n";
		system $install{$device{distribution}};
        return 1;
    }

    sub check {
        # Check if Tor is installed
        my $tor_path = `which tor`;
        chomp($tor_path);
        
        if ($tor_path && -x $tor_path) {
            # print "[+] Tor is installed ($tor_path).\n"; 
            return 1;
        } 
        
        print "[!] Tor is NOT installed. Attempting auto-installation...\n";
        return shift->install();
    }
}

1;