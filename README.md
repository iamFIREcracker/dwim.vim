# dwim.vim

A tiny Vim plugin that opens files from a `filename:line:col` string —
the kind your terminal, compiler, linter, or git diff just spat out —
and jumps you to the right spot.

Paste a path, hit `:DWIM`, and you're there. No argument? It reads the
OS clipboard.

## Features

- **`filename:line:col`, `filename:line`, or just `filename`** — all
  three forms work.
- **Clipboard fallback** — `:DWIM` with no argument grabs the location
  from the `+` register.
- **Cleans up terminal copy/paste noise** — newlines, `\0` bytes, and
  literal `^@` sequences are stripped.
- **Git diff prefixes** — `a/path/to/file` and `b/path/to/file` are
  unwrapped when the underlying file exists.
- **TypeScript / MSBuild locations** — `foo.ts(280,13): error TS2339`
  is normalized to `foo.ts:280:13` and trailing diagnostic text is
  dropped.

## Commands

| Command           | Description                                              |
|-------------------|----------------------------------------------------------|
| `:DWIM [target]`  | Open `target`. Defaults to the OS clipboard (`+` reg).   |

## Examples

```vim
:DWIM src/foo.ts:42:7
:DWIM b/src/foo.ts:42
:DWIM src/foo.ts(280,13): error TS2339: ...
:DWIM                            " read from clipboard
```

## Suggested mapping

```vim
nnoremap <leader>o :DWIM<CR>
```

## License

[MIT](LICENSE).
