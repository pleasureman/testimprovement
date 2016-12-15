# Resource management of Docker - Cgroups feature supproting Docker

随着Docker技术被越来越多的个人、企业所接受，其用途也越来越广泛。Docker资源管理包含对CPU、内存、IO等资源的限制，但大部分Docker使用者在使用资源管理接口时往往只知其然而不知其所以然。本文将介绍Docker资源管理背后的Cgroups机制，并且列举每一个资源管理接口对应的Cgroups接口，让Docker使用者对资源管理知其然并且知其所以然。

##1.Docker资源管理接口概览
| Option                     |  Description                                                                                                                                    |
| -------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| `-m`, `--memory=""`        | Memory limit (format: `<number>[<unit>]`). Number is a positive integer. Unit can be one of `b`, `k`, `m`, or `g`. Minimum is 4M.               |
| `--memory-swap=""`         | Total memory limit (memory + swap, format: `<number>[<unit>]`). Number is a positive integer. Unit can be one of `b`, `k`, `m`, or `g`.         |
| `--memory-reservation=""`  | Memory soft limit (format: `<number>[<unit>]`). Number is a positive integer. Unit can be one of `b`, `k`, `m`, or `g`.                         |
| `--kernel-memory=""`       | Kernel memory limit (format: `<number>[<unit>]`). Number is a positive integer. Unit can be one of `b`, `k`, `m`, or `g`. Minimum is 4M.        |
| `--oom-kill-disable=false` | Whether to disable OOM Killer for the container or not.                                                                                         |
| `--memory-swappiness=""`   | Tune a container's memory swappiness behavior. Accepts an integer between 0 and 100.                                                            |
| `-c`, `--cpu-shares=0`     | CPU shares (relative weight)                                                                                                                    |
| `--cpu-period=0`           | Limit the CPU CFS (Completely Fair Scheduler) period                                                                                            |
| `--cpu-quota=0`            | Limit the CPU CFS (Completely Fair Scheduler) quota                                                                                             |
| `--cpuset-cpus=""`         | CPUs in which to allow execution (0-3, 0,1)                                                                                                     |
| `--cpuset-mems=""`         | Memory nodes (MEMs) in which to allow execution (0-3, 0,1). Only effective on NUMA systems.                                                     |
| `--blkio-weight=0`         | Block IO weight (relative weight) accepts a weight value between 10 and 1000.                                                                   |
| `--blkio-weight-device=""` | Block IO weight (relative device weight, format: `DEVICE_NAME:WEIGHT`)                                                                          |
| `--device-read-bps=""`     | Limit read rate from a device (format: `<device-path>:<number>[<unit>]`). Number is a positive integer. Unit can be one of `kb`, `mb`, or `gb`. |
| `--device-write-bps=""`    | Limit write rate to a device (format: `<device-path>:<number>[<unit>]`). Number is a positive integer. Unit can be one of `kb`, `mb`, or `gb`.  |
| `--device-read-iops="" `   | Limit read rate (IO per second) from a device (format: `<device-path>:<number>`). Number is a positive integer.                                 |
| `--device-write-iops="" `  | Limit write rate (IO per second) to a device (format: `<device-path>:<number>`). Number is a positive integer.                                  |

## 2. Docker资源管理原理——Cgroups子系统介绍
Cgroups是control groups的缩写，是Linux内核提供的一种可以限制、记录、隔离进程组（process groups）所使用的物理资源（如：CPU、内存、IO等）的机制。最初由google的工程师提出，后来被整合进Linux内核。对资源的分配和管理是由各个cgroup子系统完成的。Cgroups有7个子系统，分别是cpuset、cpu、cpuacct、blkio、devices、freezer、memory。下面介绍与docker资源管理接口相关的4个子系统。

2.1 memory -- 这个子系统用来限制cgroup中的任务所能使用的内存上限。<br>

