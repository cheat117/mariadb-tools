.. program:: mariadb-status-diff

==============================
:program:`mariadb-status-diff`
==============================

NAME
====

:program:`mariadb-status-diff` - Look at many samples of MariaDB ``SHOW GLOBAL STATUS`` side-by-side.

SYNOPSIS
========

Usage
-----

::

  mariadb-status-diff [OPTIONS] -- COMMAND

:program:`mariadb-status-diff` columnizes repeated output from a program like mariadb-admin extended.

Get output from ``mariadb-admin``:

.. code-block:: bash

    mariadb-status-diff -r -- mariadb-admin ext -i10 -c3

Get output from a file:

.. code-block:: bash

    mariadb-status-diff -r -- cat mariadb-admin-output.txt

RISKS
=====

:program:`mariadb-status-diff` is mature, proven in the real world, and well tested,
but all database tools can pose a risk to the system and the database
server.  Before using this tool, please:

* Read the tool's documentation

* Review the tool's known "BUGS"

* Test the tool on a non-production server

* Backup your production server and verify the backups

DESCRIPTION
===========

:program:`mariadb-status-diff` executes the ``COMMAND`` you specify, and reads through the result one
line at a time.  It places each line into a temporary file.  When it finds a
blank line, it assumes that a new sample of SHOW GLOBAL STATUS is starting,
and it creates a new temporary file.  At the end of this process, it has a
number of temporary files.  It joins the temporary files together side-by-side
and prints the result.  If :option:`--relative` option is given, it first subtracts
each sample from the one after it before printing results.

OPTIONS
=======

.. option:: --help

 Show help and exit.

.. option:: --relative

 short form: -r

 Subtract each column from the previous column.

.. option:: --version

 Show version and exit.

ENVIRONMENT
===========

This tool does not use any environment variables.

SYSTEM REQUIREMENTS
===================

This tool requires the Bourne shell (*/bin/sh*) and the seq program.

AUTHORS
=======

Cole Busby, Baron Schwartz

ABOUT THIS MARIADB TOOL
=======================

This tool is part of MariaDB client tools. This MariaDB Tool was forked from
Percona Toolkit's pt-mext in August, 2019. Percona Toolkit was forked from two
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

:program:`mariadb-status-diff` 6.0.2.1

