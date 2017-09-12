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

func usage() {
	fmt.Printf("usage: check_file_count [-w count] [-c count] path\n")
}

// FileNames takes a slice of FileInfos returned from os.Readdir, and prints a
// listing of the file names in the slice.
func FileNames(fi []os.FileInfo) {
	for i:= 0; i < len(fi); i++ {
		filename := fi[i].Name()
		fmt.Printf("%s\n", filename)
	}
}

func main() {
	var dir string
	var warn *int
	var crit *int
	var ret int

	warn = flag.Int("w", 8, "warning count")
	crit = flag.Int("c", 16, "warning count")
	flag.Parse()

	dir = flag.Arg(0)
	if dir == "" {
		usage()
		os.Exit(255)
	}

	f, err := os.Open(dir)
	if err != nil {
		fmt.Printf("Error opening %s: %v\n", dir, err)
	}
	fileinfo, err := f.Readdir(0)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error reading directory: %v", err)
	}

	/*
	 * Compare the file count against threshold values and set icinga2(8)
	 * compatible exit codes accordingly.
	 */
	count := len(fileinfo)
	ret = UNKNOWN
	if count >= *crit {
		ret = CRITICAL
	} else if count >= *warn {
		ret = WARNING
	} else if count <= *warn {
		ret = OK
	}

	fmt.Printf("%d files present in %s\n", count, dir)
	FileNames(fileinfo)
	os.Exit(ret)
}
