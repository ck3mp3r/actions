# CI Tools Action

A GitHub Action that sets up Nushell CI tools from the [nu-mods](https://github.com/ck3mp3r/nu-mods) repository.

## Usage

```yaml
- name: Setup CI Tools
  uses: ./actions/ci-tools

- name: Use CI Tools in workflow
  shell: nu {0}
  run: |
    use ci *
    
    # Example: Build nix flakes
    glob **/flake.nix 
      | each {|f| $f | path dirname}
      | ci nix flakes
      | ci nix packages
      | ci nix build
```

## Inputs

### `nu-mods-ref`

**Optional** Git reference (branch/tag/commit) of nu-mods repository to use.

**Default:** `main`

**Example:**
```yaml
- name: Setup CI Tools
  uses: ./actions/ci-tools
  with:
    nu-mods-ref: feature/ci-scm-module
```

## What it does

This action:
1. Installs Nix package manager
2. Installs Nushell via Nix
3. Installs the CI module from nu-mods repository via Nix flakes
4. Creates a symlink from the Nushell config scripts directory to the installed modules
5. Verifies that the CI modules can be loaded

## CI Module Features

The CI module from nu-mods provides:

- **Nix Integration**: Build flakes, manage packages, handle closures, cache to Cachix
- **Git Operations**: SCM operations for CI workflows
- **GitHub Integration**: Summary generation, logging
- **Logging**: Structured logging with levels (info, warn, error)

## Example Workflows

### Build and Cache Nix Flakes

```yaml
name: build-and-cache
on:
  push:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup CI Tools
        uses: ./actions/ci-tools
        
      - name: Build and cache flakes
        shell: nu {0}
        run: |
          use ci *

          # Find all flakes
          let buildable_flakes = (
            glob **/flake.nix 
              | each {|f| $f | path dirname}
              | ci nix flakes 
              | ci nix packages 
              | get flake? 
              | uniq
          )

          # Build all flakes
          let build_results = ($buildable_flakes | ci nix build)

          # Cache to Cachix
          $build_results | each {|result|
            if ($result.status == "success" and $result.path != null) {
              $result.path 
                | ci nix closure
                | ci nix cache "https://my-cache.cachix.org"
            }
          }
```

### Conditional Caching Based on Event

```yaml
- name: Build with conditional caching
  shell: nu {0}
  env:
    CACHIX_AUTH_TOKEN: ${{ secrets.CACHIX_AUTH_TOKEN }}
  run: |
    use ci *

    # Determine paths to check based on trigger
    let paths_to_check = if $env.GITHUB_EVENT_NAME == "workflow_dispatch" {
      glob **/flake.nix | each {|f| $f | path dirname}
    } else {
      git diff --name-only HEAD~1 HEAD | lines
    }

    # Get buildable flakes
    let buildable_flakes = (
      $paths_to_check 
        | ci nix flakes 
        | ci nix packages 
        | get flake? 
        | uniq
    )

    # Build and cache only on main branch
    let should_cache = ($env.GITHUB_REF == "refs/heads/main")
    
    let build_results = ($buildable_flakes | ci nix build)
    
    $build_results | each {|result|
      if ($result.status == "success") {
        let cache_results = if $should_cache {
          $result.path 
            | ci nix closure
            | ci nix cache "https://cache.cachix.org" --upstream "https://cache.nixos.org"
        } else {
          $result.path 
            | ci nix closure
            | ci nix cache "https://cache.cachix.org" --dry-run
        }
        
        $cache_results
      }
    }
```

## Requirements

- GitHub Actions runner (Linux or macOS)
- Git repository with proper permissions
- For Cachix integration: `CACHIX_AUTH_TOKEN` secret

## Features

- **Nix-based Installation**: Uses Nix for reliable, reproducible installation
- **Flake Support**: Direct installation from nu-mods Nix flake
- **Version Control**: Specify exact git reference for deterministic builds
- **CI/CD Optimized**: Designed for GitHub Actions workflows
- **Pipeline-friendly**: CI commands support Nushell pipelines
