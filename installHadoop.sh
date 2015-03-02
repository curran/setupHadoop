#!/bin/bash

# This script will install Hadoop.

sudo apt-get update
sudo apt-get install -y default-jdk

# To check what your Java version is, you can run
# java -version

# Set up SSH keys for Hadoop to use.
ssh-keygen -t rsa -P '' -f ~/.ssh/id_dsa
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys

# Fetch and unzip Hadoop.
curl -O http://mirror.cogentco.com/pub/apache/hadoop/common/hadoop-2.6.0/hadoop-2.6.0.tar.gz
tar xfz hadoop-2.6.0.tar.gz
sudo mv hadoop-2.6.0 /usr/local/hadoop
rm hadoop-2.6.0.tar.gz

# Set up environment variables.
echo export JAVA_HOME=/usr/lib/jvm/java-7-openjdk-amd64 >> ~/.bashrc
echo export HADOOP_PREFIX=/usr/local/hadoop >> ~/.bashrc
echo export PATH=\$PATH:/usr/local/hadoop/bin >> ~/.bashrc
echo export PATH=\$PATH:/usr/local/hadoop/sbin >> ~/.bashrc

# This will be required in the parent shell
source ~/.bashrc

# Copy config files into Hadoop directory.
cp -r master/* /usr/local/hadoop/etc/hadoop/
