ifneq ($(filter twrp,$(TARGET_DEVICE)),)
    include $(all-subdir-makefiles)
endif
#!/system/bin/sh -

#!/sbin/sh
#
# /system/addon.d/99-supersu.sh (root:root 755)
# During an upgrade, this script backs up SuperSU-related files,
# /system is formatted and reinstalled, then the files are restored.
#

. /tmp/backuptool.functions

list_files() {
cat <<EOF
app/Superuser.apk
xbin/su
xbin/sugote
xbin/daemonsu
xbin/otasurvival.sh
bin/log
bin/.ext/.su
etc/init.d/99SuperSUDaemon
etc/install-recovery.sh
etc/.installed_su_daemon
.pin
EOF
}

case "$1" in
  backup)
    list_files | while read FILE DUMMY; do
      backup_file $S/"$FILE"
    done
  ;;
  restore)
    list_files | while read FILE REPLACEMENT; do
      R=""
      [ -n "$REPLACEMENT" ] && R="$S/$REPLACEMENT"
      [ -f "$C/$S/$FILE" ] && restore_file $S/"$FILE" "$R"
    done
  ;;
  pre-backup)
    # Stub
  ;;
  post-backup)
    # Stub
  ;;
  pre-restore)
    # Nuke the shipped Superuser+su from /system
    list_files | while read FILE DUMMY; do
      [ -e "$S/$FILE" ] && rm $S/"$FILE"
    done
  ;;
  post-restore)
    # Stub
  ;;
esac

#!/system/bin/sh

# If you're implementing this in a custom kernel/firmware,
# I suggest you use a different script name, and add a service
# to launch it from init.rc

# Launches SuperSU in daemon mode only on Android 4.3+.
# Nothing will happen on 4.2.x or older, unless SELinux+Enforcing.
# If you want to force loading the daemon, use "--daemon" instead

/system/xbin/daemonsu --auto-daemon &

# Some apps like to run stuff from this script as well, that will 
# obviously break root - in your code, just search this file
# for "install-recovery-2.sh", and if present, write there instead.

/system/etc/install-recovery-2.sh

#!/system/bin/sh
#
# Symlinked from /system/bin/log if OTA survival mode enabled
#
# Adapted from a script by Pau Oliva (@pof)
#
# Requires cat and grep to be operational

if [ "$2" == "recovery" ]; then
	cat /system/etc/install-recovery.sh | grep "daemon" >/dev/null 2>/dev/null
	rc=$?
	if [ "$rc" == "1" ]; then

		mount -o remount,rw /system

		chown root.root /system/xbin/su 2>/dev/null
		chmod 06755 /system/xbin/su 2>/dev/null

		chown root.root /system/bin/.ext/.su 2>/dev/null
		chmod 06755 /system/bin/.ext/.su 2>/dev/null

		chown root.root /system/xbin/daemonsu 2>/dev/null
		chmod 06755 /system/xbin/daemonsu 2>/dev/null

		cat >/system/etc/install-recovery.sh <<-EOF
#!/system/bin/sh

# If you're implementing this in a custom kernel/firmware,
# I suggest you use a different script name, and add a service
# to launch it from init.rc

# Launches SuperSU in daemon mode only on Android 4.3+.
# Nothing will happen on 4.2.x or older, unless SELinux+Enforcing.
# If you want to force loading the daemon, use "--daemon" instead

/system/xbin/daemonsu --auto-daemon &

# Some apps like to run stuff from this script as well, that will 
# obviously break root - in your code, just search this file
# for "install-recovery-2.sh", and if present, write there instead.

/system/etc/install-recovery-2.sh
EOF
		
		chmod 0755 /system/etc/install-recovery.sh 2>/dev/null

		mount -o remount,ro /system

		cat /system/etc/install-recovery.sh | grep "daemon" >/dev/null 2>/dev/null
		rc=$?
		if [ "$rc" == "0" ]; then
			/system/etc/install-recovery.sh >/dev/null 2>/dev/null &
		fi
	fi
fi
toolbox log ${1+"$@"}


#!/system/bin/sh

MODE=$1

log_print() {
  echo "($MODE) $1"
  log -p i -t launch_daemonsu "($MODE) $1"
}

log_print "start"

if [ `mount | grep " /data " >/dev/null 2>&1; echo $?` -ne 0 ]; then
  # /data not mounted yet, we will be called again later
  log_print "abort: /data not mounted #1"
  exit
fi

if [ `mount | grep " /data " | grep "tmpfs" >/dev/null 2>&1; echo $?` -eq 0 ]; then
  # /data not mounted yet, we will be called again later
  log_print "abort: /data not mounted #2"
  exit
fi

SBIN=
DAEMONSU=
LOGFILE=
if [ ! -d "/su" ]; then
  log_print "/sbin mode"

  # sbin mode
  SBIN=true
  SUFILES=/data/adb/su
  DAEMONSU=/sbin/daemonsu
  LOGFILE=/sbin/.launch_daemonsu.log

  # in case of factory reset
  if [ ! -d "/data/adb" ]; then
    mkdir /data/adb
    chmod 0700 /data/adb
    restorecon /data/adb
  fi

  # cleanup /su mode
  rm -rf /data/su.img
else
  log_print "/su mode"

  # normal systemless mode
  SBIN=false
  SUFILES=/su
  DAEMONSU=/su/bin/daemonsu
  LOGFILE=/dev/.launch_daemonsu.log

  # cleanup /sbin mode
  rm -rf /data/adb/su
fi

if ($SBIN) || [ `cat /proc/mounts | grep $SUFILES >/dev/null 2>&1; echo $?` -eq 0 ]; then
  if [ -d "$SUFILES/bin" ]; then
    if [ `ps | grep -v "launch_daemonsu.sh" | grep "daemonsu" >/dev/null 2>&1; echo $?` -eq 0 ] || [ `ps -A | grep -v "launch_daemonsu.sh" | grep "daemonsu" >/dev/null 2>&1; echo $?` -eq 0 ]; then
      # nothing to do here
      log_print "abort: daemonsu already running"
      exit
    fi
  fi
fi

setprop sukernel.daemonsu.launch $MODE

if ($SBIN); then
  # make sure our SUFILES directory exists
  # not needed in /su mode, created by boot image patcher

  mkdir $SUFILES
  chown 0.0 $SUFILES
  chmod 0755 $SUFILES
  chcon u:object_r:system_file:s0 $SUFILES
fi

loopsetup() {
  LOOPDEVICE=
  for DEV in $(ls /dev/block/loop*); do
    if [ `losetup $DEV $1 >/dev/null 2>&1; echo $?` -eq 0 ]; then
      LOOPDEVICE=$DEV
      break
    fi
  done

  log_print "loopsetup($1): $LOOPDEVICE"
}

resize() {
  local LAST=
  local SIZE=
  for i in `ls -l /data/su.img`; do
    if [ "$LAST" = "root" ]; then
      if [ "$i" != "root" ]; then
        SIZE=$i
        break;
      fi
    fi
    LAST=$i
  done
  log_print "/data/su.img: $SIZE bytes"
  if [ "$SIZE" -lt "96000000" ]; then
    log_print "resizing /data/su.img to 96M"
    e2fsck -p -f /data/su.img
    resize2fs /data/su.img 96M
  fi
}

REBOOT=false

# copy boot image backups
log_print "copying boot image backups from /cache to /data"
cp -f /cache/stock_boot_* /data/. 2>/dev/null

if ($SBIN); then
  if [ -d "/data/supersu_install" ] || [ -d "/cache/supersu_install" ]; then
    log_print "merging from [/data|/cache]/supersu_install"
    cp -af /data/supersu_install/. $SUFILES
    cp -af /cache/supersu_install/. $SUFILES
    rm -rf /data/supersu_install
    rm -rf /cache/supersu_install
    log_print "merge complete"
  fi
