# WHAT'S THIS? {{-
# ====================================================
#
# An   experiment   to   see   if   I   could   create
# a   Nix   expression   for   `nix-shell`   from   my
# `configuration.nix` on NixOS. Not perfect, but it is
# just one file that works without having to mess with
# Home Manager or other Nix  setup files on any distro
# where Nix can be installed.

# HOW TO CALL IT
# ====================================================
#
# 1. The most direct way:
#
#         nix-shell  -v -E 'import (builtins.fetchurl "https://raw.githubusercontent.com/toraritte/shell.nixes/main/baseline/baseline_config.nix")' --argstr "nixpkgs_commit" "nixpkgs-22.11-darwin"
#
# 2. Using a local shell function (from https://discourse.nixos.org/t/why-does-the-same-nix-expression-behave-differently-in-different-nix-shell-calls/24620):
#
#         getShell () { \
#            nix-shell  -v \
#           -E "import (builtins.fetchurl \
#               \"https://raw.githubusercontent.com/toraritte/shell.nixes/$1/baseline/baseline_config.nix\")" \
#           --argstr "nixpkgs_commit" "$2"; \
#         }
#
#    This is duplication is intentional to make it easier to copy from the browswer.
#
#         getShell () { nix-shell  -v -E "import (builtins.fetchurl \"https://raw.githubusercontent.com/toraritte/shell.nixes/$1/baseline/baseline_config.nix\")" --argstr "nixpkgs_commit" "$2"; }
#
#    + The 1st argument ($1)
#      is either a commit hash of the repo
#      or "main" to get  the  HEAD of  the
#      default branch.
#
#    + The 2nd argument ($2)
#      is a commit hash from the NixOS/nixpkgs
#      repo.
#
#         getShell "main" "832bdf74072489b8da042f9769a0a2fac9b579c7"
#
# 3. Using `run.sh`
#
#         source <(curl https://raw.githubusercontent.com/toraritte/shell.nixes/main/run.sh)
#
#    See   `run.sh`   in   the  root   of   the
#    `toraritte/shell.nixes`   repo   for   the
#    synopsis and more examples.

# }}-

# ISSUES {{-
#
# + Git auto-completion doesn't always work.
#
#   Weirdly, it worked on a  Ubuntu server in the cloud,
#   but not on one (same version) on the local machine.
#
# }}-
{ nixpkgs_commit ? import <nixpkgs> {}
, raw_github_url_to_shell_nix_dir ? ""
#                                                         !!  VVV  !!
, _utils_file ? "https://github.com/toraritte/shell.nixes/raw/dev/_utils.nix"
#                                                         !!  ^^^  !!
}:

let
  # WHY THE `wrapperFunction`? {{-
  # ====================================================
  #
  # Wanted to  be able  to pass both  a string  (i.e., a
  # commit hash in  the Nixpkgs repo) and  a package set
  # as  well. The  `wrapperFunction`  is most  probably
  # superfluous  though as  I  could have  just put  the
  # conditional at the top, and I can't remember what my
  # original reasoning was.

  # ASIDE: wrapperFunction: `let .. in ..` vs `() {}`
  # ====================================================
  # Could have used  the latter too, and  only chose the
  # former  because it  looked more  Nix-y (albeit  more
  # verbose). With the parentheses:
  #
  #    { commit ? import <nixpkgs> {} }:
  #
  #    (
  #      { maybe_nixpkgs_commit }:
  #
  #      let
  #        pkgs = ...
  #      in
  #        pkgs.mkShell {
  #          ...
  #        }
  #    ) { maybe_nixpkgs_commit = commit; }
  # }}-
  wrapperFunction =
    { maybe_nixpkgs_commit }:

    let
      pkgs =
        if ( builtins.isString maybe_nixpkgs_commit )
        then import (builtins.fetchTarball "https://github.com/NixOS/nixpkgs/tarball/${maybe_nixpkgs_commit}") {}
        else maybe_nixpkgs_commit
      ;

      # short for shell.nixes_utils
      sn_utils =
        (import (builtins.fetchurl _utils_file)) raw_github_url_to_shell_nix_dir
      ;
      fetchContents = sn_utils.fetchContents sn_utils.fetchLocalOrRemoteFile;

      my_vim = # {{-
        pkgs.vim_configurable.customize {

          vimrcConfig.customRC = fetchContents ./vimrc;

          vimrcConfig.packages.myVimPackage =
            with pkgs.vimPlugins; {
              # Loaded on launch.
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
                #   Consider using fugitive's `:Gdiff :0` instead
                #   see https://stackoverflow.com/questions/15369499/how-can-i-view-git-diff-for-any-commit-using-vim-fugitive
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

              # Original comments from Vim-related sample configs
              # (probably from nixos.wiki?):
              #
              # > manually loadable by calling `:packadd $plugin-name`
              # > however, if a Vim plugin has a dependency that is not explicitly listed in
              # > opt that dependency will always be added to start to avoid confusion.

              opt = [
              ];

              # > To automatically load a plugin when opening a filetype, add vimrc lines like:
              # > autocmd FileType php :packadd phpCompletion
            };
        };
      # }}-

    in
      pkgs.mkShell {
        buildInputs = # {{-
        # Packages that work both on Linux and Mac.
        [
          pkgs.gh
          pkgs.unixtools.netstat
          pkgs.unzip
          pkgs.zip
          pkgs.netcat
          my_vim
          pkgs.elixir
          pkgs.erlang
          pkgs.tmux
          pkgs.tree
          # TODO figure out how to configure it like VIM
          # https://discourse.nixos.org/t/is-it-possible-to-change-the-default-git-user-config-for-a-devshell/17612/7
          pkgs.git
          # Needed for Git (see Git config below (search for `git.conf`).
          pkgs.delta
          pkgs.silver-searcher
          pkgs.ffmpeg
          pkgs.fzf
          pkgs.mc
          pkgs.rclone
          pkgs.curl
          pkgs.openssh
          # Needed for `curl`; otherwise error 77 is thrown;
          # see more at https://github.com/NixOS/nixpkgs/issues/66716
          # .
          pkgs.cacert
          # Not sure about this one, but can't hurt.
          pkgs.libxml2
          pkgs.par
          pkgs.which
          pkgs.less
        ]
        # Packages that only work on Linux.
        ++ pkgs.lib.optionals
             pkgs.stdenv.isLinux
             [
               # For file_system on Linux.
               pkgs.inotify-tools
               # pkgs.busybox
             ]
        # Packages that only work on Mac.
        ++ pkgs.lib.optionals
             pkgs.stdenv.isDarwin
             (with pkgs.darwin.apple_sdk.frameworks;
               [
                 # For file_system on macOS.
                 CoreFoundation
                 CoreServices
               ]
             );
        # }}-

        # ENVIRONMENT VARIABLES VS SHELL VARIABLES {{-
        # ====================================================
        # Variables  defined   outside  `shellHook`   will  be
        # exported   implicitly,   thus becoming   environment
        # variables. Opted to include environment variables to
        # be added here before `shellHook` in case any of them
        # are also needed there.
        # }}-

        # QUESTION Why bother adding stuff outside `shellHook`? {{-
        #          Anything could  be added in there,  and then
        #          use `export` to  convert them to environment
        #          variables.
        #
        # ANSWER: See last paragraph of the next section.
        # }}-

        # LOCALE PRESERVATION CODE AND NOTES {{-
        # ====================================================
        #
        # Without  this, almost  everything  fails with  locale
        # issues  when  using  `nix-shell --pure`  (at least on
        # NixOS).
        #
        # See
        # + https://github.com/NixOS/nix/issues/318#issuecomment-52986702
        # + http://lists.linuxfromscratch.org/pipermail/lfs-support/2004-June/023900.html
        #
        # ( Also, this  variable needs   to be  here and  not in
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
        # when on the same system) instead of falling  back to
        # POSIX  (which  will  happen  when  using  `nix-shell
        # --pure`), then
        #
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
        GIT_CONFIG_GLOBAL = sn_utils.fetchLocalOrRemoteFile ./git.conf;

        shellHook = fetchContents ./shell-hook.sh;
    };
in
  wrapperFunction { maybe_nixpkgs_commit = nixpkgs_commit; }

# vim: set foldmethod=marker foldmarker={{-,}}- foldlevelstart=0 tabstop=2 shiftwidth=2 expandtab:
