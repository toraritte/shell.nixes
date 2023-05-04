Sets up a toy PostgreSQL instance. (Used the word "toy" because this is a really minimal and **insecure** setup; just look into [`shell-hook.sh`](./shell-hook.sh).)

[`postgres_shell.nix`](./postgres_shell.nix) depends on [`_utils.nix`](/_utils.nix), but none of the "`shellHook` inserts" (i.e., [`shell-hook.sh`](./shell-hook.sh) and [`clean-up.sh`](./clean-up.sh)) depend on it, so they can be simply added to another `shell.nix`.

### How to call?

+ mac:

  * Calling from `shell.nixes` project root:

    ```text
    nix-shell --argstr "nixpkgs_commit" "nixpkgs-22.11-darwin" --argstr "_utils_file" "file://$(realpath _utils.nix)" postgres/postgres_shell.nix --show-trace
    ```

    or

    ```text
    source run.sh -g https://github.com/toraritte/shell.nixes/blob/main/postgres/postgres_shell.nix
    ```

  * Calling remotely (once commits are pushed, that is):

    ```text
    source <(curl https://raw.githubusercontent.com/toraritte/shell.nixes/main/run.sh) -g https://github.com/toraritte/shell.nixes/blob/main/postgres/postgres_shell.nix
    ```

+ linux:

  All the same, but replace  `nixpkgs_commit` from `"nixpkgs-22.11-darwin"` with `"22.11"` (or something else that points to a commit in the [Nixpkgs repo](https://github.com/NixOS/nixpkgs)).


### NOTE: The `_nix-shell` directory (experimental)

Just a convention to make it possible for other Nix shell expressions in this repo to get stacked. Will see how it works.
