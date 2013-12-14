package Pod::Coverage::Moose;
{
  $Pod::Coverage::Moose::VERSION = '0.05';
}
# git description: v0.04-19-g4edd882

BEGIN {
  $Pod::Coverage::Moose::AUTHORITY = 'cpan:ETHER';
}
# ABSTRACT: Pod::Coverage extension for Moose
use Moose;

use Pod::Coverage;
use Carp            qw( croak );
use Class::Load qw( load_class );

use namespace::autoclean;



has package => (
    is          => 'rw',
    isa         => 'Str',
    required    => 1,
);


has cover_requires => (
    is          => 'ro',
    isa         => 'Bool',
    default => 0,
);

#
#   original pod_coverage object
#

has _pod_coverage => (
    is          => 'rw',
    isa         => 'Pod::Coverage',
    handles     => [qw( coverage why_unrated naked uncovered covered )],
);


my %is = map { $_ => 1 } qw( rw ro wo );
sub BUILD {
    my ($self, $args) = @_;

    my $meta    = $self->package->meta;
    my @trustme = @{ $args->{trustme} || [] };

    push @trustme, qr/^meta$/;
    push @trustme,                                          # MooseX-AttributeHelpers hack
        map  { qr/^$_$/ }
        map  { $_->name }
        grep { $_->isa('MooseX::AttributeHelpers::Meta::Method::Provided') }
        $meta->get_all_methods
            unless $meta->isa('Moose::Meta::Role');
    push @trustme,
        map { qr/^\Q$_\E$/ }                                # turn value into a regex
        map {                                               # iterate over all roles of the class
            my $role = $_;
            $role->get_method_list,
            ($self->cover_requires ? ($role->get_required_method_list) : ()),
            map {                                           # iterate over attributes
                my $attr = $role->get_attribute($_);
                ($attr->{is} && $is{$attr->{is}} ? $_ : ()),  # accessors
                grep defined, map { $attr->{ $_ } }                             # other attribute methods
                    qw( clearer predicate reader writer accessor );
            } $role->get_attribute_list,
        }
        $meta->calculate_all_roles;

    $args->{trustme} = \@trustme;

    $self->_pod_coverage(Pod::Coverage->new(%$args));
}


around new => sub {
    my $next = shift;
    my ($self, @args) = @_;

    my %args  = (@args == 1 && ref $args[0] eq 'HASH' ? %{ $args[0] } : @args);
    my $class = $args{package}
        or croak 'You need to specify a package in the constructor arguments';

    load_class($class);
    return Pod::Coverage->new(%args) unless $class->can('meta');

    return $self->$next(@args);
};

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Robert 'phaylon' Sedlacek Dave Rolsky Karen Etheridge Vyacheslav Matyukhin
initialises

=head1 NAME

Pod::Coverage::Moose - Pod::Coverage extension for Moose

=head1 VERSION

version 0.05

=head1 SYNOPSIS

  use Pod::Coverage::Moose;

  my $pcm = Pod::Coverage::Moose->new(package => 'MoosePackage');
  print 'Coverage: ', $pcm->coverage, "\n";

=head1 DESCRIPTION

When using L<Pod::Coverage> in combination with L<Moose>, it will
report any method imported from a Role. This is especially bad when
used in combination with L<Test::Pod::Coverage>, since it takes away
its ease of use.

To use this module in combination with L<Test::Pod::Coverage>, use
something like this:

  use Test::Pod::Coverage;
  all_pod_coverage_ok({ coverage_class => 'Pod::Coverage::Moose'});

=head1 ATTRIBUTES

=head2 package

This is the package used for inspection.

=head2 cover_requires

Boolean flag to indicate that C<requires $method> declarations in a Role should be trusted.

=head1 METHODS

=head2 meta

L<Moose> meta object.

=head2 BUILD

Initialises the internal L<Pod::Coverage> object. It uses the meta object
to find all methods and attribute methods imported via roles.

=head1 DELEGATED METHODS

=head2 Delegated to the traditional L<Pod::Coverage> object are

=over

=item coverage

=item covered

=item naked

=item uncovered

=item why_unrated

=back

=head1 EXTENDED METHODS

=head2 new

The constructor will only return a C<Pod::Coverage::Moose> object if it
is invoked on a class that C<can> a C<meta> method. Otherwise, a
traditional L<Pod::Coverage> object will be returned. This is done so you
don't get in trouble for mixing L<Moose> with non Moose classes in your
project.

=head1 SEE ALSO

L<Moose>,
L<Pod::Coverage>,
L<Test::Pod::Coverage>

=head1 AUTHOR

Robert 'phaylon' Sedlacek <rs@474.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Robert 'phaylon' Sedlacek.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 CONTRIBUTORS

=over 4

=item *

Dave Rolsky <autarch@urth.org>

=item *

Karen Etheridge <ether@cpan.org>

=item *

Vyacheslav Matyukhin <me@berekuk.ru>

=back

=cut
