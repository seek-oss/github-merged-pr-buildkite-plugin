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
    "fetch -v origin dev : echo FETCHED" \
    "checkout FETCH_HEAD : echo CHECKED_OUT" \
    "merge --no-edit deadbeef : echo MERGED"

  run "$post_checkout_hook"

  assert_success
  assert_output --partial "FETCHED"
  assert_output --partial "CHECKED_OUT"
  assert_output --partial "MERGED"
  unstub git
}

@test "Aborts merge if it fails" {
  export BUILDKITE_PULL_REQUEST=123
  export BUILDKITE_PLUGIN_GITHUB_MERGED_PR_MODE="checkout"
  export BUILDKITE_PULL_REQUEST_BASE_BRANCH="dev"
  export BUILDKITE_COMMIT="deadbeef"

  stub git \
    "fetch -v origin dev : echo FETCHED" \
    "checkout FETCH_HEAD : echo CHECKED_OUT" \
    "merge --no-edit deadbeef : echo MERGED && false" \
    "merge --abort : echo ABORTED_MERGE"

  run "$post_checkout_hook"

  assert_failure
  assert_output --partial "FETCHED"
  assert_output --partial "CHECKED_OUT"
  assert_output --partial "MERGED"
  assert_output --partial "ABORTED_MERGE"
  unstub git
}

@test "Forces merges when GITHUB_MERGED_PR_FORCE_BRANCH is set" {
  export BUILDKITE_COMMIT="deadbeef"
  export GITHUB_MERGED_PR_FORCE_BRANCH="master"

  stub git \
    "fetch -v origin master : echo FETCHED" \
    "checkout FETCH_HEAD : echo CHECKED_OUT" \
    "merge --no-edit deadbeef : echo MERGED"

  run "$post_checkout_hook"

  assert_success
  assert_output --partial "FETCHED"
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

@test "Triggers PR builds on default branch" {
  export BUILDKITE_PIPELINE_SLUG="my-pipeline"
  export BUILDKITE_PLUGIN_GITHUB_MERGED_PR_MODE="trigger"
  export BUILDKITE_PLUGIN_GITHUB_MERGED_PR_UPDATE_PRS="true"
  export BUILDKITE_PIPELINE_DEFAULT_BRANCH="dev"
  export BUILDKITE_BRANCH="dev"

  stub buildkite-agent \
    "pipeline upload : echo UPLOADED_PIPELINE"

  stub git \
    "fetch origin : echo FETCHED" \
    "ls-remote origin 'refs/pull/*/head' : echo deadbeef refs/pull/123/head" \
    "merge-base --is-ancestor deadbeef dev : echo UNMERGED && false" \
    "branch -a -q --contains deadbeef : echo remotes/origin/MY_PR_BRANCH"

  stub grep \
    "remotes/origin : echo remotes/origin/MY_PR_BRANCH"

  stub sed \
    "-e 's,^[[:space:]]*remotes/origin/,,g' : echo MY_PR_BRANCH"

  run "$post_checkout_hook"

  assert_success
  assert_output --partial "Updating PRs"
  assert_output --partial "FETCHED"
  assert_output --partial "Triggering new build of my-pipeline for PR 123"
  assert_output --partial "UPLOADED_PIPELINE"
  unstub buildkite-agent
  unstub git
  unstub grep
  unstub sed
}

@test "Doesn't rebuild merged PR branches" {
  export BUILDKITE_PIPELINE_SLUG="my-pipeline"
  export BUILDKITE_PLUGIN_GITHUB_MERGED_PR_MODE="trigger"
  export BUILDKITE_PLUGIN_GITHUB_MERGED_PR_UPDATE_PRS="true"
  export BUILDKITE_PIPELINE_DEFAULT_BRANCH="dev"
  export BUILDKITE_BRANCH="dev"

  stub git \
    "fetch origin : echo FETCHED" \
    "ls-remote origin 'refs/pull/*/head' : echo deadbeef refs/pull/123/head" \
    "merge-base --is-ancestor deadbeef dev : echo MERGED"

  run "$post_checkout_hook"

  assert_success
  assert_output --partial "FETCHED"
  assert_output --partial "MERGED"
  unstub git
}

@test "Skips old unmerged PR branch" {
  export BUILDKITE_PIPELINE_SLUG="my-pipeline"
  export BUILDKITE_PLUGIN_GITHUB_MERGED_PR_MODE="trigger"
  export BUILDKITE_PLUGIN_GITHUB_MERGED_PR_UPDATE_PRS="true"
  export BUILDKITE_PLUGIN_GITHUB_MERGED_PR_OLDEST_PR="150"
  export BUILDKITE_PIPELINE_DEFAULT_BRANCH="dev"
  export BUILDKITE_BRANCH="dev"

  stub git \
    "fetch origin : echo FETCHED" \
    "ls-remote origin 'refs/pull/*/head' : echo deadbeef refs/pull/123/head" \
    "merge-base --is-ancestor deadbeef dev : echo UNMERGED && false" \
    "branch -a -q --contains deadbeef : echo remotes/origin/MY_PR_BRANCH"

  stub grep \
    "remotes/origin : echo remotes/origin/MY_PR_BRANCH"

  stub sed \
    "-e 's,^[[:space:]]*remotes/origin/,,g' : echo MY_PR_BRANCH"

  run "$post_checkout_hook"

  assert_success
  assert_output --partial "FETCHED"
  assert_output --partial "UNMERGED"
  unstub git
  unstub grep
  unstub sed
}

@test "Does nothing on default branch when disabled" {
  export BUILDKITE_PIPELINE_SLUG="my-pipeline"
  export BUILDKITE_PLUGIN_GITHUB_MERGED_PR_MODE="trigger"
  unset BUILDKITE_PLUGIN_GITHUB_MERGED_PR_UPDATE_PRS
  export BUILDKITE_PIPELINE_DEFAULT_BRANCH="dev"
  export BUILDKITE_BRANCH="dev"

  run "$post_checkout_hook"

  assert_success
  assert_output --partial "Not configured to update PRs"
}
