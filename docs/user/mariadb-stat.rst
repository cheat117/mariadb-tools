.. program:: mariadb-stat

=======================
:program:`mariadb-stat`
=======================

NAME
====

:program:`mariadb-stat` - Collect forensic data about MariaDB when problems occur.

SYNOPSIS
========

Usage
-----

::

  mariadb-stat [OPTIONS]

:program:`mariadb-stat` waits for a trigger condition to occur, then collects data
to help diagnose problems.  The tool is designed to run as a daemon with root
privileges, so that you can diagnose intermittent problems that you cannot
observe directly.  You can also use it to execute a custom command, or to
collect data on demand without waiting for the trigger to occur.

RISKS
=====

:program:`mariadb-stat` is mature, proven in the real world, and well tested,
but all database tools can pose a risk to the system and the database
server.  Before using this tool, please:

* Read the tool's documentation

* Review the tool's known "BUGS"

* Test the tool on a non-production server

* Backup your production server and verify the backups

DESCRIPTION
===========

Sometimes a problem happens infrequently and for a short time, giving you no
chance to see the system when it happens. How do you solve intermittent MariaDB
problems when you can't observe them? That's why :program:`mariadb-stat` exists. In addition to
using it when there's a known problem on your servers, it is a good idea to run
:program:`mariadb-stat` all the time, even when you think nothing is wrong.  You will
appreciate the data it collects when a problem occurs, because problems such as
MariaDB lockups or spikes in activity typically leave no evidence to use in root
cause analysis.

:program:`mariadb-stat` does two things: it watches a MariaDB server and waits for a trigger
condition to occur, and it collects diagnostic data when that trigger occurs.
To avoid false-positives caused by short-lived problems, the trigger condition
must be true at least :option:`--cycles` times before a :option:`--collect` is triggered.

To use :program:`mariadb-stat` effectively, you need to define a good trigger.  A good trigger
is sensitive enough to fire reliably when a problem occurs, so that you don't
miss a chance to solve problems.  On the other hand, a good trigger isn't
prone to false positives, so you don't gather information when the server
is functioning normally.

The most reliable triggers for MariaDB tend to be the number of connections to the
server, and the number of queries running concurrently. These are available in
the SHOW GLOBAL STATUS command as Threads_connected and Threads_running.
Sometimes Threads_connected is not a reliable indicator of trouble, but
Threads_running usually is.  Your job, as the tool's user, is to define an
appropriate trigger condition for the tool.  Choose carefully, because the
quality of your results will depend on the trigger you choose.

You define the trigger with the :option:`--function`, :option:`--variable`, 
:option:`--threshold`, and :option:`--cycles` options.  The default values
for these options define a reasonable trigger, but you should adjust
or change them to suite your particular system and needs.

By default, :program:`mariadb-stat` tool watches MariaDB forever until the trigger occurs,
then it collects diagnostic data for a while, and sleeps afterwards to avoid
repeatedly collecting data if the trigger remains true.  The general order of
operations is:

.. code-block:: bash

    while true; do
       if --variable from --function > --threshold; then
          cycles_true++
          if cycles_true >= --cycles; then
             --notify-by-email
             if --collect; then
                if --disk-bytes-free and --disk-pct-free ok; then
                   (--collect for --run-time seconds) &
                fi
                rm files in --dest older than --retention-time
             fi
             iter++
             cycles_true=0
          fi
          if iter < --iterations; then
             sleep --sleep seconds
          else
             break
          fi
       else
          if iter < --iterations; then
             sleep --interval seconds
          else
             break
          fi
       fi
    done
    rm old --dest files older than --retention-time
    if --collect process are still running; then
       wait up to --run-time * 3 seconds
       kill any remaining --collect processes 
    fi

The diagnostic data is written to files whose names begin with a timestamp, so
you can distinguish samples from each other in case the tool collects data
multiple times.  The pt-sift tool is designed to help you browse and analyze
the resulting data samples.

