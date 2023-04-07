# _utils.nix :: { URLDirName } ->  NixAttrSet Functions {{-
# URLDirName :: String
#     URL to a remote directory where supporting
#     files reside; it should end with a forward
#     slash.
#     (e.g., "https://github.com/toraritte/shell.nixes/raw/dev/baseline/")
# }}-
{ remote_prefix }:

let

# compose :: (b -> c) -> (a -> b) -> (a -> c)
# https://funprog.srid.ca/nix/nix-and-composition.html
  compose = f: g: x: f ( g x );

  # NOTE `localOrRemoteFile` vs `fetchFile` {{-
  #
  # The usage basically boils  down to signal semantics,
  # especially  in   the  case   of  local   files:  use
  # `localOrRemoteFile`  if  the  intention is  to  just
  # return the  path strings, and use `fetchFile` if the
  # goal is for the referenced path to end up in the Nix
  # store.
  #
  # **KEEP IN MIND**:
  #
  #   The  evaluation  of  a  Nix  path  depends
  #   on  the context  whether it  produces side
  #   effects or not! #
  #
  # When `rel_path` is  a local file, the  output is the
  # same (i.e., the resolved  absolute path of the input
  # relative path),  but instances of the  Nix path data
  # type  have  different  behaviour, depending  on  the
  # context.
  #
  # For example:
  #
  # + If sssigned to variable, it is just that, a path.
  #
  # + If  assigned to  variable in  the body  of
  #   `mkShell`, that variable  will be exported
  #   as  an environment  variable AND  the path
  #   will  be copied  to  the  Nix store.  (See
  #   e.g., this thread
  #   https://discourse.nixos.org/t/when-is-a-path-in-a-nix-expression-copied-into-the-nix-store/27052.)
  #

  # }}-
  # NOTE Nix path resolutions and side effects {{-
  # + https://discourse.nixos.org/t/how-to-refer-to-current-directory-in-shell-nix/9526
  # + https://stackoverflow.com/questions/43850371/when-does-a-nix-path-type-make-it-into-the-nix-store-and-when-not
  # + https://gist.github.com/CMCDragonkai/de84aece83f8521d087416fa21e34df4
  # + https://discourse.nixos.org/t/infinite-loop-when-importing-fetched-nix-expression-with-relative-path/27032
  # + https://discourse.nixos.org/t/when-is-a-path-in-a-nix-expression-copied-into-the-nix-store/27052
  # }}-

#    URL :: "https?://.*"  (e.g., "https://raw.githubusercontent.com/toraritte/shell.nixes/main/run.sh")
# URLDir :: "https?://.*/" (e.g., "https://raw.githubusercontent.com/toraritte/shell.nixes/main/")
# PathOrUrl = NixPath | URL

# localOrRemoteFile' :: { remote_prefix :: URLDir, rel_path :: NixPath } -> PathOrUrl {{-
#
# Dependencies:
# + builtins
# }}-
  localOrRemoteFile' = # {{-
    { remote_prefix ? remote_prefix
    , rel_path # relative to shell.nix being evaluated; TODO add WARNING
    }:
    if ( builtins.pathExists rel_path )
    then rel_path
    else remote_prefix + ( builtins.baseNameOf rel_path )
  ;
  # }}-

# localOrRemoteFile :: NixPath -> PathOrUrl {{-
#
# Dependencies:
# + localOrRemoteFile'
# }}-
  localOrRemoteFile =
    rel_path:
    localOrRemoteFile' { inherit remote_prefix rel_path; }
  ;

# fetchFile' :: { remote_prefix :: URLDir, rel_path :: NixPath } -> PathOrUrl {{-
#
# Dependencies:
# + localOrRemoteFile'
# + builtins
# }}-
  fetchFile' = # {{-
    { rel_path
    , remote_prefix ? remote_prefix
    }:
    let
      path_or_url = localOrRemoteFile' { inherit remote_prefix rel_path; };
    in
      if ( (builtins.typeOf path_or_url) == "path" )
      # when this shell.nix is run from the repo
      then rel_path #=> NixPath
      # when run remotely (e.g., using run.sh)
      else builtins.fetchurl path_or_url #=> URL
  ;
  # }}-

# fetchFile' :: NixPath -> PathOrUrl {{-
#
# Dependencies:
# + fetchFile'
# }}-
  fetchFile = rel_path: fetchFile' { inherit remote_prefix rel_path; };

# fetchFileContents' :: (NixPath -> PathOrUrl) -> (NixPath -> String) {{-
#
# Dependencies:
# + compose
# + builtins
# }}-
  fetchFileContents' = fetcher: compose builtins.readFile fetcher;

# fetchFileContents :: NixPath -> String {{-
#
# Dependencies:
# + fetchFileContents'
# }}-
  fetchFileContents = fetchFileContents' fetchFile;

# a.k.a., trapWrap
# cleanUp :: (NixPath -> PathOrUrl) -> List ShellScript -> TrapWrappedScript {{-
#
# ShellScript :: NixPath to file containing valid shell commands
# TrapWrappedScript :: "trap \ " + ... + " \ EXIT"
#
# Dependencies:
# + fetchFileContents'
# + builtins
# }}-
  cleanUp' = # {{-
    fetcher:
    shell_script_paths:
    let
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
  # }}-

# cleanUp :: List ShellScript -> TrapWrappedScript {{-
#
# ShellScript :: NixPath to file containing valid shell commands
# TrapWrappedScript :: "trap \ " + ... + " \ EXIT"
#
# Dependencies:
# + fetchFileContents'
# + builtins
# }}-
# WARNING Use of quotes (`,',") in input files` {{-
#
# Use  only  single  quotes  (')  whenever  necessary!
# Double quotes (") and  backticks (`) n comments kept
# messing up `trap` specifications.  Not sure how they
# affect execution in commands,  but keep the above in
# mind.
# }}-
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
