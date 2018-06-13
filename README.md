# GitHub Pull Request Plugin

A [Buildkite plugin](https://buildkite.com/docs/agent/v3/plugins) to help build the GitHub post-merge check PR ref (`refs/pull/123/merge`).

This plugin helps you run CI run against the "merged" branch, helping catch bad merges.

The plugin has two modes:
  - `mode: trigger` to async trigger another build (of the current pipeline); and
  - `mode: checkout` to checkout the PR merged ref (`refs/pull/123/merge`) rather than the head (`refs/pull/123/head`)

## Example

```yml
steps:
  - plugins:
      seek-oss/github-merged-pr#v0.0.5:
        mode: checkout
```

```yml
steps:
  - plugins:
      seek-oss/github-merged-pr#v0.0.5:
        mode: trigger
```

Ensure `Skip pull request builds for existing commits` is set to `false` in your Pipeline settings, as BuildKite will build the branch and skip the PR build.

## Tests

To run the tests of this plugin, run
```sh
docker-compose run --rm tests
```

## License

MIT (see [LICENSE](LICENSE))