Although this sounds simple enough, in practice there are a number of
subtleties, such as detecting when the disk is beginning to fill up so that the
tool doesn't cause the server to run out of disk space.  This tool handles these
types of potential problems, so it's a good idea to use this tool instead of
writing something from scratch and possibly experiencing some of the hazards
this tool is designed to avoid.

CONFIGURING
===========

You can use standard MariaDB tool configuration files to set command line
options.

You will probably want to run the tool as a daemon and customize at least the
:option:`--threshold`.  Here's a sample configuration file for triggering when
there are more than 20 queries running at once:

.. code-block:: bash

   daemonize
   threshold=20

If you don't run the tool as root, then you will need specify several options,
such as :option:`--pid`, :option:`--log`, and :option:`--dest`, else the tool will probably
fail to start.

OPTIONS
=======

.. option:: --ask-pass

 Prompt for a password when connecting to MariaDB.

.. option:: --collect

 default: yes; negatable: yes

 Collect diagnostic data when the trigger occurs.  Specify ``--no-collect``
 to make the tool watch the system but not collect data.

 See also :option:`--stalk`.

.. option:: --collect-gdb

 Collect GDB stacktraces.  This is achieved by attaching to MariaDB and printing
 stack traces from all threads. This will freeze the server for some period of
 time, ranging from a second or so to much longer on very busy systems with a lot
 of memory and many threads in the server.  For this reason, it is disabled by
 default. However, if you are trying to diagnose a server stall or lockup,
 freezing the server causes no additional harm, and the stack traces can be vital
 for diagnosis.

 In addition to freezing the server, there is also some risk of the server
 crashing or performing badly after GDB detaches from it.

.. option:: --collect-oprofile

 Collect oprofile data.  This is achieved by starting an oprofile session,
 letting it run for the collection time, and then stopping and saving the
 resulting profile data in the system's default location.  Please read your
 system's oprofile documentation to learn more about this.

.. option:: --collect-strace

 Collect strace data. This is achieved by attaching strace to the server, which
 will make it run very slowly until strace detaches.  The same cautions apply as
 those listed in --collect-gdb.  You should not enable this option together with
 --collect-gdb, because GDB and strace can't attach to the server process
 simultaneously.

.. option:: --collect-tcpdump

 Collect tcpdump data. This option causes tcpdump to capture all traffic on all
 interfaces for the port on which MariaDB is listening.  You can later use
 pt-query-digest to decode the MariaDB protocol and extract a log of query traffic
 from it.

.. option:: --config

 type: string

 Read this comma-separated list of config files.  If specified, this must be the
 first option on the command line.

.. option:: --cycles

 type: int; default: 5

 How many times :option:`--variable` must be greater than :option:`--threshold` before triggering :option:`--collect`.  This helps prevent false positives, and makes
 the trigger condition less likely to fire when the problem recovers quickly.

.. option:: --daemonize

 Daemonize the tool.  This causes the tool to fork into the background and log
 its output as specified in --log.

.. option:: --defaults-file

 short form: -F; type: string

 Only read mariadb options from the given file.  You must give an absolute
 pathname.

.. option:: --dest

 type: string; default: /var/lib/mariadb-stat

 Where to save diagnostic data from :option:`--collect`.  Each time the tool
 collects data, it writes to a new set of files, which are named with the
 current system timestamp.

.. option:: --disk-bytes-free

 type: size; default: 100M

 Do not :option:`--collect` if the disk has less than this much free space.
 This prevents the tool from filling up the disk with diagnostic data.

 If the :option:`--dest` directory contains a previously captured sample of data,
 the tool will measure its size and use that as an estimate of how much data is
 likely to be gathered this time, too.  It will then be even more pessimistic,
 and will refuse to collect data unless the disk has enough free space to hold
 the sample and still have the desired amount of free space.  For example, if
 you'd like 100MB of free space and the previous diagnostic sample consumed
 100MB, the tool won't collect any data unless the disk has 200MB free.

 Valid size value suffixes are k, M, G, and T.

