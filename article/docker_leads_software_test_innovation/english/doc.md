# Docker leads software test innovation
While Docker is accepted by more and more people, it is applied `more and more` widely. This paper would introduce the effect of Docker on software testing technology from testing type, Devops, test automation, test scenarios, test practice and so on. I assume that readers have known Docker and its dependency on core technology of kernel. If you don't know much of it, read [docker document](https://docs.docker.com/) in advance.

## 1.Pain points of traditional software development progress
In traditional software development progress before Devops, developers do code and self-test at first. Then the codes will be pushed into git repository. Develpers will build software code to create binary files before each test iteration. Tester will test and verify this iteration. After the verification is pass, it is released to operation team. Operators would deploy the release in servers for customers.

In this process, pain points are as follow:

(1)Different environment among development, test, operation teams

In this situation, some bugs, which should have been found in development phase, can't be found till test phase or operation phase. Sometimes software works fine in development environment. However, it is down once it is deployed in operation phase. At this time, the operation team had to resort to development team, leading to a decline in the efficiency of the entire team.

(2)Can't accurately obtain the software environment of customers.
 
We often can't reproduce the defects costomers submit and have to debug on costomers' site.

(3) Developers don't tend to execute enough test cases before codes are pushed.

The self test task is dependent on developers' responsibility. Because there is no process to ensure that the self test task is complete. This leads to the fact that some low level software defects are left to test team and operation team.

(4)Developers fail to reproduce the defects testers submit, which leads to buckpassing between the two teams.

(5)Have to spend too much time in setting up test environment; The cost of automation test is high.

We often use VM to set up traditional engineering environment. VM's resource consumption is high and its development speed is slow. Automation efficiency is not high.

## 2. Current changlleges in test technoloy domain
The above pain points make test technology face some changllege. They include, but are not limited to the following.<br>
(1)set up consistent test environment<br>
(2)deploy software quickly<br>
(3)Execute test in parallel and ensure that test environment isn't contaminated.<br>
(4)Reproduce software defects successfully.<br>
(5)Create clean test environment.<br>
(6)Set up test tools correctly. Need to set up a tool in different linux distributions.<br>
(7)Deploy some test hosts quickly.<br>
(8)Import test data quickly.<br>
(9)Clean up test environment quickly.<br>
(10)Save, copy, and restore test environment quickly.<br>

##3.Docker对测试技术的革命性影响
测试技术面临的挑战一度成为了制约项目效率提升的瓶颈。然而，随着Docker容器技术的出现，早先很多棘手的挑战可以迎刃而解了。利用Docker生态中的工具可以有效的支撑软件测试活动的进行。具体体现在如下方面：<br>
(1)更早的发现单元测试中的软件缺陷。<br>
测试驱动开发是软件工程中一个具有里程碑意义的创新，即开发者在提交开发代码的同时也要提供对应的测试代码，在代码提交后系统会自动进行一轮自动化测试。通过Docker可以快速部署测试环境，可以有力的支撑自动化测试，从而确保在第一时间发现单元测试中的软件缺陷。<br>
(2)为功能测试和集成测试提供清洁的测试环境。<br>
很多公司由于成本问题，不得不在一个虚拟机中运行不同类型的测试任务。而这些任务在运行时往往会导致环境污染。通过Docker技术的隔离性，可以有效地解决测试环境的污染问题。<br>
(3)让测试团队和客户丢掉冗长的配置文档。<br>
开发转测试时往往带有较长的环境部署文档，而在这些文档中往往存在部署过程跳步的问题，测试团队很难一次准确的将环境部署成功。而现在可以通过Docker镜像将配置环境的过程简化，测试团队省去了查阅文档的过程，只需要基于开发团队提供的Docker镜像就可以轻松的配置测试环境。<br>
(4)便于复现客户报告的软件缺陷。<br>
当客户使用软件发现缺陷时，可以将其所使用的环境打包成镜像提供给开发团队。开发团队通过镜像即可获取与客户一致的软件环境。<br>
(5)通过Dockerfile可以梳理好测试镜像制作的流程。<br>
如果流程步骤需要微调时(如将安装gcc3.4改为安装gcc4.3)，可以将Dockerfile中对应的信息进行修改并重新创建新的镜像，不必手动重新配置运行环境。<br>
(6)可以将成熟的测试套或测试工具通过镜像共享。<br>
这样可以支持软件在不同linux发行版中成功的运行，软件提供商可以将主要精力放在完善功能上，不必投入过多时间将软件适配到不同的linux发行版中。<br>
(7)利用Docker生态中的工具可以快速创建可伸缩的测试环境，大大减少了测试所消耗的时间。<br>
可以在短时间内快速集中资源来完成一项测试任务，在任务完成后又可以快速的对资源进行回收，有利于提升资源使用效率。<br>
(8)优越的性能指标。<br>
通过优于虚拟机的性能，Docker可以提升测试效率。通过“-v”选项可以将主机的目录快速映射到容器中，可以实现测试文件的快速共享。通过“--rm”选项可以在测试完成后第一时间删除容器，以便释放系统资源。<br>
(9)轻松的恢复测试环境（包括内存）-CRIU技术 Checkpoint Restore In Userspace<br>
结合CRIU技术，可以实现容器运行状态的保存，这项技术也是容器热迁移的基础。<br>

##4.Devops与Docker
DevOps一词的来自于Development和Operations的组合，突出重视软件开发人员和运维人员的沟通合作，通过自动化流程来使得软件构建、测试、发布更加快捷、频繁和可靠。<br>
![Predevops](images/1.png "Predevops_png")

在Devops出现之前，软件经过开发、测试后由运维团队将发布件部署到公司的基础设施上，并将服务提供给客户使用。然而，开发、测试、运维三个团队缺少有效协同工作的机制，导致部门墙严重。开发团队往往关注新功能开发和快速迭代，而运维团队关注的是发布件的稳定性，他们不希望版本频繁的更替。往往在这两个团队间会爆发激烈的斗争。<br>
![Devops](images/2.png "Devops_png")

在Devops出现之后，团队通过协作和自动化的方式打通了开发、测试、运维团队之间的壁垒。当有新的代码提交时，系统在第一时间会触发自动化测试，依次在开发自验环境、测试环境、运维环境中验证软件，确保可以第一时间发现软件缺陷。然而，当出现业务峰值时，传统的基础设施中的虚拟机就无法有效的应对了。<br>
![Devops](images/3.png "Postdevops_png")

后Devops时代指的是Devops已经和Docker充分的融合在一起应用的时代。在这个时代中，可以使用Docker来屏蔽不同平台的差异，同时使用Docker镜像作为标准的交付件，可在开发、测试和运维环境中启动Docker容器来运行业务，来确保三套环境上的应用以及运行所依赖内容的一致性。随着云计算的普及，很多云平台提供了应用引擎，如果你的应用符合引擎的规范，云平台就可以自动检测业务负载量。当业务出现峰值时，平台可以利用的Docker容器技术的快速部署、资源快速扩展伸缩等特性来应对，从而有效的支撑了业务的正常运行。<br>

##5.Docker与自动化测试
对于重复枯燥的手动测试任务，可以考虑将其进行自动化改造。自动化的成本在于自动化程序的编写和维护，而收益在于节省了手动执行用例的时间。简而言之，如果收益大于成本，测试任务就有价值自动化，否则受益的只是测试人员的自动化技能得到了提升。利用Docker的快速部署、环境共享等特性，可以大大减少自动化的成本，使很多原本没有价值自动化的测试任务变为了有价值自动化的任务，大大提升了项目效率。<br>
那么如果自动化测试已经运行在了虚拟机中，是否有必要使用Docker技术将其进行改造？这个就要具体问题具体分析了。笔者并不赞同将所有测试任务一刀切的进行容器化改造。如果当前虚拟机已经满足测试需求，你就需要评估一下引入Docker进行改造所需的成本，其中包含学习Docker技术所需要的时间成本。反之，如果虚拟机无法满足当前的测试需求，可以考虑尽快引入Docker进行改造。<br>

##6.Docker的约束
Build, Ship, and Run Any App, Anywhere.这是Docker公司高调宣称的口号，即在任何平台都可以构建、部署、运行任何应用。然而，由于Docker自身的特点，其使用场景有一些约束：<br>
(1)因为容器与主机共享内核，如果容器中应用需要不同的内核版本，就不得不更换主机内核。但如果主机内核变更后又会影响到其它容器的运行。变通的方法是将应用源码的编写与内核特性解耦。<br>
(2)Docker使用时需要3.10或以上版本的内核，这是最低的限制。如果你需要使用更高级的Docker特性，如user namespace，那么还需要更高版本的内核。<br>
(3)使用“--privileged”选项后可以在容器内加载或卸载内核模块，但这个操作会影响到主机和其它容器。<br>
(4)无法模拟不同平台的运行环境，例如不能在x86系统中启动arm64的容器。<br>
(5)因为Docker采用了namespace的方案来实现隔离，而这种隔离属于软件隔离，安全性不高。不适合安全性高的测试任务。
(6)因为目前没有time namespace技术，修改某个容器时间时就不得不影响到主机和其它容器。

##7.适用于Docker的测试场景
由于容器与主机共享内核使用，凡是和内核无强相关的测试任务是适合引入Docker进行改造的，例如源码编译测试、软件安装测试、互联网应用测试、数据库测试等。而与内核强相关的测试任务是不适合使用Docker进行改造的，如内核网络模块测试、内核namespace特性测试等。