| 子系统常用cgroups接口 | 描述 | 对应的docker接口 |
| ---------------------------------------- | ---------------------------------------- | ---------------------------------------- |
| cgroup/memory/memory.limit_in_bytes | 设定内存上限，单位是字节，也可以使用k/K、m/M或者g/G表示要设置数值的单位。| -m, --memory="" |
| cgroup/memory/memory.memsw.limit_in_bytes |设定内存加上交换分区的使用总量。通过设置这个值，可以防止进程把交换分区用光。| --memory-swap="" |
| cgroup/memory/memory.soft_limit_in_bytes |设定内存限制，但这个限制并不会阻止进程使用超过限额的内存，只是在系统内存不足时，会优先回收超过限额的进程占用的内存，使之向限定值靠拢。| --memory-reservation="" |
| cgroup/memory/memory.kmem.limit_in_bytes |设定内核内存上限。| --kernel-memory="" |
| cgroup/memory/memory.oom_control |如果设置为0，那么在内存使用量超过上限时，系统不会杀死进程，而是阻塞进程直到有内存被释放可供使用时，另一方面，系统会向用户态发送事件通知，用户态的监控程序可以根据该事件来做相应的处理，例如提高内存上限等。| --oom-kill-disable="" |
| cgroup/memory/memory.swappiness |控制内核使用交换分区的倾向。取值范围是0至100之间的整数（包含0和100）。值越小，越倾向使用物理内存。| --memory-swappiness="" |

2.2 cpu -- 这个子系统使用调度程序提供对 CPU 的 cgroup 任务访问。<br>

| 子系统常用cgroups接口 | 描述 | 对应的docker接口 |
| ---------------------------------------- | ---------------------------------------- | ---------------------------------------- |
| cgroup/cpu/cpu.shares | 负责CPU比重分配的接口。假设我们在cgroupfs的根目录下创建了两个cgroup（C1和C2），并且将cpu.shares分别配置为512和1024，那么当C1和C2争用CPU时，C2将会比C1得到多一倍的CPU占用率。要注意的是，只有当它们争用CPU时CPU share才会起作用，如果C2是空闲的，那么C1可以得到全部的CPU资源。 | -c, --cpu-shares="" |
| cgroup/cpu/cpu.cfs_period_us | 负责CPU带宽限制，需要与cpu.cfs_quota_us搭配使用。我们可以将period设置为1秒，将quota设置为0.5秒，那么cgroup中的进程在1秒内最多只能运行0.5秒，然后就会被强制睡眠，直到下一个1秒才能继续运行。 | --cpu-period="" |
| cgroup/cpu/cpu.cfs_quota_us | 负责CPU带宽限制，需要与cpu.cfs_period_us搭配使用。 | --cpu-quota="" |

2.3 cpuset -- 这个子系统为 cgroup 中的任务分配独立 CPU（在多核系统）和内存节点。<br>

| 子系统常用cgroups接口 | 描述 | 对应的docker接口 |
| ---------------------------------------- | ---------------------------------------- | ---------------------------------------- |
| cgroup/cpuset/cpuset.cpus | 允许进程使用的CPU列表（例如：0-4,9）。 | --cpuset-cpus="" |
| cgroup/cpuset/cpuset.mems | 允许进程使用的内存节点列表（例如：0-1）。 | --cpuset-mems="" |

2.4 blkio -- 这个子系统为块设备设定输入/输出限制，比如物理设备（磁盘、固态硬盘、USB等）。<br>

| 子系统常用cgroups接口 | 描述 | 对应的docker接口 |
| ---------------------------------------- | ---------------------------------------- | ---------------------------------------- |
| cgroup/blkio/blkio.weight | 设置权重值，取值范围是10至1000之间的整数（包含10和1000）。这跟cpu.shares类似，是比重分配，而不是绝对带宽的限制，因此只有当不同的cgroup在争用同一个块设备的带宽时，才会起作用。 | --blkio-weight="" |
| cgroup/blkio/blkio.weight_device | 对具体的设备设置权重值，这个值会覆盖上述的blkio.weight。 | --blkio-weight-device=""  |
| cgroup/blkio/blkio.throttle.read_bps_device | 对具体的设备，设置每秒读块设备的带宽上限。 | --device-read-bps="" |
| cgroup/blkio/blkio.throttle.write_bps_device | 设置每秒写块设备的带宽上限。同样需要指定设备。 | --device-write-bps="" |
| cgroup/blkio/blkio.throttle.read_iops_device | 设置每秒读块设备的IO次数的上限。同样需要指定设备。 | --device-read-iops="" |
| cgroup/blkio/blkio.throttle.write_iops_device | 设置每秒写块设备的IO次数的上限。同样需要指定设备。 | --device-write-iops="" |

