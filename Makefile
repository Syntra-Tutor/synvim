all:
	@echo "Synvim: minimal Neovim config with window-management shortcuts."
	@echo "Run 'make install' or './setup.sh' to install."

install:
	./setup.sh

.PHONY: all install
