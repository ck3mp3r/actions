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

  # If major or minor version changed, use current version as-is
  if $current_major != $tag_major or $current_minor != $tag_minor {
    return $current_version
  }

  # If current version is same as latest tag, increment patch
  if $current_version == $latest_tag_version {
    let new_patch = $current_patch + 1
    return $"($current_major).($current_minor).($new_patch)"
  }

  # Otherwise use current version as-is
  $current_version
}
