#!/bin/bash

# ---------------------------------------------------------
# >>> Init Vars
  HOMEDIR=${PWD}
  ${DEVICE}DIR=${HOMEDIR}/out/target/product/${DEVICE}
  RELEASENAME="broodROM-JB-Release-4.zip"
  # JOBS=`cat /proc/cpuinfo | grep processor | wc -l`;
  # If you uncomment the "JOBS" var make sure you comment the 
  # "JOBS" var down below in the build config
# ---------------------------------------------------------

# ---------------------------------------------------------
# >>> broodROM Jellybean Automated Build Script
# >>> Copyright 2013 broodplank.net
# >>> REV7 (Release 4)
# ---------------------------------------------------------

# ---------------------------------------------------------
# >>> Check for updates before starting?
#
  CHECKUPDATES=0        # 0 to disable, 1 for repo sync
# ---------------------------------------------------------

# ---------------------------------------------------------
#
# >>> BUILD CONFIG
#
# ---------------------------------------------------------
#
# >>> Main Configuration (intended for option 6, All-In-One) 
#
  JOBS=5                # CPU Cores + 1 (also hyperthreading)
  INCLUDERECOVERY=1      # Includes recovery.img in zip (0/1)
  INCLUDEGAPPS=0         # Include Lite version of GAPPS 
                         # Only for personal use! Distribution is strictly prohibited!
#
# >>> Odin Configuration
# All files besides system.img, boot.img, reovery.img and cache.img
# should be placed in build/broodrom/odin to be included if 1 (below)
#
  BUILDODIN=0            # If 1, an odin package will be created
                         # If 0, all options below will be ignored
  ODINADDMODEM=0         # Add amss.mbn (modem) to odin package
  ODINADDBOOT=0          # Add adsp.mbn, dbl.mbn, osbl.mbn (bootloader)
  ODINADDPARAM=0         # Add EMMCBOOT.MBN and partition.bin
#
# ---------------------------------------------------------


. build/envsetup.sh
clear


echo "----------------------------------------"
echo "-         BROODROM JELLYBEAN           -"
echo "----------------------------------------"
echo " "
echo " >>> Please choose target device"

lunch 
clear

echo ${TARGET_PRODUCT} | sed -e 's/full_//g' > ./currentdevice
export DEVICE=`cat ./currentdevice`;
rm -f ./currentdevice




ShowMenu () {
clear
echo " "	
echo "----------------------------------------"
echo "-     broodROM Jellybean Release 4     -"
echo "-          Auto build script           -"
echo "-       Version: Revision 7            -"
echo "-                                      -"
echo "-         www.broodplank.net           -"
echo "----------------------------------------"
echo " "
echo ">> Chosen target device: ${DEVICE}"
echo ">> Number of simultaneous jobs: ${JOBS}"
echo " "
echo "Please make your choice:"
echo " "
echo " [1] Update broodROM JB (Sync repositories)"
echo " [2] Compile broodROM JB"
echo " [3] Compile broodRecovery"
echo " [4] Build CWM ZIP"
echo " [5] Build Odin Image"
echo " "
echo " [6] All of the above actions"
echo " "
echo " If option 6 is chosen, please open the build.sh script"
echo " in the source root and adjust the variables to your needs"
echo " "
echo " [x] Exit"
echo " "


}

while [ 1 ]
do
ShowMenu
read CHOICE
case "$CHOICE" in

"1")
clear
echo "----------------------------------------"
echo "- Syncing repositories...              -"
echo "----------------------------------------"
repo sync
clear
;;


"2")
clear
echo " "	
echo "----------------------------------------"
echo "- Preparing environment for compiling  -"
echo "----------------------------------------"
echo " "
busybox sleep 1
echo "Loading initial environment setup"
echo " "
. build/envsetup.sh
echo " "
echo "Ordering full_${DEVICE}-userdebug for lunch"
echo "Ignore the dependencies not found warning"
echo " "
lunch full_${DEVICE}-userdebug
echo " "	
echo "----------------------------------------"
echo "-    Compiling broodROM Jellybean      -"
echo "-  Number of simultaneous jobs: ${JOBS}      -"
echo "----------------------------------------"
echo " "
busybox sleep 1
echo "Building!"
echo " "
make -j${JOBS} ${MAKEPARAM}
;;


"3")
clear
echo " "	
echo "----------------------------------------"
echo "- Preparing environment for compiling  -"
echo "----------------------------------------"
echo " "
busybox sleep 1
echo "Loading initial environment setup"
echo " "
. build/envsetup.sh
echo " "
echo "Ordering full_${DEVICE}-userdebug for lunch"
echo "Ignore the dependencies not found warning"
echo " "
lunch full_${DEVICE}-userdebug
echo " "	
echo "----------------------------------------"
echo "-        Compiling broodRecovery       -"
echo "-  Number of simultaneous jobs: ${JOBS}      -"
echo "----------------------------------------"
echo " "
busybox sleep 1
echo "Building!"
echo " "
make otatools -j${JOBS}
make recoveryimage -j${JOBS}
;; 

