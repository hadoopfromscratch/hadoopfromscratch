#!/bin/bash

YOUR_FQDN=localhost

yum -y install wget gcc gcc-c++ autoconf automake libtool zlib-devel cmake openssl openssl-devel snappy snappy-devel bzip2 bzip2-devel protobuf protobuf-devel

wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u102-b14/jdk-8u102-linux-x64.tar.gz
tar xvf ~/jdk-8u102-linux-x64.tar.gz
mv ~/jdk1.8.0_102 /opt/java
echo "PATH=\"/opt/java/bin:\$PATH\"" >> ~/.bashrc
echo "export JAVA_HOME=\"/opt/java\"" >> ~/.bashrc

wget http://apache.rediris.es/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz
tar xvf ~/apache-maven-3.3.9-bin.tar.gz
mv ~/apache-maven-3.3.9 ~/maven
echo "PATH=\"/root/maven/bin:\$PATH\"" >> ~/.bashrc
source ~/.bashrc

wget http://apache.uvigo.es//ant/binaries/apache-ant-1.9.7-bin.tar.bz2
tar -xvf ~/apache-ant-1.9.7-bin.tar.bz2
mv ~/apache-ant-1.9.7 ~/ant
echo "PATH=\"/root/ant/bin:\$PATH\"" >> ~/.bashrc
source ~/.bashrc

wget http://apache.rediris.es/hadoop/common/hadoop-2.7.3/hadoop-2.7.3-src.tar.gz
tar -xvf ~/hadoop-2.7.3-src.tar.gz
mv ~/hadoop-2.7.3-src ~/hadoop-src
cd ~/hadoop-src
mvn package -Pdist,native -DskipTests -Dtar
tar -C/opt -xvf ~/hadoop-src/hadoop-dist/target/hadoop-2.7.3.tar.gz
mv /opt/hadoop-* /opt/hadoop
echo "PATH=\"/opt/hadoop/bin:\$PATH\"" >> ~/.bashrc
source ~/.bashrc

sed -i '1iJAVA_HOME=/opt/java' /opt/hadoop/etc/hadoop/hadoop-env.sh
sed -i '1iJAVA_HOME=/opt/java' /opt/hadoop/etc/hadoop/yarn-env.sh

cat << EOF > /opt/hadoop/etc/hadoop/core-site.xml
<configuration>
  <property><name>fs.defaultFS</name><value>hdfs://$YOUR_FQDN</value></property>
</configuration>
EOF

cat << EOF > /opt/hadoop/etc/hadoop/hdfs-site.xml
<configuration>
  <property><name>dfs.replication</name><value>1</value></property>
  <property><name>dfs.namenode.name.dir</name><value>/data/dfs/nn</value></property>
  <property><name>dfs.datanode.data.dir</name><value>/data/dfs/dn</value></property>
  <property><name>dfs.namenode.checkpoint.dir</name><value>/data/dfs/snn</value></property>
</configuration>
EOF

cat << EOF > /opt/hadoop/etc/hadoop/yarn-site.xml
<configuration>
  <property><name>yarn.resourcemanager.hostname</name><value>$YOUR_FQDN</value></property>
  <property><name>yarn.scheduler.minimum-allocation-mb</name><value>1024</value></property>
  <property><name>yarn.scheduler.increment-allocation-mb</name><value>1024</value></property>
  <property><name>yarn.scheduler.maximum-allocation-mb</name><value>1024</value></property>
  <property><name>yarn.scheduler.minimum-allocation-vcores</name><value>1</value></property>
  <property><name>yarn.scheduler.increment-allocation-vcores</name><value>1</value></property>
  <property><name>yarn.scheduler.maximum-allocation-vcores</name><value>1</value></property>
  <property><name>yarn.nodemanager.resource.memory-mb</name><value>4096</value></property>
  <property><name>yarn.nodemanager.resource.cpu-vcores</name><value>4</value></property>
  <property><name>yarn.nodemanager.local-dirs</name><value>/data/yarn</value></property>
  <property><name>yarn.nodemanager.aux-services</name><value>mapreduce_shuffle</value></property>
  <property><name>yarn.nodemanager.aux-services.mapreduce_shuffle.class</name><value>org.apache.hadoop.mapred.ShuffleHandler</value></property>
  <property><name>yarn.log-aggregation-enable</name><value>true</value></property>
  <property><name>yarn.nodemanager.local-dirs</name><value>/data/yarn/local</value></property>
  <property><name>yarn.nodemanager.log-dirs</name><value>/data/yarn/log</value></property>
  <property><name>yarn.nodemanager.vmem-check-enabled</name><value>false</value></property>
