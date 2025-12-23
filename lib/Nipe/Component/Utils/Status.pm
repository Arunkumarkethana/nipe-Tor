package Nipe::Component::Utils::Status {
	use JSON;
	use strict;
	use warnings;
	use HTTP::Tiny;
	use Readonly;

	Readonly my $SUCCESS_CODE => 200;

	our $VERSION = '0.0.4';

	sub new {
		my $api_check = 'https://check.torproject.org/api/ip';
        my $request_content;
        my $status_code;

        # On macOS, use curl with explicit SOCKS proxy to verify Tor connectivity
        # because CLI tools/Perl don't auto-inherit System Proxy settings.
        if ($^O eq 'darwin') {
            my $output = `curl -s --socks5-hostname 127.0.0.1:9050 $api_check`;
            if ($output && $output =~ /IsTor/) {
                $request_content = $output;
                $status_code = 200;
            } else {
                $status_code = 500;
            }
        } else {
            # Linux/Existing Logic
            my $request  = HTTP::Tiny -> new -> get($api_check);
            $status_code = $request->{status};
            $request_content = $request->{content};
        }

		if ($status_code == $SUCCESS_CODE) {
			my $data = decode_json($request_content);

			my $check_ip  = $data -> {'IP'};
			my $check_tor = $data -> {'IsTor'} ? 'true' : 'false';

			return "\n\r[+] Status: $check_tor \n\r[+] Ip: $check_ip\n\n";
		}

		return "\n[!] ERROR: sorry, it was not possible to establish a connection to the server.\n\n";
	}
}

1;