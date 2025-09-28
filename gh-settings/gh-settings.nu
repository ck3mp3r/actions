# GitHub repository settings management module using gh CLI

# Default configuration for repository settings
export def default-github-settings [] {
  {
    repository: {
      allow_merge_commit: false
      allow_rebase_merge: true
      allow_squash_merge: true
      allow_auto_merge: true
      delete_branch_on_merge: true
      allow_update_branch: true
    }
    branch_protection: {
      branch: "main"
      required_pull_request_reviews: {
        required_approving_review_count: 1
        dismiss_stale_reviews: true
        require_code_owner_reviews: false
        require_last_push_approval: false
        bypass_pull_request_allowances: {
          apps: ["renovate[bot]" "dependabot[bot]" "github-actions[bot]"]
          users: []
          teams: []
        }
      }
      required_linear_history: true
      required_status_checks: {
        strict: true
        contexts: []
      }
      enforce_admins: true
      required_conversation_resolution: true
      allow_force_pushes: false
      allow_deletions: false
      block_creations: false
      lock_branch: false
      allow_fork_syncing: false
      restrictions: null
    }
  }
}

# Generate default settings file
export def generate-default-settings [output_file: string] {
  let config = default-github-settings
  $config | to yaml | save $output_file
  print $"Default configuration saved to ($output_file)"
}

# Apply GitHub settings to repository
export def apply-github-settings [
  owner: string
  repo: string
  config: record
  dry_run: bool
] {
  print $"Applying GitHub settings to ($owner)/($repo)"
  if $dry_run { print "DRY RUN MODE - No changes will be made" }

  # Apply repository settings
  if "repository" in $config {
    apply-repository-settings $owner $repo $config.repository $dry_run
  }

  # Apply branch protection
  if "branch_protection" in $config {
    apply-branch-protection $owner $repo $config.branch_protection $dry_run
  }

  if not $dry_run {
    print "✅ GitHub settings applied successfully"
  } else {
    print "✅ Dry run completed - no changes made"
  }
}

# Apply repository-level settings using gh CLI
def apply-repository-settings [
  owner: string
  repo: string
  settings: record
  dry_run: bool
] {
  print "📋 Applying repository settings..."

  if $dry_run {
    print $"Would update repository settings:"
    print $settings
    return
  }

  let repo_full = $"($owner)/($repo)"

  try {
    # Convert settings to JSON and use gh api to update repository
    let settings_json = ($settings | to json)
    let result = (^gh api repos/($repo_full) --method PATCH --input - <<< $settings_json | complete)

    if $result.exit_code != 0 {
      print $"❌ Failed to update repository settings: ($result.stderr)"
      exit 1
    }

    let response = ($result.stdout | from json)
    print $"✅ Repository settings updated: ($response.name)"
  } catch {|err|
    print $"❌ Failed to update repository settings: ($err.msg)"
    exit 1
  }
}

# Apply branch protection settings using gh CLI
def apply-branch-protection [
  owner: string
  repo: string
  protection: record
  dry_run: bool
] {
  let branch = $protection.branch
  print $"🔒 Applying branch protection to branch: ($branch)"

  # Remove the branch field from protection settings for API call
  let protection_settings = ($protection | reject branch)

  if $dry_run {
    print $"Would update branch protection for ($branch):"
    print $protection_settings
    return
  }

  let repo_full = $"($owner)/($repo)"

  try {
    # Convert settings to JSON and use gh api to update branch protection
    let protection_json = ($protection_settings | to json)
    let result = (^gh api repos/($repo_full)/branches/($branch)/protection --method PUT --input - <<< $protection_json | complete)

    if $result.exit_code != 0 {
      print $"❌ Failed to update branch protection: ($result.stderr)"
      exit 1
    }

    print $"✅ Branch protection updated for ($branch)"
  } catch {|err|
    print $"❌ Failed to update branch protection: ($err.msg)"
    exit 1
  }
}

# Get current repository settings using gh CLI
export def get-current-settings [
  owner: string
  repo: string
] {
  let repo_full = $"($owner)/($repo)"
  print $"Getting current settings for ($owner)/($repo)"

  # Get repository settings using gh api
  let repo_result = (^gh api repos/($repo_full) | complete)
  if $repo_result.exit_code != 0 {
    print $"❌ Failed to get repository settings: ($repo_result.stderr)"
    exit 1
  }
  let repo_settings = ($repo_result.stdout | from json)

  # Get branch protection settings for main branch using gh api
  let protection_result = (^gh api repos/($repo_full)/branches/main/protection | complete)
  let protection_settings = if $protection_result.exit_code == 0 {
    $protection_result.stdout | from json
  } else {
    print "⚠️  No branch protection found for main branch"
    {}
  }

  {
    repository: {
      allow_merge_commit: $repo_settings.allow_merge_commit
      allow_rebase_merge: $repo_settings.allow_rebase_merge
      allow_squash_merge: $repo_settings.allow_squash_merge
      allow_auto_merge: $repo_settings.allow_auto_merge
      delete_branch_on_merge: $repo_settings.delete_branch_on_merge
      allow_update_branch: ($repo_settings.allow_update_branch? | default false)
    }
    branch_protection: $protection_settings
  }
}

# Compare current settings with desired configuration
export def compare-github-settings [
  owner: string
  repo: string
  desired_config: record
] {
  let current = get-current-settings $owner $repo

  print "=== 📊 Repository Settings Comparison ==="

  if "repository" in $desired_config {
    let desired_repo = $desired_config.repository
    let current_repo = $current.repository

    for key in ($desired_repo | columns) {
      let desired_val = $desired_repo | get $key
      let current_val = $current_repo | get $key

      if $desired_val != $current_val {
        print $"❌ ($key): current=($current_val), desired=($desired_val)"
      } else {
        print $"✅ ($key): ($current_val)"
      }
    }
  }

  print "\n=== 🔒 Branch Protection Comparison ==="
  if ($current.branch_protection | is-empty) {
    print "❌ No branch protection configured"
  } else {
    print "✅ Branch protection is configured"

    if "branch_protection" in $desired_config {
      let desired_protection = $desired_config.branch_protection
      let current_protection = $current.branch_protection

      # Compare key protection settings
      let key_settings = [
        "required_linear_history"
        "enforce_admins"
        "allow_force_pushes"
        "allow_deletions"
        "required_conversation_resolution"
      ]

      for setting in $key_settings {
        if $setting in $desired_protection {
          let desired_val = $desired_protection | get $setting
          let current_val = try { $current_protection | get $setting } catch { false }

          if $desired_val != $current_val {
            print $"❌ ($setting): current=($current_val), desired=($desired_val)"
          } else {
            print $"✅ ($setting): ($current_val)"
          }
        }
      }
    }
  }
}
