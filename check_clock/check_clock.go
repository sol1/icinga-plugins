/* Copyright (c) 2017 Oliver Lowe, Sol1 pty ltd. All rights reserved. */

package main

import (
	"flag"
	"fmt"
	"log"
	"math"
	"os"
	"time"
)

func usage() {
	fmt.Print("usage: check_clock [-w seconds] [-c seconds] hostname\n")
}

func main() {
	var warn, crit *float64;    // warning, critical thresholds
	var hostname string;        // remote ntp server
	var ltime, rtime time.Time; // local and remote times.

	if len(os.Args) < 2 {
		usage()
		os.Exit(1)
	}

	warn     = flag.Float64("w", 1, "warning threshold")
	crit     = flag.Float64("c", 2, "critical threshold")
	hostname = flag.Arg(0)
	flag.Parse()

	/* Sanity check. */
	if *warn > *crit {
		fmt.Println("check_clock: warning larger than critical ",
		            "threshold.");
		usage()
		os.Exit(1)
	}

	/* From NTP server get remote time, and get local system time. */
	ltime = time.Now()

	rtime, err := TimeV(hostname, 4)
	if (err != nil) {
		log.Fatal("Error querying ntp server: ", err)
		os.Exit(3)
	}

	/*
	 * Calculate absolute value of the offset to account for both positive
	 * and negative differences. Exit with warning or error if difference
	 * falls outside of acceptable limits.
	 */
	offset := ltime.Sub(rtime)
	diff := math.Abs(float64(offset.Seconds()))
	if diff >= *crit {
		fmt.Printf("Local clock inaccurate: offset %d\n", offset)
		os.Exit(2)
	} else if (diff <= *crit && diff > *warn) {
		fmt.Printf("Local clock may be inaccurate: offset %d\n", offset)
		os.Exit(1)
	} else if diff < *warn {
		fmt.Printf("Local clock is accurate: offset is %v\n", offset)
		os.Exit(0)
	} else {
		log.Println("Unexpected time difference.")
		os.Exit(3)
	}
}
