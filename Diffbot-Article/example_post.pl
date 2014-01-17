#!/usr/bin/perl

use strict;
use warnings;

BEGIN { push @INC, './lib' }

use Diffbot::Article qw(articlePost);
use JSON::XS;
use Data::Dumper::Concise;

#USER CODE                                 
my $token = "f2e2d920eab44063aa742b2b0698ab49"; #Set your token here
my $fedata = articlePost("http://blog.diffbot.com/diffbots-new-product-api-teaches-robots-to-shop-online",$token,['*'],"/home/slingshot/work/tempspace/data","text/html",2,"hello");
print $fedata;
my $json_dump = JSON::XS::decode_json($fedata);
print Dumper $json_dump;
