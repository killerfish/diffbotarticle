package Diffbot::Article;

use strict;
use warnings;
use Carp;
use Exporter;
use IO::Socket;

use constant CRLF => "\r\n";

our $VERSION     = 1.00;
our $ABSTRACT    = "Module for Diffbot Article api";
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
		my %args = @_;
		my (@fieldlist, $version);
		croak("Cant Proceed, No token provided") if(!($args{token}));
                croak("Cant Proceed, No url provided") if(!($args{url}));
		if(!($args{fields})){
			carp("Missing! No fields specified, using default *");
			@fieldlist = ('*');
		}
		else { @fieldlist = @{$args{fields}}; }
		if(!$args{version}){
                        carp("Missing! No version specified, using default 1");
                        $version = 1; 
                }
                else { $version = $args{version}; }
		my ($url, $token) = ($args{url}, $args{token});
		my ($json, $scal);
		$scal = join(",", @fieldlist);
                my $request = "/v2/article?token=$token&url=$url&fields=$scal";
                my $sock = new IO::Socket::INET (PeerAddr => 'api.diffbot.com',PeerPort => '80',Proto => 'tcp');
                	die "Could not create socket: $!\n" unless $sock;
                print $sock "GET $request HTTP/1.1", CRLF;
                print $sock "Host: api.diffbot.com", CRLF, CRLF;
		if (getResponseCode($sock) eq "success")
		{
			$json = getResponseData($sock);
		}
                close($sock);
                return $json;
}
sub articlePost
{
		my %args = @_;
		my (@fieldlist, $version);
		croak("Cant Proceed, No token provided") if(!$args{token});
                croak("Cant Proceed, No url provided") if(!$args{url});
		croak("Cant Proceed, No data or file provided for input") if(!$args{srcfile} && !$args{data});
		croak("Cant Proceed, No content type specified!") if(!($args{content_type}));
		croak("Cant Proceed, Invalid content type, value should be 'text/plain' or 'text/html'") if(($args{content_type} ne "text/plain") and ($args{content_type} ne "text/html"));
		if(!$args{fields}){
                        carp("Missing! No fields specified, using default *");
                        @fieldlist = ('*'); 
                }
                else { @fieldlist = @{$args{fields}}; }
                if(!$args{version}){
                        carp("Missing! No version specified, using default 1");
                        $version = 1;  
                }
                else { $version = $args{version}; }
		my ($json, $scal);
		my ($token, $url, $src_file, $content_type, $data) = ($args{token}, $args{url}, $args{srcfile}, $args{content_type}, $args{data});
		if($args{srcfile} ne 0)
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
		$scal = join(",", @fieldlist);
                my $request = "/v2/article?token=$token&url=$url&fields=$scal";
                my $sock = new IO::Socket::INET (PeerAddr => 'api.diffbot.com',PeerPort => '80',Proto => 'tcp');
                        die "Could not create socket: $!\n" unless $sock;
		binmode $sock;
		print $sock "POST $request HTTP/1.1", CRLF;			
	        print $sock "Host: api.diffbot.com", CRLF;
		print $sock "Content-Type: $content_type", CRLF;
		print $sock "Content-Length: $content_length", CRLF, CRLF;
		print $sock $data, CRLF, CRLF;
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


__END__

=head1 NAME

Diffbot::Article - Module for the diffbot Article API

=head1 VERSION

Version 1.00

=head1 SYNOPSIS

This module is an interface for www.diffbot.com Article API, and supports the two methods for Get and Post.
	
	use Diffbot::Article;
	
	my $json_obj = articleGet((url => $url, token => $token, fields => \@fieldarrayref, version => $version))
	my $json_obj = articlePost((url => $url, token => $token, fields => \@fieldsarrayref, srcfile => $srcfile, content_type => $content_type, version => $version, data => $data))


=head1 METHODS

=head2 articleGet

Pass the url, along with the token in a hash, to fetch diffbot data (based on url). Other options can also be set in hash and sent.
	
	my %topass = (token => $token, url => $url, fields => \@fieldarrayref, version => $version)
	articleGet(%topass)
	
	Fields can be set by setting values in an array and sending the reference through hash.
	You can view the fields at www.diffbot.com. Also check example_get.pl to see how to use.

	Returns diffbot response, which can be parsed through perl JSON::XS to get a json object.

=cut

=head2 articlePost

Gets diffbot data based on the content data sent, url and token should also be set through hash. Other options can also be set in hash and sent.

	my %topass = (token => $token, url => $url, fields => \@fieldarrayref, version => $version, srcfile => $srcfile, content_type => 'text/html', data => $data)
	articlePost(%topass)

	Additional arguments required to be sent are the content_type ('text/html' or 'text/plain') and srcfile or data.
	You can specify either a file or data content to be sent. If both fields are set, the file content will be Posted.
	Check example_post.pl to see how to use.
 
	Returns diffbot response, which can be parsed through perl JSON::XS to get a json object.

=cut

=head1 AUTHOR

Usman Raza, B<C<usman.r123 at gmail.com>>


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Diffbot::Article

Github repo https://github.com/killerfish/diffbotarticle

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Usman Raza.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
