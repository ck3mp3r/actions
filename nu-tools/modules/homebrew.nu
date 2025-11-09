# Function to update Homebrew formula for multiple architectures
export def update-homebrew-formula [
  version: string
  binary_name: string
  architectures: list<record<name: string, hash: string>>
] {
  let formula = $in
  | str replace -r 'version "[^"]*"' $'version "($version)"'
  | str replace -r 'v[0-9]+\.[0-9]+\.[0-9]+' $'v($version)' --all

  $architectures | reduce --fold $formula {|arch acc|
    $acc
    | str replace -r $'($binary_name)-[0-9]+\.[0-9]+\.[0-9]+-($arch.name)\.tgz' $'($binary_name)-($version)-($arch.name).tgz'
    | str replace -r $'($arch.name)\.tgz"\s+sha256 "[a-f0-9]{64}"' $"($arch.name).tgz\"\n      sha256 \"($arch.hash)\""
  }
}
