#!/bin/bash

YOUR_FQDN=localhost

yum -y install wget gcc gcc-c++ autoconf automake libtool zlib-devel cmake openssl openssl-devel snappy snappy-devel bzip2 bzip2-devel protobuf protobuf-devel

cd ~
wget --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u112-b15/jdk-8u112-linux-x64.tar.gz
tar xvf ~/jdk-8u112-linux-x64.tar.gz
mv ~/jdk1.8.0_112 /opt/java
echo "PATH=\"/opt/java/bin:\$PATH\"" >> ~/.bashrc
echo "export JAVA_HOME=\"/opt/java\"" >> ~/.bashrc

cd ~
wget http://apache.rediris.es/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz
tar xvf ~/apache-maven-3.3.9-bin.tar.gz
mv ~/apache-maven-3.3.9 ~/maven
echo "PATH=\"/root/maven/bin:\$PATH\"" >> ~/.bashrc
source ~/.bashrc

cd ~
wget http://apache.rediris.es/ant/binaries/apache-ant-1.9.8-bin.tar.gz
tar -xvf ~/apache-ant-1.9.8-bin.tar.gz
mv ~/apache-ant-* ~/ant
echo "PATH=\"/root/ant/bin:\$PATH\"" >> ~/.bashrc
source ~/.bashrc

cd ~
wget http://apache.rediris.es/zookeeper/zookeeper-3.4.8/zookeeper-3.4.8.tar.gz
tar -xvf zookeeper-3.4.8.tar.gz 
cd zookeeper-3.4.8
ant clean tar
tar -C/opt -xvf build/zookeeper-3.4.8.tar.gz 
mv /opt/zookeeper-3.4.8 /opt/zookeeper
mkdir /opt/zookeeper/data
echo 1 > /opt/zookeeper/data/myid

cat << EOF > /opt/zookeeper/conf/zoo.cfg
clientPort=2181
dataDir=/opt/zookeeper/data
server.1=$YOUR_FQDN:2888:3888
EOF

cat << EOF > /opt/zookeeper/conf/zookeeper-env.sh 
ZOO_LOG_DIR=/opt/zookeeper/logs
EOF
echo "PATH=\"/opt/zookeeper/bin:\$PATH\"" >> ~/.bashrc
source ~/.bashrc
zkServer.sh start

cd ~
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
  <property><name>hadoop.proxyuser.root.groups</name><value>*</value></property>
  <property><name>hadoop.proxyuser.root.hosts</name><value>*</value></property>
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
wget http://apache.rediris.es/spark/spark-2.0.2/spark-2.0.2.tgz
tar -xvf spark-2.0.2.tgz 
cd ~/spark-2.0.2
dev/make-distribution.sh --name custom-spark --tgz "-Pyarn,hadoop-2.7" -DskipTests
tar -C/opt -xvf spark-2.0.2-bin-custom-spark.tgz 
cd /opt
mv spark-* spark
echo "PATH=\"/opt/spark/bin:\$PATH\"" >> ~/.bashrc
source ~/.bashrc

cd /opt/spark/conf

cat << EOF > spark-env.sh
HADOOP_CONF_DIR="/opt/hadoop/etc/hadoop"
#export SPARK_DIST_CLASSPATH=$(hadoop classpath)
EOF

cat << EOF > spark-defaults.conf
spark.driver.memory              512m
spark.executor.memory            512m
EOF

cd ~
wget http://apache.rediris.es/hbase/1.2.4/hbase-1.2.4-src.tar.gz
tar -xvf hbase-1.2.4-src.tar.gz 
cd hbase-1.2.4
mvn clean package assembly:single -DskipTests -Dhadoop.version=2.7.3 -Dzookeeper.version=3.4.8
tar -C/opt -xvf hbase-assembly/target/hbase-1.2.4-bin.tar.gz
mv /opt/hbase-* /opt/hbase
echo "PATH=\"/opt/hbase/bin:\$PATH\"" >> ~/.bashrc
source ~/.bashrc

cat << EOF > /opt/hbase/conf/hbase-site.xml
<configuration>
<property><name>hbase.cluster.distributed</name><value>true</value></property>
<property><name>hbase.rootdir</name><value>hdfs://$YOUR_FQDN:8020/hbase</value></property>
<property><name>hbase.zookeeper.quorum</name><value>$YOUR_FQDN</value></property>
</configuration>
EOF

