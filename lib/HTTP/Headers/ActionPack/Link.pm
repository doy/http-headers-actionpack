package HTTP::Headers::ActionPack::Link;
# ABSTRACT: A Link

use strict;
use warnings;

use URI::Escape qw[ uri_escape uri_unescape ];

use HTTP::Headers::ActionPack::Util qw[
    split_header_words
    join_header_words
];

use parent 'HTTP::Headers::ActionPack::Core::BaseHeaderType';

sub new {
    my $class = shift;
    my $self  = $class->SUPER::new( @_ );

    foreach my $param ( grep { /\*$/ } @{ $self->_param_order } ) {
        my ($encoding, $language, $content) = ( $self->params->{ $param } =~ /^(.*)\'(.*)\'(.*)$/);
        $self->params->{ $param } = {
            encoding => $encoding,
            language => $language,
            content  => uri_unescape( $content )
        };
    }

    $self;
}

sub href { (shift)->subject         }
sub rel  { (shift)->params->{'rel'} }

sub relation_matches {
    my ($self, $relation) = @_;

    if ( my $rel = $self->params->{'rel'} ) {
        # if it is an extension rel type
        # then it is a URI and it should
        # not be compared in a case-insensitive
        # manner ...
        if ( $rel =~ m!^\w+\://! ) {
            $self->params->{'rel'} eq $relation ? 1 : 0;
        }
        # if it is not a URI, then compare
        # it case-insensitively
        else {
            (lc $self->params->{'rel'} ) eq (lc $relation) ? 1 : 0;
        }
    }
}

sub new_from_string {
    my ($class, $link_header_string) = @_;
    my ($href, @params) = @{ (split_header_words( $link_header_string ))[0] };
    $href =~ s/^<//;
    $href =~ s/>$//;
    $class->new( $href, @params );
}

sub to_string {
    my $self = shift;

    my @params;
    foreach my $param ( @{ $self->_param_order } ) {
        if ( $param =~ /\*$/ ) {
            my $complex = $self->params->{ $param };
            push @params => ( $param,
                join "'" => (
                    $complex->{'encoding'},
                    $complex->{'language'},
                    uri_escape( $complex->{'content'} ),
                )
            );
        }
        else {
            push @params => ( $param, $self->params->{ $param } );
        }
        my ($encoding, $language, $content) = ( $self->params->{ $param } =~ /^(.*)\'(.*)\'(.*)$/);
    }

    join_header_words( '<' . $self->href . '>', @params );
}

1;

__END__

=head1 SYNOPSIS

  use HTTP::Headers::ActionPack::Link;

=head1 DESCRIPTION

This is an object which represents an HTTP Link header.

=head1 METHODS

=over 4

=item C<href>

=item C<new_from_string ( $link_header_string )>

This will take an HTTP header Link string
and parse it into and object.

=item C<to_string>

This stringifys the link respecting the
parameter order.

NOTE: This will canonicalize the header such
that it will add a space between each semicolon
and quotes and unquotes all headers appropriately.

=back





