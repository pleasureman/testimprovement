#软件测试技术新趋势
“测试已死”的观点在业内仍然存在着争议，很多公司缩减了测试人员，开发测试比屡创新高。本文旨在通过介绍软件测试的新趋势和新技术来展示软件测试行业面临的机遇与挑战，为软件测试工程师的职业规划提供参考。

##安全测试(孙远负责)
从孟加拉国银行8100万美元被黑客成功盗取到美国民主党邮件泄露，网络安全事件已经被推到了风口浪尖。随着物联网逐步普及，智能家居、汽车电子等设备的网络化水平大幅提升。而物联网的安全却不容乐观，很多中小企业往往忽视安全防护。特别是开源软件软件广泛应用的环境下，为网络安全带来了新的挑战。开源软件的源代码公开，黑客可以通过阅读源代码更容易的分析出软件的安全漏洞。当开源社区中发布出cve漏洞时，需要厂商及时的合入补丁，否则将给黑客入侵敞开大门。

新的编程语言的出现在提高了编码效率的同时，也为软件产品增添了安全挑战。Golang语言目前已经被广泛使用，但业界仍然没有针对该语言的扫描工具。
Security Testing needs a solution for IoT progress

The biggest issue in IoT testing continues to be in security testing. IoT testing requires testers to possess additional technical knowledge beyond domain expertise. Testing the interactions between layers—application, middleware, data, etc. – will require some grey box testing approaches. IoT services/APIs are most likely to be virtualized and, in turn, it will help testing to be done effectively. Grow knowledge and skill testing on virtualized environments.

Basic Application Security Testing Becomes Mainstream

Lightweight security tools, particularly dynamic security testing tools, and security testing frameworks (while static analysis tools are used by developers) will gain more popularity (e.g., Nmap for port scanning, sqlmap for SQL injection; Zapr and Arachni for security scanning; ClamAV; bundler-audit, Node, or SafeNuGet for checking external dependencies for known vulnerabilities). Security testing frameworks (e.g., BDD security testing, ATF, OWASP, etc.) will provide a common way to specify and validate security scenarios.

##人工智能
[解析：人工智能对于软件测试产业的影响](http://www.elecfans.com/rengongzhineng/473707.html)
##符号执行

##精准测试(更完整的覆盖率)(孙远负责)

##云化测试

##物联网

##开源测试(1.开源测试工具 2.基于开源软件二次开发的测试)(孙远负责)

##容器化/Devops/微服务(孙远负责)
Containers and Microservices Will Have a Huge Impact on Testing

Containers will help reduce configuration and compatibility testing demand, and microservices will help break testing down into smaller units as test automation continues to Shift-Left* from the UI toward the services/API layer. With the benefits of shifting the testing to the services level, they also come with some new changes. For example, despite the benefits of containers and microservices, configuration/compatibility continues to be a laborious task due to the fact that we have to deal with the permutation of microservices versions currently deployed. When we do integration testing with other services, would we test against the versions of the other services that are currently in production, or against the latest versions of the other services that are not yet in production, or both? The challenges also come with figuring out how to improve reusability of test automation across the different language, technology used in the microservices.
##敏捷、精益(测试前移)(孙远负责)

##客户化测试

##大数据

##自动化测试

##移动互联网测试(孙远负责)
Testing Mobile Applications Continues to Advance

Similar to Application testing in cloud service, Mobile testing is also moving to the cloud but it’s having its own hurdles. While mobile emulator and device clouds (though they can be expensive) help elevate the challenges of having the right mix of devices and configurations available in-house, having the right test environments continue to be problematic. For one, the rapid pace of technology changes and updates force the applications and testing to update even when there is no new feature introduced. Your test automation will also have to be updated accordingly. Furthermore, having the right tools and expertise to test the mix of mobile and variety IoT devices proves to be an on-going difficulty for testing. Functional testing and security testing will continue to be a challenge in testing multi-channel devices (mobile, wearable, social and traditional), and mesh and conversational systems. As mobile apps can be easily constructed using reusable APIs as well as apps can be easily created by citizen developers, there will be more testing demand.

##参考文章

[TOP 10 TESTING TRENDS FOR 2017](http://www.logigear.com/magazine/top-10-testing-trends-for-2017/)

[软件测试的新趋势](http://www.infoq.com/cn/articles/new-trends-of-software-testing)
