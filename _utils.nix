{ remote_prefix ? "" }:

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
    remote_prefix: filename:
    let
      # The journey to figure out how to get the current dir:
      # + https://discourse.nixos.org/t/how-to-refer-to-current-directory-in-shell-nix/9526
      # + https://stackoverflow.com/questions/43850371/when-does-a-nix-path-type-make-it-into-the-nix-store-and-when-not
      # + https://gist.github.com/CMCDragonkai/de84aece83f8521d087416fa21e34df4
      path = ./. + "/${filename}";
    in
      # Check if this shell.nix is run remotely or locally
      if ( builtins.pathExists ( trace path path ) )
      # when this shell.nix is run from the repo
      then builtins.readFile path #=> String
      # when run remotely using run.sh
      else builtins.readFile
          ( builtins.fetchurl
            ( remote_prefix + filename) #=> Nix store path (usually `/nix/store/...`)
          )
          #=> String
  ;

  f = fetchFile remote_prefix;

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

  c = cleanUp remote_prefix;

in

  { inherit fetchFile f cleanUp c; }

# vim: set foldmethod=marker foldmarker={{-,}}- foldlevelstart=0 tabstop=2 shiftwidth=2 expandtab:
