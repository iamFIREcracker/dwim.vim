" DWIM open: filename[:line[:col]] {{{

function! s:OpenAtLocation(arg, count, mods, bang) abort
  " Parse leading ++curwin directive
  let l:arg = a:arg
  let l:curwin = 0
  if l:arg =~# '^\s*++curwin\>'
    let l:arg = substitute(l:arg, '^\s*++curwin\s*', '', '')
    let l:curwin = 1
  endif

  " :0DWIM is shorthand for ++curwin -- force the current window and
  " ignore any window-modifying :command-modifiers.
  if a:count == 0
    let l:curwin = 1
  endif

  " Pick :edit vs :split. :vertical, :tab, :aboveleft, etc. are silently
  " dropped on :edit (which doesn't open a window), so switch to :split
  " whenever a window/tab modifier is present -- that's what makes
  " :vert DWIM and :tab DWIM Just Work without an explicit ++split flag.
  let l:window_mod = a:mods =~# '\v<%(vertical|tab|aboveleft|leftabove|belowright|rightbelow|botright|topleft)>'
  if l:curwin
    let l:open = 'edit'
  elseif l:window_mod
    let l:open = trim(a:mods . ' split')
  else
    let l:open = trim(a:mods . ' edit')
  endif

  " Fall back to the OS clipboard when no argument is given
  let l:arg = empty(l:arg) ? getreg('+') : l:arg

  " 1. Clean up crap introduced by terminal copy/paste
  "    - remove newlines / CR
  "    - remove NUL chars (shown as ^@)
  "    - remove literal ^@ sequences (two characters: ^ and @)
  let l:arg = substitute(l:arg, '\r\|\n', '', 'g')
  let l:arg = substitute(l:arg, '\%x00', '', 'g')
  let l:arg = substitute(l:arg, '\^@', '', 'g')

  " 2. Trim leading/trailing whitespace
  let l:arg = substitute(l:arg, '^\s*\|\s*$', '', 'g')

  " 3. Normalize TypeScript/MSBuild-style locations: file(line,col)
  "    e.g. 'foo.ts(280,13): error TS2339: ...' -> 'foo.ts:280:13'
  "    Drop any trailing text after the location too.
  if l:arg =~ '(\d\+,\d\+)'
    let l:m = matchlist(l:arg, '\v^(.{-})\((\d+),(\d+)\)')
    let l:arg = l:m[1] . ':' . l:m[2] . ':' . l:m[3]
  endif

  " 3. Normalize bracketed locations: file:[line,col]
  "    e.g. '.../TokenValidationException.java:[1,11]' -> '...:1:11'
  if l:arg =~ ':\[\d\+,\d\+\]$'
    let l:m = matchlist(l:arg, '\v^(.*):\[(\d+),(\d+)\]$')
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

  " 5. Resolve the file by progressively stripping leading path
  "    components, opening the first variant that exists on disk. For
  "    '/app/src/foo/bar.ts' this tries, in order:
  "      /app/src/foo/bar.ts -> app/src/foo/bar.ts -> src/foo/bar.ts
  "      -> foo/bar.ts -> bar.ts
  "    This turns an absolute or over-qualified path into one Vim can
  "    open, and subsumes git's a/ and b/ diff prefixes (a/src/foo.ts
  "    resolves to src/foo.ts). The original path is kept when nothing
  "    matches, so opening a brand-new file still works.
  let l:candidate = l:file
  while !empty(l:candidate)
    if filereadable(l:candidate)
      let l:file = l:candidate
      break
    endif
    " Stop once there's no leading component left to strip.
    if l:candidate !~# '/'
      break
    endif
    " Drop everything up to and including the first slash.
    let l:candidate = substitute(l:candidate, '^[^/]*/\+', '', '')
  endwhile

  " 6. Open the file
  execute l:open . a:bang fnameescape(l:file)

  " 7. Jump to the requested location
  if l:line > 0
    execute l:line
    if l:col > 0
      call cursor(l:line, l:col)
    endif
  endif
endfunction

" :DWIM /path/to/file.js:123:45
" With no argument, reads the location from the OS clipboard.
"
" Window placement:
"   :DWIM {target}            " edit in the current window (default)
"   :0DWIM {target}           " force current window (same as ++curwin)
"   :DWIM ++curwin {target}   " force current window (ignore any :mods)
"   :vert DWIM {target}       " open in a vertical split
"   :aboveleft DWIM {target}  " open in a horizontal split above
"   :tab DWIM {target}        " open in a new tab
command! -nargs=? -bang -bar -count=1 DWIM
      \ call <SID>OpenAtLocation(<q-args>, <count>, '<mods>', '<bang>')
" }}}
