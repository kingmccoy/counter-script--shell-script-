#!/bin/bash

#######################################################
#                                                     #
#      TESTER COUNTER PROGRAM BASH SHELL SCRIPT       #
#           by: TEST ENGINEERING DEPARTMENT           #
#                    version 4.2                      #
#                                                     #
#######################################################

#######################################################
#----------Remove # for dedidated directory-----------#
#######################################################

# Changes v2.0: Update counter script for Mfg V5P0.
# Changes v3.0: Detect duplicate test of QR.
# Changes v4.0: Add mac all directory to capture all test data logs tested and backup to mac all directory. Detection of duplicate mac address.
# Changes v4.1: Fixed not showing result on failed units. Fixed detection of duplicate mac address. Change reference detection of duplicate mac address from text file to directory
# Changes v4.2: Fixed showing multiple latest file on failed units with same QR codes.

# Directories
# directory=/work/Mfg_Softwares/RS9113_Module_MfgSoftware_V5P0/Driver_slave/wlan_slave/release/flash/
# testlog=test_5_log
# mac_all=/work/Mfg_Softwares/calibration_mac_all

# Files
# qr_code_test=/work/Mfg_Softwares/RS9113_Module_MfgSoftware_V5P0/Driver_slave/wlan_slave/release/qr_value
# last_mac_use_file=$directory/RSI_LastMac.txt
# mac_all_file=/work/Mfg_Softwares/mac_all.txt

# Directories
directory=/mnt/d/
testlog=counter_test
mac_all=/mnt/d/calibration_mac_all

# Files
qr_code_test=$directory/qr_value
last_mac_use_file=$directory/RSI_LastMac.txt
mac_all_file=/mnt/d/mac_all.txt

# get_qr_code="$(cat $qr_code_test)" #---if cat doesn't work please use below
read -r get_qr_code < $qr_code_test #---this is alternative option to get the string
# get_qr_code="$(sed -n 1p "$qr_code_test" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" || read $get_qr_code #---use this if the file has .txt extension
get_last_mac="$(sed -n 1p "$last_mac_use_file" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" || read $get_last_mac #Get the string from 1st line of the text file
get_wlan_mac="$(echo "$get_last_mac" | awk -F '=' '{print toupper($2)}')" #Get the mac address of the WLAN_MAC_ID into upper characters

# echo "$get_qr_code"
# echo "$get_wlan_mac"

# increment="4" #---increment on the mac address from last mac to current mac

# hex_mac_current=$(printf "%X\n" $((0x$get_wlan_mac + 0x$increment))) #---Convert the mac string to hex to add hex numbers
# echo $hex_mac_current 

