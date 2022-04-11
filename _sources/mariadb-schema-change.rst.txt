.. program:: mariadb-schema-change

================================
:program:`mariadb-schema-change`
================================

NAME
====

:program:`mariadb-schema-change` - ALTER tables without locking them.

SYNOPSIS
========

Usage
-----

::

  mariadb-schema-change [OPTIONS] DSN

:program:`mariadb-schema-change` alters a table's structure without blocking reads or
writes.  Specify the database and table in the DSN. Do not use this tool before
reading its documentation and checking your backups carefully.

Add a column to sakila.actor:

.. code-block:: bash

   mariadb-schema-change --alter "ADD COLUMN c1 INT" D=sakila,t=actor

Change sakila.actor to InnoDB, effectively performing OPTIMIZE TABLE in a
non-blocking fashion because it is already an InnoDB table:

.. code-block:: bash

   mariadb-schema-change --alter "ENGINE=InnoDB" D=sakila,t=actor

RISKS
=====

:program:`mariadb-schema-change` is mature, proven in the real world, and well tested,
but all database tools can pose a risk to the system and the database
server.  Before using this tool, please:

* Read the tool's documentation

* Review the tool's known "BUGS"

* Test the tool on a non-production server

* Backup your production server and verify the backups

DESCRIPTION
===========

:program:`mariadb-schema-change` emulates the way that MariaDB alters tables internally,
but it works on a copy of the table you wish to alter. This means that the
original table is not locked, and clients may continue to read and change data
in it.

:program:`mariadb-schema-change` works by creating an empty copy of the table to alter,
modifying it as desired, and then copying rows from the original table into the
new table. When the copy is complete, it moves away the original table and
replaces it with the new one.  By default, it also drops the original table.

The data copy process is performed in small chunks of data, which are varied to
attempt to make them execute in a specific amount of time (see
:option:`--chunk-time`).  This process is very similar to how other tools, such as
pt-table-checksum, work.  Any modifications to data in the original tables
during the copy will be reflected in the new table, because the tool creates
triggers on the original table to update the corresponding rows in the new
table.  The use of triggers means that the tool will not work if any triggers
are already defined on the table.

When the tool finishes copying data into the new table, it uses an atomic
``RENAME TABLE`` operation to simultaneously rename the original and new tables.
After this is complete, the tool drops the original table.

Foreign keys complicate the tool's operation and introduce additional risk.  The
technique of atomically renaming the original and new tables does not work when
foreign keys refer to the table. The tool must update foreign keys to refer to
the new table after the schema change is complete. The tool supports two methods
for accomplishing this. You can read more about this in the documentation for
:option:`--alter-foreign-keys-method`.

Foreign keys also cause some side effects. The final table will have the same
foreign keys and indexes as the original table (unless you specify differently
in your ALTER statement), but the names of the objects may be changed slightly
to avoid object name collisions in MariaDB and InnoDB.

For safety, the tool does not modify the table unless you specify the
:option:`--execute` option, which is not enabled by default.  The tool supports a
variety of other measures to prevent unwanted load or other problems, including
automatically detecting replicas, connecting to them, and using the following
safety checks:

*

 In most cases the tool will refuse to operate unless a PRIMARY KEY or UNIQUE INDEX is 
 present in the table. See :option:`--alter` for details.

*

 The tool refuses to operate if it detects replication filters. See
 :option:`--[no]check-replication-filters` for details.

*

 The tool pauses the data copy operation if it observes any replicas that are
 delayed in replication. See :option:`--max-lag` for details.

*

 The tool pauses or aborts its operation if it detects too much load on the
 server. See :option:`--max-load` and :option:`--critical-load` for details.

*

 The tool sets ``innodb_lock_wait_timeout=1`` and (for MariaDB 5.5 and newer)
 ``lock_wait_timeout=60`` so that it is more likely to be the victim of any
 lock contention, and less likely to disrupt other transactions.  These
 values can be changed by specifying :option:`--set-vars`.

*

 The tool refuses to alter the table if foreign key constraints reference it,
 unless you specify :option:`--alter-foreign-keys-method`.

*

 The tool cannot alter MyISAM tables on "Galera" nodes.

MariaDB Galera Cluster
======================

:program:`mariadb-schema-change` works with Galera Cluster 5.5.28
and newer, but there are two limitations: only InnoDB tables can be altered,
and ``wsrep_OSU_method`` must be set to ``TOI`` (total order isolation).
The tool exits with an error if the host is a cluster node and the table
is MyISAM or is being converted to MyISAM (``ENGINE=MyISAM``), or if
``wsrep_OSU_method`` is not ``TOI``.  There is no way to disable these checks.

*******************************
MariaDB 10.2+ Generated columns
*******************************

The tools ignores MariaDB 10.2+ ``GENERATED`` columns since the value for those columns
is generated according to the expresion used to compute column values.

OUTPUT
======

The tool prints information about its activities to STDOUT so that you can see
what it is doing.  During the data copy phase, it prints :option:`--progress`
reports to STDERR.  You can get additional information by specifying
:option:`--print`.

If :option:`--statistics` is specified, a report of various internal event counts
is printed at the end, like:

.. code-block:: bash

    # Event  Count
    # ====== =====
    # INSERT     1

OPTIONS
=======

:option:`--dry-run` and :option:`--execute` are mutually exclusive.

This tool accepts additional command-line arguments.  Refer to the
"SYNOPSIS" and usage information for details.

