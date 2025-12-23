package Nipe::Component::Engine::Rotate;

use strict;
use warnings;
use IO::Socket::UNIX;

sub new {
    my $socket_path = '/tmp/nipe_tor_run/control';
    
    # Check if Tor Control Socket exists
    if (! -S $socket_path) {
        return "[!] Error: Tor Control Socket not found at $socket_path. Is Nipe running?\n";
    }

    # Connect to the socket
    my $client = IO::Socket::UNIX->new(
        Peer => $socket_path,
        Type => SOCK_STREAM,
        Timeout => 10
    ) or return "[!] Error: Could not connect to Tor Control Socket: $!\n";

    # Read Auth Cookie (if needed, but our config might allow cookie auth)
    # For now, we try unconditional 'AUTHENTICATE' first, or read cookie if needed.
    # Our torrc has 'CookieAuthentication 1', so we need the cookie.
    
    my $cookie_path = '/tmp/nipe_tor_run/control.authcookie';
    open(my $fh, '<', $cookie_path) or return "[!] Error: Could not read Auth Cookie.\n";
    binmode($fh);
    my $cookie_data;
    read($fh, $cookie_data, 32); # Read 32 bytes
    close($fh);
    
    # Hex encode the cookie for the AUTHENTICATE command logic? 
    # Actually, the protocol says: AUTHENTICATE [GlobalHexEncoding]
    # Let's try the simplest: AUTHENTICATE "hexcookie"
    my $hex_cookie = unpack("H*", $cookie_data);

    print $client "AUTHENTICATE $hex_cookie\r\n";
    my $auth_response = <$client>;
    
    if ($auth_response !~ /^250/) {
        return "[!] Error: Tor Authentication Failed: $auth_response";
    }

    # Send NEWNYM signal
    print $client "SIGNAL NEWNYM\r\n";
    my $signal_response = <$client>;

    close($client);

    if ($signal_response =~ /^250/) {
        return "[+] Success: Tor Identity Rotated (SIGNAL NEWNYM sent).\n";
    } else {
        return "[!] Error: Failed to rotate identity: $signal_response";
    }
}

1;
