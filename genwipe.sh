#!/bin/bash
ShowExample()
	{
	Example+=("$Show_part_mounts#dd seek=0 of=/dev/$BaseName bs=$Sector_Size count=$Dest_Size if=/dev/urandom oflag=\"noerror,nocache,direct\"");
	Example+=("$Show_part_mounts#dd seek=0 of=/dev/$BaseName bs=$Sector_Size count=$Dest_Size if=/dev/random  oflag=\"noerror,nocache,direct\"");
	Example+=("$Show_part_mounts#dd seek=0 of=/dev/$BaseName bs=$Sector_Size count=$Dest_Size if=/dev/zero    oflag=\"noerror,nocache,direct\"");

	Example+=("$Show_mounts#dd seek=$Start_point of=/dev/$StorageName bs=$Sector_Size count=$Dest_Size if=/dev/urandom oflag=\"noerror,nocache,direct\"");
	Example+=("$Show_mounts#dd seek=$Start_point of=/dev/$StorageName bs=$Sector_Size count=$Dest_Size if=/dev/random  oflag=\"noerror,nocache,direct\"");
	Example+=("$Show_mounts#dd seek=$Start_point of=/dev/$StorageName bs=$Sector_Size count=$Dest_Size if=/dev/zero    oflag=\"noerror,nocache,direct\"");

	Example+=("${Show_mounts}${Show_part_mounts}#pv --stop-at-size -s $((Dest_Size * Sector_Size)) --progress --eta --timer --rate --average-rate < /dev/urandom > /dev/$BaseName");
	Example+=("${Show_mounts}${Show_part_mounts}#pv --stop-at-size -s $((Dest_Size * Sector_Size)) --progress --eta --timer --rate --average-rate < /dev/random  > /dev/$BaseName");
	Example+=("${Show_mounts}${Show_part_mounts}#pv --stop-at-size -s $((Dest_Size * Sector_Size)) --progress --eta --timer --rate --average-rate < /dev/zero    > /dev/$BaseName");

for GetEx in "${Example[@]}";do
echo -e $GetEx;
done;
	}
ShowHelp()
	{
echo 'Use valid path to the storage device!
The script is reading data from sysfs located at "/sys/block/".
E=empty, no mount points found
M=mount, has mounted partitions
 Usage:
To show calculated examples for "dd" and "pv"
 genwipe.sh /dev/sdXY
To execute examples
 genwipe.sh /dev/sdXY | cut -d# -f2 | xargs sh -c
If you dont have "pv" installed then you can skip it:
 genwipe.sh /dev/sdXY | cut -d# -f2 |grep -v pv| xargs sh -c
To update information about partitions use:
 partprobe';
	}
if [[ ! -z "$@" ]];then
	if [[ -e "$1" && -b "$1"  ]];then
Get_Dev_mounts=$(lsblk -o "MOUNTPOINT" ${1/[0-9]*/}  | awk '//{if(NR>1)DM=DM sprintf($1)}END{print DM}');
if [[ -z "$Get_Dev_mounts" ]];then 
Show_mounts='E';
else
Show_mounts='\e[31mM\e[0m';
fi
		if [[ "$@" =~ [a-Z][0-9]+$ ]];then 
			DevPath="$1";
			rmPath="${DevPath/[^*]*\///}";
			PartBaseName="${rmPath/\//}";
			DevBaseName="${PartBaseName/[0-9]/}";
#Get size of partition
			Part_Start="$(cat /sys/block/$DevBaseName/$PartBaseName/start)";
			Part_Size="$( cat  /sys/block/$DevBaseName/$PartBaseName/size)";
			Logical_Sector_Size="$(cat /sys/block/$DevBaseName/queue/logical_block_size)";
			BaseName="$PartBaseName";
			StorageName="$DevBaseName";
			Dest_Size="$Part_Size"
			Sector_Size="$Logical_Sector_Size";
			Start_point="$Part_Start" 
Get_Part_mounts=$(findmnt "$1" -o TARGET  | awk '//{if(NR>1)DM=DM sprintf($1)}END{print DM}');
if [[  -z "$Get_Part_mounts" ]];then
Show_part_mounts='E';
else
Show_part_mounts='\e[31mM\e[0m';
fi
			ShowExample "$1";	
		fi

if [[  -z "$Get_Part_mounts" ]];then
Show_part_mounts="$Show_mounts"
fi
		if [[ "$1" =~ [a-Z]+$ ]];then 
			DevPath="$1";
			rmPath="${DevPath/[^*]*\///}";
			PartBaseName="${rmPath/\//}";
			DevBaseName="${PartBaseName/[0-9]/}";
#Get size of partition
#			Part_Start="$(cat /sys/block/$DevBaseName/$PartBaseName/start)";
			Part_Size="$( cat  /sys/block/$DevBaseName/size)";
			Physical_Sector_Size="$(cat /sys/block/$DevBaseName/queue/physical_block_size)";
			BaseName="$PartBaseName";
			StorageName=$BaseName;
			Dest_Size="$Part_Size";
			Sector_Size="$Physical_Sector_Size";
			Start_point=0;

			ShowExample "$1";
		fi
	fi
	if [[ "$@" == '--help' || "$@" == '-h' ]];then
		ShowHelp;
	fi
else
ShowHelp;
fi
