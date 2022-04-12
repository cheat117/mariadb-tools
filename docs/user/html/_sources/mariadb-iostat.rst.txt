.. program:: mariadb-iostat

=========================
:program:`mariadb-iostat`
=========================

NAME
====

:program:`mariadb-iostat` - An interactive I/O monitoring tool for GNU/Linux.

SYNOPSIS
========

Usage
-----

::

  mariadb-iostat [OPTIONS] [FILES]

:program:`mariadb-iostat` prints disk I/O statistics for GNU/Linux.  It is somewhat similar
to iostat, but it is interactive and more detailed.  It can analyze samples
gathered from another machine.

RISKS
=====

:program:`mariadb-iostat` is mature, proven in the real world, and well tested,
but all database tools can pose a risk to the system and the database
server.  Before using this tool, please:

* Read the tool's documentation

* Test the tool on a non-production server

* Backup your production server and verify the backups

DESCRIPTION
===========

The :program:`mariadb-iostat` tool is similar to iostat, but has some advantages. It prints
read and write statistics separately, and has more columns. It is menu-driven
and interactive, with several different ways to aggregate the data. It
integrates well with the mariadb-stat tool. It also does the "right thing" by
default, such as hiding disks that are idle.  These properties make it very
convenient for quickly drilling down into I/O performance and inspecting disk
behavior.

This program works in two modes. The default is to collect samples of
*/proc/diskstats* and print out the formatted statistics at intervals. The other
mode is to process a file that contains saved samples of */proc/diskstats*; there
is a shell script later in this documentation that shows how to collect such a
file.

In both cases, the tool is interactively controlled by keystrokes, so you can
redisplay and slice the data flexibly and easily.  It loops forever, until you
exit with the 'q' key.  If you press the '?' key, you will bring up the
interactive help menu that shows which keys control the program.

When the program is gathering samples of */proc/diskstats* and refreshing its
display, it prints information about the newest sample each time it refreshes.
When it is operating on a file of saved samples, it redraws the entire file's
contents every time you change an option.

The program doesn't print information about every block device on the system. It
hides devices that it has never observed to have any activity.  You can enable
and disable this by pressing the 'i' key.

OUTPUT
======

In the rest of this documentation, we will try to clarify the distinction
between block devices (/dev/sda1, for example), which the kernel presents to the
application via a filesystem, versus the (usually) physical device underneath
the block device, which could be a disk, a RAID controller, and so on.  We will
sometimes refer to logical I/O operations, which occur at the block device,
versus physical I/Os which are performed on the underlying device.  When we
refer to the queue, we are speaking of the queue associated with the block
device, which holds requests until they're issued to the physical device.

The program's output looks like the following sample, which is too wide for this
manual page, so we have formatted it as several samples with line breaks:

.. code-block:: bash

   #ts device rd_s rd_avkb rd_mb_s rd_mrg rd_cnc   rd_rt
   {6} sda     0.9     4.2     0.0     0%    0.0    17.9
   {6} sdb     0.4     4.0     0.0     0%    0.0    26.1
   {6} dm-0    0.0     4.0     0.0     0%    0.0    13.5
   {6} dm-1    0.8     4.0     0.0     0%    0.0    16.0

       ...    wr_s wr_avkb wr_mb_s wr_mrg wr_cnc   wr_rt
       ...    99.7     6.2     0.6    35%    3.7    23.7
       ...    14.5    15.8     0.2    75%    0.5     9.2
       ...     1.0     4.0     0.0     0%    0.0     2.3
       ...   117.7     4.0     0.5     0%    4.1    35.1

       ...              busy in_prg    io_s  qtime stime
       ...                6%      0   100.6   23.3   0.4
       ...                4%      0    14.9    8.6   0.6
       ...                0%      0     1.1    1.5   1.2
       ...                5%      0   118.5   34.5   0.4

The columns are as follows:

