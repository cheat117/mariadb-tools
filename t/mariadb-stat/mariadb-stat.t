#!/usr/bin/env perl

BEGIN {
   die "The PERCONA_TOOLKIT_BRANCH environment variable is not set.\n"
      unless $ENV{PERCONA_TOOLKIT_BRANCH} && -d $ENV{PERCONA_TOOLKIT_BRANCH};
   unshift @INC, "$ENV{PERCONA_TOOLKIT_BRANCH}/lib";
};

use strict;
use warnings FATAL => 'all';
use threads;
use English qw(-no_match_vars);
use Test::More;
use Time::HiRes qw(sleep);

use PerconaTest;
use DSNParser;
use Sandbox;

my $dp = new DSNParser(opts=>$dsn_opts);
my $sb = new Sandbox(basedir => '/tmp', DSNParser => $dp);
my $dbh = $sb->get_dbh_for('master');

if ( !$dbh ) {
   plan skip_all => 'Cannot connect to sandbox master';
}

my $cnf      = "/tmp/12345/configs/mariadb-client.cnf";
my $pid_file = "/tmp/mariadb-stat.pid.$PID";
my $log_file = "/tmp/mariadb-stat.log.$PID";
my $dest     = "/tmp/mariadb-stat.collect.$PID";
my $int_file = "/tmp/mariadb-stat-after-interval-sleep";
my $pid;

sub cleanup {
   diag(`rm $pid_file $log_file $int_file 2>/dev/null`);
   diag(`rm -rf $dest 2>/dev/null`);
}

sub wait_n_cycles {
   my ($n) = @_;
   PerconaTest::wait_until(
      sub {
         return 0 unless -f "$dest/after_interval_sleep";
         my $n_cycles = `wc -l "$dest/after_interval_sleep"  | awk '{print \$1}'`;
         $n_cycles ||= '';
         chomp($n_cycles);
         return ($n_cycles || 0) >= $n; 
      },
      1.5,
      15
   );
}

# ###########################################################################
# Test that it won't run if can't connect to MySQL.
# ###########################################################################

my $retval = system("$trunk/bin/mariadb-stat -- --no-defaults --protocol socket --socket /dev/null  >$log_file 2>&1");
my $output = `cat $log_file`;

like(
   $output,
   qr/Can't connect to local server through socket/,
   "Cannot connect to MySQL"
);

is(
   $retval >> 8,
   1,
   "Exit 1"
);

# ###########################################################################
# Test that it runs and dies normally.
# ###########################################################################

cleanup();

# As of v2.1.9 when --verbose was added, non-matching checks are not
# printed by default.  So we use the --plugin to tell us when the tool
# has completed a cycle.
$retval = system("$trunk/bin/mariadb-stat --daemonize --pid $pid_file --log $log_file --dest $dest --plugin $trunk/t/mariadb-stat/samples/plugin002.sh -- --defaults-file=$cnf");

is(
   $retval >> 8,
   0,
   "Parent exit 0"
);

PerconaTest::wait_for_files($pid_file, $log_file);
ok(
   -f $pid_file,
   "Creates PID file"
);

ok(
   -f $log_file,
   "Creates log file"
);

sleep 1;

ok(
   -d $dest,
   "Creates --dest (collect) dir"
);

chomp($pid = `cat $pid_file 2>/dev/null`);
$retval = system("kill -0 $pid");
is(
   $retval >> 0,
   0,
   "mariadb-stat is running"
);

wait_n_cycles(2);
PerconaTest::kill_program(pid_file => $pid_file);

$output = `cat $log_file 2>/dev/null`;
unlike(
   $output,
   qr/Check results: status\(Threads_running\)=\d+, matched=no, cycles_true=0/,
   "Non-matching results not logged because --verbose=2"
) or diag(`cat $log_file 2>/dev/null`, `cat $dest/*-output 2>/dev/null`);

PerconaTest::wait_until(sub { !-f $pid_file });

ok(
   ! -f $pid_file,
   "Removes PID file"
);

