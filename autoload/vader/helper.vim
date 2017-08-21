function! vader#helper#syntax_at(...)
  syntax sync fromstart
  if a:0 < 2
    let l:pos = getpos('.')
    let l:cur_lnum = pos[1]
    let l:cur_col = pos[2]
    if a:0 == 0
      let l:lnum = l:cur_lnum
      let l:col = l:cur_col
    else
      let l:lnum = l:cur_lnum
      let l:col = a:1
    endif
  else
    let l:lnum = a:1
    let l:col = a:2
  endif
  call map(synstack(l:lnum, l:col), 'synIDattr(v:val, "name")')
  return synIDattr(synID(l:lnum, l:col, 1), 'name')
endfunction

function! vader#helper#syntax_of(pattern, ...)
  if a:0 < 1
    let l:nth = 1
  else
    let l:nth = a:1
  endif

  let l:pos_init = getpos('.')
  call cursor(1, 1)
  let found = search(a:pattern, 'cW')
  while found != 0 && nth > 1
    let found = search(a:pattern, 'W')
    let nth -= 1
  endwhile

  if found
    let l:pos = getpos('.')
    let l:output = vader#helper#syntax_at(l:pos[1], l:pos[2])
  else
    let l:output = ''
  endif
  call setpos('.', l:pos_init)
  return l:output
endfunction
