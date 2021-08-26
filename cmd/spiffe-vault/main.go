package main

import (
	"context"
	"flag"
	"log"
	"os"

	"github.com/peterbourgon/ff/v3/ffcli"
	"github.com/philips-labs/spiffe-vault/cmd/spiffe-vault/cli"
)

func main() {
	rootFlagSet := flag.NewFlagSet("spiffe-vault", flag.ExitOnError)

	app := &ffcli.Command{
		Name:    "spiffe-vault [flags] <subcommand>",
		FlagSet: rootFlagSet,
		Subcommands: []*ffcli.Command{
			cli.Auth(),
			cli.Version(),
		},
	}

	if err := app.Parse(os.Args[1:]); err != nil {
		log.Fatal(err)
	}

	if err := app.Run(context.Background()); err != nil {
		log.Fatal(err)
	}
}