$output = `cat $log_file 2>/dev/null`;
like(
   $output,
   qr/Caught signal, exiting/,
   "Caught signal logged"
) or diag(`cat $log_file 2>/dev/null`, `cat $dest/*-output 2>/dev/null`);

# #############################################################################
# --verbose 3 (non-matching results)
# #############################################################################

cleanup();

$retval = system("$trunk/bin/mariadb-stat --daemonize --pid $pid_file --log $log_file --variable Threads_running --dest $dest --verbose 3 -- --defaults-file=$cnf");

PerconaTest::wait_for_files($pid_file, $log_file);
PerconaTest::wait_for_sh("grep -q 'Check results' $log_file >/dev/null");
PerconaTest::kill_program(pid_file => $pid_file);

$output = `cat $log_file 2>/dev/null`;
like(
   $output,
   qr/Check results: status\(Threads_running\)=\d+, matched=no, cycles_true=0/,
   "Matching results logged with --verbose 3"
) or diag(`cat $dest/*-output 2>/dev/null`);

# #############################################################################
# --verbose 1 (just errors and warnings)
# #############################################################################

cleanup();

$retval = system("$trunk/bin/mariadb-stat --daemonize --pid $pid_file --log $log_file --dest $dest --verbose 1 --plugin $trunk/t/mariadb-stat/samples/plugin002.sh -- --defaults-file=$cnf");

PerconaTest::wait_for_files($pid_file, $log_file);
wait_n_cycles(2);
PerconaTest::kill_program(pid_file => $pid_file);

$output = `cat $log_file 2>/dev/null`;

like(
   $output,
   qr/Caught signal, exiting/,
   "Warning logged (--verbose 1)"
);

unlike(
   $output,
   qr/Start|Collect|Check/i,
   "No run info log (--verbose 1)"
);

# ###########################################################################
# Test collect.
# ###########################################################################

cleanup();

# We'll have to watch Uptime since it's the only status var that's going
# to be predictable.
my (undef, $uptime) = $dbh->selectrow_array("SHOW STATUS LIKE 'Uptime'");
my $threshold = $uptime + 2;

$retval = system("$trunk/bin/mariadb-stat --iterations 1 --dest $dest --variable Uptime --threshold $threshold --cycles 2 --run-time 2 --pid $pid_file -- --defaults-file=$cnf >$log_file 2>&1");

PerconaTest::wait_until(sub { !-f $pid_file });

$output = `cat $dest/*-trigger 2>/dev/null`;
like(
   $output,
   qr/Check results: status\(Uptime\)=\d+, matched=yes, cycles_true=2/,
   "Collect triggered"
)
or diag(
   'output',    $output,
   'log file',  `cat $log_file 2>/dev/null`,
   'collector', `cat $dest/*-output 2>/dev/null`,
   'dest',      `ls -l $dest/ 2>/dev/null`,
   'df',        `cat $dest/*-df 2>/dev/null`,
);

# There is some nondeterminism here. Sometimes it'll run for 2 samples because
# the samples may not be precisely 1 second apart.
chomp($output = `cat $dest/*-df 2>/dev/null | grep -c '^TS'`);
ok(
   $output >= 1 && $output <= 3,
   "Collect ran for --run-time"
)
or diag(
   'output',    $output,
   'log file',  `cat $log_file 2>/dev/null`,
   'collector', `cat $dest/*-output 2>/dev/null`,
   'dest',      `ls -l $dest/ 2>/dev/null`,
   'df',        `cat $dest/*-df 2>/dev/null`,
);

ok(
   PerconaTest::not_running("mariadb-stat --iterations 1"),
   "mariadb-stat is not running"
);

$output = `cat $dest/*-trigger 2>/dev/null`;
like(
   $output,
   qr/mariadb-stat ran with --function=status --variable=Uptime --threshold=$threshold/,
   "Trigger file logs how mariadb-stat was ran"
);

chomp($output = `cat $log_file 2>/dev/null | grep 'Collect [0-9] PID'`);
like(
   $output,
   qr/Collect 1 PID \d+/,
   "Collector PID logged"
)
or diag(
   'output',    $output,
   'log file',  `cat $log_file 2>/dev/null`,
   'collector', `cat $dest/*-output 2>/dev/null`,
);

