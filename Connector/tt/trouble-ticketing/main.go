package main

import (
	"flag"
	"fmt"
	"log"
	"os"

	"openc3.org/trouble-ticketing/config"
	"openc3.org/trouble-ticketing/http"
)

var GitVersion string

func main() {

	cfg := flag.String("c", "cfg.json", "configuration file")
	version := flag.Bool("v", false, "show version")
	gitVersion := flag.Bool("gv", false, "show git version")
	flag.Parse()

	if *version {
		fmt.Println(config.VERSION)
		os.Exit(0)
	}

	if *gitVersion {
		fmt.Println(GitVersion)
		os.Exit(0)
	}

	handleConfig(*cfg)

	http.Start()
}

func handleConfig(configFile string) {
	err := config.Parse(configFile)
	if err != nil {
		log.Fatalln(err)
	}
}
