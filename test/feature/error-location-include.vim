function! VaderTestIncludedFunction(error) abort
  " some comment for offset
  throw a:error
endfunction

if !empty(get(g:, 'vader_test_throw'))
  " some comment for offset
  throw g:vader_test_throw
endif
