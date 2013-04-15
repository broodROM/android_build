#!/bin/bash

# Init Vars
HOMEDIR=${PWD}
ARIESVEDIR=${HOMEDIR}/out/target/product/ariesve
RELEASENAME="broodROM-JB-Release-4.zip"

# Copyright 2013 broodplank.net
# REV2 (Release 4)

# Number of simultaneous jobs

#CPU:
JOBS=5 

#Single core: -j2
#Dual core: -j3
#Quad Core: -j5
#Octa Core: -j9 (i7 Hyperthreading)
#Octa Core: -j16 (Native AMD octa core)


clear
clear
echo " "  
echo "----------------------------------------"
echo "-     broodROM Jellybean Release 4     -"
echo "-          Auto build script           -"
echo "----------------------------------------"
echo " "
busybox sleep 2


echo " "	
echo "----------------------------------------"
echo "- Preparing environment for compiling  -"
echo "----------------------------------------"
echo " "
busybox sleep 1
echo "Loading initial environment setup"
echo " "
. build/envsetup.sh
echo "Ordering full_ariesve-userdebug for lunch"
echo "Ignore the dependencies not found warning"
echo " "
lunch full_ariesve-userdebug

echo " "	
echo "----------------------------------------"
echo "-    Compiling broodROM Jellybean      -"
echo "-  Number of simultaneous jobs: ${JOBS}      -"
echo "----------------------------------------"
echo " "
busybox sleep 1
echo "Building!"
echo " "
make -j${JOBS}

echo " "	
echo "----------------------------------------"
echo "-       Manipulating output...         -"
echo "----------------------------------------"
echo " "
busybox sleep 1
echo "Replacing contents of xbin"
rm -Rf ${ARIESVEDIR}/system/xbin
cp -Rf ${HOMEDIR}/build/broodrom/xbin ${ARIESVEDIR}/system/xbin
echo "Replacing kernel"
cp -f ${ARIESVEDIR}/system/etc/broodrom/boot_ocuv.img ${ARIESVEDIR}/boot.img
echo "Placing META-INF folder"
rm -Rf ${ARIESVEDIR}/META-INF
cp -Rf ${HOMEDIR}/build/broodrom/recovery/META-INF ${ARIESVEDIR}/META-INF


echo " "	
echo "----------------------------------------"
echo "-     Packing final OTA zip file       -"
echo "----------------------------------------"
echo " "
busybox sleep 1
echo "Preparing zip contents:"
cd ${ARIESVEDIR}
rm -Rf autobuild
mkdir autobuild
echo "Copy boot.img"
cp boot.img autobuild/boot.img
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
echo " - All operations done!                      -"
echo " - Signed Zip can be found in root folder    -"
echo " ---------------------------------------------"

busybox sleep 5
exit
