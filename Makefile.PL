# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name     'Interhack';
all_from 'lib/Interhack.pm';

# Specific dependencies
requires 'Moose';
requires 'Moose::Role';
requires 'MooseX::Storage';
requires 'IO::Socket::INET';
requires 'Term::ReadKey';
requires 'Term::VT102';
requires 'Module::Refresh';

install_script 'bin/interhack';

auto_install;
WriteAll;

