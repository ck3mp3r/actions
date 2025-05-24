act-test-update-flake-lock:
	@act push \
		--rm \
		--container-architecture linux/amd64 \
		-s GITHUB_TOKEN=${GITHUB_TOKEN} \
		-s ACTIONS_RUNTIME_TOKEN=${GITHUB_TOKEN} \
		-P ubuntu-latest=catthehacker/ubuntu:js-latest \
		-W .github/workflows/update-flake-lock.yaml \
		-j lockfile

act-test-semver:
	@act push \
		--rm \
		--container-architecture linux/amd64 \
		-s GITHUB_TOKEN=${GITHUB_TOKEN} \
		-s ACTIONS_RUNTIME_TOKEN=${GITHUB_TOKEN} \
		-P ubuntu-latest=catthehacker/ubuntu:js-latest \
		-W .github/workflows/test.yaml \
		-j test
