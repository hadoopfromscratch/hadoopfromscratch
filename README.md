# HadoopFromScratch

A set of tools to compile and roll out your own Hadoop distro for testing purposes.

## Requirements

- CentOS 7 is required.
- SElinux and firewalld should be disabled.
- The install.sh script should be run as root.
- It is also recommended to configure a resolvable FQDN for the host, even thought the default "localhost" should be enough for testing purposes.


## Installation

Download install.sh and run it as root:

```curl -s https://raw.githubusercontent.com/hadoopfromscratch/hadoopfromscratch/master/install.sh | bash```

If everything goes well, Hadoop should be up and running and "Pi"-jobs (two last lines of install.sh) should execute without errors.

## Software and versions

The script will download, compile, configure and run the following pieces of software:

- Java 8u102
- Ant 1.9.7
- Maven 3.3.9
- Hadoop 2.7.3
- Spark 2.0.1
- Cassandra 3.11

## Layout

- /opt will contain installed software (java, hadoop and spark. each in its own directory)
- /data will contain Hadoop's data
- User's home dir will contain ant and maven directories and all downloaded sources. All its contents can be safely removed after the installation is finished.