"4")
echo " "	
echo "----------------------------------------"
echo "-       Manipulating output...         -"
echo "----------------------------------------"
echo " "
busybox sleep 1
echo "Replacing contents of xbin"
rm -Rf ${${DEVICE}DIR}/system/xbin
cp -Rf ${HOMEDIR}/build/broodrom/xbin ${${DEVICE}DIR}/system/xbin
echo "Replacing kernel"
cp -f ${${DEVICE}DIR}/system/etc/broodrom/boot_ocuv.img ${${DEVICE}DIR}/boot.img
if [[ "$INCLUDERECOVERY" == "1" ]]; then
	echo "Placing META-INF folder"
	rm -Rf ${${DEVICE}DIR}/META-INF
	cp -Rf ${HOMEDIR}/build/broodrom/recovery/META-INF1 ${${DEVICE}DIR}/META-INF
else
	echo "Placing META-INF folder"
	rm -Rf ${${DEVICE}DIR}/META-INF
	cp -Rf ${HOMEDIR}/build/broodrom/recovery/META-INF ${${DEVICE}DIR}/META-INF
fi;


echo " "	
echo "----------------------------------------"
echo "-     Packing final OTA zip file       -"
echo "----------------------------------------"
echo " "
busybox sleep 1
echo "Preparing zip contents:"
cd ${${DEVICE}DIR}
rm -Rf autobuild
mkdir autobuild
echo "Copy boot.img"
cp boot.img autobuild/boot.img
if [[ "$INCLUDERECOVERY" == "1" ]]; then
echo "Copy recovery.img"
cp -f recovery.img autobuild/recovery.img
fi;
echo "Copy system folder"
cp -R system autobuild/system
echo "Copy META-INF folder"
cp -R META-INF autobuild/META-INF
cd autobuild
echo "Zipping all"
zip -r ${RELEASENAME} .
mv -f ${RELEASENAME} ${HOMEDIR}/build/broodrom/${RELEASENAME}

echo " "	
echo "----------------------------------------"
echo "-     Signing final OTA zip file       -"
echo "----------------------------------------"
echo " "
busybox sleep 1
cd ${HOMEDIR}/build/broodrom
echo "Signing, please wait..."
java -jar signapk.jar testkey.x509.pem testkey.pk8 ${RELEASENAME} signed-${RELEASENAME}
mv -f signed-${RELEASENAME} ${HOMEDIR}/signed-${RELEASENAME}
rm -f ${RELEASENAME}
echo "Signing done!" 
echo " "
echo " "
echo " ---------------------------------------------"	
echo " - CWM Zip creation process completed        -"
echo " - Signed Zip can be found in root folder    -"
echo " ---------------------------------------------"
;;


"5")
clear
rm -Rf ${HOMEDIR}/broodROM-Release-4.tar.md5
        rm -Rf ${${DEVICE}DIR}/autobuildodin
	echo " "	
	echo "----------------------------------------"
	echo "-        Building Odin Package         -"
	echo "----------------------------------------"
	echo "-                                      - "
	echo "- Build Odin Package:                  -"
	echo "- Include Modem: ${ODINADDMODEM}                     -"
	echo "- Include Bootloader: ${ODINADDBOOT}                -"
	echo "- Include Param: ${ODINADDPARAM}                     -"
	echo "----------------------------------------"
	echo " "
	busybox sleep 5
        echo "Preparing files for packaging"
        echo " "
	rm -Rf ${${DEVICE}DIR}/autobuildodin
	mkdir ${${DEVICE}DIR}/autobuildodin
	cp ${${DEVICE}DIR}/system.img ${${DEVICE}DIR}/autobuildodin/system.img
	cp ${${DEVICE}DIR}/system/etc/broodrom/boot_ocuv.img ${${DEVICE}DIR}/autobuildodin/boot.img
	cp ${${DEVICE}DIR}/recovery.img ${${DEVICE}DIR}/autobuildodin/recovery.img
        echo "Creating empty cache file"
	dd if=/dev/zero of=${${DEVICE}DIR}/autobuildodin/cache.img bs=1K count=102400
		if [[ "$ODINADDMODEM" == "1" ]]; then
			cp ${HOMEDIR}/build/broodrom/odin/amss.mbn ${${DEVICE}DIR}/autobuildodin/amss.mbn
			$ODINMODEM = "amss.mbn"
		fi;
		if [[ "$ODINADDBOOT" == "1" ]]; then
			cp ${HOMEDIR}/build/broodrom/odin/adsp.mbn ${${DEVICE}DIR}/autobuildodin/adsp.mbn
			cp ${HOMEDIR}/build/broodrom/odin/osbl.mbn ${${DEVICE}DIR}/autobuildodin/osbl.mbn
			cp ${HOMEDIR}/build/broodrom/odin/dbl.mbn ${${DEVICE}DIR}/autobuildodin/dbl.mbn
            $ODINBOOT = "adsp.mbn osbl.mbn dbl.mbn"
		fi;
		if [[ "$ODINADDPRAM" == "1" ]]; then
			cp ${HOMEDIR}/build/broodrom/odin/EMMCBOOT.MBN ${${DEVICE}DIR}/autobuildodin/EMMCBOOT.MBN
			cp ${HOMEDIR}/build/broodrom/odin/partition.bin ${${DEVICE}DIR}/autobuildodin/partition.bin
            $ODINPARAM = "EMMCBOOT.MBN partition.bin"
		fi;
	echo " "
        echo "Packing odin files"
        echo " "
	cd ${${DEVICE}DIR}/autobuildodin
	tar -c boot.img recovery.img system.img cache.img ${ODINMODEM} ${ODINBOOT} ${ODINPARAM} > broodROM-Release-4.tar
	echo " "
        echo "Adding MD5 Sums"
        echo " "    
	md5sum -t broodROM-Release-4.tar >> broodROM-Release-4.tar
	mv broodROM-Release-4.tar ${HOMEDIR}/broodROM-Release-4.tar.md5
	echo " "
        echo "Done!"
        echo " "    
        busybox sleep 1
