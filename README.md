# HadoopFromScratch

A set of tools to compile and roll out your own Hadoop distro for testing purposes.

## Requirements

- CentOS 7 is required.
- SElinux and firewalld should be disabled.
- The install.sh script should be run as root.
- It is also recommended to configure a resolvable FQDN for the host, even thought the default "localhost" should be enough for testing purposes.


## Installation

Download install.sh and run it as root:

```bash ./install.sh```


## Software and versions

The script will download, compile, configure and run the following pieces of software.

- Java 8u102
- Maven 3.3.9
- Hadoop 2.7.3
- Spark 2.0.0

Java, Hadoop and Spark are installed into /opt. Maven is installed into user's homedir. It is not needed once the script exits and can be safely removed.

If everything goes well, Hadoop should be up and running and "Pi"-jobs (two last lines of install.sh) should execute without errors.
