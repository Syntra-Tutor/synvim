# Synvim

A small Neovim configuration focused on text editing and window management. It keeps Neovim's built-in editing behavior and adds a few basic editor settings and split shortcuts. There are no plugins, language servers, or external tool integrations.

## Shortcuts

| Shortcut | Action |
| --- | --- |
| `Alt` + Arrow | Move focus across splits |
| `Alt` + `h` / `j` / `k` / `l` | Swap the active split with its neighbor |
| `Alt` + `q` / `Alt` + `w` | Close the active split |
| `Alt` + `+` | Split right with a terminal |
| `Alt` + `-` | Split down with a terminal |
| `Esc` | Leave terminal mode at a shell prompt, otherwise forward Esc |

There is intentionally no split zoom mapping: Neovim's standard maximize commands resize the overall layout, not just one split independently.

## Install

```sh
make install
# or
./setup.sh
```
