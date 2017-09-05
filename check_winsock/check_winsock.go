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
	filter := fmt.Sprintf("imagename eq %s", proc)
	cmd := exec.Command("tasklist", "-fi", filter)
	o, err := cmd.CombinedOutput()
	if err != nil {
		return false, err
	}
	output := string(o)
	return strings.Contains(output, proc), nil
}

func main() {
	var status int
	var addr string


	if len(os.Args) < 2 {
		usage()
		os.Exit(1)
	}

	expectedport := flag.Int("p", 0, "port number")
	process := flag.String("n", "", "process name")
	flag.Parse()
	addr = flag.Arg(0)
	if addr == "" {
		/* Remote address is a required parameter. */
		usage()
		os.Exit(1)
	}

	/*
	 * TODO(olly): Check if process is running using ProcStat(). If not,
	 * then don't even worry about checking sockets.
	 */
	status = UNKNOWN
	if *process != "" {
		fmt.Printf("warning: the -n option is not implemented yet\n")
		isrunning, err := ProcStat(*process)
		if err != nil {
			fmt.Fprintf(os.Stderr,
			    "warning: Error querying process list: %v\n", err)
		}
		if isrunning {
			fmt.Fprintf(os.Stderr, "%s is running\n", *process)
		} else if isrunning == false {
			fmt.Fprintf(os.Stderr,
			    "warning: %s not running\n", *process)
		}
	}

	isconnected, sockets, err := netstat.HasIPConnected(addr)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error on HasIPConnected(): %v\n", err)
	}

	if isconnected {
		fmt.Printf("active connection with %s\n", addr)
		/* Check that the remote port is as expected. */
		for i := 0; i < len(sockets); i++ {
			/*
			 * We don't care about remote ports if the option isn't
			 * set, so just return OK.
			 */
			if *expectedport == 0 {
				status = OK
				break
			}
			/* cast to int. Unknown why pkg netstat returns float64. */
			remoteport := int(sockets[i].RemotePort)
			if remoteport == *expectedport {
				status = OK
				fmt.Printf("socket uses expected port: %d\n",
				    remoteport)
				break
			} else if remoteport != *expectedport {
				status = CRITICAL
				fmt.Printf("socket uses unexpected port: %d\n",
				    remoteport)
			} else {
				status = UNKNOWN
				fmt.Printf("Cannot compare remote port with",
				    "expected port\n")
			}
		}
	} else if isconnected == false {
		status = WARNING
		fmt.Printf("No connection to %s\n", addr)
	}
	os.Exit(status)
}
