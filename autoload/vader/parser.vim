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

function! vader#parser#parse(fn)
  let lines = s:load_file(a:fn)
  return s:parse_vader(lines)
endfunction

function! s:load_file(filename)
  return readfile(fnamemodify(a:filename, ':p'))
endfunction

function! s:flush_buffer(cases, case, lnum, label, newlabel, buffer, final)
  if !empty(a:label)
    let rev = reverse(copy(a:buffer))
    while len(rev) > 0 && empty(rev[0])
      call remove(rev, 0)
    endwhile

    let data = map(reverse(rev), 'strpart(v:val, 2)')
    let a:case[a:label] = data
    if !empty(a:buffer)
      call remove(a:buffer, 0, -1)
    endif

    if a:final ||
          \ a:label == 'expect' ||
          \ a:newlabel == 'given' ||
          \ has_key(a:case, a:newlabel) ||
          \ a:newlabel == 'do' && has_key(a:case, 'execute') ||
          \ a:newlabel == 'execute' && has_key(a:case, 'do')
      call add(a:cases, deepcopy(a:case))
      for key in keys(a:case)
        call remove(a:case, key)
      endfor
      let a:case.comment = {}
      let a:case.lnum = a:lnum
    endif
  endif
endfunction

function! s:parse_vader(lines)
  let label    = ''
  let newlabel = ''
  let buffer   = []
  let cases    = []
  let case     = { 'lnum': 1, 'comment': {} }
  let lnum     = 0

  for line in a:lines
    let lnum += 1

    " Comment
    if line =~ '^#'
      continue
    endif

    let matched = 0
    for l in ['Given', 'Execute', 'Expect', 'Do']
      let m = matchlist(line, '^'.l.'\s*\(.*\)\s*:')
      if !empty(m)
        let newlabel = tolower(l)
        call s:flush_buffer(cases, case, lnum, label, newlabel, buffer, 0)

        let label = newlabel
        if !empty(m[1])
          let args    = matchlist(m[1], '^\(.\{-}\)\?\s*\((\(.*\))\)\?$')
          let arg     = get(args, 1, '')
          let comment = get(args, 3, '')

          if !empty(arg) && (l == 'Given')
            let case.type = arg
          endif
          if !empty(comment)
            let case.comment[tolower(l)] = comment
          endif
        endif
        let matched = 1
        break
      endif
    endfor
    if matched | continue | endif

    " Continuation
    if !empty(line) && line !~ '^  '
      throw "Syntax error: " . line
    endif
    call add(buffer, line)
  endfor
  call s:flush_buffer(cases, case, lnum, label, '', buffer, 1)

  return cases
endfunction