## 3.Details of Docker resource management and application examples
In this section, we would elaborate all of resource management interfaces. For deepening understanding, test cases are added for some of them. Docker version is 1.11.0. If stress command is unavailable in docker image, you can install it by executing "sudo apt-get install stress".
### 3.1 memory subsystem
#### 3.1.1 -m, --memory=""
The option is to limit memory usage. It is relevant to cgroup/memory/memory.limit_in_bytes file.
range: greater than or equal to 4M<br>
unit：b,k,m,g<br>

In default, a container can use unlimited memory until the memory of its host is exhausted.
Make sure its relevant cgroup file by executing the following command.

    $ docker run -it --memory 100M ubuntu:14.04 bash -c "cat /sys/fs/cgroup/memory/memory.limit_in_bytes"
    104857600

When the memory usage is limited to 100M, the value of the cgroup file is 104857600. The unit is Byte. It means that 104857600 Bytes are equal to 100M.

The memory of its host is as follow.

    $ free
              total        used        free      shared  buff/cache   available
    Mem:        4050284      254668     3007564      180484      788052     3560532
    Swap:             0           0           0

Note no swap in the host.

Use stress tool to verfiy that memroy limitation takes effect. Stress is a stress tool. The following command would create a process, which calls malloc and free memory continuously, within a container. In theory, if memory usage is less than limitation, a container survive. Note that a container will be killed if you try using stress tool to malloc up to 100M memory because of other processes in the container.

    $ docker run -ti -m 100M ubuntu:14.04 stress --vm 1 --vm-bytes 50M
    stress: info: [1] dispatching hogs: 0 cpu, 0 io, 1 vm, 0 hdd

When 50MB of memory is allocated in a container whose memory is limited to 100MB, it works fine.

When the allocated memory is more than 100MB, the below error occurs.

    $ docker run -ti -m 100M ubuntu:14.04 stress --vm 1 --vm-bytes 101M
    stress: info: [1] dispatching hogs: 0 cpu, 0 io, 1 vm, 0 hdd
    stress: FAIL: [1] (416) <-- worker 6 got signal 9
    stress: WARN: [1] (418) now reaping child worker processes
    stress: FAIL: [1] (422) kill error: No such process
    stress: FAIL: [1] (452) failed run completed in 0s

Note the above result is showed in case of no swap. If swap is added, what happened? Now add swap in the follwing command.

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

Then allocate more memory than limit.

    $ docker run -ti -m 100M ubuntu:14.04 stress --vm 1 --vm-bytes 101M
    stress: info: [1] dispatching hogs: 0 cpu, 0 io, 1 vm, 0 hdd

After swap is available, the container works fine. It means part of data of memory is transfered to swap
A container can exhaust memory of the host without memory restriction. This leads to unstablity of the host. So please limit memory as you use a container.

#### 3.1.2 --memory-swap=""
The option is to limit the sum of memory and swap. It is relevant to cgroup/memory/memory.memsw.limit_in_bytes.

range: greater than the value of memory limit<br>
unit：b,k,m,g<br>

Get the value of the relevant cgroup file by executing the following command.

    $ docker run -ti -m 300M --memory-swap 1G ubuntu:14.04 bash -c "cat /sys/fs/cgroup/memory/memory.memsw.limit_in_bytes"
    1073741824

From the above log, when memory-swap is limited to 1GB, the value of the cgroup file is 1073741824 and its unit is Byte. In short, 1073741824B is equal to 1GB.

<table>
  <thead>
    <tr>
      <th>Option</th>
      <th>Result</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td class="no-wrap">
          <strong>memory=inf, memory-swap=inf</strong> (default)
      </td>
      <td>
        There is no memory limit for the container. The container can use
        as much memory as needed.
      </td>
    </tr>
    <tr>
      <td class="no-wrap"><strong>memory=L&lt;inf, memory-swap=inf</strong></td>
      <td>
        (specify memory and set memory-swap as <code>-1</code>) The container is
        not allowed to use more than L bytes of memory, but can use as much swap
        as is needed (if the host supports swap memory).
      </td>
    </tr>
    <tr>
      <td class="no-wrap"><strong>memory=L&lt;inf, memory-swap=2*L</strong></td>
      <td>
        (specify memory without memory-swap) The container is not allowed to
        use more than L bytes of memory, swap <i>plus</i> memory usage is double
        of that.
      </td>
    </tr>
    <tr>
      <td class="no-wrap">
          <strong>memory=L&lt;inf, memory-swap=S&lt;inf, L&lt;=S</strong>
      </td>
      <td>
        (specify both memory and memory-swap) The container is not allowed to
        use more than L bytes of memory, swap <i>plus</i> memory usage is limited
        by S.
      </td>
    </tr>
  </tbody>
