### TYPES ### {{-
#
#    URL :: String
#           + https?://.*  (e.g., "https://github.com/toraritte/shell.nixes/raw/dev/baseline/baseline_config.nix")
#
# URLDir :: String
#                     !! V !!
#           + https?://.*/ (e.g., "https://github.com/toraritte/shell.nixes/raw/dev/baseline/")
#                     !! ^ !!
#
#     URL to a remote directory where supporting
#     files reside; it should end with a forward
#     slash.
#
# Path = NixPath | NixStorePath
#
# RelativeNixPath :: NixPath
#                    + ^\.\/.+$ (e.g., ./. or ./_utils.nix)
#
# NixStorePath :: String
#                 + ^\/nix\/store\/.+$
#                 (except if a different Nix store path is configured)
#
# RelativePathToRemoteFile :: String
#                     + ^[^/]+(\/[^/]+)+? (this is probably wrong)
#                     (e.g., "git.conf", "postgres/clean_up.sh")
# }}-

# _utils.nix :: URLDir ->  NixAttrSet Functions
url_dir:

let

# compose :: (b -> c) -> (a -> b) -> (a -> c)
# https://funprog.srid.ca/nix/nix-and-composition.html
  compose = f: g: x: f ( g x );

# fetchRemoteFile' :: URLDir -> RelativePathToRemoteFile -> NixStorePath {{- {{-
#
#   See notes at `fetchLocalOrRemoteFile'`.
#
# Dependencies:
# + builtins
# }}-
  fetchRemoteFile' =
    url_dir:
    rel_path_to_url_dir:
    builtins.fetchurl ( url_dir +  rel_path_to_url_dir )
  ;

# }}-
# fetchRemoteFile  :: RelativePathToRemoteFile -> NixStorePath {{-
  fetchRemoteFile = fetchRemoteFile' url_dir;

# }}-
# fetchLocalOrRemoteFile' :: URLDir -> RelativeNixPath -> Path {{- {{-
#
# Dependencies:
# + builtins
# }}-
  fetchLocalOrRemoteFile' =
    url_dir:
    rel_path:
    if ( builtins.pathExists rel_path )
    # when this <g>"shell.nix" expression</g> is run from the repo
    then rel_path #=> NixPath
    # when run remotely (e.g., using run.sh)
    else fetchRemoteFile' url_dir ( builtins.baseNameOf rel_path )
  ;

# }}-
# fetchLocalOrRemoteFile  :: RelativeNixPath -> Path {{- {{-
#
# Dependencies:
# + fetchLocalOrRemoteFile'
# }}-
  fetchLocalOrRemoteFile = fetchLocalOrRemoteFile' url_dir;

# }}-
# fetchContents :: (RelativeNixPath -> Path) -> (NixPath -> String) {{- {{-
#
# Dependencies:
# + compose
# + builtins
# }}-
  fetchContents = fetcher: compose builtins.readFile fetcher;

# }}-

### cleanUp WARNING: Use of quotes (`,',") in input files` {{- {{-
#
# Use  only  single  quotes  (')  whenever  necessary!
# Double quotes (") and  backticks (`) n comments kept
# messing up `trap` specifications.  Not sure how they
# affect execution in commands,  but keep the above in
# mind.
# }}- }}-
# cleanUp :: (RelativeNixPath -> Path) -> List ShellScript -> TrapWrappedScript {{- {{-
#
# ShellScript :: NixPath to file containing valid shell commands
# TrapWrappedScript :: "trap \ " + ... + " \ EXIT"
#
# Dependencies:
# + fetchContents
# + builtins
# }}-
  cleanUp =
    fetcher:
    shell_script_paths:
    let
    # catScripts :: List ShellScript -> String
      catScripts =
        builtins.foldl'
          (acc: next: acc + ((fetchContents fetcher) next))
          ""
      ;
    in
      ''
        trap \
        "
        ${catScripts shell_script_paths}
        " \
        EXIT
      ''
  ;

# }}-

in

  { inherit        fetchRemoteFile fetchRemoteFile'
            fetchLocalOrRemoteFile fetchLocalOrRemoteFile'
            cleanUp
            compose
            fetchContents
    ;
  }

### NOTES ### {{-

# 1. Why no `fetchLocalFile` function? {{-
#
#   Because the Nix "path" data type by itself
#   will suffice in most (all?) cases. See "3.
#   Nix  path  resolutions and  side  effects"
#   below, especially 3.e

