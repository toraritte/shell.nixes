TODO: This repo is huge mess...

TODO: Make naming style consistent. (E.g., in `_utils.nix` functions and types have snake case, while other variables are CamelCased, and other Nix expressions are all over the place.)

+ `_helpers`: Some good notes in `README`s, but it was so long ago that not even sure what I was trying to achieve.
+ `_utils`: Helper functions for composing `shellHook`s; see `shell.nix` files in [`./postgres`](./postgres) and [`.baseline`](./baseline) directories. (I think this was to goal of `_helpers`, but I had even less clue of what I was doing than now.)

NOTES:

+ `builtins.fetchurl` will cache results (see issue https://github.com/NixOS/nix/issues/1223), and so far the only solution for me is to keep track of fetched files and to delete them with `nix-store --delete <nix-store-path>`

---

Each folder has their specific README, but the source files are heavily commented as well, in case it is missing. If you still have any questions, or have suggestions, please feel free to open an issue, PR, or track me down any other way.

---

## Helpers (i.e., the [`_helpers`](./_helpers) directory)

Mostly Nix expressions (only one at the moment, to be precise) to promote code re-use.

## Some `nix-shell` tricks learned along the way

+ **_invoke `nix-shell` with a URL of a `shell.nix`_**

  The discussion can be found [here](https://discourse.nixos.org/t/how-to-invoke-nix-shell-with-the-contents-of-an-url-e-g-a-raw-github-link/12281) and using [deno-shell.nix](./deno-shell.nix) as an example:
  
  ```shell
    nix-shell -E 'import (builtins.fetchurl "https://raw.githubusercontent.com/toraritte/shell.nixes/main/deno-shell.nix")'
  ```

+ **_Definitely take a look at the comments in [deno-shell.nix](./deno-shell.nix)!_**

+ **_call `nix-shell` on a package that is not in the Nixpkgs repo_**

  That is, kind of like `nix-shell -p` but that can only be called on Nixpkgs packages (as far as I know).
  
  #### Traditional way
  
  ```shell
  nix-shell -p '(callPackage (fetchTarball https://github.com/DavHau/mach-nix/tarball/3.0.2) {}).mach-nix'
  ```

  #### Nix flakes
  
  That is, if 
  
    1. [flakes support is enabled](https://nixos.wiki/wiki/Flakes#:~:text=Installing%20flakes) (at least, at the time of writing this, flakes are not yet enabled by default), and 
    
    2. the target repo also supports flakes (right?...),
  
  one can do:
  
  ```shell
  nix shell github:DavHau/mach-nix
  ```
  
  Quoting [the rest](https://discourse.nixos.org/t/how-to-invoke-nix-shell-p-for-packages-not-in-nixpkgs/12475/3) verbatim because I have yet to understand it:
  
  > I would just capture `mach-nix` in your `shell.nix` or `devShell` in your `flake.nix`. Then pair it with [`direnv`](https://direnv.net/) to allow you to bring it into your shell when you need it for a particular project.

## `azure-new`

<sup>Mentioning it here because it is not a simple subdirectory but a git submodule - it has its own extensive readme, but wnated to note it here as well.</sup>

`azure-new` is a collection of scripts to provision custom NixOS images and VMs on the [Microsoft Azure cloud computing platform](https://azure.microsoft.com/en-us/), originally created by @colemickens. I presume the main motivation was that [the Azure backend has been removed from NixOps](https://github.com/NixOS/nixops/pull/1131). The weird layout of the project comes from the fact that it has been ripped out from the [Nixpkgs repo](https://github.com/toraritte/nixpkgs); see more details in the project readme on the how.)

> **Tip**: To clone this repo **with** the `azure-new` submodule, please see the [How to “git clone” including submodules?](https://stackoverflow.com/questions/3796927/how-to-git-clone-including-submodules) Stackoverflow thread.

> **`git submodule` reminders to self**  
> 
> Reminder on [how to set up a git submodule that tracks a branch](https://stackoverflow.com/a/15782629/1498178):
> 
> ```text
> # add submodule to track master branch
> git submodule add -b branch_name URL_to_Git_repo optional_directory_rename
> 
> # update your submodule
> git submodule update --remote 
> ```