# ###########################################################################
# Triggered but --no-collect.
# ###########################################################################

cleanup();

(undef, $uptime) = $dbh->selectrow_array("SHOW STATUS LIKE 'Uptime'");
$threshold = $uptime + 2;

$retval = system("$trunk/bin/mariadb-stat --no-collect --iterations 1 --dest $dest  --variable Uptime --threshold $threshold --cycles 1 --run-time 1 --pid $pid_file -- --defaults-file=$cnf >$log_file 2>&1");

PerconaTest::wait_until(sub { !-f $pid_file });

$output = `cat $log_file 2>/dev/null`;
like(
   $output,
   qr/Collect 1 triggered/,
   "Collect triggered"
);

ok(
   ! -f "$dest/*",
   "No files collected"
) or diag(`ls -l $dest/ 2>/dev/null`);

ok(
   PerconaTest::not_running("mariadb-stat --no-collect"),
   "mariadb-stat is not running"
);

# #############################################################################
# --config
# #############################################################################

cleanup();

diag(`cp $ENV{HOME}/.mariadb-stat.conf $ENV{HOME}/.mariadb-stat.conf.original 2>/dev/null`);
diag(`cp $trunk/t/mariadb-stat/samples/config001.conf $ENV{HOME}/.mariadb-stat.conf`);

system "$trunk/bin/mariadb-stat --dest $dest --pid $pid_file >$log_file 2>&1 &";
PerconaTest::wait_for_files($pid_file);
sleep 1;
chomp($pid = `cat $pid_file`);
$retval = system("kill $pid 2>/dev/null");
is(
   $retval >> 0,
   0,
   "Killed mariadb-stat"
);

$output = `cat $log_file 2>/dev/null`;
like(
   $output,
   qr/Check results: status\(Aborted_connects\)=|variable=Aborted_connects/,
   "Read default config file"
);

diag(`rm $ENV{HOME}/.mariadb-stat.conf`);
diag(`cp $ENV{HOME}/.mariadb-stat.conf.original $ENV{HOME}/.mariadb-stat.conf 2>/dev/null`);

# #############################################################################
# Don't stalk, just collect.
# #############################################################################

cleanup();

# As of 2.2, --no-stalk means just that: don't stalk, just collect, so
# we have to specify --iterations=1 else the tool will continue to run,
# whereas in 2.1 --no-stalk implied/forced "collect once and exit".

$retval = system("$trunk/bin/mariadb-stat --no-stalk --run-time 2 --dest $dest --prefix nostalk --pid $pid_file --iterations 1 -- --defaults-file=$cnf >$log_file 2>&1");

PerconaTest::wait_until(sub { !-f $pid_file });

$output = `cat $dest/nostalk-trigger 2>/dev/null`;
like(
   $output,
   qr/Not stalking/,
   "Not stalking, collect triggered"
)
or diag(
   'dest',      `ls -l $dest/ 2>/dev/null`,
   'log_file',  `cat $log_file 2>/dev/null`,
   'collector', `cat $dest/*-output 2>/dev/null`,
);

chomp($output = `grep -c '^TS' $dest/nostalk-df 2>/dev/null`);
is(
   $output,
   2,
   "Not stalking, collect ran for --run-time"
)
or diag(
   'dest',      `ls -l $dest/ 2>/dev/null`,
   'log_file',  `cat $log_file 2>/dev/null`,
   'collector', `cat $dest/*-output 2>/dev/null`,
);

my $vmstat = `which vmstat 2>/dev/null`;
SKIP: {
   skip "vmstat is not installed", 1 unless $vmstat;
   chomp(my $n=`awk '/[ ]*[0-9]/ { n += 1 } END { print n }' "$dest/nostalk-vmstat"`);
   is(
      $n,
      "2",
      "vmstat ran for --run-time seconds (bug 955860)"
   );
};

