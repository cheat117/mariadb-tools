.. program:: mariadb-parted

=========================
:program:`mariadb-parted`
=========================

NAME
====

:program:`mariadb-parted` - MySQL partition management script

EXAMPLES
========

.. code-block:: bash

   # Create weekly partitions for the next quarter to test.part_table
   mariadb-parted --add --interval w +1q h=localhost,D=test,t=part_table

   # Create daily partitions for the next 2 weeks
   # starting exactly at the beginning of every day
   mariadb-parted --add --interval d +2w.startof h=localhost,D=test,t=part_table

   # Email ops@example.com about partitions added
   mariadb-parted --add --email-activity --email-to ops@example.com \
              --interval d +4w h=localhost,D=test,t=part_table

   # Drop partitions older than 8 weeks
   mariadb-parted --drop -8w h=localhost,D=test,t=part_table

   # Drop partitions older than Dec 20th, 2010, but only 5 of them.
   mariadb-parted --drop --limit 5 '2010-12-20 00:00:00' \
              h=localhost,D=test,t=part_table

   # Drop and archive partitions older than 2 quarters ago.
   mariadb-parted --drop --archive --archive-path /backups -2q \
              h=locahost,D=test,t=part_table

   # Same as above, but archived to a separate database.
   mariadb-parted --drop --archive --archive-database h=remotehost,D=test_archives,t=part_table -2q \
              h=locahost,D=test,t=part_table

   # Logging to syslog
   mariadb-parted --logfile syslog:LOCAL0 --add --interval d 1y \
              h=localhost,D=test,t=part_table

SYNOPSIS
========

:program:`mariadb-parted` [options] ACTION TIMESPEC DSN

This tool assists in the creation of partitions in regular intervals.
It creates partitions in regular intervals up to some maximum future date.

.. code-block:: bash

   --help,          -h   This help. See C<perldoc mariadb-parted> for full docs.
   --dryrun,        -n   Report on actions without taking them.
   --logfile,       -L   Direct output to given logfile. Default: none.

   --email-activity      Send a brief email report of actions taken.
                         The email is sent to --email-to.
   --use-hours 	        Use hours instead of days when checking partitions.
   --partcol-integer     Assume no partitioning time or date function in use
   --email-to,      -E   Where to send activity and failure emails.
                         Default: none.

   --prefix,        -P   Partition prefix. Defaults to 'p'.

   --archive             Archive partitions before dropping them.
   --archive-path        Directory to place mysqldumps.
                         Default: current directory.
   --archive-database    Database to archive partitions to.
                         Default: none

   --limit,         -m   Limit the number of actions to be performed.
                         Default: 0 (unlimited)

ACTION
======

.. code-block:: bash

   --add   Add partitions.
   --drop  Remove partitions.

TIMESPEC
========

A timespec is a "natural" string to specify how far in advance to create
partitions. A sampling of possible timespecs:

.. code-block:: bash

   1w (create partitions one week in advance)
   1m (one month)
   2q (two quarters)
   5h (five hours)

See the full documentation for a complete description of timespecs.

DSN
===

