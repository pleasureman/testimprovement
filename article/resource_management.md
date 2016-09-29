#docker资源管理探秘--docker背后的内核cgroup机制
##1.docker资源管理简介
待补充
##2.cgroup子系统介绍
待补充
##3.docker资源管理接口简介
| 选项                     |  描述                                                                                                                                    |
| -------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| `-m`, `--memory=""`        | 内存使用限制 (格式: `<数字>[<单位>]`)。 数字需要使用整数，对应的单位是`b`, `k`, `m`, `g`中的一个。最小取值是4M。              |
| `--memory-swap=""`         | 总内存使用限制 (物理内存 + 交换分区, 格式: `<数字>[<单位>]`)数字需要使用整数，对应的单位是`b`, `k`, `m`, `g`中的一个。         |
| `--memory-reservation=""`  | 内存软限制 (格式: `<数字>[<单位>]`)。 数字需要使用正整数，对应的单位是`b`, `k`, `m`, `g`中的一个。                         |
| `--kernel-memory=""`       | 内核内存限制 (格式: `<数字>[<单位>]`)。 数字需要使用正整数，对应的单位是`b`, `k`, `m`, `g`中的一个。最小取值是4M。       |
| `-c`, `--cpu-shares=0`     | CPU份额 (相对权重)                                                                                                                    |
| `--cpu-period=0`           | 完全公平算法中的period值                                                                                            |
| `--cpuset-cpus=""`         | 限制容器使用的cpu核(0-3, 0,1)                                                                                                     |
| `--cpuset-mems=""`         | 限制容器使用的内存节点，该限制仅仅在NUMA系统中生效。                                                     |
| `--cpu-quota=0`            | 完全公平算法中的quota值                                                                                             |
| `--blkio-weight=0`         | 块设备IO相对权重，取值在10值1000之间的整数（包含10和1000）                                                                   |
| `--blkio-weight-device=""` | 指定的块设备的IO相对权重(格式: `设备名称:权重值`)                                                                          |
| `--device-read-bps=""`     | 限制对某个设备的读取速率 (格式: `<设备路径>:<数字>[<单位>]`)，数字需要使用正整数，单位是`kb`, `mb`, or `gb`中的一个。 |
| `--device-write-bps=""`    | 限制对某个设备的写速率 (格式: `<设备路径>:<数字>[<单位>]`)，数字需要使用正整数，单位是`kb`, `mb`, or `gb`中的一个。 |
| `--device-read-iops="" `   | 限制对某个设备每秒IO的读取速率(格式: `<设备路径>:<数字>`)，数字需要使用正整数。                                 |
| `--device-write-iops="" `  | 限制对某个设备每秒IO的写速率(格式: `<设备路径>:<数字>`)，数字需要使用正整数。                                  |
| `--oom-kill-disable=false` | 内存耗尽时是否杀掉容器                                                                                         |
| `--memory-swappiness=""`   | 调节容器内存使用交换分区的选项，取值为0和100之间的整数(含0和100)。                                                            |


##4.docker资源管理接口详解
###(1)-m, --memory=""
可以限制容器使用的内存量，对应的cgroup文件是cgroup/memory/memory.limit_in_bytes。<br>
取值范围:大于等于4M<br>
单位：b,k,m,g<br>

在默认情况下，容器可以占用无限量的内存，直至主机内存资源耗尽。
运行如下命令来确认容器内存的资源管理对应的cgroup文件。

    $ docker run -it --memory 100M ubuntu:14.04 bash -c "cat /sys/fs/cgroup/memory/memory.limit_in_bytes"
    104857600

可以看到，当内存限定为100M时，对应的cgroup文件数值为104857600，该数值的单位为kB，即104857600kB等于100M。

本机内存环境为：

    $ free
              total        used        free      shared  buff/cache   available
    Mem:        4050284      254668     3007564      180484      788052     3560532
    Swap:             0           0           0

值得注意的是本机目前没有配置交换分区(swap)。

我们使用stress工具来证明内存限定已经生效。stress是一个压力测试套，如下命令将要在容器内创建一个进程，在该进程中不断的执行占用内存(malloc)和释放内存(free)的操作。在理论上如果占用的内存少于限定值，容器会工作正常。注意，如果试图使用边界值，即试图在容器中使用stress工具占用100M内存，这个操作通常会失败，因为容器中还有其他进程在运行。

    $ docker run -ti -m 100M ubuntu:memory stress --vm 1 --vm-bytes 50M
    stress: info: [1] dispatching hogs: 0 cpu, 0 io, 1 vm, 0 hdd

