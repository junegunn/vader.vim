" Copyright (c) 2013 Junegunn Choi
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

if exists("g:loaded_vader")
  finish
endif
let g:loaded_vader = 1
let s:register = {}

function! vader#run(bang, ...)
  if a:0 == 0
    let patterns = [expand('%')]
  else
    let patterns = a:000
  endif

  call s:prepare()
  try
    let all_cases = []
    let qfl = []
    let st  = reltime()
    let [success, total] = [0, 0]

    for gl in patterns
      for fn in split(glob(gl), "\n")
        if fnamemodify(fn, ':e') == 'vader'
          let cases = vader#parser#parse(fn)
          call add(all_cases, [fn, cases])
          let total += len(cases)
        endif
      endfor
    endfor
    if empty(all_cases) | return | endif

    call vader#window#open()
    call vader#window#append(
    \ printf("Starting Vader: %d suite(s), %d case(s)", len(all_cases), total), 0)

    for pair in all_cases
      let [fn, case] = pair
      let [cs, ct, lqfl] = s:run(fn, case)
      let success += cs
      call extend(qfl, lqfl)
      call vader#window#append(printf('Success/Total: %s/%s', cs, ct), 1)
    endfor

    call vader#window#append(printf('Success/Total: %s/%s', success, total), 0)
    call vader#window#append('Elapsed time: '.
          \ substitute(reltimestr(reltime(st)), '^\s*', '', '') .' sec.', 0)
    call vader#window#cleanup()
    if a:bang
      if empty(qfl)
        qall
      else
        cq
      endif
    elseif !empty(qfl)
      call vader#window#copen(qfl)
    endif
  finally
    call s:cleanup()
  endtry
endfunction

function s:split_args(arg)
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

function vader#save(args)
  for varname in s:split_args(a:args)
    if exists(varname)
      let s:register[varname] = eval(varname)
    endif
  endfor
endfunction

function vader#restore(args)
  let varnames = s:split_args(a:args)
  for varname in empty(varnames) ? keys(s:register) : varnames
    if has_key(s:register, varname)
      execute printf("let %s = s:register['%s']", varname, varname)
    endif
  endfor
endfunction

function! s:prepare()
  command! -nargs=+ Save        :call vader#save(<q-args>)
  command! -nargs=* Restore     :call vader#restore(<q-args>)
  command! -nargs=+ Assert      :call vader#assert#true(<args>)
  command! -nargs=+ AssertEqual :call vader#assert#equal(<args>)
endfunction

function! s:cleanup()
  let s:register = {}
  delcommand Save
  delcommand Restore
  delcommand AssertEqual
  delcommand Assert
endfunction

function! s:comment(case, label)
  return get(a:case.comment, a:label, '')
endfunction

function! s:run(filename, cases)
  let given = []
  let given_comment = ''
  let total = len(a:cases)
  let cnt = 0
  let success = 0
  let qfl = []

  call vader#window#append("Starting Vader: ". a:filename, 1)

  for case in a:cases
    let cnt += 1
    let ok = 1
    let prefix = printf('(%2d/%2d)', cnt, total)

    if has_key(case, 'given')
      let given = case.given
      let given_comment = get(case.comment, 'given', '')
    endif

    if !empty(given)
      call s:append(prefix, 'given', given_comment)
    endif
    call vader#window#prepare(given, get(case, 'type', ''))

    if has_key(case, 'execute')
      call s:append(prefix, 'execute', s:comment(case, 'execute'))
      try
        call vader#window#execute(case.execute)
      catch
        call s:append(prefix, 'execute', '(X) '.v:exception)
        let ok = 0
      endtry
    elseif has_key(case, 'do')
      call s:append(prefix, 'do', s:comment(case, 'do'))
      try
        call vader#window#replay(case.do)
      catch
        call s:append(prefix, 'do', '(X) '.v:exception)
        let ok = 0
      endtry
    endif

    if has_key(case, 'expect')
      let result = vader#window#result()

      let oignorecase = &ignorecase
      try
        set noignorecase
        let ok = case.expect == result
      finally
        let &ignorecase = oignorecase
      endtry

      call s:append(prefix, 'expect', (ok ? '' : '(X) ') . s:comment(case, 'expect'))

      if !ok
        call vader#window#append('- Expected:', 3)
        for line in case.expect
          call vader#window#append(line, 5)
        endfor
        call vader#window#append('- Got:', 3)
        for line in result
          call vader#window#append(line, 5)
        endfor
      endif
    endif

    if ok
      let success += 1
    else
      let description = join(filter([
            \ given_comment,
            \ get(case.comment, 'do', get(case.comment, 'execute', '')),
            \ get(case.comment, 'expect', '')], '!empty(v:val)'), ' - ')
      call add(qfl, { 'type': 'E', 'filename': a:filename, 'lnum': case.lnum, 'text': description })
    endif
  endfor

  return [success, total, qfl]
endfunction

function! s:append(prefix, type, message)
  call vader#window#append(printf("%s [%7s] %s", a:prefix, toupper(a:type), a:message), 2)
endfunction
