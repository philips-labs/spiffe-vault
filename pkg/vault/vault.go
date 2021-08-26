package vault

import (
	"fmt"

	"github.com/hashicorp/vault/api"
)

type Client struct {
	*api.Client
	authPath string
}

func NewClient(authPath string) (*Client, error) {
	c, err := api.NewClient(api.DefaultConfig())
	if err != nil {
		return nil, err
	}

	return &Client{c, authPath}, nil
}

func (c *Client) Authenticate(jwt, role string) error {
	if jwt == "" {
		return fmt.Errorf("no jwt token provided to authenticate vault")
	}

	authData := map[string]interface{}{
		"jwt":  jwt,
		"role": role,
	}

	secret, err := c.Logical().Write(fmt.Sprintf("auth/%s/login", c.authPath), authData)
	if err != nil {
		return fmt.Errorf("failed to login using jwt: %w", err)
	}

	c.SetToken(secret.Auth.ClientToken)
	return nil
}

func (c *Client) GetSecret(path, key string) (map[string]interface{}, error) {
	secret, err := c.Logical().Read(fmt.Sprintf("%s/data/%s", path, key))
	if err != nil {
		return nil, fmt.Errorf("failed to retrieve secret with key '%s' from '%s': %w", key, path, err)
	}

	return secret.Data, nil
}
