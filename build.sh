#!/bin/bash
HOMEDIR=${PWD}
ARIESVEDIR=${HOMEDIR}/out/target/product/ariesve
RELEASENAME="broodROM-JB-Release-4.zip"
# Copyright 2013 broodplank.net


# Number of simultaneous jobs

JOBS=5 

#CPU:
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
. build/envsetup.sh
lunch full_ariesve-userdebug

echo " "	
echo "----------------------------------------"
echo "-    Compiling broodROM Jellybean      -"
echo "-  Number of simultaneous jobs: ${JOBS}      -"
echo "----------------------------------------"
echo " "
busybox sleep 1
make -j${JOBS}

echo " "	
echo "----------------------------------------"
echo "-       Manipulating output...         -"
echo "----------------------------------------"
echo " "
busybox sleep 1
rm -Rf ${ARIESVEDIR}/system/xbin/*
cp -Rf ${HOMEDIR}/build/broodrom/xbin/* ${ARIESVEDIR}/system/xbin/*
cp -f ${ARIESVEDIR}/system/etc/broodrom/boot_ocuv.img ${ARIESVEDIR}/boot.img
cp -Rf ${HOMEDIR}/build/broodrom/recovery/META-INF ${ARIESVEDIR}/META-INF


echo " "	
echo "----------------------------------------"
echo "-     Packing final OTA zip file       -"
echo "----------------------------------------"
echo " "
busybox sleep 1
cd ${ARIESVEDIR}
rm -Rf autobuild
mkdir autobuild
cp boot.img autobuild/
cp -R system autobuild/system
cp -R META-INF autobuild/META-INF
cd autobuild
zip -r ${RELEASENAME} .
mv -f ${RELEASENAME} ${HOMEDIR}/build/broodrom/${RELEASENAME}

echo " "	
echo "----------------------------------------"
echo "-     Signing final OTA zip file       -"
echo "----------------------------------------"
echo " "
busybox sleep 1

cd ${HOMEDIR}/build/broodrom
java -jar signapk.jar testkey.x509.pem testkey.pk8 ${RELEASENAME} signed-${RELEASENAME}
mv -f signed-${RELEASENAME} ${HOMEDIR}/signed-${RELEASENAME}
rm -f ${RELEASENAME} 



echo " "	
echo " All operations done!		"
echo " Signed Zip can be found in root folder"
echo " "

busybox sleep 5
exit










