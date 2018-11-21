" Copyright (c) 2015 Junegunn Choi
"
" MIT License
"
" Permission is hereby granted, free of charge, to any person obtaining
" a copy of this software and associated documentation files (the
" "Software"), to deal in the Software without restriction, including
" without limitation the rights to use, copy, modify, merge, publish,
" distribute, sublicense, and/or sell copies of the Software, and to
" permit persons to whom the Software is furnished to do so, subject to
" the following conditions:
"
" The above copyright notice and this permission notice shall be
" included in all copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
" EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
" MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
" NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
" LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
" OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
" WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

let s:register = {}
let s:register_undefined = []
let s:indent = 2
" Fallback to 'type' (on Windows).
let s:cat = executable('cat') ? 'cat' : 'type'

function! vader#run(bang, ...) range
  let s:error_line = 0

  let g:vader_bang = a:bang

  if a:lastline - a:firstline > 0
    if a:0 > 1
      echoerr "You can't apply range on multiple files"
      return
    endif
    let [line1, line2] = [a:firstline, a:lastline]
  else
    let [line1, line2] = [1, 0]
  endif

  let options = {
        \ 'exitfirst': index(a:000, '-x') >= 0,
        \ 'quiet': index(a:000, '-q') >= 0,
        \ }
  let patterns = filter(copy(a:000), "index(['-x', '-q'], v:val) == -1")
  if empty(patterns)
    let patterns = [expand('%')]
  endif

  if a:bang && !options.quiet
    redir => ver
    silent version
    redir END
    call vader#print_stderr(ver . "\n\n")
  endif

  call vader#assert#reset()
  try
    let all_cases = []
    let qfl = []
    let st  = reltime()
    let [success, pending, total] = [0, 0, 0]

    for gl in patterns
      if filereadable(gl)
        let files = [gl]
      else
        let files = filter(split(glob(gl), "\n"),
              \ "fnamemodify(v:val, ':e') ==# 'vader'")
      endif
      for fn in files
        let afn = fnamemodify(fn, ':p')
        let cases = vader#parser#parse(afn, line1, line2)
        call add(all_cases, [afn, cases])
        let total += len(cases)
      endfor
    endfor
    if empty(all_cases)
      throw 'Vader: no tests found for patterns ('.join(patterns).')'
    endif

    call vader#window#open()
    call vader#window#append(
    \ printf("Starting Vader: %d suite(s), %d case(s)", len(all_cases), total), 0)

    for pair in all_cases
      let [fn, case] = pair
      let [cs, cp, ct, lqfl] = s:run(fn, case, options)
      let success += cs
      let pending += cp
      call extend(qfl, lqfl)
      call vader#window#append(
            \ printf('Success/Total: %s/%s%s',
            \     cs, ct, cp > 0 ? (' ('.cp.' pending)') : ''),
            \ 1)
      if options.exitfirst && (cs + cp) < ct
        break
      endif
    endfor

    let successful = success + pending == total
    let g:vader_result = {
          \ 'total': total,
          \ 'success': success,
          \ 'pending': pending,
          \ 'successful': successful,
          \ }

    let stats = vader#assert#stat()
    call vader#window#append(printf('Success/Total: %s/%s (%sassertions: %d/%d)',
          \ success, total, (pending > 0 ? pending . ' pending, ' : ''),
          \ stats[0], stats[1]), 0)
    if 0 && exists('*reltimefloat')
      let duration = printf('%.2f', reltimefloat(reltime(st)))
    else
      let duration = substitute(substitute(reltimestr(reltime(st)), '^\s*', '', ''), '\.\d\d\zs.*', '', '')
    endif
    call vader#window#append(printf('Elapsed time: %s sec.', duration), 0)
    call vader#window#cleanup()

    if a:bang
      if exists('*s:output_stderr_buffer')
        call s:output_stderr_buffer()
      endif
      if successful
        qall!
      else
        cq
      endif
    else
      let g:vader_report = join(getline(1, '$'), "\n")
      let g:vader_errors = qfl
      call setqflist(qfl)

      if !empty(qfl)
        call vader#window#copen()
      endif
    endif
  catch
    let error = 'Vader error: '.v:exception.' (in '.v:throwpoint.')'
    if a:bang
      call vader#print_stderr(error)
      cq
    else
      echoerr error
    endif
  finally
    call s:cleanup()
  endtry
