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


let s:assertions = [0, 0]

let s:type_names = {
      \ 0: 'Number',
      \ 1: 'String',
      \ 2: 'Funcref',
      \ 3: 'List',
      \ 4: 'Dictionary',
      \ 5: 'Float',
      \ 6: 'Boolean',
      \ 7: 'Null' }

function! vader#assert#reset()
  let s:assertions = [0, 0]
endfunction

function! vader#assert#stat()
  return s:assertions
endfunction

function! vader#assert#true(...)
  let s:assertions[1] += 1

  if a:0 == 1
    let [expr, message] = [a:1, "Assertion failure"]
  elseif a:0 == 2
    let [expr, message] = a:000
  else
    throw 'Invalid number of arguments'
  endif

  if !expr
    throw message
  endif
  let s:assertions[0] += 1
  return 1
endfunction

function! s:check_types(...)
  let [Exp, Got] = a:000[0:1]
  if type(Exp) !=# type(Got)
    throw get(a:000, 2, printf("type mismatch: %s (%s) should be equal to %s (%s)",
          \ string(Got), get(s:type_names, type(Got), type(Got)),
          \ string(Exp), get(s:type_names, type(Exp), type(Exp))))
  endif
endfunction

function! vader#assert#equal(...)
  let [Exp, Got] = a:000[0:1]
  let s:assertions[1] += 1

  call s:check_types(Exp, Got)
  if Exp !=# Got
    let type = type(Exp)
    let type_name = get(s:type_names, type)
    let type_name_plural = type_name ==# 'Dictionary' ? 'Dictionaries' : type_name.'s'
    let msg = (type == type({}) || type == type([]))
          \ ? printf("Unequal %s\n      %%s should be equal to\n      %%s", type_name_plural)
          \ : '%s should be equal to %s'
    throw get(a:000, 2, printf(msg, string(Got), string(Exp)))
  endif
  let s:assertions[0] += 1
  return 1
endfunction

function! vader#assert#not_equal(...)
  let [Exp, Got] = a:000[0:1]
  let s:assertions[1] += 1

  call s:check_types(Exp, Got)
  if Exp ==# Got
    throw get(a:000, 2, printf("%s should not be equal to %s", string(Got), string(Exp)))
  endif
  let s:assertions[0] += 1
  return 1
endfunction

function! vader#assert#throws(exp)
  let s:assertions[1] += 1

  let g:vader_exception = ''
  let g:vader_throwpoint = ''
  let ok = 0
  try
    execute a:exp
  catch
    let g:vader_exception = v:exception
    let g:vader_throwpoint = v:throwpoint
    let ok = 1
  endtry

  let s:assertions[0] += ok
  if ok | return 1
  else  | throw 'Exception expected but not raised: '.a:exp
  endif
endfunction