;;


"6")
if [[ "$CHECKUPDATES" == "1" ]]; then
       echo "----------------------------------------"
       echo "- Syncing repositories...              -"
       echo "----------------------------------------"
       repo sync
       clear
fi;

echo " "	
echo "----------------------------------------"
echo "- Preparing environment for compiling  -"
echo "----------------------------------------"
echo " "
busybox sleep 1
echo "Loading initial environment setup"
echo " "
. build/envsetup.sh
echo " "
echo "Ordering full_${DEVICE}-userdebug for lunch"
echo "Ignore the dependencies not found warning"
echo " "
lunch full_${DEVICE}-userdebug

echo " "	
echo "----------------------------------------"
echo "-    Compiling broodROM Jellybean      -"
echo "-  Number of simultaneous jobs: ${JOBS}      -"
echo "----------------------------------------"
echo " "
busybox sleep 1
echo "Building!"
echo " "
make -j${JOBS} ${MAKEPARAM}

echo " "	
echo "----------------------------------------"
echo "-       Manipulating output...         -"
echo "----------------------------------------"
echo " "
busybox sleep 1
echo "Replacing contents of xbin"
rm -Rf ${${DEVICE}DIR}/system/xbin
cp -Rf ${HOMEDIR}/build/broodrom/xbin ${${DEVICE}DIR}/system/xbin
echo "Replacing kernel"
cp -f ${${DEVICE}DIR}/system/etc/broodrom/boot_ocuv.img ${${DEVICE}DIR}/boot.img
if [[ "$INCLUDERECOVERY" == "1" ]]; then
	echo "Placing META-INF folder"
	rm -Rf ${${DEVICE}DIR}/META-INF
	cp -Rf ${HOMEDIR}/build/broodrom/recovery/META-INF1 ${${DEVICE}DIR}/META-INF
else
	echo "Placing META-INF folder"
	rm -Rf ${${DEVICE}DIR}/META-INF
	cp -Rf ${HOMEDIR}/build/broodrom/recovery/META-INF ${${DEVICE}DIR}/META-INF