#ts

 This column's contents vary depending on the tool's aggregation mode.  In the
 default mode, when each line contains information about a single disk but
 possibly aggregates across several samples from that disk, this column shows the
 number of samples that were included into the line of output, in {curly braces}.
 In the example shown, each line of output aggregates {10} samples of
 */proc/diskstats*.

 In the "all" group-by mode, this column shows timestamp offsets, relative to the
 time the tool began aggregating or the timestamp of the previous lines printed,
 depending on the mode.  The output can be confusing to explain, but it's rather
 intuitive when you see the lines appearing on your screen periodically.

 Similarly, in "sample" group-by mode, the number indicates the total time span
 that is grouped into each sample.

 If you specify :option:`--show-timestamps`, this field instead shows the timestamp at
 which the sample was taken; if multiple timestamps are present in a single line
 of output, then the first timestamp is used.

device

 The device name.  If there is more than one device, then instead the number
 of devices aggregated into the line is shown, in {curly braces}.

rd_s

 The average number of reads per second.  This is the number of I/O requests that
 were sent to the underlying device.  This usually is a smaller number than the
 number of logical IO requests made by applications.  More requests might have
 been queued to the block device, but some of them usually are merged before
 being sent to the disk.

 This field is computed from the contents of */proc/diskstats* as follows.  See
 "KERNEL DOCUMENTATION" below for the meaning of the field numbers:

 .. code-block:: bash

     delta[field1] / delta[time]


rd_avkb

 The average size of the reads, in kilobytes.  This field is computed as follows:

 .. code-block:: bash

     2 * delta[field3] / delta[field1]


rd_mb_s

 The average number of megabytes read per second.  Computed as follows:

 .. code-block:: bash

     2 * delta[field3] / delta[time]


rd_mrg

 The percentage of read requests that were merged together in the queue scheduler
 before being sent to the physical device.  The field is computed as follows:

 .. code-block:: bash

     100 * delta[field2] / (delta[field2] + delta[field1])


rd_cnc

 The average concurrency of the read operations, as computed by Little's Law.
 This is the end-to-end concurrency on the block device, not the underlying
 disk's concurrency. It includes time spent in the queue.  The field is computed
 as follows:

 .. code-block:: bash

     delta[field4] / delta[time] / 1000 / devices-in-group


rd_rt

 The average response time of the read operations, in milliseconds.  This is the
 end-to-end response time, including time spent in the queue.  It is the response
 time that the application making I/O requests sees, not the response time of the
 physical disk underlying the block device.  It is computed as follows:

 .. code-block:: bash

     delta[field4] / (delta[field1] + delta[field2])


wr_s, wr_avkb, wr_mb_s, wr_mrg, wr_cnc, wr_rt

 These columns show write activity, and they match the corresponding columns for
 read activity.

busy

 The fraction of wall-clock time that the device had at least one request in
 progress; this is what iostat calls %util, and indeed it is utilization,
 depending on how you define utilization, but that is sometimes ambiguous in
 common parlance.  It may also be called the residence time; the time during
 which at least one request was resident in the system.  It is computed as
 follows:

 .. code-block:: bash

     100 * delta[field10] / (1000 * delta[time])

 This field cannot exceed 100% unless there is a rounding error, but it is a
 common mistake to think that a device that's busy all the time is saturated.  A
 device such as a RAID volume should support concurrency higher than 1, and
 solid-state drives can support very high concurrency.  Concurrency can grow
 without bound, and is a more reliable indicator of how loaded the device really
 is.

in_prg

 The number of requests that were in progress.  Unlike the read and write
 concurrencies, which are averages that are generated from reliable numbers, this
 number is an instantaneous sample, and you can see that it might represent a
 spike of requests, rather than the true long-term average.  If this number is
 large, it essentially means that the device is heavily loaded.  It is computed
 as follows:

 .. code-block:: bash

     field9


ios_s

 The average throughput of the physical device, in I/O operations per second
 (IOPS).  This column shows the total IOPS the underlying device is handling.  It
 is the sum of rd_s and wr_s.

qtime

 The average queue time; that is, time a request spends in the device scheduler
 queue before being sent to the physical device.  This is an average over reads
 and writes.

 It is computed in a slightly complex way: the average response time seen by the
 application, minus the average service time (see the description of the next
 column).  This is derived from the queueing theory formula for response time, R
 = W + S: response time = queue time + service time.  This is solved for W, of
 course, to give W = R - S.  The computation follows:

 .. code-block:: bash

     delta[field11] / (delta[field1, 2, 5, 6] + delta[field9])
        - delta[field10] / delta[field1, 2, 5, 6]

 See the description for ``stime`` for more details and cautions.

