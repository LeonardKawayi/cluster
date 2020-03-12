elastic-job-lite 简介
elastic-job 是当当网开源的分布式任务调度系统，基于 quartz 二次开发实现的，由两个相互独立的子项目 Elastic-Job-Lite 和 Elastic-Job-Cloud 组成。

前者主要定位为轻量级，去中心化的的分布式任务调度解决方案，是以 jar 包的形式提供，后者采用自研 Mesos Framework 的解决方案，额外提供资源治理、应用分发以及进程隔离等功能，

我们今天主要说的是 elastic-job-lite，cloud 放在下一期讲解，目前最新版本是 3.0.0.M1-SNAPSHOT，已经停止更新了

但是使用的人，公司和教程还是很多的，遇到问题基本通过搜索可以解决的，解决不了的可以研究源码（还是相对比较好理解的）可以放心的使用。

elastic-job-lite 架构
elastic-job-lite 轻量级的，去中心化的，上面说过他是基于 quartz 的，所以他的调度由使用其 jar 的项目驱动的，引入了 zookeeper 和分片的概念的为多台机器调度提供了协调和并行，并且配备一个运维端来管理 job

elastic-job-lite 架构图如下：

![image-20200312170044836](/Users/zhangzhenkun/Library/Application Support/typora-user-images/image-20200312170044836.png)

从上图我们可以看出，elastic-job-lite 是以 zookeeper 作为注册中心的，console 作为控制台和服务端解构，直接操纵 zk 改变 job 的配置信息，服务端启动时连接 zk，注册 job，初始化 Scheuler, 进行 leader 选举，分片，然后按照 job 配置信息调度作业，支持作业执行中的监控，event 发送，失败转移等

elastic-job-lite 部署图如下：

![image-20200312170058306](/Users/zhangzhenkun/Library/Application Support/typora-user-images/image-20200312170058306.png)

elastic-web 控制台部署一台机器（也只能部署一台，有点坑），原因是 elsatic-web 通过界面添加 zk 的地址，写入本台机器文件中，这是有状态的，如果部署多台，负载均衡后，你再页面看到的信息多次访问后会不一致，因为会调用到不同的机器上，看下面的图，就理解了，如果想要多台做负载均衡，做 HA，需要对这块做二次开发。（一般小公司一台足够了，web 没什么压力）

elastic-job-lite 使用
elastic-job-lite 入门使用
首先准备好 zk 集群，elastic-job-lite 使用 zk 作为注册中心，其次在自己的项目中引入 maven 依赖

<dependency> 
    <groupId>com.dangdang</groupId> 
    <artifactId>elastic-job-lite-core</artifactId> 
    <version>3.0.0.M1-SNAPSHOT</version> 
</dependency>
elastic-job-lite 支持三种作业类型，我们可以根据自己的业务需求选择合适作业类型

io.elasticjob.lite.api.simple.SimpleJob 实现此接口代表这个作业时简单累型作业
io.elasticjob.lite.api.dataflow.DataflowJob 实现此接口代表这个作业是支持流处理的作业
io.elasticjob.lite.api.script.ScriptJob 实现此接口代表这个作业是一个脚本作业

我们分析上面类图:

![image-20200312170137105](/Users/zhangzhenkun/Library/Application Support/typora-user-images/image-20200312170137105.png)

JobCoreConfiguration 类定义了 job 作业核心配置属性
JobTypeConfiguration, Job 类型的配置接口，有三个实现类，对应上面三种类型的作业，JobTypeConfiguration 接口定义了获取 JobCoreConfiguration 类的方法
JobRootConfiguration, Job 跟配置接口，定义了获取 JobTypeConfiguration 实现类的方法
LiteJobConfiguration 类实现了 JobRootConfiguration 接口
接下来我们分析这写类中定义的 job 配置属性，我整理完成后截图如下：

![image-20200312170234856](/Users/zhangzhenkun/Library/Application Support/typora-user-images/image-20200312170234856.png)



elastic-job-lite 任务执行架构图



在 elastic-job-lite 中，由调度器统一调度 job，每种类型的 job 都对应一个调度器（目前调度器只有一种实现 SpringJobScheduler），准备说是一个 job 对应一个 scheduler，每种类型的 job 执行方法不一样，Simple 类型通过执行 execute 方法，方法入参会携带分片参数决定当前机器处理那些分片的数据，DataFlow 类型执行 fetch 方法，也是携带分片参数抓取属于当前机器处理的数据交给 execute 方法执行，Script 类型是通过触发一个脚本来执行脚本中的业务逻辑，这个脚本可以是 window 下的.exe 文件，也可以是 python 等文件
elastic-job-lite 的作业执行流程图

![image-20200312170303235](/Users/zhangzhenkun/Library/Application Support/typora-user-images/image-20200312170303235.png)

上图详细描述 elastic-job-lite 中一个任务的执行流程，从 quartz 中一个 job 运行线程开始，调用 LiteJob 的 execute 方法，紧接着根据 job 的类型创建 JobExecutor，开始执行 jobExecutor，根据模板设计模式，父类 AbstractExecutor 规定了 job 的执行流程，子类重写了具体不同 job 类型执行时的同逻辑。

描述一下各个方法的作用

checkJobExecutionEnvironment 检查作业运行环境
getShardingContext 获取作业的分片的上下文
postJobStatusTraceEvent 发送作业状态跟踪时间
misfireRunning 错过执行检查和设置
beforeJobExecuted 作业执行前监听器执行
execute 执行作业
isExecuteMisfired 是否执行错过执行
failoverIfNecessary 失效转移是否执行
afterJobExecuted 作业执行后监听器执行
elastic-job-lite 启动流程

![image-20200312170314453](/Users/zhangzhenkun/Library/Application Support/typora-user-images/image-20200312170314453.png)

首先启动连接注册中心 k，并且进行初始化，创建 zk 客户端，接着作业调度器 JobScheduler, 执行调度器的 init 方法，在 init 方法中做如下事情

往注册中心更新 jobConfig
创建 job 调取器控制中心
注册 job
注册 job 启动信息，这一步里面又做了很多事情，开启关于 job 的 zk 监听器，主节点选举，持久化作业服务器上线信息，持久化作业运行实例信息，设置重新分片的标记，初始化作业监听服务，启动调解分布式作业不一致状态服务
elastic-job-lite 优缺点
从上面的分析我想大家已经能得出一些 elastic-job-lite 的一些利弊信息了，这里我在归纳总结一下，
优点

轻量级，简单，依赖少，只需一个 zk 就可以使用起来
支持多种作业类型，分片，失效转移，错过执行，动态新增，删除节点
简单的可视化管理
方便和 spring 整合，springboot 整合
缺点

占用业务机器资源，资源调度和业务执行没有解耦
zk 作为注册中心不友好，不支持高可用
不支持复杂的作业管理（作业依赖），一些复杂业务场景不可使用
可视化相对简单，作业监控也比较简单
对单次执行不太友好