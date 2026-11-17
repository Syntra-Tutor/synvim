all:
	@echo "synvim is a minimal Neovim config."
	@echo "Run 'make install' or './setup.sh' to deploy it."

install:
	./setup.sh

.PHONY: all install

