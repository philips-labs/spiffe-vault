package cli

import (
	"context"
	"flag"
	"fmt"
	"os"
	"time"

	"github.com/peterbourgon/ff/v3/ffcli"

	"github.com/philips-labs/spiffe-vault/pkg/spiffe"
	"github.com/philips-labs/spiffe-vault/pkg/vault"
)

const (
	defaultAudience   = "CI"
	defaultAuthPath   = "jwt"
	defaultSocketPath = "unix:///spiffe-workload-api/spire-agent.sock"
)

// Auth creates an instance of *ffcli.Command to authenticate with vault using Spiffe
func Auth() *ffcli.Command {
	var (
		flagset    = flag.NewFlagSet("spiffe-vault version", flag.ExitOnError)
		socketPath = flagset.String("socketPath", defaultSocketPath, fmt.Sprintf("the unix socket path to the spire-agent (default: %s).", defaultSocketPath))
		authPath   = flagset.String("authPath", defaultAuthPath, fmt.Sprintf("the authentication path in Vault (default: %s)", defaultAuthPath))
		role       = flagset.String("role", "", "the role to authenticate with against Vault")
		audience   = flagset.String("audience", defaultAudience, fmt.Sprintf("the bound audience to verify in the claims (default: %s)", defaultAudience))
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

			if *socketPath == "" {
				return fmt.Errorf("socketPath flag required")
			}

			ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
			defer cancel()

			jwt, err := spiffe.FetchJWT(ctx, *socketPath, *audience)
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
			fmt.Fprintln(os.Stderr, "# Export following environment variable to authenticate to Hashicorp Vault")
			fmt.Fprintf(os.Stdout, "export VAULT_TOKEN=%s\n", c.Token())

			return nil
		},
	}
}
