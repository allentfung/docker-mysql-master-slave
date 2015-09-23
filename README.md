docker-mysql-master-slave
=========================

Docker setup of 2 MySQL servers - one master and one slave (replication)


Build and run:
<pre>
git clone https://github.com/allentfung/docker-mysql-master-slave.git
cd docker-mysql-master-slave
./docker build -t docker-mysql .
./setup.sh
</pre>

MySQL credentials are: `root / root`.
MySQL credentials are: `replication / password`.
