function! VaderTestIncludedFunction(error) abort
  throw a:error
endfunction

if !empty(get(g:, 'vader_test_throw'))
  throw g:vader_test_throw
endif
