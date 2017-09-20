package main

import (
	"bufio"
	"encoding/json"
	"flag"
	"fmt"
	"log"
	"os"
	"os/exec"
)

const OK string = "OK"
const DEGRADED string = "DEGRADED"
const REBUILDING string = "REBUILDING"

const K    int = 0
const WARN int = 1
const CRIT int = 2
const UNKNOWN int = 3


type Controller struct {
	Family string
	State	string
}

func ControllerStat(helper string) (cmsg []byte, err error) {
	output, err := exec.Command(helper).Output()
	if err != nil {
		log.Printf("ControllerStat(): Error running %s: %v", helper, err)
		return nil, err
	}
	return output, nil
}

func main() {
	var ctype = flag.String("t", "", "family type of RAID controller")
	flag.Parse()
	var cmesg []byte

	// Read incoming message from controller from either standard input or
	// from the standard output of a specified helper program.
	if *ctype == "" {
		scanner := bufio.NewScanner(os.Stdin)
		for scanner.Scan() {
			cmesg = scanner.Bytes()
		}
	} else {
		var err error
		cmesg, err = ControllerStat(*ctype)
		if err != nil {
			fmt.Printf("Could not run helper for %s\n", *ctype)
			os.Exit(UNKNOWN)
		}
	}

	var c Controller
	if err := json.Unmarshal(cmesg, &c); err != nil {
		fmt.Printf("Error unmarshalling json: %v\n", err)
		os.Exit(UNKNOWN)
	}
	if c.State == OK {
		fmt.Printf("%s reports state is %s\n", c.Family, c.State)
		os.Exit(K)
	}
	if c.State != OK {
		fmt.Printf("controller %s state is %s\n", c.Family, c.State)
		os.Exit(CRIT)
	}
}
