package funcs

import (
	"fmt"
	"os"
)

func PrintlnLog(msg string) {
	_, present := os.LookupEnv("C3DEBUG1")
	if present {
		fmt.Fprintln(os.Stdout, fmt.Sprintf("DEBUG1. trouble-ticketing. msg: %v", msg))
	}
}
