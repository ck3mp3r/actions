export def 'branch exists' [] {
  let branch = $in

  let result = (git branch --list $branch | str trim)

  if ($result != "") {
    true
  } else {
    false
  }
}

export def 'branch create' [] {
  let branch = $in

  git checkout -b $branch
}

export def 'branch rebase' [] {
  let target_branch = $in

  git fetch origin $target_branch

  let changes = (git log HEAD..origin/$target_branch --oneline | str trim)

  if ($changes != "") {
    git rebase origin/$target_branch
    true
  } else {
    false
  }
}
