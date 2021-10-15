package cli_test

import (
	"context"
	"fmt"
	"runtime"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"

	"github.com/philips-labs/spiffe-vault/cmd/spiffe-vault/cli"
)

func TestVersionCliText(t *testing.T) {
	assert := assert.New(t)

	sb := strings.Builder{}
	cli := cli.Version(&sb)

	expected := fmt.Sprintf(`GitVersion:    devel
GitCommit:     unknown
GitTreeState:  unknown
BuildDate:     unknown
GoVersion:     %s
Compiler:      %s
Platform:      %s/%s

`, runtime.Version(), runtime.Compiler, runtime.GOOS, runtime.GOARCH)

	err := cli.ParseAndRun(context.Background(), nil)
	assert.NoError(err)
	assert.Equal(expected, sb.String())
}

func TestVersionCliJson(t *testing.T) {
	assert := assert.New(t)

	sb := strings.Builder{}
	cli := cli.Version(&sb)

	expected := fmt.Sprintf(`{
  "git_version": "devel",
  "git_commit": "unknown",
  "git_tree_state": "unknown",
  "build_date": "unknown",
  "go_version": "%s",
  "compiler": "%s",
  "platform": "%s/%s"
}
`, runtime.Version(), runtime.Compiler, runtime.GOOS, runtime.GOARCH)

	err := cli.ParseAndRun(context.Background(), []string{"-json"})
	assert.NoError(err)
	assert.Equal(expected, sb.String())
}
