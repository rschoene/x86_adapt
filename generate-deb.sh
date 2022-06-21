#!/bin/bash
# this script generates a debian/ubuntu package with dkms support

#remove old directory
if [ -d debpack ]; then
    rm -r debpack
fi

#copy template
cp -r debpack_template debpack

#set revision
if [ -z "$1" ]; then
    REVISION=$(git log -1 --date=short --pretty=format:%cd)
else
    REVISION=$1
fi
echo $REVISION

find debpack/DEBIAN -type f | xargs sed -i "s/###VERSION###/$REVISION/g"
find debpack/usr/src/x86_adapt_defs-template -type f | xargs sed -i "s/###VERSION###/$REVISION/g"
find debpack/usr/src/x86_adapt_driver-template -type f | xargs sed -i "s/###VERSION###/$REVISION/g"

#create uncore knobs
cd definition_driver/knobs
./write_uncore_pmc_definitions.py
cd -

## x86_adapt_defs
#create definitions driver source
./definition_driver/prepare.py debpack/usr/src/x86_adapt_defs-template/src definition_driver/
#copy header
cp --parents definition_driver/x86_adapt_defs.h debpack/usr/src/x86_adapt_defs-template/

## x86_adapt_driver
#copy files
cp -r driver/. debpack/usr/src/x86_adapt_driver-template/src
# TODO: maybe change make file
./definition_driver/prepare.py debpack/usr/src/x86_adapt_driver-template/definition_driver definition_driver/
cp --parents definition_driver/x86_adapt_defs.h debpack/usr/src/x86_adapt_driver-template/


#building libs and example programs
mkdir build
cd build
cmake ..
make
cd -

#copy programs
mkdir -p  debpack/usr/bin
cp build/x86a_read debpack/usr/bin
cp build/x86a_write debpack/usr/bin
mkdir -p  debpack/usr/include
cp library/include/x86_adapt.h debpack/usr/include
mkdir -p debpack/usr/share
cp -r library/doc/man debpack/usr/share

#copy libs
mkdir -p debpack/usr/lib
cp build/libx86_adapt* debpack/usr/lib

#remove build directory
rm -r build

#rename dkms directory
mv debpack/usr/src/x86_adapt_defs-template/ debpack/usr/src/x86_adapt_defs-$REVISION
mv debpack/usr/src/x86_adapt_driver-template/ debpack/usr/src/x86_adapt_driver-$REVISION

#build deb
dpkg -b ./debpack x86_adapt_driver.deb
