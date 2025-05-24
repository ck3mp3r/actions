export def 'flake update' [] {
  let flake = $in
  cd ($flake | path dirname)
  nix flake update
  cd -

  $flake
}
