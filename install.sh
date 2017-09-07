#!/bin/bash

YOUR_FQDN=localhost

yum -y install wget gcc gcc-c++ autoconf automake libtool zlib-devel cmake openssl openssl-devel snappy snappy-devel bzip2 bzip2-devel protobuf protobuf-devel

cd ~
wget -c --header "Cookie: oraclelicense=accept-securebackup-cookie" http://download.oracle.com/otn-pub/java/jdk/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.tar.gz
tar xvf ~/jdk-8u131-linux-x64.tar.gz
mv ~/jdk1.8.0_131 /opt/java
echo "PATH=\"/opt/java/bin:\$PATH\"" >> ~/.bashrc
echo "export JAVA_HOME=\"/opt/java\"" >> ~/.bashrc

cd ~
wget http://apache.rediris.es/maven/maven-3/3.3.9/binaries/apache-maven-3.3.9-bin.tar.gz
tar xvf ~/apache-maven-3.3.9-bin.tar.gz
mv ~/apache-maven-3.3.9 ~/maven
echo "PATH=\"/root/maven/bin:\$PATH\"" >> ~/.bashrc
source ~/.bashrc

cd ~
wget http://apache.rediris.es/ant/binaries/apache-ant-1.10.1-bin.tar.gz
tar -xvf ~/apache-ant-1.10.1-bin.tar.gz
mv ~/apache-ant-1.10.1 ~/ant
echo "PATH=\"/root/ant/bin:\$PATH\"" >> ~/.bashrc
source ~/.bashrc

cd ~
wget http://apache.rediris.es/zookeeper/zookeeper-3.4.10/zookeeper-3.4.10.tar.gz
tar -xvf zookeeper-3.4.10.tar.gz 
cd zookeeper-3.4.10
ant clean tar
tar -C/opt -xvf build/zookeeper-3.4.10.tar.gz 
mv /opt/zookeeper-3.4.10 /opt/zookeeper
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
wget http://apache.rediris.es/hadoop/common/hadoop-2.8.1/hadoop-2.8.1-src.tar.gz
tar -xvf ~/hadoop-2.8.1-src.tar.gz
mv ~/hadoop-2.8.1-src ~/hadoop-src
cd ~/hadoop-src
mvn package -Pdist,native -DskipTests -Dtar -Dzookeeper.version=3.4.10
tar -C/opt -xvf ~/hadoop-src/hadoop-dist/target/hadoop-2.8.1.tar.gz
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
  <property><name>mapreduce.job.reduce.slowstart.completedmaps</name><value>0.8</value></property>
  <property><name>yarn.app.mapreduce.am.resource.cpu-vcores</name><value>1</value></property>
  <property><name>yarn.app.mapreduce.am.resource.mb</name><value>1024</value></property>
  <property><name>yarn.app.mapreduce.am.command-opts</name><value>-Djava.net.preferIPv4Stack=true -Xmx768m</value></property>
  <property><name>mapreduce.map.cpu.vcores</name><value>1</value></property>
  <property><name>mapreduce.map.memory.mb</name><value>1024</value></property>
  <property><name>mapreduce.map.java.opts</name><value>-Djava.net.preferIPv4Stack=true -Xmx768m</value></property>
  <property><name>mapreduce.reduce.cpu.vcores</name><value>1</value></property>
  <property><name>mapreduce.reduce.memory.mb</name><value>1024</value></property>
  <property><name>mapreduce.reduce.java.opts</name><value>-Djava.net.preferIPv4Stack=true -Xmx768m</value></property>
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
hdfs dfs -mkdir -p /user
hdfs dfs -mkdir /tmp
hdfs dfs -chmod 1777 /tmp

cd ~
wget http://apache.rediris.es/spark/spark-2.2.0/spark-2.2.0.tgz
tar -xvf spark-2.2.0.tgz 
cd ~/spark-2.2.0
dev/make-distribution.sh --name custom-spark --tgz "-Pyarn,hadoop-2.7" -Dhadoop.version=2.8.1 -DskipTests
tar -C/opt -xvf spark-2.2.0-bin-custom-spark.tgz 
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
wget http://apache.rediris.es/hbase/1.3.1/hbase-1.3.1-src.tar.gz
tar -xvf hbase-1.3.1-src.tar.gz 
cd hbase-1.3.1
mvn clean package assembly:single -DskipTests -Dhadoop.version=2.8.1 -Dzookeeper.version=3.4.10
tar -C/opt -xvf hbase-assembly/target/hbase-1.3.1-bin.tar.gz
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
hbase-daemon.sh start thrift
hbase-daemon.sh start regionserver

cd ~
wget http://apache.rediris.es/hive/hive-2.3.0/apache-hive-2.3.0-src.tar.gz
tar -xvf apache-hive-2.3.0-src.tar.gz
cd apache-hive-2.3.0-src
sed -i '/<dependencies>/a <dependency><groupId>junit</groupId><artifactId>junit</artifactId><scope>test</scope></dependency>' shims/common/pom.xmlq
mvn clean package -Dhadoop.version=2.8.1 -DskipTests -Pdist
tar -C/opt -xvf ./packaging/target/apache-hive-2.3.0-bin.tar.gz
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
wget http://apache.rediris.es/pig/pig-0.16.0/pig-0.16.0-src.tar.gz
tar -xvf pig-0.16.0-src.tar.gz 
cd pig-0.16.0-src
sed -i '/<\/dependencies>/i \
    <dependency org="org.apache.hadoop" name="hadoop-hdfs-client" rev="${hadoop-hdfs.version}" conf="hadoop23->master"><artifact name="hadoop-hdfs-client" ext="jar" /></dependency>' ivy.xml
