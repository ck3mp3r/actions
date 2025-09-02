use ./git_utils.nu *
use ./flake_utils.nu *
use ./utils.nu *

def update-all-flakes [] {
  let flakes = (glob **/flake.nix)

  if ($flakes | is-empty) {
    error make {msg: "No flake.nix files found in repository"}
  }

  let updates = $flakes | each {|flake|
    let flake_dir = ($flake | path dirname)

    try {
      $flake_dir | flake update
      $flake
    } catch {
      error make {msg: $"Failed to update flake: ($flake)"}
    }
  }

  $updates
}

def create-or-update-branch [
  head_branch: string
  --force-update
] {
  let updates = (update-all-flakes)

  if ($updates | is-not-empty) {
    branch commit-all -m "chore: update flake.lock(s)"

    if $force_update {
      $head_branch | branch push --force
      print $"Branch ($head_branch) has been updated and force-pushed"
    } else {
      $head_branch | branch push
      print $"Successfully created branch ($head_branch) with flake updates"
    }
    true
  } else {
    error make {msg: "No flakes were successfully updated"}
  }
}

export def update-flake-locks [
  head_branch: string
  target_branch: string
  checks_required: list = []
] {
  try {
    if ($head_branch | branch exists) {
      print $"Branch ($head_branch) already exists, checking if update is needed..."

      # Fetch latest branches
      git fetch origin $target_branch
      git fetch origin $head_branch

      # Check if main has new commits since the branch was created
      let main_has_updates = (git log $"origin/($head_branch)..origin/($target_branch)" --oneline | str trim | is-not-empty)

      if $main_has_updates {
        print $"Main branch has new commits, updating ($head_branch)..."

        # Reset branch to latest main
        git checkout -B $head_branch $"origin/($target_branch)"

        # Update and push
        create-or-update-branch $head_branch --force-update
        print "The workflow will need to run again to perform the merge"
        return
      }

      # Checkout the branch to check its status
      git checkout $head_branch

      # Check if required checks have passed
      let checks = (git rev-parse HEAD | commit checks --status "success" --checks-required $checks_required)

      if (($checks | is-not-empty) or ($checks_required | is-empty)) {
        print $"Merging ($head_branch) into ($target_branch)..."
        $head_branch | branch merge --squash --into $target_branch
        $target_branch | branch push
        $head_branch | branch delete
        print $"Successfully merged and deleted ($head_branch)"
      } else {
        print "Required checks have not passed yet"
      }
    } else {
      print $"Creating new branch ($head_branch) for flake updates..."

      $head_branch | branch create
      create-or-update-branch $head_branch
    }
  } catch {|err|
    print -e $"Error: ($err.msg)"
    exit 1
  }
}
