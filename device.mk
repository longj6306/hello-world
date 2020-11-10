
#PRODUCT_COPY_FILES += Nokia/Deadpool_VZW/DPL_VZW/twrp.fstab:recovery/root/etc/twrp.fstab


#/boot       emmc        /dev/block/platform/msm_sdcc.1/by-name/boot
#/system     ext4        /dev/block/platform/msm_sdcc.1/by-name/system
#/data       ext4        /dev/block/platform/msm_sdcc.1/by-name/userdata length=-16384
#/cache      ext4        /dev/block/platform/msm_sdcc.1/by-name/cache
#/recovery   emmc        /dev/block/platform/msm_sdcc.1/by-name/recovery
#/efs        ext4        /dev/block/platform/msm_sdcc.1/by-name/efs                            flags=display="EFS";backup=1
#/external_sd     vfat       /dev/block/mmcblk1p1    /dev/block/mmcblk1   flags=display="Micro SDcard";storage;wipeingui;removable
#/usb-otg         vfat       /dev/block/sda1         /dev/block/sda       flags=display="USB-OTG";storage;wipeingui;removable
#/preload    ext4        /dev/block/platform/msm_sdcc.1/by-name/hidden


#/external_sd  vfat  /dev/block/mmcblk1p1  flags=display="Micro SDcard";storage;wipeingui;removable

#/efs1         emmc   /dev/block/mmcblk0p12 flags=backup=1;display=EFS
#/efs2         emmc   /dev/block/mmcblk0p13 flags=backup=1;subpartitionof=/efs1
#/efs3         emmc   /dev/block/mmcblk0p14 flags=backup=1;subpartitionof=/efs1

#/usb-otg  vfat   /dev/block/sda*  flags=removable;storage;display=USB-OTG

#/devices/soc.0/f9200000.ssusb/f9200000.dwc3/xhci-hcd.0.auto/usb*    auto     auto    defaults    voldmanaged=usb:auto

# Android fstab file.
#<src>                                                  <mnt_point>         <type>    <mnt_flags and options>                       <fs_mgr_flags>
# The filesystem that contains the filesystem checker binary (typically /system) cannot
# specify MF_CHECK, and must come before any filesystems that do specify MF_CHECK
#/dev/block/bootdevice/by-name/system    /system    ext4    ro,barrier=1    wait,verify
#/dev/block/bootdevice/by-name/cust    /cust    ext4    ro,barrier=1    wait,verify
#/devices/hi_mci.1/mmc_host/mmc1/*                       auto                auto      defaults                                      voldmanaged=sdcard:auto,noemulatedsd
#/devices/hisi-usb-otg/usb1/*                            auto                auto      defaults                                      voldmanaged=usbotg:auto
#/dev/block/bootdevice/by-name/userdata         /data                f2fs     nosuid,nodev,noatime,discard,inline_data,inline_xattr wait,forceencrypt=footer,check
#/dev/block/bootdevice/by-name/cache   /cache                ext4      rw,nosuid,nodev,noatime,data=ordered wait,check


#/boot         emmc       /dev/block/platform/hi_mci.0/by-name/boot
#/recovery     emmc       /dev/block/platform/hi_mci.0/by-name/recovery   flags=backup=1
#/custom        ext4       /dev/block/platform/hi_mci.0/by-name/cust       flags=display="Cust";backup=1
#/misc         emmc       /dev/block/platform/hi_mci.0/by-name/misc
#/oeminfo      emmc       /dev/block/platform/hi_mci.0/by-name/oeminfo    flags=display="OEMinfo";backup=1
#/data         f2fs       /dev/block/dm-0


make clean && make -j# recoveryimage

make -j# bootimage


ifneq ($(filter twrp,$(TARGET_DEVICE)),)
    include $(all-subdir-makefiles)
endif

# commit 9a98ffcbaa332902ed3f03c8d3c8021bf3b178f9
# From android-goldfish-3.4 from https://android.googlesource.com/kernel/goldfish

CONFIG_EXPERIMENTAL=y
CONFIG_SYSVIPC=y
CONFIG_AUDIT=y
CONFIG_IKCONFIG=y
CONFIG_IKCONFIG_PROC=y
CONFIG_LOG_BUF_SHIFT=16
CONFIG_CGROUPS=y
CONFIG_CGROUP_DEBUG=y
CONFIG_CGROUP_FREEZER=y
CONFIG_CGROUP_CPUACCT=y
CONFIG_RESOURCE_COUNTERS=y
CONFIG_CGROUP_SCHED=y
CONFIG_RT_GROUP_SCHED=y
CONFIG_BLK_DEV_INITRD=y
CONFIG_CC_OPTIMIZE_FOR_SIZE=y
CONFIG_EMBEDDED=y
CONFIG_SLAB=y
CONFIG_ARCH_MMAP_RND_BITS=16
# CONFIG_BLK_DEV_BSG is not set
CONFIG_ARCH_GOLDFISH=y
CONFIG_MACH_GOLDFISH_ARMV7=y
CONFIG_NO_HZ=y
CONFIG_HIGH_RES_TIMERS=y
CONFIG_PREEMPT=y
CONFIG_AEABI=y
# CONFIG_OABI_COMPAT is not set
CONFIG_HIGHMEM=y
CONFIG_ZBOOT_ROM_TEXT=0x0
CONFIG_ZBOOT_ROM_BSS=0x0
# CONFIG_CORE_DUMP_DEFAULT_ELF_HEADERS is not set
CONFIG_BINFMT_MISC=y
CONFIG_NET=y
CONFIG_PACKET=y
CONFIG_UNIX=y
CONFIG_NET_KEY=y
CONFIG_INET=y
CONFIG_IP_MULTICAST=y
CONFIG_IP_ADVANCED_ROUTER=y
CONFIG_IP_MULTIPLE_TABLES=y
CONFIG_IP_PNP=y
CONFIG_IP_PNP_DHCP=y
CONFIG_IP_PNP_BOOTP=y
CONFIG_IP_MROUTE=y
CONFIG_IP_PIMSM_V1=y
CONFIG_IP_PIMSM_V2=y
CONFIG_SYN_COOKIES=y
CONFIG_INET_ESP=y
# CONFIG_INET_XFRM_MODE_BEET is not set
# CONFIG_INET_LRO is not set
# CONFIG_INET_DIAG is not set
CONFIG_IPV6_MULTIPLE_TABLES=y
CONFIG_NETFILTER=y
# CONFIG_BRIDGE_NETFILTER is not set
CONFIG_NF_CONNTRACK=y
CONFIG_NF_CONNTRACK_EVENTS=y
CONFIG_NF_CT_PROTO_DCCP=y
CONFIG_NF_CT_PROTO_SCTP=y
CONFIG_NF_CT_PROTO_UDPLITE=y
CONFIG_NF_CONNTRACK_AMANDA=y
CONFIG_NF_CONNTRACK_FTP=y
CONFIG_NF_CONNTRACK_H323=y
CONFIG_NF_CONNTRACK_IRC=y
CONFIG_NF_CONNTRACK_NETBIOS_NS=y
CONFIG_NF_CONNTRACK_PPTP=y
CONFIG_NF_CONNTRACK_SANE=y
CONFIG_NF_CONNTRACK_TFTP=y
CONFIG_NF_CT_NETLINK=y
CONFIG_NETFILTER_TPROXY=y
CONFIG_NETFILTER_XT_TARGET_CLASSIFY=y
CONFIG_NETFILTER_XT_TARGET_CONNMARK=y
CONFIG_NETFILTER_XT_TARGET_IDLETIMER=y
CONFIG_NETFILTER_XT_TARGET_MARK=y
CONFIG_NETFILTER_XT_TARGET_NFLOG=y
CONFIG_NETFILTER_XT_TARGET_NFQUEUE=y
CONFIG_NETFILTER_XT_TARGET_TPROXY=y
CONFIG_NETFILTER_XT_TARGET_TRACE=y
CONFIG_NETFILTER_XT_MATCH_COMMENT=y
CONFIG_NETFILTER_XT_MATCH_CONNBYTES=y
CONFIG_NETFILTER_XT_MATCH_CONNLIMIT=y
CONFIG_NETFILTER_XT_MATCH_CONNMARK=y
CONFIG_NETFILTER_XT_MATCH_CONNTRACK=y
CONFIG_NETFILTER_XT_MATCH_HASHLIMIT=y
CONFIG_NETFILTER_XT_MATCH_HELPER=y
CONFIG_NETFILTER_XT_MATCH_IPRANGE=y
CONFIG_NETFILTER_XT_MATCH_LENGTH=y
CONFIG_NETFILTER_XT_MATCH_LIMIT=y
CONFIG_NETFILTER_XT_MATCH_MAC=y
CONFIG_NETFILTER_XT_MATCH_MARK=y
CONFIG_NETFILTER_XT_MATCH_POLICY=y
CONFIG_NETFILTER_XT_MATCH_PKTTYPE=y
CONFIG_NETFILTER_XT_MATCH_QTAGUID=y
CONFIG_NETFILTER_XT_MATCH_QUOTA=y
CONFIG_NETFILTER_XT_MATCH_QUOTA2=y
CONFIG_NETFILTER_XT_MATCH_QUOTA2_LOG=y
CONFIG_NETFILTER_XT_MATCH_SOCKET=y
CONFIG_NETFILTER_XT_MATCH_STATE=y
CONFIG_NETFILTER_XT_MATCH_STATISTIC=y
CONFIG_NETFILTER_XT_MATCH_STRING=y
CONFIG_NETFILTER_XT_MATCH_TIME=y
CONFIG_NETFILTER_XT_MATCH_U32=y
CONFIG_NF_CONNTRACK_IPV4=y
CONFIG_IP_NF_IPTABLES=y
CONFIG_IP_NF_MATCH_AH=y
CONFIG_IP_NF_MATCH_ECN=y
CONFIG_IP_NF_MATCH_TTL=y
CONFIG_IP_NF_FILTER=y
CONFIG_IP_NF_TARGET_REJECT=y
CONFIG_IP_NF_TARGET_REJECT_SKERR=y
CONFIG_NF_NAT=y
CONFIG_IP_NF_TARGET_MASQUERADE=y
CONFIG_IP_NF_TARGET_NETMAP=y
CONFIG_IP_NF_TARGET_REDIRECT=y
CONFIG_IP_NF_MANGLE=y
CONFIG_IP_NF_RAW=y
CONFIG_IP_NF_ARPTABLES=y
CONFIG_IP_NF_ARPFILTER=y
CONFIG_IP_NF_ARP_MANGLE=y
CONFIG_NF_CONNTRACK_IPV6=y
CONFIG_IP6_NF_IPTABLES=y
CONFIG_IP6_NF_FILTER=y
CONFIG_IP6_NF_TARGET_REJECT=y
CONFIG_IP6_NF_TARGET_REJECT_SKERR=y
CONFIG_IP6_NF_MANGLE=y
CONFIG_IP6_NF_RAW=y
CONFIG_BRIDGE=y
CONFIG_VLAN_8021Q=y
CONFIG_CONNECTOR=y
CONFIG_MTD=y
CONFIG_MTD_CHAR=y
CONFIG_MTD_BLOCK=y
CONFIG_MTD_GOLDFISH_NAND=y
CONFIG_BLK_DEV_LOOP=y
CONFIG_BLK_DEV_NBD=y
CONFIG_BLK_DEV_RAM=y
CONFIG_BLK_DEV_RAM_SIZE=8192
CONFIG_QEMU_PIPE=y
CONFIG_QEMU_TRACE=y
CONFIG_MD=y
CONFIG_BLK_DEV_DM=y
CONFIG_DM_DEBUG=y
CONFIG_DM_CRYPT=y
CONFIG_DM_UEVENT=y
CONFIG_NETDEVICES=y
CONFIG_TUN=y
CONFIG_SMC91X=y
CONFIG_INPUT_EVDEV=y
CONFIG_KEYBOARD_GOLDFISH_EVENTS=y
# CONFIG_INPUT_MOUSE is not set
CONFIG_INPUT_MISC=y
# CONFIG_SERIO_SERPORT is not set
# CONFIG_LEGACY_PTYS is not set
CONFIG_GOLDFISH_TTY=y
CONFIG_POWER_SUPPLY=y
CONFIG_BATTERY_GOLDFISH=y
# CONFIG_HWMON is not set
CONFIG_FB=y
CONFIG_FB_MODE_HELPERS=y
CONFIG_FB_TILEBLITTING=y
CONFIG_FB_GOLDFISH=y
CONFIG_MMC=y
CONFIG_MMC_GOLDFISH=y
CONFIG_RTC_CLASS=y
CONFIG_RTC_DRV_GOLDFISH=y
CONFIG_STAGING=y
CONFIG_ANDROID=y
CONFIG_ANDROID_BINDER_IPC=y
CONFIG_ASHMEM=y
CONFIG_ANDROID_LOW_MEMORY_KILLER=y
CONFIG_EXT4_FS=y
CONFIG_EXT4_FS_SECURITY=y
CONFIG_FUSE_FS=y
CONFIG_MSDOS_FS=y
CONFIG_VFAT_FS=y
CONFIG_TMPFS=y
CONFIG_YAFFS_FS=y
CONFIG_NFSD=y
CONFIG_NFSD_V3=y
CONFIG_NLS_CODEPAGE_437=y
CONFIG_NLS_ISO8859_1=y
CONFIG_MAGIC_SYSRQ=y
CONFIG_SCHEDSTATS=y
CONFIG_SCHED_TRACER=y
CONFIG_BLK_DEV_IO_TRACE=y
CONFIG_SECURITY=y
CONFIG_SECURITY_NETWORK=y
CONFIG_SECURITY_SELINUX=y
CONFIG_SECURITY_SELINUX_BOOTPARAM=y
CONFIG_CRYPTO_ECB=y
CONFIG_CRYPTO_PCBC=y
CONFIG_CRYPTO_SHA256=y
CONFIG_CRYPTO_AES=y
CONFIG_CRYPTO_TWOFISH=y
# CONFIG_CRYPTO_ANSI_CPRNG is not set