.. option:: --alter

 type: string

 The schema modification, without the ALTER TABLE keywords. You can perform
 multiple modifications to the table by specifying them with commas. Please refer
 to the MariaDB manual for the syntax of ALTER TABLE.

 The following limitations apply which, if attempted, will cause the tool
 to fail in unpredictable ways:

 *

  In almost all cases a PRIMARY KEY or UNIQUE INDEX needs to be present in the table. 
  This is necessary because the tool creates a DELETE trigger to keep the new table 
  updated while the process is running.

  A notable exception is when a PRIMARY KEY or UNIQUE INDEX is being created from 
  **existing columns** as part of the ALTER clause; in that case it will use these 
  column(s) for the DELETE trigger.


 *

  The ``RENAME`` clause cannot be used to rename the table.


 *

  Columns cannot be renamed by dropping and re-adding with the new name.
  The tool will not copy the original column's data to the new column.


 *

  If you add a column without a default value and make it NOT NULL, the tool
  will fail, as it will not try to guess a default value for you; You must
  specify the default.


 *

  ``DROP FOREIGN KEY constraint_name`` requires specifying ``_constraint_name``
  rather than the real ``constraint_name``.  Due to a limitation in MariaDB,
  :program:`mariadb-schema-change` adds a leading underscore to foreign key constraint
  names when creating the new table.  For example, to drop this constraint:

  .. code-block:: bash

     CONSTRAINT `fk_foo` FOREIGN KEY (`foo_id`) REFERENCES `bar` (`foo_id`)

  You must specify ``--alter "DROP FOREIGN KEY _fk_foo"``.


 *

  The tool does not use ``LOCK IN SHARE MODE`` with MariaDB 5.0 because it can
  cause a slave error which breaks replication:

  .. code-block:: bash

      Query caused different errors on master and slave. Error on master:
      'Deadlock found when trying to get lock; try restarting transaction' (1213),
      Error on slave: 'no error' (0). Default database: 'pt_osc'.
      Query: 'INSERT INTO pt_osc.t (id, c) VALUES ('730', 'new row')'

  The error happens when converting a MyISAM table to InnoDB because MyISAM
  is non-transactional but InnoDB is transactional.  MariaDB 5.1 and newer
  handle this case correctly, but testing reproduces the error 5% of the time
  with MariaDB 5.0.

  This is a MariaDB bug, similar to `http://bugs.mysql.com/bug.php?id=45694 <http://bugs.mysql.com/bug.php?id=45694>`_,
  but there is no fix or workaround in MariaDB 5.0.  Without ``LOCK IN SHARE MODE``,
  tests pass 100% of the time, so the risk of data loss or breaking replication
  should be negligible.

  **Be sure to verify the new table if using MariaDB 5.0 and converting
  from MyISAM to InnoDB!**


.. option:: --alter-foreign-keys-method

 type: string

 How to modify foreign keys so they reference the new table.  Foreign keys that
 reference the table to be altered must be treated specially to ensure that they
 continue to reference the correct table. When the tool renames the original
 table to let the new one take its place, the foreign keys "follow" the renamed
 table, and must be changed to reference the new table instead.

 The tool supports two techniques to achieve this. It automatically finds "child
 tables" that reference the table to be altered.

 auto

  Automatically determine which method is best.  The tool uses
  ``rebuild_constraints`` if possible (see the description of that method for
  details), and if not, then it uses ``drop_swap``.


 rebuild_constraints

  This method uses ``ALTER TABLE`` to drop and re-add foreign key constraints that
  reference the new table.  This is the preferred technique, unless one or more of
  the "child" tables is so large that the ``ALTER`` would take too long.  The tool
  determines that by comparing the number of rows in the child table to the rate
  at which the tool is able to copy rows from the old table to the new table. If
  the tool estimates that the child table can be altered in less time than the
  :option:`--chunk-time`, then it will use this technique.  For purposes of estimating
  the time required to alter the child table, the tool multiplies the row-copying
  rate by :option:`--chunk-size-limit`, because MariaDB's ``ALTER TABLE`` is typically
  much faster than the external process of copying rows.

  Due to a limitation in MariaDB, foreign keys will not have the same names after
  the ALTER that they did prior to it. The tool has to rename the foreign key
  when it redefines it, which adds a leading underscore to the name. In some
  cases, MariaDB also automatically renames indexes required for the foreign key.


 drop_swap

  Disable foreign key checks (FOREIGN_KEY_CHECKS=0), then drop the original table
  before renaming the new table into its place. This is different from the normal
  method of swapping the old and new table, which uses an atomic ``RENAME`` that is
  undetectable to client applications.

  This method is faster and does not block, but it is riskier for two reasons.
  First, for a short time between dropping the original table and renaming the
  temporary table, the table to be altered simply does not exist, and queries
  against it will result in an error.  Secondly, if there is an error and the new
  table cannot be renamed into the place of the old one, then it is too late to
  abort, because the old table is gone permanently.

  This method forces ``--no-swap-tables`` and ``--no-drop-old-table``.


 none

  This method is like ``drop_swap`` without the "swap".  Any foreign keys that
  referenced the original table will now reference a nonexistent table. This will
  typically cause foreign key violations that are visible in ``SHOW ENGINE INNODB
  STATUS``, similar to the following:

  .. code-block:: bash

      Trying to add to index `idx_fk_staff_id` tuple:
      DATA TUPLE: 2 fields;
      0: len 1; hex 05; asc  ;;
      1: len 4; hex 80000001; asc     ;;
      But the parent table `sakila`.`staff_old`
      or its .ibd file does not currently exist!

  This is because the original table (in this case, sakila.staff) was renamed to
  sakila.staff_old and then dropped. This method of handling foreign key
  constraints is provided so that the database administrator can disable the
  tool's built-in functionality if desired.


.. option:: --[no]analyze-before-swap

 default: yes

 Execute ANALYZE TABLE on the new table before swapping with the old one.
 By default, this happens only when running MariaDB 5.6 and newer, and
 ``innodb_stats_persistent`` is enabled. Specify the option explicitly to enable
 or disable it regardless of MariaDB version and ``innodb_stats_persistent``.

 This circumvents a potentially serious issue related to InnoDB optimizer
 statistics. If the table being alerted is busy and the tool completes quickly,
 the new table will not have optimizer statistics after being swapped. This can
 cause fast, index-using queries to do full table scans until optimizer
 statistics are updated (usually after 10 seconds). If the table is large and
 the server very busy, this can cause an outage.

.. option:: --ask-pass

 Prompt for a password when connecting to MariaDB.

.. option:: --channel

 type: string

 Channel name used when connected to a server using replication channels.
 Suppose you have two masters, master_a at port 12345, master_b at port 1236 and
 a slave connected to both masters using channels chan_master_a and chan_master_b.
 If you want to run pt-table-sync to synchronize the slave against master_a, pt-table-sync
 won't be able to determine what's the correct master since SHOW SLAVE STATUS
 will return 2 rows. In this case, you can use --channel=chan_master_a to specify
 the channel name to use in the SHOW SLAVE STATUS command.

