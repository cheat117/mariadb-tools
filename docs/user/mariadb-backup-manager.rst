.. program:: mariadb-backup-manager

=================================
:program:`mariadb-backup-manager`
=================================

NAME
====

MariaDB Backup Manager - a backup-tool-agnostic backup & restore script

DESCRIPTION
===========

Backup manager is a script that supports several different backup tools and 
allows you to manage and/or schedule any of them to your liking.

Backup manager currently supports the following backup tools:

*

 mariabackup (binary backup)

*

 xtrabackup (binary backup)

*

 mydumper (logical backup)

*

 mysqldump (logical backup, either all schemas or selected schemas)

*

 binlogs (backup of binary logs)

Backup manager uses a configuration file called *mariadb-backup-manager.cnf* and located
in */etc/mariadb*. You can generate a template file (with comments) by running 
the following command:

*mariadb-backup-manager build-config*

The tool will create the config file for you, that will need to be adjusted
according to your configuration.

Backups are saved to a specific folder as indicated by the *target_directory* option.
They are normally taken by scheduling them in a dedicated crontab file in /etc/cron.d 
and can include both full and incremental levels (for binary backups). You can take 
both binary and logical backups by specifying them at different times, eg. the 
following crontab file will take a full binary backup every night at midnight, 
incrementals every hour at the half hour, and a logical backup on mondays at 5am:

0 0 * * * root /usr/local/sbin/mariadb-backup-manager backup mariabackup full

30 * * * * root /usr/local/sbin/mariadb-backup-manager backup mariabackup incr

0 5 * * 1 root /usr/local/sbin/mariadb-backup-manager backup mysqldump

0 4 * * * root /usr/local/sbin/mariadb-backup-manager purge

Backup retention is automatically handled by running the purge command nightly.
You can specify the desired retention by configuring the *purge_days* option, this will 
keep backups for the specified number of days. If you have abundant disk space for 
backups you may enable the *smart_purge* option, this will apply a smart retention 
and keep full and incremental backups for last 7 days, weekly full backups for 
last month, and monthly full backups for up to *smart_purge_months* months.

PRIVILEGES REQUIRED BY BACKUP MANAGER
=====================================

Backup manager will need to be run as root in most cases. This is especially a 
requirement when using a binary backup tool that needs to read the tablespace files.
The actual database user, however, should not be root, but a dedicated user instead,
having the following grants:

*GRANT SELECT, RELOAD, PROCESS, LOCK TABLES, REPLICATION CLIENT ON \*.\**

The password for the dedicated backup user must be specified in the configuration 
file, which should have mode 600 to avoid people on the system to be able to read it.

TAKING BACKUPS
==============

To manually perform a backup, just run:

*mariadb-backup-manager backup <backup_tool> <level>*

where *backup_tool* is one of the supported backup tools (see above) and *level* is
either ``full`` or ``incr``. Please be aware that only binary backups support incremental 
backups.

To backup binary logs for the server, just run the following

*mariadb-backup-manager backup binlogs*

The above requires that you have run at least one full backup in order to work. After 
that, it will keep track of which binlogs have been already backed up and only 
save the new ones on every invocation.

BROWSING BACKUPS
================

To browse the inventory of available backups, and see their <backup_id>,  you can run:

*mariadb-backup-manager inventory pretty* (can be abbreviated *inv pretty*)

If you omit the *pretty* option, script will show more inventory details including 
compression and encryption used by each backup, actual paths to files, etcetera.

You can see the point in time of each backup piece and binlogs related information
by running:

*mariadb-backup-manager list binlogs*

RESTORING BACKUPS
=================

To perform a restore, just run:

*mariadb-backup-manager restore <backup_id> <target_dir>*

Make sure you have enough disk space on the *target_dir* filesystem first!
These are the possible restore options:

* 	classic restore to a destination folder:
	*mariadb-backup-manager restore <backup_id> <target_dir>*

* 	performing an automatic restore test:
	*mariadb-backup-manager restore test*

* 	streaming a restore to stdout (notice the final "-"):
	*mariadb-backup-manager restore <backup_id> -*

* 	restoring to a specified point in time:
	*mariadb-backup-manager restore <backup_id> <target_dir> <point-in-time>*

This script supports performing an automatic restore test, that can be run regularly 
from crontab to ensure that the backup can actually be restored without issues; it
will create a folder, extract the backup in it, prepare it, check the successful 
completion status, and then clean up after it, freeing disk space. This is only
working for binary backups.

It is also possible to stream the (binary) backup instead of restoring to a 
*target_dir*, this can be used to stream the restore to another server via ssh.
When this option is used only the full backup is restored, even if there are available 
incrementals.  Example of streaming-restore a mariabackup:

*mariadb-backup-manager restore <backup_id> - | ssh anotherhost mbstream -x ...*

You can restore to a specific point in time if you are taking backups of binary logs.
The requested point in time can be specified either as *file:position* or as a timestamp
in the usual ``YY-MM-DD HH:MM:SS`` format (in this case, please **specify it between quotes**
to prevent the shell from eating the whitespace).

