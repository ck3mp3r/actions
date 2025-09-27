# Cargo project management module

# Update Cargo.toml version, return list of files
export def update-cargo-version [version: string] {
  print $"Updating Cargo.toml version to ($version)"
  let cargo_toml = (open Cargo.toml)
  let updated_cargo = ($cargo_toml | upsert package.version $version)
  $updated_cargo | to toml | save --force Cargo.toml
  ^cargo check
  print "Updated Cargo.toml and Cargo.lock"
  ["Cargo.toml" "Cargo.lock"]
}