endfunction

" Define vader#print_stderr based on available features / used options.
" This is done a) for performance reasons, but b) mainly because `mode()`
" might be e.g. "ic" during tests, and we need to detect the initial usage of
" "-es" / "-Es".
if !empty($VADER_OUTPUT_FILE)
  function! vader#print_stderr(output) abort
    let lines = split(a:output, '\n')
    call writefile(lines, $VADER_OUTPUT_FILE, 'a')
  endfunction
elseif has('nvim')
  if exists('v:stderr')
    function! vader#print_stderr(output) abort
      call chansend(v:stderr, a:output)
    endfunction
  elseif filewritable('/dev/stderr')
    function! vader#print_stderr(output) abort
      let lines = split(a:output, '\n')
      call writefile(lines, '/dev/stderr', 'a')
    endfunction
  else
    " Assume --headless mode being used.  Could be detected using
    " "len(nvim_list_uis()) == 0 after VimEnter", but not available with
    " Neovim 0.2.0 at least.
    function! vader#print_stderr(output) abort
      for line in split(a:output, '\n')
        echom line
      endfor
    endfunction
  endif
else
  if v:version >= 702  " mode(1) only works with Vim v7.2a.
    let mode = mode(1)
  else
    let mode = ''
  endif
  if mode ==# 'ce' || mode ==# 'cv'  " -es (silent ex mode)
    function! vader#print_stderr(output) abort
      let lines = split(a:output, '\n')
      for line in lines
        verbose echon line."\n"
      endfor
    endfunction
  else
    " Cannot output single lines reliably in this case.
    let s:stderr_buffer = []
    if !empty(mode)
      call add(s:stderr_buffer,
          \ printf('Vader note: cannot print to stderr reliably/directly.  Please consider using %s''s -es/-Es option (mode=%s).',
              \ has('nvim') ? 'Neovim' : 'Vim',
              \ mode))
    endif
    function! s:output_stderr_buffer() abort
      let s:tmpfile = tempname()
      call writefile(s:stderr_buffer, s:tmpfile)
      execute printf('silent !%s %s 1>&2', s:cat, s:tmpfile)
      let s:stderr_buffer = []
    endfunction
    augroup vader_exit
      autocmd VimLeave * call s:output_stderr_buffer()
    augroup END

    function! vader#print_stderr(output) abort
      let lines = split(a:output, '\n')
      call extend(s:stderr_buffer, lines)
    endfunction
  endif
endif

function! s:split_args(arg)
  let varnames = split(a:arg, ',')
  let names = []
  for varname in varnames
    let name = substitute(varname, '^\s*\(.*\)\s*$', '\1', '')
    let name = substitute(name, '^''\(.*\)''$', '\1', '')
    let name = substitute(name, '^"\(.*\)"$',  '\1', '')
    call add(names, name)
  endfor
  return names
endfunction

function! vader#log(msg)
  let msg = type(a:msg) == 1 ? a:msg : string(a:msg)
  call vader#window#append('> ' . msg, s:indent)
endfunction

function! vader#save(args)
  for varname in s:split_args(a:args)
    if exists(varname)
      let s:register[varname] = deepcopy(eval(varname))
    else
      let s:register_undefined += [varname]
    endif
  endfor
endfunction

function! vader#restore(args)
  let varnames = s:split_args(a:args)
  for varname in empty(varnames) ? keys(s:register) : varnames
    if has_key(s:register, varname)
      execute printf("let %s = deepcopy(s:register['%s'])", varname, varname)
    endif
  endfor
  let undefined = empty(varnames) ? s:register_undefined
        \ : filter(copy(varnames), 'index(s:register_undefined, v:val) != -1')
  for varname in undefined
    if varname[0] ==# '$'
      execute printf('let %s = ""', varname)
    else
      execute printf('unlet! %s', varname)
    endif
  endfor
