# GitHub release management module

# Create GitHub release with changelog
export def create-github-release [version: string] {
  print $"Creating GitHub release v($version)"

  # Get the previous tag for changelog generation  
  let all_tags = (^git tag --sort "-version:refname" | lines)
  let previous_tag = ($all_tags | where not ($it == $"v($version)") | first | default "")

  # Generate changelog using git log
  let changelog = if ($previous_tag | is-empty) {
    # If no previous tag, get all commits
    ^git log "--pretty=format:- %s" --reverse
  } else {
    # Get commits since previous tag
    ^git log $"($previous_tag)..HEAD" "--pretty=format:- %s" --reverse
  }

  # Create release with changelog as body
  ^gh release create $"v($version)" --title $"Release v($version)" --notes $changelog
  print $"Created GitHub release v($version) with changelog"
}

# Upload artifacts to existing GitHub release (accepts files via pipeline)
export def upload-release-artifacts [version: string] {
  let files = $in
  print $"Uploading ($files | length) artifacts to GitHub release v($version)"
  ^gh release upload $"v($version)" ...$files
  print $"Successfully uploaded artifacts to release v($version)"
}
