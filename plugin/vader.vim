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

if exists('g:loaded_vader')
  finish
endif

if &compatible
  function! s:vader(...) range
    echoerr 'Cannot run Vader in compatible mode'
  endfunction
else
  let g:loaded_vader = 1

  function! s:vader(...) range
    if a:lastline - a:firstline > 0 && a:0 > 1
      echoerr 'Range and file arguments are mutually exclusive'
      return
    endif
    execute printf("%d,%dcall vader#run(%s)", a:firstline, a:lastline, string(a:000)[1:-2])
  endfunction
endif

command! -bang -nargs=* -range -complete=file Vader <line1>,<line2>call s:vader(<bang>0, <f-args>)