The result of a restore of a binary backup to a folder will be a prepared datadir 
that can be used to start a MariaDB server (remember to change ownership of the files
before starting). When restoring a logical backup taken with mysqldump, you need 
to pipe the output of mariadb-backup-manager to the mysql command line client using the
appropriate options. When restoring a logical backup taken with mydumper, you are 
left with a manual task due to the way this backup tool works; just use myloader 
and give *target_dir* as source directory.

Binlogs backups aren't meant to be restored individually, so you should use the
point in time restore functionality instead. However, these are stored in a compressed 
tar format and can be extracted manually if need be.

PARTIAL BACKUPS
===============

When using mysqldump as the backup tool it is possible to either dump the entire database, or 
alternatively perform a dump of selected schemas.

* to dump all schemas:
*mariadb-backup-manager backup mysqldump*

* to dump *schema1* and *schema2* only:
*mariadb-backup-manager backup mysqldump schema1,schema2*

PURGING BACKUPS
===============

To purge old backups, just run one of the following:

* to purge any expired backup based on the configured retention:
*mariadb-backup-manager purge*

* to purge the specified *backup_id* only:
*mariadb-backup-manager purge <backup_id>*

To see what would be purged by the configured retention without actually purging 
anything, you can run:

*mariadb-backup-manager purge dry-run*

LOGGING
=======

To see logfiles for a specific backup id just run the following command:

*mariadb-backup-manager logs <backup_id>*

If the backup is still running this command will automatically tail the log end, so it can 
be used to watch progress.

BUILDING A SLAVE SERVER
=======================

You can use backup manager to automatically build another slave server, including replication
setup (new slave will have same master as backup server).
The syntax is as follows:

*mariadb-backup-manager build-slave <target_server> <target_directory>*

The new slave will be build using the most recent available binary full backup.
*target_server* must be the hostname or IP address of a running server and *target_directory* 
the data directory on such server, which should be empty. Additionally, for the entire 
process to complete, the target server should already have a meaningful config file in place.

Backup manager will check if there is a private/public key equivalence set up for the root 
user between the backup server and the target server. If found, it will be used and process 
will start automatically; if not, you will be prompted for the root password for the target 
server, which will be used to set up such equivalence (so you will be asked for the password 
only once).

The backup will be streamed over ssh to the target server, prepared there, the permissions of 
the data directory will be changed, MariaDB will be started and replication will be set up
automatically. For this last thing to succeed, you need to make sure that the backup user 
has the SUPER privilege.  If the replication setup fails, backup manager is smart enough to 
stop there and ask you to fix the grants, then only this last step will need to be repeated 
without the need to stream the backup over again.

NOTIFICATIONS
=============

Backup manager can notify by email both on successful and failed backups.
If *failure_notify* is defined in configuration file, the specified email(s) will be 
notified on failures of both full and incremental backups.  If *success_notify* is defined, 
the specified email(s) will be notified on successful full backups.
*notify_label* option can be used to customize the email subject to include server details, 
should you have multiple backup servers running.

CALLING OUT URLS
================

It is possible to call external URLs before and after each backup session, eg. to disable 
monitoring of the backup server. See options *callout_url_before* and *callout_url_after* 
in configuration file.

BACKUP ENCRYPTION
=================

The script autogenerates an encryption key and exports it into the environment with the name 
"enc_key", so that it can be picked up by openssl (or whatever encryptor is chosen).
The key is saved in the inventory and automatically used when restoring the backup.

It is therefore important that the backup manager inventory (a sqlite3 database located in 
/etc/mariadb) is not accidentally deleted, otherwise your encrypted backups will instantly 
become useless.

Having the encryption key stored on same server as the encrypted backups only makes sense
if you move the backups to some external storage (eg. Amazon S3), and is not otherwise 
a secure approach.

Therefore, it is possible (and also recommended) to pass your own external encryption key 
to backup manager instead, by placing it in the environment before calling the script.  In this 
situation backup manager will not autogenerate a key, nor will it save the passed key to its 
inventory.

This feature can be used to take secure backups by invoking backup manager via ssh from another 
server, passing the encryption key via the ssh environment.

Example:

1.

 Pick a server which can reach the backup server via a ssh connection.

2.

 On this server edit */etc/ssh/sshd_config* and add *AcceptEnv=enc_key* to the configuration,
 then save the change and restart the sshd service.

3.

 Create a random key and save it to a file, eg:
 *openssl rand -base64 32 > /etc/backup.key*

4.

 Run the secure backup by connecting via ssh to the backup server:
 *enc_key=$(cat /etc/backup.key) ssh -oSendEnv=enc_key backup_server *
 */usr/local/sbin/mariadb-backup-manager backup mariabackup full*

Example of restoring an encrypted backup (assumes key is still in the above file):


 *enc_key=$(cat /etc/backup.key) ssh -oSendEnv=enc_key backup_server *
 */usr/local/sbin/mariadb-backup-manager restore <backup_id> <target_dir>*

AUTHOR
======

Rick Pizzi <rick.pizzi@mariadb.com>

ABOUT THIS MARIADB TOOL
=======================

This tool is part of MariaDB client tools.

COPYRIGHT, LICENSE, AND WARRANTY
================================

This program is copyright 2019-2022 MariaDB Corporation and/or its affiliates.
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

:program:`mariadb-backup-manager` 6.0.2.1

