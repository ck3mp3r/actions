# Cachix cache management module

# Helper to strip ANSI codes from strings
def strip-ansi []: string -> string {
  str replace -ra '\x1b\[[0-9;]*m' ''
}

# Helper to log messages to both stdout and GitHub Actions summary
def log [
  message: string
  --summary-only # Only write to summary file, not stdout
  --no-summary # Don't write to summary file
] {
  let is_github = ($env.GITHUB_STEP_SUMMARY? | is-not-empty)
  let summary_file = if $is_github { $env.GITHUB_STEP_SUMMARY } else { null }

  if not $summary_only {
    print $message
  }
  if $is_github and ($summary_file | is-not-empty) and (not $no_summary) {
    let clean_msg = ($message | strip-ansi)
    $"($clean_msg)\n" | save --append $summary_file
  }
}

# Get all recursive dependencies for a flake output
export def get-flake-dependencies [
  flake: string = ".#" # Flake output to analyze
] {
  print $"(ansi cyan_bold)📦 Getting all recursive dependencies for ($flake)...(ansi reset)"

  let all_paths = (do { ^nix path-info --recursive $flake } | complete | get stdout | lines)
  let total_count = ($all_paths | length)

  print $"(ansi green)✓ Found ($total_count) total paths(ansi reset)\n"

  $all_paths
}

# Check cache status for store paths
export def check-cache-status [
  cache: string = "ck3mp3r" # Cachix cache name
  --upstream: string = "https://cache.nixos.org" # Upstream cache to check
] {
  let paths = $in

  print $"(ansi cyan_bold)🔍 Checking which paths are in caches...(ansi reset)"
  print $"(ansi default_dimmed)   This may take a while...(ansi reset)\n"

  $paths | par-each {|path|
    let hash = ($path | path basename | split row '-' | first)

    let upstream_check = try {
      ^nix path-info --store $upstream $path
      | complete
    } catch {
      {exit_code: 1 stdout: "" stderr: ""}
    }

    # Check Cachix via HTTP (more reliable than nix path-info)
    let cachix_check = try {
      http head $"https://($cache).cachix.org/($hash).narinfo"
      {status: 200}
    } catch {
      {status: 404}
    }

    {
      path: $path
      in_upstream: ($upstream_check.exit_code == 0)
      in_cachix: ($cachix_check.status == 200)
    }
  }
}

# Get paths that are missing from both upstream and cachix caches
export def get-missing-paths [
  cache: string = "ck3mp3r" # Cachix cache name
  --upstream: string = "https://cache.nixos.org" # Upstream cache to check
] {
  let path_status = $in

  let paths_to_push = ($path_status | where in_upstream == false and in_cachix == false | get path)
  let already_in_cachix = ($path_status | where in_cachix == true | length)
  let upstream_count = ($path_status | where in_upstream == true | length)
  let push_count = ($paths_to_push | length)

  log --no-summary $"(ansi green)✓ Already in upstream: ($upstream_count) paths(ansi reset)"
  log --no-summary $"(ansi blue)✓ Already in ($cache).cachix.org: ($already_in_cachix) paths(ansi reset)"
  log --no-summary $"(ansi yellow)⚠ Not in any cache: ($push_count) paths(ansi reset)\n"

  # Write summary in markdown format if in GitHub Actions
  let is_github = ($env.GITHUB_STEP_SUMMARY? | is-not-empty)
  if $is_github and ($env.GITHUB_STEP_SUMMARY | is-not-empty) {
    let summary_file = $env.GITHUB_STEP_SUMMARY
    "## 📊 Cache Summary\n\n" | save --append $summary_file
    $"| Cache | Count |\n" | save --append $summary_file
    $"|-------|-------|\n" | save --append $summary_file
    $"| ✅ Already in upstream | ($upstream_count) |\n" | save --append $summary_file
    $"| ✅ Already in ($cache).cachix.org | ($already_in_cachix) |\n" | save --append $summary_file
    $"| ⚠️ Not in any cache | ($push_count) |\n\n" | save --append $summary_file
  }

  $paths_to_push
}

# Push store paths to Cachix cache
export def push-paths [
  cache: string = "ck3mp3r" # Cachix cache name
] {
  let paths = $in
  let push_count = ($paths | length)

  if $push_count == 0 {
    log $"(ansi green_bold)✅ Nothing to push - all store paths are already cached!(ansi reset)"
    return
  }

  # Show what will be pushed
  log --no-summary $"(ansi cyan_bold)📋 Paths to push:(ansi reset)"

  let is_github = ($env.GITHUB_STEP_SUMMARY? | is-not-empty)
  if $is_github and ($env.GITHUB_STEP_SUMMARY | is-not-empty) {
    let summary_file = $env.GITHUB_STEP_SUMMARY
    "## 📦 Paths to Push\n\n" | save --append $summary_file
    $paths | each {|path|
      let name = ($path | path basename)
      print $"   • ($name)"
      $"- `($name)`\n" | save --append $summary_file
    }
  } else {
    $paths | each {|path|
      let name = ($path | path basename)
      print $"   • ($name)"
    }
  }
  print ""

  # Push to cachix
  log $"(ansi cyan_bold)⬆️  Pushing ($push_count) paths to ($cache).cachix.org...(ansi reset)\n"

  let push_result = try {
    $paths
    | str join "\n"
    | ^cachix push $cache
    | complete
  } catch {
    log $"(ansi red_bold)❌ Failed to push to cachix(ansi reset)"
    error make {msg: "Failed to push to cachix"}
  }

  if $push_result.exit_code != 0 {
    log $"(ansi red_bold)❌ Cachix push failed:(ansi reset)"
    log $push_result.stderr
    error make {msg: $"Cachix push failed: ($push_result.stderr)"}
  }

  log $push_result.stdout
  log $"\n(ansi green_bold)✅ Successfully pushed ($push_count) paths to ($cache).cachix.org!(ansi reset)"
  log $"(ansi default_dimmed)   Users can now use: cachix use ($cache)(ansi reset)"

  if $is_github and ($env.GITHUB_STEP_SUMMARY | is-not-empty) {
    let summary_file = $env.GITHUB_STEP_SUMMARY
    $"\n## ✅ Success\n\nSuccessfully pushed **($push_count)** paths to `($cache).cachix.org`\n" | save --append $summary_file
  }
}

# Build flake and push missing paths to Cachix cache
export def publish-to-cachix [
  cache: string = "ck3mp3r" # Cachix cache name
  --flake: string = ".#" # Flake output to build
  --upstream: string = "https://cache.nixos.org" # Upstream cache to check against
] {

  print $"(ansi cyan_bold)🔨 Building flake output: ($flake)(ansi reset)"

  # Build the flake
  let build_result = try {
    ^nix build $flake --json --no-link
    | complete
  } catch {
    print $"(ansi red_bold)❌ Failed to build flake(ansi reset)"
    error make {msg: "Failed to build flake"}
  }

  if $build_result.exit_code != 0 {
    print $"(ansi red_bold)❌ Build failed:(ansi reset)"
    print $build_result.stderr
    error make {msg: $"Build failed: ($build_result.stderr)"}
  }

  print $"(ansi green)✓ Build successful(ansi reset)\n"

  # Get dependencies, check cache status, filter missing, and push
  get-flake-dependencies $flake
  | check-cache-status $cache --upstream $upstream
  | get-missing-paths $cache --upstream $upstream
  | push-paths $cache
}
