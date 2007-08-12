# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name     'Interhack';
all_from 'lib/Interhack.pm';

# Specific dependencies
requires 'Moose';
requires 'Moose::Role';
requires 'MooseX::Storage' => '0.06'; # <0.06 had bugs with bools and falsity
requires 'IO::Socket::INET';
requires 'Term::ReadKey';
requires 'Term::VT102';
requires 'Module::Refresh';
requires 'Log::Log4perl';

build_requires 'Test::More';
build_requires 'Test::Builder';

install_script 'bin/interhack';

auto_install;
WriteAll;