##8.Docker测试实践
###8.1.容器化编译系统测试
![Compilingtest1](images/4.png "Compilingtest1_png")

早期我们将linux发行版安装到物理机中进行测试。当需要重新进行全量测试时不得不手动还原测试环境。之后改用了虚拟机，虽然能够通过自动化的方式实现环境还原，但虚拟机的损耗较大，效率不高。<br>
![Compilingtest2](images/5.png "Compilingtest2_png")

之后我们尝试将环境制作成Docker镜像，同时进行了如下的改进：<br>
(1)通过Docker的“-v”选项，将主机目录映射到容器中，实现多个容器共享测试代码。测试代码部署时间从2分钟减少到10秒。<br>
(2)将大粒度的执行时间较长的用例拆分成为若干个小用例。<br>
(3)利用容器并发执行测试。<br>
(4)使用Dockerfile梳理产品依赖包和编译软件的安装。<br>
编译系统测试是用户态的测试，非常适合使用Docker进行加速。如果需要针对某一个linux发行版进行测试，可以通过Docker快速部署的特点，将所有的资源快速利用起来，从而达到加速测试执行的目的。<br>

###8.2.linux外围包测试
![Packagetest1](images/6.png "Packagetest1_png")

外围包包含动态链接库文件和常用的命令行工具，属于linux操作系统的中间层，其上运行着应用程序，其下由linux内核支撑。起初的外围包测试采用串行执行，效率不高。同时受到环境污染的影响，容易产生软件缺陷的误报。在改进方面，我们首先通过Dockerfile基于rootfs制作一个Docker镜像，然后通过Docker-compose工具实现测试用例的并发执行。<br>
![Packagetest2](images/7.png "Packagetest2_png")

以下是改进前后的对比。<br>

| 改进前                                       | 改进后                                       |
| ---------------------------------------- | ---------------------------------------- |
|每套环境独占一台主机，主机利用率不高。|多套环境可以在同一主机上部署，可以更有效利用主机资源。特别是在主机资源昂贵的情况下，可以节省很多成本。|
|测试串行执行，因为环境污染问题测试任务不易并发。|通过Docker进行测试任务隔离，可以并行执行测试，提高了cpu利用率。 |
|环境释放时清理工作依赖于程序员的技能。在每个测试用例中有一个cleanup函数，负责资源回收和环境恢复。如果程序员编程技巧不高的话，可能会造成资源回收不彻底，测试环境会受到污染。|环境释放时清理工作由Docker接管，当执行完任务后，可以删除容器。即使不写cleanup函数，也可以实现资源的回收。|
|无法解决多个外围包的环境污染问题。当连续执行多个测试时，有部分测试无法通过，而单独执行这些测试时又能够通过。这通常是由于测试环境污染造成的。 |容器可快速启动与关闭，每次都是清洁的环境。 |
|外围包编译环境不易统一，导致测试结果不一致。 |通过镜像保存编译环境，确保环境统一。 |
|测试网络包时需要至少两台主机，分别部署服务端和客户端。|测试网络包时只需要在同一台主机中启动两个容器来部署服务端和客户端。|

##9.通过Docker进行测试加速的原理
Docker本身并不会直接加速测试执行。在串行执行测试时，在容器中执行测试反而会带来约5%左右的性能衰减。但我们可以充分利用Docker快速部署、环境共享等特性，同时配合容器云来快速提供所需的测试资源，以应对测试任务的峰值。如果忽略环境部署时间，当每个测试用例粒度无限小并且提供的测试资源无限多时，测试执行所需的时间也就无限小。

##10.总结
很多测试任务可以利用Docker进行改造，读者可以根据项目自身的特点，因地制宜的使用Docker进行测试能力的改造。如果想进一步了解容器云，可以参考[《网易云的实践之路：谈谈容器云的机会与挑战》](http://www.infoq.com/cn/articles/opportunities-and-challenges-for-container-clouds)这篇文章。

##作者简介
孙远，华为中央软件研究院资深工程师，硕士毕业，9年软件行业经验。目前在华为从事容器Docker项目的测试工作。工作涉及到功能测试、性能测试、压力测试、稳定性测试、安全测试、测试管理、工程能力构建等内容。参与编写了《Docker进阶与实战》的Docker测试章节。先前曾经就职于美国风河系统公司，作为team lead从事风河Linux产品测试工作。活跃于Docker社区和内核测试ltp社区，目前有大量测试用例被开源社区接收。<br>
研究方向：容器技术、Docker、Linux内核、软件测试、自动化测试、测试过程改进<br>
公司邮箱：sunyuan3@huawei.com<br>
个人邮箱：yuan.sun82@gmail.com<br>