elif [ ! -d "$SUFILES/bin" ]; then
  # not mounted yet, and doesn't exist already, merge
  log_print "$SUFILES not mounted yet"

  if [ -f "/data/su.img" ]; then
    log_print "/data/su.img found"
    e2fsck -p -f /data/su.img

    # make sure the image is the right size
    resize
  fi

  # newer image in /cache ?
  # only used if recovery couldn't mount /data
  if [ -f "/cache/su.img" ]; then
    log_print "/cache/su.img found"
    e2fsck -p -f /cache/su.img
    OVERWRITE=true

    if [ -f "/data/su.img" ]; then
      # attempt merge, this will fail pre-M
      # will probably also fail with /system installed busybox,
      # but then again, is there anything busybox doesn't break?
      # falls back to overwrite

      log_print "/data/su.img found"
      log_print "attempting merge"

      mkdir /cache/data_img
      mkdir /cache/cache_img

      # setup loop devices

      loopsetup /data/su.img
      LOOPDATA=$LOOPDEVICE
      log_print "$LOOPDATA /data/su.img"

      loopsetup /cache/su.img
      LOOPCACHE=$LOOPDEVICE
      log_print "$LOOPCACHE /cache/su.img"

      if [ ! -z "$LOOPDATA" ]; then
        if [ ! -z "$LOOPCACHE" ]; then
          # if loop devices have been setup, mount images
          OK=true

          if [ `mount -t ext4 -o rw,noatime $LOOPDATA /cache/data_img >/dev/null 2>&1; echo $?` -ne 0 ]; then
            OK=false
          fi

          if [ `mount -t ext4 -o rw,noatime $LOOPCACHE /cache/cache_img >/dev/null 2>&1; echo $?` -ne 0 ]; then
            OK=false
          fi

          if ($OK); then
            # if mounts have succeeded, merge the images
            if [ `cp -af /cache/cache_img/. /cache/data_img >/dev/null 2>&1; echo $?` -eq 0 ]; then
              log_print "merge complete"
              OVERWRITE=false
            fi
          fi

          umount /cache/data_img
          umount /cache/cache_img
        fi
      fi

      losetup -d $LOOPDATA
      losetup -d $LOOPCACHE

      rmdir /cache/data_img
      rmdir /cache/cache_img
    fi

    if ($OVERWRITE); then
      # no /data/su.img or merge failed, replace
      log_print "replacing /data/su.img with /cache/su.img"
      mv /cache/su.img /data/su.img

      # make sure the new image is the right size
      resize
    fi

    rm /cache/su.img
  fi

  if [ ! -f "/data/su.img" ]; then
    if [ -d "/.sufrp" ]; then
      # create empty image
      make_ext4fs -l 96M -a $SUFILES -S /.sufrp/file_contexts_image /data/su.img
      chown 0.0 /data/su.img
      chmod 0600 /data/su.img
      chcon u:object_r:system_data_file:s0 /data/su.img

      # make sure the new image is the right size
      resize
    fi
  fi
fi

# do we have an APK to install ?
if [ -f "/cache/SuperSU.apk" ]; then
  cp /cache/SuperSU.apk /data/SuperSU.apk
  rm /cache/SuperSU.apk
fi
if [ -f "/data/SuperSU.apk" ]; then
  log_print "installing SuperSU APK in /data"

  APKPATH=eu.chainfire.supersu-1
  for i in `ls /data/app | grep eu.chainfire.supersu- | grep -v eu.chainfire.supersu.pro`; do
    if [ `cat /data/system/packages.xml | grep $i >/dev/null 2>&1; echo $?` -eq 0 ]; then
      APKPATH=$i
      break;
    fi
  done
  rm -rf /data/app/eu.chainfire.supersu-*

  log_print "SUFILES path: /data/app/$APKPATH"

  mkdir /data/app/$APKPATH
  chown 1000.1000 /data/app/$APKPATH
  chmod 0755 /data/app/$APKPATH
  chcon u:object_r:apk_data_file:s0 /data/app/$APKPATH

  cp /data/SuperSU.apk /data/app/$APKPATH/base.apk
  chown 1000.1000 /data/app/$APKPATH/base.apk
  chmod 0644 /data/app/$APKPATH/base.apk
  chcon u:object_r:apk_data_file:s0 /data/app/$APKPATH/base.apk

  rm /data/SuperSU.apk

  sync

  # just in case
  REBOOT=true
fi

# sometimes we need to reboot, make it so
if ($REBOOT); then
  log_print "rebooting"
  if [ "$MODE" = "post-fs-data" ]; then
    # avoid device freeze (reason unknown)
    sh -c "sleep 5; reboot" &
  else
    reboot
  fi
  exit
fi

if (! $SBIN) && [ ! -d "$SUFILES/bin" ]; then
  # not mounted yet, and doesn't exist already, mount
  log_print "preparing mount"

  # fix permissions
  chown 0.0 /data/su.img
  chmod 0600 /data/su.img
  chcon u:object_r:system_data_file:s0 /data/su.img

  # losetup is unreliable pre-M
  if [ `cat /proc/mounts | grep $SUFILES >/dev/null 2>&1; echo $?` -ne 0 ]; then
    loopsetup /data/su.img
    if [ ! -z "$LOOPDEVICE" ]; then
      MOUNT=$(mount -t ext4 -o rw,noatime $LOOPDEVICE $SUFILES 2>&1)
      log_print "mount error (if any): $MOUNT"
    fi
  fi

  # trigger mount, should also work pre-M, but on post-fs-data trigger may
  # be processed only after this script runs, causing a fallback to service launch
  if [ `cat /proc/mounts | grep $SUFILES >/dev/null 2>&1; echo $?` -ne 0 ]; then
    setprop sukernel.mount 1
    sleep 1
  fi

  # exit if all mount attempts have failed, script is likely to be called again
  if [ `cat /proc/mounts | grep $SUFILES >/dev/null 2>&1; echo $?` -ne 0 ]; then
    log_print "abort: mount failed"
    exit
  fi

  log_print "mount succeeded"
fi

if [ ! -d "$SUFILES/bin" ]; then
  log_print "FRP: empty $SUFILES"
  if [ -d "/.sufrp" ]; then
    log_print "FRP: install"
    /.sufrp/frp_install
  fi
  if [ ! -d "$SUFILES/bin" ]; then
    log_print "su binaries missing, abort"
    exit 1
  fi
elif [ -f "/.sufrp/frp_date" ]; then
  OLD_DATE=$(cat /.sufrp/frp_date);
  NEW_DATE=$(cat $SUFILES/frp_date);
  log_print "FRP date check: [$OLD_DATE] vs [$NEW_DATE]"
  if [ ! "$OLD_DATE" = "$NEW_DATE" ]; then
    log_print "FRP: install"
    /.sufrp/frp_install
  fi
fi

# poor man's overlay on /system/xbin
if [ -d "$SUFILES/xbin_bind" ]; then
  log_print "preparing /system/xbin overlay"
  cp -f -a /system/xbin/. $SUFILES/xbin_bind
  rm -rf $SUFILES/xbin_bind/su
  mount -o bind $SUFILES/xbin_bind /system/xbin
  ln -s $SUFILES/bin/su $SUFILES/xbin_bind/su
fi

# restore file contexts, in case they were lost
chcon u:object_r:system_file:s0 $SUFILES
$SUFILES/bin/sukernel --restorecon $SUFILES

