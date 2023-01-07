# WHAT'S THIS?
# ====================================================

# An   experiment   to   see   if   I   could   create
# a   Nix   expression   for   `nix-shell`   from   my
# `configuration.nix` on NixOS. Not perfect, but it is
# just one file that works without having to mess with
# Home Manager or other Nix  setup files on any distro
# where Nix can be installed.

# ----------------------------------------------------

# NOTE Why the `wrapper`? {{-

# The `wrapper` shenanigans is  used to convey the Nix
# expression's semantics in different context:
#
# + SHELL:
#   Calling   `nix-shell`   without  arguments
#   means  that  we  are  fine  with  whatever
#   Nixpkgs   version  is   set  in   the  Nix
#   shell expression,  but supplying  a commit
#   hash   (using   `nix-shell  --arg   commit
#   '"<hash>"'`)  means that  we  want to  pin
#   Nixpkgs to that specific commit.
#
# + NIX SHELL EXPRESSION:
#   The `commit`  argument is really  either a
#   string  or  an  attribute set  (i.e.,  the
#   Nixpkgs  package set),  and  wanted to  be
#   clear about this as  there are no types in
#   Nix.  (Talking  about clarity,  a  comment
#   would have probably sufficed...)

# ASIDE: wrapper: `let .. in ..` vs `() {}`
# ====================================================
# Could have used  the latter too, and  only chose the
# former  because it  looked more  Nix-y (albeit  more
# verbose). With the parentheses:
#
#    { commit ? import <nixpkgs> {} }:
#
#    (
#      { maybeNixpkgsCommit }:
#
#      let
#        pkgs = ...
#      in
#        pkgs.mkShell {
#          ...
#        }
#    ) { maybeNixpkgsCommit = commit; }

# }}-

{ commit ? import <nixpkgs> {} }:

