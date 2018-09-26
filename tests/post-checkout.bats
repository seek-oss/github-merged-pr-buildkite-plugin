#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'

post_checkout_hook="$PWD/hooks/post-checkout"

@test "Triggers a build if PR number set and mode is trigger" {
  export BUILDKITE_PULL_REQUEST=123
  export BUILDKITE_PLUGIN_GITHUB_MERGED_PR_MODE="trigger"
  export BUILDKITE_PIPELINE_SLUG="my-pipeline"
  export BUILDKITE_BRANCH="dev"

  stub buildkite-agent \
    "pipeline upload : echo UPLOADED_PIPELINE"

  run "$post_checkout_hook"

  assert_success
  assert_output --partial "Triggering merged build of my-pipeline for PR 123"
  assert_output --partial "UPLOADED_PIPELINE"
  unstub buildkite-agent
}

@test "Merges with target PR branch" {
  export BUILDKITE_PULL_REQUEST=123
  export BUILDKITE_PLUGIN_GITHUB_MERGED_PR_MODE="checkout"
  export BUILDKITE_PULL_REQUEST_BASE_BRANCH="dev"
  export BUILDKITE_COMMIT="deadbeef"

  stub git \
    "checkout origin/dev : echo CHECKED_OUT" \
    "merge deadbeef : echo MERGED"

  run "$post_checkout_hook"

  assert_success
  assert_output --partial "CHECKED_OUT"
  assert_output --partial "MERGED"
  unstub git
}

@test "Forces merges when GITHUB_MERGED_PR_FORCE_BRANCH is set" {
  export BUILDKITE_COMMIT="deadbeef"
  export GITHUB_MERGED_PR_FORCE_BRANCH="master"

  stub git \
    "checkout origin/master : echo CHECKED_OUT" \
    "merge deadbeef : echo MERGED"

  run "$post_checkout_hook"

  assert_success
  assert_output --partial "CHECKED_OUT"
  assert_output --partial "MERGED"
  unstub git
}

@test "Does nothing if no PR number set" {
  export BUILDKITE_PULL_REQUEST=""

  run "$post_checkout_hook"

  assert_success
  assert_output --partial "Not a pull request"
}

@test "Does nothing if PR is false" {
  export BUILDKITE_PULL_REQUEST="false"

  run "$post_checkout_hook"

  assert_success
  assert_output --partial "Not a pull request"
}
