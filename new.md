3.6.5	同步与异步任务
如果你通过前端执行control文件，必须指定运行模式。假如当前我们可以使用3台机器。我们可以让他们异步运行，使用autoserv控制每一台机器，对每台机器都使用独立的行，并设置参数SYNC_COUN=1（默认为1），如下：
autoserv control_file -m machine1
autoserv control_file -m machine2
autoserv control_file -m machine3
autoserv control_file -m machine4
当然你也可以使用同步模（此模式需要以下所有机器处于可用状态），如下：
	autoserv control_file -m machine1,machine2,machine3,machine4
		你可能只需要两台机器（一个客户端和一个服务端用于网络测试），不需要等待全部机器可用，此时设置SYNC_COUNT=2，按照以下方式进行：
autoserv control_file -m machine1,machine2
autoserv control_file -m machine3,machine4