stime

 The average service time; that is, the time elapsed while the physical device
 processes the request, after the request finishes waiting in the queue.  This is
 an average over reads and writes.  It is computed from the queueing theory
 utilization formula, U = SX, solved for S.  This means that utilization divided
 by throughput gives service time:

 .. code-block:: bash

     delta[field10] / (delta[field1, 2, 5, 6])

 Note, however, that there can be some kernel bugs that cause field 9 in
 */proc/diskstats* to become negative, and this can cause field 10 to be wrong,
 thus making the service time computation not wholly trustworthy.

 Note that in the above formula we use utilization very specifically. It is a
 duration, not a percentage.

 You can compare the stime and qtime columns to see whether the response time for
 reads and writes is spent in the queue or on the physical device.  However, you
 cannot see the difference between reads and writes.  Changing the block device
 scheduler algorithm might improve queue time greatly.  The default algorithm,
 cfq, is very bad for servers, and should only be used on laptops and
 workstations that perform tasks such as working with spreadsheets and surfing
 the Internet.

If you are used to using iostat, you might wonder where you can find the same
information in :program:`mariadb-iostat`.  Here are two samples of output from both tools on
the same machine at the same time, for */dev/sda*, wrapped to fit:

.. code-block:: bash

         #ts dev rd_s rd_avkb rd_mb_s rd_mrg rd_cnc   rd_rt
    08:50:10 sda  0.0     0.0     0.0     0%    0.0     0.0
    08:50:20 sda  0.4     4.0     0.0     0%    0.0    15.5
    08:50:30 sda  2.1     4.4     0.0     0%    0.0    21.1
    08:50:40 sda  2.4     4.0     0.0     0%    0.0    15.4
    08:50:50 sda  0.1     4.0     0.0     0%    0.0    33.0

                 wr_s wr_avkb wr_mb_s wr_mrg wr_cnc   wr_rt
                  7.7    25.5     0.2    84%    0.0     0.3
                 49.6     6.8     0.3    41%    2.4    28.8
                210.1     5.6     1.1    28%    7.4    25.2
                297.1     5.4     1.6    26%   11.4    28.3
                 11.9    11.7     0.1    66%    0.2     4.9

                         busy  in_prg   io_s  qtime   stime
                           1%       0    7.7    0.1     0.2
                           6%       0   50.0   28.1     0.7
                          12%       0  212.2   24.8     0.4
                          16%       0  299.5   27.8     0.4
                           1%       0   12.0    4.7     0.3

             Dev rrqm/s  wrqm/s   r/s    w/s  rMB/s  wMB/s
    08:50:10 sda   0.00   41.40  0.00   7.70   0.00   0.19
    08:50:20 sda   0.00   34.70  0.40  49.60   0.00   0.33
    08:50:30 sda   0.00   83.30  2.10 210.10   0.01   1.15
    08:50:40 sda   0.00  105.10  2.40 297.90   0.01   1.58
    08:50:50 sda   0.00   22.50  0.10  11.10   0.00   0.13

                    avgrq-sz avgqu-sz  await  svctm  %util
                       51.01     0.02   2.04   1.25   0.96
                       13.55     2.44  48.76   1.16   5.79
                       11.15     7.45  35.10   0.55  11.76
                       10.81    11.40  37.96   0.53  15.97
                       24.07     0.17  15.60   0.87   0.97

The correspondence between the columns is not one-to-one.  In particular:

rrqm/s, wrqm/s

 These columns in iostat are replaced by rd_mrg and wr_mrg in :program:`mariadb-iostat`.

avgrq-sz

 This column is in sectors in iostat, and is a combination of reads and writes.
 The :program:`mariadb-iostat` output breaks these out separately and shows them in kB.  You
 can derive it via a weighted average of rd_avkb and wr_avkb in :program:`mariadb-iostat`, and
 then multiply by 2 to get sectors (each sector is 512 bytes).

