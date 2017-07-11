package main

import (
	"fmt"
	"flag"
	"math"
	"os"
	"time"
)

func modtime(path string) (time time.Time, err error) {

	fi, err := os.Stat(path);
	if (err != nil) {
		fmt.Fprintf(os.Stderr, "Error opening %s\n", path);
		return time, err;
	} else {
		return fi.ModTime(), nil;
	}
}

func main() {
	var path string
	var warn, crit *float64;
	var now time.Time;
	var offset time.Duration;
	var diff float64;

	warn = flag.Float64("w", 1800, "warning threshold");
	crit = flag.Float64("c", 3600, "critical threshold");
	flag.Parse();
	path = flag.Arg(0);

	/* Start with an unknown status */
	var ret int;
	ret = 3;

	mt, err := modtime(path);
	if (err != nil) {
		fmt.Fprintf(os.Stderr, "Error checking modification time of %s:",
		    path)
	}

	now = time.Now();
	offset = now.Sub(mt);

	diff = math.Abs(float64(offset.Seconds()))
	if (diff >= *crit) {
		ret = 2;
	} else if (diff >= *warn) {
		ret = 1;
	} else if (diff < *warn) {
		ret = 0;
	}

	fmt.Printf("%s modified %g seconds ago\n", path, diff);
	os.Exit(ret);
}
