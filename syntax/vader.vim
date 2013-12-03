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

if exists("b:current_syntax")
  finish
endif

let s:oisk = &isk

syn clear
syn include @vimSnippet syntax/vim.vim

syn region vaderText    start=/^\s\{2,}/ end=/^\S\@=/
syn region vaderCommand start=/^\s\{2,}/ end=/^\S\@=/ contains=@vimSnippet

syn match vaderGiven   /^Given\(\s*(.*)\s*\)\?:/        contains=vaderMessage nextgroup=vaderText skipempty
syn match vaderExpect  /^Expect\(\s*(.*)\s*\)\?:/       contains=vaderMessage nextgroup=vaderText skipempty
syn match vaderDo      /^Do\(\s*(.*)\s*\)\?:/           contains=vaderMessage nextgroup=vaderCommand skipempty
syn match vaderExecute /^Execute\(\s*(.*)\s*\)\?:/      contains=vaderMessage nextgroup=vaderCommand skipempty
syn match vaderBefore  /^Before\(\s*(.*)\s*\)\?:/       contains=vaderMessage nextgroup=vaderCommand skipempty
syn match vaderAfter   /^After\(\s*(.*)\s*\)\?:/        contains=vaderMessage nextgroup=vaderCommand skipempty

let s:ifs = ['lua', 'perl', 'ruby', 'python']
let s:langs = get(g:, 'vader_types',
  \ ['lua', 'perl', 'ruby', 'python', 'java', 'c', 'cpp', 'javascript', 'yaml', 'html', 'css', 'clojure', 'sh', 'tex'])
for lang in s:langs
  silent! unlet b:current_syntax
  execute printf('syn include @%sSnippet syntax/%s.vim', lang, lang)
  execute printf('syn region vader_%s start=/^\s\{2,}/ end=/^\(\s\?\S\)\@=/ contains=@%sSnippet', lang, lang)
  execute printf('syn match vaderGiven /^Given\s*%s\s*\((.*)\)\?\s*:/ contains=vaderGivenType,vaderMessage nextgroup=vader_%s skipempty', lang, lang)
  execute printf('syn match vaderExpect /^Expect\s*%s\s*\((.*)\)\?\s*:/ contains=vaderExpectType,vaderMessage nextgroup=vader_%s skipempty', lang, lang)
  if index(s:ifs, lang) >= 0
    execute printf('syn match vaderExecute /^Execute\s*%s\s*\((.*)\)\?\s*:/ contains=vaderExecuteType,vaderMessage nextgroup=vader_%s skipempty', lang, lang)
  endif
endfor

syn match vaderGivenType /\(Given\s*\)\@<=[^()\s]\+/ contained
syn match vaderExpectType /\(Expect\s*\)\@<=[^()\s]\+/ contained
syn match vaderExecuteType /\(Execute\s*\)\@<=[^()\s]\+/ contained

syn match vaderMessage /(\@<=.*)\@=/ contained contains=Todo
syn match vaderComment /^#.*/ contains=Todo

syn keyword Todo TODO FIXME XXX TBD

hi def link vaderGiven       Include
hi def link vaderBefore      Special
hi def link vaderAfter       Special
hi def link vaderDo          PreProc
hi def link vaderExecute     Statement
hi def link vaderExecuteType Identifier
hi def link vaderMessage     Title
hi def link vaderExpect      Boolean
hi def link vaderGivenType   Identifier
hi def link vaderExpectType  Identifier
hi def link vaderComment     Comment

hi def link vaderText String

let b:current_syntax = 'vader'

let &isk = s:oisk

