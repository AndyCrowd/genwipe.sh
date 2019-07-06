#!/bin/bash
ShowExample() {
	Example+=("${Show_part_mounts}nCountEx#dd seek=0 of=/dev/$BaseName bs=$Sector_Size count=$Dest_Size if=/dev/urandom oflag=\"nocache\"")
	Example+=("${Show_part_mounts}nCountEx#dd seek=0 of=/dev/$BaseName bs=$Sector_Size count=$Dest_Size if=/dev/zero    oflag=\"direct\"")
	Example+=("${Show_mounts}nCountEx#dd seek=$Start_point of=/dev/$StorageName bs=$Sector_Size count=$Dest_Size if=/dev/urandom oflag=\"nocache\"")
	Example+=("${Show_mounts}nCountEx#dd seek=$Start_point of=/dev/$StorageName bs=$Sector_Size count=$Dest_Size if=/dev/zero    oflag=\"direct\"")
	Example+=("${Show_part_mounts}nCountEx#openssl enc -aes-256-ctr -pass pass:"'"$'"(dd if=/dev/urandom bs=128 count=1 2>/dev/null|base64)"'"'" -nosalt </dev/zero|pv --stop-at-size -bartpes $((Dest_Size * Sector_Size))|dd bs=64K of=/dev/$BaseName")
	Example+=("${Show_part_mounts}nCountEx#head -c 32 /dev/urandom | openssl enc -rc4 -nosalt -in /dev/zero -pass stdin | dd of=/dev/$BaseName bs=$Sector_Size count=$Dest_Size")
	Example+=("${Show_mounts}${Show_part_mounts}nCountEx#pv --stop-at-size -s $((Dest_Size * Sector_Size)) --progress --eta --timer --rate --average-rate < /dev/urandom > /dev/$BaseName")
	Example+=("${Show_mounts}${Show_part_mounts}nCountEx#pv --stop-at-size -s $((Dest_Size * Sector_Size)) --progress --eta --timer --rate --average-rate < /dev/zero    > /dev/$BaseName")
	Example+=("${Show_mounts}${Show_part_mounts}nCountEx#badblocks -c $Sector_Size -wsv /dev/$BaseName")

	if [[ -n  "$TestIt"  ]];then
		IFS='#'
		for GetArr in "${Example[@]}";do
			if [[  "$GetArr" =~ "dd" || "$GetArr" =~ "pv" || "$GetArr" =~ "openssl" ]]; then
				TmpEx="${GetArr/*'Ex'}"
				RmBN="${TmpEx/$BaseName/null}"
				RmN="${RmBN/$BaseName/null}"
				echo "${RmN/'seek=0'/}"
			fi
		done
	fi

	if [[ -n "$ShowExampleNumber"  || -n "$UseExamples" ]]; then
		if [[   "$ShowExampleNumber" =~ [0-9]+$ && "$ShowExampleNumber" -lt  "${#Example[@]}" ]]; then
			echo -e "${Example[ShowExampleNumber]}"
		fi
		case "$UseExamples" in
			c)
				if [[ $(echo "${Example[4]}" | grep ^E -c) != 0 ]]; then
					echo '#!/bin/bash' > /tmp/wipe.sh
					echo "${Example[4]/*'Ex#'}" >> /tmp/wipe.sh
					echo "${Example[7]/*'Ex#'}" >> /tmp/wipe.sh
					chmod +x /tmp/wipe.sh
					echo '/tmp/wipe.sh'
					cat /tmp/wipe.sh
				fi
				;;
			t)
				IFS='#'
				for GetArr in "${Example[@]}";do
					TmpEx="${GetArr/*'Ex'}"
					RmBN="${TmpEx/$BaseName/null}"
					RmN="${RmBN/$BaseName/null}"
					if [[  "$GetArr" =~ "dd" || "$GetArr" =~ "pv" || "$GetArr" =~ "openssl" ]];then
						TmpEx="${GetArr/*'Ex'}"
						RmBN="${TmpEx/$BaseName/null}"
						RmN="${RmBN/$BaseName/null}"
						echo "${RmN/'seek=0'/}"
					fi
				done
				;;
			*)
				echo 'The example number does not exist!'
				;;
		esac
	else
		CountEx=0
		for GetEx in "${Example[@]}";do
			[[ -z "$TestIt" ]] && echo -e "${GetEx/nCountEx/_$CountEx\_}"
			((CountEx++))
		done
	fi
}