</table>

Examples:
We set nothing about memory in the following command, this means the processes in the container can use as much memory and swap memory as they need.

    $ docker run -it ubuntu:14.04 bash -c "cat /sys/fs/cgroup/memory/memory.limit_in_bytes && cat /sys/fs/cgroup/memory/memory.memsw.limit_in_bytes" 
    9223372036854771712
    9223372036854771712

We set memory limit and disabled swap memory limit in the following command, this means the processes in the container can use 300M memory and as much swap memory as they need (if the host supports swap memory). "-1" means no limit is set.

    $ docker run -it -m 300M --memory-swap -1 ubuntu:14.04 bash -c "cat /sys/fs/cgroup/memory/memory.limit_in_bytes && cat /sys/fs/cgroup/memory/memory.memsw.limit_in_bytes"
    314572800
    9223372036854771712

We set memory limit only in the following command, this means the processes in the container can use 300M memory and 300M swap memory. By default, the total virtual memory size (--memory-swap) will be set as double of memory. In this case, memory + swap would be 2*300M, so processes can use 300M swap memory as well.

    $ docker run -it -m 300M ubuntu:14.04 bash -c "cat /sys/fs/cgroup/memory/memory.limit_in_bytes && cat /sys/fs/cgroup/memory/memory.memsw.limit_in_bytes"
    314572800
    629145600

We set both memory and swap memory in the following command, so the processes in the container can use 300M memory and 700M swap memory.

    $ docker run -it -m 300M --memory-swap 1G ubuntu:14.04 bash -c "cat /sys/fs/cgroup/memory/memory.limit_in_bytes && cat /sys/fs/cgroup/memory/memory.memsw.limit_in_bytes"
    314572800
    1073741824

When the value of memory-swap limit is less than the value of memory limit, the error "Minimum memoryswap limit should be larger than memory limit" occurs.

    $ docker run -it -m 300M --memory-swap 200M ubuntu:14.04 bash -c "cat /sys/fs/cgroup/memory/memory.limit_in_bytes && cat /sys/fs/cgroup/memory/memory.memsw.limit_in_bytes"
    docker: Error response from daemon: Minimum memoryswap limit should be larger than memory limit, see usage..
    See 'docker run --help'.

The memory more than the value of memory-swap limit is allocated, the below error occurs.

    $ docker run -ti -m 100M --memory-swap 200M ubuntu:14.04 stress --vm 1 --vm-bytes 201M
    stress: info: [1] dispatching hogs: 0 cpu, 0 io, 1 vm, 0 hdd
    stress: FAIL: [1] (416) <-- worker 7 got signal 9
    stress: WARN: [1] (418) now reaping child worker processes
    stress: FAIL: [1] (422) kill error: No such process
    stress: FAIL: [1] (452) failed run completed in 0s

When the value of memory limit is less than the value of memory-swap limit, a container works fine. See the following log for details.

    $ docker run -ti -m 100M --memory-swap 200M ubuntu:memory stress --vm 1 --vm-bytes 180M
    stress: info: [1] dispatching hogs: 0 cpu, 0 io, 1 vm, 0 hdd

#### 3.1.3 --memory-reservation=""
range:positive integer<br>
unit:b,k,m,g<br>

This option is relevant to cgroup/memory/memory.soft_limit_in_bytes.

    $ docker run -ti --memory-reservation 50M ubuntu:14.04 bash -c "cat /sys/fs/cgroup/memory/memory.soft_limit_in_bytes"
    52428800

Memory reservation is a kind of memory soft limit that allows for greater sharing of memory. Under normal circumstances, containers can use as much of the memory as needed and are constrained only by the hard limits set with the -m/--memory option.

When memory reservation is set, Docker detects memory contention or low memory and forces containers to restrict their consumption to a reservation limit.

Memory reservation does not guarantee the limit won't be exceeded. Instead, the feature attempts to ensure that, when memory is heavily contended for, memory is allocated based on the reservation hints/setup.

