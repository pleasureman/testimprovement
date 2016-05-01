#docker资源管理探秘
##1.docker资源管理接口简介
| 选项                     |  描述                                                                                                                                    |
| -------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| `-m`, `--memory=""`        | 内存使用限制 (格式: `<数字>[<单位>]`)。 需要使用整数，对应的单位是`b`, `k`, `m`, `g`中的一个。最小取值是4M。              |
| `--memory-swap=""`         | 总内存使用限制 (物理内存 + 交换分区, 格式: `<数字>[<单位>]`)需要使用整数，对应的单位是`b`, `k`, `m`, `g`中的一个。         |
| `--memory-reservation=""`  | Memory soft limit (format: `<number>[<unit>]`). Number is a positive integer. Unit can be one of `b`, `k`, `m`, or `g`.                         |
| `--kernel-memory=""`       | Kernel memory limit (format: `<number>[<unit>]`). Number is a positive integer. Unit can be one of `b`, `k`, `m`, or `g`. Minimum is 4M.        |
| `-c`, `--cpu-shares=0`     | CPU shares (relative weight)                                                                                                                    |
| `--cpu-period=0`           | Limit the CPU CFS (Completely Fair Scheduler) period                                                                                            |
| `--cpuset-cpus=""`         | CPUs in which to allow execution (0-3, 0,1)                                                                                                     |
| `--cpuset-mems=""`         | Memory nodes (MEMs) in which to allow execution (0-3, 0,1). Only effective on NUMA systems.                                                     |
| `--cpu-quota=0`            | Limit the CPU CFS (Completely Fair Scheduler) quota                                                                                             |
| `--blkio-weight=0`         | Block IO weight (relative weight) accepts a weight value between 10 and 1000.                                                                   |
| `--blkio-weight-device=""` | Block IO weight (relative device weight, format: `DEVICE_NAME:WEIGHT`)                                                                          |
| `--device-read-bps=""`     | Limit read rate from a device (format: `<device-path>:<number>[<unit>]`). Number is a positive integer. Unit can be one of `kb`, `mb`, or `gb`. |
| `--device-write-bps=""`    | Limit write rate to a device (format: `<device-path>:<number>[<unit>]`). Number is a positive integer. Unit can be one of `kb`, `mb`, or `gb`.  |
| `--device-read-iops="" `   | Limit read rate (IO per second) from a device (format: `<device-path>:<number>`). Number is a positive integer.                                 |
| `--device-write-iops="" `  | Limit write rate (IO per second) to a device (format: `<device-path>:<number>`). Number is a positive integer.                                  |
| `--oom-kill-disable=false` | Whether to disable OOM Killer for the container or not.                                                                                         |
| `--memory-swappiness=""`   | Tune a container's memory swappiness behavior. Accepts an integer between 0 and 100.                                                            |
| `--shm-size=""`            | Size of `/dev/shm`. The format is `<number><unit>`. `number` must be greater than `0`. Unit is optional and can be `b` (bytes), `k` (kilobytes), `m` (megabytes), or `g` (gigabytes). If you omit the unit, the system uses bytes. If you omit the size entirely, the system uses `64m`. |

##2.cgroups简介
##3.docker资源管理接口详解
###(1)-m, --memory=""
可以限制容器使用的内存量，对应的cgroup文件是cgroup/memory/memory.limit_in_bytes。<br>
取值范围:大于等于4M<br>
单位：b,k,m,g<br>

在默认情况下，容器可以占用无限量的内存，直至主机内存资源耗尽。
运行如下命令来确认容器内存的资源管理对应的cgroup文件。

    $ docker run -it --memory 100M ubuntu bash -c "cat /sys/fs/cgroup/memory/memory.limit_in_bytes"
    104857600

可以看到，当内存限定为100M时，对应的cgroup文件数值为104857600，该数值的单位为kB，即104857600kB等于100M。

本机内存环境为：

    free
              total        used        free      shared  buff/cache   available
    Mem:        4050284      254668     3007564      180484      788052     3560532
    Swap:             0           0           0

值得注意的是本机目前没有配置交换分区(swap)。

