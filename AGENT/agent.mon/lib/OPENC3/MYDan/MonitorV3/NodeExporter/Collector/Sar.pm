package OPENC3::MYDan::MonitorV3::NodeExporter::Collector::Sar;
use strict;
use warnings;
use Carp;
use POSIX;
use OPENC3::MYDan::MonitorV3::NodeExporter::Collector::Sar::Table;

my %FIXME = 
(
    PAGE  => [ 'pgpgin/s', 'kbhugfree' ],
    IO    => [ 'tps' ],
    LOAD  => [ 'runq-sz', 'proc/s', 'cswch/s' ],
    MEM   => [ 'frmpg/s', 'kbmemfree' ],
    SWAP  => [ 'kbswpfree', 'pswpin/s' ],
    NFS   => [ 'call/s', 'scall/s' ],
    SOCK  => [ 'totsck' ],
    IP    => [ 'irec/s', 'ihdrerr/s' ],
    ICMP  => [ 'imsg/s', 'ierr/s' ],
    TCP   => [ 'active/s', 'atmptf/s' ],
    UDP   => [ 'idgm/s' ],
    SOCK6 => [ 'tcp6sck' ],
    IP6   => [ 'irec6/s', 'ihdrer6/s' ],
    ICMP6 => [ 'imsg6/s', 'ierr6/s' ],
    UDP6  => [ 'idgm6/s' ],
    FILE  => [ 'dentunusd' ],
);

my %EMXIF = map{ my $t = $_; map{ $_ => $t }@{$FIXME{$t}} } keys %FIXME;

our %declare = (
#    node_cpu_gnice_percent => 'Time to run virtual machines at low priority',
#    node_cpu_gnice_percent_summary => 'The time to run the virtual machine at low priority, all cores are summarized',

    node_cpu_guest_percent => 'Represents the time to run other operating systems through virtualization, that is, the CPU time to run the virtual machine.',
    node_cpu_guest_percent_summary => 'Represents the time to run other operating systems through virtualization, that is, the CPU time to run the virtual machine. all cores are summarized',

    node_cpu_idle_percent => 'CPU idle time. Note that it does not include the time to wait for I / O (iowait).',
    node_cpu_idle_percent_summary => 'CPU idle time. Note that it does not include the time to wait for I / O (iowait), all cores are summarized.',

    node_cpu_iowait_percent => 'CPU time waiting for I / O',
    node_cpu_iowait_percent_summary => 'CPU time waiting for I / O, all cores are summarized.',

    node_cpu_irq_percent => 'CPU time to process hard interrupts',
    node_cpu_irq_percent_summary => 'CPU time to process hard interrupts, all cores are summarized.',

    node_cpu_mhz => 'CPU frequency, MHZ',
    node_cpu_mhz_summary => 'CPU frequency, MHZ, all cores are summarized.',

    node_cpu_nice_percent => 'Low priority user state CPU time, that is, the CPU time when the nice value of the process is adjusted to be between 1-19.',
    node_cpu_nice_percent_summary => 'Low priority user state CPU time, that is, the CPU time when the nice value of the process is adjusted to be between 1-19, all cores are summarized.',

    node_cpu_soft_percent => 'CPU time to process soft interrupts.',
    node_cpu_soft_percent_summary => 'CPU time to process soft interrupts, all cores are summarized.',

    node_cpu_steal_percent => 'CPU time is occupied by other virtual machines when the system is running in the virtual machine.',
    node_cpu_steal_percent_summary => 'CPU time is occupied by other virtual machines when the system is running in the virtual machine, all cores are summarized.',

    node_cpu_system_percent => 'Kernel CPU time',
    node_cpu_system_percent_summary => 'Kernel CPU time, all cores are summarized.',

    node_cpu_user_percent => 'User state CPU time. Note that it does not include the following nice time, but includes the guest time.',
    node_cpu_user_percent_summary => 'User state CPU time. Note that it does not include the following nice time, but includes the guest time, all cores are summarized.',

    node_dev_avgqu_sz => 'Average I / O queue length. Delta (aveq) / S / 1000 (because aveq is in milliseconds).',
    node_dev_await => 'Average latency per device I / O operation in milliseconds. Delta (ruse + wuse) / delta (Rio + WIO)',
    node_dev_util_percent => 'What percentage of a second is spent on I / O operations, or how many times a second the I / O queue is non empty. Delta (use) / S / 1000 (because the unit of use is milliseconds)',

    node_dev_rd_sec_sec => 'The total number of sectors read per second',
    node_dev_wr_sec_sec => 'The total number of sectors written per second',

    node_file_file_nr => 'Number of file handles used by the system',
    node_file_inode_nr => 'Number of indexes used',

    node_iface_rxbyt_sec => 'Packet size accepted per second, in byte',
    node_iface_rxbyt_sec_summary => 'Packet size accepted per second, in byte, summarized.',
    node_iface_txbyt_sec => 'Packet size sent per second, in byte',
    node_iface_txbyt_sec_summary => 'Packet size sent per second, in byte, summarized.',

    node_io_bread_sec => 'The total number of blocks read from disk per second',
    node_io_bwrtn_sec => 'The total number of blocks written to this disk per second',
    node_io_tps => 'The total number of IO on the disk per second, which is equal to TPS in iostat',
    node_io_rtps => 'Total IO read from disk per second',
    node_io_wtps => 'The total number of IO writes from to disk per second',

    node_load_cswch_sec => 'Total number of context switches per second.',

    node_load_ldavg_1 => 'System load average in the last minute',
    node_load_ldavg_5 => 'Average system load in the past 5 minutes',
    node_load_ldavg_15 => 'Average system load in the past 15 minutes',

    node_load_plist_sz => 'Number of tasks in the task list.',
    node_load_proc_sec => 'Total number of tasks created per second.',
    node_load_runq_sz => 'Run queue length (number of tasks waiting for run  time).',

    node_mem_memused_percent => 'Percentage of used memory.',
    node_swap_swpused_percent => 'Percentage of used swap space.',
);

our $collectorname = 'node_sar';
our $cmd = 'LANG=en sar -A 6 1';

sub co
{
    my $data = shift;
    my ( $error, @res ) = ( 0 );
    my @data = OPENC3::MYDan::MonitorV3::NodeExporter::Collector::Sar::Table::co( $data );

    my %data;

    for ( 0 .. $#data )
    {
        my $data = shift @data;
        my $fix = $EMXIF{$data->[0][0]};

        unless( $fix ) { push @data, $data; next; }

        $data{$data->[0][0]} = $data;
    }

    for my $t ( keys %FIXME )
    {
        my @d;
        $d[0][0] = $t; $d[1][0] = 'value';   
        map{ my $i = $_; push @{$d[$i]}, map{ $data{$_} ? @{$data{$_}[$i]}: () }@{$FIXME{$t}} } 0 .. 1;

        push @data, \@d if @{$d[0]} > 1;
    }

    my %ignore = ( INTR => 1, ICMP6 => 1, ICMP => 1, IP6 => 1, IP => 1, NFS => 1, TTY => 1 );

    my %check = %declare;

    for my $data ( @data )
    {
        my $title = shift @$data;
        next if $ignore{$title->[0]};
        
        for my $row ( @$data )
        {
            for my $col ( 1 .. @$title -1 )
            {
                    my $name = lc( "node_$title->[0]_$title->[$col]" );

                    $name =~ s/%([a-z]+)/$1_percent/;
                    $name =~ s/(\/s)/_sec/g;
                    $name =~ s/-/_/g;
                    $name =~ s#i/o#io#g;
                    my $target = lc( $row->[0] );
                    my %lable = $target eq 'value' || $target eq 'all' ? () : ( lable => +{ name => $target } );
                    $name = "${name}_summary" if $target eq 'all';

                    delete $check{$name};

                    push @res, +{ name => $name, value => $row->[$col], %lable };
            }
        }
    }

    if( keys %check )
    {
        $error = 1;
        warn sprintf "sar error nofind:%s\n", join ',', keys %check;
    }

    push @res, +{ name => 'node_collector_error', value => $error, lable => +{ collector => $collectorname } };
    return @res;
}

1;
