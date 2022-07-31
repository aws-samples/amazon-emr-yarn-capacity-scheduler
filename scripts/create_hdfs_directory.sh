#!/bin/bash
# Create HDFS directories for users

usage() {
	cat <<EOF
   Usage: ./create_hdfs_directory.sh user:group user:group ...
   Ex: ./create_hdfs_directory.sh user1:group1 user2:group1 user3:group2 user4:group2
   This script creates HDFS directories
EOF
	exit 1
}

[[ $# -lt 1 ]] && {
	echo Specify one or more user:group names to create HDFS directories on EMR
	usage
}

while [[ $# -gt 0 ]]; do
	# If no : then make group name == user name
	user=${1%:*}
	group=${1##*:}
	shift

  # Add user to HDFS
	hdfs dfs -mkdir /user/"$user"
	hdfs dfs -chown "$user:$group" /user/"$user"
done