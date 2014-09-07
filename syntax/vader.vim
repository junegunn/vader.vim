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

if exists("b:current_syntax")
  finish
endif

let s:oisk = &isk

syn clear
syn include @vimSnippet syntax/vim.vim

syn region vaderText    start=/^\s\{2,}/ end=/^\S\@=/ contained
syn region vaderCommand start=/^\s\{2,}/ end=/^\S\@=/ contains=@vimSnippet contained

syn match vaderMessage /(\@<=.*)\@=/ contained contains=Todo
syn match vaderGivenType /\(Given\s*\)\@<=[^()\s]\+/ contained
syn match vaderExpectType /\(Expect\s*\)\@<=[^()\s]\+/ contained
syn match vaderExecuteType /\(Execute\s*\)\@<=[^()\s]\+/ contained

syn match vaderComment /^["#].*/ contains=Todo
syn match vaderSepCaret /^^.*/ contains=Todo
syn match vaderSepTilde /^\~.*/ contains=Todo
syn match vaderSepDouble /^=.*/ contains=Todo
syn match vaderSepSingle /^-.*/ contains=Todo
syn match vaderSepAsterisk /^\*.*/ contains=Todo
syn cluster vaderIgnored contains=vaderComment,vaderSepCaret,vaderSepTilde,vaderSepDouble,vaderSepSingle,vaderSepAsterisk

syn region vaderGiven   start=/^Given\(\s*(.*)\)\?\s*:/   end=/\(^[^ ^#~=*-]\)\@=/ contains=vaderMessage,vaderText,@vaderIgnored nextgroup=@vaderTopLevel skipempty
syn region vaderExpect  start=/^Expect\(\s*(.*)\)\?\s*:/  end=/\(^[^ ^#~=*-]\)\@=/ contains=vaderMessage,vaderText,@vaderIgnored nextgroup=@vaderTopLevel skipempty
syn region vaderDo      start=/^Do\(\s*(.*)\)\?\s*:/      end=/\(^[^ ^#~=*-]\)\@=/ contains=vaderMessage,vaderCommand,@vaderIgnored nextgroup=@vaderTopLevel skipempty
syn region vaderExecute start=/^Execute\(\s*(.*)\)\?\s*:/ end=/\(^[^ ^#~=*-]\)\@=/ contains=vaderMessage,vaderCommand,@vaderIgnored nextgroup=@vaderTopLevel skipempty
syn region vaderBefore  start=/^Before\(\s*(.*)\)\?\s*:/  end=/\(^[^ ^#~=*-]\)\@=/ contains=vaderMessage,vaderCommand,@vaderIgnored nextgroup=@vaderTopLevel skipempty
syn region vaderAfter   start=/^After\(\s*(.*)\)\?\s*:/   end=/\(^[^ ^#~=*-]\)\@=/ contains=vaderMessage,vaderCommand,@vaderIgnored nextgroup=@vaderTopLevel skipempty
syn match vaderInclude /^Include\(\s*(.*)\)\?\s*:/ contains=vaderMessage
syn cluster vaderTopLevel contains=vaderGiven,vaderExpect,vaderDo,vaderExpect,vaderBefore,vaderAfter,vaderInclude

syn keyword Todo TODO FIXME XXX TBD

hi def link vaderInclude     Repeat
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
hi def link vaderText        String
hi def link vaderComment     Comment
hi def link vaderSepCaret    Error
hi def link vaderSepTilde    Debug
hi def link vaderSepDouble   Label
hi def link vaderSepSingle   Label
hi def link vaderSepAsterisk Exception

let b:current_syntax = 'vader'
call vader#syntax#reset()
call vader#syntax#include(1, '$')

let &isk = s:oisk