avgqu-sz

 This column really represents concurrency at the block device scheduler.  The
 :program:`mariadb-iostat` output shows concurrency for reads and writes separately: rd_cnc
 and wr_cnc.

await

 This column is the average response time from the beginning to the end of a
 request to the block device, including queue time and service time, and is not
 shown in :program:`mariadb-iostat`.  Instead, :program:`mariadb-iostat` shows individual response times at
 the disk level for reads and writes (rd_rt and wr_rt), as well as queue time
 versus service time for reads and writes in aggregate.

svctm

 This column is the average service time at the disk, and is shown as stime in
 :program:`mariadb-iostat`.

%util

 This column is called busy in :program:`mariadb-iostat`.  Utilization is usually defined as
 the portion of time during which there was at least one active request, not as a
 percentage, which is why we chose to avoid this confusing term.

COLLECTING DATA
===============

It is straightforward to gather a sample of data for this tool.  Files should
have this format, with a timestamp line preceding each sample of statistics:

.. code-block:: bash

    TS <timestamp>
    <contents of /proc/diskstats>
    TS <timestamp>
    <contents of /proc/diskstats>
    ... et cetera

You can simply use :program:`mariadb-iostat` with :option:`--save-samples` to collect this data
for you.  If you wish to capture samples as part of some other tool, and use
:program:`mariadb-iostat` to analyze them, you can include a snippet of shell script such as
the following:

.. code-block:: bash

    INTERVAL=1
    while true; do
       sleep=$(date +%s.%N | awk "{print $INTERVAL - (\$1 % $INTERVAL)}")
       sleep $sleep
       date +"TS %s.%N %F %T" >> diskstats-samples.txt
       cat /proc/diskstats >> diskstats-samples.txt
    done

KERNEL DOCUMENTATION
====================

This documentation supplements `the official
documentation <http://www.kernel.org/doc/Documentation/iostats.txt>`_ on the
contents of */proc/diskstats*.  That documentation can sometimes be difficult
to understand for those who are not familiar with Linux kernel internals.  The
contents of */proc/diskstats* are generated by the ``diskstats_show()`` function
in the kernel source file *block/genhd.c*.

Here is a sample of */proc/diskstats* on a recent kernel.

.. code-block:: bash

    8 1 sda1 426 243 3386 2056 3 0 18 87 0 2135 2142

The fields in this sample are as follows.  The first three fields are the major
and minor device numbers (8, 1), and the device name (sda1). They are followed
by 11 fields of statistics:

1.

 The number of reads completed.  This is the number of physical reads done by the
 underlying disk, not the number of reads that applications made from the block
 device.  This means that 426 actual reads have completed successfully to the
 disk on which */dev/sda1* resides.  Reads are not counted until they complete.

2.

 The number of reads merged because they were adjacent.  In the sample, 243 reads
 were merged. This means that */dev/sda1* actually received 869 logical reads,
 but sent only 426 physical reads to the underlying physical device.

3.

 The number of sectors read successfully.  The 426 physical reads to the disk
 read 3386 sectors.  Sectors are 512 bytes, so a total of about 1.65MB have been
 read from */dev/sda1*.

4.

 The number of milliseconds spent reading.  This counts only reads that have
 completed, not reads that are in progress.  It counts the time spent from when
 requests are placed on the queue until they complete, not the time that the
 underlying disk spends servicing the requests. That is, it measures the total
 response time seen by applications, not disk response times.

5.

 Ditto for field 1, but for writes.

6.

 Ditto for field 2, but for writes.

7.

 Ditto for field 3, but for writes.

8.

 Ditto for field 4, but for writes.

9.

 The number of I/Os currently in progress, that is, they've been scheduled by the
 queue scheduler and issued to the disk (submitted to the underlying disk's
 queue), but not yet completed.  There are bugs in some kernels that cause this
 number, and thus fields 10 and 11, to be wrong sometimes.

10.

 The total number of milliseconds spent doing I/Os.  This is **not** the total
 response time seen by the applications; it is the total amount of time during
 which at least one I/O was in progress.  If one I/O is issued at time 100,
 another comes in at 101, and both of them complete at 102, then this field
 increments by 2, not 3.