The following example limits the memory (-m) to 500M and sets the memory reservation to 200M. Under this configuration, when the container consumes memory more than 200M and less than 500M, the next system memory reclaim attempts to shrink container memory below 200M.

    $ docker run -it -m 500M --memory-reservation 200M ubuntu:14.04 bash

The following example sets memory reservation to 1G without a hard memory limit. The container can use as much memory as it needs. The memory reservation setting ensures the container doesn't consume too much memory for long time, because every memory reclaim shrinks the container's consumption to the reservation.

    $ docker run -it --memory-reservation 1G ubuntu:14.04 bash

#### 3.1.4 --kernel-memory=""
This option ti to limit kernel memory.  It is relevant to cgroup/memory/memory.kmem.limit_in_bytes.

    $ docker run -ti --kernel-memory 50M ubuntu:14.04 bash -c "cat /sys/fs/cgroup/memory/memory.kmem.limit_in_bytes"
    52428800

The following example sets memory and kernel memory, so the processes in the container can use 500M memory in total, in this 500M memory, it can be 50M kernel memory tops.

    $ docker run -it -m 500M --kernel-memory 50M ubuntu:14.04 bash

The following example sets kernel memory without -m, so the processes in the container can use as much memory as they want, but they can only use 50M kernel memory.

    $ docker run -it --kernel-memory 50M ubuntu:14.04 bash

#### 3.1.5 --oom-kill-disable=false
By default, kernel kills processes in a container if an out-of-memory(OOM) error occurs. To change this behaviour, use the --oom-kill-disable option. It is relevant to cgroup/memory/memory.oom_control.

When a container allocates memory more than the value of memory limit, kernle will trigger out-of-memory(OOM). If --oom-kill-disable=false, the container will be killed. If --oom-kill-disable=true, the container is suspended.

The following example limits memory to 20MB and set --oom-kill-disable as true. The value of oom_kill_disable is 1.

    $  docker run -m 20m --oom-kill-disable=true ubuntu:14.04 bash -c 'cat /sys/fs/cgroup/memory/memory.oom_control'
    oom_kill_disable 1
    under_oom 0

oom_kill_disable: (0 or 1); 1 means that a container use memory more than the limit(20MB) and the container is suspended.

under_oom: (0 or 1); 1 means that OOM occurs in a container.

Use the "x=a; while true; do x=$x$x$x$x; done" command to exhaust memory and trigger OOM. The log is as follow.

    $ docker run -m 20m --oom-kill-disable=false ubuntu:14.04 bash -c 'x=a; while true; do x=$x$x$x$x; done'
    $ echo $?
    137

The container exits with the return value of 137. When its memory usage exceeds the limit, OOM occurs and it is killed. We can see the value of  under_oom is 1 and value of oom_kill_disable is 1 by the cgroup file, /sys/fs/cgroup/memory/docker/${container_id}/memory.oom_control.

If --oom-kill-disable=true, the container wouldn't be killed. It is suspended.

    $ docker run -m 20m --oom-kill-disable=true ubuntu:14.04 bash -c 'x=a; while true; do x=$x$x$x$x; done'

####3.1.6 --memory-swappiness=""
This option is to set tendency of swap memory usage. The range is integers between 0 and 100, including 0 and 100. A value of 0 turns off anonymous page swapping. A value of 100 sets all anonymous pages as swappable. It is relevant to cgroup/memory/memory.swappiness.

    $ docker run --memory-swappiness=100 ubuntu:14.04 bash -c 'cat /sys/fs/cgroup/memory/memory.swappiness'
    100

### 3.2 cpu subsystem
#### 3.2.1 -c, --cpu-shares=0
It is relevant to the cgroup/cpu/cpu.shares file.

    $ docker run --rm --cpu-shares 1600 ubuntu:14.04 bash -c "cat /sys/fs/cgroup/cpu/cpu.shares"
    1600

This option is to set CPU relative weight, which is for CPU intensive processes. When tasks in one container are idle, other containers can use the left-over CPU time. The option can take effect only when 2 or more containers compete for CPU resource.

The following example sets two container’s CPU shares to 1024 and 512.

    $ docker run -ti --cpu-shares 1024 ubuntu:14.04 stress -c 1
    stress: info: [1] dispatching hogs: 1 cpu, 0 io, 0 vm, 0 hdd
    
    $ docker run -ti --cpu-shares 512 ubuntu:14.04 stress -c 1
    stress: info: [1] dispatching hogs: 1 cpu, 0 io, 0 vm, 0 hdd

