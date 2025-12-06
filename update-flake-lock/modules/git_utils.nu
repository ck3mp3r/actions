export def 'branch exists' [] {
  let branch = $in

  (git branch --remote | lines | any {|line| $line | str contains $branch })
}

export def 'branch switch' [] {
  git switch $in --
  $in
}

export def 'branch create' [] {
  let branch = $in

  git checkout -b $branch --
  $branch
}

export def 'branch rebase' [] {
  let target_branch = $in

  git fetch origin $target_branch

  let changes = (git log $"HEAD..origin/($target_branch)" --oneline | str trim)

  if ($changes != "") {
    git rebase origin/($target_branch)
    true
  } else {
    false
  }
}

export def 'branch push' [--force (-f)] {
  let branch = $in
  $env.GIT_TERMINAL_PROMPT = 0

  mut cmd = [git push origin $branch]
  if $force {
    $cmd = $cmd ++ [--force]
  }
  run-external ...($cmd) | ignore
  $branch
}

export def 'branch delete' [] {
  let branch = $in
  git push origin --delete $branch
  $branch
}

export def 'branch merge' [--into (-i): string = "main" --squash (-s)] {
  let head_branch = $in

  git switch $into --

  if ($squash) {
    git merge --squash $head_branch
    git commit -m (git log --format="%s" $"($into)..origin/($head_branch)" | str join "\n")
  } else {
    git merge $head_branch
  }
}

export def 'branch commit-all' [--message (-m): string] {
  git commit -am $"($message)"
}

export def 'commit checks' [--status: string = "success" --checks-required: list = []] {
  let commit = $in

  let checks = if ($checks_required | is-not-empty) {
    $checks_required | each {|workflow|
      gh run list --workflow $workflow --status $status --commit $commit --json status,conclusion | from json
    } | flatten
  } else {
    []
  }

  $checks
}