sed -i 's/target name="package" depends="jar, docs/target name="package" depends="jar/g' build.xml 
ant -Dhadoopversion=23 -Dzookeeper.version=3.4.10 -Dhadoop-common.version=2.8.1 -Dhadoop-hdfs.version=2.8.1 -Dhadoop-mapreduce.version=2.8.1 tar
tar -C/opt -xvf /root/pig-0.16.0-src/build/pig-0.16.0-SNAPSHOT.tar.gz
mv /opt/pig-* /opt/pig
echo "PATH=\"/opt/pig/bin:\$PATH\"" >> ~/.bashrc
source ~/.bashrc

cd ~
wget http://apache.rediris.es/flume/1.7.0/apache-flume-1.7.0-src.tar.gz
tar -xvf apache-flume-1.7.0-src.tar.gz 
cd apache-flume-1.7.0-src
mvn package -DskipTests -DsourceJavaVersion=1.8 -DtargetJavaVersion=1.8 -Dhadoop2.version=2.8.1 -Dhive.version=2.3.0
tar -C/opt -xvf  flume-ng-dist/target/apache-flume-1.7.0-bin.tar.gz 
mv /opt/apache-flume* /opt/flume
echo "PATH=\"/opt/flume/bin:\$PATH\"" >> ~/.bashrc
source ~/.bashrc

cd ~
yum -y install git asciidoc redhat-lsb-core xmlto
git clone https://github.com/apache/sqoop.git
cd sqoop
git checkout branch-1.4.7
ant tar -Dhadoop.version=2.8.1 -Dhcatalog.version=2.1.0
tar -C/opt -xvf build/sqoop-1.4.7.bin__hadoop-2.8.1.tar.gz
mv /opt/sqoop-* /opt/sqoop
cp ~/mysql-connector-java-5.1.40/mysql-connector-java-5.1.40-bin.jar /opt/sqoop/lib/
echo "PATH=\"/opt/sqoop/bin:\$PATH\"" >> ~/.bashrc
source ~/.bashrc

cat << EOF > /opt/sqoop/conf/sqoop-env.sh 
export HADOOP_COMMON_HOME=/opt/hadoop
export HADOOP_MAPRED_HOME=/opt/hadoop/share/hadoop/mapreduce
export HBASE_HOME=/opt/hbase
export HIVE_HOME=/opt/hive
export ZOOCFGDIR=/opt/zookeeper/conf
EOF

cd ~
wget http://apache.rediris.es/cassandra/3.11.0/apache-cassandra-3.11.0-src.tar.gz
tar -xvf apache-cassandra-3.11.0-src.tar.gz
cd apache-cassandra-3.11.0-src
ant artifacts
tar -C/opt -xvf build/apache-cassandra-3.11.0-SNAPSHOT-bin.tar.gz
mv /opt/apache-cassandra-3.11.0-SNAPSHOT /opt/cassandra
echo "PATH=\"/opt/cassandra/bin:\$PATH\"" >> ~/.bashrc
source ~/.bashrc
cassandra -R

# Hue
cd ~
yum -y install asciidoc cyrus-sasl-devel cyrus-sasl-gssapi cyrus-sasl-plain gcc gcc-c++ krb5-devel libffi-devel libtidy libxml2-devel libxslt-devel make mariadb mariadb-devel openldap-devel python-devel sqlite-devel openssl-devel gmp-devel
wget https://dl.dropboxusercontent.com/u/730827/hue/releases/3.12.0/hue-3.12.0.tgz
tar -xvf hue-3.12.0.tgz
cd hue-3.12.0
sed -i 's/SETUID_USER = "hue"/SETUID_USER = "root"/' desktop/core/src/desktop/supervisor.py
sed -i 's/SETGID_GROUP = "hue"/SETGID_GROUP = "root"/' desktop/core/src/desktop/supervisor.py

cat << EOF | mysql
create database hue;
grant all privileges on hue.* to 'hue'@'%' identified by 'hue';
grant all privileges on hue.* to 'hue'@'localhost' identified by 'hue';
flush privileges;
EOF

cat << EOF > desktop/conf/hue.ini
[desktop]
  secret_key=ashdofhaoirtoidfjgoianoanweorianwofinawerot
  http_host=0.0.0.0
  http_port=8000
  send_dbug_messages=true
  server_user=root
  server_group=root
  default_user=root
  default_hdfs_superuser=root
  [[auth]]
    idle_session_timeout=-1
  [[database]]
    engine=mysql
    host=$YOUR_FQDN
    user=hue
    password=hue
    name=hue
[hadoop]
  [[hdfs_clusters]]
    [[[default]]]
      fs_defaultfs=hdfs://$YOUR_FQDN:8020
      webhdfs_url=http://$YOUR_FQDN:50070/webhdfs/v1
  [[yarn_clusters]]
    [[[default]]]
      resourcemanager_host=$YOUR_FQDN
      submit_to=True
      resourcemanager_api_url=http://$YOUR_FQDN:8088
      proxy_api_url=http://$YOUR_FQDN:8088
EOF

INSTALL_DIR=/opt/hue make install
nohup /opt/hue/build/env/bin/supervisor 1>/dev/null 2>/dev/null &
