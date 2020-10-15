# linux_config_files

This is how I keep all my configuration files synched across machines. It was
inspired by a blog post (see pdf in this repository)

## To make this work

1) Clone this repository into your home directory (you should then have a
linux_config_files directory):

```shell
git clone https://github.com/Matt-A-Bennett/linux_config_files.git
```

2) (Optional, but recommended!) Make a backup of your .bashrc, .inputrc, and
any other configuration files that you plan to keep synched across machines:
```shell
cd ~/
mv .bashrc .old_bashrc
mv .inputrc .old_inputrc
mv .vimrc .old_vimrc
mv .tmux.conf .tmux.old_conf
```

3) Replace .bashrc, .inputrc, and any other configuration files that you want
to keep synched across machines with symbolic links from your /home/user
directory like so:

```shell
cd ~/
ln -s ~/linux_config_files/multihost_bashrc/base_bashrc .bashrc
ln -s ~/linux_config_files/.inputrc .inputrc
ln -s ~/linux_config_files/.vimrc .vimrc
ln -s ~/linux_config_files/.tmux.conf .tmux.conf
```

### Ultisnips
I use [Ultisnips](https://github.com/SirVer/ultisnips) in my .vimrc, which
stores the snippets in ~/.vim/ultisnips 

In order to keep my .snippets files synched across machines, I keep my ultisnip
directory in the ~/linux_config_files and create a symbolic link to it from
~/.vim/ultsnips

```shell
cd ~/.vim && ln -sd ~/linux_config_files/ultisnips ultisnips
```
### FZF
I [fzf](https://github.com/junegunn/fzf) both as a command line tool and from
within Vim using [this vim plugin](https://github.com/junegunn/fzf.vim). I
configured it to use
[silverseacher-ag](https://github.com/ggreer/the_silver_searcher) in order to
respect .gitignore files. 

Being able to ignore specific files and directories is nice not only in git
repositories, but across everything in my home directory. To achieve this, your
home directory must not be a git repository, but I don't think anyone does
that...

I created a .git directory and a .gitignore file in my home directory. The
.gitignore file should be symbolically linked to a file in the
linux_config_files repository as above. The only difference is that the file
that it links to can't itself be called '.gitignore', since there is (or might
one day) already exist the 'real .gitignore' associated with the
linux_config_files repository! So I call it fzfhome_gitignore instead.

```shell
cd ~/
mkdir .git
ln -s ~/linux_config_files/fzfhome_gitignore .gitignore
```

Then in your .bashrc, add the following line (already added for this
repository):
```shell
export FZF_DEFAULT_COMAND='ag --hidden --ignore .git ""'
```
