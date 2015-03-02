# setupHadoop
Shell scripts and instructions for setting up Hadoop on a cluster. Intended for use with fresh instances of Ubuntu Server 14.04.1 LTS on Amazon EC2. The instructions below show how to set up a 2 node cluster.

## Creating Instances
First, create two virtual machines using the Amazon Web Interface.

 * Click through Services -> EC2 -> Instances -> Launch Instance.
 * Select "Ubuntu Server 14.04 LTS (HVM), SSD Volume Type".
 * Click "Review and Launch", then click "Launch".
 * On the dialog "Select an existing key pair...", select "Create a new pair"
 * Enter a name for the key pair (I used "cloudTest")
 * Click "Download Key Pair", which will download "cloudTest.pem"
 * Click "Launch Instance"
 * Click "View Instances" to get back to the instances page.
 * Repeat this process a second time, this time using the existing key pair "cloudTest", to create a second instance.

Once you have created two instances, you can name them by clicking on the empty "Name" field. For example, you can name them "Master" and "Slave", to help keep track of which is which. After doing this, you should see a listing like this:

![Instances](http://curran.github.io/images/setupHadoop/instances.png)

## Connecting to an Instance

In a terminal, go to the directory where "cloudTest.pem" is.

`cd ~/Downloads`

Make sure the key file is not visible to others via ssh.

`chmod 400 cloudTest.pem`

If you don't do this, then you'll see this error later:

```
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@         WARNING: UNPROTECTED PRIVATE KEY FILE!          @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
```

Find the public IP of your instance in the AWS Web Interface.

Connect to the instance via SSH using the following command.

`ssh -i cloudTest.pem ubuntu@<your IP here>`

For example,

`ssh -i cloudTest.pem ubuntu@54.67.81.195`

Type "yes" at the prompt `Are you sure you want to continue connecting (yes/no)? yes`

Once logged in, you can check what your Ubuntu version is by running

`lsb_release -a`

## Set Up Hadoop

```
sudo apt-get install -y git \
git clone https://github.com/curran/setupHadoop.git \
cd setupHadoop \
chmod +x installHadoop.sh \
./installHadoop.sh
```

Allow all traffic into the master node by scrolling to the right in the AWS instance listing page, clicking the link in the "Security Groups" column -> "Inbound" tab -> "Edit" button -> "Add Rule" button -> change "Custom TCP Rule" to "All TCP" -> "Save" button

# Setting up a cluster

One might think that the simplest approach to setting up a cluster is to first set up many machines as independent single-node Hadoop clusters, make sure each one is working individually, then shut them all down, reconfigure them such that one is a master and the others are slaves, then restart the cluster. Note that you "start the cluster" by starting HDFS and YARN from the _master node only_. The master node will connect to slave nodes via SSH and start the appropriate processes on each, namely DataNode for HDFS and ResourceManager for YARN.

Once you have set up many single-node clusters, shut them all down by running `stop-dfs.sh` on each machine. The output should look like this:

```
$ stop-dfs.sh
Stopping namenodes on [localhost]
localhost: stopping namenode
localhost: stopping datanode
Stopping secondary namenodes
```

Since the master needs to communicate to slaves over SSH, we need to add the public key of the master machine to the list of allowed hosts in the slave machine(s). To do this:

 * Log into the master node over SSH
 * Execute `cat ~/.ssh/id_rsa.pub`
 * Copy the output to the clipboard
 * Log into the slave node over SSH
 * Edit the file `~/.ssh/authorized_keys`
 * Paste the contents of the clipboard into a new line of the file
 * Save and close the file

## Getting HDFS to work on a cluster

Choose a single machine to be the master node for HDFS, which will run the NameNode daemon. All other machines will be slaves, and will run the DataNode daemon.

To set up a slave machine, do the following:

Edit the file `/usr/local/hadoop/etc/hadoop/core-site.xml`. Change the `fs.defaultFS` value to use the IP of the master node (found using `ifconfig` ran on the master node). This IP is also listed in the Amazon Web Interface, called "Private IP".

The file should look something like this:
```
<configuration>
  <property>
    <name>fs.default.name</name>
    <value>hdfs://52.11.95.33:9000</value>
  </property>
</configuration>
```

## Control Hadoop

The following commands are defined in `/usr/local/hadoop/bin` and `/usr/local/hadoop/sbin`. They are available as commands to execute because these paths were added to `$PATH` by `setupHadoop.sh`.

Format the file system.

`hdfs namenode -format` WARNING - if you want to set up a cluster, make sure all configurations are set before executing this. If this is executed with config for a single machine, then it seems to break the state of the system and you cannot get the full cluster working.

`start-dfs.sh` Start HDFS. This will launch the NameNode and DataNode Hadoop daemons.
`stop-dfs.sh` Stop HDFS.

You can always check to see which daemons are running by executing `jps`. The output will look something like this:

```
$ jps
11296 NameNode
11453 DataNode
11768 Jps
```

Now you should see the following page on port `50070` of your master node:

![workingHDFS](http://curran.github.io/images/setupHadoop/workingHDFS.png)
A working HDFS cluster with 2 DataNodes. (on port `50070`)


To get YARN working, edit the file `/usr/local/hadoop/etc/hadoop/yarn-site.xml` to set the IP of the Resource Manager. In my case this is the same as the HDFS name node.
```
<configuration>
  <property>
    <name>yarn.resourcemanager.hostname</name>
    <value>52.11.95.33</value>
  </property>
</configuration>
```

![workingYARN](http://curran.github.io/images/setupHadoop/workingYARN.png)
A working YARN cluster with 2 NodeManagers. (on port `8088`)

Draws from

 * https://www.digitalocean.com/community/tutorials/how-to-install-hadoop-on-ubuntu-13-10
 * http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/ClusterSetup.html
 * http://hadoop.apache.org/docs/current/hadoop-project-dist/hadoop-common/SingleCluster.html
 * http://www.alexjf.net/blog/distributed-systems/hadoop-yarn-installation-definitive-guide/
 * https://help.ubuntu.com/community/CheckingYourUbuntuVersion
 * http://www.michael-noll.com/tutorials/running-hadoop-on-ubuntu-linux-multi-node-cluster/
 * https://www.youtube.com/watch?v=3rb111Z9TVI

By Curran Kelleher March 2015
