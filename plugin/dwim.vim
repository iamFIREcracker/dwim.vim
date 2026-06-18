" DWIM open: filename[:line[:col]] {{{

function! s:OpenAtLocation(arg) abort
  " Fall back to the OS clipboard when no argument is given
  let l:arg = empty(a:arg) ? getreg('+') : a:arg

  " 1. Clean up crap introduced by terminal copy/paste
  "    - remove newlines / CR
  "    - remove NUL chars (shown as ^@)
  "    - remove literal ^@ sequences (two characters: ^ and @)
  let l:arg = substitute(l:arg, '\r\|\n', '', 'g')
  let l:arg = substitute(l:arg, '\%x00', '', 'g')
  let l:arg = substitute(l:arg, '\^@', '', 'g')

  " 2. Trim leading/trailing whitespace
  let l:arg = substitute(l:arg, '^\s*\|\s*$', '', 'g')

  " 3. Strip git diff a/ or b/ prefixes if the resulting path exists
  "    Git outputs paths like 'a/path/to/file' and 'b/path/to/file' in diffs;
  "    strip the prefix only if the resulting path actually exists.
  if l:arg =~# '^[ab]/'
    let l:stripped_arg = substitute(l:arg, '^[ab]/', '', '')
    " Extract just the file part for existence check (remove :line:col suffix)
    let l:stripped_file = substitute(l:stripped_arg, ':\d\+\(:\d\+\)\?$', '', '')
    if filereadable(l:stripped_file)
      let l:arg = l:stripped_arg
    endif
  endif

  " 3. Normalize TypeScript/MSBuild-style locations: file(line,col)
  "    e.g. 'foo.ts(280,13): error TS2339: ...' -> 'foo.ts:280:13'
  "    Drop any trailing text after the location too.
  if l:arg =~ '(\d\+,\d\+)'
    let l:m = matchlist(l:arg, '\v^(.{-})\((\d+),(\d+)\)')
    let l:arg = l:m[1] . ':' . l:m[2] . ':' . l:m[3]
  endif

  let l:line = 0
  let l:col  = 0

  " 4. Parse filename:line:col
  " filename:line:col
  if l:arg =~ ':\d\+:\d\+$'
    let l:m = matchlist(l:arg, '\v^(.*):(\d+):(\d+)$')
    let l:file = l:m[1]
    let l:line = str2nr(l:m[2])
    let l:col  = str2nr(l:m[3])

  " filename:line
  elseif l:arg =~ ':\d\+$'
    let l:m = matchlist(l:arg, '\v^(.*):(\d+)$')
    let l:file = l:m[1]
    let l:line = str2nr(l:m[2])

  " just a filename
  else
    let l:file = l:arg
  endif

  " 5. Open the file
  execute 'edit' fnameescape(l:file)

  " 6. Jump to the requested location
  if l:line > 0
    execute l:line
    if l:col > 0
      call cursor(l:line, l:col)
    endif
  endif
endfunction

" :DWIM /path/to/file.js:123:45
" With no argument, reads the location from the OS clipboard.
command! -nargs=? DWIM call <SID>OpenAtLocation(<q-args>)
" }}}