endfunction

function! s:cleanup()
  let s:register = {}
  let s:register_undefined = []
  if exists(':Log') == 2
    delcommand Log
    delcommand Save
    delcommand Restore
    delcommand Assert
    delcommand AssertEqual
    delcommand AssertNotEqual
    delcommand AssertThrows
    delfunction SyntaxAt
    delfunction SyntaxOf
  endif
endfunction

function! s:comment(case, label)
  return get(a:case.comment, a:label, '')
endfunction

function! s:get_source_from_tb_entry(tb_entry)
  let func_line = split(a:tb_entry, '\v[\[\]]')
  if len(func_line) == 2
    let [f, l] = func_line
  else
    let split_f_linenr = split(a:tb_entry, ', line ')
    if len(split_f_linenr) == 2
      let [f, l] = split_f_linenr
    else
      let f = split_f_linenr[0]
      return ['', 0, f, '']
    endif
  endif
  if f =~# '\v^\d+$'
    let f = '{'.f.'}'
  endif
  try
    if exists('*execute')
      let func = execute('verb function '.f)
    else
      redir => func
        silent exe 'verb function '.f
      redir END
    endif
  catch /^Vim\%((\a\+)\)\=:E123/
    return ['', l, f, '']
  endtry

  let func_lines = split(func, "\n")
  " Vim patch v8.1.0362 will display source location of function.
  let m = matchlist(func_lines[1], '\v^\s*Last set from (.*) line (\d+)$')
  if empty(m)
    let floc = ''
  else
    let floc = fnamemodify(m[1], ':~:.') . ':' . (m[2] + l)
  endif

  let source = map(filter(func_lines, "v:val =~# '\\v^".l."[^0-9]'"), "substitute(v:val, '\\v^\\d+\\s+', '', '')")
  if len(source) != 1
    throw printf('Internal error: could not find source of %s:%d (parsed function: %s, source: %s)', string(a:tb_entry), l, f, string(source))
  endif
  return [source[0], l, f, floc]
endfunction

function! s:execute(prefix, type, block, fpos, lang_if)
  let g:vader_current_file = a:fpos[0]
  let [error, lines] = vader#window#execute(a:block, a:lang_if)
  if empty(error)
    return [1, []]
  endif

  " Get line number from wrapper function or throwpoint.
  let match_prefix = matchstr(error[1], '\v^function \zs\<SNR\>\d+_vader_wrapper')
  if empty(match_prefix)
    call s:append(a:prefix, a:type, 'Error: '.error[0]. ' (in '.error[1].')', 1)
    return [0, []]
  endif

  call s:append(a:prefix, a:type, error[0], 1)

  let tb_entries = reverse(split(error[1], '\.\.'))
  let tb_first = remove(tb_entries, -1)
  call filter(tb_entries, "v:val !~# '\\vvader#assert#[^,]+, line \\d+$'")
  for tb_entry in tb_entries
    let [source, l, f, floc] = s:get_source_from_tb_entry(tb_entry)
    if l
      if empty(floc)
        let floc = 'line '.l
      endif
      call vader#log('in '.f.' ('.floc.')')
      if len(source)
        call vader#log('  '.source)
      endif
    else
      call vader#log('in '.f)
    endif
  endfor
  let tb_first = substitute(tb_first, '^function ', '', '')
  let [source, l, _, _] = s:get_source_from_tb_entry(tb_first)
  let errpos = [a:fpos[0], l + a:fpos[1]]
  if len(source)
    call vader#log(errpos[0].':'.(errpos[1]).': '.source)
  else
    call vader#log(errpos[0].':'.(errpos[1]))
  endif

  return [0, errpos]
endfunction

