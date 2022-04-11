.. program:: mariadb-stat-browser

===============================
:program:`mariadb-stat-browser`
===============================

NAME
====

:program:`mariadb-stat-browser` - Browses files created by mariadb-stat.

SYNOPSIS
========

Usage
-----

::

  mariadb-stat-browser FILE|PREFIX|DIRECTORY

:program:`mariadb-stat-browser` browses files created by mariadb-stat.  If no options are given,
the tool browses all mariadb-stat files in ``/var/lib/mariadb-stat`` if that directory
exists, else the current working directory is used.  If a FILE is given,
the tool browses files with the same prefix in the given file's directory.
If a PREFIX is given, the tool browses files in ``/var/lib/mariadb-stat``
(or the current working directory) with the same prefix.  If a DIRECTORY
is given, the tool browses all mariadb-stat files in it.

RISKS
=====

Percona Toolkit is mature, proven in the real world, and well tested,
but all database tools can pose a risk to the system and the database
server.  Before using this tool, please:

* Read the tool's documentation

* Review the tool's known "BUGS"

* Test the tool on a non-production server

* Backup your production server and verify the backups

DESCRIPTION
===========

:program:`mariadb-stat-browser` downloads other tools that it might need, such as mariadb-iostat,
and then makes a list of the unique timestamp prefixes of all the files in
the directory, as written by the mariadb-stat tool.  If the user specified
a timestamp on the command line, then it begins with that sample of data;
otherwise it begins by showing a list of the timestamps and prompting for
a selection.  Thereafter, it displays a summary of the selected sample, and
the user can navigate and inspect with keystrokes.  The keystroke commands
you can use are as follows:

* d

 Sets the action to start the mariadb-iostat tool on the sample's disk
 performance statistics.

* i

 Sets the action to view the first INNODB STATUS sample in less.

* m

 Displays the first 4 samples of SHOW STATUS counters side by side with the
 mariadb-status-diff tool.

* n

 Summarizes the first sample of netstat data in two ways: by originating host,
 and by connection state.

* j

 Select the next timestamp as the active sample.

* k

 Select the previous timestamp as the active sample.

* q

 Quit the program.

* 1

 Sets the action for each sample to the default, which is to view a summary
 of the sample.

* 0

 Sets the action to just list the files in the sample.

* *

 Sets the action to view all of the sample's files in the less program.

OPTIONS
=======

.. option:: --help

 Show help and exit.

.. option:: --version

 Show version and exit.

ENVIRONMENT
===========

This tool does not use any environment variables.

SYSTEM REQUIREMENTS
===================

This tool requires Bash v3 and the following programs: mariadb-iostat, mariadb-stacktrace,
mariadb-status-diff, and mariadb-align-output.  If these programs are not in your PATH,
they will be fetched from the Internet if curl is available.

AUTHORS
=======

Cole Busby, Baron Schwartz

ABOUT THIS MARIADB TOOL
=======================

This tool is part of MariaDB client tools. This MariaDB Tool was forked from
Percona Toolkit's pt-stalk in August, 2019. Percona Toolkit was forked from two
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

:program:`mariadb-stat-browser` 6.0.2.1