is(
   `cat $dest/nostalk-hostname 2>/dev/null`,
   `hostname`,
   "Not stalking, collect gathered data"
)
or diag(
   'dest',      `ls -l $dest/ 2>/dev/null`,
   'log_file',  `cat $log_file 2>/dev/null`,
   'collector', `cat $dest/*-output 2>/dev/null`,
);

ok(
   PerconaTest::not_running("mariadb-stat --no-stalk"),
   "Not stalking, mariadb-stat is not running"
)
or diag(
   'dest',      `ls -l $dest/ 2>/dev/null`,
   'log_file',  `cat $log_file 2>/dev/null`,
   'collector', `cat $dest/*-output 2>/dev/null`,
);

# ############################################################################
# bad "find" usage in purge_samples gives 
# https://bugs.launchpad.net/percona-toolkit/+bug/942114
# ############################################################################

use File::Temp qw( tempdir );

my $tempdir = tempdir( CLEANUP => 1 );

my $script = <<"EOT";
. $trunk/bin/mariadb-stat
purge_samples $tempdir 10000 2>&1
EOT

$output = `$script`;

unlike(
   $output,
   qr/\Qfind: warning: you have specified the -depth option/,
   "Bug 942114: no bad find usage"
);


# ###########################################################################
# Test that it handles floating point values 
# ###########################################################################

cleanup();

system("$trunk/bin/mariadb-stat --daemonize  --variable=PI --dest $dest  --no-collect --log $log_file --iterations=1  --run-time=2  --cycles=2  --sleep=1 --function $trunk/t/mariadb-stat/samples/plugin003.sh --threshold 3.1415  --pid $pid_file --defaults-file=$cnf >$log_file 2>&1");


sleep 5;
PerconaTest::kill_program(pid_file => $pid_file);

$output = `cat $log_file 2>/dev/null`;
like(
   $output,
   qr/matched=yes/,
   "Accepts floating point values as treshold variable"
);
          
# ###########################################################################
# Test report about performance schema transactions in MySQL 5.7+
# ###########################################################################

cleanup();

SKIP: {

   skip "Only test on mysql 5.7" if ( $sandbox_version lt '5.7' );

   sub start_thread {
      # this must run in a thread because we need to have an uncommitted transaction
      my ($dsn_opts) = @_;
      my $dp = new DSNParser(opts=>$dsn_opts);
      my $sb = new Sandbox(basedir => '/tmp', DSNParser => $dp);
      my $dbh = $sb->get_dbh_for('master');
      $sb->load_file('master', "t/mariadb-stat/samples/issue-1642751.sql");
   }
   my $thr = threads->create('start_thread', $dsn_opts);
   $thr->detach();
   threads->yield();
   
   my $cmd = "$trunk/bin/mariadb-stat --no-stalk --iterations=1 --host=127.0.0.1 --port=12345 --user=msandbox "
           . "--password=msandbox --sleep 0 --run-time=10 --dest $dest --log $log_file --iterations=1  "
           . "--run-time=2  --pid $pid_file --defaults-file=$cnf >$log_file 2>&1";
   system($cmd);
   sleep 15;
   PerconaTest::kill_program(pid_file => $pid_file);
   
   $output = `cat $dest/*-ps-locks-transactions 2>/dev/null`;

   like(
      $output,
      qr/ STATE: ACTIVE/,
      "MySQL 5.7 ACTIVE transactions"
   );
          
   like(
      $output,
      qr/ STATE: COMMITTED/,
      "MySQL 5.7 COMMITTED transactions"
   );
   
   cleanup();
}

