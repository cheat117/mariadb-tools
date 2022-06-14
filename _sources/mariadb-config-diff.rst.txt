.. program:: mariadb-config-diff

==============================
:program:`mariadb-config-diff`
==============================

NAME
====

:program:`mariadb-config-diff` - Diff MySQL configuration files and server variables.

SYNOPSIS
========

Usage
-----

::

  mariadb-config-diff [OPTIONS] CONFIG CONFIG [CONFIG...]

:program:`mariadb-config-diff` diffs MySQL configuration files and server variables.
CONFIG can be a filename or a DSN.  At least two CONFIG sources must be given.
Like standard Unix diff, there is no output if there are no differences.

Diff host1 config from SHOW VARIABLES against host2:

.. code-block:: bash

   mariadb-config-diff h=host1 h=host2

Diff config from [mysqld] section in my.cnf against host1 config:

.. code-block:: bash

   mariadb-config-diff /etc/my.cnf h=host1

Diff the [mysqld] section of two option files:

.. code-block:: bash

    mariadb-config-diff /etc/my-small.cnf /etc/my-large.cnf

RISKS
=====

:program:`mariadb-config-diff` is mature, proven in the real world, and well tested,
but all database tools can pose a risk to the system and the database
server.  Before using this tool, please:

* Read the tool's documentation

* Review the tool's known "BUGS"

* Test the tool on a non-production server

* Backup your production server and verify the backups

DESCRIPTION
===========

:program:`mariadb-config-diff` diffs MySQL configurations by examining the values of server
system variables from two or more CONFIG sources specified on the command
line.  A CONFIG source can be a DSN or a filename containing the output of
``mysqld --help --verbose``, ``my_print_defaults``, ``SHOW VARIABLES``, or
an option file (e.g. my.cnf).

For each DSN CONFIG, :program:`mariadb-config-diff` connects to MySQL and gets variables
and values by executing ``SHOW /*!40103 GLOBAL*/ VARIABLES``.  This is
an "active config" because it shows what server values MySQL is
actively (currently) running with.

Only variables that all CONFIG sources have are compared because if a
variable is not present then we cannot know or safely guess its value.
For example, if you compare an option file (e.g. my.cnf) to an active config
(i.e. SHOW VARIABLES from a DSN CONFIG), the option file will probably
only have a few variables, whereas the active config has every variable.
Only values of the variables present in both configs are compared.

Option file and DSN configs provide the best results.

OUTPUT
======

There is no output when there are no differences.  When there are differences,
:program:`mariadb-config-diff` prints a report to STDOUT that looks similar to the following:

.. code-block:: bash

   2 config differences
   Variable                  my.master.cnf   my.slave.cnf
   ========================= =============== ===============
   datadir                   /tmp/12345/data /tmp/12346/data
   port                      12345           12346

Comparing MySQL variables is difficult because there are many variations and
subtleties across the many versions and distributions of MySQL.  When a
comparison fails, the tool prints a warning to STDERR, such as the following:

.. code-block:: bash

   Comparing log_error values (mysqld.log, /tmp/12345/data/mysqld.log)
   caused an error: Argument "/tmp/12345/data/mysqld.log" isn't numeric
   in numeric eq (==) at ./mariadb-config-diff line 2311.

Please report these warnings so the comparison functions can be improved.

EXIT STATUS
===========

:program:`mariadb-config-diff` exits with a zero exit status when there are no differences, and
1 if there are.

OPTIONS
=======

This tool accepts additional command-line arguments.  Refer to the
"SYNOPSIS" and usage information for details.

.. option:: --ask-pass

 Prompt for a password when connecting to MySQL.

.. option:: --charset

 short form: -A; type: string

 Default character set.  If the value is utf8, sets Perl's binmode on
 STDOUT to utf8, passes the mysql_enable_utf8 option to DBD::mysql, and
 runs SET NAMES UTF8 after connecting to MySQL.  Any other value sets
 binmode on STDOUT without the utf8 layer, and runs SET NAMES after
 connecting to MySQL.

