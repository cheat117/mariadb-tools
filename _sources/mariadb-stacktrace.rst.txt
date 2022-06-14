.. program:: mariadb-stacktrace

=============================
:program:`mariadb-stacktrace`
=============================

NAME
====

:program:`mariadb-stacktrace` - Aggregate GDB stack traces for a selected program.

SYNOPSIS
========

Usage
-----

::

  mariadb-stacktrace [OPTIONS] [FILES]

:program:`mariadb-stacktrace` is a poor man's profiler, inspired by `http://poormansprofiler.org <http://poormansprofiler.org>`_.
It can create and summarize full stack traces of processes on Linux.
Summaries of stack traces can be an invaluable tool for diagnosing what
a process is waiting for.

RISKS
=====

:program:`mariadb-stacktrace` is mature, proven in the real world, and well tested,
but all database tools can pose a risk to the system and the database
server.  Before using this tool, please:

* Read the tool's documentation

* Test the tool on a non-production server

* Backup your production server and verify the backups

DESCRIPTION
===========

:program:`mariadb-stacktrace` performs two tasks: it gets a stack trace, and it summarizes the stack
trace.  If a file is given on the command line, the tool skips the first step
and just aggregates the file.

To summarize the stack trace, the tool extracts the function name (symbol)
from each level of the stack, and combines them with commas.  It does this
for each thread in the output.  Afterwards, it sorts similar threads together
and counts how many of each one there are, then sorts them most-frequent first.

:program:`mariadb-stacktrace` is a read-only tool.  However, collecting GDB stacktraces is achieved by
attaching GDB to the program and printing stack traces from all threads. This
will freeze the program for some period of time, ranging from a second or so to
much longer on very busy systems with a lot of memory and many threads in the
program.  In the tool's default usage as a MariaDB profiling tool, this means that
MariaDB will be unresponsive while the tool runs, although if you are using the
tool to diagnose an unresponsive server, there is really no reason not to do
this.  In addition to freezing the server, there is also some risk of the server
crashing or performing badly after GDB detaches from it.

OPTIONS
=======

.. option:: --binary

 short form: -b; type: string; default: mysqld

 Which binary to trace.

.. option:: --help

 Show help and exit.

.. option:: --interval

 short form: -s; type: int; default: 0

 Number of seconds to sleep between :option:`--iterations`.

.. option:: --iterations

 short form: -i; type: int; default: 1

 How many traces to gather and aggregate.

.. option:: --lines

 short form: -l; type: int; default: 0

 Aggregate only first specified number of many functions; 0=infinity.

.. option:: --pid

 short form: -p; type: int

 Process ID of the process to trace; overrides :option:`--binary`.

.. option:: --save-samples

 short form: -k; type: string

 Keep the raw traces in this file after aggregation.

.. option:: --version

 Show version and exit.

ENVIRONMENT
===========

This tool does not use any environment variables.

SYSTEM REQUIREMENTS
===================

This tool requires Bash v3 or newer.  If no backtrace files are given,
then gdb is also required to create backtraces for the process specified
on the command line.

AUTHORS
=======

Cole Busby, Baron Schwartz, based on a script by Domas Mituzas (`http://poormansprofiler.org/ <http://poormansprofiler.org/>`_)

ABOUT THIS MARIADB TOOL
=======================

This tool is part of MariaDB client tools. This MariaDB Tool was forked from
Percona Toolkit's pt-pmp in August, 2019. Percona Toolkit was forked from two
projects in June, 2011: Maatkit and Aspersa.  Those projects were created by
Baron Schwartz and primarily developed by him and Daniel Nichter.

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

:program:`mariadb-stacktrace` 6.0.2.1

