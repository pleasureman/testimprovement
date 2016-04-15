#docker资源管理探秘
##1.docker资源管理接口简介
##2.cgroups简介
##3.docker资源管理接口详解
###(1)-m, --memory=""
可以限制容器使用的内存量，对应的cgroup文件是cgroup/memory/memory.limit_in_bytes。<br>

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
###(13)--device-write-bps=""
###(14)--device-read-iops=""
###(15)--device-write-iops=""
###(16)--oom-kill-disable=false
###(17)--memory-swappiness=""
###(18)--shm-size=""

##参考资料：
http://www.tuicool.com/articles/zIJrEjn<br>
http://www.cnblogs.com/hustcat/p/3980244.html<br>
http://www.lupaworld.com/article-250948-1.html<br>
http://www.litrin.net/2015/08/14/docker%E5%AE%B9%E5%99%A8%E7%9A%84%E8%B5%84%E6%BA%90%E9%99%90%E5%88%B6/<br>
http://www.tuicool.com/articles/Qrq2Ynz<br>
https://github.com/docker/docker/blob/master/docs/reference/run.md<br>
