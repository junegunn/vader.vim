let s:regex_block_header  = '^\('
let s:regex_block_header .=   'Given\|Do\|Execute\|Then\|Expect\|Before\|After'
let s:regex_block_header .= '\)'
let s:regex_block_header .= '\s\+'
let s:regex_block_header .= '\w*'
let s:regex_block_header .= '\s*'
let s:regex_block_header .= '\%(([^()]\+)\)\?'
let s:regex_block_header .= '[:;]'
let s:regex_block_header .= '\s*'

""
" Foldexpression for vader files.
"
" This foldexpression folds the contents of all blocks.
" The actual block headings are /not/ part of the fold to benefit from the
" syntax highlighting, which is lost otherwise.
function! vader#folding#foldExpr(lnum) abort
  " each block header is level 0
  if getline(a:lnum)     =~# s:regex_block_header
    return 0
  endif

  " the content after each block header starts a new level 1 fold
  if getline(a:lnum - 1) =~# s:regex_block_header
    return '>1'
  endif

  " empty lines at the end of a block are not considered being part of the
  " block and therefore not part of the fold
  if getline(a:lnum) !~# '^\s*$'
        \ && getline(nextnonblank(a:lnum + 1)) =~# s:regex_block_header
    return 's1'
  endif

  " all other lines don't change the fold level
  return '='
endfunction

