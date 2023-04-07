# _utils.nix :: { URLDirName, WorkingDirectory } ->  Functions
#
# URLDirName :: String
#     URL to a remote directory where supporting
#     files reside; it should end with a forward
#     slash.
#     (e.g., "https://github.com/toraritte/shell.nixes/raw/dev/baseline/")
#
# WorkingDirectory :: NixPath
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

{ remote_prefix }:

let

  # https://funprog.srid.ca/nix/nix-and-composition.html
  compose = f: g: x: f ( g x );

  # NOTE `localOrRemoteFile` vs `fetchFile` {{-
  #
  # When `rel_path` is  a local file, the  output is the
  # same (i.e., the resolved  absolute path of the input
  # relative path),  but instances of the  Nix path data
  # type  have  different  semantics, depending  on  the
  # context.
  #
  # For example:
  #
  # + If sssigned to variable, it is just that, a path.
  #
  # + If  assigned to  variable in  the body  of
  #   `mkShell`, that variable  will be exported
  #   as  an environment  variable and  the path
  #   will  be copied  to  the  Nix store.  (See
  #   e.g., this thread
  #   https://discourse.nixos.org/t/when-is-a-path-in-a-nix-expression-copied-into-the-nix-store/27052.)
  #
  # Therefore, in  the case of local  assets, it doesn't
  # matter which one is used, but if the expectation for
  # the path  is to  end up  in the  Nix store  then use
  # `fetchFile`.
  # }}-

  localOrRemoteFile' =
    { remote_prefix ? remote_prefix
    , rel_path # relative to shell.nix being evaluated; add WARNING
    }:
    if ( builtins.pathExists rel_path )
    then rel_path
    else remote_prefix + ( builtins.baseNameOf rel_path )
  ;

  localOrRemoteFile =
    rel_path:
    localOrRemoteFile' { inherit remote_prefix rel_path; }
  ;

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

  fetchFile' =
    { rel_path
    , remote_prefix ? remote_prefix
    }:
    let
      # The journey to figure out how to get the current dir:
      # + https://discourse.nixos.org/t/how-to-refer-to-current-directory-in-shell-nix/9526
      # + https://stackoverflow.com/questions/43850371/when-does-a-nix-path-type-make-it-into-the-nix-store-and-when-not
      # + https://gist.github.com/CMCDragonkai/de84aece83f8521d087416fa21e34df4

      path_or_url = localOrRemoteFile rel_path;
    in
      # Check if this shell.nix is run remotely or locally
      if ( (builtins.typeOf path_or_url) == "path" )
      # when this shell.nix is run from the repo
      then rel_path #=> String
      # when run remotely using run.sh
      else builtins.fetchurl path_or_url
             # ( p.remote_prefix + rel_path) #=> Nix store path (usually `/nix/store/...`)
           #=> String
  ;

  fetchFile =
    rel_path:
    fetchFile' { inherit remote_prefix rel_path; }
  ;

  fetchFileContents' =
    fetcher:
    compose
      builtins.readFile
      fetcher
  ;

  fetchFileContents = fetchFileContents' fetchFile;

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

  cleanUp' =
    fetcher:
    shell_script_paths:
    let

    # cat_scripts :: List ShellScriptName -> String
      cat_scripts =
        builtins.foldl'
          (acc: next: acc + ((fetchFileContents' fetcher) next))
          ""
      ;
    in
      ''
        trap \
        "
        ${cat_scripts shell_script_paths}
        " \
        EXIT
      ''
  ;

  cleanUp = cleanUp' fetchFile;

in

  { inherit localOrRemoteFile' localOrRemoteFile
                     fetchFile fetchFile'
             fetchFileContents fetchFileContents'
                       cleanUp cleanUp'
            compose
    ;
  }

# vim: set foldmethod=marker foldmarker={{-,}}- foldlevelstart=0 tabstop=2 shiftwidth=2 expandtab:
