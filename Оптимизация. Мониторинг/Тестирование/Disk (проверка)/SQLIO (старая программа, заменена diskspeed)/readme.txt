README file for sqlio v1.5 dated 11/17/99.

NOTE: Use of sqlio covered by the END-USER LICENSE AGREEMENT FOR 
MICROSOFT SQL SERVER I/O GENERATION PROGRAM ("SQLIO") which can be
found in the file EULA.doc that accompanies this readme.txt file.

Sqlio is a disk workload generator that is designed to simulate
some aspects of the I/O workload of Microsoft SQL Server.

The syntax of sqlio (which can be produced by executing "sqlio -?") is:

================
Usage: obj\i386\sqlio [options] [<filename>...]
        [options] may include any of the following:
        -k<R|W>                 kind of IO (R=reads, W=writes)
        -t<threads>             number of threads
        -s<secs>                number of seconds to run
        -d<drive1>..<driveN>    use same filename on each drive letter given
        -R<drive1>,,<driveN>    raw drive letters/number on which to run
        -f<stripe factor>       stripe size in blocks, random, or sequential
        -p[I]<cpu affinity>     cpu number for affinity (0 based)(I=ideal)
        -a[R[I]]<cpu mask>      cpu mask for (R=roundrobin (I=ideal)) affinity
        -o<#outstanding>        depth to use for completion routines
        -b<io size(KB)>         IO block size in KB
        -i<#IOs/run>            number of IOs per IO run
        -m<[C|S]><#sub-blks>    do multi blk IO (C=copy, S=scatter/gather)
        -L<[S|P][i|]>           latencies from (S=system, P=processor) timer
        -U[p]                   report system (p=per processor) utilization
        -B<[N|Y|H|S]>           set buffering (N=none, Y=all, H=hdwr, S=sfwr)
        -S<#blocks>             start I/Os #blocks into file
        -v1.1.1                 I/Os runs use same blocks, as in version 1.1.1
        -64                     use 64 bit memory operations
        -F<paramfile>           read parameters from <paramfile>
Defaults:
        -kR -t1 -s30 -f64 -b2 -i64 -BN testfile.dat
Maximums:
        -t (threads):                   256
        no. of files, includes -d & -R: 256
        filename length:                256

================

    Not all builds of the sqlio executable support all options listed above;
    options not supported by a particular build will not be listed in the
    output, so they may differ from those listed above.  Each build has a
    different sub-version value to indicate which options it supports:

    v1.5.64_SG - supports all options, available only for Alpha currently
    v1.5.SG - does not support -64 (64 bit), Alpha and Intel
    v1.5.0 - does not support -64 nor -mS (scatter/gather), Alpha and Intel

    A new feature in this version is the handling of ctrl-C.  Previous
    versions simply stopped the I/Os and reported nothing.  This version, upon
    ctrl-C, stops the initiation of new I/Os, waits for the completion of any
    I/Os in progress, and then prints all the normal end of execution output.
    The I/O rate will be based upon the number of I/Os completed and the actual
    duration of the run, rather than the scheduled duration.  A second ctrl-C
    will not be handled but returned so as to cause immediate termination of
    the sqlio process.

    Some options cause additional output, but the throughput is output
    at the end of a run regardless of the options, e.g.:

throughput metrics:
IOs/sec:   183.16
MBs/sec:     0.35

    This output and other metrics reported have been formatted to make
    importing (as space seperated data) into a spreadsheet easier.

    In addition to results output, sqlio outputs a version string and
    information indicating how it has interpreted the command line arguments
    before starting the workload, as well as any file size increases needed to
    match the arguments.

