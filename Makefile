# Builds Neat.UI, Files, Task Manager and Remote into ./dist.
# Run inside the workspace container:  ws run -- make
PREFIX   := $(CURDIR)/dist
BUILD    := $(CURDIR)/build
PACKAGES := neat-ui neat-files neat-taskmanager neat-remote
# Extra cmake arguments, e.g. from packaging (given last, so they win).
CMAKE_EXTRA :=
CMAKE_ARGS := -G Ninja -DCMAKE_BUILD_TYPE=RelWithDebInfo -DCMAKE_INSTALL_PREFIX=$(PREFIX) \
              -DCMAKE_PREFIX_PATH=$(PREFIX) $(CMAKE_EXTRA)

.PHONY: all files taskmanager remote ui $(PACKAGES) clean
all: $(PACKAGES)
ui: neat-ui
files: neat-files
taskmanager: neat-taskmanager
remote: neat-remote
neat-files neat-taskmanager neat-remote: neat-ui

$(PACKAGES):
	cmake -S packages/$@ -B $(BUILD)/$@ $(CMAKE_ARGS)
	cmake --build $(BUILD)/$@
	cmake --install $(BUILD)/$@

clean:
	rm -rf $(BUILD) $(PREFIX)