# Added by Dees_Troy
CONFIG_PARTITION_ADVANCED=y
CONFIG_MSDOS_PARTITION=y
CONFIG_EFI_PARTITION=y

$(call inherit-product, $(SRC_TARGET_DIR)/product/languages_full.mk)

$(call inherit-product-if-exists, vendor/emulator/twrp/twrp-vendor.mk)

DEVICE_PACKAGE_OVERLAYS += device/emulator/twrp/overlay

LOCAL_PATH := device/emulator/twrp
ifeq ($(TARGET_PREBUILT_KERNEL),)
	LOCAL_KERNEL := $(LOCAL_PATH)/kernAl
else
	LOCAL_KERNEL := $(TARGET_PREBUILT_KERNEL)
endif

PRODUCT_COPY_FILES += \
    $(LOCAL_KERNEL):kernel

$(call inherit-product, build/target/product/full.mk)

PRODUCT_NAME := teamwin_twrp
PRODUCT_BRAND := teamwin
# mount point	fstype		device

/external_sd  vfat      /dev/block/mmcblk0p3     /dev/block/mmcblk0
/system       ext4      /dev/block/mtdblock0
/data         ext4      /dev/block/mtdblock1     length=-16384
/cache        ext4      /dev/block/mtdblock2
/boot         emmc      /dev/block/mmcblk0p1
/recovery     emmc      /dev/block/mmcblk0p2

