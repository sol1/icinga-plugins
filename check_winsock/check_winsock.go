package main

import (
	"fmt"
	"os"
	"os/exec"
	"strings"

	"mig.ninja/mig/modules/netstat"
)


func usage() {
	fmt.Printf("usage: check_winsock address\n")
}

/* 
 * procstat returns true if the process proc is currently running, or false
 * otherwise. Error is returned on unsuccessful querying of running processes.
 */
func procstat(proc string) (running bool, err error) {
	cmdstring := fmt.Sprintf("tasklist /fi \"imagename eq %s\"", proc)
	cmd := exec.Command(cmdstring)
	o, err := cmd.Output()
	if err != nil {
		return false, err
	}
	output := string(o[:len(o)])
	return strings.Contains(proc, output), nil
}

func main() {
	if len(os.Args) < 2 {
		usage()
		os.Exit(1)
	}
	/* Check if process is running */

	addr := os.Args[1]
	isconnected, elements, err := netstat.HasIPConnected(addr)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error on HasIPConnected(): %v\n", err)
	}

	if isconnected {
		for i := 0; i < len(elements); i++ {
			port := elements[i].RemotePort
			fmt.Printf("Connected to %s on %d\n", addr, int(port))
		}
	} else {
		fmt.Printf("No connection to %s\n", addr)
	}
}
