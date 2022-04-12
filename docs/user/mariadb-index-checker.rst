.. program:: mariadb-index-checker

================================
:program:`mariadb-index-checker`
================================

NAME
====

:program:`mariadb-index-checker` - Find duplicate indexes and foreign keys on MariaDB tables.

SYNOPSIS
========

Usage
-----

::

  mariadb-index-checker [OPTIONS] [DSN]

:program:`mariadb-index-checker` examines MariaDB tables for duplicate or redundant
indexes and foreign keys.  Connection options are read from MariaDB option files.

.. code-block:: bash

    mariadb-index-checker --host host1

RISKS
=====

MariaDB Tools is mature, proven in the real world, and well tested,
but all database tools can pose a risk to the system and the database
server.  Before using this tool, please:

* Read the tool's documentation

* Review the tool's known "BUGS"

* Test the tool on a non-production server

* Backup your production server and verify the backups

DESCRIPTION
===========

This program examines the output of SHOW CREATE TABLE on MariaDB tables, and if
it finds indexes that cover the same columns as another index in the same
order, or cover an exact leftmost prefix of another index, it prints out
the suspicious indexes.  By default, indexes must be of the same type, so a
BTREE index is not a duplicate of a FULLTEXT index, even if they have the same
columns.  You can override this.

It also looks for duplicate foreign keys.  A duplicate foreign key covers the
same columns as another in the same table, and references the same parent
table.

The output ends with a short summary that includes an estimate of the total
size, in bytes, that the duplicate indexes are using. This is calculated by
multiplying the index length by the number of rows in their respective tables.

OPTIONS
=======

This tool accepts additional command-line arguments.  Refer to the
"SYNOPSIS" and usage information for details.

.. option:: --all-structs

 Compare indexes with different structs (BTREE, HASH, etc).

 By default this is disabled, because a BTREE index that covers the same columns
 as a FULLTEXT index is not really a duplicate, for example.

.. option:: --ask-pass

 Prompt for a password when connecting to MariaDB.

.. option:: --charset

 short form: -A; type: string

 Default character set.  If the value is utf8, sets Perl's binmode on
 STDOUT to utf8, passes the mysql_enable_utf8 option to DBD::mysql, and runs SET
 NAMES UTF8 after connecting to MariaDB.  Any other value sets binmode on STDOUT
 without the utf8 layer, and runs SET NAMES after connecting to MariaDB.

.. option:: --[no]clustered

 default: yes

 PK columns appended to secondary key is duplicate.

 Detects when a suffix of a secondary key is a leftmost prefix of the primary
 key, and treats it as a duplicate key.  Only detects this condition on storage
 engines whose primary keys are clustered (currently InnoDB and solidDB).

 Clustered storage engines append the primary key columns to the leaf nodes of
 all secondary keys anyway, so you might consider it redundant to have them
 appear in the internal nodes as well.  Of course, you may also want them in the
 internal nodes, because just having them at the leaf nodes won't help for some
 queries.  It does help for covering index queries, however.

 Here's an example of a key that is considered redundant with this option:

 .. code-block:: bash

    PRIMARY KEY  (`a`)
    KEY `b` (`b`,`a`)

 The use of such indexes is rather subtle.  For example, suppose you have the
 following query:

 .. code-block:: bash

    SELECT ... WHERE b=1 ORDER BY a;

 This query will do a filesort if we remove the index on ``b,a``.  But if we
 shorten the index on ``b,a`` to just ``b`` and also remove the ORDER BY, the query
 should return the same results.

 The tool suggests shortening duplicate clustered keys by dropping the key
 and re-adding it without the primary key prefix.  The shortened clustered
 key may still duplicate another key, but the tool cannot currently detect
 when this happens without being ran a second time to re-check the newly
 shortened clustered keys.  Therefore, if you shorten any duplicate clustered
 keys, you should run the tool again.

.. option:: --config

 type: Array

 Read this comma-separated list of config files; if specified, this must be the
 first option on the command line.

.. option:: --databases

 short form: -d; type: hash

 Check only this comma-separated list of databases.

.. option:: --defaults-file

 short form: -F; type: string

 Only read mysql options from the given file.  You must give an absolute pathname.

.. option:: --engines

 short form: -e; type: hash

 Check only tables whose storage engine is in this comma-separated list.

.. option:: --help

 Show help and exit.

.. option:: --host

 short form: -h; type: string

 Connect to host.

.. option:: --ignore-databases

 type: Hash

 Ignore this comma-separated list of databases.

.. option:: --ignore-engines

 type: Hash

 Ignore this comma-separated list of storage engines.

.. option:: --ignore-order

 Ignore index order so KEY(a,b) duplicates KEY(b,a).

.. option:: --ignore-tables

 type: Hash

 Ignore this comma-separated list of tables.  Table names may be qualified with
 the database name.

.. option:: --key-types

 type: string; default: fk

 Check for duplicate f=foreign keys, k=keys or fk=both.

.. option:: --password

 short form: -p; type: string

 Password to use when connecting.
 If password contains commas they must be escaped with a backslash: "exam\,ple"

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

.. option:: --set-vars

 type: Array

 Set the MariaDB variables in this comma-separated list of ``variable=value`` pairs.

 By default, the tool sets:

 .. code-block:: bash

     wait_timeout=10000

 Variables specified on the command line override these defaults.  For
 example, specifying ``--set-vars wait_timeout=500`` overrides the defaultvalue of ``10000``.

 The tool prints a warning and continues if a variable cannot be set.

.. option:: --socket

 short form: -S; type: string

 Socket file to use for connection.

.. option:: --[no]sql

 default: yes

 Print DROP KEY statement for each duplicate key.  By default an ALTER TABLE
 DROP KEY statement is printed below each duplicate key so that, if you want to
 remove the duplicate key, you can copy-paste the statement into MariaDB.

 To disable printing these statements, specify ``--no-sql``.

.. option:: --[no]summary

 default: yes

 Print summary of indexes at end of output.

.. option:: --tables

 short form: -t; type: hash

 Check only this comma-separated list of tables.

 Table names may be qualified with the database name.

.. option:: --user

 short form: -u; type: string

 User for login if not current user.

.. option:: --verbose

 short form: -v

 Output all keys and/or foreign keys found, not just redundant ones.

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

This tool does not use any environment variables.

SYSTEM REQUIREMENTS
===================

You need Perl, and some core packages that ought to be installed in any
reasonably new version of Perl.

AUTHORS
=======

Cole Busby, Baron Schwartz, Brian Fraser, and Daniel Nichter

ABOUT THIS MARIADB TOOL
=======================

This tool is part of MariaDB client tools. This MariaDB Tool was forked from
Percona Toolkit's pt-duplicate-key-checker in October, 2021. Percona Toolkit 
was forked from two projects in June, 2011: Maatkit and Aspersa.  
Those projects were created by Baron Schwartz and primarily developed by him 
and Daniel Nichter.

COPYRIGHT, LICENSE, AND WARRANTY
================================

This program is copyright 2021-2022 MariaDB Corporation and/or its affiliates,
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

:program:`mariadb-index-checker` 6.0.2.1

