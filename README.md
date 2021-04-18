Each  folder  has  their specific  README,  and  the
source files are heavily commented as well.

---

## Some `nix-shell` tricks learned along the way

### Invoke `nix-shell` with a URL of a `shell.nix`

The discussion can be found [here](https://discourse.nixos.org/t/how-to-invoke-nix-shell-with-the-contents-of-an-url-e-g-a-raw-github-link/12281) and using [deno-shell.nix](./deno-shell.nix) as an example:

```shell
  nix-shell -E 'import (builtins.fetchurl "https://raw.githubusercontent.com/toraritte/shell.nixes/main/deno-shell.nix")'
```

### Call `nix-shell` on a package that is not in the Nixpkgs repo

That is, kind of like `nix-shell -p` but that can only be called on Nixpkgs packages (as far as I know). See [mach-nix/README.md](./mach-nix/README.md) for the details.

## Azure-related

### `azure-new`

`azure-new` is a collection of scripts to provision custom NixOS images and VMs on the [Azure cloud platform](https://azure.microsoft.com/en-us/), created by @colemickens. I presume the main motivation was that [the Azure backend has been removed from NixOps](https://github.com/NixOS/nixops/pull/1131).

The directory with the same name is a git submodule tracking `tweak-azure-new3` branch on [my fork of Nixpkgs](https://github.com/toraritte/nixpkgs) so beware when [cloning with submodules](https://stackoverflow.com/questions/3796927/how-to-git-clone-including-submodules) as it is huge.

> NOTE: The scripts are located in `nixos/maintainers/scripts/azure-new`.

```text
Receiving objects: 100% (1957809/1957809), 1.12 GiB | 4.47 MiB/s, done.
```

### `flake-azure`

@colemickens has been keeping busy and dropped this great project:
https://github.com/colemickens/flake-azure-demo/tree/dev

I have yet to find time to try it out but here's the IRC channel #nixos-azure with [logs](https://logs.nix.samueldr.com/nixos-azure/).

## `git submodule` reminder

Reminder on [how to set up a git submodule that tracks a branch](https://stackoverflow.com/a/15782629/1498178):

```text
# add submodule to track master branch
git submodule add -b branch_name URL_to_Git_repo optional_directory_rename

# update your submodule
git submodule update --remote 
```
