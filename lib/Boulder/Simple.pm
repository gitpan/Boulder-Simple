# Copyright (c) 2004 Timothy Appnel
# http://www.timaoutloud.org/
# This code is released under the Artistic License.
#
# Boulder::Simple - a class for simple Boulder IO interaction.
# DEPRECATED. Use Boulder::Util instead.
# 

package Boulder::Simple;

use strict;
use CGI::Util qw( unescape escape );

use vars qw( $VERSION );
$VERSION = '0.021';

sub save {
    my($class,$filehandle,$data) = @_;
    $filehandle = to_filehandle($filehandle);
    local($,) = '';
    local($\) = '';
    $data = [ $data ] if (ref($data) eq 'HASH');  
    foreach my $rec (@$data) {
        my $param;
        foreach $param (keys %$rec) {
            my($escaped_param) = escape($param);
            my @vals = ref($rec->{$param}) eq 'ARRAY' ?
                @{$rec->{$param}} : ( $rec->{$param} );
            my $v;
            foreach $v (@vals) {
                print $filehandle "$escaped_param=",escape("$v"),"\n";
            }
        }
        print $filehandle "=\n";
    }
}

sub load_as_query { 
    my @lines = load(@_);
    return undef unless @lines;
    "@lines" =~ /=/ ? join("&",@lines) : join("+",@lines);
}

sub load_as_hash {
    my @lines = load(@_);
    return undef unless @lines;
    my %hash;
    foreach (@lines) {
        my($key,$value)=split /=/, $_, 2;
        next unless $key;
        $value = unescape($value);
        unless (exists($hash{$key})) {
            $hash{$key} = $value;
            next;
        } 
        if (ref($hash{$key}) eq 'ARRAY') {
            push(@{$hash{$key}},$value);
        } else {
            $hash{$key} = [ $hash{$key}, $value ];
        }
    }
    \%hash;
}

sub load {
	my($class,$filehandle) = @_;
    my @lines;
	if (defined($filehandle) && ($filehandle ne '')) {
        while (<$filehandle>) {
          chomp;
          last if /^=/;
          push(@lines,$_);
        }
    }
    @lines;
}

# Borrowed from CGI so we don't have to load that package if
# we don't need to. Turns a string into a filehandle.
sub to_filehandle { 
    my $thingy = shift;
    return undef unless $thingy;
    return $thingy if UNIVERSAL::isa($thingy,'GLOB');
    return $thingy if UNIVERSAL::isa($thingy,'FileHandle');
    if (!ref($thingy)) {
		my $caller = 1;
		while (my $package = caller($caller++)) {
			my($tmp) = $thingy=~/[\':]/ ? $thingy : "$package\:\:$thingy"; 
			return $tmp if defined(fileno($tmp));
		}
    }
    return undef;
}

1;

__END__

=begin

=head1 NAME

Boulder::Simple - a class for simple Boulder IO interaction. 
DEPRECATED. Use Boulder::Util instead.

=head1 SYNOPSIS
 
 #!/usr/bin/perl -w
 use strict;
 
 use Boulder::Simple;
 
 my $file ='boulder.txt';
 
 my $data = { 
     vocals => ['frank', 'kim'],
     guitar => ['frank', 'joey'],
     bass => 'kim',
     drums => 'david'
 };
 
 my $fh;
 open ($fh,">$file");
 Boulder::Simple->save($fh,$data);
 close $fh;
 
 my $fh2;
 open ($fh2,"$file");
 while(my $q = Boulder::Simple->load_as_query($fh2)) {
     print "$q\n";
 }
 close $fh2;

=head1 DESCRIPTION

Boulder::Simple is a simple lightweight class for manipulating
Boulder IO records. DEPRECATED. Use Boulder::Util instead.

Boulder IO is the native format output by the CGI package's C<save>
method. While working on a project I used that method to serialize
the state of a query for later use. That later use did not involve
a CGI request though. I wanted to avoid loading up the CGI package
just to read in the file memory and the L<Boulder> package itself
seemed like a bit much. What I wished I had was a quick way of
reading those records without incurring the overhead of either
package. Hence Boulder::Simple.

The package provides just a save and a few load methods for reading
and writing. The load methods work like quasi-iterators were only
one record is loaded at a time to allow developers to control
memory consumption as they see fit.

This package does not support the entire Boulder IO format and
makes a few asusmptions in the name of simplicity. Heirarchical
records are not supported. Also the = character is assumed to
always be the record delimiter. All data is always URL encoded. If
you are working with data that was serialized by CGI as I was these
are not a problem. If you do need these features then perhaps the
L<Boulder> package is for you.

The release is quite functional, but may better serve it purpose
with some interface tweaks. Feedback is appreciated.

=head1 METHODS

A file handle is required for all methods. When working with a
HASH, multi-valued keys (field names) are represented as an ARRAY 
reference.

=over

=item load(HANDLE)

Loads one record from the handle provided and returns an array of
its lines. The key/value pairs are unprocessed.

=item load_as_query(HANDLE)

Loads one record from the handle provided and returns the key/value
pairs as an HTTP query string.

=item load_as_hash(HANDLE)

Loads one record from the handle provided and returns the key/value
pairs as an HTTP query string.

=item save(HANDLE,\%hash)

Writes the HASH reference to the file. How it writes (append,
overwrite/create) is entirely up to the handle that it is passed.

=back

=head1 DEPENDENCIES

L<CGI::Util>

=head1 SEE ALSO

L<Boulder>

=head1 LICENSE

The software is released under the Artistic License. The terms of
the Artistic License are described at
L<http://www.perl.com/language/misc/Artistic.html>.

=head1 AUTHOR & COPYRIGHT

Except where otherwise noted, Boulder::Simple is Copyright 2004-2005,
Timothy Appnel, tima@cpan.org. All rights reserved.

=cut

=end