See the below log of the top command. PID of the first container is 1418, whose CPU usage is 66.1%. PID of the second container is 1471, whose CPU usage is 32.9. The proporation is appromately 2:1. The result is as expected.

    top - 18:51:50 up 9 days,  2:07,  0 users,  load average: 0.62, 0.15, 0.05
    Tasks:  84 total,   3 running,  81 sleeping,   0 stopped,   0 zombie
    %Cpu(s): 90.4 us,  2.2 sy,  0.0 ni,  0.0 id,  0.0 wa,  0.0 hi,  7.4 si,  0.0 st
    KiB Mem :  2052280 total,    71468 free,   117284 used,  1863528 buff/cache
    KiB Swap:        0 total,        0 free,        0 used.  1536284 avail Mem 
    PID USER      PR  NI    VIRT    RES    SHR S %CPU %MEM     TIME+ COMMAND
    1418 root      20   0    7312    100      0 R 66.1  0.0   0:22.92 stress
    1471 root      20   0    7312     96      0 R 32.9  0.0   0:04.97 stress

#### 3.2.2 --cpu-period=""
By default, the period of CFS(Completely Fair Scheduler) is 100ms in linux. We can use --cpu-period to set the period of CPUs to limit the container's CPU usage. And usually --cpu-period should work with --cpu-quota. --cpu-quota sets CPU period constraints. CFS is the default scheduler of kernel. It is to allocate CPU resources. --cpu-quota can also be set for multi-core cpu.

It is relevant to the cgroup/cpu/cpu.cfs_period_us.

The following example sets CPU period to 50000ms and verifys the value of the cgroup file.

    $ docker run -ti --cpu-period 50000 ubuntu:14.04 bash -c "cat /sys/fs/cgroup/cpu/cpu.cfs_period_us"
    50000

In the following example, the container can use 50% CPU resource.

    $ docker run -ti --cpu-period=50000 --cpu-quota=25000 ubuntu:14.04 stress -c 1
    stress: info: [1] dispatching hogs: 1 cpu, 0 io, 0 vm, 0 hdd

From the last line, we can see the cpu usage percentage is 50.0%. The result is as expected.

    top - 10:36:55 up 6 min,  0 users,  load average: 0.49, 0.21, 0.10
    Tasks:  68 total,   2 running,  66 sleeping,   0 stopped,   0 zombie
    %Cpu(s): 49.3 us,  0.0 sy,  0.0 ni, 50.7 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
    KiB Mem :  4050748 total,  3063952 free,   124280 used,   862516 buff/cache
    KiB Swap:        0 total,        0 free,        0 used.  3728860 avail Mem 
    PID USER      PR  NI    VIRT    RES    SHR S %CPU %MEM     TIME+ COMMAND                                           
    770 root      20   0    7312     96      0 R 50.0  0.0   0:38.06 stress

#### 3.2.3 --cpu-quota=0
The option is to set CPU period constraints. 
It is relevant to the cgroup/cpu/cpu.cfs_quota_us file. In general, it should work with --cpu-period.
See the --cpu-period section for details.

    $ docker run --cpu-quota 1600 ubuntu:14.04 bash -c "cat /sys/fs/cgroup/cpu/cpu.cfs_quota_us"
    1600

### 3.3 cpuset subsystem
#### 3.3.1 --cpuset-cpus=""
The option is relevant to the cgroup/cpuset/cpuset.cpus file.

In the following example, the processes of the container only run on cpu core 1 in a multi-core VM. The value of the cgroup file is 1.

    $ docker run -ti --cpuset-cpus 1 ubuntu:14.04 bash -c "cat /sys/fs/cgroup/cpuset/cpuset.cpus"
    1

In the following example, the container only use on cpu core 1 and the stress tool is running.

    $ docker run -ti --cpuset-cpus 1 ubuntu:14.04 stress -c 1

In the below log, the status of each cpu is showed. Note that the console can show the status of each cpu only when press 1 button after run the top command.

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

The usage percentage of CPU core 1. Other cpus are idle. The result is as expected.

#### 3.3.2 --cpuset-mems=""
The option is relevant to the cgroup/cpuset/cpuset.mems.

    $ docker run -ti --cpuset-mems=0 ubuntu:14.04 bash -c "cat /sys/fs/cgroup/cpuset/cpuset.mems"
    0

