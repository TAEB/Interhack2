package Interhack::Plugin::Debug;
use Calf::Role qw/debug info warn error fatal/;
use Log::Log4perl;

our $VERSION = '1.99_01';

# attributes {{{
has logger => (
    per_load => 1,
    is => 'rw',
    lazy => 1,
    default => sub
    {
        my $self = shift;
        Log::Log4perl->init($self->config_dir . "/log4perl.conf");
        Log::Log4perl->get_logger("Interhack");
    }
);
# }}}
# method modifiers {{{
# }}}
# methods {{{
sub debug # {{{
{
    my $self = shift;
    unshift @_, $self->logger;
    my $coderef = $self->logger->can('debug');
    goto &$coderef;
} # }}}
sub info # {{{
{
    my $self = shift;
    unshift @_, $self->logger;
    my $coderef = $self->logger->can('info');
    goto &$coderef;
} # }}}
sub warn # {{{
{
    my $self = shift;
    unshift @_, $self->logger;
    my $coderef = $self->logger->can('warn');
    goto &$coderef;
} # }}}
sub error # {{{
{
    my $self = shift;
    unshift @_, $self->logger;
    my $coderef = $self->logger->can('error');
    goto &$coderef;
} # }}}
sub fatal # {{{
{
    my $self = shift;
    unshift @_, $self->logger;
    my $coderef = $self->logger->can('fatal');
    goto &$coderef;
} # }}}
# }}}

1;