let
  wrapper =
    { maybeNixpkgsCommit }:

    let
      pkgs =
        if ( builtins.isString maybeNixpkgsCommit )
        then import (builtins.fetchTarball "https://github.com/NixOS/nixpkgs/tarball/${maybeNixpkgsCommit}") {}
        else maybeNixpkgsCommit
      ;
      myVim =
        pkgs.vim_configurable.customize {

          vimrcConfig.customRC =
          # {{-
          ''
            syntax on
            " colorscheme wombat256mod
            set background=dark
            let g:gruvbox_contrast_dark = 'hard'
            colorscheme gruvbox

            set encoding=utf-8
            set noequalalways
            set foldlevelstart=99
            set foldtext=substitute(getline(v:foldstart),'/\\*\\\|\\*/\\\|{{{\\d\\=',''\'','g')
            set modeline
            set autoindent expandtab smarttab
            set shiftround
            set nocompatible
            set cursorline
            " set list
            set number
            set relativenumber
            set incsearch hlsearch
            " set showcmd
            set laststatus=2
            set backspace=indent,eol,start
            set wildmenu
            set autoread
            set history=5000
            set noswapfile
            set fillchars="vert:|,fold: "
            set showmatch
            set matchtime=2
            set hidden
            set listchars=tab:⇥\ ,trail:␣,extends:⇉,precedes:⇇,nbsp:·,eol:¬,space:␣
            set ignorecase
            set smartcase

            autocmd FileType erl setlocal ts=4 sw=4 sts=4 et

            " https://vi.stackexchange.com/questions/6/how-can-i-use-the-undofile
            if !isdirectory($HOME."/.vim")
                call mkdir($HOME."/.vim", "", 0770)
            endif
            if !isdirectory($HOME."/.vim/undo-dir")
                call mkdir($HOME."/.vim/undo-dir", "", 0700)
            endif
            set undodir=~/.vim/undo-dir
            set undofile

            " TODO airline-ify
            " set statusline=   " clear the statusline for when vimrc is reloaded
            " set statusline+=[%-6{fugitive#head()}]
            " set statusline+=%f\                          " file name
            " set statusline+=[%2{strlen(&ft)?&ft:'none'},  " filetype
            " set statusline+=%2{strlen(&fenc)?&fenc:&enc}, " encoding
            " set statusline+=%2{&fileformat}]              " file format
            " set statusline+=[%L\,r%l,c%c]            " [total lines,row,column]
            " set statusline+=[b%n,                      " buffer number
            " " window number, alternate file in which window (-1 = not visible)
            " set statusline+=w%{winnr()}]
            " set statusline+=%h%m%r%w                     " flags

            " === Scripts   {{{1
            " ===========

            " _$ - Strip trailing whitespace {{{2
            nnoremap _$ :call Preserve("%s/\\s\\+$//e")<CR>
            function! Preserve(command)
              " Preparation: save last search, and cursor position.
              let _s=@/
              let l = line(".")
              let c = col(".")
              " Do the business:
              execute a:command
              " Clean up: restore previous search history, and cursor position
              let @/=_s
              call cursor(l, c)
            endfunction

            " MakeDirsAndSaveFile (:M) {{{2

            " Created to be able to save a file opened with :edit where the path
            " contains directories that do not exist yet. This script will create
            " them and if they exist, `mkdir` will run without throwing an error.

            command! M :call MakeDirsAndSaveFile()
            " https://stackoverflow.com/questions/12625091/how-to-understand-this-vim-script
            " or
            " :h eval.txt
            " :h :fu
            function! MakeDirsAndSaveFile()
              " https://vi.stackexchange.com/questions/1942/how-to-execute-shell-commands-silently
              :silent !mkdir -p %:h
              :redraw!
              " ----------------------------------------------------------------------------------
              :write
            endfunction

            " === Key mappings    {{{1
            " ================

            " Auto-close mappings {{{2
            " https://stackoverflow.com/a/34992101/1498178
            inoremap <leader>" ""<left>
            inoremap ` ``<left>
            inoremap <leader>' ''\''<left>
            inoremap <leader>( ()<left>
            inoremap <leader>[ []<left>
            inoremap <leader>{ {}<left>
            inoremap <leader>{<CR> {<CR>}<ESC>O
            autocmd FileType nix inoremap {<CR> {<CR>};<ESC>O

            " 44 instead of <C-^> {{{2
            nnoremap 44 <C-^>
            " 99 instead of <C-w>w {{{2
            nnoremap 99 <C-w>w

            " \yy - copy entire buffer to system clipboard {{{2
            nnoremap <leader>yy :%yank +<CR>

            " \ys - copy entire buffer to * {{{2
            nnoremap <leader>ys :%yank *<CR>

            " vil - inner line {{{2
            nnoremap vil ^vg_

            " <Leader>l - change working dir for current window only {{{2
            nnoremap <Leader>l :lcd %:p:h<CR>:pwd<CR>

            " <Space> instead of 'za' (unfold the actual fold) {{{2
            nnoremap <Space> za

            " <Leader>J Like gJ, but always remove spaces {{{2
            fun! JoinSpaceless()
                execute 'normal gJ'

                " Character under cursor is whitespace?
                if matchstr(getline('.'), '\%' . col('.') . 'c.') =~ '\s'
                    " When remove it!
                    execute 'normal dw'
                endif
            endfun
            nnoremap <Leader>J :call JoinSpaceless()<CR>

            " in NORMAL mode CTRL-j splits line at cursor {{{2
            nnoremap <NL> i<CR><ESC>

            " <C-p> and <C-n> instead of <Up>,<Down> on command line {{{2
            cnoremap <C-p> <Up>
            cnoremap <C-n> <Down>

            " {visual}* search {{{2
            xnoremap * :<C-u>call <SID>VSetSearch()<CR>/<C-R>=@/<CR><CR>
            xnoremap # :<C-u>call <SID>VSetSearch()<CR>?<C-R>=@/<CR><CR>
            function! s:VSetSearch()
              let temp = @s
              norm! gv"sy
              let @/ = '\V' . substitute(escape(@s, '/\'), '\n', '\\n', 'g')
              let @s = temp
            endfunction

            "gp - http://vim.wikia.com/wiki/Selecting_your_pasted_text
            nnoremap <expr> gp '`[' . strpart(getregtype(), 0, 1) . '`]'

            " === Plugin configuration   {{{1
            " ========================

            " peekaboo {{{2
            let g:peekaboo_window = 'belowright 30new'

            " airline {{{2
            let g:airline_theme='distinguished'
            " vim-airline was overwriting vim-bufferline settings
            " but this prevents it. See bufferline settings below.
            let g:airline#extensions#bufferline#overwrite_variables = 0

            " fzf-vim {{{2
            nnoremap <leader><C-n> :History:<CR>
            nnoremap <leader><C-m> :History/<CR>
            nnoremap <leader><C-o> :Files<CR>
            nnoremap <leader><C-l> :Lines<CR>
            nnoremap <leader><C-r> :BLines<CR>
            nnoremap <leader><C-k> :Buffers<CR>
            nnoremap <leader><C-j> :Ag<CR>
            nnoremap <leader><C-w> :Windows<CR>
            nnoremap <leader><C-g> :Commits<CR>
            nnoremap <leader><C-p> :BCommits<CR>
            nnoremap <leader><C-h> :History<CR>
            nnoremap <leader><C-u> :Marks<CR>
            nnoremap <leader><C-i> :BD<CR>
            imap <c-x><c-l> <plug>(fzf-complete-line)

            " https://github.com/junegunn/fzf.vim/pull/733#issuecomment-559720813
            " (modification: added bang (!) at the end of `bwipeout`
            function! s:list_buffers()
              redir => list
              silent ls
              redir END
              return split(list, "\n")
            endfunction

            function! s:delete_buffers(lines)
              execute 'bwipeout!' join(map(a:lines, {_, line -> split(line)[0]}))
            endfunction

            command! BD call fzf#run(fzf#wrap({
              \ 'source': s:list_buffers(),
              \ 'sink*': { lines -> s:delete_buffers(lines) },
              \ 'options': '--multi --reverse --bind ctrl-a:select-all+accept'
            \ }))

            " bufferline {{{2
            let g:bufferline_active_buffer_left = '['
            let g:bufferline_active_buffer_right = ']'
            let g:bufferline_fname_mod = ':.'
            let g:bufferline_pathshorten = 1
            let g:bufferline_rotate = 1

            " UndoTree {{{2
            let g:undotree_ShortIndicators = 1
            let g:undotree_CustomUndotreeCmd = 'vertical 32 new'
            let g:undotree_CustomDiffpanelCmd= 'belowright 12 new'

            " Goyo {{{2

            let g:goyo_width = 104

            function! s:goyo_enter()
              Limelight0.4
              UndotreeToggle
              " ...
            endfunction

            function! s:goyo_leave()
              Limelight!
              UndotreeToggle
              " ...
            endfunction

            autocmd! User GoyoEnter nested call <SID>goyo_enter()
            autocmd! User GoyoLeave nested call <SID>goyo_leave()

            " FastFold {{{2
            let g:markdown_folding = 1

            " netrw {{{2
            let g:netrw_winsize   = 30
            let g:netrw_liststyle = 3
          ''; # }}-

        vimrcConfig.packages.myVimPackage = with pkgs.vimPlugins; {
          # loaded on launch
          start =
          [ # {{-
            commentary
            fugitive
            fzf-vim
            goyo
            limelight-vim
            repeat
            # seoul256
            surround
            tabular
            undotree
            # vim-peekaboo
            # Consider using fugitive's `:Gdiff :0` instead
            # see https://stackoverflow.com/questions/15369499/how-can-i-view-git-diff-for-any-commit-using-vim-fugitive
            # vim-signify
            vim-unimpaired
            vim-vinegar
            wombat256
            fastfold
            vim-airline
            vim-airline-themes
            vim-bufferline
            vim-elixir
            vim-obsession
            vim-ragtag
            vim-erlang-runtime
            gruvbox-community
          ]; # }}-

          # manually loadable by calling `:packadd $plugin-name`
          # however, if a Vim plugin has a dependency that is not explicitly listed in
          # opt that dependency will always be added to start to avoid confusion.
          opt = [
          ];
          # To automatically load a plugin when opening a filetype, add vimrc lines like:
          # autocmd FileType php :packadd phpCompletion
        };
      };
    in
      pkgs.mkShell {
        buildInputs =
        # Packages that work both on Linux and Mac
        [
          myVim
          pkgs.elixir
          pkgs.erlang
          pkgs.tmux
          pkgs.tree
          # TODO figure out how to configure it like VIM
          # https://discourse.nixos.org/t/is-it-possible-to-change-the-default-git-user-config-for-a-devshell/17612/7
          pkgs.git
          # Needed for Git (see Git config below (search for `git.conf`)
          pkgs.delta
          pkgs.silver-searcher
          pkgs.ffmpeg
          pkgs.fzf
          pkgs.mc
          pkgs.rclone
          pkgs.curl
          pkgs.openssh
          # needed for `curl`; otherwise error 77 is thrown
          # see more at https://github.com/NixOS/nixpkgs/issues/66716
          pkgs.cacert
          # not sure about this one but can't hurt
          pkgs.libxml2
          pkgs.par
          pkgs.which
          pkgs.less
        ]
        # Packages that only work on Linux
        ++ pkgs.lib.optionals
             pkgs.stdenv.isLinux
             [
               # For file_system on Linux.
               pkgs.inotify-tools
               # pkgs.busybox
             ]
        # Packages that only work on Mac
        ++ pkgs.lib.optionals
             pkgs.stdenv.isDarwin
             (with pkgs.darwin.apple_sdk.frameworks;
               [
                 # For file_system on macOS.
                 CoreFoundation
                 CoreServices
               ]
             );

        # ENVIRONMENT VARIABLES VS SHELL VARIABLES
        # ----------------------------------------------------
        # Variables  defined   outside  `shellHook`   will  be
        # exported   implicitly,   thus   become   environment
        # variables. Opted to include environment variables to
        # be added here before `shellHook` in case any of them
        # are also needed there.

        # QUESTION Why bother adding stuff outside `shellHook`?
        #          Anything could  be added in there,  and then
        #          use `export` to  convert them to environment
        #          variables.
        #
        # ANSWER: See next section.

        # locale preservation (and notes) {{-
        # ====================================================

        # Without  this, almost  everything  fails with  locale issues  when
        # using `nix-shell --pure` (at least on NixOS).
        # See
        # + https://github.com/NixOS/nix/issues/318#issuecomment-52986702
        # + http://lists.linuxfromscratch.org/pipermail/lfs-support/2004-June/023900.html
        #
        # ( Also, this  variable needs  to be  here and  not in
        #   `shellHook`,  not only  because  it needs  to be  an
        #   environment variable, but also  because its value is
        #   determined by a Nix  expression. Although that could
        #   have been worked around with quotes and concat (++),
        #   this is just cleaner (for now).
        # )

        LOCALE_ARCHIVE =
          if pkgs.stdenv.isLinux
            then "${pkgs.glibcLocales}/lib/locale/locale-archive"
            else ""
        ;

        # The LOCALE_ARCHIVE  only ensure that `locale`  is in
        # scope  (I think),  but if  one wants  their specific
        # locale settings  to be available (or  preserve them,
        # if on  the same system)  instead of falling  back to
        # POSIX  (which  will  happen  when  using  `nix-shell
        # --pure`), then
        # 1. Issue the `locale` command
        # 2. insert the output here:

        LANG="en_US.UTF-8";
        LC_CTYPE="en_US.UTF-8";
        LC_NUMERIC="en_US.UTF-8";
        LC_TIME="en_US.UTF-8";
        LC_COLLATE="en_US.UTF-8";
        LC_MONETARY="en_US.UTF-8";
        LC_MESSAGES="en_US.UTF-8";
        LC_PAPER="en_US.UTF-8";
        LC_NAME="en_US.UTF-8";
        LC_ADDRESS="en_US.UTF-8";
        LC_TELEPHONE="en_US.UTF-8";
        LC_MEASUREMENT="en_US.UTF-8";
        LC_IDENTIFICATION="en_US.UTF-8";

        # }}-

        # https://discourse.nixos.org/t/is-it-possible-to-change-the-default-git-user-config-for-a-devshell/17612

        GIT_CONFIG_GLOBAL =
          # QUESTION
          # `gitConfig` is a derivation (i.e., a `.drv` file) at
          # this  point, and  it is  provided to  an environment
          # variable,  so  I presume  it  will  be built  first,
          # right?
          pkgs.writeText # {{-
            "git.conf"
            ''
            [alias]
                    br = "branch"
                    ci = "commit"
                    co = "checkout"
                    lo = "log --pretty=format:\"%C(yellow)%h%Creset %s%n%C(magenta)%C(bold)%an%Creset %ar\" --graph"
                    st = "status"
                    v = "log --graph --oneline --decorate"
                    van = "log --pretty=format:'%C(yellow)%h%Creset %ad %C(magenta)%C(bold)%cn%Creset %s %C(auto)%d%C(reset)' --graph --date=format:%Y/%m/%d_%H%M"
                    vn = "log --pretty=format:'%C(yellow)%h%Creset %ad %s %C(auto)%d%C(reset)' --graph --date=format:%Y/%m/%d_%H%M"
                    vo = "log --graph --decorate"

            [core]
                    pager = "delta --dark"

            [diff]
                    tool = "vimdiff"

            [interactive]
                    diffFilter = "delta --dark --color-only"

            [merge]
                    tool = "vimdiff"

            [user]
                    email = "toraritte@gmail.com"
                    name = "Attila Gulyas"
            ''
        ; # }}-

        shellHook =
            '' # {{-
            # If  not running  interactively,  don't do  anything;
            # this is important for remote shells:
            # http://unix.stackexchange.com/questions/257571/why-does-bashrc-check-whether-the-current-shell-is-interactive

            case $- in
                *i*) ;;
                  *) return;;
            esac

            set -o vi

            # ==============================================================
            # prompt =======================================================
            # ==============================================================

            CWD=$(pwd)
            cd ~
            if [ ! -f ~/git-prompt.sh ]; then
              curl -O https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh
            fi
            source ~/git-prompt.sh
            cd $CWD

            # + for staged, * if unstaged.
            export GIT_PS1_SHOWDIRTYSTATE=1¬

            # $ if something is stashed.
            export GIT_PS1_SHOWSTASHSTATE=1¬

            # % if there are untracked files.
            export GIT_PS1_SHOWUNTRACKEDFILES=1¬

            # <,>,<> behind, ahead, or diverged from upstream.
            export GIT_PS1_SHOWUPSTREAM=1

            # "She's saying ... a bunch of stuff. Look, have you tried drugs?"
            export PS1='NIX-SHELL \[\e[33m\]$(__git_ps1 "%s") \[\e[m\]\[\e[32m\]\u@\h \[\e[m\] \[\e[01;30m\][\w]\[\033[0m\]\nNIX-SHELL \j \[\e[01;30m\][\t]\[\033[0m\] '

            # ==============================================================
            # history ======================================================
            # ==============================================================
            export HISTCONTROL=ignoredups # no duplicate lines in history
            export HISTSIZE=200000
            export HISTFILESIZE=200000
            export HISTTIMEFORMAT='%Y/%m/%d-%H:%M '

            # ==============================================================
            # miscellaneous ================================================
            # ==============================================================
            # Make sure that tmux uses the right variable in order to
            # display vim colors correctly.

            export TERM="screen-256color"
            export EDITOR=$(which vim)
            export MANWIDTH=72
            export ERL_AFLAGS="-kernel shell_history enabled"

            # Android Studio would only open up with blank windows
            # https://unix.stackexchange.com/questions/368817/blank-android-studio-window-in-dwm/428908#428908
            export _JAVA_AWT_WM_NONREPARENTING=1

            # ==============================================================
            # fzf ==========================================================
            # ==============================================================
            export FZF_DEFAULT_COMMAND='find .'
            export FZF_DIR_ONLY="''\${FZF_DEFAULT_COMMAND} -type d"
            export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
            export FZF_ALT_C_COMMAND=$FZF_DIR_ONLY

            export FZF_DEFAULT_OPTS="--height 70% +i"
            export FZF_CTRL_R_OPTS=$FZF_DEFAULT_OPTS

            export FZF_TMUX=$(which fzf-tmux)
            export FZF_TMUX_OPTS=$FZF_DEFAULT_OPTS
            export FZF_TMUX_HEIGHT="70%"

            export FZF_ALT_C_OPTS=$FZF_DEFAULT_OPTS" --multi"
            export FZF_CTRL_T_OPTS=$FZF_ALT_C_OPTS" --preview='head -$LINES {}'"
            export FZF_COMPLETION_OPTS=$FZF_CTRL_T_OPTS

            # ==============================================================
            # unified bash history =========================================
            # ==============================================================
            # HIT ENTER FIRST IF LAST COMMAND IS NOT SEEN IN ANOTHER WINDOW
            # http://superuser.com/questions/37576/can-history-files-be-unified-in-bash
            # (`histappend` in `shellOptions` above is also part of this)

            export PROMPT_COMMAND="''\${PROMPT_COMMAND:+$PROMPT_COMMAND$'\n'}history -a; history -c; history -r" # help history
            shopt -s histappend # man shopt

            # ==============================================================
            # shell options (cont.) ========================================
            # ==============================================================

            # Glob hidden files too with *

            shopt -s dotglob

            # Check  the window  size after  each command  and, if
            # necessary, update the values of LINES and COLUMNS.

            shopt -s checkwinsize

            # If  set,  the  pattern   "**"  used  in  a  pathname
            # expansion context  will match all files  and zero or
            # more directories and subdirectories.

            shopt -s globstar

            # Set variable identifying the chroot you work in (used in the prompt below)

            if [ -z "''\${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
                debian_chroot=$(cat /etc/debian_chroot)
            fi

            # Enable bash support for FZF

            source "$(fzf-share)/key-bindings.bash"
            source "$(fzf-share)/completion.bash"

            # ==============================================================
            # aliases ======================================================
            # ==============================================================

            alias ll='ls -alF --group-directories-first --color'
            alias g='egrep --colour=always -i'
            alias ag='ag --hidden'
            alias b='bc -lq'
            alias dt="date +%Y/%m/%d-%H:%M"
            alias r='fc -s' # repeat the last command
            alias tmux='tmux -2' # make tmux support 256 color

            alias gl='git v --color=always | less -r'
            alias glv='git v --color=always --all | less -r'
            alias glh="gl | head"

            alias ga='git van --color=always | less -r'
            alias gav='git van --color=always --all | less -r'
            alias gah="ga | head"

            alias gd='git vn --color=always | less -r'
            alias gdv='git vn --color=always --all | less -r'
            alias gdh="gd | head"

            # http://www.gnu.org/software/bash/manual/bashref.html#Special-Parameters

            tl() {
              tree -C $@ | less -R
            }
            ''; # }}-
    };
in
  wrapper { maybeNixpkgsCommit = commit; }

# vim: set foldmethod=marker foldmarker={{-,}}- foldlevelstart=0:
