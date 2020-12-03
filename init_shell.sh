#!/system/bin/sh
cd /mnt/expand/df9b4de7-ca62-442f-9ed1-bd4fe795b26e/user/0/com.vmos.gbi/osimg/r/ot01/
mkdir -p /mnt/expand/df9b4de7-ca62-442f-9ed1-bd4fe795b26e/user/0/com.vmos.gbi/osimg/r/ot01/dev/socket
mkdir -p /mnt/expand/df9b4de7-ca62-442f-9ed1-bd4fe795b26e/user/0/com.vmos.gbi/osimg/r/ot01/dev/myproc
chmod -R 777 /mnt/expand/df9b4de7-ca62-442f-9ed1-bd4fe795b26e/user/0/com.vmos.gbi/osimg/r/ot01/dev
rm -rf /mnt/expand/df9b4de7-ca62-442f-9ed1-bd4fe795b26e/user/0/com.vmos.gbi/osimg/r/ot01/dev/__properties__
rm -rf /mnt/expand/df9b4de7-ca62-442f-9ed1-bd4fe795b26e/user/0/com.vmos.gbi/osimg/r/ot01/dev/socket/*
rm -rf /mnt/expand/df9b4de7-ca62-442f-9ed1-bd4fe795b26e/user/0/com.vmos.gbi/osimg/r/ot01/dev/__kmsg__
rm -rf /mnt/expand/df9b4de7-ca62-442f-9ed1-bd4fe795b26e/user/0/com.vmos.gbi/osimg/r/ot01/dev/myproc/*
rm -rf /mnt/expand/df9b4de7-ca62-442f-9ed1-bd4fe795b26e/user/0/com.vmos.gbi/osimg/r/ot01/data/myproc/*
rm -rf /mnt/expand/df9b4de7-ca62-442f-9ed1-bd4fe795b26e/user/0/com.vmos.gbi/osimg/r/ot01/proc/map*
mkdir -p /mnt/expand/df9b4de7-ca62-442f-9ed1-bd4fe795b26e/user/0/com.vmos.gbi/osimg/r/ot01/data/myproc
mkdir -p /mnt/expand/df9b4de7-ca62-442f-9ed1-bd4fe795b26e/user/0/com.vmos.gbi/osimg/socket/01/vmhal
mkdir -p /mnt/expand/df9b4de7-ca62-442f-9ed1-bd4fe795b26e/user/0/com.vmos.gbi/osimg/socket/01/vmhal/power_supply
mkdir -p /mnt/expand/df9b4de7-ca62-442f-9ed1-bd4fe795b26e/user/0/com.vmos.gbi/osimg/socket/01/vmhal/power_supply/battery
mkdir -p /mnt/expand/df9b4de7-ca62-442f-9ed1-bd4fe795b26e/user/0/com.vmos.gbi/osimg/socket/01/vmhal/power_supply/dc
mkdir -p /mnt/expand/df9b4de7-ca62-442f-9ed1-bd4fe795b26e/user/0/com.vmos.gbi/osimg/socket/01/vmhal/power_supply/usb
touch /mnt/expand/df9b4de7-ca62-442f-9ed1-bd4fe795b26e/user/0/com.vmos.gbi/osimg/socket/01/vmhal/power_supply/battery/capacity
touch /mnt/expand/df9b4de7-ca62-442f-9ed1-bd4fe795b26e/user/0/com.vmos.gbi/osimg/socket/01/vmhal/power_supply/battery/type
touch /mnt/expand/df9b4de7-ca62-442f-9ed1-bd4fe795b26e/user/0/com.vmos.gbi/osimg/socket/01/vmhal/power_supply/battery/status
echo "Battery">/mnt/expand/df9b4de7-ca62-442f-9ed1-bd4fe795b26e/user/0/com.vmos.gbi/osimg/socket/01/vmhal/power_supply/battery/type
touch /mnt/expand/df9b4de7-ca62-442f-9ed1-bd4fe795b26e/user/0/com.vmos.gbi/osimg/socket/01/vmhal/power_supply/dc/type
touch /mnt/expand/df9b4de7-ca62-442f-9ed1-bd4fe795b26e/user/0/com.vmos.gbi/osimg/socket/01/vmhal/power_supply/dc/online
echo "Mains">/mnt/expand/df9b4de7-ca62-442f-9ed1-bd4fe795b26e/user/0/com.vmos.gbi/osimg/socket/01/vmhal/power_supply/dc/type
touch /mnt/expand/df9b4de7-ca62-442f-9ed1-bd4fe795b26e/user/0/com.vmos.gbi/osimg/socket/01/vmhal/power_supply/usb/type
touch /mnt/expand/df9b4de7-ca62-442f-9ed1-bd4fe795b26e/user/0/com.vmos.gbi/osimg/socket/01/vmhal/power_supply/usb/online
mkdir -p /mnt/expand/df9b4de7-ca62-442f-9ed1-bd4fe795b26e/user/0/com.vmos.gbi/osimg/socket/01/log
mv /mnt/expand/df9b4de7-ca62-442f-9ed1-bd4fe795b26e/user/0/com.vmos.gbi/osimg/socket/01/log/__my_logcat__ /mnt/expand/df9b4de7-ca62-442f-9ed1-bd4fe795b26e/user/0/com.vmos.gbi/osimg/socket/01/log/__my_logcat__.bak
ln -s /mnt/expand/df9b4de7-ca62-442f-9ed1-bd4fe795b26e/user/0/com.vmos.gbi/osimg/socket/01 /mnt/expand/df9b4de7-ca62-442f-9ed1-bd4fe795b26e/user/0/com.vmos.gbi/osimg/r/ot01/dev/socket/socket
ln -s /mnt/expand/df9b4de7-ca62-442f-9ed1-bd4fe795b26e/user/0/com.vmos.gbi/osimg/socket/ex_engine /mnt/expand/df9b4de7-ca62-442f-9ed1-bd4fe795b26e/user/0/com.vmos.gbi/osimg/r/ot01/dev/socket/socket/ex_engine
ln -s /mnt/expand/df9b4de7-ca62-442f-9ed1-bd4fe795b26e/user/0/com.vmos.gbi/osimg/socket/testa1 /mnt/expand/df9b4de7-ca62-442f-9ed1-bd4fe795b26e/user/0/com.vmos.gbi/osimg/r/ot01/dev/socket/socket/testa1
./init 720 1466 320 0 12:34:56:d6:3a:8c 9deed30a7d46 msm8937 2 352910100507940