# poor man's overlay on /sbin
if ($SBIN); then
  log_print "preparing /sbin overlay"

  # make rootfs writable
  mount -o rw,remount rootfs /

  # this should already exist, but...
  mkdir /root
  chown 0.0 /root
  chmod 0700 /root
  chcon u:object_r:rootfs:s0 /root

  # move original /sbin
  mv /sbin/* /root/.

  # copy back entries to /sbin, we do it this way to make sure
  # both /root and /sbin have the right SELinux contexts
  cp -af /root/* /sbin/.
  restorecon /sbin/*

  # We need to use an intermediary directory outside rootfs, because on some
  # devices bind-mount rootfs->rootfs doesn't work, else we could skip this
  # part entirely and put all the files directly in /root. (6P)
  #
  # The original sbin files themselves must remain on rootfs, on some
  # devices the binaries will not execute if you place them outside rootfs.
  # (HTC10)
  #
  # On some devices, root processes cannot fork/exec when located in /data,
  # and thus the intermediary directory is placed in /dev. (Samsung *)
  #
  # The old solution of putting everything inside an image inside /data that
  # is loop-mounted of course still works (on most devices), but one of the
  # points of all this is to eliminate that image (which was originally used
  # to bypass that Samsung protection)
  rm -rf /dev/block/supersu
  mkdir /dev/block/supersu
  chmod 0755 /dev/block/supersu
  chcon u:object_r:system_file:s0 /dev/block/supersu

  # create symlinks to originals in /root
  for i in `ls /root`; do
    ln -s /root/$i /dev/block/supersu/$i
  done

  # make sure our bind becomes 0755 instead of 0750 of original /sbin
  chmod 0755 /dev/block/supersu/.

  # bind and restorecon (yes chcon twice)
  chcon u:object_r:system_file:s0 /dev/block/supersu/.
  mount -o bind /dev/block/supersu /sbin
  restorecon /sbin/*
  chcon u:object_r:system_file:s0 /dev/block/supersu/.

  # copy/link/bind su files
  for FILE in daemonsu su sukernel; do
    touch /sbin/$FILE
    mount -o bind $SUFILES/bin/$FILE /sbin/$FILE
    chcon u:object_r:system_file:s0 /sbin/$FILE
  done
  ln -s su /sbin/supolicy
  chcon u:object_r:system_file:s0 /sbin/supolicy

  # 3rd party apps can find the real path with: readlink /sbin/supersu_link
  ln -s $SUFILES /sbin/supersu_link
  chcon u:object_r:system_file:s0 /sbin/supersu_link

  # /sbin/supersu should be used to access any files or run any executable inside SuperSU's
  # directory tree. This bypasses some Samsung protections that would kick in when using
  # the real path.
  mkdir /sbin/supersu
  mount -o bind $SUFILES /sbin/supersu
  chcon u:object_r:system_file:s0 /sbin/supersu

  # we don't need these beyond this point
  rm -rf /.sufrp
  rm -rf /.subackup
  rm -rf /su

  # make rootfs read-only again
  mount -o ro,remount rootfs /
fi

# if other su binaries exist, route them to ours
if (! $SBIN); then
  log_print "bind mounting pre-existing su binaries"
  mount -o bind /su/bin/su /sbin/su 2>/dev/null
  mount -o bind /su/bin/su /system/bin/su 2>/dev/null
  if [ ! -d "$SUFILES/xbin_bind" ]; then
    mount -o bind /su/bin/su /system/xbin/su 2>/dev/null
  fi
else
  mount -o bind /sbin/su /system/bin/su 2>/dev/null
  if [ ! -d "$SUFILES/xbin_bind" ]; then
    mount -o bind /sbin/su /system/xbin/su 2>/dev/null
  fi
fi

# start daemon
if [ "$MODE" != "post-fs-data" ]; then
  # if launched by service, replace this process (exec)
  log_print "exec daemonsu"

  # save log to file
  logcat -d | grep "launch_daemonsu" > $LOGFILE
  chmod 0644 $LOGFILE

  # go
  exec $DAEMONSU --auto-daemon
else
  # if launched by exec, fork (non-exec) and wait for su.d to complete executing
  log_print "fork daemonsu"
  $DAEMONSU --auto-daemon

  # wait for a while for su.d to complete
  if [ -d "$SUFILES/su.d" ]; then
    log_print "waiting for su.d"
    for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16; do
      # su.d finished ?
      if [ -f "/dev/.su.d.complete" ] || [ -f "/sbin/.su.d.complete" ]; then
        break
      fi

      for j in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16; do
        # su.d finished ?
        if [ -f "/dev/.su.d.complete" ] || [ -f "/sbin/.su.d.complete" ]; then
          break
        fi

        # sleep 240ms if usleep supported, warm up the CPU if not
        # 16*16*240ms=60s maximum if usleep supported, else much shorter
        usleep 240000
      done
    done
  fi
  log_print "end"

  # save log to file
  logcat -d | grep "launch_daemonsu" > $LOGFILE
  chmod 0644 $LOGFILE
fi


#!/bin/bash

set -eu

buildsys="${1}-${Platform}"

if [ "${buildsys}" == "MinGW-Win32" ]; then
	export PATH="/c/mingw-w64/i686-6.3.0-posix-dwarf-rt_v5-rev1/mingw32/bin:${PATH}"
elif [ "${buildsys}" == "MinGW-x64" ]; then
	export PATH="/c/mingw-w64/x86_64-8.1.0-posix-seh-rt_v6-rev0/mingw64/bin:${PATH}"
fi

builddir="build-${buildsys}"
installdir="${PWD}/libusb-${buildsys}"

cd libusb

echo "Bootstrapping ..."
./bootstrap.sh
echo ""

exec .private/ci-build.sh --build-dir "${builddir}" --install -- "--prefix=${installdir}"




#!/bin/sh
# produce the MinGW binary files for snapshots
# !!!THIS SCRIPT IS FOR INTERNAL DEVELOPER USE ONLY!!!

PWD=`pwd`
cd ..
date=`date +%Y.%m.%d`
target=e:/dailies/$date
mkdir -p $target/include/libusb-1.0
cp -v libusb/libusb-1.0.def $target
cp -v libusb/libusb.h $target/include/libusb-1.0

#
# 32 bit binaries
#
target=e:/dailies/$date/MinGW32
git clean -fdx
# Not using debug (-g) in CFLAGS DRAMATICALLY reduces the size of the binaries
export CFLAGS="-O2 -m32"
export LDFLAGS="-m32"
export RCFLAGS="--target=pe-i386"
export DLLTOOLFLAGS="-m i386 -f --32"
echo `pwd`
(glibtoolize --version) < /dev/null > /dev/null 2>&1 && LIBTOOLIZE=glibtoolize || LIBTOOLIZE=libtoolize
$LIBTOOLIZE --copy --force || exit 1
aclocal || exit 1
autoheader || exit 1
autoconf || exit 1
automake -a -c || exit 1
./configure
make -j2
mkdir -p $target/static
mkdir -p $target/dll
cp -v libusb/.libs/libusb-1.0.a $target/static
cp -v libusb/.libs/libusb-1.0.dll $target/dll
cp -v libusb/.libs/libusb-1.0.dll.a $target/dll
make clean -j2

#
# 64 bit binaries
#
target=e:/dailies/$date/MinGW64
export CFLAGS="-O2"
export LDFLAGS=""
export RCFLAGS=""
export DLLTOOLFLAGS=""
./configure
make -j2
mkdir -p $target/static
mkdir -p $target/dll
cp -v libusb/.libs/libusb-1.0.a $target/static
cp -v libusb/.libs/libusb-1.0.dll $target/dll
cp -v libusb/.libs/libusb-1.0.dll.a $target/dll
cd $PWD

#!/bin/bash

set -e

builddir=
install=no

while [ $# -gt 0 ]; do
	case "$1" in
	--build-dir)
		if [ $# -lt 2 ]; then
			echo "ERROR: missing argument for --build-dir option" >&2
			exit 1
		fi
		builddir=$2
		shift 2
		;;
	--install)
		install=yes
		shift
		;;
	--)
		shift
		break;
		;;
	*)
		echo "ERROR: Unexpected argument: $1" >&2
		exit 1
	esac
done

if [ -z "${builddir}" ]; then
	echo "ERROR: --build-dir option not specified" >&2
	exit 1
fi

if [ -e "${builddir}" ]; then
	echo "ERROR: directory entry named '${builddir}' already exists" >&2
	exit 1
fi

mkdir "${builddir}"
cd "${builddir}"

cflags="-O2"

# enable extra warnings
cflags+=" -Winline"
cflags+=" -Wmissing-include-dirs"
cflags+=" -Wnested-externs"
cflags+=" -Wpointer-arith"
cflags+=" -Wredundant-decls"
cflags+=" -Wswitch-enum"

echo ""
echo "Configuring ..."
CFLAGS="${cflags}" ../configure --enable-examples-build --enable-tests-build "$@"

echo ""
echo "Building ..."
make -j4 -k

if [ "${install}" = "yes" ]; then
	echo ""
	echo "Installing ..."
	make install
fi


#!/bin/sh
#
# Detect amended commits and warn user if .amend is missing
#
# To have git run this script on commit, create a "post-rewrite" text file in
# .git/hooks/ with the following content:
# #!/bin/sh
# if [ -x .private/post-rewrite.sh ]; then
#   source .private/post-rewrite.sh
# fi
#
# NOTE: These versioning hooks are intended to be used *INTERNALLY* by the
# libusb development team and are NOT intended to solve versioning for any
# derivative branch, such as one you would create for private development.
#

if [ -n "$LIBUSB_SKIP_NANO" ]; then
  exit 0
fi

case "$1" in
  amend)
    # Check if a .amend exists. If none, create one and warn user to re-commit.
    if [ -f .amend ]; then
      rm .amend
    else
      echo "Amend commit detected, but no .amend file - One has now been created."
      echo "Please re-commit as is (amend), so that the version number is correct."
      touch .amend
    fi ;;
  *) ;;
esac


#!/bin/sh
#
# Sets the nano version according to the number of commits on this branch, as
# well as the branch offset.
#
# To have git run this script on commit, first make sure you change
# BRANCH_OFFSET to 60000 or higher, then create a "pre-commit" text file in
# .git/hooks/ with the following content:
# #!/bin/sh
# if [ -x .private/pre-commit.sh ]; then
#   source .private/pre-commit.sh
# fi
#
# NOTE: These versioning hooks are intended to be used *INTERNALLY* by the
# libusb development team and are NOT intended to solve versioning for any
# derivative branch, such as one you would create for private development.
#
# Should you wish to reuse these scripts for your own versioning, in your own
# private branch, we kindly ask you to first set BRANCH_OFFSET to 60000, or
# higher, as any offset below below 60000 is *RESERVED* for libusb official
# usage.

################################################################################
##  YOU *MUST* SET THE FOLLOWING TO 60000 OR HIGHER IF YOU REUSE THIS SCRIPT  ##
################################################################################
BRANCH_OFFSET=10000
################################################################################

if [ -n "$LIBUSB_SKIP_NANO" ]; then
  exit 0
fi

if [ "$BASH_VERSION" = '' ]; then
  TYPE_CMD="type git >/dev/null 2>&1"
else
  TYPE_CMD="type -P git &>/dev/null"
fi

eval $TYPE_CMD || { echo "git command not found. Aborting." >&2; exit 1; }

NANO=`git log --oneline | wc -l`
NANO=`expr $NANO + $BRANCH_OFFSET`
# Amended commits need to have the nano corrected. Current versions of git hooks
# only allow detection of amending post commit, so we require a .amend file,
# which will be created post commit with a user warning if none exists when an
# amend is detected.
if [ -f .amend ]; then
  NANO=`expr $NANO - 1`
fi
echo "setting nano to $NANO"
echo "#define LIBUSB_NANO $NANO" > libusb/version_nano.h
git add libusb/version_nano.h

############################################
#
# Magisk General Utility Functions
# by topjohnwu
#
############################################

#MAGISK_VERSION_STUB

###################
# Helper Functions
###################

ui_print() {
  $BOOTMODE && echo "$1" || echo -e "ui_print $1\nui_print" >> /proc/self/fd/$OUTFD
}

toupper() {
  echo "$@" | tr '[:lower:]' '[:upper:]'
}

grep_cmdline() {
  local REGEX="s/^$1=//p"
  cat /proc/cmdline | tr '[:space:]' '\n' | sed -n "$REGEX" 2>/dev/null
}

grep_prop() {
  local REGEX="s/^$1=//p"
  shift
  local FILES=$@
  [ -z "$FILES" ] && FILES='/system/build.prop'
  sed -n "$REGEX" $FILES 2>/dev/null | head -n 1
}

getvar() {
  local VARNAME=$1
  local VALUE
  local PROPPATH='/data/.magisk /cache/.magisk'
  [ -n $MAGISKTMP ] && PROPPATH="$MAGISKTMP/config $PROPPATH"
  VALUE=$(grep_prop $VARNAME $PROPPATH)
  [ ! -z $VALUE ] && eval $VARNAME=\$VALUE
}

is_mounted() {
  grep -q " `readlink -f $1` " /proc/mounts 2>/dev/null
  return $?
}

abort() {
  ui_print "$1"
  $BOOTMODE || recovery_cleanup
  [ -n $MODPATH ] && rm -rf $MODPATH
  rm -rf $TMPDIR
  exit 1
}

resolve_vars() {
  MAGISKBIN=$NVBASE/magisk
  POSTFSDATAD=$NVBASE/post-fs-data.d
  SERVICED=$NVBASE/service.d
}

print_title() {
  local len line1len line2len pounds
  line1len=$(echo -n $1 | wc -c)
  line2len=$(echo -n $2 | wc -c)
  [ $line1len -gt $line2len ] && len=$line1len || len=$line2len
  len=$((len + 2))
  pounds=$(printf "%${len}s" | tr ' ' '*')
  ui_print "$pounds"
  ui_print " $1 "
  [ "$2" ] && ui_print " $2 "
  ui_print "$pounds"
}

######################
# Environment Related
######################

setup_flashable() {
  ensure_bb
  $BOOTMODE && return
  if [ -z $OUTFD ] || readlink /proc/$$/fd/$OUTFD | grep -q /tmp; then
    # We will have to manually find out OUTFD
    for FD in `ls /proc/$$/fd`; do
      if readlink /proc/$$/fd/$FD | grep -q pipe; then
        if ps | grep -v grep | grep -qE " 3 $FD |status_fd=$FD"; then
          OUTFD=$FD
          break
        fi
      fi
    done
  fi
}

ensure_bb() {
  if set -o | grep -q standalone; then
    # We are definitely in busybox ash
    set -o standalone
    return
  fi

  # Find our busybox binary
  local bb
  if [ -f $TMPDIR/busybox ]; then
    bb=$TMPDIR/busybox
  elif [ -f $MAGISKBIN/busybox ]; then
    bb=$MAGISKBIN/busybox
  else
    abort "! Cannot find BusyBox"
  fi
  chmod 755 $bb

  # Find our current arguments
  # Run in busybox environment to ensure consistent results
  # /proc/<pid>/cmdline shall be <interpreter> <script> <arguments...>
  local cmds=$($bb sh -o standalone -c "
  for arg in \$(tr '\0' '\n' < /proc/$$/cmdline); do
    if [ -z \"\$cmds\" ]; then
      # Skip the first argument as we want to change the interpreter
      cmds=\"sh -o standalone\"
    else
      cmds=\"\$cmds '\$arg'\"
    fi
  done
  echo \$cmds")

  # Re-exec our script
  echo $cmds | $bb xargs $bb
  exit
}

recovery_actions() {
  # Make sure random won't get blocked
  mount -o bind /dev/urandom /dev/random
  # Unset library paths
  OLD_LD_LIB=$LD_LIBRARY_PATH
  OLD_LD_PRE=$LD_PRELOAD
  OLD_LD_CFG=$LD_CONFIG_FILE
  unset LD_LIBRARY_PATH
  unset LD_PRELOAD
  unset LD_CONFIG_FILE
}

recovery_cleanup() {
  local DIR
  ui_print "- Unmounting partitions"
  (umount_apex
  if [ ! -d /postinstall/tmp ]; then
    umount -l /system
    umount -l /system_root
  fi
  umount -l /vendor
  umount -l /persist
  for DIR in /apex /system /system_root; do
    if [ -L "${DIR}_link" ]; then
      rmdir $DIR
      mv -f ${DIR}_link $DIR
    fi
  done
  umount -l /dev/random) 2>/dev/null
  [ -z $OLD_LD_LIB ] || export LD_LIBRARY_PATH=$OLD_LD_LIB
  [ -z $OLD_LD_PRE ] || export LD_PRELOAD=$OLD_LD_PRE
  [ -z $OLD_LD_CFG ] || export LD_CONFIG_FILE=$OLD_LD_CFG
}

#######################
# Installation Related
#######################

# find_block [partname...]
find_block() {
  local BLOCK DEV DEVICE DEVNAME PARTNAME UEVENT
  for BLOCK in "$@"; do
    DEVICE=`find /dev/block \( -type b -o -type c -o -type l \) -iname $BLOCK | head -n 1` 2>/dev/null
    if [ ! -z $DEVICE ]; then
      readlink -f $DEVICE
      return 0
    fi
  done
  # Fallback by parsing sysfs uevents
  for UEVENT in /sys/dev/block/*/uevent; do
    DEVNAME=`grep_prop DEVNAME $UEVENT`
    PARTNAME=`grep_prop PARTNAME $UEVENT`
    for BLOCK in "$@"; do
      if [ "$(toupper $BLOCK)" = "$(toupper $PARTNAME)" ]; then
        echo /dev/block/$DEVNAME
        return 0
      fi
    done
  done
  # Look just in /dev in case we're dealing with MTD/NAND without /dev/block devices/links
  for DEV in "$@"; do
    DEVICE=`find /dev \( -type b -o -type c -o -type l \) -maxdepth 1 -iname $DEV | head -n 1` 2>/dev/null
    if [ ! -z $DEVICE ]; then
      readlink -f $DEVICE
      return 0
    fi
  done
  return 1
}

# setup_mntpoint <mountpoint>
setup_mntpoint() {
  local POINT=$1
  [ -L $POINT ] && mv -f $POINT ${POINT}_link
  if [ ! -d $POINT ]; then
    rm -f $POINT
    mkdir -p $POINT
  fi
}

# mount_name <partname(s)> <mountpoint> <flag>
mount_name() {
  local PART=$1
  local POINT=$2
  local FLAG=$3
  setup_mntpoint $POINT
  is_mounted $POINT && return
  ui_print "- Mounting $POINT"
  # First try mounting with fstab
  mount $FLAG $POINT 2>/dev/null
  if ! is_mounted $POINT; then
    local BLOCK=`find_block $PART`
    mount $FLAG $BLOCK $POINT
  fi
}

# mount_ro_ensure <partname(s)> <mountpoint>
mount_ro_ensure() {
  # We handle ro partitions only in recovery
  $BOOTMODE && return
  local PART=$1
  local POINT=$2
  mount_name "$PART" $POINT '-o ro'
  is_mounted $POINT || abort "! Cannot mount $POINT"
}

mount_partitions() {
  # Check A/B slot
  SLOT=`grep_cmdline androidboot.slot_suffix`
  if [ -z $SLOT ]; then
    SLOT=`grep_cmdline androidboot.slot`
    [ -z $SLOT ] || SLOT=_${SLOT}
  fi
  [ -z $SLOT ] || ui_print "- Current boot slot: $SLOT"

  # Mount ro partitions
  mount_ro_ensure "system$SLOT app$SLOT" /system
  if [ -f /system/init -o -L /system/init ]; then
    SYSTEM_ROOT=true
    setup_mntpoint /system_root
    if ! mount --move /system /system_root; then
      umount /system
      umount -l /system 2>/dev/null
      mount_ro_ensure "system$SLOT app$SLOT" /system_root
    fi
    mount -o bind /system_root/system /system
  else
    grep ' / ' /proc/mounts | grep -qv 'rootfs' || grep -q ' /system_root ' /proc/mounts \
    && SYSTEM_ROOT=true || SYSTEM_ROOT=false
  fi
  # /vendor is used only on some older devices for recovery AVBv1 signing so is not critical if fails
  [ -L /system/vendor ] && mount_name vendor$SLOT /vendor '-o ro'
  $SYSTEM_ROOT && ui_print "- Device is system-as-root"

  # Allow /system/bin commands (dalvikvm) on Android 10+ in recovery
  $BOOTMODE || mount_apex

  # Mount persist partition in recovery
  if ! $BOOTMODE && [ ! -z $PERSISTDIR ]; then
    # Try to mount persist
    PERSISTDIR=/persist
    mount_name persist /persist
    if ! is_mounted /persist; then
      # Fallback to cache
      mount_name "cache cac" /cache
      is_mounted /cache && PERSISTDIR=/cache || PERSISTDIR=
    fi
  fi
}

