#!/bin/bash
ShowExample()
	{
	Example+=("#dd seek=0 of=/dev/$BaseName bs=$Sector_Size count=$Dest_Size if=/dev/urandom oflag=\"noerror,nocache,direct\"");
	Example+=("#dd seek=0 of=/dev/$BaseName bs=$Sector_Size count=$Dest_Size if=/dev/random  oflag=\"noerror,nocache,direct\"");
	Example+=("#dd seek=0 of=/dev/$BaseName bs=$Sector_Size count=$Dest_Size if=/dev/zero    oflag=\"noerror,nocache,direct\"");

	Example+=("#dd seek=$Start_point of=/dev/$StorageName bs=$Sector_Size count=$Dest_Size if=/dev/urandom oflag=\"noerror,nocache,direct\"");
	Example+=("#dd seek=$Start_point of=/dev/$StorageName bs=$Sector_Size count=$Dest_Size if=/dev/random  oflag=\"noerror,nocache,direct\"");
	Example+=("#dd seek=$Start_point of=/dev/$StorageName bs=$Sector_Size count=$Dest_Size if=/dev/zero    oflag=\"noerror,nocache,direct\"");

	Example+=("#pv --stop-at-size -s $((Dest_Size * Sector_Size)) --progress --eta --timer --rate --average-rate < /dev/urandom > /dev/$BaseName");
	Example+=("#pv --stop-at-size -s $((Dest_Size * Sector_Size)) --progress --eta --timer --rate --average-rate < /dev/random  > /dev/$BaseName");
	Example+=("#pv --stop-at-size -s $((Dest_Size * Sector_Size)) --progress --eta --timer --rate --average-rate < /dev/zero    > /dev/$BaseName");

for GetEx in "${Example[@]}";do
echo $GetEx;
done;
	}
ShowHelp()
	{
echo 'Use valid path to the storage device!
The script reading data from /sys/block/
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
	if [[ -e "$@" && -b "$@"  ]];then
		if [[ "$@" =~ [a-Z][0-9]+$ ]];then 
			DevPath="$@";
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
			ShowExample $@;	
		fi
		if [[ "$@" =~ [a-Z]+$ ]];then 
			DevPath="$@";
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
			ShowExample "$@";
		fi
	fi
	if [[ "$@" == '--help' || "$@" == '-h' ]];then
		ShowHelp;
	fi
else
ShowHelp;
fi