function! s:run(filename, cases, options)
  let given = { 'lines': [] }
  let before = {}
  let after = {}
  let then = {}
  let comment = { 'given': '', 'before': '', 'after': '' }
  let total = len(a:cases)
  let just  = len(string(total))
  let cnt = 0
  let pending = 0
  let success = 0
  let exitfirst = get(a:options, 'exitfirst', 0)
  let qfl = []
  let g:vader_file = a:filename

  call vader#window#append("Starting Vader: ". a:filename, 1)

  for case in a:cases
    let cnt += 1
    let ok = 1
    let prefix = printf('(%'.just.'d/%'.just.'d)', cnt, total)

    for label in ['given', 'before', 'after', 'then']
      if has_key(case, label)
        execute 'let '.label." = {'lines': case[label], 'fpos': case.fpos[label]}"
        let comment[label] = get(case.comment, label, '')
      endif
    endfor

    if !empty(given.lines)
      call s:append(prefix, 'given', comment.given)
    endif
    call vader#window#prepare(given.lines, get(case, 'type', ''))

    if !empty(before)
      let s:indent = 2
      let [ok, errpos] = s:execute(prefix, 'before', before.lines, before.fpos, '')
    endif

    let s:indent = 3
    if has_key(case, 'execute')
      call s:append(prefix, 'execute', s:comment(case, 'execute'))
      if ok
        let [ok, errpos] = s:execute(prefix, 'execute', case.execute, case.fpos.execute, get(case, 'lang_if', ''))
      endif
    elseif has_key(case, 'do')
      call s:append(prefix, 'do', s:comment(case, 'do'))
      try
        call vader#window#replay(case.do)
      catch
        call s:append(prefix, 'do', v:exception, 1)
        if v:throwpoint !~ 'vader#assert'
          call vader#log(v:throwpoint)
        endif
        let ok = 0
        let errpos = case.fpos.do
      endtry
    endif

    if has_key(case, 'then')
      call s:append(prefix, 'then', s:comment(case, 'then'))
      if ok
        let [ok, errpos] = s:execute(prefix, 'then', then.lines, then.fpos, '')
      endif
    endif

    if has_key(case, 'expect')
      let result = vader#window#result()
      let match = case.expect ==# result
      if match
        call s:append(prefix, 'expect', s:comment(case, 'expect'))
      else
        let begin = s:append(prefix, 'expect', s:comment(case, 'expect'), 1)
        let ok = 0
        let errpos = case.fpos.expect
        let data = { 'type': get(case, 'type', ''), 'got': result, 'expect': case.expect }
        call vader#window#append('- Expected:', 3)
        for line in case.expect
          call vader#window#append(line, 5, 0)
        endfor
        let end = vader#window#append('- Got:', 3)
        for line in result
          let end = vader#window#append(line, 5, 0)
        endfor
        call vader#window#set_data(begin, end, data)
      endif
    endif

    if !empty(after)
      let s:indent = 2
      let g:vader_case_ok = ok
      let [after_ok, after_errpos] = s:execute(prefix, 'after', after.lines, after.fpos, '')
      let ok = after_ok && ok
      if empty(errpos)
        let errpos = after_errpos
      endif
    endif

    if ok
      let success += 1
    else
      let pending += case.pending
      let description = join(filter([
            \ comment.given,
            \ get(case.comment, 'do', get(case.comment, 'execute', '')),
            \ get(case.comment, 'then', ''),
            \ get(case.comment, 'expect', '')], '!empty(v:val)'), ' / ') .
            \ ' (#'.s:error_line.')'
      if empty(errpos)
        let errpos = [a:filename, case.lnum]
      endif
      call add(qfl, { 'type': 'E', 'filename': fnamemodify(errpos[0], ':~:.'), 'lnum': errpos[1], 'text': description })
      if exitfirst && !case.pending
        call vader#window#append('Stopping after first failure.', 2)
        break
      endif
    endif
  endfor

  unlet g:vader_file
  return [success, pending, total, qfl]
endfunction

function! s:append(prefix, type, message, ...)
  let error = get(a:, 1, 0)
  let message = (error ? '(X) ' : '') . a:message
  let line = vader#window#append(printf("%s [%7s] %s", a:prefix, toupper(a:type), message), 2)
  if error
    let s:error_line = line
  endif
  return line
endfunction