Important notes about options:

    Sqlio with no filename option defaults to using a file named testfile.dat
    in the current directory.

    Multiple filenames can be specified on the command line.
    The <filename> option can include raw devices, such as lettered partitions
    and numbered physical disks; to generate I/Os on a partition with letter X,
    specify X: as the filename; to generate I/Os to a physical disk numbered
    as 9, specify 9: as the filename.

    Sqlio expands a file to the required size as necessary, and creates the
    file specified if it does not exist (excluding raw devices).

    The -k option specifies the type of I/O, with either R for reads or W for
    writes following the -k.

    The -t option specifies the number of threads within the sqlio process
    that will be used to generate I/Os.

    The -s option specifies the number of seconds for sqlio to run.

    The -d option specifies one or more drive letters that will be prepended
    to the given filename (only one filename may be specified with -d).  This
    option can be used to simply specify a drive other than the current drive,
    or it can be used to specify several drives across which sqlio will execute
    IOs (all of the drives specified must have a file with the same name).
    For example, given the options -dDEF \test, sqlio will generate I/Os on the
    three files D:\test, E:\test, and F:\test.

    The -R option allows the easy specification of multiple files when the files
    are all raw (i.e., a partition letter or a driver number).  The -R option
    should be followed by a comma-separated list of the letters and/or numbers
    of the raw files to be used for I/O.  The ":" needed when specifying such
    a file as a standard filename argument is not needed when using -R.
    For example, given the option -RDEF123, sqlio will generate I/Os on
    partitions D:, E:, and F:, and disk drives 1:, 2:, and 3: (this is no
    different than specifying the files separately as D: E: F: 1: 2: 3:).

    The -f option is useful for matching IOs to stripe sets, as it specifies
    the number of blocks in between successive I/Os of sqlio.  For example,
    if using an NT software stripe of 64KB, set -f to 32 (for 2KB blocks),
    while if using a hardware stripe of 128KB, set -f to 64 (for 2KB blocks).
    Note that the strip size of sqlio is based upon both the value of the -f
    parameter and the size of the I/Os (-b block size parameter).
    Alternatively, -frandom can be specified, in which case the block within
    the file is chosen randomly across the entire file (block size aligned),
    or -fsequential can be specified, in which case the next (logical) block
    after the previous I/O on that file is chosen (last block wraps to first).
    For regular files, the existing size of the file will be used, unless a
    size field is specified in a parameter file (see -F) in which case that
    size will be used.  For raw files, a size field MUST be specified in a
    parameter file.  Note that -i option is meaningless with either -frandom
    or with -fsequential.

    The -p option sets the affinity of all the threads of a sqlio process to
    run on the cpu specified, with 0 used for the first processor, 1 for the
    second, etc.  For example, 0, 1, 2, or 3 would be valid values on a 4way
    SMP.  An optional argument, I, can be appended to the -p to enable the
    use of Ideal affinity (instead of the default behaviour of -p, which is
    Hard affinity).

    The -a option allows an affinity mask to be applied to the threads of the
    sqlio process (this differs from the -p option, which can only specify one
    specific processor for which to set the affinity).  The value used with -a
    can be decimal or hexadecimal (must be preceded by 0x).  The value will be
    applied as a processor mask to each thread of sqlio.  If the -a is followed
    by R, then round robin affinity will be used.  In this case, the mask will
    be evaluated for the number of processors it masks, say N processors.
    Then 1/Nth of the threads will be affinitized to each of the specified
    processors.  If -aR is followed by I, then Ideal affinity will be used
    instead of Hard affinity.  For example, given -a0xf -t16, all 16 threads
    of the sqlio process will be affinitized to the lower 4 processors (of,
    say, an 8 way processor).  But given -aR0xf -t16, then threads 1,5,9,13
    will affinitize to processor 0, threads 2,6,10,14 to processor 1, threads
    3,7,11,15 to processor 2, and threads 4,8,12,16 to processor 3.

    The -o option enables multiple outstanding I/Os on a single thread.  The
    value following the -o is the number, or "depth", of the outstanding I/Os.
    Instead of issuing an I/O and then waiting for it to complete (the sqlio
    default, as well as the way most read I/Os are issued in SQL Server), with
    the -o option a number of I/Os (the depth value) are started asynchronously
    by each thread with an I/O completion routine specified and then the threads
    wait (this is similar to the lazy writer of SQL Server).  The completion
    routine, called upon I/O completion, starts a successive I/O, so there will
    always be "depth" number of I/Os outstanding.  Note that EACH sqlio thread
    will issue "depth" number of I/Os for EACH file specified to sqlio.
    The -o option is not supported in conjuction with the -m (multi buffer)
    option, since NT Scatter/Gather I/O does not support completion routines.

    The -b option sets the size of the I/Os (block size), in multiples of 1KB.

    The -i option controls how many IOs there are per "IO run"; an IO run
    is the central loop of the program, during which #IOs/run IOs are made,
    with each successive IO one stripe factor further in the file; the next
    IO run will move one block over.  Each thread reads/writes against a
    different set of runs and the number of runs per thread is inversely
    proportional to the number of threads.  In combination with the -f and
    -b options, this option controls how many bytes will be touched by the
    workload, which may be of importance for caching controllers (e.g.,
    the default options of -i64 -f64 -b2 touches 8MB).  Note that -i option
    is meaningless when using either -frandom or -fsequential.

    The -m option enables multi-buffer I/O operations, with the option of
    doing either copies from/to the multiple buffers to/from the I/O buffer
    (-mC option) or doing the I/Os directly out of/into the multiple buffers
    using the new scatter/gather APIs (-mS) (these APIs are available with
    NT 4.0 SP2 or with builds of NT 5.0).  The second part of the -m option
    indicates the number of sub blocks to split the I/O transfer into;
    i.e., if the I/O block size is 16KB then specifying -mC4 will cause the
    multiple buffers to be 4KB each.  Note that for scatter/gather (-mS) that
    the sub blocks must be equal the machine's native page size (e.g., 4KB on
    i386 and 8KB on ALPHA).  The -m option is not supported in conjuction
    with the -o (overlapped I/O) option, since NT Scatter/Gather I/O does
    not support completion routines.

    The -L option enables latency timings, with the option of either using
    a system level timer (-LS) or a processor timer (-LP, which is currently
    available only on i386 builds).  Note that the -LP should be used with
    caution on an SMP machine, as the thread reading the processor timer may
    not begin and end an I/O on the same processor (unless processor affinity
    is set), which could result in erroneous timings.  Also note that though
    the -LS option is made available with the intention that it will be SMP
    safe, other users of the system level timer have found that it is also
    not reliable on SMP machines, so -LS should be used with the same
    caveats as -LP.
    When enabled, this option outputs the minimum, average, and maximum time
    to complete an I/O, and includes a histogram of latency timings, e.g.:

latency metrics:
Min_Latency(ms): 2
Avg_Latency(ms): 8
Max_Latency(ms): 47
histogram:
ms: 0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24+
%:  0  0  0  1 20  3  1  1  1  2 10 35 16  6  1  1  0  0  0  0  0  0  0  0  0

    The first row (ms) of the histogram gives buckets between 0 and 23
    milliseconds and for 24 or more milliseconds.  The second row (%) gives
    the percentage of the I/Os that completed at that column's millisecond
    latency value.  The sum of the percentages may not add up to 100 due to
    rounding.  And, as in this example, 0% may not indicate 0 I/Os that
    completed with that latency value (thus there was one (or more) 2 ms I/O
    since this is the minimum latency, but there were less than 0.5% I/Os
    that completed within 1 and 2 ms.).

    An optional argument, i, can be appended to -LS or -LP to enable
    initiation timing (i.e., the time, reported in microseconds, between
    the call to start the I/O and the completion of this call, which does not
    include the actual I/O time since these I/Os are asynchronous).  The
    resulting information is output before the overall latency, e.g.:

Min_Init_Latency(us): 51
Avg_Init_Latency(us): 296
Max_Init_Latency(us): 20169


    The -U option enables the gathering and output of system utilization time,
    broken down into DPC, Interrupt, Privileged, and User time, and overall
    Processor time, plus the total number of hardware interrupts received, as
    measured during the interval during which sqlio is generating I/Os.
    Note that Privileged time includes DPC, Interrupt, and other kernel
    time, and Processor time includes User and Privileged, excluding only
    Idle time.  If followed by p, this option also outputs per processor
    utilization as well, e.g.:

ProcessorNumber:         ALL        0        1        2        3
DPCTime(%):             22.30    24.06    21.87    19.79    23.48
InterruptTime(%):       30.19    28.64    30.78    31.87    29.47
PrivilegedTime(%):      95.35    95.05    94.94    95.93    95.46
ProcessorTime(%):       98.99    98.90    98.64    99.27    99.16
UserTime(%):             3.64     3.85     3.69     3.33     3.69
Interrupts/sec:      11608.76  2898.03  2917.36  2917.26  2876.10


    The -B option can be used to control whether the file is opened with the
    attributes FILE_FLAG_NO_BUFFERING and FILE_FLAG_WRITE_THROUGH set or not.
    Not using the option or setting it to the default (-BN) will use both
    attributes, , so that both the NTFS cache and on-board drive
    controller caches are disabled.  Setting it to -BY will not set either
    attribute, allowing both types of cache to be used.  Setting it to -BH
    will enable the disk drive's hardware cache but not the file cache (i.e.,
    only FILE_FLAG_NO_BUFFERING will be set).  Setting it to -BS will enable
    the file system's software cache but not the disk drive cache (i.e., only
    FILE_FLAG_WRITE_THROUGH will be set).  Note that not all disks have drive
    caches.  Also, SCSI controllers with battery backed caches will generally
    ignore FILE_FLAG_WRITE_THROUGH and will cache anyway, which is both safe
    and desired.

    The -S option enables the user to specify where in the file the I/O
    workload will begin by specifying the number of blocks into the file
    that will be used as the base for all the I/Os; note that blocks here
    are the same size as the blocks that will be used for the I/Os, as specified
    by -b.  The default without -S is to begin at block 0 of the file.

    The -v1.1.1 option is for backward compatibility to recreate the unintended
    way in which I/O blocks were "re-used" in version 1.1.1 of sqlio

    An error was accidentally introduced in version 1.1.1 of sqlio that is fixed
    in this version.  The error affected the way in which I/Os are, as intended
    in the way I designed sqlio, supposed to move through the portion of the
    file that sqlio is reading or writing.  In versions of sqlio before 1.1.1
    (and now in this version), the discussion "About the I/Os" below is correct,
    and sqlio touches a new "run" of blocks after completing each run until it
    finishes all the runs.  However, in 1.1.1, the runs are "re-used" over and
    over.  This error could have an affect upon how well disk or controller
    caches can keep up with the I/O workload.  For comparison purposes, this
    version can reenable the error with the -v1.1.1 flag.  Using the -D50 debug
    option shows the differences in the I/O pattern.  This error in v1.1.1 was
    introduced when an earlier version's never-used option (-n) was removed.

    The -F option allows a parameter file to be specified.  The parameter file
    gives additional flexibility in the mapping of files, threads, and affinity
    masks.  Each line of the file specified by the -F option consists of:

    <file name string> <number of threads> [<mask> [<file size (MB)] ]

    Where <mask> may be in hexadecimal (preceded by 0x) or decimal and lines
    beginning with # are ignored.  For each line in the file, a pool of
    threads will be started with the specified mask and will execute I/Os on the
    specified file. The <mask> field is optional, but must be given in order to
    specify the <file size> field.  If <mask> is absent or 0, then no affinity
    will be enforced.  The <file size> field, interpreted as MB, is optional;
    however, it can only be used if -frandom or -fsequential is specified
    (see -f).  Other options that specify affinity, file names, or thread counts
    should not be used in conjunction with this option.

    The -D option (a "hidden" option) takes an argument that should be an
    integer which controls the level of debug information (e.g., -D11 sets
    the debug to level 11 and includes levels 1 through 10):
    level 1     per thread throughput information
    level 2     details on the timer calibrations
    level 3     per thread latency information
    level 4     per thread latency histograms
    level 9     disk size checking details
    level 10    memory allocation details
    level 50    per I/O details
    level 100   causes an int3 (useful for trapping to a debugger)
    The -D50 is useful for determining whether the parameters provided
    to sqlio are generating the pattern of file accesses originally
    intended by the user (but should not be used for throughput runs;
    in addition to the considerable printing overhead, the threads
    synchronize on the printf to keep the printf's readable).

    The maximums for number of threads (-t) and number of files (which includes
    the -d option, the -R option, and any files specified as plain files) have
    are 256.


About the IOs:
    The IOs are initiated asynchronously but the IO's thread then waits
    for the IO to complete (using GetOverlappedResult), except when using the
    -o option (see -o discussion for further details).  In the case of multiple
    files specified to sqlio, an I/O is issued on each file in turn, with no
    overlap of I/Os among files for a given thread (again, -o option is an
    exception, see discussion of -o).

    To better illustrate the I/O pattern that sqlio generates and how the
    options of sqlio control this pattern, here's an example:
    Sqlio views the logical disk blocks as a two dimensional array, where
    each block's size is specified by -b (default 2KB), the blocks are numbered
    sequentially in the rows, where each row's length is specified by -f
    (default is 64) and the number of rows is specified by -i (default is 64):

    0    1    2    3    4 ........ 32 ...................  63
    64  65   66   67   68 ........ 96 ................... 127
    128 ......................... 160 ................... 191
    .........................................................
    4032 ............................................... 4095

    So in the first "I/O run" of a sqlio, the 64 blocks 0, 64, 128, ..., 4032
    are read (or written).  The sqlio moves over one block and reads the next
    64 blocks, 1, 65, etc.  This continues until the whole strip is covered,
    finishing with blocks 63, 127, 191, ..., 4095.  The next I/O run simply
    repeats this pattern again, and so on until the selected time expires.

    If there are two threads (-t2), then the first thread will run through only
    half of the strip of each row (i.e., it'll stop at blocks 31, 95, 159, etc.)
    before starting back at the beginning (0, 64, ...) while the second thread
    will start in the middle (32, 96, 160, etc.) and do the rest of the stripe
    (up to 63, 127, etc.) before starting at it's beginning again.

    In the case of multiple outstanding I/Os per thread (-o option), then each
    thread still acts the same as without -o, initiating the I/Os in the same
    order described here (the difference is that additional I/Os may still be
    completing "behind" when a given I/O is started and other I/Os may be
    started before the given I/O has completed).

    Note that setting -f1 effectively results in sequential I/O.

    The way threads split up the strip has the side effect that there has to
    be at least as large a stripe factor as the number of threads specified.
    So one limitation on sequential I/O (-f1) is that only one thread can be
    specified.  Note that specifying equal stripe (-f) and thread (-t) values
    can generate an almost sequential I/O pattern, since each thread will be
    doing I/O on only a single blocks width of the whole strip, right "next"
    to the I/Os of the other threads.  However, as the threads do not execute
    in order, the ordering of these blocks will not be truely sequential.

    As this discussion clearly shows, sqlio, in the default usage, has very
    small seeks over the disk and touches a very small portion of the disk.
    This is an aspect of sqlio that does NOT simulate the behavior of SQL
    Server on large OLTP workloads (I plan to address these issues in future
    workload generator).  In fact, sqlio can generate very high read I/O per
    disk rates because the default 128KB stripe can be buffered very well by
    current on disk buffers, and even higher rates can be achieved when caches
    on a controller are present.  Therefore, experimentation with the -i and
    -f options should be done to ensure proper results.

