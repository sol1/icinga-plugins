package main

import (
	"bytes"
	"flag"
	"log"
	"os"
	"os/exec"
	"fmt"
	"bufio"
	"strings"
)

const UNKNOWN  int = 127
const CRITICAL int = 2
const WARNING  int = 1
const OK       int = 0

func usage() {
	fmt.Printf("usage: check_winsock [-C message] [-n process] [-p port] address\n")
}

/*
 * ProcStat returns true if the process proc is running, or false otherwise.
 * err is returned on failure to query the running processes.
 */
func ProcStat(proc string) (running bool, err error) {
	filter := fmt.Sprintf("imagename eq %s", proc)
	cmd := exec.Command("tasklist", "-fi", filter)
	o, err := cmd.CombinedOutput()
	if err != nil {
		return false, err
	}
	return strings.Contains(string(o), proc), nil
}

func WinNetstat() (output []byte, err error) {
	cmd := exec.Command("netstat", "-na", "-p", "TCP")
	o, err := cmd.CombinedOutput()
	if err != nil {
		log.Printf("WinNetstat(): %v\n", err)
		return output, err
	}
	return o, nil
}

func WinNetstatProc() (output []byte, err error) {
	cmd := exec.Command("netstat", "-bna", "-p", "TCP")
	o, err := cmd.CombinedOutput()
	if err != nil {
		log.Printf("WinNetstatProc(): %v\n", err)
		return output, err
	}
	return o, nil
}

func CheckConnected(addr string) (connected bool, err error) {
	output, err := WinNetstat()
	if err != nil {
		log.Printf("CheckConnected(): error receiving output\n")
		return false, err
	}

	r := bytes.NewReader(output)
	scanner := bufio.NewScanner(r)
	for scanner.Scan() {
		cols := strings.Fields(scanner.Text())
		// ignore UDP and empty lines.
		if len(cols) > 0 && cols[0] == "TCP" {
			longaddr := strings.Split(cols[2], ":")
			if longaddr[0] == addr {
				return true, nil
			}
		}
	}
	return false, err
}
/* 
 * CheckConnected returns true if the host is currently connected to the address
 * and port, or false otherwise. Error is returned on unsuccessful listing of
 * network info.
 */
func CheckConnectedPort(addr, port string) (connected bool, err error) {
	output, err := WinNetstat()
	r := bytes.NewReader(output)
	if err != nil {
		log.Printf("CheckConnectedPort(): error receving output\n")
		return false, err
	}

	scanner := bufio.NewScanner(r)
	for scanner.Scan() {
		cols := strings.Fields(scanner.Text())
		// ignore UDP and empty lines.
		if len(cols) > 0 && cols[0] == "TCP" {
			longaddr := strings.Split(cols[2], ":")
			if longaddr[0] == addr && longaddr[1] == port {
				return true, nil
			}
		}
	}

	if err := scanner.Err(); err != nil {
		log.Printf("Error scanning netstat output\n")
		os.Exit(UNKNOWN)
	}
	return false, err
}

/* 
 * CheckConnectedProc returns true if the process is currently connected to the address
 * and port, or false otherwise. Error is returned on unsuccessful listing of
 * network info.
 */
func CheckConnectedProc(proc, addr, port string)(connected bool, err error){
	output, err := WinNetstatProc()
	if err != nil {
		log.Printf("CheckConnectedProc(): netstat error: %v\n", err)
		return false, err
	}

	r := bytes.NewReader(output)
	scanner := bufio.NewScanner(r)
	var matchedaddr bool = false
	var curproc string = ""
	for scanner.Scan() {
		cols := strings.Fields(scanner.Text())
		if len(cols) > 0 && cols[0] == "TCP" {
			// proto = cols[0]
			// localconn = cols[1]
			remotehost := cols[2]
			longaddr := strings.Split(remotehost, ":")
			/*
			 * Check entry contains the address we're interested in.
			 * Otherwise, move on to next line.
			 */
			if longaddr[0] == addr && longaddr[1] == port {
				matchedaddr = true
				continue
			}
			continue
		}

		if len(cols) > 0 && strings.HasPrefix(cols[0], "[") {
			curproc = cols[0]
		}

		/*
		 * Check the socket parent process is as requested. We
		 * compare strings in the same format as returned by
		 * netstat with the 'b' option on windows:
		 * "[processname.exe]"
		 */
		procf := fmt.Sprintf("[%s]", proc)
		if curproc != procf {
			matchedaddr = false
		} else if matchedaddr && curproc == procf {
			return true, nil
		}
	}

	if err := scanner.Err(); err != nil {
		/* Can't scan? That's bad, bail out */
		log.Printf("Error scanning netstat output\n")
		os.Exit(UNKNOWN)
	}
	return false, err
}

func main() {
	var status int
	var addr string

	if len(os.Args) < 2 {
		usage()
		os.Exit(1)
	}

	expectedport := flag.String("p", "0", "port number")
	process := flag.String("n", "", "process name")
	critmsg := flag.String("C", "", "extra output on critical status")
	flag.Parse()
	addr = flag.Arg(0)
	status = UNKNOWN

	if addr == "" {
		/* Remote address is a required parameter. */
		usage()
		os.Exit(1)
	}

	if *process != "" {
		isrunning, err := ProcStat(*process)
		if err != nil {
			fmt.Fprintf(os.Stderr,
			    "Cannot determine status of %s\n", *process)
			fmt.Fprintf(os.Stderr,
			    "Error querying process list: %v\n", err)
			os.Exit(UNKNOWN)
		}
		if isrunning == false {
			fmt.Printf("%s not running\n", *process)
			os.Exit(OK)
		}
	}

	var connected bool
	var err error
	if *expectedport == "" {
		connected, err = CheckConnected(addr)
		if err != nil {
			fmt.Printf("Cannot check sockets\n")
		}
		if connected {
			fmt.Printf("Socket established to %s\n", addr)
		}
	}

	if *expectedport != "" && *process == "" {
		connected, err = CheckConnectedPort(addr, *expectedport)
		if err != nil {
			fmt.Printf("Error listing sockets\n")
		}
		if connected {
			fmt.Printf("Socket established to %s:%s\n", addr, *expectedport)
		}
	}

	if *process != "" {
		connected, err = CheckConnectedProc(*process, addr, *expectedport)
		if err != nil {
			fmt.Printf("Error listing sockets\n")
			log.Fatal(err)
		}
		if connected {
			fmt.Printf("%s has socket established to %s:%s\n",
			    *process, addr, *expectedport)
		} else {
			fmt.Printf("Process %s has no sockets", *process)
			fmt.Printf("matching criteria %s:%s\n", addr, *expectedport)
		}
	}

	if connected {
		status = OK
	} else {
		status = CRITICAL
		/* Print user-defined message set at command line */
		if *critmsg != "" {
			fmt.Println(*critmsg)
		}
	}

	os.Exit(status)
}
