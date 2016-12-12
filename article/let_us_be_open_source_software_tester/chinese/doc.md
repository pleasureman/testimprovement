# 让我们成为开源软件测试者
## 1.开源测试工具概况
以测试管理、缺陷管理、持续集成、功能测试、性能测试、测试框架、测试设计、安全测试作为分类来介绍开源测试工具的现状。<br>
测试管理： TestLink, Testopia<br>
缺陷管理：Redmine, Bugzilla, Mantis<br>
持续集成：Jenkins<br>
功能测试：selenium, LTP (Linux Test Project)<br>
性能测试：lmbench, sysbench, iperf, fio<br>
测试框架：<br>
测试设计：xmind<br>
安全测试：Metasploit<br>
## 2.当前开源社区测试能力的短板
以kernel和docker社区为例展示目前开源社区中测试能力的短板。<br>
kernel:测试用例和文档添加不及时；往往功能代码合入内核主线一年以后开源社区仍然没有对应的测试用例。<br>
docker:虽然社区采用测试驱动开发的方式，但测试用例由于是开发者编写的，测试缺少测试思维和边界异常点检查。而且用例往往只是功能验证，无法覆盖全面的代码路径，更缺少一些专项测试（性能测试、压力测试、长稳测试、安全测试等）。<br>


User namespace support completed 2013年2月18日<br>
https://kernelnewbies.org/Linux_3.8<br>
userns01:2015年5月21日<br>


Cgroup namespace CLONE_NEWCGROUP 2016年5月15日<br>
https://kernelnewbies.org/Linux_4.6<br>
在ltp中无用例<br>

## 3.专业测试人员参与开源社区贡献的必要性
从心理学的角度来看，开发者不愿意看到自己编写的代码存在缺陷。由于项目时间紧急，即使发现了自己代码存在缺陷，往往也不会告知测试，通常会默默的祈祷测试不要发现该缺陷。<br>
补充专项测试（性能、长稳、安全、异常边界、安全）<br>
## 4.测试工程师参与开源社区的方式
(1)添加测试用例

(2)书写或补充文档

添加例子

(3)修改软件缺陷

(4)测试待发布版本

(5)补充专项测试方案

(6)回答社区中的问题

## 总结


## 作者简介
孙远，资深工程师，就职于华为2012实验室中央软件院欧拉八部，硕士毕业，9年软件行业经验。目前在华为从事容器Docker项目的测试工作。工作涉及到功能测试、性能测试、压力测试、稳定性测试、安全测试、测试管理、工程能力构建等内容。参与编写了《Docker进阶与实战》的Docker测试章节。先前曾经就职于美国风河系统公司，作为team lead从事风河Linux产品测试工作。活跃于Docker社区和内核测试ltp社区，目前有大量测试用例被开源社区接收。<br>
研究方向：容器技术、Docker、Linux内核、软件测试、自动化测试、测试过程改进<br>
## 参考文章
https://kernelnewbies.org/Linux_3.8<br>
https://kernelnewbies.org/Linux_4.6<br>
http://www.infoworld.com/article/2860074/open-source-software/become-an-open-source-software-tester.html<br>