.. option:: --config

 type: Array

 Read this comma-separated list of config files; if specified, this must be the
 first option on the command line.  (This option does not specify a CONFIG;
 it's equivalent to ``--defaults-file``.)

.. option:: --database

 short form: -D; type: string

 Connect to this database.

.. option:: --defaults-file

 short form: -F; type: string

 Only read mysql options from the given file.  You must give an absolute
 pathname.

.. option:: --help

 Show help and exit.

.. option:: --host

 short form: -h; type: string

 Connect to host.

.. option:: --[no]ignore-case

 default: yes

 Compare the variables case-insensitively.

.. option:: --ignore-variables

 type: array

 Ignore, do not compare, these variables.

.. option:: --password

 short form: -p; type: string

 Password to use for connection.

.. option:: --pid

 type: string

 Create the given PID file.  The tool won't start if the PID file already
 exists and the PID it contains is different than the current PID.  However,
 if the PID file exists and the PID it contains is no longer running, the
 tool will overwrite the PID file with the current PID.  The PID file is
 removed automatically when the tool exits.

.. option:: --port

 short form: -P; type: int

 Port number to use for connection.

.. option:: --[no]report

 default: yes

 Print the MySQL config diff report to STDOUT.  If you just want to check
 if the given configs are different or not by examining the tool's exit
 status, then specify ``--no-report`` to suppress the report.

.. option:: --report-width

 type: int; default: 78

 Truncate report lines to this many characters.  Since some variable values can
 be long, or when comparing multiple configs, it may help to increase the
 report width so values are not truncated beyond readability.

.. option:: --set-vars

 type: Array

 Set the MySQL variables in this comma-separated list of ``variable=value`` pairs.

 By default, the tool sets:

 .. code-block:: bash

     wait_timeout=10000

 Variables specified on the command line override these defaults.  For
 example, specifying ``--set-vars wait_timeout=500`` overrides the defaultvalue of ``10000``.

 The tool prints a warning and continues if a variable cannot be set.

.. option:: --socket

 short form: -S; type: string

 Socket file to use for connection.

.. option:: --user

 short form: -u; type: string

 MySQL user if not current user.

.. option:: --version

 Show version and exit.

DSN OPTIONS
===========

These DSN options are used to create a DSN.  Each option is given like
``option=value``.  The options are case-sensitive, so P and p are not the
same option.  There cannot be whitespace before or after the ``=`` and
if the value contains whitespace it must be quoted.  DSN options are
comma-separated.  See the mariadb-tools manpage for full details.

* A

 dsn: charset; copy: yes

 Default character set.

* D

 dsn: database; copy: yes

 Default database.

* F

 dsn: mysql_read_default_file; copy: yes

 Only read default options from the given file

* h

 dsn: host; copy: yes

 Connect to host.

* p

 dsn: password; copy: yes

 Password to use when connecting.
 If password contains commas they must be escaped with a backslash: "exam\,ple"

* P

 dsn: port; copy: yes

 Port number to use for connection.

* S

 dsn: mysql_socket; copy: yes

 Socket file to use for connection.

* u

 dsn: user; copy: yes

 User for login if not current user.

ENVIRONMENT
===========

This tool doesn't require any environment variables for usability.

SYSTEM REQUIREMENTS
===================

You need Perl, DBI, DBD::mysql, and some core packages that ought to be
installed in any reasonably new version of Perl.

BUGS
====

Please report bugs at `https://jira.mariadb.org/projects/TOOLS <https://jira.mariadb.org/projects/TOOLS>`_.
Include the following information in your bug report:

* Complete command-line used to run the tool

* Tool :option:`--version`

* MariaDB version of all servers involved

* Output from the tool including STDERR

* Input files (log/dump/config files, etc.)

If possible, include debugging output by running the tool with ``PTDEBUG``;
see "ENVIRONMENT".

AUTHORS
=======

Cole Busby, Baron Schwartz and Daniel Nichter

ABOUT THIS MARIADB TOOL
=======================

This tool is part of MariaDB client tools. This MariaDB Tool was forked from
Percona Toolkit's :program:`mariadb-config-diff` in August, 2019. Percona Toolkit was forked from two
projects in June, 2011: Maatkit and Aspersa.  Those projects were created by
Baron Schwartz and primarily developed by him and Daniel Nichter.

COPYRIGHT, LICENSE, AND WARRANTY
================================

This program is copyright 2019-2022 MariaDB Corporation and/or its affiliates,
2011-2019 Percona LLC and/or its affiliates, 2010-2011 Baron Schwartz.

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

:program:`mariadb-config-diff` 6.0.2.1

