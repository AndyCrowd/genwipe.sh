# genwipe.sh

Use valid path to the storage device!
The script reading data from /sys/block/
 Usage:
To show calculated examples for "dd" and "pv"
 genwipe.sh /dev/sdXY
To execute examples
 genwipe.sh /dev/sdXY | cut -d# -f2 | xargs sh -c
If you dont have "pv" installed then you can skip it:
 genwipe.sh /dev/sdXY | cut -d# -f2 |grep -v pv| xargs sh -c
To update information about partitions use:
 partprobe
