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
- **Leading path components are peeled off** — an absolute or
  over-qualified path is tried as-is, then with leading components
  stripped one at a time, opening the first variant that exists. So
  `/app/src/foo/bar.ts` falls back to `app/src/foo/bar.ts`,
  `src/foo/bar.ts`, and so on. This also unwraps git diff prefixes
  like `a/path/to/file` and `b/path/to/file`.
- **TypeScript / MSBuild locations** — `foo.ts(280,13): error TS2339`
  is normalized to `foo.ts:280:13` and trailing diagnostic text is
  dropped.
- **Bracketed locations** — `Foo.java:[1,11]` is normalized to
  `Foo.java:1:11`. A leading diagnostic tag like `[ERROR]` and any
  trailing message (`error: ';' expected`) are dropped.

## Commands

| Command           | Description                                              |
|-------------------|----------------------------------------------------------|
| `:DWIM [target]`  | Open `target`. Defaults to the OS clipboard (`+` reg).   |

### Window placement

Pick where the file lands using the usual command modifiers, plus an
optional `++curwin` override:

| Invocation                  | Where the file opens                      |
|-----------------------------|-------------------------------------------|
| `:DWIM {target}`            | current window (default)                  |
| `:0DWIM {target}`           | current window (shorthand for `++curwin`) |
| `:DWIM ++curwin {target}`   | current window, ignoring any modifiers    |
| `:vert DWIM {target}`       | vertical split                            |
| `:aboveleft DWIM {target}`  | horizontal split above                    |
| `:belowright DWIM {target}` | horizontal split below                    |
| `:tab DWIM {target}`        | a new tab                                 |

Internally `:DWIM` switches from `:edit` to `:split` whenever a
window/tab modifier (`:vertical`, `:aboveleft`, `:leftabove`,
`:belowright`, `:rightbelow`, `:topleft`, `:botright`, `:tab`) is
present, so no explicit `++split` flag is needed.

A trailing `!` is passed through to the underlying `:edit` / `:split`
so unsaved changes in the current buffer can be discarded.

## Examples

```vim
:DWIM src/foo.ts:42:7
:DWIM b/src/foo.ts:42
:DWIM src/foo.ts(280,13): error TS2339: ...
:DWIM src/Foo.java:[1,11]
:DWIM                            " read from clipboard

:tab DWIM src/foo.ts:42          " open in a new tab
:vert DWIM src/foo.ts:42         " open in a vertical split
:aboveleft DWIM src/foo.ts:42    " open in a horizontal split above
```

## Suggested mapping

```vim
nnoremap <leader>o :DWIM<CR>
```

## License

[MIT](LICENSE).