当在限定内存为100M的容器中，试图占用50M的内存时，容器工作正常。
如下所示，当试图占用超过100M内存时，必然导致容器异常。

    $ docker run -ti -m 100m ubuntu:memory stress --vm 1 --vm-bytes 101M
    stress: info: [1] dispatching hogs: 0 cpu, 0 io, 1 vm, 0 hdd
    stress: FAIL: [1] (416) <-- worker 6 got signal 9
    stress: WARN: [1] (418) now reaping child worker processes
    stress: FAIL: [1] (422) kill error: No such process
    stress: FAIL: [1] (452) failed run completed in 0s

注意这种情况是在系统无交换分区(swap)的情况下出现的，如果我们添加了交换分区，情况又会怎样？首先通过如下命令来添加交换分区(swap)。

    $ dd if=/dev/zero of=/tmp/mem.swap bs=1M count=8192
    8192+0 records in
    8192+0 records out
    8589934592 bytes (8.6 GB) copied, 35.2693 s, 244 MB/s
    $ mkswap /tmp/mem.swap
    Setting up swapspace version 1, size = 8388604 KiB
    no label, UUID=55ea48e9-553d-4013-a2ae-df194f7941ed
    $ sudo swapon /tmp/mem.swap 
    swapon: /tmp/mem.swap: insecure permissions 0664, 0600 suggested.
    swapon: /tmp/mem.swap: insecure file owner 1100, 0 (root) suggested.
    $ free -m
                  total        used        free      shared  buff/cache   available
    Mem:           3955         262          28         176        3665        3463
    Swap:          8191           0        8191

之后再次尝试占用大于限定的内存。

    $ docker run -ti -m 100m ubuntu:14.04 stress --vm 1 --vm-bytes 101M
    stress: info: [1] dispatching hogs: 0 cpu, 0 io, 1 vm, 0 hdd

在加入交换分区后容器工作正常，这意味着有部分存储在内存中的信息被转移到了交换分区中了。
注意，在实际容器使用场景中，如果我不不对容器使用内存量加以限制的话，可以能导致一个容器会耗尽整个主机内存，从而导致系统不稳定。所以在使用容器时务必对容器内存加以限制。

###(2)--memory-swap=""
可以限制容器使用交换分区和内存的总和，对应的cgroup文件是cgroup/memory/memory.memsw.limit_in_bytes。<br>
取值范围:大于内存限定值<br>
单位：b,k,m,g<br>

运行如下命令来确认容器交换分区的资源管理对应的cgroup文件。

    $ docker run -ti -m 300M --memory-swap 1G ubuntu:14.04 bash -c "cat /sys/fs/cgroup/memory/memory.memsw.limit_in_bytes"
    1073741824

可以看到，当memory-swap限定为1G时，对应的cgroup文件数值为1073741824，该数值的单位为kB，即1073741824kB等于1G。


<table>
  <thead>
    <tr>
      <th>条件</th>
      <th>结果</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td class="no-wrap">
          <strong>memory=无穷大, memory-swap=无穷大</strong> (默认条件下)
      </td>
      <td>
        系统不限定容器对内存和交换分区的使用量，容器能够使用主机所能提供的所有内存。
      </td>
    </tr>
    <tr>
      <td class="no-wrap"><strong>memory=L&lt;无穷大, memory-swap=无穷大</strong></td>
      <td>
        (设定memory限定值同时将memory-swap设置为<code>-1</code>) 容器的内存使用量不能超过L，但是交换分区的使用量不受限制(前提是主机支持交换分区)。
      </td>
    </tr>
    <tr>
      <td class="no-wrap"><strong>memory=L&lt;无穷大, memory-swap=2*L</strong></td>
      <td>
        (设定memory限定值而不设置memory-swap值) 容器的内存使用量不能超过L，而内存使用量和交换分区的使用量不能超过两倍的L。
      </td>
    </tr>
    <tr>
      <td class="no-wrap">
          <strong>memory=L&lt;无穷大, memory-swap=S&lt;无穷大, L&lt;=S</strong>
      </td>
      <td>
        (设定了memory和memory-swap的限定值) 容器的内存使用量不能超过L，而内存使用量和交换分区的使用量不能超过两倍的S。
      </td>
    </tr>
  </tbody>