DSNs, such as those passed as option values, or arguments to a program
are of the format: ``({key}={value}(,{key}={value})*``. That is, a ``key=value`` pair, followed
by a comma, followed by any number of additional ``key=value`` pairs separated by
commas.

Examples
--------

.. code-block:: bash

   h=testdb1,u=pdb,p=frogs
   h=localhost,S=/tmp/mysql.sock,u=root,F=/root/my.cnf

Where 'h' is a hostname, 'S' is a socket path, 'u' is a user, 'F' is a path
to a defaults file, and 'p' is a password. These are non-exhaustive examples.

TIMESPEC
========

A timespec is one of:

.. code-block:: bash

   A modifier to current local time,
   A unix timestamp (assumed in UTC),
   The string 'now' to refer to current local time,
   An absolute time in 'YYYY-MM-DD HH:MM:SS' format,
   An absolute time in 'YYYY-MD-DD HH:MM:SS TIMEZONE' format.

For the purposes of this module, TIMEZONE refers to zone names
created and maintained by the zoneinfo database.
See `http://en.wikipedia.org/wiki/Tz_database <http://en.wikipedia.org/wiki/Tz_database>`_ for more information.
Commonly used zone names are: Etc/UTC, US/Pacific and US/Eastern.

Since the last four aren't very complicated, this section describes
what the modifiers are.

A modifer is, an optional plus or minus sign followed by a number,
and then one of:

.. code-block:: bash

   y = year, q = quarter , m = month, w = week, d = day, h = hour

Followed optionally by a space or a period and 'startof'.
Which is described in the next section.

Some examples (the time is assumed to be 00:00:00):

.. code-block:: bash

   -1y         (2010-11-01 -> 2009-11-01)
    5d         (2010-12-10 -> 2010-12-15)
   -1w         (2010-12-13 -> 2010-12-07)
   -1q startof (2010-05-01 -> 2010-01-01)
    1q.startof (2010-05-01 -> 2010-07-01)

startof
=======

The 'startof' modifier for timespecs is a little confusing,
but, is the only sane way to achieve latching like behavior.
It adjusts the reference time so that it starts at the beginning
of the requested type of interval. So, if you specify ``-1h startof``,
and the current time is: ``2010-12-03 04:33:56``, first the calculation
throws away ``33:56`` to get: ``2010-12-03 04:00:00``, and then subtracts
one hour to yield: ``2010-12-03 03:00:00``.

Diagram of the 'startof' operator for timespec ``-1q startof``,
given the date ``2010-05-01 00:00``.

.. code-block:: bash

           R P   C
           v v   v
    ---.---.---.---.---.--- Dec 2010
    ^   ^   ^   ^   ^   ^
    Jul Oct Jan Apr Jul Oct
   2009    2010

   . = quarter separator
   C = current quarter
   P = previous quarter
   R = Resultant time (2010-01-01 00:00:00)

OPTIONS
=======

--help, -h

 This help.

--dryrun, -n

 Report on actions that would be taken. Works best with the ``Pdb_DEBUG`` environment variable set to true.

 See also: ENVIRONMENT

--logfile, -L

 Path to a file for logging, or, ``syslog:<facility>``
 Where ``<facility>`` is a pre-defined logging facility for this machine.

 See also: syslog(3), syslogd(8), syslog.conf(5)

--email-to, -E

 Where to send emails.

 This tool can send emails on failure, and whenever it adds, drops, or archive partitions.
 Ordinarily, it will only send emails on failure.

.. option:: --email-activity

 If this flag is present, then this will make the tool also email
 whenver it adds, drops, or archives a partition.

.. option:: --use-hours

 If this flag is present, then partitions will be checked on the hour and not on the day.
 Useful when you need to partition by hour.

.. option:: --partcol-integer

 If this flag is present, then the tool will assume there is no partitioning function
 defined, e.g. if you are storing your date into an integer column

--prefix, -P

 Prefix for partition names. Partitions are always named like: <prefix>N.
 Where N is a number. Default is 'p', which was observed to be the most common prefix.

--interval, -i

 type: string one of: d w m y

 Specifies the size of the each partition for the --add action.
 'd' is day, 'w' is week, 'm' is month, and 'y' is year.

.. option:: --limit

 Specifies a limit to the number of partitions to add, drop, or archive.
 By default this is unlimited (0), so, for testing one usually wishes to set
 this to 1.

.. option:: --archive

 type: boolean

 mysqldump partitions to files **in the current directory** named like <host>.<schema>.<table>.<partition_name>.sql

 There is not currently a way to archive without dropping a partition.

.. option:: --archive-path

 What directory to place the SQL dumps of partition data in.

.. option:: --archive-database

 What database to place the archived partitions in.

ACTIONS
=======

.. option:: --add

 Adds partitions till there are at least TIMESPEC --interval sized future buckets.

 The adding of partitions is not done blindly. This will only add new partitions
 if there are fewer than TIMESPEC future partitions. For example:

 .. code-block:: bash

    Given: --interval d, today is: 2011-01-15, TIMESPEC is: +1w,
           last partition (p5) is for 2011-01-16;

    Result:
      Parted will add 6 partitions to make the last partition 2011-01-22 (p11).

    Before:
     |---+|
    p0  p5

    After:
     |---+-----|
    p0  p5    p11

 You can think of ``--add`` as specifying a required minimum safety zone.

.. option:: --drop

 Drops partitions strictly older than TIMESPEC.
 The partitions are not renumbered to start with p0 again.

 .. code-block:: bash

    Given: today is: 2011-01-15, TIMESPEC is: -1w,
           first partition (p0) is for 2011-01-06

    Result: 2 partitions will be dropped.

    Before: |-----+--|
            0     6  9
    After : |---+--|
            2   6  9


ENVIRONMENT
===========

Due to legacy reasons, this tool respond to the environment variable ``Pdb_DEBUG`` 
instead of PTDEBUG. This variable, when set to true, enables additional (very 
verbose) output from the tool.

SYSTEM REQUIREMENTS
===================

You need Perl, DBI, DBD::mysql, and some core packages that ought to be
installed in any reasonably new version of Perl.

ABOUT THIS MARIADB TOOL
=======================

This tool is part of MariaDB client tools. This MariaDB Tool was forked from
PalominoDB's pdb-parted in 2019.

COPYRIGHT, LICENSE, AND WARRANTY
================================

This program is copyright 2019-2022 MariaDB Corporation and/or its affiliates,
2009-2013 PalominoDB, Inc.

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

:program:`mariadb-parted` 6.0.2.1

