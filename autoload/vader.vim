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
  call s:prepare()
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

function! s:prepare()
  command! -nargs=+ Log            :call vader#log(<args>)
  command! -nargs=+ Save           :call vader#save(<q-args>)
  command! -nargs=* Restore        :call vader#restore(<q-args>)
  command! -nargs=+ Assert         :call vader#assert#true(<args>)
  command! -nargs=+ AssertEqual    :call vader#assert#equal(<args>)
  command! -nargs=+ AssertNotEqual :call vader#assert#not_equal(<args>)
  command! -nargs=+ AssertThrows   :call vader#assert#throws(<q-args>)
  let g:SyntaxAt = function('vader#helper#syntax_at')
  let g:SyntaxOf = function('vader#helper#syntax_of')
endfunction

function! s:cleanup()
  let s:register = {}
  let s:register_undefined = []
  delcommand Log
  delcommand Save
  delcommand Restore
  delcommand Assert
  delcommand AssertEqual
  delcommand AssertNotEqual
  delcommand AssertThrows
  unlet g:SyntaxAt
  unlet g:SyntaxOf
endfunction

function! s:comment(case, label)
  return get(a:case.comment, a:label, '')
endfunction

function! s:execute(prefix, type, block, lang_if)
  try
    call vader#window#execute(a:block, a:lang_if)
    return 1
  catch
    call s:append(a:prefix, a:type, v:exception, 1)
    call s:print_throwpoint()
    return 0
  endtry
endfunction

function! s:print_throwpoint()
  if v:throwpoint !~ 'vader#assert'
    Log v:throwpoint
  endif
endfunction

function! s:run(filename, cases, options)
  let given = []
  let before = []
  let after = []
  let then = []
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
        execute 'let '.label.' = case[label]'
        let comment[label] = get(case.comment, label, '')
      endif
    endfor

    if !empty(given)
      call s:append(prefix, 'given', comment.given)
    endif
    call vader#window#prepare(given, get(case, 'type', ''))

    if !empty(before)
      let s:indent = 2
      let ok = ok && s:execute(prefix, 'before', before, '')
    endif

    let s:indent = 3
    if has_key(case, 'execute')
      call s:append(prefix, 'execute', s:comment(case, 'execute'))
      let ok = ok && s:execute(prefix, 'execute', case.execute, get(case, 'lang_if', ''))
    elseif has_key(case, 'do')
      call s:append(prefix, 'do', s:comment(case, 'do'))
      try
        call vader#window#replay(case.do)
      catch
        call s:append(prefix, 'do', v:exception, 1)
        call s:print_throwpoint()
        let ok = 0
      endtry
    endif

    if has_key(case, 'then')
      call s:append(prefix, 'then', s:comment(case, 'then'))
      let ok = ok && s:execute(prefix, 'then', then, '')
    endif

    if has_key(case, 'expect')
      let result = vader#window#result()
      let match = case.expect ==# result
      if match
        call s:append(prefix, 'expect', s:comment(case, 'expect'))
      else
        let begin = s:append(prefix, 'expect', s:comment(case, 'expect'), 1)
        let ok = 0
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
      let ok = s:execute(prefix, 'after', after, '') && ok
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
      call add(qfl, { 'type': 'E', 'filename': a:filename, 'lnum': case.lnum, 'text': description })
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