我们使用stress工具来证明内存限定已经生效。stress是一个压力测试套，如下命令将要在容器内创建一个进程，在该进程中不断的执行占用内存(malloc)和释放内存(free)的操作。在理论上如果占用的内存少于限定值，容器会工作正常。注意，如果试图使用边界值，即试图在容器中使用stress工具占用100M内存，这个操作通常会失败，因为容器中还有其他进程在运行。

    [unicorn@unicorn ~]$ docker run -ti -m 100M ubuntu:memory stress --vm 1 --vm-bytes 50M
    stress: info: [1] dispatching hogs: 0 cpu, 0 io, 1 vm, 0 hdd

当在限定内存为100M的容器中，试图占用50M的内存时，容器工作正常。
如下所示，当试图占用超过100M内存时，必然导致容器异常。

    [unicorn@unicorn ~]$ docker run -ti -m 100m ubuntu:memory stress --vm 1 --vm-bytes 101M
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

    [unicorn@unicorn ~]$ docker run -ti -m 100m ubuntu:memory stress --vm 1 --vm-bytes 101M
    stress: info: [1] dispatching hogs: 0 cpu, 0 io, 1 vm, 0 hdd

在加入交换分区后容器工作正常，这意味着有部分存储在内存中的信息被转移到了交换分区中了。
注意，在实际容器使用场景中，如果我不不对容器使用内存量加以限制的话，可以能导致一个容器会耗尽整个主机内存，从而导致系统不稳定。所以在使用容器时务必对容器内存加以限制。

###(2)--memory-swap=""
对应的cgroup文件是cgroup/memory/memory.memsw.limit_in_bytes<br>

    [unicorn@unicorn ~]$ docker run -ti -m 300M --memory-swap 1G rnd-dockerhub.huawei.com/official/ubuntu:latest bash -c "cat /sys/fs/cgroup/memory/memory.memsw.limit_in_bytes"
    1073741824


###(3)--memory-reservation=""
对应的cgroup文件是cgroup/memory/memory.soft_limit_in_bytes

    [unicorn@unicorn ~]$ docker run -ti --memory-reservation 50M rnd-dockerhub.huawei.com/official/ubuntu:latest bash -c "cat /sys/fs/cgroup/memory/memory.soft_limit_in_bytes"
    52428800

###(4)--kernel-memory=""
对应的cgroup文件cgroup/memory/memory.kmem.limit_in_bytes

    [unicorn@unicorn ~]$ docker run -ti --kernel-memory 50M rnd-dockerhub.huawei.com/official/ubuntu:latest bash -c "cat /sys/fs/cgroup/memory/memory.kmem.limit_in_bytes"
    52428800

###(5)-c, --cpu-shares=0
对应的cgroup文件是cgroup/cpu/cpu.shares<br>

    [unicorn@unicorn docker_engine]$ docker run --rm --cpu-shares 1600 rnd-dockerhub.huawei.com/official/ubuntu:latest bash -c "cat /sys/fs/cgroup/cpu/cpu.shares"
    1600

###(6)--cpu-period=0
对应的cgroup文件是cgroup/cpu/cpu.cfs_period_us

    [unicorn@unicorn ~]$ docker run -ti --cpu-period 50000 rnd-dockerhub.huawei.com/official/ubuntu:latest bash -c "cat /sys/fs/cgroup/cpu/cpu.cfs_period_us"
    50000

###(7)--cpuset-cpus=""
对应的cgroup文件是cgroup/cpuset/cpuset.cpus

    [unicorn@unicorn ~]$ docker run -ti --cpuset-cpus 1 rnd-dockerhub.huawei.com/official/ubuntu:latest bash -c "cat /sys/fs/cgroup/cpuset/cpuset.cpus"
    1

###(8)--cpuset-mems=""
对应的cgroup文件是cgroup/cpuset/cpuset.mems

    [unicorn@unicorn ~]$ docker run -ti --cpuset-mems=0 rnd-dockerhub.huawei.com/official/ubuntu:latest bash -c "cat /sys/fs/cgroup/cpuset/cpuset.mems"
    0

###(9)--cpu-quota=0
对应的cgroup文件是cgroup/cpu/cpu.cfs_quota_us

    [unicorn@unicorn docker_engine]$ docker run --rm --cpu-quota 1600 rnd-dockerhub.huawei.com/official/ubuntu:latest bash -c "cat /sys/fs/cgroup/cpu/cpu.cfs_quota_us"
    1600