.. option:: --charset

 short form: -A; type: string

 Default character set.  If the value is utf8, sets Perl's binmode on
 STDOUT to utf8, passes the mysql_enable_utf8 option to DBD::mysql, and runs SET
 NAMES UTF8 after connecting to MariaDB.  Any other value sets binmode on STDOUT
 without the utf8 layer, and runs SET NAMES after connecting to MariaDB.

.. option:: --[no]check-alter

 default: yes

 Parses the :option:`--alter` specified and tries to warn of possible unintended
 behavior. Currently, it checks for:

 Column renames

  In previous versions of the tool, renaming a column with
  ``CHANGE COLUMN name new_name`` would lead to that column's data being lost.
  The tool now parses the alter statement and tries to catch these cases, so
  the renamed columns should have the same data as the originals. However, the
  code that does this is not a full-blown SQL parser, so you should first
  run the tool with :option:`--dry-run` and :option:`--print` and verify that it detects
  the renamed columns correctly.


 DROP PRIMARY KEY

  If :option:`--alter` contain ``DROP PRIMARY KEY`` (case- and space-insensitive),
  a warning is printed and the tool exits unless :option:`--dry-run` is specified.
  Altering the primary key can be dangerous, but the tool can handle it.
  The tool's triggers, particularly the DELETE trigger, are most affected by
  altering the primary key because the tool prefers to use the primary key
  for its triggers.  You should first run the tool with :option:`--dry-run` and
  :option:`--print` and verify that the triggers are correct.


.. option:: --[no]check-foreign-keys

 default: yes

 Check for self-referencing foreign keys. Currently self referencing FKs are
 not full supported, so, to prevent errors, this program won't run if the table
 has self-referencing foreign keys. Use this parameter to disable self-referencing
 FK checks.

.. option:: --check-interval

 type: time; default: 1

 Sleep time between checks for :option:`--max-lag`.

.. option:: --[no]check-plan

 default: yes

 Check query execution plans for safety. By default, this option causes
 the tool to run EXPLAIN before running queries that are meant to access
 a small amount of data, but which could access many rows if MariaDB chooses a bad
 execution plan. These include the queries to determine chunk boundaries and the
 chunk queries themselves. If it appears that MariaDB will use a bad query
 execution plan, the tool will skip the chunk of the table.

 The tool uses several heuristics to determine whether an execution plan is bad.
 The first is whether EXPLAIN reports that MariaDB intends to use the desired index
 to access the rows. If MariaDB chooses a different index, the tool considers the
 query unsafe.

 The tool also checks how much of the index MariaDB reports that it will use for
 the query. The EXPLAIN output shows this in the key_len column. The tool
 remembers the largest key_len seen, and skips chunks where MariaDB reports that it
 will use a smaller prefix of the index. This heuristic can be understood as
 skipping chunks that have a worse execution plan than other chunks.

 The tool prints a warning the first time a chunk is skipped due to
 a bad execution plan in each table. Subsequent chunks are skipped silently,
 although you can see the count of skipped chunks in the SKIPPED column in
 the tool's output.

 This option adds some setup work to each table and chunk. Although the work is
 not intrusive for MariaDB, it results in more round-trips to the server, which
 consumes time. Making chunks too small will cause the overhead to become
 relatively larger. It is therefore recommended that you not make chunks too
 small, because the tool may take a very long time to complete if you do.

.. option:: --[no]check-replication-filters

 default: yes

 Abort if any replication filter is set on any server.  The tool looks for
 server options that filter replication, such as binlog_ignore_db and
 replicate_do_db.  If it finds any such filters, it aborts with an error.

 If the replicas are configured with any filtering options, you should be careful
 not to modify any databases or tables that exist on the master and not the
 replicas, because it could cause replication to fail.  For more information on
 replication rules, see `http://dev.mysql.com/doc/en/replication-rules.html <http://dev.mysql.com/doc/en/replication-rules.html>`_.

.. option:: --check-slave-lag

 type: string

 Pause the data copy until this replica's lag is less than :option:`--max-lag`.  The
 value is a DSN that inherits properties from the the connection options
 (:option:`--port`, :option:`--user`, etc.).  This option overrides the normal behavior of
 finding and continually monitoring replication lag on ALL connected replicas.
 If you don't want to monitor ALL replicas, but you want more than just one
 replica to be monitored, then use the DSN option to the :option:`--recursion-method`
 option instead of this option.

.. option:: --chunk-index

 type: string

 Prefer this index for chunking tables.  By default, the tool chooses the most
 appropriate index for chunking.  This option lets you specify the index that you
 prefer.  If the index doesn't exist, then the tool will fall back to its default
 behavior of choosing an index.  The tool adds the index to the SQL statements in
 a ``FORCE INDEX`` clause.  Be careful when using this option; a poor choice of
 index could cause bad performance.

.. option:: --chunk-index-columns

 type: int

 Use only this many left-most columns of a :option:`--chunk-index`.  This works
 only for compound indexes, and is useful in cases where a bug in the MariaDB
 query optimizer (planner) causes it to scan a large range of rows instead
 of using the index to locate starting and ending points precisely.  This
 problem sometimes occurs on indexes with many columns, such as 4 or more.
 If this happens, the tool might print a warning related to the
 :option:`--[no]check-plan` option.  Instructing the tool to use only the first
 N columns of the index is a workaround for the bug in some cases.

.. option:: --chunk-size

 type: size; default: 1000

 Number of rows to select for each chunk copied.  Allowable suffixes are
 k, M, G.

 This option can override the default behavior, which is to adjust chunk size
 dynamically to try to make chunks run in exactly :option:`--chunk-time` seconds.
 When this option isn't set explicitly, its default value is used as a starting
 point, but after that, the tool ignores this option's value.  If you set this
 option explicitly, however, then it disables the dynamic adjustment behavior and
 tries to make all chunks exactly the specified number of rows.

 There is a subtlety: if the chunk index is not unique, then it's possible that
 chunks will be larger than desired. For example, if a table is chunked by an
 index that contains 10,000 of a given value, there is no way to write a WHERE
 clause that matches only 1,000 of the values, and that chunk will be at least
 10,000 rows large.  Such a chunk will probably be skipped because of
 :option:`--chunk-size-limit`.