.. option:: --disk-pct-free

 type: int; default: 5

 Do not :option:`--collect` if the disk has less than this percent free space.
 This prevents the tool from filling up the disk with diagnostic data.

 This option works similarly to :option:`--disk-bytes-free` but specifies a
 percentage margin of safety instead of a bytes margin of safety.
 The tool honors both options, and will not collect any data unless both
 margins are satisfied.

.. option:: --function

 type: string; default: status

 What to watch for the trigger.  The default value watches
 ``SHOW GLOBAL STATUS``, but you can also watch ``SHOW PROCESSLIST`` and specify
 a file with your own custom code.  This function supplies the value of
 :option:`--variable`, which is then compared against :option:`--threshold` to see if the
 the trigger condition is met.  Additional options may be required as
 well; see below. Possible values are:

 * status

  Watch ``SHOW GLOBAL STATUS`` for the trigger.  The value of
  :option:`--variable` then defines which status counter is the trigger.


 * processlist

  Watch ``SHOW FULL PROCESSLIST`` for the trigger.  The trigger
  value is the count of processes whose :option:`--variable` column matches the
  :option:`--match` option.  For example, to trigger :option:`--collect` when more than
  10 processes are in the "statistics" state, specify:

  .. code-block:: bash

      --function processlist \
      --variable State       \
      --match statistics     \
      --threshold 10


 In addition, you can specify a file that contains your custom trigger
 function, written in Unix shell script.  This can be a wrapper that executes
 anything you wish.  If the argument to :option:`--function` is a file, then it
 takes precedence over built-in functions, so if there is a file in the working
 directory named "status" or "processlist" then the tool will use that file
 even though are valid built-in values.

 The file works by providing a function called ``trg_plugin``, and the tool
 simply sources the file and executes the function.  For example, the file
 might contain:

 .. code-block:: bash

     trg_plugin() {
        mysql $EXT_ARGV -e "SHOW ENGINE INNODB STATUS" \
          | grep -c "has waited at"
     }

 This snippet will count the number of mutex waits inside InnoDB.  It
 illustrates the general principle: the function must output a number, which is
 then compared to :option:`--threshold` as usual.  The ``$EXT_ARGV`` variable
 contains the MariaDB options mentioned in the "SYNOPSIS" above.

 The file should not alter the tool's existing global variables.  Prefix any
 file-specific global variables with "PLUGIN_" or make them local.

.. option:: --help

 Print help and exit.

.. option:: --host

 short form: -h; type: string

 Host to connect to.

.. option:: --interval

 type: int; default: 1

 How often to check the if trigger is true, in seconds.

.. option:: --iterations

 type: int

 How many times to :option:`--collect` diagnostic data.  By default, the tool
 runs forever and collects data every time the trigger occurs.
 Specify :option:`--iterations` to collect data a limited number of times.
 This option is also useful with ``--no-stalk`` to collect data once and
 exit, for example.

.. option:: --log

 type: string; default: /var/log/mariadb-stat.log

 Print all output to this file when daemonized.

.. option:: --match

 type: string

 The pattern to use when watching SHOW PROCESSLIST.  See :option:`--function`
 for details.

.. option:: --notify-by-email

 type: string

 Send an email to these addresses for every :option:`--collect`.

.. option:: --password

 short form: -p; type: string

 Password to use when connecting.
 If password contains commas they must be escaped with a backslash: "exam\,ple"

.. option:: --pid

 type: string; default: /var/run/mariadb-stat.pid

 Create the given PID file.  The tool won't start if the PID file already
 exists and the PID it contains is different than the current PID.  However,
 if the PID file exists and the PID it contains is no longer running, the
 tool will overwrite the PID file with the current PID.  The PID file is
 removed automatically when the tool exits.