# Release name
PRODUCT_RELEASE_NAME := twrp

# Inherit from the common Open Source product configuration
$(call inherit-product, $(SRC_TARGET_DIR)/product/aosp_base_telephony.mk)

# Inherit from our custom product configuration
$(call inherit-product, vendor/omni/config/common.mk)

# Inherit device configuration
$(call inherit-product, device/emulator/twrp/device.mk)

## Device identifier. This must come after all inclusions
PRODUCT_DEVICE := twrp
PRODUCT_NAME := aosp_twrp
PRODUCT_BRAND := teamwin
PRODUCT_MODEL := twrp
PRODUCT_MANUFACTURER := teamwin



USE_CAMERA_STUB := true

# inherit from the proprietary version
-include vendor/emulator/twrp/BoardConfigVendor.mk

TARGET_NO_BOOTLOADER := true
TARGET_BOOTLOADER_BOARD_NAME := twrp

# Platform
TARGET_NO_RADIOIMAGE := true
TARGET_BOARD_PLATFORM := SDM429

# Architecture
TARGET_ARCH := arm
TARGET_CPU_ABI := armeabi-v8a
TARGET_CPU_ABI2 := armeabi
TARGET_CPU_SMP := true
TARGET_ARCH_VARIANT := armv7-a-neon
ARCH_ARM_HAVE_TLS_REGISTER := true
TARGET_CPU_VARIANT := cortex-a9

BOARD_KERNEL_BASE := 0x80000000
# BOARD_KERNEL_CMDLINE :=

BOARD_BOOTIMAGE_PARTITION_SIZE := 0x105c0000
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 0x105c0000
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 0x105c0000
BOARD_USERDATAIMAGE_PARTITION_SIZE := 0x105c0000
BOARD_FLASH_BLOCK_SIZE := 131072

TARGET_PREBUILT_KERNEL := device/emulator/twrp/kernAl

# Recovery:Start

# Use this flag if the board has a ext4 partition larger than 2gb
BOARD_HAS_LARGE_FILESYSTEM := true

#TARGET_RECOVERY_INITRC := device/emulator/twrp/recovery/init.rc
TARGET_USERIMAGES_USE_EXT4 := true

# TWRP specific build flags
TW_THEME := portrait_hdpi
RECOVERY_SDCARD_ON_DATA := true
TW_EXCLUDE_MTP := true
# Dirty workaround to prevent errors related to the brightness file
TW_BRIGHTNESS_PATH := "/brightness"
