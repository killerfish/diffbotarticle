package Diffbot::Article;

use strict;
use warnings;
use Exporter;
use IO::Socket;

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
our @EXPORT = qw(articleGet);

#API CODE
sub articleGet{
		my ($url, $token, $api, $fields, $version) = @_;
                my @fieldlist = @{$fields};
                my $chunked_mode = 1;
                my $request = "/v2/article?token=$token&url=$url&fields=@fieldlist";
                my $sock = new IO::Socket::INET (PeerAddr => 'api.diffbot.com',PeerPort => '80',Proto => 'tcp');
                	die "Could not create socket: $!\n" unless $sock;
                print $sock "GET $request HTTP/1.1\r\n";
                print $sock "Host: api.diffbot.com\r\n\r\n";
                my $response_code = <$sock>;
                if($response_code =~ m/^HTTP\/1.1\s+(\S+)\s+(.+)/) 
                {
                       if($1 != 200)
                       {
                               die "Error! Code: $1, Message: $2\n";
                       }
                }
                while(<$sock> =~ m/^(\S+):\s+(.+)/)
		{
         	       print "$1: $2\n";
                       if($1 eq "Content-Length")
                       {
                	       $chunked_mode = 0;                    
                       }
                }
                my $json;
                if($chunked_mode == 1)
                {
                	my $temp = <$sock>;
                        my $flag = 1;
                        while($temp ne "0\r\n")
                        {
                        	$temp =~ s/\r\n//g;
  	                        if($flag % 2 == 1)
                                {
          	                      $temp = <$sock>;
                                      $flag = $flag + 1;
                                }
                                else
                                {
                                      $json = $json.$temp;
                                      $temp = <$sock>;
                                      $flag = $flag + 1;
                                }
                        }
                }
                else
                {
                	while(my $line = <$sock>)
                        {
                        	$json = $json.$line;
                        }
                }
                close($sock);
                return $json;
}
sub articlePost{}
1;
