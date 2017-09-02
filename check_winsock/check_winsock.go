package main

import (
	"flag"
	"fmt"
	"os"
	"os/exec"
	"strings"

	"mig.ninja/mig/modules/netstat"
)

const UNKNOWN  int = 127
const CRITICAL int = 2
const WARNING  int = 1
const OK       int = 0

func usage() {
	fmt.Printf("usage: check_winsock [-p port] address\n")
}

/* 
 * ProcStat returns true if the process proc is currently running, or false
 * otherwise. Error is returned on unsuccessful listing of running processes.
 */
func ProcStat(proc string) (running bool, err error) {
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
	/*
	 * TODO(olly): Check if process is running using ProcStat(). If not,
	 * then don't even worry about checking sockets.
	 */

	expectedport := flag.Int("p", 0, "port number")
	process := flag.String("n", "", "process name")
	flag.Parse()
	addr := os.Args[1]

	if *process != "" {
		fmt.Printf("warning: the -n option is not yet implemented\n")
	}

	isconnected, sockets, err := netstat.HasIPConnected(addr)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error on HasIPConnected(): %v\n", err)
	}

	status := UNKNOWN
	if isconnected {
		fmt.Printf("established socket with %s\n", addr)
		/* We don't care about remote ports if the option isn't set. */
		if expectedport == 0 {
			status = OK
			break
		}
		/* Check that the remote port of each socket is as expected. */
		for i := 0; i <= len(sockets); i++ {
			remoteport := sockets[i].RemotePort
			if remoteport == expectedport {
				status = OK
				fmt.Printf("Socket uses expected port %d\n",
				    *expectedport)
			} else if remoteport != expectedport {
				status = CRITICAL
				fmt.Printf("Socket established with %s, ",
				    "but using port %d (not %d)",
				    addr, remoteport, *expectedport)
			}
		}
	} else if isconnected == false {
		status = WARNING
		fmt.Printf("No connection to %s\n", addr)
	}
	os.Exit(status)
}