ShowHelp() {
	echo 'This script helps to calculate parameters to wipe a device/partition with dd.
The script is reading data from sysfs located at "/sys/block/".
E=empty, no mount points found
M=mount, has mounted partitions
Usage:
To show calculated examples for "dd" and "pv"
genwipe.sh /dev/sdXY
To show only specific example use it'"'"'s number:
genwipe.sh /dev/sdXY 2
To show only command
genwipe.sh /dev/sdXY | cut -d# -f2
If you dont have "pv" installed then you can skip it:
genwipe.sh /dev/sdXY | cut -d# -f2 |grep -v pv
To update information about partitions use:
partprobe'
}


# ACTUAL SCRIPT STARTS HERE

if [[ "$#" -lt 1 ]]; then
	ShowHelp
fi

case "$1" in
	t)
		BaseName='null'
		StorageName='null'
		Sector_Size='512'
		Start_point='0'
		Dest_Size='1024'
		TestIt='YES'
		ShowExample
		;;
esac

if [[ -e "$1" && -b "$1"  ]];then
	if [[ "$2" =~ [0-9]+$ ]];then
		ShowExampleNumber="$2"
	fi
	if [[ "$2" =~ [a-Z]+$ ]];then
		UseExamples="$2"
	fi
	Get_Dev_mounts=$(lsblk -o "MOUNTPOINT" "${1/[0-9]*/}"  | awk '//{if(NR>1)DM=DM sprintf($1)}END{print DM}')
	if [[ -z "$Get_Dev_mounts" ]];then
		Show_mounts='E'
	else
		Show_mounts='M\e[31m!\e[0m'
	fi
	if [[ "$1" =~ [a-Z][0-9]+$ ]];then
		DevPath="$1"
		rmPath="${DevPath/[^*]*\///}"
		PartBaseName="${rmPath/\//}"
		DevBaseName="${PartBaseName/[0-9]/}"
		#Get size of partition
		Part_Start="$(cat /sys/block/"$DevBaseName"/"$PartBaseName"/start)"
		Part_Size="$( cat  /sys/block/"$DevBaseName"/"$PartBaseName"/size)"
		Logical_Sector_Size="$(cat /sys/block/"$DevBaseName"/queue/logical_block_size)"
		BaseName="$PartBaseName"
		StorageName="$DevBaseName"
		Dest_Size="$Part_Size"
		Sector_Size="$Logical_Sector_Size"
		Start_point="$Part_Start"
		Get_Part_mounts=$(findmnt "$1" -o TARGET  | awk '//{if(NR>1)DM=DM sprintf($1)}END{print DM}')
		if [[  -z "$Get_Part_mounts" ]];then
			Show_part_mounts='E'
		else
			Show_part_mounts='M\e[31m!\e[0m'
		fi
		ShowExample "$1"
	fi

	if [[  -z "$Get_Part_mounts" ]];then
		Show_part_mounts="$Show_mounts"
	fi
	if [[ "$1" =~ [a-Z]+$ ]];then
		DevPath="$1"
		rmPath="${DevPath/[^*]*\///}"
		PartBaseName="${rmPath/\//}"
		DevBaseName="${PartBaseName/[0-9]/}"
		Part_Size="$( cat  /sys/block/"$DevBaseName"/size)"
		Physical_Sector_Size="$(cat /sys/block/"$DevBaseName"/queue/physical_block_size)"
		BaseName="$PartBaseName"
		StorageName=$BaseName
		Dest_Size="$Part_Size"
		Sector_Size="$Physical_Sector_Size"
		Start_point=0

		ShowExample "$1"
	fi
fi
for opt in "$@"; do
	if [[ "$opt" == '--help' || "$opt" == '-h' ]]; then
		ShowHelp
	fi
done
exit 0
