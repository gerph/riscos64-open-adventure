#! /bin/sh
case $? in
    0) echo "ok - $1 succeeded";;
    *) echo "not ok - $1 failed";;
esac
