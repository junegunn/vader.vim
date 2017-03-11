test:
	test/run-tests.sh

# Neovim might quit after ~5s with stdin being closed.  Use --headless mode to
# work around this.
# > Vim: Error reading input, exiting...
# > Vim: Finished.
testnvim: export TEST_VIM=env VADER_OUTPUT_FILE=/dev/stderr nvim --headless
testnvim:
	test/run-tests.sh

# Run tests in dockerized Vims.
DOCKER_IMAGE:=blueyed/vader.vim
DOCKER_STREAMS:=-ti
DOCKER=docker run $(DOCKER_STREAMS) --rm -v $(PWD):/testplugin $(DOCKER_IMAGE)
docker_image:
	docker build -f Dockerfile.tests -t $(DOCKER_IMAGE) .
docker_push:
	docker push $(DOCKER_IMAGE)

# docker run --rm $(DOCKER_IMAGE) sh -c 'cd /vim-build/bin && ls vim*'
DOCKER_VIMS:=vim73 vim74-trusty vim74-xenial vim8069 vim-master
_DOCKER_VIM_TARGETS:=$(addprefix docker_test-,$(DOCKER_VIMS))

docker_test_all: $(_DOCKER_VIM_TARGETS)

$(_DOCKER_VIM_TARGETS):
	$(MAKE) docker_test DOCKER_VIM=$(patsubst docker_test-%,%,$@)

docker_test: DOCKER_VIM:=vim-master
docker_test: DOCKER_STREAMS:=-a stderr
docker_test: DOCKER_RUN:=env TEST_VIM=/vim-build/bin/$(DOCKER_VIM) /testplugin/test/run-tests.sh
docker_test: docker_run

docker_run: $(TESTS_VADER_DIR)
docker_run:
	$(DOCKER) $(if $(DOCKER_RUN),$(DOCKER_RUN),bash)

.PHONY: test docker_image docker_push docker_test_all docker_test docker_run