</configuration>
EOF

cat << EOF > /opt/hadoop/etc/hadoop/mapred-site.xml
<configuration>
  <property><name>mapreduce.framework.name</name><value>yarn</value></property>
  <property><name>mapreduce.framework.name</name><value>yarn</value></property>
  <property><name>mapreduce.job.reduce.slowstart.completedmaps</name><value>0.8</value></property>
  <property><name>yarn.app.mapreduce.am.resource.cpu-vcores</name><value>1</value></property>
  <property><name>yarn.app.mapreduce.am.resource.mb</name><value>512</value></property>
  <property><name>yarn.app.mapreduce.am.command-opts</name><value>-Djava.net.preferIPv4Stack=true -Xmx400m</value></property>
  <property><name>mapreduce.map.cpu.vcores</name><value>1</value></property>
  <property><name>mapreduce.map.memory.mb</name><value>512</value></property>
  <property><name>mapreduce.map.java.opts</name><value>-Djava.net.preferIPv4Stack=true -Xmx400m</value></property>
  <property><name>mapreduce.reduce.cpu.vcores</name><value>1</value></property>
  <property><name>mapreduce.reduce.memory.mb</name><value>512</value></property>
  <property><name>mapreduce.reduce.java.opts</name><value>-Djava.net.preferIPv4Stack=true -Xmx400m</value></property>
  <property><name>mapreduce.jobhistory.address</name><value>$YOUR_FQDN:10020</value></property>
  <property><name>mapreduce.jobhistory.webapp.address</name><value>$YOUR_FQDN:19888</value></property>
</configuration>
EOF

mkdir /data
hadoop namenode -format
/opt/hadoop/sbin/hadoop-daemon.sh start namenode
/opt/hadoop/sbin/hadoop-daemon.sh start datanode
/opt/hadoop/sbin/yarn-daemon.sh start resourcemanager
/opt/hadoop/sbin/yarn-daemon.sh start nodemanager
/opt/hadoop/sbin/mr-jobhistory-daemon.sh start historyserver
hdfs dfs -mkdir -p /user/history
hdfs dfs -mkdir /tmp
hdfs dfs -chmod 1777 /tmp

cd ~
wget http://apache.rediris.es/spark/spark-2.0.1/spark-2.0.1.tgz
tar -xvf spark-2.0.1.tgz 
cd ~/spark-2.0.1
dev/make-distribution.sh --name custom-spark --tgz -Phadoop-2.7 -Phive -Phive-thriftserver -Pyarn -DskipTests
tar -C/opt -xvf spark-2.0.1-bin-custom-spark.tgz 
cd /opt
mv spark-* spark
echo "PATH=\"/opt/spark/bin:\$PATH\"" >> ~/.bashrc
source ~/.bashrc

cd /opt/spark/conf

echo "HADOOP_CONF_DIR=\"/opt/hadoop/etc/hadoop\"" > spark-env.sh

cat << EOF > spark-defaults.conf
spark.driver.memory              512m
spark.executor.memory            512m
EOF

yarn jar /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.3.jar pi  4 100
spark-submit --class org.apache.spark.examples.SparkPi --deploy-mode client --master yarn /opt/spark/examples/jars/spark-examples_2.11-2.0.1.jar 100

cd ~
wget http://apache.rediris.es/sqoop/1.4.6/sqoop-1.4.6.tar.gz
tar xvf sqoop-1.4.6.tar.gz
cd sqoop-1.4.6
ant package -Dhadoop.version=2.7.3 -Dhcatalog.version=2.1.0
echo "PATH=\"/opt/sqoop/bin:\$PATH\"" >> ~/.bashrc
source ~/.bashrc

cd ~
wget http://apache.rediris.es/flume/1.7.0/apache-flume-1.7.0-src.tar.gz
tar -xvf apache-flume-1.7.0-src.tar.gz 
cd apache-flume-1.7.0-src
mvn package -DskipTests -DsourceJavaVersion=1.8 -DtargetJavaVersion=1.8 -Dhadoop2.version=2.7.3 -Dhive.version=1.2.0
tar -C/opt -xvf  flume-ng-dist/target/apache-flume-1.7.0-bin.tar.gz 
echo "PATH=\"/opt/flume/bin:\$PATH\"" >> ~/.bashrc
source ~/.bashrc

yum -y install git
git clone git://git.apache.org/cassandra.git /opt/cassandra
cd /opt/cassandra/
git checkout cassandra-3.11
ant
echo "PATH=\"/opt/cassandra/bin:\$PATH\"" >> ~/.bashrc
source ~/.bashrc
cassandra -R
