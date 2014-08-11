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

let s:quickfix_bfr  = 0
let s:console_tab   = 0
let s:workbench_tab = 0

function! s:console()
  execute 'normal! '.s:console_tab.'gt'
endfunction

function! s:workbench()
  execute 'normal! '.s:workbench_tab.'gt'
endfunction

function! vader#window#workbench()
  call s:workbench()
endfunction

function! vader#window#open()
  silent! bd \[Vader\]
  silent! bd \[Vader-workbench\]
  if bufexists(s:quickfix_bfr)
    execute "silent! bd ".s:quickfix_bfr
  endif

  tabnew
  setlocal buftype=nofile
  setlocal noswapfile
  setf vader-result
  silent f \[Vader\]
  let s:console_tab = tabpagenr()

  tabnew
  setlocal buftype=nofile
  setlocal noswapfile
  silent f \[Vader-workbench\]
  let s:workbench_tab = tabpagenr()
endfunction

function! vader#window#execute(lines, lang_if)
  call s:workbench()
  let temp = tempname()
  try
    if empty(a:lang_if)
      let lines = a:lines
    else
      let lines = copy(a:lines)
      call insert(lines, a:lang_if . ' << __VADER__LANG__IF__')
      call add(lines, '__VADER__LANG__IF__')
    endif
    call writefile(lines, temp)
    execute 'source '.temp
  finally
    call delete(temp)
  endtry
endfunction

function! vader#window#replay(lines)
  call s:workbench()
  call setreg('x', substitute(join(a:lines, ''), '\\<[^>]\+>', '\=eval("\"".submatch(0)."\"")', 'g'), 'c')
  normal! @x
endfunction

function! vader#window#result()
  call s:workbench()
  return getline(1, line('$'))
endfunction

function! vader#window#append(message, indent)
  call s:console()
  call append(line('$') - 1,
        \ substitute(repeat('  ', a:indent) . a:message, '\s*$', '', ''))
endfunction

function! vader#window#prepare(lines, type)
  call s:workbench()
  if !empty(a:type)
    execute 'setf '.a:type
  endif

  %d
  for line in a:lines
    call append(line('$') - 1, line)
  endfor
  normal! ddgg

  let &undolevels = &undolevels " Break undo block
endfunction

function! vader#window#cleanup()
  silent! bd \[Vader-workbench\]
  call s:console()

  nnoremap <buffer> q :tabclose<CR>
  normal! Gzb
endfunction

function! vader#window#copen()
  copen
  let s:quickfix_bfr = bufnr('')
  1wincmd w
  normal! Gzb
  2wincmd w
  nnoremap <buffer> q :tabclose<CR>
endfunction
