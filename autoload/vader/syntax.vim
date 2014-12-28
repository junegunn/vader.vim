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

let s:ifs = ['lua', 'perl', 'ruby', 'python']

function! vader#syntax#reset()
  let b:vader_types = {}
endfunction

function! vader#syntax#include(l1, l2)
  let lines = filter(getline(a:l1, a:l2), '!empty(v:val) && v:val[0] != " "')
  for line in lines
    let match = matchlist(line, '^\(Given\|Expect\|Execute\)\s\+\([^:; (]\+\)')
    if len(match) >= 3
      silent! call s:load(match[2])
    endif
  endfor
endfunction

function! vader#syntax#_head()
  return '\(\(^\(Given\|Expect\|Do\|Execute\|Then\|Before\|After\)\(\s\+[^:;(]\+\)\?\s*\((.*)\)\?\s*[:;]\s*$\)\|\(^Include\(\s*(.*)\)\?\s*:\)\)\@='
endfunction

function! s:load(type)
  let b:vader_types = get(b:, 'vader_types', {})
  if has_key(b:vader_types, a:type)
    return
  endif

  if empty(globpath(&rtp, "syntax/".a:type.".vim", 1))
    return
  endif

  let b:vader_types[a:type] = 1

  unlet! b:current_syntax
  execute printf('syn include @%sSnippet syntax/%s.vim', a:type, a:type)
  execute printf('syn region vader_%s start=/^\s\{2,}/ end=/^\S\@=/ contains=@%sSnippet contained', a:type, a:type)
  execute printf('syn region vader_raw_%s start=/\(;\s*$\)\@<=/ end=/%s/ contains=@%sSnippet contained', a:type, vader#syntax#_head(), a:type)

  call s:define_syntax_region('Given', a:type)
  call s:define_syntax_region('Expect', a:type)
  if index(s:ifs, a:type) >= 0
    call s:define_syntax_region('Execute', a:type)
  endif
  let b:current_syntax = 'vader'
endfunction

function! s:define_syntax_region(block, lang)
  execute printf('syn region vader%s start=/^%s\s\+%s\s*\((.*)\)\?\s*:\s*$/ end=/\(^[^ ^#~=*-]\)\@=/ contains=vader%sType,vaderMessage,@vaderIgnored,vader_%s nextgroup=@vaderTopLevel skipempty keepend', a:block, a:block, a:lang, a:block, a:lang)
  execute printf('syn region vader%sRaw start=/^%s\s\+%s\s*\((.*)\)\?\s*;\s*$/ end=/%s/ contains=vader%sType,vaderMessage,@vaderIgnored,vader_raw_%s nextgroup=@vaderTopLevel skipempty keepend', a:block, a:block, a:lang, vader#syntax#_head(), a:block, a:lang)
endfunction