.. option:: --chunk-size-limit

 type: float; default: 4.0

 Do not copy chunks this much larger than the desired chunk size.

 When a table has no unique indexes, chunk sizes can be inaccurate.  This option
 specifies a maximum tolerable limit to the inaccuracy.  The tool uses <EXPLAIN>
 to estimate how many rows are in the chunk.  If that estimate exceeds the
 desired chunk size times the limit, then the tool skips the chunk.

 The minimum value for this option is 1, which means that no chunk can be larger
 than :option:`--chunk-size`.  You probably don't want to specify 1, because rows
 reported by EXPLAIN are estimates, which can be different from the real number
 of rows in the chunk.  You can disable oversized chunk checking by specifying a
 value of 0.

 The tool also uses this option to determine how to handle foreign keys that
 reference the table to be altered. See :option:`--alter-foreign-keys-method` for
 details.

.. option:: --chunk-time

 type: float; default: 0.5

 Adjust the chunk size dynamically so each data-copy query takes this long to
 execute.  The tool tracks the copy rate (rows per second) and adjusts the chunk
 size after each data-copy query, so that the next query takes this amount of
 time (in seconds) to execute.  It keeps an exponentially decaying moving average
 of queries per second, so that if the server's performance changes due to
 changes in server load, the tool adapts quickly.

 If this option is set to zero, the chunk size doesn't auto-adjust, so query
 times will vary, but query chunk sizes will not. Another way to do the same
 thing is to specify a value for :option:`--chunk-size` explicitly, instead of leaving
 it at the default.

.. option:: --config

 type: Array

 Read this comma-separated list of config files; if specified, this must be the
 first option on the command line.

.. option:: --critical-load

 type: Array; default: Threads_running=50

 Examine SHOW GLOBAL STATUS after every chunk, and abort if the load is too high.
 The option accepts a comma-separated list of MariaDB status variables and
 thresholds.  An optional ``=MAX_VALUE`` (or ``:MAX_VALUE``) can follow each
 variable.  If not given, the tool determines a threshold by examining the
 current value at startup and doubling it.

 See :option:`--max-load` for further details. These options work similarly, except
 that this option will abort the tool's operation instead of pausing it, and the
 default value is computed differently if you specify no threshold.  The reason
 for this option is as a safety check in case the triggers on the original table
 add so much load to the server that it causes downtime.  There is probably no
 single value of Threads_running that is wrong for every server, but a default of
 50 seems likely to be unacceptably high for most servers, indicating that the
 operation should be canceled immediately.

.. option:: --database

 short form: -D; type: string

 Connect to this database.

.. option:: --default-engine

 Remove ``ENGINE`` from the new table.

 By default the new table is created with the same table options as
 the original table, so if the original table uses InnoDB, then the new
 table will use InnoDB.  In certain cases involving replication, this may
 cause unintended changes on replicas which use a different engine for
 the same table.  Specifying this option causes the new table to be
 created with the system's default engine.

.. option:: --data-dir

 type: string

 Create the new table on a different partition using the DATA DIRECTORY feature.
 Only available on 5.6+. This parameter is ignored if it is used at the same time
 than remove-data-dir.

.. option:: --remove-data-dir

 default: no

 If the original table was created using the DATA DIRECTORY feature, remove it and create 
 the new table in MariaDB default directory without creating a new isl file.

.. option:: --defaults-file

 short form: -F; type: string

 Only read mysql options from the given file.  You must give an absolute
 pathname.

.. option:: --[no]drop-new-table

 default: yes

 Drop the new table if copying the original table fails.

 Specifying ``--no-drop-new-table`` and ``--no-swap-tables`` leaves the new,
 altered copy of the table without modifying the original table.  See
 :option:`--new-table-name`.

 --no-drop-new-table does not work with
 ``alter-foreign-keys-method drop_swap``.

.. option:: --[no]drop-old-table

 default: yes

 Drop the original table after renaming it. After the original table has been
 successfully renamed to let the new table take its place, and if there are no
 errors, the tool drops the original table by default. If there are any errors,
 the tool leaves the original table in place.

 If ``--no-swap-tables`` is specified, then there is no old table to drop.

.. option:: --[no]drop-triggers

 default: yes

 Drop triggers on the old table.  ``--no-drop-triggers`` forces
 ``--no-drop-old-table``.

.. option:: --dry-run

 Create and alter the new table, but do not create triggers, copy data, or
 replace the original table.

.. option:: --execute

 Indicate that you have read the documentation and want to alter the table.  You
 must specify this option to alter the table. If you do not, then the tool will
 only perform some safety checks and exit.  This helps ensure that you have read the
 documentation and understand how to use this tool.  If you have not read the
 documentation, then do not specify this option.

.. option:: --[no]check-unique-key-change

 default: yes

 Avoid :program:`mariadb-schema-change` to run if the specified statement for :option:`--alter` is 
 trying to add an unique index. 
 Since :program:`mariadb-schema-change` uses ``INSERT IGNORE`` to copy rows to the new table, if
 the row being written produces a duplicate key, it will fail silently and data will
 be lost.

 Example:

 .. code-block:: sql

      CREATE DATABASE test;
      USE test;
      CREATE TABLE `a` (
        `id` int(11) NOT NULL,
        `unique_id` varchar(32) DEFAULT NULL,
        PRIMARY KEY (`id`)
      ) ENGINE=InnoDB DEFAULT CHARSET=latin1;

      insert into a values (1, "a");
      insert into a values (2, "b");
      insert into a values (3, "");
      insert into a values (4, "");
      insert into a values (5, NULL);
      insert into a values (6, NULL);

 Using :program:`mariadb-schema-change` to add an unique index on the ``unique_id`` field, will cause some rows to
 be lost due to the use of ``INSERT IGNORE`` to copy rows from the source table.
 For this reason, :program:`mariadb-schema-change` will fail if it detects that the :option:`--alter` parameter is trying
 to add an unique key and it will show an example query to run to detect if there are 
 rows that will produce duplicated indexes.

 Even if you run the query and there are no rows that will produce duplicated indexes,
 take into consideration that after running this query, changes can be made to the table that can produce
 duplicate rows and this data will be lost.

