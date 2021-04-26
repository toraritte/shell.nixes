[`clam.nix`](./clam.nix) is for modularizing shell hooks in Nix expressions called with `nix-shell` (usually stored in `shell.nix` files).

<sup>The idea itself was suggested by @SRGOM in [issue #1](https://github.com/toraritte/shell.nixes/issues/1), but instead of modularizing shell scripts themselves (e.g., [like this](https://stackoverflow.com/questions/8352851/how-to-call-one-shell-script-from-another-shell-script)), decided to solve it with the Nix language using `import`s.</sup>

See list of pre-requisite concepts at the bottom. TODO: add link

## 1. How to use

The reference usage of [`clam.nix`](./clam.nix) is demonstrated in [`elixir-phoenix-postgres/shell.nix`](../../elixir-phoenix-postgres/shell.nix), but see below for an example demonstration, and the following sections explain the structure and how it works.

```nix
pkgs.mkShell {

  buildInputs =
    [
      # ...
    ];

  shellHook =
    let
      rump =
        ''
        pg_ctl -D $PGDATA stop
        ''
      ;
      cavern =
          import ../_helpers/shell-hook/inserts/postgres.nix
        + import ../_helpers/shell-hook/inserts/mix.nix
      ;
    in
      import ../_helpers/shell-hook/clam.nix { inherit cavern rump; }
  ;
}
```

## 2. How [`clam.nix`](./clam.nix) works

[`clam.nix`](./clam.nix) is a Nix expression function, and its parameters add extra functionality to the returned [shell script](https://en.wikipedia.org/wiki/Shell_script). The template defines the generic phases of

  1. **setup** (`nixShellDataDir`)
  2. **actions** (`cavern`)
  3. **clean-up** (`rump`)

 where the the items in the parentheses denote the function's parameters that is used in those phases.

<figure>
  <img src="https://i.imgur.com/Wmw4hl6.jpg" height="72%" width="72%" alt="An empty clam shell slightly opened, photographed on a sandy beach with the ocean and the clear sky as a background."/>
  <figcaption>A mnemonic (By febb, <a href="https://creativecommons.org/licenses/by-sa/3.0" title="Creative Commons Attribution-Share Alike 3.0">CC BY-SA 3.0</a>, <a href="https://commons.wikimedia.org/w/index.php?curid=47254998">Link</a>)</figcaption>
</figure>

```text
├── _helpers
│   └── shell-hook
│       ├── clam.nix         - the shell script template
│       ├── inserts          - generic shell script snippets
│       │   │                  that add extra functionality;
│       │   │                  see "2.3 Inserts"
│       │   ├── mix.nix  
│       │   └── postgres.nix
│       └── README.md
```

### 2.1 Phases

#### 2.1.1 Setup phase

```nix
mkdir ${nixShellDataDir}
export NIX_SHELL_DIR=$PWD/${nixShellDataDir}
```

That is,

1. create the Nix shell temporary directory (see **2.1.1 `nixShellDataDir`** section for its purpose), and

2. make its path available in the Nix shell environment in the `NIX_SHELL_DIR` environment variable;`NIX_SHELL_DIR` can then be used in custom shell commands (see **1.2 Actions phase** and **1.3 Clean-up phase** sections) to refer to the temporary Nix shell temporary directory.

#### 2.1.2 Actions phase

> NOTE: **This phase has no default actions**.

Set up development environment (by including custom shell commands in `cavern`; see **2.2.2 `cavern`**) for your specific language or framework or customize the shell for your purpose. (E.g., start a database instance, set environment variables, download language packages, etc.)

#### 2.1.3 Clean-up phase

By default, this phase deletes the `$NIX_SHELL_DIR` (see **2.1.1 Setup phase** section) directory, but any other clean-up measures need to be provided by the user.

For example, if a database instance has been started previously, it will keep running when exiting Nix shell, unless it is explicitly stopped in the clean-up phase (via shell commands specified in `rump`; see **2.2.3 `rump`**).

<sup>Not unsetting environment variables is alright, because `nix-shell` starts a sub-shell so these will go out of scope when leaving; [`nix shell` may be another matter though](https://github.com/NixOS/nix/issues/4715).</sup>

### 2.2 [`clam.nix`](./clam.nix) parameters

```nix
{ nixShellDataDir ? ".nix-shell"
, cavern
, rump ? ""
}:
```

#### 2.2.1 `nixShellDataDir` :: String (default: `.nix-shell`)

The name of the temporary directory created in the **setup phase** (see sections **2. How clam.nix works** and **2.1 Setup** below) when entering the Nix shell to to store application-specific data, instead of having those scattered around in the system (e.g., in the user's home directory, `/run`, etc.). This temporary directory will be deleted when exiting the shell (see **1.3 Clean-up** section). 

<sup>TODO: Is there a need to retain it? My workflow is usually to (1) enter `nix-shell`, (2) do stuff, and (3) suspend the system at the end of the day/session, so I start in the same environment the next time. This also means if I make changes to the environment, and these won't be reflected when I'll enter it the next time. I would argue that **deleting it is good** because it forces one to update the `shell.nix` on change (and some action will definitely warrant this anyway, such as changing environment variables).</sup>

Examples of application specific data:

+ language modules (e.g., [Mix-specific files for Elixir](./_helpers/shell-hook/inserts/mix.nix), [Node.js modules](https://unix.stackexchange.com/a/482026/85131) etc.)

+ runtime (configuration) files (e.g., see comment on `unix_socket_directories`<sup>†</sup> in the [`postgres.nix`](./_helpers/shell-hook/inserts/postgres.nix))

<sup>† There is a [difference between Unix and TCP/IP sockets](https://serverfault.com/questions/124517/what-is-the-difference-between-unix-sockets-and-tcp-ip-sockets) and not all Unix sockets are files (see [wiki](https://en.wikipedia.org/wiki/Unix_domain_socket#:~:text=Unix%20domain%20sockets%20may%20use,by%20opening%20the%20same%20socket.) and [this question](https://unix.stackexchange.com/questions/116563/is-there-a-file-for-each-socket)).</sup>

#### 2.2.2 `cavern` :: String

Accepts a string that contains valid shell commands; see **2.1.2 Actions phase** for more.

#### 2.2.3 `rump` :: String (default: `""`)

Accepts a string that contains valid shell commands; see **2.1.2 Clean-up phase** for more.

### 2.3 Inserts (i.e., the contents of the `./inserts/` directory)

A collection of generic shell script snippets that I've been re-using between different environments. For example, [./inserts/postgres.nix](./inserts/postgres.nix) spins up a PostgreSQL server (which works just the same for an Elixir project as for a Python one).

## ∞. Pre-requisite concepts

### Derivation

TODO

### `$stdenv/setup`

TODO

### `nix-shell`

TODO

<sup>I believe that [`nix-shell`'s Nix manual entry](https://nixos.org/manual/nix/stable/#name-2) is grossly over-simplified, and its behaviour does raise [questions](https://hyp.is/nFTgRHFyEeunHQ9ZFhBBmA/toraritte.github.io/saves/Nix-Package-Manager-Guide-Version-2.3.10.html).</sup>

### `shellHook` or `nix-shell` shell hook

From [`nix-shell`'s Nix manual entry](https://nixos.org/manual/nix/stable/#name-2):

> If the derivation defines the variable `shellHook`, it will be evaluated after `$stdenv/setup` has been sourced. Since this hook is not executed by regular Nix builds, it allows you to perform initialisation specific to `nix-shell`. For example, the derivation attribute
> 
>     shellHook =
>       ''
>         echo "Hello shell"
>       '';
>
> will cause `nix-shell` to print "Hello shell".

