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

let s:vader_tab = 0
let s:vader_window = 0

function! vader#window#open()
  if s:vader_tab
    execute "normal! ". s:vader_tab . "gt"
  endif

  " No tab
  if s:vader_tab != tabpagenr()
    tabnew
    set buftype=nofile
    silent! bd \[Vader\]
    silent f \[Vader\]
    let s:vader_tab = tabpagenr()
  endif

  for i in range(1, winnr('$'))
    execute i.'wincmd w'
    if &filetype == 'qf'
      bd
    endif
  endfor

  if winnr('$') < 2
    topleft new
    set buftype=nofile
    silent! bd vader-workbench
    silent f vader-workbench
  endif
  1wincmd w
  %d
  2wincmd w
  %d
endfunction

function! vader#window#execute(lines)
  1wincmd w
  let temp = tempname()
  try
    call writefile(a:lines, temp)
    execute 'source '.temp
  finally
    call delete(temp)
  endtry
endfunction

function! vader#window#replay(lines)
  1wincmd w
  let @x = substitute(join(a:lines, ''), '\\<[^>]\+>', '\=eval("\"".submatch(0)."\"")', 'g')
  normal! @x
endfunction

function! vader#window#result()
  1wincmd w
  return getline(1, line('$'))
endfunction

function! vader#window#append(message, indent)
  2wincmd w
  call append(line('$') - 1, repeat('  ', a:indent) . a:message)
endfunction

function! vader#window#prepare(lines, type)
  1wincmd w
  if !empty(a:type)
    execute 'setf '.a:type
  endif

  %d
  for line in a:lines
    call append(line('$') - 1, line)
  endfor
  normal! ddgg
endfunction

function! vader#window#cleanup()
  silent! bd vader-workbench

  nnoremap <buffer> q :silent! bd \[Vader\]<CR>:tabclose<CR>
  normal! ggzt
endfunction

function! vader#window#copen(qfl)
  call setqflist(a:qfl)
  copen
  nnoremap <buffer> q :silent! bd \[Vader\]<CR>:tabclose<CR>
endfunction