.. option:: --force

 This options bypasses confirmation in case of using alter-foreign-keys-method = none , which might break foreign key constraints.

.. option:: --force-concat-enums

 The NibbleIterator in :program:`mariadb-schema-change` can detect indexes having ENUM fields and 
 if the items it has are sorted or not. According to documentation at 
 `https://dev.mysql.com/doc/refman/5.7/en/enum.html <https://dev.mysql.com/doc/refman/5.7/en/enum.html>`_:

 ENUM values are sorted based on their index numbers, which depend on the order in 
 which the enumeration members were listed in the column specification. 
 For example, 'b' sorts before 'a' for ENUM('b', 'a'). 
 The empty string sorts before nonempty strings, and NULL values sort before all other 
 enumeration values.

 To prevent unexpected results when using the ORDER BY clause on an ENUM column, 
 use one of these techniques:
 - Specify the ENUM list in alphabetic order.
 - Make sure that the column is sorted lexically rather than by index number by coding 
 ORDER BY CAST(col AS CHAR) or ORDER BY CONCAT(col).

 The NibbleIterator in :program:`mariadb-schema-change` uses CONCAT(col) but, doing that, adds overhead
 since MariaDB cannot use the column directly and has to calculate the result of CONCAT
 for every row.
 To make this scenario vissible to the user, if there are indexes having ENUM fields 
 with usorted items, it is necessary to specify the ``--force-concat-enums`` parameter.

.. option:: --help

 Show help and exit.

.. option:: --host

 short form: -h; type: string

 Connect to host.

.. option:: --max-flow-ctl

 type: float

 Somewhat similar to --max-lag but for PXC clusters.
 Check average time cluster spent pausing for Flow Control and make tool pause if 
 it goes over the percentage indicated in the option.
 A value of 0 would make the tool pause when *any* Flow Control activity is 
 detected.
 Default is no Flow Control checking.
 This option is available for PXC versions 5.6 or higher.

.. option:: --max-lag

 type: time; default: 1s

 Pause the data copy until all replicas' lag is less than this value.  After each
 data-copy query (each chunk), the tool looks at the replication lag of
 all replicas to which it connects, using Seconds_Behind_Master. If any replica
 is lagging more than the value of this option, then the tool will sleep
 for :option:`--check-interval` seconds, then check all replicas again.  If you
 specify :option:`--check-slave-lag`, then the tool only examines that server for
 lag, not all servers.  If you want to control exactly which servers the tool
 monitors, use the DSN value to :option:`--recursion-method`.

 The tool waits forever for replicas to stop lagging.  If any replica is
 stopped, the tool waits forever until the replica is started.  The data copy
 continues when all replicas are running and not lagging too much.

 The tool prints progress reports while waiting.  If a replica is stopped, it
 prints a progress report immediately, then again at every progress report
 interval.

.. option:: --max-load

 type: Array; default: Threads_running=25

 Examine SHOW GLOBAL STATUS after every chunk, and pause if any status variables
 are higher than their thresholds.  The option accepts a comma-separated list of
 MariaDB status variables.  An optional ``=MAX_VALUE`` (or ``:MAX_VALUE``) can follow
 each variable.  If not given, the tool determines a threshold by examining the
 current value and increasing it by 20%.

 For example, if you want the tool to pause when Threads_connected gets too high,
 you can specify "Threads_connected", and the tool will check the current value
 when it starts working and add 20% to that value.  If the current value is 100,
 then the tool will pause when Threads_connected exceeds 120, and resume working
 when it is below 120 again.  If you want to specify an explicit threshold, such
 as 110, you can use either "Threads_connected:110" or "Threads_connected=110".

 The purpose of this option is to prevent the tool from adding too much load to
 the server. If the data-copy queries are intrusive, or if they cause lock waits,
 then other queries on the server will tend to block and queue. This will
 typically cause Threads_running to increase, and the tool can detect that by
 running SHOW GLOBAL STATUS immediately after each query finishes.  If you
 specify a threshold for this variable, then you can instruct the tool to wait
 until queries are running normally again.  This will not prevent queueing,
 however; it will only give the server a chance to recover from the queueing.  If
 you notice queueing, it is best to decrease the chunk time.

.. option:: --preserve-triggers

 Preserves old triggers when specified. 
 As of MariaDB 10.2.3, it is possible to define multiple triggers for a given 
 table that have the same trigger event and action time. This allows us to
 add the triggers needed for :program:`mariadb-schema-change` even if the table
 already has its own triggers.
 If this option is enabled, :program:`mariadb-schema-change` will try to copy all the
 existing triggers to the new table BEFORE start copying rows from the original
 table to ensure the old triggers can be applied after altering the table.

 Example.

 .. code-block:: sql

    CREATE TABLE test.t1 (
         id INT NOT NULL AUTO_INCREMENT,
         f1 INT,
         f2 VARCHAR(32),
         PRIMARY KEY (id)
    );

    CREATE TABLE test.log (
       ts  TIMESTAMP,
       msg VARCHAR(255)
    );

    CREATE TRIGGER test.after_update
     AFTER
       UPDATE ON test.t1
       FOR EACH ROW 
         INSERT INTO test.log VALUES (NOW(), CONCAT("updated row row with id ", OLD.id, " old f1:", OLD.f1, " new f1: ", NEW.f1 ));

 For this table and triggers combination, it is not possible to use --preserve-triggers 
 with an --alter like this: ``"DROP COLUMN f1"`` since the trigger references the column 
 being dropped and at would make the trigger to fail.

 After testing the triggers will work on the new table, the triggers are 
 dropped from the new table until all rows have been copied and then they are
 re-applied.

 --preserve-triggers cannot be used with these other parameters, --no-drop-triggers, 
 --no-drop-old-table and --no-swap-tables since --preserve-triggers implies that 
 the old triggers should be deleted and recreated in the new table. 
 Since it is not possible to have more than one trigger with the same name, old triggers 
 must be deleted in order to be able to recreate them into the new table.

 Using ``--preserve-triggers`` with ``--no-swap-tables`` will cause triggers to remain
 defined for the original table.
 Please read the documentation for --swap-tables

 If both ``--no-swap-tables`` and ``--no-drop-new-table`` is set, the trigger will remain
 on the original table and will be duplicated on the new table 
 (the trigger will have a random suffix as no trigger names are unique).

