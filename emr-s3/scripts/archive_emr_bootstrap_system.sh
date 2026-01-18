#!/bin/bash

set -euxo pipefail

# Define versions
SPARK_VERSION="3.5.4"
HADOOP_VERSION="3.4.1"
SCALA_VERSION="2.12"

sudo mkdir -p /artifacts
sudo chown -R spark:spark /artifacts
sudo chmod -R 777 /artifacts

# Use a writable log path
#LOG_FILE="/home/hadoop/spark-connect.log"

# Optional: ensure the log file exists and is writable
#touch $LOG_FILE
#chmod 644 $LOG_FILE

export SPARK_LOG_DIR=/home/hadoop/spark-logs
mkdir -p $SPARK_LOG_DIR
chmod 755 $SPARK_LOG_DIR


# Define packages to load for Spark Connect server
SPARK_PACKAGES="org.apache.spark:spark-connect_${SCALA_VERSION}:${SPARK_VERSION},org.apache.hadoop:hadoop-aws:${HADOOP_VERSION}"


# Start Spark Connect server in the background
#/usr/lib/spark/sbin/start-connect-server.sh \
#  --packages ${SPARK_PACKAGES} &

#set -eux

# Define the service file path
SERVICE_FILE="/etc/systemd/system/spark-connect-server.service"

# Create the systemd service for Spark Connect
echo "Creating systemd service for Spark Connect Server..."

# Use sudo to ensure the service is created with root privileges and pass the SERVICE_FILE explicitly
sudo bash -c "cat <<EOF > $SERVICE_FILE
[Unit]
Description=Spark Connect Server
After=network.target

[Service]
Type=simple
User=hadoop
Group=hadoop
Environment="SPARK_LOG_DIR=/home/hadoop/spark-logs"
Environment=JAVA_HOME=/etc/alternatives/jre
Environment=HADOOP_HOME=/usr/lib/hadoop
ExecStart=env SPARK_NO_DAEMONIZE=1 /usr/lib/spark/sbin/start-connect-server.sh -Dlog4j.configuration=file:/usr/lib/spark/conf/log4j2.properties  \
  --packages ${SPARK_PACKAGES} \
  --conf spark.connect.grpc.binding.address=0.0.0.0 \
  --conf spark.connect.grpc.binding.port=15002 
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF"

# Reload systemd to recognize the new service
sudo systemctl daemon-reload

# Enable the service so it starts automatically on boot
sudo systemctl enable spark-connect-server

# Start the service immediately
sudo systemctl start spark-connect-server

echo "Spark Connect Server service created and started." 