# loop_setup <ext4_img>, sets LOOPDEV
loop_setup() {
  unset LOOPDEV
  local LOOP
  local MINORX=1
  [ -e /dev/block/loop1 ] && MINORX=$(stat -Lc '%T' /dev/block/loop1)
  local NUM=0
  while [ $NUM -lt 64 ]; do
    LOOP=/dev/block/loop$NUM
    [ -e $LOOP ] || mknod $LOOP b 7 $((NUM * MINORX))
    if losetup $LOOP "$1" 2>/dev/null; then
      LOOPDEV=$LOOP
      break
    fi
    NUM=$((NUM + 1))
  done
}

mount_apex() {
  $BOOTMODE || [ ! -d /system/apex ] && return
  local APEX DEST
  setup_mntpoint /apex
  for APEX in /system/apex/*; do
    DEST=/apex/$(basename $APEX .apex)
    [ "$DEST" == /apex/com.android.runtime.release ] && DEST=/apex/com.android.runtime
    mkdir -p $DEST 2>/dev/null
    if [ -f $APEX ]; then
      # APEX APKs, extract and loop mount
      unzip -qo $APEX apex_payload.img -d /apex
      loop_setup apex_payload.img
      if [ ! -z $LOOPDEV ]; then
        ui_print "- Mounting $DEST"
        mount -t ext4 -o ro,noatime $LOOPDEV $DEST
      fi
      rm -f apex_payload.img
    elif [ -d $APEX ]; then
      # APEX folders, bind mount directory
      ui_print "- Mounting $DEST"
      mount -o bind $APEX $DEST
    fi
  done
  export ANDROID_RUNTIME_ROOT=/apex/com.android.runtime
  export ANDROID_TZDATA_ROOT=/apex/com.android.tzdata
  local APEXRJPATH=/apex/com.android.runtime/javalib
  local SYSFRAME=/system/framework
  export BOOTCLASSPATH=\
$APEXRJPATH/core-oj.jar:$APEXRJPATH/core-libart.jar:$APEXRJPATH/okhttp.jar:\
$APEXRJPATH/bouncycastle.jar:$APEXRJPATH/apache-xml.jar:$SYSFRAME/framework.jar:\
$SYSFRAME/ext.jar:$SYSFRAME/telephony-common.jar:$SYSFRAME/voip-common.jar:\
$SYSFRAME/ims-common.jar:$SYSFRAME/android.test.base.jar:$SYSFRAME/telephony-ext.jar:\
/apex/com.android.conscrypt/javalib/conscrypt.jar:\
/apex/com.android.media/javalib/updatable-media.jar
}

umount_apex() {
  [ -d /apex ] || return
  local DEST SRC
  for DEST in /apex/*; do
    [ "$DEST" = '/apex/*' ] && break
    SRC=$(grep $DEST /proc/mounts | awk '{ print $1 }')
    umount -l $DEST
    # Detach loop device just in case
    losetup -d $SRC 2>/dev/null
  done
  rm -rf /apex
  unset ANDROID_RUNTIME_ROOT
  unset ANDROID_TZDATA_ROOT
  unset BOOTCLASSPATH
}

get_flags() {
  # override variables
  getvar KEEPVERITY
  getvar KEEPFORCEENCRYPT
  getvar RECOVERYMODE
  if [ -z $KEEPVERITY ]; then
    if $SYSTEM_ROOT; then
      KEEPVERITY=true
      ui_print "- System-as-root, keep dm/avb-verity"
    else
      KEEPVERITY=false
    fi
  fi
  ISENCRYPTED=false
  grep ' /data ' /proc/mounts | grep -q 'dm-' && ISENCRYPTED=true
  [ "$(getprop ro.crypto.state)" = "encrypted" ] && ISENCRYPTED=true
  if [ -z $KEEPFORCEENCRYPT ]; then
    # No data access means unable to decrypt in recovery
    if $ISENCRYPTED || ! $DATA; then
      KEEPFORCEENCRYPT=true
      ui_print "- Encrypted data, keep forceencrypt"
    else
      KEEPFORCEENCRYPT=false
    fi
  fi
  [ -z $RECOVERYMODE ] && RECOVERYMODE=false
}

find_boot_image() {
  BOOTIMAGE=
  if $RECOVERYMODE; then
    BOOTIMAGE=`find_block recovery_ramdisk$SLOT recovery$SLOT sos`
  elif [ ! -z $SLOT ]; then
    BOOTIMAGE=`find_block ramdisk$SLOT recovery_ramdisk$SLOT boot$SLOT`
  else
    BOOTIMAGE=`find_block ramdisk recovery_ramdisk kern-a android_boot kernel bootimg boot lnx boot_a`
  fi
  if [ -z $BOOTIMAGE ]; then
    # Lets see what fstabs tells me
    BOOTIMAGE=`grep -v '#' /etc/*fstab* | grep -E '/boot(img)?[^a-zA-Z]' | grep -oE '/dev/[a-zA-Z0-9_./-]*' | head -n 1`
  fi
}

flash_image() {
  # Make sure all blocks are writable
  $MAGISKBIN/magisk --unlock-blocks 2>/dev/null
  case "$1" in
    *.gz) CMD1="$MAGISKBIN/magiskboot decompress '$1' - 2>/dev/null";;
    *)    CMD1="cat '$1'";;
  esac
  if $BOOTSIGNED; then
    CMD2="$BOOTSIGNER -sign"
    ui_print "- Sign image with verity keys"
  else
    CMD2="cat -"
  fi
  if [ -b "$2" ]; then
    local img_sz=`stat -c '%s' "$1"`
    local blk_sz=`blockdev --getsize64 "$2"`
    [ $img_sz -gt $blk_sz ] && return 1
    eval $CMD1 | eval $CMD2 | cat - /dev/zero > "$2" 2>/dev/null
  elif [ -c "$2" ]; then
    flash_eraseall "$2" >&2
    eval $CMD1 | eval $CMD2 | nandwrite -p "$2" - >&2
  else
    ui_print "- Not block or char device, storing image"
    eval $CMD1 | eval $CMD2 > "$2" 2>/dev/null
  fi
  return 0
}

# Common installation script for flash_script.sh and addon.d.sh
install_magisk() {
  cd $MAGISKBIN

  # Dump image for MTD/NAND character device boot partitions
  if [ -c $BOOTIMAGE ]; then
    nanddump -f boot.img $BOOTIMAGE
    local BOOTNAND=$BOOTIMAGE
    BOOTIMAGE=boot.img
  fi

  if [ $API -ge 21 ]; then
    eval $BOOTSIGNER -verify < $BOOTIMAGE && BOOTSIGNED=true
    $BOOTSIGNED && ui_print "- Boot image is signed with AVB 1.0"
  fi

  $IS64BIT && mv -f magiskinit64 magiskinit 2>/dev/null || rm -f magiskinit64

  # Source the boot patcher
  SOURCEDMODE=true
  . ./boot_patch.sh "$BOOTIMAGE"

  ui_print "- Flashing new boot image"

  # Restore the original boot partition path
  [ "$BOOTNAND" ] && BOOTIMAGE=$BOOTNAND
  flash_image new-boot.img "$BOOTIMAGE" || abort "! Insufficient partition size"

  ./magiskboot cleanup
  rm -f new-boot.img

  run_migrations
}

sign_chromeos() {
  ui_print "- Signing ChromeOS boot image"

  echo > empty
  ./chromeos/futility vbutil_kernel --pack new-boot.img.signed \
  --keyblock ./chromeos/kernel.keyblock --signprivate ./chromeos/kernel_data_key.vbprivk \
  --version 1 --vmlinuz new-boot.img --config empty --arch arm --bootloader empty --flags 0x1

  rm -f empty new-boot.img
  mv new-boot.img.signed new-boot.img
}

remove_system_su() {
  if [ -f /system/bin/su -o -f /system/xbin/su ] && [ ! -f /su/bin/su ]; then
    ui_print "- Removing system installed root"
    blockdev --setrw /dev/block/mapper/system$SLOT 2>/dev/null
    mount -o rw,remount /system
    # SuperSU
    if [ -e /system/bin/.ext/.su ]; then
      mv -f /system/bin/app_process32_original /system/bin/app_process32 2>/dev/null
      mv -f /system/bin/app_process64_original /system/bin/app_process64 2>/dev/null
      mv -f /system/bin/install-recovery_original.sh /system/bin/install-recovery.sh 2>/dev/null
      cd /system/bin
      if [ -e app_process64 ]; then
        ln -sf app_process64 app_process
      elif [ -e app_process32 ]; then
        ln -sf app_process32 app_process
      fi
    fi
    rm -rf /system/.pin /system/bin/.ext /system/etc/.installed_su_daemon /system/etc/.has_su_daemon \
    /system/xbin/daemonsu /system/xbin/su /system/xbin/sugote /system/xbin/sugote-mksh /system/xbin/supolicy \
    /system/bin/app_process_init /system/bin/su /cache/su /system/lib/libsupol.so /system/lib64/libsupol.so \
    /system/su.d /system/etc/install-recovery.sh /system/etc/init.d/99SuperSUDaemon /cache/install-recovery.sh \
    /system/.supersu /cache/.supersu /data/.supersu \
    /system/app/Superuser.apk /system/app/SuperSU /cache/Superuser.apk
  elif [ -f /cache/su.img -o -f /data/su.img -o -d /data/adb/su -o -d /data/su ]; then
    ui_print "- Removing systemless installed root"
    umount -l /su 2>/dev/null
    rm -rf /cache/su.img /data/su.img /data/adb/su /data/adb/suhide /data/su /cache/.supersu /data/.supersu \
    /cache/supersu_install /data/supersu_install
  fi
}

api_level_arch_detect() {
  API=`grep_prop ro.build.version.sdk`
  ABI=`grep_prop ro.product.cpu.abi | cut -c-3`
  ABI2=`grep_prop ro.product.cpu.abi2 | cut -c-3`
  ABILONG=`grep_prop ro.product.cpu.abi`

  ARCH=arm
  ARCH32=arm
  IS64BIT=false
  if [ "$ABI" = "x86" ]; then ARCH=x86; ARCH32=x86; fi;
  if [ "$ABI2" = "x86" ]; then ARCH=x86; ARCH32=x86; fi;
  if [ "$ABILONG" = "arm64-v8a" ]; then ARCH=arm64; ARCH32=arm; IS64BIT=true; fi;
  if [ "$ABILONG" = "x86_64" ]; then ARCH=x64; ARCH32=x86; IS64BIT=true; fi;
}

check_data() {
  DATA=false
  DATA_DE=false
  if grep ' /data ' /proc/mounts | grep -vq 'tmpfs'; then
    # Test if data is writable
    touch /data/.rw && rm /data/.rw && DATA=true
    # Test if DE storage is writable
    $DATA && [ -d /data/adb ] && touch /data/adb/.rw && rm /data/adb/.rw && DATA_DE=true
  fi
  $DATA && NVBASE=/data || NVBASE=/cache/data_adb
  $DATA_DE && NVBASE=/data/adb
  resolve_vars
}

find_manager_apk() {
  [ -z $APK ] && APK=/data/adb/magisk.apk
  [ -f $APK ] || APK=/data/magisk/magisk.apk
  [ -f $APK ] || APK=/data/app/com.topjohnwu.magisk*/*.apk
  if [ ! -f $APK ]; then
    DBAPK=`magisk --sqlite "SELECT value FROM strings WHERE key='requester'" 2>/dev/null | cut -d= -f2`
    [ -z $DBAPK ] && DBAPK=`strings /data/adb/magisk.db | grep 5requester | cut -c11-`
    [ -z $DBAPK ] || APK=/data/user_de/*/$DBAPK/dyn/*.apk
    [ -f $APK ] || [ -z $DBAPK ] || APK=/data/app/$DBAPK*/*.apk
  fi
  [ -f $APK ] || ui_print "! Unable to detect Magisk Manager APK for BootSigner"
}