.. option:: --new-table-name

 type: string; default: %T_new

 New table name before it is swapped.  ``%T`` is replaced with the original
 table name.  When the default is used, the tool prefixes the name with up
 to 10 ``_`` (underscore) to find a unique table name.  If a table name is
 specified, the tool does not prefix it with ``_``, so the table must not
 exist.

.. option:: --null-to-not-null

 Allows MODIFYing a column that allows NULL values to one that doesn't allow
 them. The rows which contain NULL values will be converted to the defined
 default value. If no explicit DEFAULT value is given MariaDB will assign a default
 value based on datatype, e.g. 0 for number datatypes, '' for string datatypes.

.. option:: --only-same-schema-fks

 Check foreigns keys only on tables on the same schema than the original table.
 This option is dangerous since if you have FKs refenrencing tables in other
 schemas, they won't be detected.

.. option:: --password

 short form: -p; type: string

 Password to use when connecting.
 If password contains commas they must be escaped with a backslash: "exam\,ple"

.. option:: --pause-file

 type: string

 Execution will be paused while the file specified by this param exists.

.. option:: --pid

 type: string

 Create the given PID file.  The tool won't start if the PID file already
 exists and the PID it contains is different than the current PID.  However,
 if the PID file exists and the PID it contains is no longer running, the
 tool will overwrite the PID file with the current PID.  The PID file is
 removed automatically when the tool exits.

.. option:: --plugin

 type: string

 Perl module file that defines a ``pt_online_schema_change_plugin`` class.
 A plugin allows you to write a Perl module that can hook into many parts
 of :program:`mariadb-schema-change`.  This requires a good knowledge of Perl and
 MariaDB tools conventions, which are beyond this scope of this
 documentation.  Please contact MariaDB if you have questions or need help.

 See "PLUGIN" for more information.

.. option:: --port

 short form: -P; type: int

 Port number to use for connection.

.. option:: --print

 Print SQL statements to STDOUT.  Specifying this option allows you to see most
 of the statements that the tool executes. You can use this option with
 :option:`--dry-run`, for example.

.. option:: --progress

 type: array; default: time,30

 Print progress reports to STDERR while copying rows.  The value is a
 comma-separated list with two parts.  The first part can be percentage, time, or
 iterations; the second part specifies how often an update should be printed, in
 percentage, seconds, or number of iterations.

.. option:: --quiet

 short form: -q

 Do not print messages to STDOUT (disables :option:`--progress`).
 Errors and warnings are still printed to STDERR.

.. option:: --recurse

 type: int

 Number of levels to recurse in the hierarchy when discovering replicas.
 Default is infinite.  See also :option:`--recursion-method`.

.. option:: --recursion-method

 type: array; default: processlist,hosts

 Preferred recursion method for discovering replicas.  Possible methods are:

 .. code-block:: bash

    METHOD       USES
    ===========  ==================
    processlist  SHOW PROCESSLIST
    hosts        SHOW SLAVE HOSTS
    dsn=DSN      DSNs from a table
    none         Do not find slaves

 The processlist method is the default, because SHOW SLAVE HOSTS is not
 reliable.  However, the hosts method can work better if the server uses a
 non-standard port (not 3306).  The tool usually does the right thing and
 finds all replicas, but you may give a preferred method and it will be used
 first.

 The hosts method requires replicas to be configured with report_host,
 report_port, etc.

 The dsn method is special: it specifies a table from which other DSN strings
 are read.  The specified DSN must specify a D and t, or a database-qualified
 t.  The DSN table should have the following structure:

 .. code-block:: sql

    CREATE TABLE `dsns` (
      `id` int(11) NOT NULL AUTO_INCREMENT,
      `parent_id` int(11) DEFAULT NULL,
      `dsn` varchar(255) NOT NULL,
      PRIMARY KEY (`id`)
    );

 To make the tool monitor only the hosts 10.10.1.16 and 10.10.1.17 for
 replication lag, insert the values ``h=10.10.1.16`` and ``h=10.10.1.17`` into the
 table. Currently, the DSNs are ordered by id, but id and parent_id are otherwise
 ignored.

 You can change the list of hosts while OSC is executing:
 if you change the contents of the DSN table, OSC will pick it up very soon.

--reverse-triggers Copy the triggers added during the copy in reverse order. Commands in the new table will be
reflected in the old table. You can use this as a safety feature, so that the old
table continues to receive updates. This option requires ``--no-drop-old-table``.

 Warning! This option creates reverse triggers on the new table before it starts copying.
 After new table is renamed to its original name triggers will continue working. But because the
 name change metadata version in the table cache will also change you may start receiving
 "Prepared statement needs to be re-prepared" errors. The workaround for this is to re-prepare statements.
 If you do not use server-side prepared statements your application should not be affected.

.. option:: --skip-check-slave-lag

 type: DSN; repeatable: yes

 DSN to skip when checking slave lag. It can be used multiple times.
 Example: --skip-check-slave-lag h=127.0.0.1,P=12345 --skip-check-slave-lag h=127.0.0.1,P=12346
 Plase take into consideration that even when for the MariaDB driver h=127.1 is equal to h=127.0.0.1,
 for this parameter you need to specify the full IP address.

.. option:: --slave-user

 type: string

 Sets the user to be used to connect to the slaves.
 This parameter allows you to have a different user with less privileges on the 
 slaves but that user must exist on all slaves.

.. option:: --slave-password

 type: string

 Sets the password to be used to connect to the slaves.
 It can be used with --slave-user and the password for the user must be the same
 on all slaves.