# }}-
# 2. `fetchRemoteFile'` vs `fetchLocalOrRemoteFile'` {{-
#
#    Use `fetchLocalOrRemoteFile'`  when it  is evaluated
#    in the  context of a <g>general  purpose "shell.nix"
#    expression</g>, <g>fetch</g>ing files  that are both
#    available to it locally and remotely.
#
#    For      example,      `baseline_config.nix`      or
#    `postgres_shell.nix` in  the `toraritte/shell.nixes`
#    repo:
#
#    + If  called  locally  (e.g.,  from  the  cloned
#      `toraritte/shell.nixes` repo via `nix-shell`),
#      then the  files denoted  by `rel_path`  in the
#      filesystem will be copied to the Nix store.
#
#    + If  called  remotely   (e.g.,  via  `run.sh`),
#      the  referenced files  will be  <g>fetch</g>ed
#      remotely   from  the   `toraritte/shell.nixes`
#      GitHub repo.
#
#    In  contrast,   `fetchRemoteFile'?`  functions  (and
#    native  Nix   ways  to  <g>fetch</g>   local  files;
#    see   "1.   Why   no   `fetchLocalFile`   function?"
#    in   NOTES   above)   are   more   appropriate   for
#    <g>project-specific "shell.nix" expression</g>s that
#    are  called  locally  within   the  context  of  the
#    project  they belong  to  (e.g., `dev_shell.nix`  in
#    `society-for-the-blind/slate-2`), and  not remotely.
#    (At least,  if a  software project  has more  than a
#    couple of files than it makes more sense to copy the
#    entire  project directory  to  one's local  machine,
#    instead of pulling them one-by-one via Nix commands.
#    Nonetheless, there may be smaller ones.)
#
# The usage basically boils  down to signal semantics,
# especially  in   the  case   of  local   files:  use
# `localOrRemoteFile`  if  the  intention is  to  just
# return the  path strings, and use `fetchFile` if the
# goal is for the referenced path to end up in the Nix
# store.
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
#   https://discourse.nixos.org/t/when-is-a-path-in-a-nix-expression-copied-into-the-nix-store/27052.)

# }}-
# 3. Nix path resolutions and side effects {{-
#
#    **KEEP IN MIND**:
#
#      Whether  the  evaluation  of  a  Nix  path
#      results in side effects  or not depends on
#      the context!
#
#    For example, if a Nix path is assigned to a variable
#    in  the body  of  `mkShell`, that  variable will  be
#    exported  as an  environment variable  AND the  path
#    will be copied to the  Nix store. Otherwise, it will
#    probably just get expanded to an absolute path.
#
#       a. https://discourse.nixos.org/t/how-to-refer-to-current-directory-in-shell-nix/9526
#       b. https://stackoverflow.com/questions/43850371/when-does-a-nix-path-type-make-it-into-the-nix-store-and-when-not
#       c. https://gist.github.com/CMCDragonkai/de84aece83f8521d087416fa21e34df4
#       d. https://discourse.nixos.org/t/infinite-loop-when-importing-fetched-nix-expression-with-relative-path/27032
#       e. https://discourse.nixos.org/t/when-is-a-path-in-a-nix-expression-copied-into-the-nix-store/27052

# }}-
# 4. cleanUp -> trapWrap?`
# 5. Why the `Relative*` constrained types? {{-
#
#    Given that  the functions here are  run on different
#    machines with different  OSs (and architectures), it
#    doesn't  make sense  to  use  absolute paths.  Also,
#    every  function  here  assumes an  input  path  that
#    is  relative to  the current  directory the  calling
#    <g>"shell.nix" expression</g>  is executing  in (see
#    item  2.  in  these  NOTES  above)  or,  in the case
#    of `fetchRemoteFile'?` functions, the input path has
#    to be relative to remote repo URL.
#
#    (For the latter, the `"http.../"` - `"../.."` scheme
#    was simply  shorter to implement than  `"http..."` -
#    `"/../.."`.)

#   }}-
# }}-

### GLOSSARY ### {{-

# + <g>fetch</g> {{-
#
#   Get the contents of the file,  and put it in the Nix
#   store. For  local files, Nix takes  care of creating
#   the hash and  copying the contents of  the file. For
#   remote  files, usually  "fetchers" (functions  whose
#   names start with `fetch`) are used; see Nix builtins
#   and the Nixpkgs repo `stdlib`.

#   }}-
# + <g>"shell.nix" expression</g> {{-
#
#   A  Nix  expression  whose   purpose  is  to  produce
#   and  enter  a  sub-shell with  preconfigured  tools.
#   (Currently, the only  officially supported sub-shell
#   by  Nix,  as far  as  I  know,  is Bash,  but  there
#   are   efforts   to   extend  this   support;   e.g.,
#   see [nuenv](https://determinate.systems/posts/nuenv)
#   that is using nushell.)
#
#   If the  Nix expression uses  `mkShell` then it  is a
#   <g>"shell.nix" expression</g>.  (However, some older
#   ones may  still use  `mkDerivation`; not  sure about
#   the specifics, but it's worth noting.)

#   }}-
# + <g>general purpose "shell.nix" expression</g> {{-
#
#   A <g>"shell.nix" expression</g> that is
#   + not tied to a specific project
#   + used for general activities
#
#   Examples:
#
#   + `baseline/baseline_config.nix`    in
#     `toraritte/shell.nixes`    that   is
#     roughly   trying   to  emulate   the
#     environment that  I use on  my NixOS
#     boxes.
#
#   + `postgres/postgres_shell.nix`  (same
#     repo  as  above)  is to  fire  up  a
#     PostgreSQL  instance for  testing or
#     trying something out.

#   }}-
# + <g>project-specific "shell.nix" expression</g> {{-
#
#   A  <g>"shell.nix"  expression</g>  that is  used  to
#   set  up a  development  environment  for a  project.
#   For    example,    `society-for-the-blind/slate-2`'s
#   `dev_shell.nix`.

#   }}-
# }}-

# vim: set foldmethod=marker foldmarker={{-,}}- foldlevelstart=0 tabstop=2 shiftwidth=2 expandtab:
