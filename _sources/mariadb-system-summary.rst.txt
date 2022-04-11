.. program:: mariadb-system-summary

=================================
:program:`mariadb-system-summary`
=================================

NAME
====

:program:`mariadb-system-summary` - Summarize system information nicely.

SYNOPSIS
========

Usage
-----

::

  mariadb-system-summary

:program:`mariadb-system-summary` conveniently summarizes the status and configuration of
a server. It is not a tuning tool or diagnosis tool.  It produces a report that
is easy to diff and can be pasted into emails without losing the formatting.  
This tool works well on many types of Unix systems.

RISKS
=====

:program:`mariadb-system-summary` is mature, proven in the real world, and well tested,
but all database tools can pose a risk to the system and the database
server.  Before using this tool, please:

* Read the tool's documentation

* Test the tool on a non-production server

* Backup your production server and verify the backups

DESCRIPTION
===========

:program:`mariadb-system-summary` runs a large variety of commands to inspect system status and
configuration, saves the output into files in a temporary directory, and
then runs Unix commands on these results to format them nicely.  It works
best when executed as a privileged user, but will also work without privileges,
although some output might not be possible to generate without root.

OUTPUT
======

Many of the outputs from this tool are deliberately rounded to show their
magnitude but not the exact detail. This is called fuzzy-rounding. The idea is
that it doesn't matter whether a particular counter is 918 or 921; such a small
variation is insignificant, and only makes the output hard to compare to other
servers. Fuzzy-rounding rounds in larger increments as the input grows. It
begins by rounding to the nearest 5, then the nearest 10, nearest 25, and then
repeats by a factor of 10 larger (50, 100, 250), and so on, as the input grows.

The following is a simple report generated from a CentOS virtual machine,
broken into sections with commentary following each section. Some long lines
are reformatted for clarity when reading this documentation as a manual page in
a terminal.

.. code-block:: bash

  # MariaDB System Summary Report ##############################
          Date | 2012-03-30 00:58:07 UTC (local TZ: EDT -0400)
      Hostname | localhost.localdomain
        Uptime | 20:58:06 up 1 day, 20 min, 1 user,
                 load average: 0.14, 0.18, 0.18
        System | innotek GmbH; VirtualBox; v1.2 ()
   Service Tag | 0
      Platform | Linux
       Release | CentOS release 5.5 (Final)
        Kernel | 2.6.18-194.el5
  Architecture | CPU = 32-bit, OS = 32-bit
     Threading | NPTL 2.5
      Compiler | GNU CC version 4.1.2 20080704 (Red Hat 4.1.2-48).
       SELinux | Enforcing
   Virtualized | VirtualBox

This section shows the current date and time, and a synopsis of the server and
operating system.

.. code-block:: bash

  # Processor ##################################################
    Processors | physical = 1, cores = 0, virtual = 1, hyperthreading = no
        Speeds | 1x2510.626
        Models | 1xIntel(R) Core(TM) i5-2400S CPU @ 2.50GHz
        Caches | 1x6144 KB

This section is derived from */proc/cpuinfo*.

.. code-block:: bash

  # Memory #####################################################
         Total | 503.2M
          Free | 29.0M
          Used | physical = 474.2M, swap allocated = 1.0M,
                 swap used = 16.0k, virtual = 474.3M
       Buffers | 33.9M
        Caches | 262.6M
         Dirty | 396 kB
       UsedRSS | 201.9M
    Swappiness | 60
   DirtyPolicy | 40, 10
   Locator  Size  Speed    Form Factor  Type    Type Detail
   =======  ====  =====    ===========  ====    ===========

Information about memory is gathered from ``free``. The Used statistic is the
total of the rss sizes displayed by ``ps``. The Dirty statistic for the cached
value comes from */proc/meminfo*. On Linux, the swappiness settings are
gathered from ``sysctl``. The final portion of this section is a table of the
DIMMs, which comes from ``dmidecode``. In this example there is no output.

.. code-block:: bash

  # Mounted Filesystems ########################################
    Filesystem                       Size Used Type  Opts Mountpoint
    /dev/mapper/VolGroup00-LogVol00   15G  17% ext3  rw   /
    /dev/sda1                         99M  13% ext3  rw   /boot
    tmpfs                            252M   0% tmpfs rw   /dev/shm

The mounted filesystem section is a combination of information from ``mount`` and
``df``. This section is skipped if you disable :option:`--summarize-mounts`.

.. code-block:: bash

  # Disk Schedulers And Queue Size #############################
          dm-0 | UNREADABLE
          dm-1 | UNREADABLE
           hdc | [cfq] 128
           md0 | UNREADABLE
           sda | [cfq] 128

The disk scheduler information is extracted from the */sys* filesystem in
Linux.

.. code-block:: bash

  # Disk Partioning ############################################
  Device       Type      Start        End               Size
  ============ ==== ========== ========== ==================
  /dev/sda     Disk                              17179869184
  /dev/sda1    Part          1         13           98703360
  /dev/sda2    Part         14       2088        17059230720

Information about disk partitioning comes from ``fdisk -l``.

.. code-block:: bash

  # Kernel Inode State #########################################
  dentry-state | 10697 8559  45 0  0  0
       file-nr | 960   0  50539
      inode-nr | 14059 8139

These lines are from the files of the same name in the */proc/sys/fs*
directory on Linux. Read the ``proc`` man page to learn about the meaning of
these files on your system.

.. code-block:: bash

  # LVM Volumes ################################################
  LV       VG         Attr   LSize   Origin Snap% Move Log Copy% Convert
  LogVol00 VolGroup00 -wi-ao 269.00G                                      
  LogVol01 VolGroup00 -wi-ao   9.75G

This section shows the output of ``lvs``.

.. code-block:: bash

  # RAID Controller ############################################
    Controller | No RAID controller detected

The tool can detect a variety of RAID controllers by examining ``lspci`` and
``dmesg`` information. If the controller software is installed on the system, in
many cases it is able to execute status commands and show a summary of the RAID
controller's status and configuration. If your system is not supported, please
file a bug report.

.. code-block:: bash

  # Network Config #############################################
    Controller | Intel Corporation 82540EM Gigabit Ethernet Controller
   FIN Timeout | 60
    Port Range | 61000

The network controllers attached to the system are detected from ``lspci``. The
TCP/IP protocol configuration parameters are extracted from ``sysctl``. You can skip this section by disabling the :option:`--summarize-network` option.

.. code-block:: bash

  # Interface Statistics #######################################
  interface rx_bytes rx_packets rx_errors tx_bytes tx_packets tx_errors
  ========= ======== ========== ========= ======== ========== =========
  lo        60000000      12500         0 60000000      12500         0
  eth0      15000000      80000         0  1500000      10000         0
  sit0             0          0         0        0          0         0

Interface statistics are gathered from ``ip -s link`` and are fuzzy-rounded. The
columns are received and transmitted bytes, packets, and errors.  You can skip
this section by disabling the :option:`--summarize-network` option.

.. code-block:: bash

  # Network Connections ########################################
    Connections from remote IP addresses
      127.0.0.1           2
    Connections to local IP addresses
      127.0.0.1           2
    Connections to top 10 local ports
      38346               1
      60875               1
    States of connections
      ESTABLISHED         5
      LISTEN              8

This section shows a summary of network connections, retrieved from ``netstat``
and "fuzzy-rounded" to make them easier to compare when the numbers grow large.
There are two sub-sections showing how many connections there are per origin
and destination IP address, and a sub-section showing the count of ports in
use.  The section ends with the count of the network connections' states.  You
can skip this section by disabling the :option:`--summarize-network` option.

.. code-block:: bash

  # Top Processes ##############################################
    PID USER  PR  NI  VIRT  RES  SHR S %CPU %MEM    TIME+  COMMAND
      1 root  15   0  2072  628  540 S  0.0  0.1   0:02.55 init
      2 root  RT  -5     0    0    0 S  0.0  0.0   0:00.00 migration/0
      3 root  34  19     0    0    0 S  0.0  0.0   0:00.03 ksoftirqd/0
      4 root  RT  -5     0    0    0 S  0.0  0.0   0:00.00 watchdog/0
      5 root  10  -5     0    0    0 S  0.0  0.0   0:00.97 events/0
      6 root  10  -5     0    0    0 S  0.0  0.0   0:00.00 khelper
      7 root  10  -5     0    0    0 S  0.0  0.0   0:00.00 kthread
     10 root  10  -5     0    0    0 S  0.0  0.0   0:00.13 kblockd/0
     11 root  20  -5     0    0    0 S  0.0  0.0   0:00.00 kacpid
  # Notable Processes ##########################################
    PID    OOM    COMMAND
   2028    +0    sshd

This section shows the first few lines of ``top`` so that you can see what
processes are actively using CPU time.  The notable processes include the SSH
daemon and any process whose out-of-memory-killer priority is set to 17. You
can skip this section by disabling the :option:`--summarize-processes` option.

.. code-block:: bash

  # Simplified and fuzzy rounded vmstat (wait please) ##########
    procs  ---swap-- -----io---- ---system---- --------cpu--------
     r  b    si   so    bi    bo     ir     cs  us  sy  il  wa  st
     2  0     0    0     3    15     30    125   0   0  99   0   0
     0  0     0    0     0     0   1250    800   6  10  84   0   0
     0  0     0    0     0     0   1000    125   0   0 100   0   0
     0  0     0    0     0     0   1000    125   0   0 100   0   0
     0  0     0    0     0   450   1000    125   0   1  88  11   0
  # The End ####################################################

This section is a trimmed-down sample of ``vmstat 1 5``, so you can see the
general status of the system at present. The values in the table are
fuzzy-rounded, except for the CPU columns.  You can skip this section by
disabling the :option:`--summarize-processes` option.

OPTIONS
=======

.. option:: --config

 type: string

 Read this comma-separated list of config files.  If specified, this must be the
 first option on the command line.

.. option:: --help

 Print help and exit.

.. option:: --read-samples

 type: string

 Create a report from the files in this directory.

.. option:: --save-samples

 type: string

 Save the collected data in this directory.

.. option:: --sleep

 type: int; default: 5

 How long to sleep when gathering samples from vmstat.

.. option:: --summarize-mounts

 default: yes; negatable: yes

 Report on mounted filesystems and disk usage.

.. option:: --summarize-network

 default: yes; negatable: yes

 Report on network controllers and configuration.

.. option:: --summarize-processes

 default: yes; negatable: yes

 Report on top processes and ``vmstat`` output.

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

Cole Busby, Baron Schwartz, Kevin van Zonneveld, and Brian Fraser

ABOUT THIS MARIADB TOOL
=======================

This tool is part of MariaDB client tools. This MariaDB Tool was forked from
Percona Toolkit's :program:`mariadb-system-summary` in August, 2019. Percona Toolkit was 
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

:program:`mariadb-system-summary` 6.0.2.1

