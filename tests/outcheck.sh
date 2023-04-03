#! /bin/sh
# SPDX-FileCopyrightText: Eric S. Raymond
# SPDX-License-Identifier: BSD-2-Clause
case $? in
    0) echo "ok - $1 succeeded";;
    *) echo "not ok - $1 failed";;
esac