.. option:: --plugin

 type: string

 Load a plugin to hook into the tool and extend is functionality.
 The specified file does not need to be executable, nor does its first line
 need to be shebang line.  It only needs to define one or more of these
 Bash functions:

 before_stalk

  Called before stalking.


 before_collect

  Called when the trigger occurs, before running a :option:`--collect`
  subprocesses in the background.


 after_collect

  Called after running a collector process.  The PID of the collector process
  is passed as the first argument.  This hook is called before
  ``after_collect_sleep``.


 after_collect_sleep

  Called after sleeping :option:`--sleep` seconds for the collector process to finish.
  This hook is called after ``after_collect``.


 after_interval_sleep

  Called after sleeping :option:`--interval` seconds after each trigger check.


 after_stalk

  Called after stalking.  Since :program:`mariadb-stat` stalks forever by default,
  this hook is only called if :option:`--iterations` is specified.


 For example, a very simple plugin that touches a file when :option:`--collect`
 is triggered:

 .. code-block:: bash

     before_collect() {
        touch /tmp/foo
     }

 Since the plugin is completely sourced (imported) into the tool's namespace,
 be careful not to define other functions or global variables that already
 exist in the tool.  You should prefix all plugin-specific functions and
 global variables with ``plugin_`` or ``PLUGIN_``.

 Plugins have access to all command line options but they should not modify
 them.  Each option is a global variable like ``$OPT_DEST`` which corresponds
 to :option:`--dest`.  Therefore, the global variable for each command line option
 is ``OPT_`` plus the option name in all caps with hyphens replaced by
 underscores.

 Plugins can stop the tool by setting the global variable ``OKTORUN``
 to ``1``.  In this case, the global variable ``EXIT_REASON`` should also
 be set to indicate why the tool was stopped.

 Plugin writers should keep in mind that the file destination prefix currently
 in use should be accessed through the ``$prefix`` variable, rather than
 ``$OPT_PREFIX``.

.. option:: --mariadb-only

 Trigger only MariaDB related captures, ignoring all others. The only not MariaDB related
 value being collected is the disk space, because it is needed to calculate the
 available free disk space to write the result files.
 This option is useful for RDS instances.

.. option:: --port

 short form: -P; type: int

 Port number to use for connection.

.. option:: --prefix

 type: string

 The filename prefix for diagnostic samples.  By default, all files created
 by the same :option:`--collect` instance have a timestamp prefix based on the current
 local time, like ``2011_12_06_14_02_02``, which is December 6, 2011 at 14:02:02.

.. option:: --retention-count

 type: int; default: 0

 Keep the data for the last N runs. If N > 0, the program will keep the data for the last
 N runs and will delete the older data.

.. option:: --retention-size

 type: int; default: 0

 Keep up to --retention-size MB of data. It will keep at least 1 run even if the size is bigger
 than the specified in this parameter

.. option:: --retention-time

 type: int; default: 30

 Number of days to retain collected samples.  Any samples that are older will be
 purged.

.. option:: --run-time

 type: int; default: 30

 How long to :option:`--collect` diagnostic data when the trigger occurs.
 The value is in seconds and should not be longer than :option:`--sleep`.  It is
 usually not necessary to change this; if the default 30 seconds doesn't
 collect enough data, running longer is not likely to help because the system
 or MariaDB server is probably too busy to respond.  In fact, in many cases a
 shorter collection period is appropriate.

 This value is used two other times.  After collecting, the collect subprocess
 will wait another :option:`--run-time` seconds for its commands to finish.  Some
 commands can take awhile if the system is running very slowly (which can
 likely be the case given that a collection was triggered).  Since empty files
 are deleted, the extra wait gives commands time to finish and write their
 data.  The value is potentially used again just before the tool exits to wait
 again for any collect subprocesses to finish.  In most cases this won't
 happen because of the aforementioned extra wait.  If it happens, the tool
 will log "Waiting up to N seconds for subprocesses to finish..." where N is
 three times :option:`--run-time`.  In both cases, after waiting, the tool kills
 all of its subprocesses.

.. option:: --sleep

 type: int; default: 300

 How long to sleep after :option:`--collect`.  This prevents the tool
 from triggering continuously, which might be a problem if the collection process is intrusive.
 It also prevents filling up the disk or gathering too much data to analyze
 reasonably.