11.

 This field counts the total response time of all I/Os.  In contrast to field 10,
 it counts double when two I/Os overlap.  In our previous example, this field
 would increment by 3, not 2.

OPTIONS
=======

This tool accepts additional command-line arguments.  Refer to the
"SYNOPSIS" and usage information for details.

.. option:: --columns-regex

 type: string; default: .

 Print columns that match this Perl regex.

.. option:: --config

 type: Array

 Read this comma-separated list of config files; if specified, this must be the
 first option on the command line.

.. option:: --devices-regex

 type: string

 Print devices that match this Perl regex.

.. option:: --group-by

 type: string; default: all

 Group-by mode: disk, sample, or all.  In **disk** mode, each line of output
 shows one disk device, with the statistics computed since the tool started.  In
 **sample** mode, each line of output shows one sample of statistics, with all
 disks averaged together.  In **all** mode, each line of output shows one sample
 and one disk device.

.. option:: --headers

 type: Hash; default: group,scroll

 If ``group`` is present, each sample will be separated by a blank line, unless
 the sample is only one line.  If ``scroll`` is present, the tool will print the
 headers as often as needed to prevent them from scrolling out of view. Note that
 you can press the space bar, or the enter key, to reprint headers at will.

.. option:: --help

 Show help and exit.

.. option:: --interval

 type: int; default: 1

 When in interactive mode, wait N seconds before printing to the screen.
 Also, how often the tool should sample */proc/diskstats*.

 The tool attempts to gather statistics exactly on even intervals of clock time.
 That is, if you specify a 5-second interval, it will try to capture samples at
 12:00:00, 12:00:05, and so on; it will not gather at 12:00:01, 12:00:06 and so
 forth.

 This can lead to slightly odd delays in some circumstances, because the tool
 waits one full cycle before printing out the first set of lines. (Unlike iostat
 and vmstat, :program:`mariadb-iostat` does not start with a line representing the averages
 since the computer was booted.)  Therefore, the rule has an exception to avoid
 very long delays.  Suppose you specify a 10-second interval, but you start the
 tool at 12:00:00.01.  The tool might wait until 12:00:20 to print its first
 lines of output, and in the intervening 19.99 seconds, it would appear to do
 nothing.

 To alleviate this, the tool waits until the next even interval of time to
 gather, unless more than 20% of that interval remains.  This means the tool will
 never wait more than 120% of the sampling interval to produce output, e.g if you
 start the tool at 12:00:53 with a 10-second sampling interval, then the first
 sample will be only 7 seconds long, not 10 seconds.

.. option:: --iterations

 type: int

 When in interactive mode, stop after N samples.  Run forever by default.

.. option:: --sample-time

 type: int; default: 1

 In --group-by sample mode, include N seconds of samples per group.

.. option:: --save-samples

 type: string

 File to save diskstats samples in; these can be used for later analysis.

.. option:: --show-inactive

 Show inactive devices.

.. option:: --show-timestamps

 Show a 'HH:MM:SS' timestamp in the ``#ts`` column.  If multiple timestamps are
 aggregated into one line, the first timestamp is shown.

.. option:: --version

 Show version and exit.

ENVIRONMENT
===========

The environment variable ``PTDEBUG`` enables verbose debugging output to STDERR.
To enable debugging and capture all output to a file, run the tool like:

.. code-block:: bash

    PTDEBUG=1 mariadb-iostat ... > FILE 2>&1

Be careful: debugging output is voluminous and can generate several megabytes
of output.

SYSTEM REQUIREMENTS
===================

This tool requires Perl v5.8.0 or newer and the */proc* filesystem, unless
reading from files.

AUTHORS
=======

Cole Busby,Baron Schwartz, Brian Fraser, and Daniel Nichter

ABOUT THIS MARIADB TOOL
=======================

This tool is part of MariaDB client tools. This MariaDB Tool was forked from
Percona Toolkit's pt-diskstat in August, 2019. Percona Toolkit was forked from two
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

:program:`mariadb-iostat` 6.0.2.1