</table>

列子：
以下命令没有对内存和交换分区进行限制，这意味着容器可以使用无限多的内存和交换分区。

    $ docker run -it ubuntu:14.04 bash -c "cat /sys/fs/cgroup/memory/memory.limit_in_bytes && cat /sys/fs/cgroup/memory/memory.memsw.limit_in_bytes" 
    9223372036854771712
    9223372036854771712
    
以下命令只限定了内存使用量300M，而没有限制交换分区使用量(-1意味着不做限制)。

    $ docker run -it -m 300M --memory-swap -1 ubuntu:14.04 bash -c "cat /sys/fs/cgroup/memory/memory.limit_in_bytes && cat /sys/fs/cgroup/memory/memory.memsw.limit_in_bytes"
    314572800
    9223372036854771712
    
以下命令仅仅限定了内存使用量，这意味着容器能够使用300M的内存和300M的交换分区。在默认情况下，总的内存限定值(内存+交换分区)被设置为了内存限定值的两倍。

    $ docker run -it -m 300M ubuntu:14.04 bash -c "cat /sys/fs/cgroup/memory/memory.limit_in_bytes && cat /sys/fs/cgroup/memory/memory.memsw.limit_in_bytes"
    314572800
    629145600

以下命令限定了内存和交换分区的使用量，容器可以使用300M的内存和700M的交换分区。

    $ docker run -it -m 300M --memory-swap 1G ubuntu:14.04 bash -c "cat /sys/fs/cgroup/memory/memory.limit_in_bytes && cat /sys/fs/cgroup/memory/memory.memsw.limit_in_bytes"
    314572800
    1073741824

当memory-swap限定值低于memory限定值时，系统提示"Minimum memoryswap limit should be larger than memory limit"错误。

    $ docker run -it -m 300M --memory-swap 200M ubuntu:14.04 bash -c "cat /sys/fs/cgroup/memory/memory.limit_in_bytes && cat     /sys/fs/cgroup/memory/memory.memsw.limit_in_bytes"
    docker: Error response from daemon: Minimum memoryswap limit should be larger than memory limit, see usage..
    See 'docker run --help'.

如下所示，当尝试占用的内存数量超过memory-swap值时，容器出现异常；当占用内存值大于memory限定值但小于memory-swap时，容器运行正常。

    $ docker run -ti -m 100m --memory-swap 200m ubuntu:14.04 stress --vm 1 --vm-bytes 201M
    stress: info: [1] dispatching hogs: 0 cpu, 0 io, 1 vm, 0 hdd
    stress: FAIL: [1] (416) <-- worker 7 got signal 9
    stress: WARN: [1] (418) now reaping child worker processes
    stress: FAIL: [1] (422) kill error: No such process
    stress: FAIL: [1] (452) failed run completed in 0s
    [unicorn@unicorn ~]$ docker run -ti -m 100m --memory-swap 200m ubuntu:memory stress --vm 1 --vm-bytes 180M
    stress: info: [1] dispatching hogs: 0 cpu, 0 io, 1 vm, 0 hdd
    
###(3)--memory-reservation=""
取值范围:大于等于0的整数<br>
单位：b,k,m,g<br>
对应的cgroup文件是cgroup/memory/memory.soft_limit_in_bytes

    $ docker run -ti --memory-reservation 50M ubuntu:14.04 bash -c "cat /sys/fs/cgroup/memory/memory.soft_limit_in_bytes"
    52428800

通常情况下，容器能够使用的内存量仅仅由-m/--memory选项限定。如果设置了--memory-reservation选项，当内存使用量超过--memory-reservation选项所设定的值时，系统会强制容器执行回收内存的操作，使得容器内存消耗不会长时间超过--memory-reservation限定值。

这个限制并不会阻止进程使用超过限额的内存，只是在系统内存不足时，会回收部分内存，使内存使用量向限定值靠拢。
在以下命令中，容器对内存的使用量不会超过500M，这是硬性限制。当内存使用量大于200M而小于500M时，系统会尝试回收部分内存，使得内存使用量低于200M。

    $ docker run -it -m 500M --memory-reservation 200M ubuntu:14.04 bash
    
