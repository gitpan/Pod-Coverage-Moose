=pod BOGUS

=cut

package IsMoose;
use Moose;
use namespace::clean -except => 'meta';

with 'MooseRole';

sub bar { }

1;
