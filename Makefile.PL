# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

# Define metadata
name     'Interhack';
all_from 'lib/Interhack.pm';

# Specific dependencies
requires 'Calf';
requires 'Class::Method::Modifiers';
requires 'IO::Socket::INET';
requires 'Term::ReadKey';
requires 'Term::VT102';
requires 'Log::Log4perl';
requires 'Sort::Topological';
requires 'LWP::Simple';
requires 'File::Temp';
requires 'IO::Pty::Easy';

build_requires 'Test::More';
build_requires 'Test::Builder';

install_script 'bin/interhack';

auto_install;
WriteAll;

