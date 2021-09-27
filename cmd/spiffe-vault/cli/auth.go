package cli

import (
	"context"
	"flag"
	"fmt"
	"time"

	"github.com/peterbourgon/ff/v3/ffcli"

	"github.com/philips-labs/spiffe-vault/pkg/spiffe"
	"github.com/philips-labs/spiffe-vault/pkg/vault"
)

func Auth() *ffcli.Command {
	var (
		flagset  = flag.NewFlagSet("spiffe-vault version", flag.ExitOnError)
		authPath = flagset.String("authPath", "jwt", "the authentication path in Vault (default: jwt)")
		role     = flagset.String("role", "", "the role to authenticate with against Vault")
		audience = flagset.String("audience", "CI", "the bound audience to verify in the claims")
	)
	return &ffcli.Command{
		Name:    "auth",
		FlagSet: flagset,
		Exec: func(ctx context.Context, args []string) error {
			if *role == "" {
				return fmt.Errorf("role flag required")
			}

			if *authPath == "" {
				return fmt.Errorf("authPath flag required")
			}

			ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
			defer cancel()

			jwt, err := spiffe.FetchJWT(ctx, *audience)
			if err != nil {
				return err
			}

			c, err := vault.NewClient(*authPath)
			if err != nil {
				return err
			}

			err = c.Authenticate(jwt, *role)
			if err != nil {
				return err
			}

			fmt.Println("# Export following environment variable to authenticate to Hashicorp Vault")
			fmt.Printf("export VAULT_TOKEN=%s\n", c.Token())

			return nil
		},
	}
}
