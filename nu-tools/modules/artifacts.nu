# Artifact and platform data management module

# Generate per-arch data files
export def generate-platform-data [
  version: string
  artifacts_path: string
  project_name: string
  archive_ext: string = ".tgz"
  hash_suffix: string = "-nix.sha256"
] {
  print $"Generating platform data files for version ($version)"

  # Create data directory
  mkdir data

  # Process each archive file in artifacts (download-artifact creates subdirectories)  
  let archive_files = (glob $"($artifacts_path)/**/*($archive_ext)")

  for $file in $archive_files {
    let filename = ($file | path basename)
    let platform = ($filename | str replace $"($project_name)-($version)-" "" | str replace $archive_ext "")

    # Find corresponding hash file
    let hash_file = ($file | str replace $archive_ext $hash_suffix)
    let hash = (open $hash_file | str trim)

    let url = $"https://github.com/($env.GITHUB_REPOSITORY)/releases/download/v($version)/($filename)"

    # Create platform JSON file
    let platform_data = {
      url: $url
      hash: $hash
    }

    $platform_data | to json | save --force $"data/($platform).json"
    print $"Generated data/($platform).json"
  }
}

# Generate platform data and return list of generated files
export def generate-platform-data-for [version: string project_name: string artifacts_path: string = "./artifacts"] {
  let branch_name = $"release/($version)"

  print $"Checking out release branch: ($branch_name)"
  ^git checkout $branch_name

  generate-platform-data $version $artifacts_path $project_name

  # Return the actual files that were created
  glob "data/*.json"
}