在如下命令中，容器使用的内存量不受限制，但容器消耗的内存量不会长时间超过1G，因为当容器使用量超过1G时，系统会尝试回收内存使内存使用量低于1G。

    $ docker run -it --memory-reservation 1G ubuntu:14.04 bash
    


###(4)--kernel-memory=""
该接口限制了容器对内核内存的使用，对应的cgroup文件cgroup/memory/memory.kmem.limit_in_bytes

    $ docker run -ti --kernel-memory 50M ubuntu:14.04 bash -c "cat /sys/fs/cgroup/memory/memory.kmem.limit_in_bytes"
    52428800

如下命令可以限定容器最多可以使用500M的内存。在500M内存中，内核内存最多可以使用50M。

    $ docker run -it -m 500M --kernel-memory 50M ubuntu:14.04 bash
    
如下命令可以限定容器最多可以使用50M的内核内存，而用户空间的内存使用量不受限制。

    $ docker run -it --kernel-memory 50M ubuntu:14.04 bash

###(5)-c, --cpu-shares=0
对应的cgroup文件是cgroup/cpu/cpu.shares<br>

    $ docker run --rm --cpu-shares 1600 ubuntu:14.04 bash -c "cat /sys/fs/cgroup/cpu/cpu.shares"
    1600

通过--cpu-shares可以设置容器使用CPU的权重，这个权重设置是针对cpu密集型的进程的。如果某个容器中的进程是空闲状态，那么其他容器就能够使用本该由空闲容器占用的cpu资源。也就是说，只有当两个或多个容器都试图占用整个cpu资源时，--cpu-shares设置才会有效。
我们使用如下命令来创建两个容器，它们的权重分别为1024和512。

    $ docker run -ti --cpu-shares 1024 ubuntu:14.04 stress -c 2
    stress: info: [1] dispatching hogs: 2 cpu, 0 io, 0 vm, 0 hdd

    $ docker run -ti --cpu-shares 512 ubuntu:14.04 stress -c 2
    stress: info: [1] dispatching hogs: 2 cpu, 0 io, 0 vm, 0 hdd

待补充：需要将 -c 2改为 -c 1
从如下log可以看到，每个容器会产生两个相关的进程，第一个容器产生的两个进程PID分别为25534和25533。CPU占用率分别是66.7%和66.3%，第二个容器产生的两个进程PID分别为25496和25497，两个进程的CPU占用率均为33.3%。第一个容器产生的两个进程CPU的占用率和第二个容器产生的两个进程CPU的占用率约为2:1的关系，测试结果与预期结果相符。

    top - 07:46:43 up 2 days, 23:44,  1 user,  load average: 3.84, 1.95, 0.83
    Tasks: 119 total,   5 running, 114 sleeping,   0 stopped,   0 zombie
    %Cpu(s): 98.3 us,  0.8 sy,  0.0 ni,  0.0 id,  0.0 wa,  0.0 hi,  0.8 si,  0.0 st
    KiB Mem :  4050284 total,   500276 free,   480636 used,  3069372 buff/cache
    KiB Swap:  8388604 total,  8246648 free,   141956 used.  3400212 avail Mem 
    PID USER      PR  NI    VIRT    RES    SHR S  %CPU %MEM     TIME+ COMMAND                                          
    25534 root      20   0    7312     92      0 R  66.7  0.0   1:46.55 stress                                           
    25533 root      20   0    7312     92      0 R  66.3  0.0   1:46.04 stress                                           
    25496 root      20   0    7312     96      0 R  33.3  0.0   0:56.42 stress                                           
    25497 root      20   0    7312     96      0 R  33.3  0.0   0:56.67 stress

###(6)--cpu-period=""
内核默认的linux 调度CFS（完全公平调度器）周期为100ms,我们通过--cpu-period来设置容器对CPU的使用周期，同时--cpu-period接口需要和--cpu-quota接口一起来使用。--cpu-quota接口设置了CPU的使用值。当--cpu-quota的值为0，容器对cpu的使用率为100%，CFS(完全公平调度器) 是内核默认使用的调度方式，为运行的进程分配CPU资源。对于多核CPU，根据需要调整--cpu-quota。

对应的cgroup文件是cgroup/cpu/cpu.cfs_period_us。以下命令创建了一个容器，同时设置了该容器对cpu的使用时间为50000（单位为微秒），并验证了该接口对应的cgroup文件对应的值。

    $ docker run -ti --cpu-period 50000 ubuntu:14.04 bash -c "cat /sys/fs/cgroup/cpu/cpu.cfs_period_us"
    50000

