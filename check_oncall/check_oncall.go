package main

import (
	"encoding/json"
        "flag"
	"fmt"
	"net/http"
        "strings"
        "os"
)

const apiSlug string = "https://api.opsgenie.com/v1.1/json/schedule/whoIsOnCall?"

func getUrl(apiKey *string, schedule *string) string {
    /* Check required flags are set. */
    if *apiKey == "nil" {
        fmt.Println("API key is required")
        os.Exit(3)
    }
    if *schedule == "nil" {
        fmt.Println("schedule name is required")
        os.Exit(3)
    }
    /* Create the API request URL. */
    s := []string{apiSlug, "apiKey=", *apiKey, "&name=", *schedule}
    url := strings.Join(s, "")
    return url
}

type participant struct {
    Name string
}

type jsonResponse struct {
    Participants []participant
}

func main() {

    apiKey := flag.String("k", "nil", "API Key from OpsGenie")
    schedule := flag.String("s", "nil", "Name of schedule")
    flag.Parse()

    apirequest := getUrl(apiKey, schedule)
    resp, err := http.Get(apirequest)
    if err != nil {
        fmt.Println("Error making API request: ", err)
        os.Exit(3)
    }

    var res jsonResponse
    decoder := json.NewDecoder(resp.Body)
    decoder.Decode(&res)

    if len(res.Participants[0].Name) == 0 {
        fmt.Println("Nobody!")
        os.Exit(2)
    } else {
        fmt.Println((res.Participants[0].Name))
        os.Exit(0)
    }
}
