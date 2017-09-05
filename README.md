# NAME

Datahub::Factory - A conveyor belt which transports data from a data source to a data sink.

# STATUS

[![Build Status](https://travis-ci.org/thedatahub/Datahub-Factory.svg?branch=master)](https://travis-ci.org/thedatahub/Datahub-Factory)
[![CPANTS kwalitee](https://cpants.cpanauthors.org/dist/Datahub-Factory.png)](https://cpants.cpanauthors.org/dist/Datahub-Factory)

# SYNOPSIS

dhconveyor \[ARGUMENTS\] \[OPTIONS\]

# DESCRIPTION

Datahub::Factory is a command line conveyor belt which automates three tasks:

- Data is fetched automatically from a local or remote data source.
- Data is converted to an exchange format.
- The output is pushed to a data sink.

Datahub::Factory fetches data from several sources as specified by the
_Importer_ settings, executes a [Fix](https://metacpan.org/pod/Catmandu::Fix) and sends it to
a data sink, set by _Exporter_. Several importer and exporter modules
are supported.

Datahub::Factory contains Log4perl support to monitor conveyor belt operations.

Note: This toolset is not a generic tool. It has been tailored towards the
functional requirements of the Flemish Art Collection use case.

# CONFIGURATION

## Command line options

All commands share the following switches:

- `--log_level`

    Set the log\_level. Takes a numeric parameter. Supported levels are:
    1 (WARN), 2 (INFO), 3 (DEBUG). WARN (1) is the default.

- `--log_output`

    Selects an output for the log messages. By default, it will send them to STDERR (pass `STDERR` as parameter), but STDOUT (`STDOUT`) and a log file (`logs/import_-date-.log`) (`STATISTICS`) are also supported.

- `--verbose`

    Set verbosity. Invoking the command with the --verbose, -v flag will render
    verbose output to the terminal.

# COMMANDS

## help COMMAND

Documentation about command line options.

It is possible to provide either all importer and/or exporter options on the
command line, or to create a _pipeline configuration file_ that sets those
options.

## [transport \[OPTIONS\]](https://metacpan.org/pod/Datahub::Factory::Command::transport)

Fetch data from a local or remote source, convert it to an exchange format and
export the data.

# PLUGINS

_Datahub::Factory_ uses a plugin-based architecture, making it easy to extend
with new functionality.

New commands can be added by creating a Perl module that contains a `command_name.pm`
file in the `lib/Datahub/Factory/Command` path. _Datahub::Factory_ uses the
[Datahub::Factory::Command](https://metacpan.org/pod/Datahub::Factory::Command) namespace and [App::Cmd](https://metacpan.org/pod/App::Cmd) internally.

New [Datahub::Factory::Importer](https://metacpan.org/pod/Datahub::Factory::Importer), [Exmporter](https://metacpan.org/pod/Datahub::Factory::Exporter) and [Fixer](https://metacpan.org/pod/Datahub::Factory::Fixer) plugins
can be added in the same way, in the `lib/Datahub/Factory/Importer`, `Exporter` or `Fixer`
path. All plugins use the _Datahub::Factory::Importer/Exporter/Fixer_ namespace and the
namespace package as a [Moose::Role](https://metacpan.org/pod/Moose::Role).

# AUTHORS

Pieter De Praetere <pieter@packed.be>

Matthias Vandermaesen <matthias.vandermaesen@vlaamsekunstcollectie.be>

# COPYRIGHT

Copyright 2016 - PACKED vzw, Vlaamse Kunstcollectie vzw

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the terms of the GPLv3.
