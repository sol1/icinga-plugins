#!/bin/sh

touch regress/newfile

status=3
echo "Testing success behaviour..."
if ./check_age regress/newfile; then
	echo "===> success"
	status=0
else
	echo "===> failure: exit status $?"
	status=1
fi

echo "Testing error behaviour..."
# create a file modified over 2 hours ago
echo "I'm old" > regress/oldfile
touch -A -020001 regress/oldfile 
if ! ./check_age regress/oldfile; then
	echo "===> success"
	status=0
else
	echo "===> failure: exit status $?"
	status=1
fi

echo "Testing success with custom options..."
touch regress/newfile
if ./check_age -w 12000 -c 13000 regress/newfile; then
	echo "===> success"
	status=0
else
	echo "===> failure: exit status $?"
	status=1
fi

echo "Testing failure with custom options..."
# This check should exit error; we set options such that files with a
# modification date older than 600 seconds should trigger a non-zero exit code.
# We check a file that we know is at least 3 hours (10000 seconds) old.
touch -A -030001 regress/oldfile
if ! ./check_age -w 300 -c 600 regress/oldfile; then
	echo "===> success"
	status=0
else
	echo "===> failure: exit status $?"
	status=1
fi

if [ $status -eq 0 ]; then
	echo "All tests succeeded"
elif [ $status -eq 1 ]; then
	echo "Tests failed"
else
	echo "fatal: unknown error"
	exit 3
fi

exit $status
