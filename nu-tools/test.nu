#!/usr/bin/env nu

# Test script for nu-tools modules (syntax and loading only)

print "Testing Nu Tools modules..."

# Test each module file for syntax errors
print "\n🧪 Testing module syntax..."

let modules = ["semver.nu", "git.nu", "cargo.nu", "github.nu", "artifacts.nu", "mod.nu"]

for module in $modules {
  try {
    nu -c $"source modules/($module)"
    print $"✅ ($module) - syntax OK"
  } catch {
    print $"❌ ($module) - syntax error"
  }
}

# Test semver module (safe to test)
print "\n🧪 Testing semver calculate function..."
try {
  let test_result = (nu -c 'source modules/semver.nu; calculate "1.0.0" "1.0.1"')
  if ($test_result | str trim) == "1.0.1" {
    print "✅ semver calculate works correctly"
  } else {
    print $"❌ semver calculate failed: expected 1.0.1, got ($test_result)"
  }
} catch {
  print "❌ semver calculate failed with error"
}

# Test that mod.nu can load all modules
print "\n🧪 Testing combined module loading..."
try {
  nu -c 'source modules/mod.nu; help calculate' | ignore
  print "✅ Combined module loading works"
} catch {
  print "❌ Combined module loading failed"
}

print "\n🎉 All tests completed!"