In the following example, the processes of the container only use memory nodes 1 and 3.

    $ docker run -it --cpuset-mems="1,3" ubuntu:14.04 bash

In the following example, the processes of the container only use memory nodes 0, 1 and 2.

    $ docker run -it --cpuset-mems="0-2" ubuntu:14.04 bash

### 3.4 blkio subsystem
#### 3.4.1 --blkio-weight=0
The option is set block device IO weight. By default, the value is 500. It is relevant to the cgroup/blkio/blkio.weight file.

Range: integers between 10 and 1000(including 10 and 1000)

The following example verify the value of the cgroup file.

    $ docker run -ti --rm --blkio-weight 10 ubuntu:14.04 bash -c "cat /sys/fs/cgroup/blkio/blkio.weight"
    10

The following example creates two containers with different weight values.

    $ docker run -it --name c1 --blkio-weight 300 ubuntu:14.04 /bin/bash
    $ docker run -it --name c2 --blkio-weight 600 ubuntu:14.04 /bin/bash

If you run the following command to do block IO in the two containers at the same time. Time spent is inverse proportion of blkio weights of the two containers.

    $ time dd if=/mnt/zerofile of=test.out bs=1M count=1024 oflag=direct

#### 3.4.2 --blkio-weight-device=""
The --blkio-weight-device="DEVICE_NAME:WEIGHT" flag sets a specific device weight. 

Range: integers between 10 and 1000(including 10 and 1000)

It is relevant to the cgroup/blkio/blkio.weight_device.

    $ docker run --blkio-weight-device "/dev/sda:1000" ubuntu:14.04 bash -c "cat /sys/fs/cgroup/blkio/blkio.weight_device"
    8:0 1000

""8:0" is the device id of /dev/sda. 8 is major device id and 0 is minor device id. To get it by the following stat command.

    $ stat -c %t:%T /dev/sda
    8:0

If you specify both the --blkio-weight and --blkio-weight-device, Docker uses the --blkio-weight as the default weight and uses --blkio-weight-device to override this default with a new value on a specific device. 

    $ docker run --blkio-weight 300 --blkio-weight-device "/dev/sda:500" ubuntu:14.04 bash -c "cat /sys/fs/cgroup/blkio/blkio.weight_device"
    8:0 500

In the above example, --blkio-weight-device overrides the value of --blkio-weight for /dev/sda.

#### 3.4.3 --device-read-bps=""
The option is to limit the read rate (bytes per second) from a device. It is relevant to the cgroup/blkio/blkio.throttle.read_bps_device file.

unit: kb, mb, gb

    $ docker run -it --device /dev/sda:/dev/sda --device-read-bps /dev/sda:1mb ubuntu:14.04 bash -c "cat /sys/fs/cgroup/blkio/blkio.throttle.read_bps_device"
    8:0 1048576

8:0 is the device id of /dev/sda. The value is 1048576, the Byte quantity of 1MB(the square of 1024).

The following example restricts the read rate to 1MB/s. The result is as expected.

    $ docker run -it --device /dev/sda:/dev/sda --device-read-bps /dev/sda:1mB ubuntu:14.04 bash
    root@df1de679fae4:/# dd iflag=direct,nonblock if=/dev/sda of=/dev/null bs=5M count=1
    1+0 records in
    1+0 records out
    5242880 bytes (5.2 MB) copied, 5.00464 s, 1.0 MB/s

#### 3.4.4 --device-write-bps=""
The option is to limit the write rate (bytes per second) from a device. It is relevant to the cgroup/blkio/blkio.throttle.write_bps_device.

    $ docker run -it --device /dev/sda:/dev/sda --device-write-bps /dev/sda:1mB ubuntu:14.04 bash -c "cat /sys/fs/cgroup/blkio/blkio.throttle.write_bps_device"
    8:0 1048576

8:0 is the device id of /dev/sda. The value is 1048576, the Byte quantity of 1MB(the square of 1024).

The following example restricts the write rate to 1MB/s. The result is as expected.

    $ docker run -it --device /dev/sda:/dev/sda --device-write-bps /dev/sda:1mb ubuntu:14.04 bash
    root@18dc79b91cd4:/# dd oflag=direct,nonblock of=/dev/sda if=/dev/urandom bs=10K count=1000
    1000+0 records in
    1000+0 records out
    10240000 bytes (10 MB) copied, 10.1987 s, 1.0 MB/s

