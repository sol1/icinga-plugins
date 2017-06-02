package main

import (
	"fmt"
	"os"
	"time"
)

func modtime(path string) (time time.Time, err error) {

	fi, err := os.Stat(path);
	if (err != nil) {
		fmt.Fprintf(os.Stderr, "Error opening %s\n", path);
		return time, err;
	} else {
		fmt.Printf("Successful stat() on %s\n", path);
		return fi.ModTime(), nil;
	}
}

func main() {
	var path string;
	path = os.Args[1];

	mt, err := modtime(path);
	if (err != nil) {
		os.Exit(1);
	} else {
		fmt.Print(mt);
	}
	fmt.Println("I'm a noob lol!")

};
