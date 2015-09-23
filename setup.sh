#!/bin/bash
# credits - shykes/docker-wordpress and paulczar/docker-wordpress

docker rm -f `docker ps|grep "slave\|master"|awk '{print $1}'`

echo 
echo "Create MySQL Servers (master / slave repl)"
echo "-----------------"

echo "* Create MySQL01"

MYSQL01=$(docker run -d --name master docker-mysql mysqld_safe --server-id=1 --log-bin=mysql-bin --log-slave-updates=1)
MYSQL01_IP=$(docker inspect $MYSQL01 | grep IPAd | awk -F'"' '{print $4}')

echo "* Create MySQL02"

MYSQL02=$(docker run -d --name slave docker-mysql mysqld_safe --server-id=2 --log-bin=mysql-bin --log-slave-updates=1 --auto_increment_increment=2 --auto_increment_offset=2)
MYSQL02_IP=$(docker inspect $MYSQL02 | grep IPAd | awk -F'"' '{print $4}')

echo "* Sleep for two seconds for servers to come online..."
sleep 2

echo "* Creat replication user"

docker exec -it master mysql -e 'GRANT ALL PRIVILEGES ON *.* TO "root"@"%"; FLUSH PRIVILEGES;'
docker exec -it slave mysql -e 'GRANT ALL PRIVILEGES ON *.* TO "root"@"%"; FLUSH PRIVILEGES;'
docker exec -it master mysql -e 'GRANT REPLICATION SLAVE ON *.* TO "replication"@"%" IDENTIFIED BY "password"; flush privileges;'



echo "* Export Data from MySQL01 to MySQL02"

mysqldump -uroot -h $MYSQL01_IP --single-transaction --all-databases \
	--flush-privileges | mysql -uroot -h $MYSQL02_IP

echo "* Set MySQL01 as master on MySQL02"

MYSQL01_Position=$(mysql -uroot -h $MYSQL01_IP -e "show master status \G" | grep Position | awk '{print $2}')
MYSQL01_File=$(mysql -uroot -h $MYSQL01_IP -e "show master status \G"     | grep File     | awk '{print $2}')

mysql -uroot -h $MYSQL02_IP -AN -e "CHANGE MASTER TO master_host='$MYSQL01_IP', master_port=3306, \
	master_user='replication', master_password='password', master_log_file='$MYSQL01_File', \
	master_log_pos=$MYSQL01_Position;"

echo "* Start Slave on both Servers"
mysql -uroot -h $MYSQL02_IP -AN -e "start slave;"

echo "* Create database 'mydata' on MySQL01"

mysql -uroot -h $MYSQL01_IP -e "create database mydata;"
mysql -uroot -h $MYSQL01_IP -e "CREATE TABLE mydata.t ( id INT(6) UNSIGNED AUTO_INCREMENT PRIMARY KEY );"
docker exec -it master mysql -e "insert into mydata.t values ();"
docker exec -it master mysql -e "insert into mydata.t values ();"
docker exec -it master mysql -e "insert into mydata.t values ();"

echo "* Sleep 2 seconds, then check that database 'mydata' exists on MySQL02"

sleep 2
mysql -uroot -h $MYSQL02_IP -e "show databases; \G" | grep mydata


echo "MySQL servers created!"
echo "--------------------"
echo
echo Variables available fo you :-
echo
echo MYSQL01_IP=$MYSQL01_IP
echo MYSQL02_IP=$MYSQL02_IP
