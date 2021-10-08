package spiffe

import (
	"context"
	"fmt"

	"github.com/spiffe/go-spiffe/v2/svid/jwtsvid"
	"github.com/spiffe/go-spiffe/v2/workloadapi"
)

const (
	socketPath = "unix:///var/run/spire/sockets/agent.sock"
)

// FetchJWT retrieves a JWT SVID upon successfull attestation
func FetchJWT(ctx context.Context, audience string) (string, error) {
	clientOptions := workloadapi.WithClientOptions(workloadapi.WithAddr(socketPath))

	jwtSource, err := workloadapi.NewJWTSource(ctx, clientOptions)
	if err != nil {
		return "", fmt.Errorf("unable to create jwtsource: %w", err)
	}
	defer jwtSource.Close()

	svid, err := jwtSource.FetchJWTSVID(ctx, jwtsvid.Params{
		Audience: audience,
	})
	if err != nil {
		return "", fmt.Errorf("unable to fetch svid: %w", err)
	}

	return svid.Marshal(), nil
}
