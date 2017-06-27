#!/bin/sh

status=3
echo "Running positive test..."
if ./check_file_count -w 10 -c 20 regress/fivefiles; then
	echo "===> success"
	status=0
else
	echo "===> failure: exit status: $?"
	status=1
fi

echo "Running negative test"
if ! ./check_file_count -w 1 -c 2 regress/fivefiles; then
	echo "===> success"
	status=0
else
	echo "===> failure: exit status $?"
	status=1
fi

if [ $status -eq 0 ]; then
	echo "All tests passed"
elif [ $status -eq 1 ]; then
	echo "Tests failed"
elif [ $status -eq 3 ]; then
	echo "unknown error"
fi

exit $status
