# _utils.nix :: { URLDirName, PresentWorkingDirectory } ->  Functions
# URLDirName :: String
#     URL to a remote directory where supporting
#     files reside; it should end with a forward
#     slash.
#     (e.g., "https://github.com/toraritte/shell.nixes/raw/dev/baseline/")
# PresentWorkingDirectory :: NixPath
#     This  should point  to a  local dir  where
#     supporting files reside.
#
#     NOTE `working_dir`
#     Initially, `working_dir` was hard-coded to
#     `./.`,  but, as  it turns  out, its  value
#     get resolved to  different paths depending
#     on  whether this  Nix  file is  `import`ed
#     locally  or via  `builtins.fetchurl` (kind
#     of like in a closure).
#     TODO Figure out why this is.

{ remote_prefix,  working_dir ? ./. }:

let

  # fetchFile :: FileNameOrPath -> FileContents
  #   FileContents :: String
  # FileNameOrPath :: String
  #
  #   + a name of a file
  #     (e.g., `shell-hook`)
  #
  #   + a path to a file relative to the calling `shell.nix`
  #     (e.g., `../baseline/git.conf`)
  #
  # Dependencies:
  # + builtins

  # TODO Add  3rd  parameter  "overrideRemote"  for
  #      cases when  one wants  e.g., to  specify a
  #      relative file  path (and  not just  a file
  #      name),  but  the  `remote_prefix`  URL  is
  #      unable to  deal with it so  a "hard-coded"
  #      remote URL is needed.

  fetchFile =
    { working_dir, remote_prefix }@p: filename:
    let
      # The journey to figure out how to get the current dir:
      # + https://discourse.nixos.org/t/how-to-refer-to-current-directory-in-shell-nix/9526
      # + https://stackoverflow.com/questions/43850371/when-does-a-nix-path-type-make-it-into-the-nix-store-and-when-not
      # + https://gist.github.com/CMCDragonkai/de84aece83f8521d087416fa21e34df4
      path = p.working_dir + "/${filename}";
    in
      # Check if this shell.nix is run remotely or locally
      if ( builtins.pathExists path )
      # when this shell.nix is run from the repo
      then builtins.readFile path #=> String
      # when run remotely using run.sh
      else builtins.readFile
          ( builtins.fetchurl
            ( p.remote_prefix + filename) #=> Nix store path (usually `/nix/store/...`)
          )
          #=> String
  ;

  f = fetchFile { inherit remote_prefix working_dir; };

  # a.k.a., trapWrap
  # cleanUp :: List ShellScriptName -> TrapWrappedString
  # ShellScriptName :: FileNameOrPath + has to contain valid shell commands
  # TrapWrappedString :: "trap \ " + ShellScriptName + " \ EXIT"
  #
  #   WARNING
  #
  #   Use  only  single  quotes  (')  whenever  necessary!
  #   Double quotes (") and  backticks (`) n comments kept
  #   messing up `trap` specifications.  Not sure how they
  #   affect execution in commands,  but keep the above in
  #   mind.
  #
  # Dependencies:
  # + fetchFile

  cleanUp =
    remote_prefix: shell_script_names:
    let
    # cat_scripts :: List ShellScriptName -> String
      cat_scripts =
        builtins.foldl'
          (acc: next: acc + (fetchFile remote_prefix next))
          ""
      ;
    in
      ''
        trap \
        "
        ${cat_scripts shell_script_names}
        " \
        EXIT
      ''
  ;

  c = cleanUp { inherit remote_prefix working_dir; };

in

  { inherit fetchFile f cleanUp c; }

# vim: set foldmethod=marker foldmarker={{-,}}- foldlevelstart=0 tabstop=2 shiftwidth=2 expandtab:
