#########################################################################
# File Name: sprd_check.sh
# Author: Cixi.Geng
# mail: cixi.geng@unisoc.com
# Created Time: 2020年11月20日 星期五 18时42分56秒
#########################################################################
#!/bin/sh

echo_info()
{
	echo -e "\033[32m$*\033[0m"
}
feature_file=$1
check_jq()
{
	command -v jq >/dev/null 2>&1
	if [ $? -ne 0 ];then
		echo "I require jq but it's not installed.  Aborting."
		#use apt-get install jq 
		exit 1;
	fi
}
check_jq

check_enabled_config()
{
	unset config_list
	unset config
	config_list=$(jq -r '.enabled_config[]' $feature_file)
	echo_info "<<<starting check needs enabled config>>>"
	for config in $config_list
	do
		zcat /proc/config.gz |grep "${config}=" >/dev/null 2>&1
		if [ $? -ne 0 ];then
			let return_val++
		else
			echo "CHECK_SET_OK:    $config"
		fi
	done
	echo_info "<<<finished check needs enabled config>>>"
}

check_disabled_config()
{
	unset config_list
	unset config
	config_list=$(jq -r '.disabled_config[]' $feature_file)
	echo_info "<<<starting check needs disabled config>>>"
	for config in $config_list
	do
		zcat /proc/config.gz |grep "${config}=" >/dev/null 2>&1
		if [ $? -eq 0 ];then
			let return_val++
		else
			echo "CHECK_NOSET_OK:    $config"
		fi
	done
	echo_info "<<<finished check needs disabled config>>>"
}

check_config()
{
	check_enabled_config
	check_disabled_config
}
check_config

attribute_length=$(jq -r '.attribute| length' $feature_file)
for i in $(seq 1 ${attribute_length})
do
	jq -r '.attribute['$i'-1]' $feature_file
done