.. option:: --sleep-collect

 type: int; default: 1

 How long to sleep between collection loop cycles.  This is useful with
 ``--no-stalk`` to do long collections.  For example, to collect data every
 minute for an hour, specify: ``--no-stalk --run-time 3600 --sleep-collect 60``.

.. option:: --socket

 short form: -S; type: string

 Socket file to use for connection.

.. option:: --stalk

 default: yes; negatable: yes

 Watch the server and wait for the trigger to occur.  Specify ``--no-stalk``
 to collect diagnostic data immediately, that is, without waiting for the
 trigger to occur.  You probably also want to specify values for
 :option:`--interval`, :option:`--iterations`, and :option:`--sleep`.  For example, to
 immediately collect data for 1 minute then exit, specify:

 .. code-block:: bash

     --no-stalk --run-time 60 --iterations 1

 :option:`--cycles`, :option:`--daemonize`, :option:`--log` and :option:`--pid` have no effect
 with ``--no-stalk``.  Safeguard options, like :option:`--disk-bytes-free` and
 :option:`--disk-pct-free`, are still respected.

 See also :option:`--collect`.

.. option:: --threshold

 type: int; default: 25

 The maximum acceptable value for :option:`--variable`.  :option:`--collect` is
 triggered when the value of :option:`--variable` is greater than :option:`--threshold`
 for :option:`--cycles` many times.  Currently, there is no way to define a lower
 threshold to check for a :option:`--variable` value that is too low.

 See also :option:`--function`.

.. option:: --user

 short form: -u; type: string

 User for login if not current user.

.. option:: --variable

 type: string; default: Threads_running

 The variable to compare against :option:`--threshold`.  See also :option:`--function`.

.. option:: --verbose

 type: int; default: 2

 Print more or less information while running.  Since the tool is designed
 to be a long-running daemon, the default verbosity level only prints the
 most important information.  If you run the tool interactively, you may
 want to use a higher verbosity level.

 .. code-block:: bash

    LEVEL PRINTS
    ===== =====================================
    0     Errors
    1     Warnings
    2     Matching triggers and collection info
    3     Non-matching triggers


.. option:: --version

 Print tool's version and exit.

ENVIRONMENT
===========

This tool does not require any environment variables for configuration,
although it can be influenced to work differently by through several
variables.  Keep in mind that these are expert settings, and should not
be used in most cases.

Specifically, the variables that can be set are:

CMD_GDB

CMD_IOSTAT

CMD_MPSTAT

CMD_MYSQL

CMD_MYSQLADMIN

CMD_OPCONTROL

CMD_OPREPORT

CMD_PMAP

CMD_STRACE

CMD_SYSCTL

CMD_TCPDUMP

CMD_VMSTAT

For example, during collection iostat is called with a -dx argument, but
because you have an NFS partition, you also need the -n flag there.  Instead
of editing the source, you can call :program:`mariadb-stat` as

.. code-block:: bash

     CMD_IOSTAT="iostat -n" mariadb-stat ...

which will do exactly what you need.  Combined with the plugin hooks, this
gives you a fine-grained control of what the tool does.

It is possible to enable ``debug`` mode in mysqladmin specifying:

``CMD_MYSQLADMIN='mysqladmin debug' :program:`mariadb-stat` params ...``

SYSTEM REQUIREMENTS
===================

This tool requires Bash v3 or newer.  Certain options require other programs:

:option:`--collect-gdb` requires ``gdb``

:option:`--collect-oprofile` requires ``opcontrol`` and ``opreport``

:option:`--collect-strace` requires ``strace``

:option:`--collect-tcpdump` requires ``tcpdump``

AUTHORS
=======

Cole Busby, Baron Schwartz, Justin Swanhart, Fernando Ipar, Daniel Nichter,
and Brian Fraser

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

:program:`mariadb-stat` 6.0.2.1

