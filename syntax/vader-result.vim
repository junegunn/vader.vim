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

syntax match vaderResultTitle /^[^:]*/ contains=vaderResultNumber
syntax match vaderResultTitle /^[^:]*:\@=/ contains=vaderResultNumber
syntax match vaderResultTitleRest /\(^[^:]*:\)\@<=.*/ contains=vaderResultNumber
syntax match vaderResultTitle2 /^  [^:]*:\@=/ contains=vaderResultNumber
syntax match vaderResultTitle2Rest /\(^  [^:]*:\)\@<=.*/ contains=vaderResultNumber
syntax match vaderResultNumber /-\?[0-9]\+\(\.[0-9]\+\)\?/ contained
syntax match vaderResultItem /^    [^\]]\+\]\( (X).*\)\?/ contains=vaderResultSequence,vaderResultType,vaderResultError
syntax match vaderResultSequence /^    ([0-9/ ]\+)/ contains=vaderResultNumber contained
syntax match vaderResultType /\[[A-Z ]\+\]/ contained contains=vaderResultDo,vaderResultThen,vaderResultGiven,vaderResultExpect,vaderResultExecute,vaderResultBefore,vaderResultAfter
syntax match vaderResultDiff /^          .*/
syntax match vaderResultDo /DO/ contained
syntax match vaderResultThen /THEN/ contained
syntax match vaderResultGiven /GIVEN/ contained
syntax match vaderResultExpect /EXPECT/ contained
syntax match vaderResultExecute /EXECUTE/ contained
syntax match vaderResultBefore /BEFORE/ contained
syntax match vaderResultAfter /AFTER/ contained
syntax match vaderResultError /(X).*/ contained

syntax match vaderResultExpected /^      - Expected/
syntax match vaderResultGot      /^      - Got/
syntax match vaderResultLog      /^    > .*/ contains=vaderResultLogBullet
syntax match vaderResultLog      /^      > .*/ contains=vaderResultLogBullet
syntax match vaderResultLogBullet /^\s*> / contained

hi def link vaderResultTitle Title
hi def link vaderResultTitle2 Conditional
hi def link vaderResultNumber Number
hi def link vaderResultSequence Label
hi def link vaderResultType Delimiter

hi def link vaderResultGiven Include
hi def link vaderResultDo PreProc
hi def link vaderResultThen Conditional
hi def link vaderResultBefore Special
hi def link vaderResultAfter Special
hi def link vaderResultExecute Statement
hi def link vaderResultExpect Boolean
hi def link vaderResultError Error
hi def link vaderResultDiff None

hi def link vaderResultExpected Conditional
hi def link vaderResultGot Exception
hi def link vaderResultLog String
hi def link vaderResultLogBullet Special

