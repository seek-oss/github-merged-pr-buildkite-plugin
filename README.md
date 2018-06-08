# GitHub Pull Request Plugin

A [Buildkite plugin](https://buildkite.com/docs/agent/v3/plugins) to checkout the GitHub post-merge check PR ref (`refs/pull/123/merge`) rather than building the branch `HEAD`.

This ensures tests run against the "merged" branch, helping catch bad merges.

## Example

```yml
steps:
  - plugins:
      zsims/github-pr#v0.0.1: ~
```

## Tests

To run the tests of this plugin, run
```sh
docker-compose run --rm tests
```

## License

MIT (see [LICENSE](LICENSE))