#### 3.4.5 --device-read-iops=""
The option is limit read rate (IO per second) from a device. It is relevant to the cgroup/blkio/blkio.throttle.read_iops_device file. 

    $ docker run -it --device /dev/sda:/dev/sda --device-read-iops /dev/sda:400 ubuntu:14.04 bash -c "cat /sys/fs/cgroup/blkio/blkio.throttle.read_iops_device"
    8:0 400

The following example restricts the read rate to 400 IO per second.

    $ docker run -ti --device /dev/sda:/dev/sda  --device-read-iops	/dev/sda:400 ubuntu:14.04
    root@71910742c445:/# dd iflag=direct,nonblock if=/dev/sda of=/dev/null bs=1k count=1000
    1000+0 records in
    1000+0 records out
    1024000 bytes (1.0 MB) copied, 2.42874 s, 422 kB/s

The container reads 1000 times(The second line of log: count=1000). Time spent is 2.42874 seconds, appromate 2.5(1000/400) seconds. It is as expected.

#### 3.4.6 --device-write-iops=""
The option is to limit write rate (IO per second) from a device. It is relevant to the cgroup/blkio/blkio.throttle.write_iops_device file. 

    $ docker run -it --device /dev/sda:/dev/sda --device-write-iops /dev/sda:400 ubuntu:14.04 bash -c "cat /sys/fs/cgroup/blkio/blkio.throttle.write_iops_device"
    8:0 400

The following example restricts the write rate to 400 IO per second.

    $ docker run -ti --device /dev/sda:/dev/sda --device-write-iops /dev/sda:400 ubuntu:14.04
    root@ef88a516d6ed:/# dd oflag=direct,nonblock of=/dev/sda if=/dev/urandom bs=1K count=1000
    1000+0 records in
    1000+0 records out
    1024000 bytes (1.0 MB) copied, 2.4584 s, 417 kB/s

The container writes 1000 times(The second line of log: count=1000). Time spent is 2.4584 seconds, appromate 2.5(1000/400) seconds. It is as expected.


## 4.Summary
Docker的资源管理依赖于Linux内核Cgroups机制。理解Docker资源管理的原理并不难，读者可以根据自己兴趣补充一些有针对性的测试。关于Cgroups的实现机制已经远超本文的范畴。感兴趣的读者可以自行查看[相关文章](http://www.infoq.com/cn/articles/docker-kernel-knowledge-cgroups-resource-isolation)和内核手册。

## Authors
孙远，华为中央软件研究院资深工程师，硕士毕业，9年软件行业经验。目前在华为从事容器Docker项目的测试工作。工作涉及到功能测试、性能测试、压力测试、稳定性测试、安全测试、测试管理、工程能力构建等内容。参与编写了《Docker进阶与实战》的Docker测试章节。先前曾经就职于美国风河系统公司，作为team lead从事风河Linux产品测试工作。活跃于Docker社区和内核测试ltp社区，目前有大量测试用例被开源社区接收。<br>
研究方向：容器技术、Docker、Linux内核、软件测试、自动化测试、测试过程改进<br>
公司邮箱：sunyuan3@huawei.com<br>
个人邮箱：yuan.sun82@gmail.com<br>

薛婉菊，中软国际科技服务有限公司软件测试工程师，4年软件行业经验。目前参与容器Docker项目的测试工作，工作涉及到容器功能测试、性能测试、压力测试等内容。<br>
研究方向：容器技术、Docker、自动化测试<br>
公司邮箱：xuewanju@chinasoftinc.com<br>
个人邮箱：xuewanju123@163.com<br>

##reference：
http://www.cnblogs.com/hustcat/p/3980244.html<br>
http://www.lupaworld.com/article-250948-1.html<br>
http://www.tuicool.com/articles/Qrq2Ynz<br>
https://github.com/docker/docker/blob/master/docs/reference/run.md<br>
http://www.infoq.com/cn/articles/docker-kernel-knowledge-namespace-resource-isolation<br>
https://github.com/torvalds/Linux/tree/master/Documentation/cgroup-v1<br>
http://www.361way.com/increase-swap/1957.html<br>
https://goldmann.pl/blog/2014/09/11/resource-management-in-docker/<br>
https://www.datadoghq.com/blog/how-to-collect-docker-metrics/<br>

