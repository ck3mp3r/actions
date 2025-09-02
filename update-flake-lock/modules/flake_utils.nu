export def 'flake update' [] {
  let flake = $in

  try {
    nix flake update --flake $flake
    $flake
  } catch {
    error make {msg: $"Failed to update flake: ($flake)"}
  }
}
