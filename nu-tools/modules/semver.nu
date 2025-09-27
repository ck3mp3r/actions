# Semantic version management module

# Calculate semantic version based on latest tag and current version
export def semver-calculate [latest_tag_version: string current_version: string] {
  # If no latest tag (empty string), use current version as-is
  if ($latest_tag_version | is-empty) {
    return $current_version
  }

  let current_parts = ($current_version | split row ".")
  let tag_parts = ($latest_tag_version | split row ".")

  let current_major = ($current_parts.0 | into int)
  let current_minor = ($current_parts.1 | into int) 
  let current_patch = ($current_parts.2 | into int)

  let tag_major = ($tag_parts.0 | into int)
  let tag_minor = ($tag_parts.1 | into int)
  let tag_patch = ($tag_parts.2 | into int)

  # If major or minor version changed in Cargo.toml, use current version
  if $current_major != $tag_major or $current_minor != $tag_minor {
    return $current_version
  }

  # If patch version was manually bumped in Cargo.toml, use current version 
  if $current_patch > $tag_patch {
    return $current_version
  }

  # If versions are equal, increment patch from tag
  let new_patch = $tag_patch + 1
  $"($tag_major).($tag_minor).($new_patch)"
}