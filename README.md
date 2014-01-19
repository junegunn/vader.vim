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

Execute block can also be followed by optional Expect block.

```
Execute [(comment)]:
  [vimscript]
```

In Execute block, the following commands are provided.

- Assertions
    - `Assert <boolean expr>, [message]`
    - `AssertEqual <expected>, <got>`
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

" Assuming that plugins are installed under ~/.vim/bundle

" Dependency to vader.vim
set rtp+=~/.vim/bundle/vader.vim

" The plugin under test
set rtp+=~/.vim/bundle/vim-emoji
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

License
-------

MIT
