#!/bin/sh
PROGDIR=`dirname $0`
SERVER=http://192.168.0.251:8088/files
cd $PROGDIR
HOST_OS=$(uname -s)
case $HOST_OS in
  Darwin)
      #curl $SERVER/android-ndk32-r10-darwin-x86_64.tar.bz2 | tar xjv --strip-components 1
      #curl $SERVER/android-ndk64-r10-darwin-x86_64.tar.bz2 | tar xjv --strip-components 1
      curl  $SERVER/android-ndk-r10e-darwin-x86_64.tar.bz2  | tar xjv --strip-components 1
      ;;
  Linux)
      #curl $SERVER/android-ndk32-r10-linux-x86_64.tar.bz2 | tar xjv --strip-components 1
      curl $SERVER/android-ndk-r10e-linux-x86_64.tar.bz2 | tar xjv --strip-components 1
      ;;
  MINGW32*)
      curl $SERVER/android-ndk-r10-windows-x86.tar.bz2 | tar xjv --strip-components 1
      ;;
  MINGW64*)
      curl $SERVER/android-ndk32-r10-windows-x86_64.tar.bz2 | tar xjv --strip-components 1
      ;;
  *) echo "ERROR: Unknown host operating system: $HOST_OS"
      exit 1
esac
curl -O $SERVER/android.jar
git reset --hard