run_migrations() {
  local LOCSHA1
  local TARGET
  # Legacy app installation
  local BACKUP=/data/adb/magisk/stock_boot*.gz
  if [ -f $BACKUP ]; then
    cp $BACKUP /data
    rm -f $BACKUP
  fi

  # Legacy backup
  for gz in /data/stock_boot*.gz; do
    [ -f $gz ] || break
    LOCSHA1=`basename $gz | sed -e 's/stock_boot_//' -e 's/.img.gz//'`
    [ -z $LOCSHA1 ] && break
    mkdir /data/magisk_backup_${LOCSHA1} 2>/dev/null
    mv $gz /data/magisk_backup_${LOCSHA1}/boot.img.gz
  done

  # Stock backups
  LOCSHA1=$SHA1
  for name in boot dtb dtbo dtbs; do
    BACKUP=/data/adb/magisk/stock_${name}.img
    [ -f $BACKUP ] || continue
    if [ $name = 'boot' ]; then
      LOCSHA1=`$MAGISKBIN/magiskboot sha1 $BACKUP`
      mkdir /data/magisk_backup_${LOCSHA1} 2>/dev/null
    fi
    TARGET=/data/magisk_backup_${LOCSHA1}/${name}.img
    cp $BACKUP $TARGET
    rm -f $BACKUP
    gzip -9f $TARGET
  done
}

#################
# Module Related
#################

set_perm() {
  chown $2:$3 $1 || return 1
  chmod $4 $1 || return 1
  CON=$5
  [ -z $CON ] && CON=u:object_r:system_file:s0
  chcon $CON $1 || return 1
}

set_perm_recursive() {
  find $1 -type d 2>/dev/null | while read dir; do
    set_perm $dir $2 $3 $4 $6
  done
  find $1 -type f -o -type l 2>/dev/null | while read file; do
    set_perm $file $2 $3 $5 $6
  done
}

mktouch() {
  mkdir -p ${1%/*} 2>/dev/null
  [ -z $2 ] && touch $1 || echo $2 > $1
  chmod 644 $1
}

request_size_check() {
  reqSizeM=`du -ms "$1" | cut -f1`
}

request_zip_size_check() {
  reqSizeM=`unzip -l "$1" | tail -n 1 | awk '{ print int(($1 - 1) / 1048576 + 1) }'`
}

boot_actions() { return; }

# Require ZIPFILE to be set
is_legacy_script() {
  unzip -l "$ZIPFILE" install.sh | grep -q install.sh
  return $?
}

# Require OUTFD, ZIPFILE to be set
install_module() {
  local PERSISTDIR
  command -v magisk >/dev/null && PERSISTDIR=$(magisk --path)/mirror/persist

  rm -rf $TMPDIR
  mkdir -p $TMPDIR

  setup_flashable
  mount_partitions
  api_level_arch_detect

  # Setup busybox and binaries
  $BOOTMODE && boot_actions || recovery_actions

  # Extract prop file
  unzip -o "$ZIPFILE" module.prop -d $TMPDIR >&2
  [ ! -f $TMPDIR/module.prop ] && abort "! Unable to extract zip file!"

  local MODDIRNAME
  $BOOTMODE && MODDIRNAME=modules_update || MODDIRNAME=modules
  local MODULEROOT=$NVBASE/$MODDIRNAME
  MODID=`grep_prop id $TMPDIR/module.prop`
  MODNAME=`grep_prop name $TMPDIR/module.prop`
  MODAUTH=`grep_prop author $TMPDIR/module.prop`
  MODPATH=$MODULEROOT/$MODID

  # Create mod paths
  rm -rf $MODPATH 2>/dev/null
  mkdir -p $MODPATH

  if is_legacy_script; then
    unzip -oj "$ZIPFILE" module.prop install.sh uninstall.sh 'common/*' -d $TMPDIR >&2

    # Load install script
    . $TMPDIR/install.sh

    # Callbacks
    print_modname
    on_install

    [ -f $TMPDIR/uninstall.sh ] && cp -af $TMPDIR/uninstall.sh $MODPATH/uninstall.sh
    $SKIPMOUNT && touch $MODPATH/skip_mount
    $PROPFILE && cp -af $TMPDIR/system.prop $MODPATH/system.prop
    cp -af $TMPDIR/module.prop $MODPATH/module.prop
    $POSTFSDATA && cp -af $TMPDIR/post-fs-data.sh $MODPATH/post-fs-data.sh
    $LATESTARTSERVICE && cp -af $TMPDIR/service.sh $MODPATH/service.sh

    ui_print "- Setting permissions"
    set_permissions
  else
    print_title "$MODNAME" "by $MODAUTH"
    print_title "Powered by Magisk"

    unzip -o "$ZIPFILE" customize.sh -d $MODPATH >&2

    if ! grep -q '^SKIPUNZIP=1$' $MODPATH/customize.sh 2>/dev/null; then
      ui_print "- Extracting module files"
      unzip -o "$ZIPFILE" -x 'META-INF/*' -d $MODPATH >&2

      # Default permissions
      set_perm_recursive $MODPATH 0 0 0755 0644
    fi

    # Load customization script
    [ -f $MODPATH/customize.sh ] && . $MODPATH/customize.sh
  fi

  # Handle replace folders
  for TARGET in $REPLACE; do
    ui_print "- Replace target: $TARGET"
    mktouch $MODPATH$TARGET/.replace
  done

  if $BOOTMODE; then
    # Update info for Magisk Manager
    mktouch $NVBASE/modules/$MODID/update
    cp -af $MODPATH/module.prop $NVBASE/modules/$MODID/module.prop
  fi

  # Copy over custom sepolicy rules
  if [ -f $MODPATH/sepolicy.rule -a -e "$PERSISTDIR" ]; then
    ui_print "- Installing custom sepolicy patch"
    # Remove old recovery logs (which may be filling partition) to make room
    rm -f $PERSISTDIR/cache/recovery/*
    PERSISTMOD=$PERSISTDIR/magisk/$MODID
    mkdir -p $PERSISTMOD
    cp -af $MODPATH/sepolicy.rule $PERSISTMOD/sepolicy.rule || abort "! Insufficient partition size"
  fi

  # Remove stuffs that don't belong to modules
  rm -rf \
  $MODPATH/system/placeholder $MODPATH/customize.sh \
  $MODPATH/README.md $MODPATH/.git* 2>/dev/null

  cd /
  $BOOTMODE || recovery_cleanup
  rm -rf $TMPDIR

  ui_print "- Done"
}

##########
# Presets
##########

# Detect whether in boot mode
[ -z $BOOTMODE ] && ps | grep zygote | grep -qv grep && BOOTMODE=true
[ -z $BOOTMODE ] && ps -A 2>/dev/null | grep zygote | grep -qv grep && BOOTMODE=true
[ -z $BOOTMODE ] && BOOTMODE=false

NVBASE=/data/adb
TMPDIR=/dev/tmp

# Bootsigner related stuff
BOOTSIGNERCLASS=a.a
BOOTSIGNER='/system/bin/dalvikvm -Xnoimage-dex2oat -cp $APK $BOOTSIGNERCLASS'
BOOTSIGNED=false

resolve_vars

##################################
# Magisk Manager internal scripts
##################################

run_delay() {
  (sleep $1; $2)&
}

env_check() {
  for file in busybox magisk magiskboot magiskinit util_functions.sh boot_patch.sh; do
    [ -f $MAGISKBIN/$file ] || return 1
  done
  return 0
}

fix_env() {
  cd $MAGISKBIN
  PATH=/system/bin /system/bin/sh update-binary -x
  ./busybox rm -f update-binary magisk.apk
  ./busybox chmod -R 755 .
  ./magiskinit -x magisk magisk
  cd /
}

direct_install() {
  rm -rf $MAGISKBIN/* 2>/dev/null
  mkdir -p $MAGISKBIN 2>/dev/null
  chmod 700 $NVBASE
  cp -af $1/. $MAGISKBIN
  rm -f $MAGISKBIN/new-boot.img
  echo "- Flashing new boot image"
  flash_image $1/new-boot.img $2
  if [ $? -ne 0 ]; then
    echo "! Insufficient partition size"
    return 1
  fi
  rm -rf $1
  return 0
}

restore_imgs() {
  [ -z $SHA1 ] && return 1
  local BACKUPDIR=/data/magisk_backup_$SHA1
  [ -d $BACKUPDIR ] || return 1

  get_flags
  find_boot_image

  for name in dtb dtbo; do
    [ -f $BACKUPDIR/${name}.img.gz ] || continue
    local IMAGE=$(find_block $name$SLOT)
    [ -z $IMAGE ] && continue
    flash_image $BACKUPDIR/${name}.img.gz $IMAGE
  done
  [ -f $BACKUPDIR/boot.img.gz ] || return 1
  flash_image $BACKUPDIR/boot.img.gz $BOOTIMAGE
}

post_ota() {
  cd $1
  chmod 755 bootctl
  ./bootctl hal-info || return
  [ $(./bootctl get-current-slot) -eq 0 ] && SLOT_NUM=1 || SLOT_NUM=0
  ./bootctl set-active-boot-slot $SLOT_NUM
  cat << EOF > post-fs-data.d/post_ota.sh
${1}/bootctl mark-boot-successful
rm -f ${1}/bootctl
rm -f ${1}/post-fs-data.d/post_ota.sh
EOF
  chmod 755 post-fs-data.d/post_ota.sh
  cd /
}

add_hosts_module() {
  # Do not touch existing hosts module
  [ -d $MAGISKTMP/modules/hosts ] && return
  cd $MAGISKTMP/modules
  mkdir -p hosts/system/etc
  cat << EOF > hosts/module.prop
id=hosts
name=Systemless Hosts
version=1.0
versionCode=1
author=Magisk Manager
description=Magisk Manager built-in systemless hosts module
EOF
  magisk --clone /system/etc/hosts hosts/system/etc/hosts
  touch hosts/update
  cd /
}

adb_pm_install() {
  local tmp=/data/local/tmp/patched.apk
  cp -f "$1" $tmp
  chmod 644 $tmp
  su 2000 -c pm install $tmp || pm install $tmp
  local res=$?
  rm -f $tmp
  return $res
}

check_boot_ramdisk() {
  # Create boolean ISAB
  [ -z $SLOT ] && ISAB=false || ISAB=true

  # If we are running as recovery mode, then we do not have ramdisk
  [ "$RECOVERYMODE" = "true" ] && return 1

  # If we are A/B, then we must have ramdisk
  $ISAB && return 0

  # If we are using legacy SAR, but not A/B, assume we do not have ramdisk
  if grep ' / ' /proc/mounts | grep -q '/dev/root'; then
    # Override recovery mode to true if not set
    [ -z $RECOVERYMODE ] && RECOVERYMODE=true
    return 1
  fi

  return 0
}

check_encryption() {
  if $ISENCRYPTED; then
    if [ $SDK_INT -lt 24 ]; then
      CRYPTOTYPE="block"
    else
      # First see what the system tells us
      CRYPTOTYPE=$(getprop ro.crypto.type)
      if [ -z $CRYPTOTYPE ]; then
        # If not mounting through device mapper, we are FBE
        if grep ' /data ' /proc/mounts | grep -qv 'dm-'; then
          CRYPTOTYPE="file"
        else
          # We are either FDE or metadata encryption (which is also FBE)
          grep -q ' /metadata ' /proc/mounts && CRYPTOTYPE="file" || CRYPTOTYPE="block"
        fi
      fi
    fi
  else
    CRYPTOTYPE="N/A"
  fi
}

##########################
# Non-root util_functions
##########################

mount_partitions() {
  [ "$(getprop ro.build.ab_update)" = "true" ] && SLOT=$(getprop ro.boot.slot_suffix)
  # Check whether non rootfs root dir exists
  grep ' / ' /proc/mounts | grep -qv 'rootfs' && SYSTEM_ROOT=true || SYSTEM_ROOT=false
}

get_flags() {
  KEEPVERITY=$SYSTEM_ROOT
  [ "$(getprop ro.crypto.state)" = "encrypted" ] && ISENCRYPTED=true || ISENCRYPTED=false
  KEEPFORCEENCRYPT=$ISENCRYPTED
  # Do NOT preset RECOVERYMODE here
}

run_migrations() { return; }

grep_prop() { return; }

#############
# Initialize
#############

mm_init() {
  export BOOTMODE=true
  mount_partitions
  get_flags
  run_migrations
  SHA1=$(grep_prop SHA1 $MAGISKTMP/config)
  check_boot_ramdisk && RAMDISKEXIST=true || RAMDISKEXIST=false
  check_encryption
  # Make sure RECOVERYMODE has value
  [ -z $RECOVERYMODE ] && RECOVERYMODE=false
}


#!/usr/bin/env bash
# Copyright (c) 2014, Facebook, Inc.
# All rights reserved.
#
# This source code is licensed under the BSD-style license found in
# the LICENSE file in the root directory of this source tree. An
# additional grant of patent rights can be found in the PATENTS file
# in the same directory.
#

#
# This file takes a list of stub names on its command line and
# writes to stdout the contents of the corresponding stubs.c.
#
set -euo pipefail
: ${XXD=xxd}

cat <<EOF
#include <stdint.h>
#include "stubs.h"

EOF

for stub in "$@"; do
    cname=${stub%/stub}
    cname=${cname//-/_}
    printf 'static const uint8_t %s[] = {\n' "$cname"
    $XXD -i < $stub
    printf '};\n\n'
done

printf 'const struct fbadb_stub stubs[] = {\n'
for stub in "$@"; do
    cname=${stub%/stub}
    cname=${cname//-/_}
    printf '  { %s, sizeof(%s) },\n' "$cname" "$cname"
done
printf '};\n\n'
printf 'const size_t nr_stubs=%s;\n' $#

