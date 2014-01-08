#!/usr/bin/perl
package Diffbot::HTTP;

use strict;
use warnings;

use IO::Socket;

use JSON::XS;                           
use Data::Dumper::Concise;

#USER CODE                                 
my $token = ""; #Set your token here
my $data = articleGet("http://blog.diffbot.com/diffbots-new-product-api-teaches-robots-to-shop-online",$token,"article",['*'],2);
my $json_dump = JSON::XS::decode_json($data);
print Dumper $json_dump;

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
