#!/bin/bash

YOUR_FQDN=localhost

# Zookeeper
echo "ls /" | zkCli.sh

# HDFS
dd if=/dev/zero of=/tmp/test.txt bs=130M count=1
hdfs dfs -put /tmp/test.txt /tmp
hdfs dfs -ls /tmp/test.txt
hdfs dfs -rm -skipTrash /tmp/test.txt
rm -f /tmp/test.txt

# YARN and MapReduce
yarn jar /opt/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.8.1.jar pi 3 100

# Spark
spark-submit --class org.apache.spark.examples.SparkPi --deploy-mode client --master yarn /opt/spark/examples/jars/spark-examples_2.11-2.2.0.jar 50

# HBase
hbase shell <<EOF
create 'test', 'f1'
put 'test', 'row1', 'f1', 'value1'
put 'test', 'row2', 'f1', 'value2'
put 'test', 'row3', 'f1', 'value3'
scan 'test'
disable 'test'
drop 'test'
EOF

# Hive
beeline -u "jdbc:hive2://$YOUR_FQDN:10000/default" -nroot -e "create table test (id int); insert into test values (1), (2), (3); select count(*) from test; drop table test;"

# Pig
pig <<EOF
sh echo "bob male" > /tmp/test.txt
sh echo "james male" >> /tmp/test.txt
sh echo "jane female" >> /tmp/test.txt
sh echo "tom male" >> /tmp/test.txt
sh echo "sandra female" >> /tmp/test.txt
rmf /tmp/test.txt
copyFromLocal /tmp/test.txt /tmp/
sh rm /tmp/test.txt
a = LOAD '/tmp/test.txt' USING PigStorage(' ') AS (name, sex);
b = GROUP a by sex;
c = FOREACH b GENERATE group, COUNT(a.name);
DUMP c;
rmf /tmp/test.txt
EOF

# Cassandra
cqlsh -e "create keyspace test with replication = { 'class' : 'SimpleStrategy', 'replication_factor' : 1 };"
cqlsh -e "create table test.test (id int, val varchar, primary key(id));"
cqlsh -e "insert into test.test (id, val) values (1, 'test value 1'); insert into test.test (id, val) values (2, 'test value 2'); insert into test.test (id, val) values (3, 'test value 3');"
cqlsh -e "select * from test.test;"
cqlsh -e "drop table test.test; drop keyspace test;"

# Sqoop
sqoop import --connect jdbc:mysql://$YOUR_FQDN/hive --username hive --password hive --target-dir=/tmp/test --table=DBS
hdfs dfs -rm -r -skipTrash /tmp/test

# Hue
wget -q -O - http://$YOUR_FQDN:8000 | grep Cloudera
