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

function! vader#parser#parse(fn, line1, line2)
  return s:parse_vader(s:read_vader(a:fn, a:line1, a:line2), a:line1)
endfunction

function! s:flush_buffer(cases, case, require, fn, lnum, raw, label, newlabel, buffer, final)
  if a:newlabel == 'require'
    let a:require['lnum'] = a:lnum
    return
  endif
  let is_validation = index(['then', 'expect'], a:newlabel) >= 0
  let fpos = a:fn.':'.a:lnum

  if empty(a:label) && a:newlabel != 'require'
    if is_validation
      echoerr 'Expect/Then should not appear before Do/Execute ('.fpos.')'
    endif
  else
    if a:label == 'skipif' && has_key(a:case, 'skipif')
      " SkipIf block is about to be set for the second time. This happens when
      " the SkipIf comes before the Given block in the second test or later tests
      echoerr 'Duplicate SkipIf block (SkipIf should follow Given blocks)'
    endif

    let rev = reverse(copy(a:buffer))
    while len(rev) > 0 && empty(rev[0])
      call remove(rev, 0)
    endwhile

    let data = map(reverse(rev), (a:case.raw ? 'v:val' : 'strpart(v:val, 2)'))

    if a:label == 'require'
      let a:require[a:label] = data
    else
      let a:case[a:label] = data
    endif

    if !empty(a:buffer)
      call remove(a:buffer, 0, -1)
    endif

    let fulfilled = has_key(a:case, 'do') || has_key(a:case, 'execute')
    if is_validation
      if !fulfilled
        echoerr 'Expect/Then should not appear before Do/Execute ('.fpos.')'
      endif
      if has_key(a:case, a:newlabel)
        echoerr 'Expect/Then should appear only once for each Do/Execute ('.fpos.')'
      endif
    endif

    if a:label != 'require'
      if a:final ||
      \ a:newlabel == 'given' ||
      \ index(['before', 'after', 'do', 'execute'], a:newlabel) >= 0 && fulfilled
        if has_key(a:case, 'skipif') && !has_key(a:case, 'given')
          " SkipIf block was set before Given block. This happens when a SkipIf
          " comes before a Given block in the first test
          echoerr 'SkipIf should appear after its corresponding Given'
        endif
        if a:label != 'require'
          call add(a:cases, deepcopy(a:case))
          let new = { 'comment': {}, 'lnum': a:lnum, 'pending': 0 }
          if !empty(get(a:case, 'type', ''))
            let new.type = a:case.type " To reuse Given block with type
          endif
          call extend(filter(a:case, '0'), new)
        endif
      endif
    endif
  endif
  let a:case.raw = a:raw
endfunction

function! s:read_vader(fn, line1, line2)
  let remains   = readfile(a:fn)[a:line1 - 1 : a:line2 - 1]
  let lnum      = a:line1
  let lines     = []
  let reserved  = 0
  let depth     = 0 " Not a strict depth
  let max_depth = 10

  while len(remains) > 0
    let line = remove(remains, 0)
    let m = matchlist(line, '^Include\(\s*(.*)\s*\)\?:\s*\(.\{-}\)\s*$')
    if !empty(m)
      let file = findfile(m[2], fnamemodify(a:fn, ':h'))
      if empty(file)
        echoerr "Cannot find ".m[2]
      endif
      if reserved > 0
        let depth += 1
        if depth >= max_depth
          echoerr 'Recursive inclusion limit exceeded'
        endif
        let reserved -= 1
      endif
      let included = readfile(file)
      let reserved += len(included)
      call extend(remains, included, 0)
      continue
    end

    call add(lines, [a:fn, lnum, line])
    if reserved > 0
      let reserved -= 1
    end
    if reserved == 0
      let depth = 0
      let lnum += 1
    endif
  endwhile

  return lines
endfunction

function! s:parse_vader(lines, line1)
  let label    = ''
  let newlabel = ''
  let buffer   = []
  let cases    = []
  let case     = { 'lnum': a:line1, 'comment': {}, 'pending': 0, 'raw': 0 }
  let require  = { 'lnum': 0,       'comment': '', 'pending': 0, 'raw': 0 }
  let require_defined = 0

  if empty(a:lines)
    return [], []
  endif

  for [fn, lnum, line] in a:lines
    " Comment / separators
    if !case.raw && line =~ '^[#"=~*^-]'
      continue
    endif

    let matched = 0
    for l in ['Before', 'After', 'Given', 'Execute', 'Expect', 'Do', 'Then', 'Require', 'SkipIf']
      let m = matchlist(line, '^'.l.'\%(\s\+\([^:;(]\+\)\)\?\s*\%((\(.*\))\)\?\s*\([:;]\)\s*$')
      if !empty(m)
        let newlabel = tolower(l)
        call s:flush_buffer(cases, case, require, fn, lnum, m[3] == ';', label, newlabel, buffer, 0)

        if l == 'Require'
          if require_defined == 1
            throw 'Syntax error (only one Require block is allowed per file): ' . line
          endif

          let require_defined = 1
        endif

        let label   = newlabel
        let arg     = m[1]
        let comment = m[2]
        if !empty(arg)
          if     l == 'Given'   | let case.type    = arg
          elseif l == 'Execute' | let case.lang_if = arg
          end
        elseif l == 'Given'
          let case.type = ''
        endif
        if !empty(comment)
          if l == 'Require'
            let require.comment = comment
          else
            let case.comment[tolower(l)] = comment
            if index(['do', 'execute'], label) >= 0 &&
                  \ comment =~# '\<TODO\>\|\<FIXME\>'
              let case.pending = 1
            endif
          endif
        endif
        let matched = 1
        break
      endif
    endfor
    if matched | continue | endif

    " Continuation
    if !empty(line) && !case.raw && line !~ '^  '
      throw 'Syntax error (line does not start with two spaces): ' . line
    endif
    if !empty(label)
      call add(buffer, line)
    endif
  endfor
  call s:flush_buffer(cases, case, require, fn, lnum, case.raw, label, '', buffer, 1)

  let ret = [require]
  let prev = {}
  for case in cases
    if has_key(case, "do") || has_key(case, "execute")
      call add(ret, extend(prev, case))
      let prev = {}
    else
      let prev = case
    endif
  endfor
  return ret
endfunction

