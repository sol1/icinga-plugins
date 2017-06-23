package main

import (
	"flag"
	"fmt"
	"os"
)

const UNKNOWN int = 3
const CRITICAL int = 2
const WARNING int = 1
const OK int = 0

func main() {
	var dir string
	var warn *int
	var crit *int
	var ret int

	warn = flag.Int("w", 8, "warning count")
	crit = flag.Int("c", 16, "warning count")
	flag.Parse()

	dir = flag.Arg(0)
	f, err := os.Open(dir)
	if err != nil {
		fmt.Println(err)
	}
	fileinfo, err := f.Readdir(0)
	if err != nil {
		fmt.Println(err)
	}

	/*
	 * Compare the file count against threshold values and set icinga2(8)
	 * compatible exit codes accordingly.
	 */
	count := len(fileinfo)
	ret = 3
	if count >= *crit {
		ret = CRITICAL
	} else if count >= *warn {
		ret = WARNING
	} else if count <= *warn {
		ret = OK
	}

	fmt.Printf("%d files present in %s\n", count, dir)
	os.Exit(ret)
}
