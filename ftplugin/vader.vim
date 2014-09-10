" Copyright (c) 2014 Junegunn Choi
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

let b:vader_label = vader#syntax#_head()
let b:vader_eos = '\(.*\n'.vader#syntax#_head().'\)\|\%$'

setlocal shiftwidth=2 tabstop=2 softtabstop=2 expandtab
let &l:commentstring = '" %s'

nnoremap <buffer><silent> [[ :call search(b:vader_label, 'bW')<CR>
nnoremap <buffer><silent> [] :call search(b:vader_eos, 'bW')<CR>

nnoremap <buffer><silent> ]] :call search(b:vader_label, 'W')<CR>
nnoremap <buffer><silent> ][ :call search(b:vader_eos, 'W')<CR>

vnoremap <buffer><silent> [[ <ESC>:execute "normal! gv"<BAR>call search(b:vader_label, 'bW')<CR>
vnoremap <buffer><silent> [] <ESC>:execute "normal! gv"<BAR>call search(b:vader_eos, 'bW')<CR>

vnoremap <buffer><silent> ]] <ESC>:execute "normal! gv"<BAR>call search(b:vader_label, 'W')<CR>
vnoremap <buffer><silent> ][ <ESC>:execute "normal! gv"<BAR>call search(b:vader_eos, 'W')<CR>

augroup vader_syntax
  autocmd!
  if exists('##TextChangedI')
    autocmd TextChangedI <buffer> call vader#syntax#include('.', '.')
  else
    autocmd CursorMovedI <buffer> call vader#syntax#include('.', '.')
  endif
  " autocmd FileType <buffer> call vader#syntax#include(1, '$')
augroup END

