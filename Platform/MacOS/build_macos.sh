#!/bin/sh

#  build_poco_android.sh
#
#

#===============================================================================
# Functions
#===============================================================================

abort()
{
echo
echo "Aborted: $@"
exit 1
}

doneSection()
{
echo
echo "    ================================================================="
echo "    Done"
echo
}

#===============================================================================


POCO=$1
POCO_VERSION=$2


#Execution starts here
cd $POCO

./configure \
--config=Darwin \
--static \
--no-tests \
--no-samples \
--omit=CppUnit,CppParser,CodeGeneration,PageCompiler,Remoting,Data,NetSSL_OpenSSL,Crypto,Zip

make -j32

#Copy includes
echo "Framework: Copying includes..."
mkdir -p lib/Darwin/include/Poco
for i in {Foundation,Util,XML,Net,Data,Data/SQLite}
do
cp -r $POCO/$i/include/Poco/*  lib/Darwin/include/Poco
done