###(10)--blkio-weight=0
对应的cgroup文件cgroup/blkio/blkio.weight<br>
###(11)--blkio-weight-device=""
对应的cgroup文件cgroup/blkio/blkio.weight_device<br>
###(12)--device-read-bps=""
对应的cgroup文件是cgroup/blkio/blkio.throttle.read_bps_device<br>

    [unicorn@unicorn ~]$ docker run -it --device /dev/sda:/dev/sda --device-read-bps /dev/sda:1mB     rnd-dockerhub.huawei.com/official/ubuntu:stress bash -c "cat /sys/fs/cgroup/blkio/blkio.throttle.read_bps_device"
    8:0 1048576

限速操作：<br>

    [unicorn@unicorn ~]$ docker run -it --device /dev/sda:/dev/sda --device-read-bps /dev/sda:1mB     rnd-dockerhub.huawei.com/official/ubuntu:stress bash
    root@df1de679fae4:/# dd iflag=direct,nonblock if=/dev/sda of=/dev/null bs=5M count=1
    1+0 records in
    1+0 records out
    5242880 bytes (5.2 MB) copied, 5.00464 s, 1.0 MB/s
    $root@df1de679fae4:/# 
###(13)--device-write-bps=""
对应的cgroup文件是cgroup/blkio/blkio.throttle.write_bps_device<br>

    [unicorn@unicorn ~]$ docker run -it --device /dev/sda:/dev/sda --device-write-bps /dev/sda:1mB         rnd-dockerhub.huawei.com/official/ubuntu:stress bash -c "cat /sys/fs/cgroup/blkio/blkio.throttle.write_bps_device"
    8:0 1048576

限速操作：<br>

    [unicorn@unicorn ~]$ docker run -it --device /dev/sda:/dev/sda --device-write-bps /dev/sda:1mB         rnd-dockerhub.huawei.com/official/ubuntu:stress bash
    root@bbf49f46f803:/# dd iflag=direct,nonblock if=/dev/sda of=/dev/sda bs=5M count=1
    1+0 records in
    1+0 records out
    5242880 bytes (5.2 MB) copied, 0.00457201 s, 1.1 GB/s
    root@bbf49f46f803:/# dd iflag=direct,nonblock if=/dev/sda of=/dev/sda bs=5M count=1
    1+0 records in
    1+0 records out
    5242880 bytes (5.2 MB) copied, 5.00427 s, 1.0 MB/s
###(14)--device-read-iops=""
对应的cgroup文件是cgroup/blkio/blkio.throttle.read_iops_device<br>

    [unicorn@unicorn ~]$ docker run -it --device /dev/sda:/dev/sda --device-read-iops /dev/sda:400 rnd-dockerhub.huawei.com/official/ubuntu:stress bash -c "cat /sys/fs/cgroup/blkio/blkio.throttle.read_iops_device"
    8:0 400

###(15)--device-write-iops=""
对应的cgroup文件是cgroup/blkio/blkio.throttle.write_iops_device<br>

    [unicorn@unicorn ~]$ docker run -it --device /dev/sda:/dev/sda --device-write-iops /dev/sda:400 rnd-dockerhub.huawei.com/official/ubuntu:stress bash -c "cat /sys/fs/cgroup/blkio/blkio.throttle.write_iops_device"
    8:0 400

###(16)--oom-kill-disable=false
对应的cgroup文件是cgroup/memory/memory.oom_control<br>

    unicorn@unicorn:~$  docker run -m 20m --oom-kill-disable=true rnd-dockerhub.huawei.com/official/ubuntu:latest bash -c 'cat /sys/fs/cgroup/memory/memory.oom_control'
    oom_kill_disable 1
    under_oom 0

测试：<br>

    unicorn@unicorn:~$ docker run -m 20m --oom-kill-disable=false rnd-dockerhub.huawei.com/official/ubuntu:latest bash -c 'x=a; while true; do x=$x$x$x$x; done'
    unicorn@unicorn:~$ echo $?
    137
    unicorn@unicorn:~$ docker run -m 20m --oom-kill-disable=true rnd-dockerhub.huawei.com/official/ubuntu:latest bash -c 'x=a; while true; do x=$x$x$x$x; done'
       
    
    

###(17)--memory-swappiness=""
对应的cgroup文件是cgroup/memory/memory.swappiness

    unicorn@unicorn:/sys/fs/cgroup/memory$ docker run --memory-swappiness=100 rnd-dockerhub.huawei.com/official/ubuntu:latest bash -c 'cat /sys/fs/cgroup/memory/memory.swappiness'
    100
    
###(18)--shm-size=""  Size of /dev/shm. 
##4.总结
##5.作者简介
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
