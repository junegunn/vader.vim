vader.vim
=========

```
                        _--~~| |~~--_
                       /     | |   \ \
                      |      |      | |
                     |       | |       |
                     |       |         |
                    /__----_ | | _----__\
                   |/_-~~~-_\| |/_-~~~-_\|
                   //    #  \===/    #  \\
                  //        |===|        \\
                 / |________|/~\|________| \
                /  \        |___|        /  \
               /   ^\      /| | |\      /^   \
              /     ^\   /| | | | |\   /^     \
             /       ^\/| | | | | | |\/^       \
            <          O|_|_|_|_|_|_|O          >
             ~\        \   -------   /        /~
               ~\       ~\ \_____/ /~       /~
                 ~\       ^-_____-^       /~
           _________>                   <__________
/~~~~~~~~~~                                        ~~~~~~~~~~~\
```

> I use Vader to test Vimscript.

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

Syntax of .vader file
---------------------

### Given

```
Given [filetype] [(comment)]:
  [input text]
```

### Execute

```
Execute [(comment)]:
  [commands]
```

#### Assertions

- `Assert <boolean expr>`
- `AssertEqual <expected>, <got>`

### Do

```
Do [(comment)]:
  [keystrokes]
```

### Expect

```
Expect [filetype] [(comment)]:
  [expected output]
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
  vip
  =

Expect ruby (indented block):
  def a
    a = 1
  end

Do (indent and shift):
  vip
  =
  gv
  >

Expect ruby (indented and shifted):
    def a
      a = 1
    end
```

Commands
--------

- `Vader  [file glob...]`
- `Vader! [file glob...]`
    - Exit Vim after running the tests with exit status of 0 or 1
        - `vim +'Vader!*'`

Real-life example
-----------------

- [Test cases for vim-easy-align](https://github.com/junegunn/vim-easy-align/tree/master/test)
- [Test cases for vim-emoji](https://github.com/junegunn/vim-emoji/tree/master/test)

License
-------

MIT