fi;
if [[ "$INCLUDEGAPPS" == "1" ]]; then
    echo "Including GAPPS into system, ONLY FOR PERSONAL USE!"
    cp -Rf ${HOMEDIR}/build/broodrom/gapps/* ${${DEVICE}DIR}/system/
fi;

echo " "	
echo "----------------------------------------"
echo "-     Packing final OTA zip file       -"
echo "----------------------------------------"
echo " "
busybox sleep 1
echo "Preparing zip contents:"
cd ${${DEVICE}DIR}
rm -Rf autobuild
mkdir autobuild
echo "Copy boot.img"
cp boot.img autobuild/boot.img
if [[ "$INCLUDERECOVERY" == "1" ]]; then
echo "Copy recovery.img"
cp -f recovery.img autobuild/recovery.img
fi;
echo "Copy system folder"
cp -R system autobuild/system
echo "Copy META-INF folder"
cp -R META-INF autobuild/META-INF
cd autobuild
echo "Zipping all"
zip -r ${RELEASENAME} .
mv -f ${RELEASENAME} ${HOMEDIR}/build/broodrom/${RELEASENAME}

echo " "	
echo "----------------------------------------"
echo "-     Signing final OTA zip file       -"
echo "----------------------------------------"
echo " "
busybox sleep 1

cd ${HOMEDIR}/build/broodrom
echo "Signing, please wait..."
java -jar signapk.jar testkey.x509.pem testkey.pk8 ${RELEASENAME} signed-${RELEASENAME}
mv -f signed-${RELEASENAME} ${HOMEDIR}/signed-${RELEASENAME}
rm -f ${RELEASENAME}
echo "Signing done!" 
echo " "
echo " "
echo " ---------------------------------------------"	
echo " - CWM Zip creation process completed        -"
echo " - Signed Zip can be found in root folder    -"
echo " ---------------------------------------------"

busybox sleep 3

if [[ "$BUILDODIN" == "1" ]]; then
	rm -Rf ${HOMEDIR}/broodROM-Release-4.tar.md5
        rm -Rf ${${DEVICE}DIR}/autobuildodin
	echo " "	
	echo "----------------------------------------"
	echo "-     Performing Additional Tasks      -"
	echo "----------------------------------------"
	echo "-                                      - "
	echo "- Build Odin Package:                  -"
	echo "- Include Modem: ${ODINADDMODEM}                     -"
	echo "- Include Bootloader: ${ODINADDBOOT}                -"
	echo "- Include Param: ${ODINADDPARAM}                     -"
	echo "----------------------------------------"
	echo " "
	busybox sleep 5
        echo "Preparing files for packaging"
        echo " "
	rm -Rf ${${DEVICE}DIR}/autobuildodin
	mkdir ${${DEVICE}DIR}/autobuildodin
	cp ${${DEVICE}DIR}/system.img ${${DEVICE}DIR}/autobuildodin/system.img
	cp ${${DEVICE}DIR}/system/etc/broodrom/boot_ocuv.img ${${DEVICE}DIR}/autobuildodin/boot.img
	cp ${${DEVICE}DIR}/recovery.img ${${DEVICE}DIR}/autobuildodin/recovery.img
        echo "Creating empty cache file"
	dd if=/dev/zero of=${${DEVICE}DIR}/autobuildodin/cache.img bs=1K count=102400
		if [[ "$ODINADDMODEM" == "1" ]]; then
			cp ${HOMEDIR}/build/broodrom/odin/amss.mbn ${${DEVICE}DIR}/autobuildodin/amss.mbn
			$ODINMODEM = "amss.mbn"
		fi;
		if [[ "$ODINADDBOOT" == "1" ]]; then
			cp ${HOMEDIR}/build/broodrom/odin/adsp.mbn ${${DEVICE}DIR}/autobuildodin/adsp.mbn
			cp ${HOMEDIR}/build/broodrom/odin/osbl.mbn ${${DEVICE}DIR}/autobuildodin/osbl.mbn
			cp ${HOMEDIR}/build/broodrom/odin/dbl.mbn ${${DEVICE}DIR}/autobuildodin/dbl.mbn
            $ODINBOOT = "adsp.mbn osbl.mbn dbl.mbn"
		fi;
		if [[ "$ODINADDPRAM" == "1" ]]; then
			cp ${HOMEDIR}/build/broodrom/odin/EMMCBOOT.MBN ${${DEVICE}DIR}/autobuildodin/EMMCBOOT.MBN
			cp ${HOMEDIR}/build/broodrom/odin/partition.bin ${${DEVICE}DIR}/autobuildodin/partition.bin
            $ODINPARAM = "EMMCBOOT.MBN partition.bin"
		fi;
	echo " "
        echo "Packing odin files"
        echo " "
	cd ${${DEVICE}DIR}/autobuildodin
	tar -c boot.img recovery.img system.img cache.img ${ODINMODEM} ${ODINBOOT} ${ODINPARAM} > broodROM-Release-4.tar
	echo " "
        echo "Adding MD5 Sums"
        echo " "    
	md5sum -t broodROM-Release-4.tar >> broodROM-Release-4.tar
	mv broodROM-Release-4.tar ${HOMEDIR}/broodROM-Release-4.tar.md5
        echo "Cleaning remains..."
        echo " "  
        rm -f ${HOMEDIR}/cache.img 
        rm -Rf ${${DEVICE}DIR}/autobuild
        rm -Rf ${${DEVICE}DIR}/autobuildodin
        rm -Rf ${${DEVICE}DIR}/META-INF
        echo " "
	echo " ---------------------------------------------"	
	echo " - Odin package creation done!               -"
	echo " - Odin One package can be found in root     -"
	echo " ---------------------------------------------"
	echo " "
	echo " EXIT"
fi;
;;


"x")
exit
;;


esac

done
exit

