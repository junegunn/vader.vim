vader.vim
=========

I use Vader to test Vimscript.

### Vader test cases
![](https://raw.github.com/junegunn/i/master/vader.png)

### Vader result
![](https://raw.github.com/junegunn/i/master/vader-result.png)

Installation
------------

Use your favorite plugin manager.

- [Pathogen](https://github.com/tpope/vim-pathogen)
  - `git clone https://github.com/junegunn/vader.vim.git ~/.vim/bundle/vader.vim`
- [Vundle](https://github.com/gmarik/vundle)
  1. Add `Bundle 'junegunn/vader.vim'` to .vimrc
  2. Run `:BundleInstall`
- [NeoBundle](https://github.com/Shougo/neobundle.vim)
  1. Add `NeoBundle 'junegunn/vader.vim'` to .vimrc
  2. Run `:NeoBundleInstall`
- [vim-plug](https://github.com/junegunn/vim-plug)
  1. Add `Plug 'junegunn/vader.vim'` to .vimrc
  2. Run `:PlugInstall`

Running Vader tests
-------------------

- `Vader  [file glob ...]`
- `Vader! [file glob ...]`
    - Exit Vim after running the tests with exit status of 0 or 1
        - `vim '+Vader!*' && echo Success || echo Failure`

Syntax of .vader file
---------------------

A Vader file is a flat sequence of blocks each of which starts with the block
label, such as `Execute:`, followed by the content of the block indented by 2
spaces.

- Given
    - Content to fill the execution buffer
- Do
    - Normal-mode keystrokes that can span multiple lines
- Execute
    - Vimscript to execute
- Expect
    - Expected result of the preceding Do/Execute block
- Before
    - Vimscript to run before each test case
- After
    - Vimscript to run after each test case

### Basic blocks

#### Given

The content of a Given block is pasted into the "workbench buffer" for the
subsequent Do/Execute blocks. If `filetype` parameter is given, `&filetype` of
the buffer is set accordingly. It is also used to syntax-highlight the block in
.vader file.

```
Given [filetype] [(comment)]:
  [input text]
```

#### Do

The content of a Do block is a sequence of normal-mode keystrokes that can
freely span multiple lines. A special key can be written in its name surrounded
by angle brackets preceded by a backslash (e.g. `\<Enter>`).

Do block can be followed by an optional Expect block.

```
Do [(comment)]:
  [keystrokes]
```

#### Execute

The content of an Execute block is plain Vimscript to be executed.

Execute block can also be followed by an optional Expect block.

```
Execute [(comment)]:
  [vimscript]
```

In Execute block, the following commands are provided.

- Assertions
    - `Assert <boolean expr>, [message]`
    - `AssertEqual <expected>, <got>`
    - `AssertNotEqual <unexpected>, <got>`
    - `AssertThrows <expr>`
- Other commands
    - `Log "Message"`
    - `Save <name>[, ...]`
    - `Restore [<name>, ...]`

And the path of the current .vader file can be accessed via `g:vader_file`.

In addition to plain Vimscript, you can also test Ruby/Python/Perl/Lua interface
with Execute block as follows:

```
Execute [lang] [(comment)]:
  [<lang> code]
```

See Ruby and Python examples
[here](https://github.com/junegunn/vader.vim/blob/master/example/lang_if.vader).

#### Expect

If an Expect block follows an Execute block or a Do block, the result of the
preceding block is compared to the content of the Expect block. Comparison is
case-sensitive. `filetype` parameter is used to syntax-highlight the block.

```
Expect [filetype] [(comment)]:
  [expected output]
```

### Hooks

#### Before

The content of a Before block is executed before every following
Do/Execute block.

```
Before [(comment)]:
  [vim script]
```

#### After

The content of an After block is executed after every following
Do/Execute block.

```
After [(comment)]:
  [vim script]
```

### Macros

#### Include

You can include other vader files using Include macro.

```
Include: setup.vader

# ...

Include: cleanup.vader
```

### Comments

Any line that starts with `#`, `=`, `-`, `~`, `^`, or `*` without indentation is
considered to be a comment and simply ignored.

    #################
    # Typical comment
    #################

    Given (fixture):
    ================
      Hello

    Do (modification):
    ------------------
    * change inner word
      ciw
    * to
      World

    Expect (result):
    ~~~~~~~~~~~~~~~~
      World

### Example

```
# Test case
Execute (test assertion):
  %d
  Assert 1 == line('$')

  setf python
  AssertEqual 'python', &filetype

Given ruby (some ruby code):
  def a
    a = 1
    end

Do (indent the block):
  vip=

Expect ruby (indented block):
  def a
    a = 1
  end

Do (indent and shift):
  vip=
  gv>

Expect ruby (indented and shifted):
    def a
      a = 1
    end
```

Setting up isolated testing environment
---------------------------------------

When you test a plugin, it's generally a good idea to setup a testing
environment that is isolated from the other plugins and settings irrelevant to
the test. The simplest way to achieve this is to write a minimal .vimrc such as
follows and start a clean Vim process with it.

```vim
set nocompatible
filetype off

" Assuming that plugins are installed under ~/.vim/bundle

" Dependency to vader.vim
set rtp^=~/.vim/bundle/vader.vim

" The plugin under test
set rtp^=~/.vim/bundle/vim-markdown
set rtp+=~/.vim/bundle/vim-markdown/after

" Enable loading plugins and indent files for specific file types
filetype plugin indent on
```

Then you can start Vim process with the configuration file and run Vader tests.

```sh
vim -u mini-vimrc +Vader*
```

Consider writing a script to further automate the process. You may refer to
[the one from easy-align](https://github.com/junegunn/vim-easy-align/blob/master/test/run).


Real-life examples
------------------

- [vim-emoji](https://github.com/junegunn/vim-emoji/tree/master/test)
- [seoul256.vim](https://github.com/junegunn/seoul256.vim/tree/master/test)
- [vim-easy-align](https://github.com/junegunn/vim-easy-align/tree/master/test)
- [vim-sneak](https://github.com/justinmk/vim-sneak/tree/master/tests)
- [simplenote.vim](https://github.com/mrtazz/simplenote.vim/tree/master/tests)

Known issues
------------

### feedkeys() cannot be tested

The keystrokes given to the feedkeys() function are consumed only after Vader
finishes executing the content of the Do/Execute block. Take the following case
as an example:

```vim
Do (Test feedkeys() function):
  i123
  \<C-O>:call feedkeys('456')\<CR>
  789

Expect (Wrong!):
  123456789
```

You may have expected `123456789`, but the result is `123789456`. Unfortunately
I have yet to find a workaround for this problem. Please let me know if you find
one.

### Some events may not be triggered

[It is reported](https://github.com/junegunn/vader.vim/issues/2) that
CursorMoved event is not triggered inside a Do block. If you need to test a
feature that involves autocommands on CursorMoved event, you have to manually
invoke it in the middle of the block using `:doautocmd`.

```vim
Do (Using doautocmd):
  jjj
  :doautocmd CursorMoved\<CR>
```

### Search history may not be correctly updated

This is likely a bug of Vim itself. For some reason, search history is not
correctly updated when searches are performed inside a Do block. The following
test scenario fails due to this problem.

```vim
Execute (Clear search history):
  for _ in range(&history)
    call histdel('/', -1)
  endfor

Given (Search and destroy):
  I'm a street walking cheetah with a heart full of napalm
  I'm a runaway son of the nuclear A-bomb
  I'm a world's forgotten boy
  The one who searches and destroys

Do (Searches):
  /street\<CR>
  /walking\<CR>
  /cheetah\<CR>
  /runaway\<CR>
  /search\<CR>

Execute (Assertions):
  Log string(map(range(1, &history), 'histget("/", - v:val)'))
  AssertEqual 'runaway', histget('/', -2)
  AssertEqual 'search', histget('/', -1)
```

The result is given as follows:

```vim
Starting Vader: 1 suite(s), 3 case(s)
  Starting Vader: /Users/jg/.vim/plugged/vader.vim/search-and-destroy.vader
    (1/3) [EXECUTE] Clear search history
    (2/3) [  GIVEN] Search and destroy
    (2/3) [     DO] Searches
    (3/3) [  GIVEN] Search and destroy
    (3/3) [EXECUTE] Assertions
      > ['search', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '']
    (3/3) [EXECUTE] (X) Assertion failure: 'runaway' != ''
  Success/Total: 2/3
Success/Total: 2/3 (assertions: 0/1)
Elapsed time: 0.366118 sec.
```

License
-------

MIT
