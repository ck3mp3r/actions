export def 'branch exists' [] {
  let branch = $in

  (git branch --remote | lines | any {|line| $line | str contains $branch })
}

export def 'branch create' [] {
  let branch = $in

  git checkout -b $branch
  $branch
}

export def 'branch rebase' [] {
  let target_branch = $in

  git fetch origin $target_branch

  let changes = (git log $"HEAD..origin/($target_branch)" --oneline | str trim)

  if ($changes != "") {
    git rebase origin/$target_branch
    true
  } else {
    false
  }
}

export def 'branch checks' [] {
  let branch = $in

  let owner_repo = (git remote get-url origin | str replace "^.*github.com[/:]" "" | str replace ".git$" "")
  let owner = ($owner_repo | split row "/" | first)
  let repo = ($owner_repo | split row "/" | last)

  let checks = (gh api repos/($owner)/($repo)/commits/($branch)/check-runs --jq '.check_runs[] | select(.conclusion == "success")' | from json)

  if ($checks != null) {
    true
  } else {
    false
  }
}

export def 'branch push' [ --force (-f)] {
  let branch = $in

  if ($force) {
    git push origin $branch --force
  } else {
    git push origin $branch
  }
}

export def 'branch merge' [ --squash (-s)] {
  let input = $in
  let branch = ($input | get branch)
  let target_branch = ($input | get target_branch)

  git checkout $target_branch

  if ($squash) {
    git merge --squash $branch

    let commit_messages = (git log --format="%s" origin/$target_branch..$branch | str join "\n")
    git commit -m $commit_messages
  } else {
    git merge $branch
  }
}

export def 'branch commit-all' [ --message (-m): string] {
  git commit -am $"($message)"
}
