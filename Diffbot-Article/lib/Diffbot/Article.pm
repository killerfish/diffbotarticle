package Diffbot::Article;

use strict;
use warnings;
use Exporter;
use IO::Socket;

use constant CRLF => "\r\n";

our @ISA = qw(Exporter);
our %EXPORT_TAGS = (
          'get' => [ qw(
                          articleGet
                  ) ],
          'post' => [ qw(
                          articlePost
                  ) ],
          'both' => [ qw(
                          articleGet
                          articlePost
                  ) ],
);
our @EXPORT_OK   = qw(articleGet articlePost);
our @EXPORT = ();

sub articleGet
{
		my ($url, $token, $fields, $version) = @_;
                my @fieldlist = @{$fields};
		my $json;
                my $request = "/v2/article?token=$token&url=$url&fields=@fieldlist";
                my $sock = new IO::Socket::INET (PeerAddr => 'api.diffbot.com',PeerPort => '80',Proto => 'tcp');
                	die "Could not create socket: $!\n" unless $sock;
                print $sock "GET $request HTTP/1.1\r\n";
                print $sock "Host: api.diffbot.com\r\n\r\n";
		if(getResponseCode($sock) eq "success")
		{
			$json = getResponseData($sock);
		}
                close($sock);
                return $json;
}
sub articlePost
{
		my ($url,$token, $fields, $src_file, $content_type, $version, $data) = @_;
		my @fieldlist = @{$fields};
		my $json;
		if($src_file ne 0)
		{
			$data = "";
			open (FH,"<",$src_file) || die "create: can't open src file $src_file: $!\n";
			while(<FH>)
			{
			        $data = $data.$_;
			}
			close(FH);			
		}
	        my $content_length = length $data;	
                my $chunked_mode = 1;
                my $request = "/v2/article?token=$token&url=$url";
                my $sock = new IO::Socket::INET (PeerAddr => 'api.diffbot.com',PeerPort => '80',Proto => 'tcp');
                        die "Could not create socket: $!\n" unless $sock;
		binmode $sock;
		print $sock "POST $request HTTP/1.1\r\n";			
	        print $sock "Host: api.diffbot.com\r\n";
		print $sock "Content-Type: $content_type\r\n";
		print $sock "Content-Length: $content_length\r\n\r\n";
		print $sock "$data\r\n\r\n";
		if(getResponseCode($sock) eq "success")
                {
                        $json = getResponseData($sock);
                }
                close($sock);
                return $json;
}
sub getResponseCode
{
		my $socket = shift;
		my $response_code = <$socket>;
		if($response_code =~ m/^HTTP\/1.1\s+(\S+)\s+(.+)/)
                {
                       if($1 != 200)
                       {
                               die "Error! Code: $1, Message: $2\n";
                       }
		       return "success";
                }
}
sub getResponseData
{
		my $json;
		my $chunked_mode = 1;
                my $socket = shift;
		while(<$socket> =~ m/^(\S+):\s+(.+)/)
                {
                       print "$1: $2\n";
                       if($1 eq "Content-Length")
                       {
                               $chunked_mode = 0;
                       }
                }
                if($chunked_mode == 1)
                {
                        my $temp = <$socket>;
                        my $flag = 1;
                        while($temp ne "0\r\n")
                        {
                                $temp =~ s/\r\n//g;
                                if($flag % 2 == 1)
                                {
                                      $temp = <$socket>;
                                      $flag = $flag + 1;
                                }
                                else
                                {
                                      $json = $json.$temp;
                                      $temp = <$socket>;
                                      $flag = $flag + 1;
                                }
                        }
                }
                else
                {
                        while(my $line = <$socket>)
                        {
                                $json = $json.$line;
                        }
                }
		return $json;
}

1;