.. option:: --set-vars

 type: Array

 Set the MariaDB variables in this comma-separated list of ``variable=value`` pairs.

 By default, the tool sets:

 .. code-block:: bash

     wait_timeout=10000
     innodb_lock_wait_timeout=1
     lock_wait_timeout=60

 Variables specified on the command line override these defaults.  For
 example, specifying ``--set-vars wait_timeout=500`` overrides the default
 value of ``10000``.

 The tool prints a warning and continues if a variable cannot be set.

 Note that setting the ``sql_mode`` variable requires some tricky escapes
 to be able to parse the quotes and commas.

 Example:

 .. code-block:: bash

     --set-vars sql_mode=\'STRICT_ALL_TABLES\\,ALLOW_INVALID_DATES\'

 Note the single backslash for the quotes and double backslash for the comma.

.. option:: --sleep

 type: float; default: 0

 How long to sleep (in seconds) after copying each chunk. This option is useful 
 when throttling by :option:`--max-lag` and :option:`--max-load` are not possible. 
 A small, sub-second value should be used, like 0.1, else the tool could take 
 a very long time to copy large tables.

.. option:: --socket

 short form: -S; type: string

 Socket file to use for connection.

.. option:: --statistics

 Print statistics about internal counters.  This is useful to see how
 many warnings were suppressed compared to the number of INSERT.

.. option:: --[no]swap-tables

 default: yes

 Swap the original table and the new, altered table.  This step completes the
 online schema change process by making the table with the new schema take the
 place of the original table.  The original table becomes the "old table," and
 the tool drops it unless you disable :option:`--[no]drop-old-table`.

 Using ``--no-swap-tables`` will run the whole process, it will create the new
 table, it will copy all rows but at the end it will drop the new table. It is 
 intended to run a more realistic --dry-run.

.. option:: --tries

 type: array

 How many times to try critical operations.  If certain operations fail due
 to non-fatal, recoverable errors, the tool waits and tries the operation
 again.  These are the operations that are retried, with their default number
 of tries and wait time between tries (in seconds):

 .. code-block:: bash

     OPERATION            TRIES   WAIT
     ===================  =====   ====
     create_triggers         10      1
     drop_triggers           10      1
     copy_rows               10   0.25
     swap_tables             10      1
     update_foreign_keys     10      1
     analyze_table           10      1

 To change the defaults, specify the new values like:

 .. code-block:: bash

     --tries create_triggers:5:0.5,drop_triggers:5:0.5

 That makes the tool try ``create_triggers`` and ``drop_triggers`` 5 times
 with a 0.5 second wait between tries.  So the format is:

 .. code-block:: bash

     operation:tries:wait[,operation:tries:wait]

 All three values must be specified.

 Note that most operations are affected only in MariaDB 5.5 and newer by
 ``lock_wait_timeout`` (see :option:`--set-vars`) because of metadata locks.
 The ``copy_rows`` operation is affected in any version of MariaDB by
 ``innodb_lock_wait_timeout``.

 For creating and dropping triggers, the number of tries applies to each
 ``CREATE TRIGGER`` and ``DROP TRIGGER`` statement for each trigger.
 For copying rows, the number of tries applies to each chunk, not the
 entire table.  For swapping tables, the number of tries usually applies
 once because there is usually only one ``RENAME TABLE`` statement.
 For rebuilding foreign key constraints, the number of tries applies to
 each statement (``ALTER`` statements for the ``rebuild_constraints``
 :option:`--alter-foreign-keys-method`; other statements for the ``drop_swap``
 method).

 The tool retries each operation if these errors occur:

 .. code-block:: bash

     Lock wait timeout (innodb_lock_wait_timeout and lock_wait_timeout)
     Deadlock found
     Query is killed (KILL QUERY <thread_id>)
     Connection is killed (KILL CONNECTION <thread_id>)
     Lost connection to MariaDB

 In the case of lost and killed connections, the tool will automatically
 reconnect.

 Failures and retries are recorded in the :option:`--statistics`.

.. option:: --user

 short form: -u; type: string

 User for login if not current user.

.. option:: --version

 Show version and exit.

PLUGIN
======

The file specified by :option:`--plugin` must define a class (i.e. a package)
called ``pt_online_schema_change_plugin`` with a ``new()`` subroutine.
The tool will create an instance of this class and call any hooks that
it defines.  No hooks are required, but a plugin isn't very useful without
them.

These hooks, in this order, are called if defined:

.. code-block:: bash

    init
    before_create_new_table
    after_create_new_table
    before_alter_new_table
    after_alter_new_table
    before_create_triggers
    after_create_triggers
    before_copy_rows
    after_copy_rows
    before_swap_tables
    after_swap_tables
    before_update_foreign_keys
    after_update_foreign_keys
    before_drop_old_table
    after_drop_old_table
    before_drop_triggers
    before_exit
    get_slave_lag

Each hook is passed different arguments.  To see which arguments are passed
to a hook, search for the hook's name in the tool's source code, like:

.. code-block:: bash

    # --plugin hook
    if ( $plugin && $plugin->can('init') ) {
       $plugin->init(
          orig_tbl       => $orig_tbl,
          child_tables   => $child_tables,
          renamed_cols   => $renamed_cols,
          slaves         => $slaves,
          slave_lag_cxns => $slave_lag_cxns,
       );
    }

The comment ``# --plugin hook`` precedes every hook call.

Here's a plugin file template for all hooks:

