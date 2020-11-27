#########################################################################
# File Name: sprd_check.sh
# Author: Cixi.Geng
# mail: cixi.geng@unisoc.com
# Created Time: 2020年11月20日 星期五 18时42分56秒
#########################################################################
#!/bin/sh

feature_file=$1
cur_pid=$$
return_val=0
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

check_string()
{
	str_list=$(jq -r '.string[]?' $2)
	local str_flag=0
	file_str=$(cat $1)
	for str in $str_list
	do
		if grep $str $1;then
			let str_flag++
		fi
	done
	if [ $str_flag -gt 0 ];then
		echo_pass "$str in <<<$(echo $str_list)>>>"
	else
		echo_error "$str in <<<$(echo $str_list)>>>"
		let return_val++
	fi
}

check_value()
{
	file_value=$(cat $1)
	if [ "$file_value" == "$2" ];then
		echo_pass "$file_value in $file is $2"
	else
		echo_error "$file_value in $file isn't $2"
		let return_val++
	fi

}

check_range()
{
	file_value=$(cat $1)
	if [ $file_value -gt $2 -a $file_value -lt $3 ]; then
		echo_pass "$file_value in $1 is between $2 and $3"
	else
		echo_error "$file_value in $1 isn't between $2 and $3"
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
		string_list=$(jq -r '.string[]?' $1)
		if [ -n "$string_list" ];then
			check_string $file $1
		fi
		value=$(jq -r '.value?' $1)
		if [ "$value" != "null" ];then
			echo_info "start check value"
			check_value $file $value
		fi
		range_list=$(jq -r '.range[]?' $1)
		if [ -n "$range_list" ];then
			echo_info "start check range"
			max_value=$(jq -r '.range[0]' $1)
			min_value=$(jq -r '.range[1]' $1)
			check_range $file $max_value $min_value
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