hbase-daemon.sh start master
hbase-daemon.sh start regionserver

cd ~
wget http://apache.rediris.es/hive/hive-2.1.1/apache-hive-2.1.1-src.tar.gz
tar -xvf apache-hive-2.1.1-src.tar.gz
cd apache-hive-2.1.1-src
mvn clean package -Dhadoop.version=2.7.3 -DskipTests -Pdist
tar -C/opt -xvf ./packaging/target/apache-hive-2.1.1-bin.tar.gz
mv /opt/apache-hive-* /opt/hive
echo "PATH=\"/opt/hive/bin:\$PATH\"" >> ~/.bashrc
source ~/.bashrc

cd ~
yum -y install mariadb-server mariadb
systemctl restart mariadb
systemctl enable mariadb
cat << EOF | mysql
delete from mysql.user WHERE User='';
create database hive;
grant all privileges on hive.* to 'hive'@'%' identified by 'hive';
grant all privileges on hive.* to 'hive'@'localhost' identified by 'hive';
flush privileges;
EOF
wget http://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-5.1.40.tar.gz
tar -xvf mysql-connector-java-5.1.40.tar.gz 
cp mysql-connector-java-5.1.40/mysql-connector-java-5.1.40-bin.jar /opt/hive/lib/

cd /opt/hive
cat << EOF > /opt/hive/conf/hive-site.xml
<configuration>
  <property><name>javax.jdo.option.ConnectionURL</name><value>jdbc:mysql://$YOUR_FQDN/hive?createDatabaseIfNotExist=true</value></property>
  <property><name>javax.jdo.option.ConnectionDriverName</name><value>com.mysql.jdbc.Driver</value></property>
  <property><name>javax.jdo.option.ConnectionUserName</name><value>hive</value></property>
  <property><name>javax.jdo.option.ConnectionPassword</name><value>hive</value></property>
  <property><name>hive.server2.enable.doAs</name><value>true</value></property>
</configuration>
EOF
schematool -dbType mysql -initSchema
hive --service metastore --hiveconf hive.log.dir=/opt/hive/logs --hiveconf hive.log.file=metastore.log >/dev/null 2>&1 &
hive --service hiveserver2 --hiveconf hive.log.dir=/opt/hive/logs --hiveconf hive.log.file=hs2.log >/dev/null 2>&1 &

cd ~
wget http://apache.rediris.es/flume/1.7.0/apache-flume-1.7.0-src.tar.gz
tar -xvf apache-flume-1.7.0-src.tar.gz 
cd apache-flume-1.7.0-src
mvn package -DskipTests -DsourceJavaVersion=1.8 -DtargetJavaVersion=1.8 -Dhadoop2.version=2.7.3 -Dhive.version=2.1.1
tar -C/opt -xvf  flume-ng-dist/target/apache-flume-1.7.0-bin.tar.gz 
mv /opt/apache-flume* /opt/flume
echo "PATH=\"/opt/flume/bin:\$PATH\"" >> ~/.bashrc
source ~/.bashrc

# Sqoop does not work with hive2 yet
#cd ~
#wget http://apache.rediris.es/sqoop/1.4.6/sqoop-1.4.6.tar.gz
#tar xvf sqoop-1.4.6.tar.gz
#cd sqoop-1.4.6
#ant package -Dhadoop.version=2.7.3 -Dhcatalog.version=2.1.0
#echo "PATH=\"/opt/sqoop/bin:\$PATH\"" >> ~/.bashrc
#source ~/.bashrc

yum -y install git
git clone git://git.apache.org/cassandra.git /opt/cassandra
cd /opt/cassandra/
git checkout cassandra-3.11
ant
echo "PATH=\"/opt/cassandra/bin:\$PATH\"" >> ~/.bashrc
source ~/.bashrc
cassandra -R

# Test
yarn jar /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.3.jar pi  4 100
spark-submit --class org.apache.spark.examples.SparkPi --deploy-mode client --master yarn /opt/spark/examples/jars/spark-examples_2.11-2.0.2.jar 100
