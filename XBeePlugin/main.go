package main

import (
	"bytes"
	"encoding/binary"
	"encoding/hex"
	"flag"
	"fmt"
	"log"

	"golang.org/x/crypto/ssh"
)

//ID of the sensor to query
var ID string
var minTemp float64
var maxTemp float64
var minHumid float64
var maxHumid float64

func init() {
	//get command flags
	flag.StringVar(&ID, "id", "", "ID of the sensor to query.")
	flag.Float64Var(&minTemp, "mintemp", -9999, "If tempreture measeures below mintemp, test is failed")
	flag.Float64Var(&maxTemp, "maxtemp", -9999, "If tempreture measeures above maxtemp, test is failed")
	flag.Float64Var(&minHumid, "minhumid", -9999, "If humidity measeures below minhumid, test is failed")
	flag.Float64Var(&maxHumid, "maxhumid", -9999, "If humidity measeures above maxhumid, test is failed")

	flag.Parse()
}

func main() {
	if ID == "" || minTemp == -9999 || maxTemp == -9999 || minHumid == -9999 || maxHumid == -9999 {
		fmt.Println("Invalid flags, run --help for info")
		return
	}

	config := &ssh.ClientConfig{
		User: "python",
		Auth: []ssh.AuthMethod{
			ssh.Password("dbps"),
		},
	}

	//Establish connection with gateway SSH server
	conn, err := ssh.Dial("tcp", "someaddress:22", config)
	if err != nil {
		log.Fatal("unable to connect: ", err)
	}
	defer conn.Close()

	readDevice(ID, conn)
}

func readDevice(id string, conn *ssh.Client) {
	session, err := conn.NewSession()
	if err != nil {
		log.Fatal("unable to create session: ", err)
	}
	defer session.Close()

	var stdoutBuf bytes.Buffer
	session.Stdout = &stdoutBuf
	session.Run("xbee " + id + " IS")

	fmt.Println(stdoutBuf.String())

	unused := make([]byte, 18)
	light := make([]byte, 4)
	temp := make([]byte, 4)
	humidity := make([]byte, 4)

	stdoutBuf.Read(unused)
	stdoutBuf.Read(light)
	stdoutBuf.Read(humidity)
	stdoutBuf.Read(temp)

	lightValue := convertLight(convertToInt(light))
	tempValue := convertTemp(convertToInt(temp))
	humidityValue := convertHumidity(convertToInt(humidity))

	// if tempValue > maxTemp || tempValue < minTemp || humidityValue > maxHumid || humidityValue < minHumid {
	// 	os.Exit(1)
	// }

	fmt.Printf("\nLight: %f\n", lightValue)
	fmt.Printf("Tempreture: %f C\n", humidityValue)
	fmt.Printf("Humidity: %f\n\n", tempValue)
}

//converts the hexidecimal array of byte to an actual value
func convertToInt(valueBytes []byte) int16 {
	decodedBuf := make([]byte, 2)
	_, err := hex.Decode(decodedBuf, valueBytes)
	if err != nil {
		log.Fatal("unable to convert hex: ", err)
	}

	var result int16
	_ = binary.Read(bytes.NewReader(decodedBuf), binary.BigEndian, &result)
	return result
}

func convertTemp(input int16) float32 {
	ADC2 := float32(input)
	mVanalog := (ADC2 / 1023.0) * 1200
	tempC := (mVanalog - 500.0) / 10.0
	return tempC
}

func convertHumidity(input int16) float32 {
	ADC3 := float32(input)
	mVanalog := (ADC3 / 1023.0) * 1200
	hum := (((mVanalog*108.2/33.2)/5000 - 0.16) / 0.0062)

	return hum
}

func convertLight(input int16) float32 {
	ADC1 := float32(input)
	brightness := ((ADC1) / 1023.0) * 1200

	return brightness
}
