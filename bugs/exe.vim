" The term 'default scope' refers the the scope where the
" unqualified names are looked up, i.e., x, y.

" This shows that default scope in function is l:.
function! F()
  let x = 1
  execute 'echo l:x is# x'
endfunction

" This explains the root of the bug.
function! X()
  " the l: hides the g:
  execute 'echo x'
endfunction

function! L()
  echo eval('g:x is# g:x')
endfunction

" Use this as a solution.
function! G()
  " Explicitly prefix a g:.
  execute 'echo g:x'
endfunction

function! W()
  " This explains why s: prefix does not work.
  " s: variable can only be used in a _script_, not in Ex mode
  " and thus not in execute command since it is a shortcut for
  " the Ex mode.
  let s:x = 1
  " Illformed, no s: is allowed.
  execute 'echo s:x'
endfunction

call F()
call X()
call G()
call W()
call L()

" In the default scope of file level is g:.
let x = 0
echo 'default scope is g: ?' x is# g:x ? 'yes' : 'no'

