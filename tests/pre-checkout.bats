#!/usr/bin/env bats

load '/usr/local/lib/bats/load.bash'

pre_checkout_hook="$PWD/hooks/pre-checkout"

@test "Updates BUILDKITE_REFSPEC if PR number set" {
  export BUILDKITE_PULL_REQUEST=123

  run "$pre_checkout_hook"

  assert_success
  assert_output --partial "Setting BUILDKITE_REFSPEC to refs/pull/123/merge"
}

@test "Triggers a build if PR number set and mode is trigger" {
  export BUILDKITE_PULL_REQUEST=123
  export BUILDKITE_PLUGIN_GITHUB_MERGED_PR_MODE="trigger"
  export BUILDKITE_PIPELINE_SLUG="my-pipeline"

  stub buildkite-agent \
    "pipeline upload : echo UPLOADED_PIPELINE"

  run "$pre_checkout_hook"

  assert_success
  assert_output --partial "Triggering merged build of my-pipeline for PR 123"
  assert_output --partial "UPLOADED_PIPELINE"
  unstub buildkite-agent
}

@test "Does nothing if no PR number set" {
  export BUILDKITE_PULL_REQUEST=""

  run "$pre_checkout_hook"

  assert_success
  assert_output --partial "No BUILDKITE_PULL_REQUEST variable set"
}

@test "Does nothing if PR is false" {
  export BUILDKITE_PULL_REQUEST="false"

  run "$pre_checkout_hook"

  assert_success
  assert_output --partial "No BUILDKITE_PULL_REQUEST variable set"
}