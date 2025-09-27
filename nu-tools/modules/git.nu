# Git workflow management module

# Get latest git tag version (without 'v' prefix)
export def get-latest-tag [] {
  let result = (^git tag --sort=-version:refname | complete)
  if $result.exit_code == 0 {
    $result.stdout | lines | first | str replace --regex "^v" ""
  } else {
    ""
  }
}

# Create and checkout release branch, pass version through pipeline
export def create-release-branch [] {
  let version = $in
  let branch_name = $"release/($version)"

  # Check if branch already exists locally
  let local_branch_exists = (^git branch --list $branch_name | complete | get stdout | str trim | is-not-empty)

  if $local_branch_exists {
    print $"Release branch ($branch_name) already exists locally, checking out"
    ^git checkout $branch_name
  } else {
    # Check if branch exists on remote
    let remote_branch_exists = (^git ls-remote --heads origin $branch_name | complete | get stdout | str trim | is-not-empty)

    if $remote_branch_exists {
      print $"Release branch ($branch_name) exists on remote, checking out and tracking"
      ^git checkout -b $branch_name $"origin/($branch_name)"
    } else {
      print $"Creating new release branch: ($branch_name)"
      ^git checkout -b $branch_name
      ^git push origin $branch_name
    }
  }

  $version
}

# Commit files with message, accept list of files
export def commit-files [message: string] {
  let files = $in
  print $"Committing ($files | str join ', ')"
  ^git add ...$files

  # Check if there are changes to commit
  let has_changes = (^git diff --cached --quiet | complete | get exit_code) != 0

  if $has_changes {
    ^git commit -m $message
    ^git push --force-with-lease origin HEAD
    print "Committed and pushed changes"
  } else {
    print "No changes to commit"
  }
}

# Setup git user for GitHub Actions
export def setup-git-user [] {
  print "Setting up git user for GitHub Actions"
  ^git config --global user.name "github-actions[bot]"
  ^git config --global user.email "github-actions[bot]@users.noreply.github.com"
}

# Merge release branch back to main and cleanup
export def merge-and-cleanup [version: string] {
  let branch_name = $"release/($version)"

  print "Merging release branch to main"
  ^git checkout main
  ^git fetch origin $branch_name
  ^git merge --squash $"origin/($branch_name)"
  ^git commit -m $"Release ($version)"
  ^git push origin main

  print "Cleaning up release branch"
  ^git push origin --delete $branch_name

  print $"Release ($version) completed successfully!"
}