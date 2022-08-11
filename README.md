## Configure Hadoop YARN CapacityScheduler on Amazon EMR on Amazon EC2 for multi-tenant heterogeneous workloads

The repository creates [Amazon EMR](https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-what-is-emr.html) cluster and configures [Apache Hadoop YARN CapacityScheduler](https://hadoop.apache.org/docs/stable/hadoop-yarn/hadoop-yarn-site/CapacityScheduler.html). Please refer to the AWS big data blog post [Configure Hadoop YARN CapacityScheduler on Amazon EMR on Amazon EC2 for multi-tenant heterogeneous workloads](https://aws.amazon.com/blogs/big-data/configure-hadoop-yarn-capacityscheduler-on-amazon-emr-on-amazon-ec2-for-multi-tenant-heterogeneous-workloads) for details.

## Folder structure

| Folder/File                               | Description                                                                                                  |
| :-----------------------------------------|:-------------------------------------------------------------------------------------------------------------|
cloudformation/templates/main.yaml          | AWS CloudFormation template to create Amazon EMR YARN configurations                                         |
cloudformation/templates/emr.yaml           | AWS CloudFormation template to create Amazon EMR cluster                                                     |
cloudformation/templates/vpc.yaml           | AWS CloudFormation template to create Amazon VPC , Subnets and other resources needed for Amazon EMR cluster |
cloudformation/parameters/parameters.json   | Parameters files for the AWS CloudFormation template                                                         |
scripts/create_users.sh                     | Unix Shell script for creating users                                                                         |
CODE_OF_CONDUCT.md                          | Code Of Conduct                                                                                              |
CONTRIBUTING.md                             | Contributing                                                                                                 |
LICENSE                                     | License                                                                                                      |

## Prerequisites

- An AWS account
- The [AWS Command Line Interface](http://aws.amazon.com/cli) (AWS CLI) [installed](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html). You are able to run commands such as ```aws s3 ls``` from the terminal.
- The [GIT Command Line Interface](https://github.com/git-guides) (GIT CLI) [installed](https://github.com/git-guides/install-git).
- Permission to create AWS resources.
- Familiarity with [AWS CloudFormation](http://aws.amazon.com/cloudformation) and [Amazon EMR](https://aws.amazon.com/emr/).

## Getting started

Please follow the below instructions to deploy the solution in your AWS account. 

### Clone the GitHub repo

```
git clone git@github.com:aws-samples/amazon-emr-yarn-capacity-scheduler.git
```

### Create Amazon S3 bucket

```
aws s3api create-bucket --bucket emr-yarn-capacity-scheduler-<AWS_ACCOUNT_ID>-<AWS_REGION> --region <AWS_REGION>
```

### Copy the GitHub repo to Amazon S3 bucket

```
aws s3 cp --recursive amazon-emr-yarn-capacity-scheduler s3://emr-yarn-capacity-scheduler-<AWS_ACCOUNT_ID>-<AWS_REGION>/
```

### Update the ```emr-yarn-capacity-scheduler/cloudformation/parameters/parameters.json``` file with approproate values

Please update the values for the following keys:

| Key                   | Description                                                                                                                                                                                                                             |
| :---------------------|:----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
ArtifactsS3Repository   | The Amazon S3 bucket name created in the previous step.                                                                                                                                                                                 |
emrKeyName              | An existing EC2 key name. If you don’t have an existing key and want to create a new key, refer to [Use an Amazon EC2 key pair for SSH credentials](https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-plan-access-ssh.html).   | 
clientCIDR              | The CIDR range of the client machine for accessing the EMR cluster via SSH. You can run the following command to identify the IP of the client machine: ```echo "$(curl -s http://checkip.amazonaws.com)/32"```                         |

We have provided sensible defaults whereever possible. Please update the values to fit your specific requirements.

### Deploy the AWS CloudFormation templates

```
aws cloudformation create-stack \
--stack-name emr-yarn-capacity-scheduler \
--template-url https://emr-yarn-capacity-scheduler-<AWS_ACCOUNT_ID>-<AWS_REGION>.s3.amazonaws.com/cloudformation/templates/main.yaml \
--parameters file://emr-yarn-capacity-scheduler/cloudformation/parameters/parameters.json \
--capabilities CAPABILITY_NAMED_IAM \
--region <AWS_REGION>
```

### Navigate to AWS Management Console > CloudFormation and check for the successful deployment of the following stacks
![Alt text](images/cloudformation-stack.png?raw=true "CloudFormation Deployment")

### AWS Management Console > EMR and check for the successful creation of emr-cluster-capacity-scheduler cluster

![Alt text](images/emr-capacity-scheduler-config.png?raw=true "EMR Capacity Scheduler Configs")

### To review the CapacityScheduler setup, access the Apache Hadoop YARN Resource Manager UI on the emr-cluster-capacity-scheduler cluster 
For instructions on how to access the UI on Amazon EMR, refer to [View web interfaces hosted on Amazon EMR clusters](https://docs.aws.amazon.com/emr/latest/ManagementGuide/emr-web-interfaces.html).

![Alt text](images/yarn-ui.png?raw=true "Yarn UI")


### To verify Capacity Scheduler configurations, ```SSH``` into the EMR primary node, ```sudo``` as different users and submit Apache Spark jobs :

```
[hadoop@ip-xx-x-xx-xxx ~]$ sudo su - user1
[user1@ip-xx-x-xx-xxx ~]$ spark-submit --master yarn --deploy-mode cluster --class org.apache.spark.examples.SparkPi /usr/lib/spark/examples/jars/spark-examples.jar
```

![Alt text](images/yarn-ui-jobs.png?raw=true "Yarn UI Job Execution")


### To test the Access Control List (ACL) in CapacityScheduler queues, submit jobs to unauthorized queues. 

```
[hadoop@ip-xx-x-xx-xxx ~]$ sudo su - user3
spark-submit --master yarn --deploy-mode cluster --queue adhoc --class org.apache.spark.examples.SparkPi /usr/lib/spark/examples/jars/spark-examples.jar
```

User should see errors like below:

```
22/07/31 18:23:41 INFO Client: Submitting application application_1659289766681_0011 to ResourceManager
22/07/31 18:23:41 INFO Client: Deleted staging directory hdfs://ip-10-0-10-117.ec2.internal:8020/user/user3/.sparkStaging/application_1659289766681_0011
Exception in thread "main" org.apache.hadoop.yarn.exceptions.YarnException: org.apache.hadoop.security.AccessControlException: User user3 does not have permission to submit application_1659289766681_0011 to queue adhoc
```

## Cleanup

- Delete the cloudformation stack

```
aws cloudformation  delete-stack --stack-name emr-yarn-capacity-scheduler

```

- Delete the Amazon S3 bucket

Please verify before runing the command. The command deletes the bucket and all files underneath it. The files may not be recoverable after delete.

```
aws s3 rb s3://emr-yarn-capacity-scheduler-<AWS_ACCOUNT_ID>-<AWS_REGION> --force
```

## Contributing

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

See the [LICENSE](/LICENSE) for more information.
