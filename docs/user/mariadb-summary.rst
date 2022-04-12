.. program:: mariadb-summary

==========================
:program:`mariadb-summary`
==========================

NAME
====

:program:`mariadb-summary` - Summarize system information nicely.

SYNOPSIS
========

Usage
-----

::

  mariadb-summary

:program:`mariadb-summary` conveniently summarizes the status and configuration of
a database and its underlying server. It is not a tuning tool or diagnosis tool.
It produces a report that is easy to diff and can be pasted into emails without
losing the formatting. This tool works well on many types of Unix systems.

RISKS
=====

:program:`mariadb-summary` is mature, proven in the real world, and well tested,
but all database tools can pose a risk to the system and the database
server.  Before using this tool, please:

* Read the tool's documentation

* Test the tool on a non-production server

* Backup your production server and verify the backups

DESCRIPTION
===========

:program:`mariadb-summary` runs mariadb-system-summary and mariadb-database-summary together.

These tools run a large variety of commands to inspect system and MariaDB
status and configuration.

It works best when executed as a privileged user, but will also work without 
privileges, although some output might not be possible to generate without root.

OUTPUT
======

See mariadb-system-summary and mariadb-database-summary documentation for output
details.

OPTIONS
=======

.. option:: --all-databases

 mariadb-dump and summarize all databases.  See :option:`--databases`.

.. option:: --ask-pass

 Prompt for a password when connecting to MariaDB.

.. option:: --config

 type: string

 Read this comma-separated list of config files.  If specified, this must be the
 first option on the command line.

.. option:: --databases

 type: string

 mariadb-dump and summarize this comma-separated list of databases.  Specify
 :option:`--all-databases` instead if you want to dump and summary all databases.

.. option:: --defaults-file

 short form: -F; type: string

 Only read mariadb options from the given file.  You must give an absolute
 pathname.

.. option:: --debug

 Development use only.

.. option:: --help

 Print help and exit.

.. option:: --host

 short form: -h; type: string

 Host to connect to.

.. option:: --password

 short form: -p; type: string

 Password to use when connecting.
 If password contains commas they must be escaped with a backslash: "exam\,ple"

.. option:: --port

 short form: -P; type: int

 Port number to use for connection.

.. option:: --read-samples

 type: string

 Create a report from the files in this directory.

.. option:: --save-samples

 type: string

 Save the collected data in this directory.

.. option:: --sleep

 type: int; default: 5

 How long to sleep when gathering samples from vmstat.

.. option:: --socket

 short form: -S; type: string

 Socket file to use for connection.

.. option:: --summarize-mounts

 default: yes; negatable: yes

 Report on mounted filesystems and disk usage.

.. option:: --summarize-network

 default: yes; negatable: yes

 Report on network controllers and configuration.

.. option:: --summarize-processes

 default: yes; negatable: yes

 Report on top processes and ``vmstat`` output.

.. option:: --support

 type: integer; default: -1

 Option intended for development use only.

.. option:: --support-annotation

 type: string; default: ""

 Option intended for development use only.

.. option:: --support-checkall

 type: boolean; default: true

 Option intended for development use only.

.. option:: --support-env

 Option intended for development use only.

.. option:: --support-innodb-mutex

 type: boolean; default: true

 Option intended for development use only.

.. option:: --support-limit

 type: integer; default: 10000

 Option intended for development use only.

.. option:: --support-memory

 type: boolean; default: true

 Option intended for development use only.

.. option:: --support-metrics

 type: integer; default: -1

 Option intended for development use only.

.. option:: --support-mounts

 type: boolean; default: true

 Option intended for development use only.

.. option:: --support-not-root

 type: boolean; default: false

 Option intended for development use only.

.. option:: --support-output-dir

 type: string;

 Option intended for development use only.

.. option:: --support-pid

 type: integer

 Option intended for development use only.

.. option:: --support-process-list

 type: boolean; default: true

 Option intended for development use only.

.. option:: --support-replica-status

 type: boolean; default: false

 Option intended for development use only.

.. option:: --support-sky

 type: boolean; default: false

 Option intended for development use only.

.. option:: --support-variables

 type: boolean; default: true

 Option intended for development use only.

.. option:: --support-tar-result

 type: boolean; default: true

 Option intended for development use only.\`

.. option:: --user

 short form: -u; type: string

 User for login if not current user.

.. option:: --version

 Print tool's version and exit.

ENVIRONMENT
===========

This tool does not use any environment variables.

SYSTEM REQUIREMENTS
===================

This tool requires the Bourne shell (*/bin/sh*).

AUTHORS
=======

Cole Busby, Manjot Singh

ABOUT THIS MARIADB TOOL
=======================

This tool is part of MariaDB client tools. This MariaDB Tool was created in 
August, 2019, based on Percona Toolkit which was 
forked from two projects in June, 2011: Maatkit and Aspersa.  Those projects 
were created by Baron Schwartz and primarily developed by him and Daniel Nichter.

COPYRIGHT, LICENSE, AND WARRANTY
================================

This program is copyright 2019-2022 MariaDB Corporation and/or its affiliates,
2011-2018 Percona LLC and/or its affiliates, 2010-2011 Baron Schwartz.

THIS PROGRAM IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, version 2; OR the Perl Artistic License.  On UNIX and similar
systems, you can issue \`man perlgpl' or \`man perlartistic' to read these
licenses.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 59 Temple
Place, Suite 330, Boston, MA  02111-1307  USA.

VERSION
=======

:program:`mariadb-summary` 6.0.2.1