# Get latest test data log
if [ -d $directory$testlog ]; then
	cd $directory$testlog

	pass_logfile=$(ls $directory$testlog/*"${get_wlan_mac}_${get_qr_code}"* 2>/dev/null) # Using ls to check for matching files
	fail_logfile=$(ls $directory$testlog/*"$(date +%Y)_${get_qr_code}"* 2>/dev/null) # Using ls to check for matching files
	
	if [ -n "$pass_logfile" ]; then
		# echo "passed exist"
		get_last_log=$(ls $directory$testlog/*"${get_wlan_mac}_${get_qr_code}"* 2>&1) #--- If file is not existing then no string output on the console
		
		if [ $? -ne 0 ]; then #---> /dev/null 2>&1 effectively suppressing any output.
			get_last_log=$(ls *"${get_wlan_mac}_${get_qr_code}"* > /dev/null 2>&1)
		
		else
			get_last_log=$(ls -t *"${get_wlan_mac}_${get_qr_code}"* | head -1)
		fi
	elif [ -n "$fail_logfile" ]; then
		# echo "failed exist"
		get_last_log=$(ls $directory$testlog/*"$(date +%Y)_${get_qr_code}"* 2>&1) #--- If file is not existing then no string output on the console

		if [ $? -ne 0 ]; then #---> /dev/null 2>&1 effectively suppressing any output.
			get_last_log=$(ls *"$(date +%y)_${get_qr_code}"* > /dev/null 2>&1)
		else
			get_last_log=$(ls -t *"$(date +%y)_${get_qr_code}"* | head -1)
		fi
	fi

	# get_last_log=$(ls $directory$testlog/*"${get_wlan_mac}_${get_qr_code}"* 2>&1) #--- If file is not existing then no string output on the console
	# get_last_log_failed=$(ls $directory$testlog/*"$(date +%Y)_${get_qr_code}"* 2>&1) #--- If file is not existing then no string output on the console
	# pwd
	
	# if [ $? -ne 0 ]; then #---> /dev/null 2>&1 effectively suppressing any output.
	# 	get_last_log=$(ls *"${get_wlan_mac}_${get_qr_code}"* > /dev/null 2>&1)
	# 	# get_last_log_failed=$(ls *"$(date +%y)_${get_qr_code}"* > /dev/null 2>&1)
	# 	# echo "true"
	# else
	# 	get_last_log=$(ls *"${get_wlan_mac}_${get_qr_code}"*)
	# 	# get_last_log_failed=$(ls *"$(date +%y)_${get_qr_code}"*)
	# 	# echo "false"
	# fi

	# Find all files in the folder and print their creation time along with the filename
	# latest_log=$(find -type f -printf "%T@ %p\n" 2>/dev/null | sort -n | tail -n 1 | cut -d' ' -f2-) #----latest file base on the lastest time stamp
	# latest_qr=$(echo "$latest_file" | awk -F '_' '{print substr($NF, 0,11)}') #----latest qr base on the latest time stamp

	latest_file=$get_last_log
	latest_qr=$get_qr_code
fi

# echo ${latest_log:2}
# echo $latest_file
# echo $latest_qr

# duplicate serial detection
if [ -d $directory$testlog ]; then
	cd $directory$testlog

	# Get duplicate QR codes within the current test data log directory
	duplicates=$(ls -lArt | awk -F '_' '{split($NF, a, "."); print a[1]}' | sort | uniq -d) # $NF last field, 'a' is storage, "." is dilimiter

	# list out the detected duplicates
	for dup_qr in $duplicates; do
		if [ ! $latest_qr == $dup_qr ]; then
			echo
			echo -e "\e[91mDuplicate test $dup_qr\e[0m"
			ls -lArt *$dup_qr* | awk '{print $6" "$7" "$8" "$NF}'
		fi
	done

	if [ -n "$latest_file" ]; then
		echo -e "\e[32m\nLatest file: $latest_file\n\e[0m" #--- # Print the latest file in green
		count=$(ls *$latest_qr* | wc -l)
	fi

	# Check duplicate on latest log
	if [[ $count -gt 1 ]]; then
		echo -e "\e[91mUnit already tested!\e[0m"
		latest=""
		for logs in *$latest_qr*; do
			if [ "$logs" = "${latest_file:0}" ]; then
				latest=$logs
				# echo -e "\e[32m$logs\e[0m >> \e[3mlatest log\e[0m"
				# echo -e "\n\e[91mPlease check the actual vs logs quantity before you proceed!\e[0m"
			else
				echo "$logs"
			fi
			# echo $logs "logs"
			# echo ${latest_file:2} "latest_file"
		done
		echo -e "\e[32m$latest\e[0m >> \e[3mlatest log\e[0m"
		echo -e "\n\e[91mWARNING:\e[0m \e[3mPlease check the actual vs logs quantity before you proceed!\e[0m"
		echo
	fi

	# note:
	# sed -e 's/^[[:space:]]*//' #remove leading whitespace characters from the extracted line
	# sed -e 's/[[:space:]]*$//' #remove trailing whitespace characters from the extracted line

	# Logs Mac
	if [ -n "$(ls $directory$testlog)" ]; then #check if directory is not empty
		if [ -f "$(ls $directory$testlog/$get_last_log 2>/dev/null)" ]; then
			mac_add="$(sed -n 7p "$latest_file" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" || read $mac_add
		fi
	fi

	# logs passed with firmware | Dual Band
	if [ -n "$(ls $directory$testlog)" ]; then #check if directory is not empty
		if [ -f "$(ls $directory$testlog/$get_last_log 2>/dev/null)" ]; then
			embedded_mode_passed_db="$(sed -n 62p "$latest_file" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" || read $embedded_mode_passed_db #Module is in Embedded Mode
			log_passed_wise_db="$(sed -n 71p "$latest_file" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" || read $log_passed_wise_db #read text on line 71. Contains PASSED
			log_passed_wise_fw_db="$(sed -n 64p "$latest_file" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" || read $log_passed_wise_fw_db #read text on line 64. fetch firmware version
			log_passed_wise_bl_db="$(sed -n 66p "$latest_file" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" || read $log_passed_wise_bl_db #read text on line 66. fetch bootloader version
		fi
	fi

	# Logs passed with firmare | Single Band
	if [ -n "$(ls $directory$testlog)" ]; then #check if directory is not empty
		if [ -f "$(ls $directory$testlog/$get_last_log 2>/dev/null)" ]; then
			embedded_mode_passed_sb="$(sed -n 42p "$latest_file" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" || read $embedded_mode_passed_sb #Module is in Embedded Mode
			log_passed_wise_sb="$(sed -n 51p "$latest_file" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" || read $log_passed_wise_sb #read text on line 51. Contains PASSED
			log_passed_wise_fw_sb="$(sed -n 44p "$latest_file" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" || read $log_passed_wise_fw_sb #read text on line 44. fetch firmware version
			log_passed_wise_bl_sb="$(sed -n 46p "$latest_file" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" || read $log_passed_wise_bl_sb #read text on line 46. fetch bootloader version
		fi
	fi
	
	# logs passed without firmware | Dual Band
	if [ -n "$(ls $directory$testlog)" ]; then #check if directory is not empty
		if [ -f "$(ls $directory$testlog/$get_last_log 2>/dev/null)" ]; then
			hosted_mode_passed_db="$(sed -n 62p "$latest_file" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" || read $hosted_mode_passed_db #Module is in Hosted Mode
			log_passed_nlink_db="$(sed -n 69p "$latest_file" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" || read $log_passed_nlink_db #read text on line 69. Contains PASSED
			log_passed_nlink_bl_db="$(sed -n 64p "$latest_file" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" || read $log_passed_nlink_bl_db #read text on line 62. fetch bootloader version
		fi
	fi

	# logs passed without firmware | Single Band
	if [ -n "$(ls $directory$testlog)" ]; then #check if directory is not empty
		if [ -f "$(ls $directory$testlog/$get_last_log 2>/dev/null)" ]; then
			hosted_mode_passed_sb="$(sed -n 42p "$latest_file" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" || read $hosted_mode_passed_sb #Module is in Hosted Mode
			log_passed_nlink_sb="$(sed -n 49p "$latest_file" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" || read $log_passed_nlink_sb #read text on line 49. Contains PASSED
			log_passed_nlink_bl_sb="$(sed -n 44p "$latest_file" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" || read $log_passed_nlink_bl_sb #read text on line 44. fetch bootloader version
		fi
	fi

	# logs failed with firmware | Dual Band
	if [ -n "$(ls $directory$testlog)" ]; then #check if directory is not empty
		if [ -f "$(ls $directory$testlog/$get_last_log 2>/dev/null)" ]; then
			embedded_mode_failed_db="$(sed -n 60p "$latest_file" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" || read $embedded_mode_failed_db #Module is in Embedded Mode | from 40p
			log_failed_wise_db="$(sed -n 57p "$latest_file" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" || read $log_failed_wise_db #read text on line 37. Contains FAILED | from 37p
			log_failed_wise_fw_db="$(sed -n 62p "$latest_file" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" || read $log_failed_wise_fw_db #read text on line 42. fetch firmware version | from 42p
			log_failed_wise_bl_db="$(sed -n 64p "$latest_file" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" || read $log_failed_wise_bl_db #read text on line 44. fetch bootloader version | from 44p
			log_failed_wise_result_db="$(sed -n 54p "$latest_file" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" || read $log_failed_wise_result_db #read text on line 34 | from 34p
		fi
	fi

	# logs failed with firmware | Single Band
	if [ -n "$(ls $directory$testlog)" ]; then #check if directory is not empty
		if [ -f "$(ls $directory$testlog/$get_last_log 2>/dev/null)" ]; then
			embedded_mode_failed_sb="$(sed -n 40p "$latest_file" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" || read $embedded_mode_failed_sb #Module is in Embedded Mode
			log_failed_wise_sb="$(sed -n 37p "$latest_file" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" || read $log_failed_wise_sb #read text on line 37. Contains FAILED
			log_failed_wise_fw_sb="$(sed -n 42p "$latest_file" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" || read $log_failed_wise_fw_sb #read text on line 42. fetch firmware version
			log_failed_wise_bl_sb="$(sed -n 44p "$latest_file" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" || read $log_failed_wise_bl_sb #read text on line 44. fetch bootloader version
			log_failed_wise_result_sb="$(sed -n 34p "$latest_file" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" || read $log_failed_wise_result_sb #read text on line 34
		fi
	fi

	# logs failed without firmware | Dual Band
	if [ -n "$(ls $directory$testlog)" ]; then #check if directory is not empty
		if [ -f "$(ls $directory$testlog/$get_last_log 2>/dev/null)" ]; then
			hosted_mode_failed_db="$(sed -n 60p "$latest_file" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" || read $hosted_mode_failed_db #Module is in Hosted Mode
			log_failed_nlink_db="$(sed -n 57p "$latest_file" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" || read $log_failed_nlink_db #read text on line 57
			log_failed_nlink_bl_db="$(sed -n 62p "$latest_file" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" || read $log_failed_nlink_bl_db #read text on line 62. fetch bootloader version
			log_failed_nlink_result_db="$(sed -n 54p "$latest_file" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" || read $log_failed_nlink_result_db #read text on line 54
		fi
	fi

	# logs failed without firmware | Single Band
	if [ -n "$(ls $directory$testlog)" ]; then #check if directory is not empty
		if [ -f "$(ls $directory$testlog/$get_last_log 2>/dev/null)" ]; then
			hosted_mode_failed_sb="$(sed -n 40p "$latest_file" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" || read $hosted_mode_failed_sb #Module is in Hosted Mode
			log_failed_nlink_sb="$(sed -n 37p "$latest_file" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" || read $log_failed_nlink_sb #read text on line 37
			log_failed_nlink_bl_sb="$(sed -n 42p "$latest_file" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" || read $log_failed_nlink_bl_sb #read text on line 42. fetch bootloader version
			log_failed_nlink_result_sb="$(sed -n 34p "$latest_file" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')" || read $log_failed_nlink_result_sb #read text on line 34
		fi
	fi

	# Read test result
	if [[ ${latest_file:0:6} = "RS9113" ]]; then # If result is passed
		if [[ $hosted_mode_passed_sb = "Module is in Hosted Mode" && $log_passed_nlink_sb = "PASSED" ]]; then # If Nlink Passed
			# echo "nlink passed single band"
			echo "QR         : $latest_qr"
			echo "Mac        : ${mac_add:22}"
			echo "Bootloader : ${log_passed_nlink_bl_sb:25}"
			echo -e "Result     : \e[1;32m$log_passed_nlink_sb\e[0m"
			echo
		fi

		if [[ $hosted_mode_passed_db = "Module is in Hosted Mode" && $log_passed_nlink_db = "PASSED" ]]; then # If Nlink Passed
			# echo "nlink passed dual band"
			echo "QR         : $latest_qr"
			echo "Mac        : ${mac_add:22}"
			echo "Bootloader : ${log_passed_nlink_bl_db:25}"
			echo -e "Result     : \e[1;32m$log_passed_nlink_db\e[0m"
			echo
		fi

		if [[ $embedded_mode_passed_sb = "Module is in Embedded Mode" && $log_passed_wise_sb = "PASSED" ]]; then # If Wise Passed
			# echo "wise passed single band"
			echo "QR         : $latest_qr"
			echo "Mac        : ${mac_add:22}"
			echo "Firmware   : ${log_passed_wise_fw_sb:23}"
			echo "Bootloader : ${log_passed_wise_bl_sb:25}"
			echo -e "Result     : \e[1;32m$log_passed_wise_sb\e[0m"
			echo
		fi

		if [[ $embedded_mode_passed_db = "Module is in Embedded Mode" && $log_passed_wise_db = "PASSED" ]]; then # If Wise Passed
			# echo "wise passed dual band"
			echo "QR         : $latest_qr"
			echo "Mac        : ${mac_add:22}"
			echo "Firmware   : ${log_passed_wise_fw_db:23}"
			echo "Bootloader : ${log_passed_wise_bl_db:25}"
			echo -e "Result     : \e[1;32m$log_passed_wise_db\e[0m"
			echo
		fi
	else # If result is failed
		if [[ $hosted_mode_failed_sb = "Module is in Hosted Mode" && $log_failed_nlink_sb = "FAILED"  ]]; then # If Nlink Failed
			# echo "nlink failed single band"
			echo "QR         : $latest_qr"
			echo "Bootloader : ${log_failed_nlink_bl_sb:25}"
			echo -e "Result     : \e[1;91m$log_failed_nlink_sb\e[0m"
			echo -e "             \e[1;91m$log_failed_nlink_result_sb\e[0m"
			echo
		fi

		if [[ $hosted_mode_failed_db = "Module is in Hosted Mode" && $log_failed_nlink_db = "FAILED"  ]]; then # If Nlink Failed
			# echo "nlink failed dual band"
			echo "QR         : $latest_qr"
			echo "Bootloader : ${log_failed_nlink_bl_db:25}"
			echo -e "Result     : \e[1;91m$log_failed_nlink_db\e[0m"
			echo -e "             \e[1;91m$log_failed_nlink_result_db\e[0m"
			echo
		fi

		if [[ $embedded_mode_failed_sb = "Module is in Embedded Mode" && $log_failed_wise_sb = "FAILED" ]]; then #If Wise Passed
			# echo "wise failed singe band"
			echo "QR         : $latest_qr"
			echo "Firmware   : ${log_failed_wise_fw_sb:23}"
			echo "Bootloader : ${log_failed_wise_bl_sb:25}"
			echo -e "Result     : \e[1;91m$log_failed_wise_sb\e[0m"
			echo -e "             \e[1;91m$log_failed_wise_result_sb\e[0m"
			echo	
		fi

		if [[ $embedded_mode_failed_db = "Module is in Embedded Mode" && $log_failed_wise_db = "FAILED" ]]; then #If Wise Passed
			# echo "wise failed dual band"
			echo "QR         : $latest_qr"
			echo "Firmware   : ${log_failed_wise_fw_db:23}"
			echo "Bootloader : ${log_failed_wise_bl_db:25}"
			echo -e "Result     : \e[1;91m$log_failed_wise_db\e[0m"
			echo -e "             \e[1;91m$log_failed_wise_result_db\e[0m"
			echo	
		fi	
	fi
fi

# Create calibration_mac_all directory
if [ ! -d $mac_all ]; then # check if directory do not exist then create directory
	mkdir $mac_all
fi

# Check if there is a duplicated mac address
check_dup_mac_via_mac_all_dir() {
	# Check duplicate mac address via mac_all directory -- recommended for faster script runtime
	if [[ -d "$directory$testlog" ]]; then # checked if directory is existing
		match_log_file=$(ls $directory$testlog/*"${get_wlan_mac}_${get_qr_code}"* 2>/dev/null) # Using ls to check for matching files
		matched_file=$(ls $mac_all/*"_${get_wlan_mac}_"* 2>/dev/null)  # Using ls to check for matching files
		matched_refence=$(ls $mac_all/*"${get_wlan_mac}_${get_qr_code}"* 2>/dev/null) # Using ls to check for matching files

		if [ -n "$match_log_file" ]; then
			if [ -n "$matched_file" ]; then  # Check if matched_file is not empty
				count_match=$(ls $matched_file 2>/dev/null | wc -l)

				if [ $count_match -gt 2 ]; then
					echo -e "\e[91m$count_match Duplicated $get_wlan_mac mac detected!"
					echo -e "\n $matched_file \n" | awk -F/ '{print $NF}'
					echo -e "\e[91mImmediately inform assigned Test Engineer.\e[0m"
					echo
				fi
			fi
		fi
	fi
}

check_dup_mac_via_mac_all_txt() {
	# Check duplicate mac address via mac_all.txt file
	if [[ -d "$directory$testlog" ]]; then # checked if directory is existing
		while IFS= read -r line
		do
			# echo "$line"
			get_mac=$(echo "$line" | awk -F '_' '{print $(NF-1)}')
			get_qr=$(echo "$line" | awk -F '_' '{print substr($NF, 0,11)}') 
			# get_log=$(ls *"${get_mac}_${get_qr}"*) #----Error if file is not in the directory

			# get_log=$(ls *"${get_mac}_${get_qr}"* 2>&1)
			# if [ $? -ne 0 ]; then #---> /dev/null 2>&1 effectively suppressing any output.
			# 	get_log=$(ls *"${get_mac}_${get_qr}"* > /dev/null 2>&1)
			# 	# echo nothing
			# else
			# 	get_log=$(ls *"${get_mac}_${get_qr}"*)
			# fi

			# echo $line
			# echo $latest_file
			# echo $get_mac $get_wlan_mac
			# echo $get_qr $get_qr_code

			# echo ${latest_log:2} "latest log"
			# echo -e $latest_file "latest file\n"

			# if [[ -d $directory$testlog && ${latest_log:2} == $latest_file ]]; then #--- check if test data log directory exist and latest file on time stamp vs lates file on refence file
			if [ -d $directory$testlog ]; then #--- check if test data log directory exist
				if [ -n "$(ls $directory$testlog)" ]; then #--- check if test data log directory is not empty
					# if [[ $line == $latest_file ]]; then #--- check refence file vs actual log

						# echo "MAC : " $get_mac "> from file ," $get_wlan_mac "> from scan"
						# echo -e "QR  : " $get_qr "  > from file ," $get_qr_code "  > from scan\n"

						if [ -f $directory$testlog/*"${get_wlan_mac}_${get_qr_code}"* ]; then
							if [[ "$get_mac" == "$get_wlan_mac" && "$get_qr" != "$get_qr_code" ]]; then
								# echo "MAC : " $get_mac "> from file ," $get_wlan_mac "> from scan"
								# echo -e "QR  : " $get_qr "  > from file ," $get_qr_code "  > from scan\n"

								echo -e "\e[91mDuplicated $get_wlan_mac mac detected!"
								echo -e "\e[91mImmediately inform assigned Test Engineer.\e[0m"
								echo
							fi
						fi
					# fi
				fi
			fi
			# fi	
		done < "$mac_all_file"
	fi
}

check_dup_mac_via_mac_all_dir

# Copy test data logs to calibration_mac_all
if [ ! -f $mac_all/$get_last_log 2>/dev/null ]; then # copy pass test data log if not existing on mac all
	if [ -f $directory$testlog/$get_last_log 2>/dev/null ]; then # check if the current test data is existing on test_5_log
		# pwd

		if [ -f $directory$testlog/*"${get_wlan_mac}_${get_qr_code}"* ]; then
			cp $get_last_log $mac_all
			echo $get_last_log >> $mac_all_file
		fi		
	fi
fi

# # Base on locate directory
# # Check if there is a duplicated mac address
# for file in "$mac_all"/*; do #--- Check all mac on calibration_mac_all directory
# 	get_mac=$(echo "$file" | awk -F '_' '{print $(NF-1)}')
# 	get_qr=$(echo "$file" | awk -F '_' '{print substr($NF, 0,11)}') 
# 	# get_log=$(ls *"${get_mac}_${get_qr}"*) #----Error if file is not in the directory

# 	get_log=$(ls *"${get_mac}_${get_qr}"* 2>&1)
# 	if [ $? -ne 0 ]; then #---> /dev/null 2>&1 effectively suppressing any output.
# 		get_log=$(ls *"${get_mac}_${get_qr}"* > /dev/null 2>&1)
# 		# echo nothing
# 	else
# 		get_log=$(ls *"${get_mac}_${get_qr}"*)
# 	fi

# 	if [[ -d $directory$testlog && ${latest_log:2} == $latest_file ]]; then #--- check if test data log directory exist and latest file on time stamp vs lates file on refence file
# 		if [ -n "$(ls $directory$testlog)" ]; then #--- check if test data log directory is not empty
# 			if [[ $get_log == $latest_file ]]; then #--- check refence file vs actual log
# 				if [[ $get_mac == $get_wlan_mac && $get_qr != $get_qr_code ]]; then
# 					echo "MAC : " $get_mac "> from file ," $get_wlan_mac "> from scan"
# 					echo -e "QR  : " $get_qr "  > from file ," $get_qr_code "  > from scan\n"

# 					echo -e "\e[91mDuplicated $get_wlan_mac mac detected!"
# 					echo -e "\e[91mImmediately inform assigned Test Engineer.\e[0m"
# 					echo
# 				fi
# 			fi
# 		fi
# 	fi
# done

s0n() {
	# find $directory$testlog -maxdepth 1 -name "*S0N*" | wc -l

	# v4p8
    # find $directory$testlog -maxdepth 1 -name "RS9113_[N0BZ]*_S0N_[0-9A-F]*.txt" | wc -l

	# v5p0
	# find "$directory$testlog" -maxdepth 1 -name "RS9113_[N0BZ]*_S0N_[0-9A-F]*_[0-9]*BC[A-Z0-9]*.txt" | wc -l

	# v4p8 or v5p0
	# find $directory$testlog -maxdepth 1 -name "RS9113_[N0BZ]*_S0N_[0-9A-F]*.txt" | wc -l #|| find "$directory$testlog" -maxdepth 1 -name "RS9113_[N0BZ]*_S0N_[0-9A-F]*_[0-9]*BC[A-Z0-9]*.txt" | wc -l

	# new counter
	v4p8_pass='^RS9113_[NB0Z]{3}_S0N_[A-F0-9]{12,13}\.txt$'
	v5p0_pass='^RS9113_[NB0Z]{3}_S0N_[A-F0-9]{12,13}_[0-9]{4}BC[A-HJ-NP-Z1-9]{5}\.txt$'
	
	cd $directory$testlog
	declare -i count=0
	
	for file in *; do
		if [[ $file =~ $v5p0_pass ]]; then
		# echo "Matching file: $file"
		count=$(($count+1))
		# Perform actions on the matching file here
	fi
	done
	echo $count
}

s0w() {
    # find $directory$testlog -maxdepth 1 -name "*S0W*" | wc -l

	# v4p8
    # find $directory$testlog -maxdepth 1 -name "RS9113_[N0BZ]*_S0W_[0-9A-F]*.txt" | wc -l

	# v5p0
	# find "$directory$testlog" -maxdepth 1 -name "RS9113_[N0BZ]*_S0W_[0-9A-F]*_[0-9]*BC[A-Z0-9]*.txt" | wc -l

	# v4p8 or v5p0
	# find $directory$testlog -maxdepth 1 -name "RS9113_[N0BZ]*_S0W_[0-9A-F]*.txt" | wc -l #|| find "$directory$testlog" -maxdepth 1 -name "RS9113_[N0BZ]*_S0W_[0-9A-F]*_[0-9]*BC[A-Z0-9]*.txt" | wc -l

	# new counter
	v4p8_pass='^RS9113_[NB0Z]{3}_S0W_[A-F0-9]{12,13}\.txt$'
	v5p0_pass='^RS9113_[NB0Z]{3}_S0W_[A-F0-9]{12,13}_[0-9]{4}BC[A-HJ-NP-Z1-9]{5}\.txt$'
	
	cd $directory$testlog
	declare -i count=0
	
	for file in *; do
		if [[ $file =~ $v5p0_pass ]]; then
		# echo "Matching file: $file"
		count=$(($count+1))
		# Perform actions on the matching file here
	fi
	done
	echo $count
}

d0n() {
    # find $directory$testlog -maxdepth 1 -name "*D0N*" | wc -l

	# v4p8
    # find $directory$testlog -maxdepth 1 -name "RS9113_[N0BZ]*_D0N_[0-9A-F]*.txt" | wc -l

	# v5p0
	# find "$directory$testlog" -maxdepth 1 -name "RS9113_[N0BZ]*_D0N_[0-9A-F]*_[0-9]*BC[A-Z0-9]*.txt" | wc -l

	# v4p8 or v5p0
	# find $directory$testlog -maxdepth 1 -name "RS9113_[N0BZ]*_D0N_[0-9A-F]*.txt" | wc -l #|| find "$directory$testlog" -maxdepth 1 -name "RS9113_[N0BZ]*_D0N_[0-9A-F]*_[0-9]*BC[A-Z0-9]*.txt" | wc -l

	# new counter
	v4p8_pass='^RS9113_[NB0Z]{3}_D0N_[A-F0-9]{12,13}\.txt$'
	v5p0_pass='^RS9113_[NB0Z]{3}_D0N_[A-F0-9]{12,13}_[0-9]{4}BC[A-HJ-NP-Z1-9]{5}\.txt$'
	
	cd $directory$testlog
	declare -i count=0
	
	for file in *; do
		if [[ $file =~ $v5p0_pass ]]; then
		# echo "Matching file: $file"
		count=$(($count+1))
		# Perform actions on the matching file here
	fi
	done
	echo $count
}

d0w() {
    # find $directory$testlog -maxdepth 1 -name "*D0W*" | wc -l

	# v4p8
    # find $directory$testlog -maxdepth 1 -name "RS9113_[N0BZ]*_D0W_[0-9A-F]*.txt" | wc -l
	
	# v5p0
	# find "$directory$testlog" -maxdepth 1 -name "RS9113_[N0BZ]*_D0W_[0-9A-F]*_[0-9]*BC[A-Z0-9]*.txt" | wc -l

	# v4p8 or v5p0
	# find $directory$testlog -maxdepth 1 -name "RS9113_[N0BZ]*_D0W_[0-9A-F]*.txt" | wc -l #|| find "$directory$testlog" -maxdepth 1 -name "RS9113_[N0BZ]*_D0W_[0-9A-F]*_[0-9]*BC[A-Z0-9]*.txt" | wc -l

	# new counter
	v4p8_pass='^RS9113_[NB0Z]{3}_D0W_[A-F0-9]{12,13}\.txt$'
	v5p0_pass='^RS9113_[NB0Z]{3}_D0W_[A-F0-9]{12,13}_[0-9]{4}BC[A-HJ-NP-Z1-9]{5}\.txt$'
	
	cd $directory$testlog
	declare -i count=0
	
	for file in *; do
		if [[ $file =~ $v5p0_pass ]]; then
		# echo "Matching file: $file"
		count=$(($count+1))
		# Perform actions on the matching file here
	fi
	done
	echo $count
}

d0f() {
   	# find $directory$testlog -maxdepth 1 -name "*D0W_DRG*" | wc -l

	# v4p8
   	# find $directory$testlog -maxdepth 1 -name "RS9113_[N0BZ]*_D0W_DRG_[0-9A-F]*.txt" | wc -l

	# v5p0
	# find "$directory$testlog" -maxdepth 1 -name "RS9113_[N0BZ]*_D0W_DRG_[0-9A-F]*_[0-9]*BC[A-Z0-9]*.txt" | wc -l

	# v4p8 or v5p0
	# find $directory$testlog -maxdepth 1 -name "RS9113_[N0BZ]*_D0W_DRG_[0-9A-F]*.txt" | wc -l #|| find "$directory$testlog" -maxdepth 1 -name "RS9113_[N0BZ]*_D0W_DRG_[0-9A-F]*_[0-9]*BC[A-Z0-9]*.txt" | wc -l

	# new counter
	v4p8_pass='^RS9113_[NB0Z]{3}_D0W_DRG_[A-F0-9]{12,13}\.txt$'
	v5p0_pass='^RS9113_[NB0Z]{3}_D0W_DRG_[A-F0-9]{12,13}_[0-9]{4}BC[A-HJ-NP-Z1-9]{5}\.txt$'
	
	cd $directory$testlog
	declare -i count=0
	
	for file in *; do
		if [[ $file =~ $v5p0_pass ]]; then
		# echo "Matching file: $file"
		count=$(($count+1))
		# Perform actions on the matching file here
	fi
	done
	echo $count
}

s1n() {
   	# find $directory$testlog -maxdepth 1 -name "*S1N*" | wc -l
   	
	# v4p8
	# find $directory$testlog -maxdepth 1 -name "RS9113_[N0BZ]*_S1N_[0-9A-F]*.txt" | wc -l
	
	# v5p0
	# find "$directory$testlog" -maxdepth 1 -name "RS9113_[N0BZ]*_S1N_[0-9A-F]*_[0-9]*BC[A-Z0-9]*.txt" | wc -l

	# v4p8 or v5p0
	# find $directory$testlog -maxdepth 1 -name "RS9113_[N0BZ]*_S1N_[0-9A-F]*.txt" | wc -l #|| find "$directory$testlog" -maxdepth 1 -name "RS9113_[N0BZ]*_S1N_[0-9A-F]*_[0-9]*BC[A-Z0-9]*.txt" | wc -l

	# new counter
	v4p8_pass='^RS9113_[NB0Z]{3}_S1N_[A-F0-9]{12,13}\.txt$'
	v5p0_pass='^RS9113_[NB0Z]{3}_S1N_[A-F0-9]{12,13}_[0-9]{4}BC[A-HJ-NP-Z1-9]{5}\.txt$'
	
	cd $directory$testlog
	declare -i count=0
	
	for file in *; do
		if [[ $file =~ $v5p0_pass ]]; then
		# echo "Matching file: $file"
		count=$(($count+1))
		# Perform actions on the matching file here
	fi
	done
	echo $count
}

s1w() {
   	# find $directory$testlog -maxdepth 1 -name "*S1W*" | wc -l

	# v4p8
	# find "$directory$testlog" -maxdepth 1 -name "RS9113_[NB0Z]*_S1W_[A-F0-9]*.txt" | wc -l

   	# v5p0
	# find "$directory$testlog" -maxdepth 1 -name "RS9113_[N0BZ]*_S1W_[0-9A-F]*_[0-9]*BC[A-Z0-9]*.txt" | wc -l

	# v4p8 or v5p0
	# find "$directory$testlog" -maxdepth 1 -name 'RS9113_[NB0Z]*_S1W_[A-F0-9]*.txt' | wc -l #|| find "$directory$testlog" -maxdepth 1 -name "RS9113_[N0BZ]*_S1W_[0-9A-F]*_[0-9]*BC[A-Z0-9]*.txt" | wc -l

	# new counter
	v4p8_pass='^RS9113_[NB0Z]{3}_S1W_[A-F0-9]{12,13}\.txt$'
	v5p0_pass='^RS9113_[NB0Z]{3}_S1W_[A-F0-9]{12,13}_[0-9]{4}BC[A-HJ-NP-Z1-9]{5}\.txt$'
	
	cd $directory$testlog
	declare -i count=0
	
	for file in *; do
		if [[ $file =~ $v5p0_pass ]]; then
		# echo "Matching file: $file"
		count=$(($count+1))
		# Perform actions on the matching file here
	fi
	done
	echo $count
}

d1n() {
    # find $directory$testlog -maxdepth 1 -name "*D1N*" | wc -l

	# v4p8
   	# find $directory$testlog -maxdepth 1 -name "RS9113_[N0BZ]*_D1N_[0-9A-F]*.txt" | wc -l

	# v5p0
	# find "$directory$testlog" -maxdepth 1 -name "RS9113_[N0BZ]*_D1N_[0-9A-F]*_[0-9]*BC[A-Z0-9]*.txt" | wc -l

	# v4p8 or v5p0
	# find $directory$testlog -maxdepth 1 -name "RS9113_[N0BZ]*_D1N_[0-9A-F]*.txt" | wc -l #|| find "$directory$testlog" -maxdepth 1 -name "RS9113_[N0BZ]*_D1N_[0-9A-F]*_[0-9]*BC[A-Z0-9]*.txt" | wc -l

	# new counter
	v4p8_pass='^RS9113_[NB0Z]{3}_D1N_[A-F0-9]{12,13}\.txt$'
	v5p0_pass='^RS9113_[NB0Z]{3}_D1N_[A-F0-9]{12,13}_[0-9]{4}BC[A-HJ-NP-Z1-9]{5}\.txt$'
	
	cd $directory$testlog
	declare -i count=0
	
	for file in *; do
		if [[ $file =~ $v5p0_pass ]]; then
		# echo "Matching file: $file"
		count=$(($count+1))
		# Perform actions on the matching file here
	fi
	done
	echo $count
}

d1w() {
    # find $directory$testlog -maxdepth 1 -name "*D1W*" | wc -l

	# v4p8
    # find $directory$testlog -maxdepth 1 -name "RS9113_[N0BZ]*_D1W_[0-9A-F]*.txt" | wc -l

	# v5p0
	# find "$directory$testlog" -maxdepth 1 -name "RS9113_[N0BZ]*_D1W_[0-9A-F]*_[0-9]*BC[A-Z0-9]*.txt" | wc -l

	# v4p8 or v5p0
	# find $directory$testlog -maxdepth 1 -name "RS9113_[N0BZ]*_D1W_[0-9A-F]*.txt" | wc -l #|| find "$directory$testlog" -maxdepth 1 -name "RS9113_[N0BZ]*_D1W_[0-9A-F]*_[0-9]*BC[A-Z0-9]*.txt" | wc -l

	# new counter
	v4p8_pass='^RS9113_[NB0Z]{3}_D1W_[A-F0-9]{12,13}\.txt$'
	v5p0_pass='^RS9113_[NB0Z]{3}_D1W_[A-F0-9]{12,13}_[0-9]{4}BC[A-HJ-NP-Z1-9]{5}\.txt$'
	
	cd $directory$testlog
	declare -i count=0
	
	for file in *; do
		if [[ $file =~ $v5p0_pass ]]; then
		# echo "Matching file: $file"
		count=$(($count+1))
		# Perform actions on the matching file here
	fi
	done
	echo $count
}

d1f() {
   	# find $directory$testlog -maxdepth 1 -name "*D1W*" | wc -l

	# v4p8
    # find $directory$testlog -maxdepth 1 -name "RS9113_[N0BZ]*_D1F_[0-9A-F]*.txt" | wc -l
	
	# v5p0
	# find "$directory$testlog" -maxdepth 1 -name "RS9113_[N0BZ]*_D1F_[0-9A-F]*_[0-9]*BC[A-Z0-9]*.txt" | wc -l

	# v4p8 or v5p0
	# find $directory$testlog -maxdepth 1 -name "RS9113_[N0BZ]*_D1F_[0-9A-F]*.txt" | wc -l #|| find "$directory$testlog" -maxdepth 1 -name "RS9113_[N0BZ]*_D1F_[0-9A-F]*_[0-9]*BC[A-Z0-9]*.txt" | wc -l

	# new counter
	v4p8_pass='^RS9113_[NB0Z]{3}_D1F_[A-F0-9]{12,13}\.txt$'
	v5p0_pass='^RS9113_[NB0Z]{3}_D1F_[A-F0-9]{12,13}_[0-9]{4}BC[A-HJ-NP-Z1-9]{5}\.txt$'
	
	cd $directory$testlog
	declare -i count=0
	
	for file in *; do
		if [[ $file =~ $v5p0_pass ]]; then
		# echo "Matching file: $file"
		count=$(($count+1))
		# Perform actions on the matching file here
	fi
	done
	echo $count
}

# count test data log base on command e.g. S0N, S0W, D0N, D0W, DOF, S1N, S1W, D1N, D1W, D1F
rs9113countcal() {
    if [[ -d "$directory$testlog" ]]; then # checked if directory is existing
		declare -i v=0

    	if [ $(s0n) != 0 ]; then
			echo -n "S0N     : "
		    s0n
		    v+=1
	    fi

   		if [ $(s0w) != 0 ]; then
		    echo -n "S0W     : "
		    s0w
		    v+=1
	    fi

   		if [ $(d0n) != 0 ]; then
			echo -n "D0N     : "
		    d0n
		    v+=1
	    fi

	    if [ $(d0w) != 0 ]; then
			echo -n "D0W     : "
		    d0w
		    v+=1
	    fi

	    if [ $(d0f) != 0 ]; then
			echo -n "D0W_DRG : "
		    d0f
		    v+=1
	    fi

	    if [ $(s1n) != 0 ]; then
			echo -n "S1N     : "
		    s1n
		    v+=1
	    fi

	    if [ $(s1w) != 0 ]; then
			echo -n "S1W     : "
    		s1w
	    	v+=1
	    fi

	    if [ $(d1n) != 0 ]; then
			echo -n "D1N     : "
		    d1n
		    v+=1
	    fi

	    if [ $(d1w) != 0 ]; then
			echo -n "D1W     : "
		    d1w
		    v+=1
	    fi

	    if [ $(d1f) != 0 ]; then
			echo -n "D1F     : "
		    d1f
		    v+=1
	    fi

	    # find . -type f -name "RS9113*[NB0Z]*D1W*[A-F0-9].txt"													- counting pass on calibration
	    # find . -type f -name "[a-zA-Z]*_[a-zA-Z]*_[0-9]*_[0-9]*_[0-9]*_[0-9]_[0-9]*.txt"						- counting failed on calibration

		# find . -type f -name "RS9113_[N0BZ]*_D1W_[0-9A-F]*_[0-9]*BC[A-Z0-9]*.txt"								- counting pass on calibration v5p0
		# find . -type f -name "[a-zA-Z]*_[a-zA-Z]*_[0-9]*_[0-9]*_[0-9]*_[0-9]_[0-9]*_[0-9]*BC[A-Z0-9]*.txt"	- counting failed on calibration v5p0

		cd $directory$testlog
		
		# Linux
		# v4p8_fail='^[A-Za-z]{3}_[A-Za-z]{3}_(_[1-9]|[0-9]{2})_[0-9]{2}:[0-9]{2}:[0-9]{2}_[0-9]{4}\.txt$'
		# v5p0_fail='^[A-Za-z]{3}_[A-Za-z]{3}_(_[1-9]|[0-9]{2})_[0-9]{2}\:[0-9]{2}\:[0-9]{2}_[0-9]{4}_[0-9]{4}BC[A-HJ-NP-Z1-9]{5}\.txt$'
		# v4p8_fail=^[A-Za-z]{3}_[A-Za-z]{3}_[0-9]{2}_[0-9]{2}\:[0-9]{2}\:[0-9]{2}_[0-9]{4}.txt$
		# v5p0_fail=^[A-Za-z]{3}_[A-Za-z]{3}_[0-9]{2}_[0-9]{2}\:[0-9]{2}\:[0-9]{2}_[0-9]{4}_[0-9]{4}BC[A-HJ-NP-Z1-9]{5}.txt$

		# Windows
		v4p8_fail=^[A-Za-z]{3}_[A-Za-z]{3}_[0-9]{2}_[0-9]{2}_[0-9]{2}_[0-9]{2}_[0-9]{4}.txt$
		v5p0_fail='^[A-Za-z]{3}_[A-Za-z]{3}_[0-9]{2}_[0-9]{2}_[0-9]{2}_[0-9]{2}_[0-9]{4}_[0-9]{4}BC[A-HJ-NP-Z1-9]{5}.txt$'
	        
		declare -i count=0
		for file in *; do
			if [[ $file =~ $v5p0_fail ]]; then
				count=$(($count+1))
			fi
		done
		
		calpass=$(($(s0n)+$(s0w)+$(d0n)+$(d0w)+$(d0f)+$(s1n)+$(s1w)+$(d1n)+$(d1w)+$(d1f)))
	    calfail=$count
		caltested=$((calpass+calfail))
		# calfail=$(find "$directory$testlog" -type f -name "[a-zA-Z]*_[a-zA-Z]*_[0-9]*_[0-9]*[0-9]*[0-9]_[0-9]*.txt" | wc -l)
		
		# total tested count
	    echo -e "\nTested"
	    echo $caltested

		# total passed count
	    echo -e "\n\e[42mPassed\e[0m"
	    echo -e "\e[32m$calpass\e[0m"

		# total failed count
	    echo -e "\n\e[41mFailed\e[0m"
	    echo -e "\e[31m$calfail\e[0m"
   fi
}

rs9113countcal

# Developed by: Macky