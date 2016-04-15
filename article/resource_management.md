#docker资源管理探秘
##1.docker资源管理接口简介
| 选项                     |  描述                                                                                                                                    |
| -------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------- |
| `-m`, `--memory=""`        | 内存使用限制 (format: `<数字>[<单位>]`). 需要使用整数，对应的单位是`b`, `k`, `m`, or `g`.最小取值是4M。              |
| `--memory-swap=""`         | Total memory limit (memory + swap, format: `<number>[<unit>]`). Number is a positive integer. Unit can be one of `b`, `k`, `m`, or `g`.         |
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

    $ docker run -it --memory 100M ubuntu bash -c "cat /sys/fs/cgroup/memory/memory.limit_in_bytes"
    104857600

###(2)--memory-swap=""
###(3)--memory-reservation=""

###(4)--kernel-memory=""

###(5)-c, --cpu-shares=0
###(6)--cpu-period=0
###(7)--cpuset-cpus=""
###(8)--cpuset-mems=""
###(9)--cpu-quota=0
###(10)--blkio-weight=0
###(11)--blkio-weight-device=""
###(12)--device-read-bps=""
    [unicorn@unicorn ~]$ docker run -it --device /dev/sda:/dev/sda --device-read-bps /dev/sda:1mB     rnd-dockerhub.huawei.com/official/ubuntu:stress bash
    root@df1de679fae4:/# dd iflag=direct,nonblock if=/dev/sda of=/dev/null bs=5M count=1
    1+0 records in
    1+0 records out
    5242880 bytes (5.2 MB) copied, 5.00464 s, 1.0 MB/s
    $root@df1de679fae4:/# 
###(13)--device-write-bps=""
###(14)--device-read-iops=""
###(15)--device-write-iops=""
###(16)--oom-kill-disable=false
###(17)--memory-swappiness=""
###(18)--shm-size=""
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
