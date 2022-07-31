#!/bin/bash
# Add local users and groups to EMR nodes

usage() {
	cat <<EOF
   Usage: ./create_users_ba.sh user:group user:group ...
   Ex: ./create_users.sh user1:group1 user2:group2 user3:group3 user4:group4
   This script creates Linux users in a given node.  Requires sudo permission.
   Needs to be executed as bootstrap action if users needs to be created in
   all nodes of an Amazon EMR cluster

EOF
	exit 1
}

[[ $# -lt 1 ]] && {
	echo Specify one or more user:group names to add to EMR
	usage
}

# Find the highest valued uid in /etc/passwd
awkcode='$3 > id {previd=id;prevuser=user; id=$3;user=$1};'
awkcode+='END {if (user == "nfsnobody") print previd+1; else print id+1}'
uid=$(getent passwd | sort -t: -k3 -n | awk -F: "$awkcode")
[[ "$uid" -lt 1000 ]] && uid=1001

# Because gid is set equal to uid value, check for possible gid overlap
gid=$(getent group | sort -t: -k3 -n | awk -F: "$awkcode")
[[ "$gid" -gt "$uid" ]] && uid="$gid"


# Add user and group, one by one using uid and gid initialized above
while [[ $# -gt 0 ]]; do
	# If no : then make group name == user name
	user=${1%:*}
	group=${1##*:}
	shift

	# Check for existing uid and gid usage on all nodes
	grep -q $uid /etc/{passwd,group} && exit 2 >& /dev/null
	[[ $? -eq 2 ]] && {
		echo uid $uid already exists
		exit
	}

	# Add Linux group and user using explicit uid number
	sudo groupadd -g $uid $group
	sudo useradd -m -c '$user account' -g $group -u $uid $user
	sudo chpasswd <<< '$user:$user'
	id $user

	((uid++))
done