--cpu-period和--cpu-quota两个接口需要一起使用，以下容器设置了--cpu-period值为50000,--cpu-quota的值为25000。该容器在运行时可以获取50%的cpu资源。

    $ docker run -ti --cpu-period=50000 --cpu-quota=25000 ubuntu:14.04 stress -c 1
    stress: info: [1] dispatching hogs: 1 cpu, 0 io, 0 vm, 0 hdd

从log的最后一行中可以看出，该容器的cpu使用率为50.0%。

    top - 10:36:55 up 6 min,  0 users,  load average: 0.49, 0.21, 0.10
    Tasks:  68 total,   2 running,  66 sleeping,   0 stopped,   0 zombie
    %Cpu(s): 49.3 us,  0.0 sy,  0.0 ni, 50.7 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
    KiB Mem :  4050748 total,  3063952 free,   124280 used,   862516 buff/cache
    KiB Swap:        0 total,        0 free,        0 used.  3728860 avail Mem 
    PID USER      PR  NI    VIRT    RES    SHR S %CPU %MEM     TIME+ COMMAND                                           
    770 root      20   0    7312     96      0 R 50.0  0.0   0:38.06 stress

  
###(7)--cpuset-cpus=""
待补充，补充步骤并注明执行top命令后按数字键1
对应的cgroup文件是cgroup/cpuset/cpuset.cpus

在多核CPU的虚拟机中，启动一个容器，设置容器只使用cpu核1，并查看该接口对应的cgroup文件会被修改为1，log如下所示。

    $ docker run -ti --cpuset-cpus 1 ubuntu:14.04 bash -c "cat /sys/fs/cgroup/cpuset/cpuset.cpus"
    1

通过以下命令指定容器使用cpu核1，并通过stress命令加压。

    $ docker run -tid --name cpu2 --cpuset-cpus 1 ubuntu:14.04 stress -c 1

    $ top
    top - 11:31:47 up 5 days, 21:00,  0 users,  load average: 0.62, 0.82, 0.77
    Tasks: 104 total,   3 running, 101 sleeping,   0 stopped,   0 zombie
    %Cpu0  :  0.0 us,  0.0 sy,  0.0 ni, 99.6 id,  0.0 wa,  0.0 hi,  0.4 si,  0.0 st
    %Cpu1  :100.0 us,  0.0 sy,  0.0 ni,  0.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
    %Cpu2  :  0.3 us,  0.3 sy,  0.0 ni, 99.3 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
    %Cpu3  :  0.0 us,  0.0 sy,  0.0 ni,100.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
    KiB Mem :  2051888 total,  1130220 free,   127972 used,   793696 buff/cache
    KiB Swap: 33554416 total, 33351848 free,   202568 used.  1739888 avail Mem 

    PID USER      PR  NI    VIRT    RES    SHR S  %CPU %MEM     TIME+ COMMAND
    10266 root      20   0    7312     96      0 R 100.0  0.0   0:11.92 stress

从以上log得知，只有cpu核1的负载为100%，而其它cpu核处于空闲状态，结果与预期结果相符。

###(8)--cpuset-mems=""
该接口对应的cgroup文件是cgroup/cpuset/cpuset.mems

    $ docker run -ti --cpuset-mems=0 ubuntu:14.04 bash -c "cat /sys/fs/cgroup/cpuset/cpuset.mems"
    0

以下命令将限制容器进程使用内存节点1、3的内存。

    $ docker run -it --cpuset-mems="1,3" ubuntu:14.04 bash
    
以下命令将限制容器进程使用内存节点0、1、2的内存。

    $ docker run -it --cpuset-mems="0-2" ubuntu:14.04 bash

###(9)--cpu-quota=0
对应的cgroup文件是cgroup/cpu/cpu.cfs_quota_us

    $ docker run --rm --cpu-quota 1600 ubuntu:14.04 bash -c "cat /sys/fs/cgroup/cpu/cpu.cfs_quota_us"
    1600

--cpu-quota接口设置了CPU的使用值，通常情况下它需要和--cpu-period接口一起来使用。具体使用方法请参考--cpu-period选项。

###(10)--blkio-weight=0
通过--blkio-weight接口可以设置容器块设备IO的权重，有效值范围为10至1000的整数(包含10和1000)。默认情况下，所有容器都会得到相同的权重值(500)。对应的cgroup文件为cgroup/blkio/blkio.weight。以下命令设置了容器块设备IO权重设置为10，在log中可以看到对应的cgroup文件的值为10。

    $ docker run -ti --rm --blkio-weight 10 ubuntu:14.04 bash -c "cat /sys/fs/cgroup/blkio/blkio.weight"
    10

通过以下两个命令来创建不同块设备IO权重值的容器。

    $ docker run -it --name c1 --blkio-weight 300 ubuntu:14.04 /bin/bash
    $ docker run -it --name c2 --blkio-weight 600 ubuntu:14.04 /bin/bash

如果在两个容器中同时进行块设备操作（例如以下命令）的话，你会发现所花费的时间和容器所拥有的块设备IO权重成正比。

    $ time dd if=/mnt/zerofile of=test.out bs=1M count=1024 oflag=direct

###(11)--blkio-weight-device=""
通过--blkio-weight-device="设备名:权重"接口可以设置容器对特定块设备IO的权重，有效值范围为10至1000的整数(包含10和1000)。
对应的cgroup文件为cgroup/blkio/blkio.weight_device。

    $ docker run --rm --blkio-weight-device "/dev/sda:1000" ubuntu:14.04 bash -c "cat /sys/fs/cgroup/blkio/blkio.weight_device"
    8:0 1000

以上log中的"8:0"表示sda的设备号，可以通过stat命令来获取某个设备的设备号。从以下log中的显示可以查看到/dev/sda对应的主机设备号为8，次设备号为0。

    $ stat -c %t:%T /dev/sda
    8:0

如果--blkio-weight-device接口和--blkio-weight接口一起使用，那么docker会使用--blkio-weight值作为默认的权重值，然后使用--blkio-weight-device值来设定指定设备的权重值，而早先设置的默认权重值将不在这个特定设备中生效。

    $ docker run --rm --blkio-weight 300 --blkio-weight-device "/dev/sda:500" ubuntu:14.04 bash -c "cat /sys/fs/cgroup/blkio/blkio.weight_device"
    8:0 500

通过以上log可以看出，当--blkio-weight接口和--blkio-weight-device接口一起使用的时候，/dev/sda设备的权重值由--blkio-weight-device设定的值来决定。

###(12)--device-read-bps=""
该接口用来限制指定设备的读取速率，对应的cgroup文件是cgroup/blkio/blkio.throttle.read_bps_device。

    $ docker run -it --device /dev/sda:/dev/sda --device-read-bps /dev/sda:1mb ubuntu:14.04 bash -c "cat /sys/fs/cgroup/blkio/blkio.throttle.read_bps_device"
    8:0 1048576

以上log中显示8:0 1000,8:0表示/dev/sda, 该接口对应的cgroup文件的值为1048576，是1MB所对应的字节数，即1024的平方。

创建容器时通过--device-read-bps接口设置设备读取速度为1MB/s。从以下log中可以看出,读取速度被限定为1.0MB/s,与预期结果相符合。

    $ docker run -it --device /dev/sda:/dev/sda --device-read-bps /dev/sda:1mB ubuntu:14.04 bash
    root@df1de679fae4:/# dd iflag=direct,nonblock if=/dev/sda of=/dev/null bs=5M count=1
    1+0 records in
    1+0 records out
    5242880 bytes (5.2 MB) copied, 5.00464 s, 1.0 MB/s

###(13)--device-write-bps=""
该接口用来限制指定设备的写速率，单位可以是kb、mb或者gb。对应的cgroup文件是cgroup/blkio/blkio.throttle.write_bps_device。

    $ docker run -it --device /dev/sda:/dev/sda --device-write-bps /dev/sda:1mB ubuntu:14.04 bash -c "cat /sys/fs/cgroup/blkio/blkio.throttle.write_bps_device"
    8:0 1048576

以上log中显示8:0 1000,8:0表示/dev/sda, 该接口对应的cgroup文件的值为1048576，是1MB所对应的字节数，即1024的平方。

创建容器时通过--device-write-bps接口设置设备写速度为1MB/s。从以下log中可以看出,读取速度被限定为1.0MB/s,与预期结果相符合。

限速操作：<br>

    $ docker run -it --device /dev/sda:/dev/sda --device /dev/sdb:/dev/sdb --device-write-bps /dev/sda:1mb ubuntu:14.04 bash
    root@bbf49f46f803:/# dd iflag=direct,nonblock if=/dev/sdb of=/dev/sda bs=5M count=1
    1+0 records in
    1+0 records out
    5242880 bytes (5.2 MB) copied, 5.00427 s, 1.0 MB/s
    
待补充(薛婉菊)，需要使用if=/dev/urandom of=/dev/sda，不要使用sdb

###(14)--device-read-iops=""
该接口设置了设备的IO读取速率，对应的cgroup文件是cgroup/blkio/blkio.throttle.read_iops_device。

    $ docker run -it --device /dev/sda:/dev/sda --device-read-iops /dev/sda:400 ubuntu:14.04 bash -c "cat /sys/fs/cgroup/blkio/blkio.throttle.read_iops_device"
    8:0 400

可以通过"--device-read-iops /dev/sda:400"来限定sda的IO读取速率(400次/秒)，log如下所示。

    $ docker run -ti --device /dev/sda:/dev/sda  --device-read-iops	/dev/sda:400 ubuntu:14.04
    root@71910742c445:/# dd iflag=direct,nonblock if=/dev/sda of=/dev/null bs=1k count=1000
    1000+0 records in
    1000+0 records out
    1024000 bytes (1.0 MB) copied, 2.42874 s, 422 kB/s
    
通过上面的log信息可以看出，容器每秒IO的读取次数为400，共需要读取1000次（log第二行：count=1000），测试结果显示执行时间为2.42874秒，约为2.5(1000/400)秒， 与预期结果相符。

###(15)--device-write-iops=""
待补充
对应的cgroup文件是cgroup/blkio/blkio.throttle.write_iops_device<br>

    $ docker run -it --device /dev/sda:/dev/sda --device-write-iops /dev/sda:400 ubuntu:14.04 bash -c "cat /sys/fs/cgroup/blkio/blkio.throttle.write_iops_device"
    8:0 400

    $ docker run -it --device /dev/sda:/dev/sda --device-write-iops /dev/sda:100 --device-read-iops /dev/sda:100 ubuntu:14.04 bash -c "dd iflag=direct,nonblock if=/dev/sda of=/dev/null bs=1b count=1000"
    1000+0 records in
    1000+0 records out
    512000 bytes (512 kB) copied, 9.89291 s, 51.8 kB/s

###(16)--oom-kill-disable=false
待补充
对应的cgroup文件是cgroup/memory/memory.oom_control<br>

    $  docker run -m 20m --oom-kill-disable=true ubuntu:14.04 bash -c 'cat /sys/fs/cgroup/memory/memory.oom_control'
    oom_kill_disable 1
    under_oom 0

测试：<br>

    $ docker run -m 20m --oom-kill-disable=false ubuntu:14.04 bash -c 'x=a; while true; do x=$x$x$x$x; done'
    $ echo $?
    137
    $ docker run -m 20m --oom-kill-disable=true ubuntu:14.04 bash -c 'x=a; while true; do x=$x$x$x$x; done'
       
    
    

###(17)--memory-swappiness=""
待补充
对应的cgroup文件是cgroup/memory/memory.swappiness

    $ docker run --memory-swappiness=100 ubuntu:14.04 bash -c 'cat /sys/fs/cgroup/memory/memory.swappiness'
    100
    
##5.总结
待补充
##6.作者简介
待补充
##参考资料：
http://www.tuicool.com/articles/zIJrEjn<br>
http://www.cnblogs.com/hustcat/p/3980244.html<br>
http://www.lupaworld.com/article-250948-1.html<br>
http://www.litrin.net/2015/08/14/docker%E5%AE%B9%E5%99%A8%E7%9A%84%E8%B5%84%E6%BA%90%E9%99%90%E5%88%B6/<br>
http://www.tuicool.com/articles/Qrq2Ynz<br>
https://github.com/docker/docker/blob/master/docs/reference/run.md<br>
http://www.infoq.com/cn/articles/docker-kernel-knowledge-namespace-resource-isolation<br>
https://github.com/torvalds/linux/tree/master/Documentation/cgroup-v1<br>
http://www.361way.com/increase-swap/1957.html<br>
https://goldmann.pl/blog/2014/09/11/resource-management-in-docker/<br>
https://www.datadoghq.com/blog/how-to-collect-docker-metrics/<br>