SKIP: {

   skip "Only test on mysql 5.7" if ( $sandbox_version lt '5.7' );

   my ($master1_dbh, $master1_dsn) = $sb->start_sandbox(
      server => 'chan_master1',
      type   => 'master',
   );
   my ($master2_dbh, $master2_dsn) = $sb->start_sandbox(
      server => 'chan_master2',
      type   => 'master',
   );
   my ($slave1_dbh, $slave1_dsn) = $sb->start_sandbox(
      server => 'chan_slave1',
      type   => 'master',
   );
   my $slave1_port = $sb->port_for('chan_slave1');
   
   $sb->load_file('chan_master1', "sandbox/gtid_on.sql", undef, no_wait => 1);
   $sb->load_file('chan_master2', "sandbox/gtid_on.sql", undef, no_wait => 1);
   $sb->load_file('chan_slave1', "sandbox/slave_channels_t.sql", undef, no_wait => 1);

   my $slave_cnf = "/tmp/$slave1_port/my.sandbox.cnf";
   my $cmd = "$trunk/bin/mariadb-stat --no-stalk --iterations=1 --host=127.0.0.1 --port=$slave1_port --user=msandbox "
           . "--password=msandbox --sleep 0 --run-time=10 --dest $dest --log $log_file --iterations=1  "
           . "--run-time=2 --pid $pid_file --defaults-file=$slave_cnf >$log_file 2>&1";
   diag ($cmd);
   system($cmd);
   sleep 5;
   PerconaTest::kill_program(pid_file => $pid_file);
   
   $output = `cat $dest/*-slave-status 2>/dev/null`;
   
   like(
      $output,
      qr/Slave has read all relay log; waiting for more updates/,
      "MySQL 5.7 SLAVE STATUS"
   ) or diag ($output);
   $sb->stop_sandbox(qw(chan_master1 chan_master2 chan_slave1));
}
                                                                              
SKIP: {
   skip "Only test on mysql 5.6" if ( $sandbox_version ne '5.6' );

   my $slave1_port = $sb->port_for('slave1');
   my $cmd = "$trunk/bin/mariadb-stat --no-stalk --iterations=1 --host=127.0.0.1 --port=$slave1_port --user=msandbox "
           . "--password=msandbox --sleep 0 --run-time=10 --dest $dest --log $log_file --iterations=1  "
           . "--run-time=2  --pid $pid_file --defaults-file=$cnf >$log_file 2>&1";
   system($cmd);                                                                 
   sleep 5;                                                                      
   PerconaTest::kill_program(pid_file => $pid_file);                             
                                                                                 
   $output = `cat $dest/*-slave-status 2>/dev/null`;                             
                                                                                 
   like(                                                                     
      $output,                                                               
      qr/SHOW SLAVE STATUS/,                                                 
      "MySQL 5.6 SLAVE STATUS"                                               
   );
}

# ###########################################################################
# Test report about performance schema prepared_statements_instances in MySQL 5.7+
# ###########################################################################

cleanup();

SKIP: {

   skip "Only test on MySQL 5.7" if ( $sandbox_version lt '5.7' );

   sub start_thread_1642750 {
      # this must run in a thread because we need to have an active session
      # with prepared statements
      my ($dsn_opts) = @_;
      my $dp = new DSNParser(opts=>$dsn_opts);
      my $sb = new Sandbox(basedir => '/tmp', DSNParser => $dp);
      my $dbh = $sb->get_dbh_for('master');
      $sb->load_file('master', "t/mariadb-stat/samples/issue-1642750.sql");
   }
   my $thr = threads->create('start_thread_1642750', $dsn_opts);
   $thr->detach();
   threads->yield();

   my $cmd = "$trunk/bin/mariadb-stat --no-stalk --iterations=1 --host=127.0.0.1 --port=12345 --user=msandbox "
           . "--password=msandbox --sleep 0 --run-time=10 --dest $dest --log $log_file --pid $pid_file  "
           . "--defaults-file=$cnf >$log_file 2>&1";

   system($cmd);
   sleep 15;
   PerconaTest::kill_program(pid_file => $pid_file);

   $output = `cat $dest/*-prepared-statements 2>/dev/null`;
   like(
      $output,
      qr/ STATEMENT_NAME: rand_statement/,
      "MySQL 5.7 prepared statement: rand_statement"
   );

   like(
      $output,
      qr/ STATEMENT_NAME: abs_statement/,
      "MySQL 5.7 prepared statement: abs_statement"
   );
}

# #############################################################################
# Done.
# #############################################################################


cleanup();
diag(`rm -rf $dest 2>/dev/null`);
ok($sb->ok(), "Sandbox servers") or BAIL_OUT(__FILE__ . " broke the sandbox");
done_testing;