.. code-block:: bash

    package pt_online_schema_change_plugin;

    use strict;

    sub new {
       my ($class, %args) = @_;
       my $self = { %args };
       return bless $self, $class;
    }

    sub init {
       my ($self, %args) = @_;
       print "PLUGIN init\n";
    }

    sub before_create_new_table {
       my ($self, %args) = @_;
       print "PLUGIN before_create_new_table\n";
    }

    sub after_create_new_table {
       my ($self, %args) = @_;
       print "PLUGIN after_create_new_table\n";
    }

    sub before_alter_new_table {
       my ($self, %args) = @_;
       print "PLUGIN before_alter_new_table\n";
    }

    sub after_alter_new_table {
       my ($self, %args) = @_;
       print "PLUGIN after_alter_new_table\n";
    }

    sub before_create_triggers {
       my ($self, %args) = @_;
       print "PLUGIN before_create_triggers\n";
    } 

   sub after_create_triggers {
       my ($self, %args) = @_;
       print "PLUGIN after_create_triggers\n";
    }

    sub before_copy_rows {
       my ($self, %args) = @_;
       print "PLUGIN before_copy_rows\n";
    }

    sub after_copy_rows {
       my ($self, %args) = @_;
       print "PLUGIN after_copy_rows\n";
    }

    sub before_swap_tables {
       my ($self, %args) = @_;
       print "PLUGIN before_swap_tables\n";
    }

    sub after_swap_tables {
       my ($self, %args) = @_;
       print "PLUGIN after_swap_tables\n";
    }

    sub before_update_foreign_keys {
       my ($self, %args) = @_;
       print "PLUGIN before_update_foreign_keys\n";
    }

    sub after_update_foreign_keys {
       my ($self, %args) = @_;
       print "PLUGIN after_update_foreign_keys\n";
    }

    sub before_drop_old_table {
       my ($self, %args) = @_;
       print "PLUGIN before_drop_old_table\n";
    }

    sub after_drop_old_table {
       my ($self, %args) = @_;
       print "PLUGIN after_drop_old_table\n";
    }

    sub before_drop_triggers {
       my ($self, %args) = @_;
       print "PLUGIN before_drop_triggers\n";
    }

    sub before_exit {
       my ($self, %args) = @_;
       print "PLUGIN before_exit\n";
    }

    sub get_slave_lag {
       my ($self, %args) = @_;
       print "PLUGIN get_slave_lag\n";

       return sub { return 0; };
    }

    1;

Notice that ``get_slave_lag`` must return a function reference; 
ideally one that returns actual slave lag, not simply zero like in the example.

Here's an example that actually does something:

.. code-block:: bash

    package pt_online_schema_change_plugin;

    use strict;

    sub new {
       my ($class, %args) = @_;
       my $self = { %args };
       return bless $self, $class;
    }

    sub after_create_new_table {
       my ($self, %args) = @_;
       my $new_tbl = $args{new_tbl};
       my $dbh     = $self->{cxn}->dbh;
       my $row = $dbh->selectrow_arrayref("SHOW CREATE TABLE $new_tbl->{name}");
       warn "after_create_new_table: $row->[1]\n\n";
    }

    sub after_alter_new_table {
       my ($self, %args) = @_;
       my $new_tbl = $args{new_tbl};
       my $dbh     = $self->{cxn}->dbh;
       my $row = $dbh->selectrow_arrayref("SHOW CREATE TABLE $new_tbl->{name}");
       warn "after_alter_new_table: $row->[1]\n\n";
    }

    1;

You could use this with :option:`--dry-run` to check how the table will look before and after.

Please contact MariaDB if you have questions or need help.

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

 dsn: database; copy: no

 Database for the old and new table.

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

* t

 dsn: table; copy: no

 Table to alter.

* u

 dsn: user; copy: yes

 User for login if not current user.

ENVIRONMENT
===========

The environment variable ``PTDEBUG`` enables verbose debugging output to STDERR.
To enable debugging and capture all output to a file, run the tool like:

.. code-block:: bash

    PTDEBUG=1 mariadb-schema-change ... > FILE 2>&1

Be careful: debugging output is voluminous and can generate several megabytes
of output.

EXIT STATUS
===========

.. code-block:: bash

    INVALID_PARAMETERS        = 1
    UNSUPORTED_MYSQL_VERSION  = 2
    NO_MINIMUM_REQUIREMENTS   = 3
    NO_PRIMARY_OR_UNIQUE_KEY  = 4
    INVALID_PLUGIN_FILE       = 5
    INVALID_ALTER_FK_METHOD   = 6
    INVALID_KEY_SIZE          = 7
    CANNOT_DETERMINE_KEY_SIZE = 9
    NOT_SAFE_TO_ASCEND        = 9
    ERROR_CREATING_NEW_TABLE  = 10
    ERROR_ALTERING_TABLE      = 11
    ERROR_CREATING_TRIGGERS   = 12
    ERROR_RESTORING_TRIGGERS  = 13
    ERROR_SWAPPING_TABLES     = 14
    ERROR_UPDATING_FKS        = 15
    ERROR_DROPPING_OLD_TABLE  = 16
    UNSUPORTED_OPERATION      = 17
    MYSQL_CONNECTION_ERROR    = 18
    LOST_MYSQL_CONNECTION     = 19

SYSTEM REQUIREMENTS
===================

You need Perl, DBI, DBD::mysql, and some core packages that ought to be
installed in any reasonably new version of Perl.

This tool works only on MariaDB 5.0.2 and newer versions, because earlier versions
do not support triggers. Also a number of permissions should be set on MariaDB 
to make :program:`mariadb-schema-change` operate as expected. PROCESS, SUPER, REPLICATION SLAVE
global privileges, as well as SELECT, INSERT, UPDATE, DELETE, CREATE, DROP, ALTER,
and TRIGGER table privileges should be granted on server. Slave needs only
REPLICATION SLAVE and REPLICATION CLIENT privileges.

AUTHORS
=======

Cole Busby, Daniel Nichter and Baron Schwartz

ACKNOWLEDGMENTS
===============

The "online schema change" concept was first implemented by Shlomi Noach
in his tool ``oak-online-alter-table``, part of
`http://code.google.com/p/openarkkit/ <http://code.google.com/p/openarkkit/>`_.  Engineers at Facebook then built
another version called ``OnlineSchemaChange.php`` as explained by their blog
post: `http://tinyurl.com/32zeb86 <http://tinyurl.com/32zeb86>`_. This tool is a hybrid of both approaches,
with additional features and functionality not present in either.

ABOUT THIS MARIADB TOOL
=======================

This tool is part of MariaDB client tools. This MariaDB Tool was forked from
Percona Toolkit's pt-online-schema-change in August, 2019. Percona Toolkit was
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

:program:`mariadb-schema-change` 6.0.2.1

