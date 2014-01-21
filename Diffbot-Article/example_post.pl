#!/usr/bin/perl

use strict;
use warnings;

BEGIN { push @INC, './lib' }

use Diffbot::Article qw(articlePost);  			### Using export tag 'get'
use JSON::XS;
use Data::Dumper::Concise;

my $token = "";						### Enter the diffbot token here
my $url = "http://newswatch.nationalgeographic.com/2013/12/16/5-sky-events-this-week-moon-poses-with-winter-gems-and-little-bear-runs-with-meteors/";    ### Enter url
my @fieldarray = ("meta","images");                                
my $version = 2;					### Version number	
my %topass = (token => $token, url => $url, fields => \@fieldarray, version => $version, srcfile => './data', content_type => 'text/html'); 
my $data = articlePost(%topass); 			### Call our function and pass it the hash
my $json_dump = JSON::XS::decode_json($data);		
print Dumper $json_dump;		
