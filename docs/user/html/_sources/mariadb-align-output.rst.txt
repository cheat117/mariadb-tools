.. program:: mariadb-align-output

===============================
:program:`mariadb-align-output`
===============================

NAME
====

:program:`mariadb-align-output` - Align output from other tools to columns.

SYNOPSIS
========

Usage
-----

::

  mariadb-align-output [FILES]

:program:`mariadb-align-output` aligns output from other tools to columns.  If no FILES are specified,
STDIN is read.

If a tool prints the following output,

.. code-block:: bash

    DATABASE TABLE   ROWS
    foo      bar      100
    long_db_name table  1
    another  long_name 500

then :program:`mariadb-align-output` reprints the output as,

.. code-block:: bash

    DATABASE     TABLE     ROWS
    foo          bar        100
    long_db_name table        1
    another      long_name  500

RISKS
=====

:program:`mariadb-align-output` is mature, proven in the real world, and well tested,
but all database tools can pose a risk to the system and the database
server.  Before using this tool, please:

* Read the tool's documentation

* Review the tool's known "BUGS"

* Test the tool on a non-production server

* Backup your production server and verify the backups

DESCRIPTION
===========

:program:`mariadb-align-output` reads lines and splits them into words.  It counts how many
words each line has, and if there is one number that predominates, it assumes
this is the number of words in each line.  Then it discards all lines that
don't have that many words, and looks at the 2nd line that does.  It assumes
this is the first non-header line.  Based on whether each word looks numeric
or not, it decides on column alignment.  Finally, it goes through and decides
how wide each column should be, and then prints them out.

This is useful for things like aligning the output of vmstat or iostat so it
is easier to read.

OPTIONS
=======

This tool accepts additional command-line arguments.  Refer to the
"SYNOPSIS" and usage information for details.

.. option:: --help

 Show help and exit.

.. option:: --version

 Show version and exit.

ENVIRONMENT
===========

This tool does not use any environment variables.

SYSTEM REQUIREMENTS
===================

You need Perl, and some core packages that ought to be installed in any
reasonably new version of Perl.

AUTHORS
=======

Cole Busby,Baron Schwartz, Brian Fraser, and Daniel Nichter

ABOUT THIS MARIADB TOOL
=======================

This tool is part of MariaDB client tools. This MariaDB Tool was forked from
Percona Toolkit's pt-align in August, 2019. Percona Toolkit was forked from two
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

:program:`mariadb-align-output` 6.0.2.1

