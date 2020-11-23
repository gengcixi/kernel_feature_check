#########################################################################
# File Name: sprd_check.sh
# Author: Cixi.Geng
# mail: cixi.geng@unisoc.com
# Created Time: 2020年11月20日 星期五 18时42分56秒
#########################################################################
#!/bin/sh

feature_file=$1
cur_pid=$$
echo_info()
{
	echo -e "\033[36m$*\033[0m"
}
echo_pass()
{
	echo -e "\033[33m ${FUNCNAME[1]} CHECK PASS: $*\033[0m"
}
echo_error()
{
	echo -e "\033[31m ${FUNCNAME[1]} CHECK FAIL: $*\033[0m"
}
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
	config_list=$(jq -r '.enabled_config[]?' $feature_file)
	if [ -n "$config_list" ];then
		echo_info "<<<starting check needs enabled config>>>"
		for config in $config_list
		do
			zcat /proc/config.gz |grep "${config}=" >/dev/null 2>&1
			if [ $? -ne 0 ];then
				echo_error "$config"
				let return_val++
			else
				echo_pass "$config"
			fi
		done
		echo_info "<<<finished check needs enabled config>>>"
	fi
}

check_disabled_config()
{
	unset config_list
	unset config
	config_list=$(jq -r '.disabled_config[]?' $feature_file)
	if [ -n "$config_list" ];then
		echo_info "<<<starting check needs disabled config>>>"
		for config in $config_list
		do
			zcat /proc/config.gz |grep "${config}=" >/dev/null 2>&1
			if [ $? -eq 0 ];then
				echo_error "$config"
				let return_val++
			else
				echo_pass "$config"
			fi
		done
		echo_info "<<<finished check needs disabled config>>>"
	fi
}

check_config()
{
	check_enabled_config
	check_disabled_config
}
check_properties()
{
	if grep $2 $1;then
		echo_pass "$2 in $1"
	else
		echo_error "$2 in $1"
		let return_val++
	fi
}

check_attribute()
{
	file=$(jq -r '.file' $1)
	if ls $file >/dev/null 2>&1;then
		echo_pass "$file"
		properties_list=$(jq -r '.properties[]?' $1)
		if [ -n "$properties_list" ];then
			for prop in $properties_list
			do
				check_properties $file $prop
			done
		fi
	else
		echo_error "$file"
		let return_val++
	fi
}

check_attribute_properties()
{
	attribute_length=$(jq -r '.attribute| length' $feature_file)
	if [ -n $attribute_length ];then
		echo_info "<<<starting check attribute properties>>>"
		for i in $(seq 1 ${attribute_length})
		do
			attri_file="/tmp/${cur_pid}-${feature_file%.*}.attri"
			touch $attri_file
			jq -r '.attribute['$i'-1]?' $feature_file>$attri_file
			check_attribute $attri_file
		done
		rm $attri_file
		echo_info "<<<finished check attribute properties>>>"
	fi
}
check_config
check_attribute_properties
if [ $return_val -gt 0 ];then
	echo_error "Total test has $return_val item failed"
fi
