## 1. Introduction

[`clam.nix`] is for modularizing _shell hooks_ TODO link in [Nix expressions] (usually stored in `shell.nix` files) that are to be used with the [`nix-shell`] command line tool. The body of the [`clam.nix`] function is a shell script template, and the input attributes enable plugging in custom shell commands at specific stages TODO link of its execution.

For example, taking the reference usage demonstrated in [`elixir-phoenix-postgres/shell.nix`](../../elixir-phoenix-postgres/shell.nix) (see [its README](../../elixir-phoenix-postgres/)), a sub-shell will be set up for a [Phoenix (an Elixir web framework)](https://www.phoenixframework.org/) project, with the required language packages and a PostgreSQL instance running in the background (**actions phase** TODO:link), all of which will be cleaned up upon exiting the shell (i.e., packages deleted, database stopped, etc.). Another example is [setting up `git secret`][discourse_git_secret].

[`nix-shell`]:
  https://nixos.org/manual/nix/stable/#name-2
  "Manual page of the nix-shell command line tool in the Nix manual"

[Nix expressions]:
  https://nixos.org/manual/nix/stable/#chap-writing-nix-expressions
  "A short introduction to Nix expressions in the Nix manual"

[`clam.nix`]:
  ./clam.nix
  "The source code of the clam.nix Nix expression"

[discourse_git_secret]:
  https://discourse.nixos.org/t/how-to-execute-a-script-once-during-the-shell-build/9377
  "A NixOS discourse thread titled \"How to execute a script once during the shell build?\""

[attribute set]:
  https://nixos.org/manual/nix/stable/#idm140737322000880
  "Sets section in the Nix manual"

[clam_nix_params]:
  #clam_nix_params
  "Description of `clam.nix` input attributes"

[`./inserts/postgres.nix`]:
  ./\_helpers/shell-hook/inserts/postgres.nix

<sup>The idea itself was suggested by @SRGOM in [issue #1](https://github.com/toraritte/shell.nixes/issues/1), but instead of modularizing shell scripts themselves (e.g., [like this](https://stackoverflow.com/questions/8352851/how-to-call-one-shell-script-from-another-shell-script)), decided to solve it with the Nix language using `import`s.</sup>

## 2. Phases of the [`clam.nix`] shell script template and the input attributes controlling them

The [`clam.nix`] function expects an [attribute set] in the form of

```nix
{ nixShellDataDir ? ".nix-shell"
, cavern          ? ""
, rump            ? ""
}:
```

<span id="clam_nix_params">where</span>

  + `nixShellDataDir` (**default value:** `.nix-shell`)
  > is a **string** used to name of a temporary directory that will be created in the directory where the Nix expression is invoked with [`nix-shell`]; see setup phase (TODO link)

  + `cavern` (**default value:** `""`)
  > is a **string** that should evaluate to valid shell commands; see actions phase (TODO link) section for the details and examples

  + `rump` (**default value**: `""`)
  > is a **string** that should also evaluate to valid shell commands; see clean-up phase (TODO link)

The template can be broken up into the following phases (these are also marked in the [source][`clam.nix`]):

  1. [**setup**](https://github.com/toraritte/shell.nixes/tree/main/_helpers/shell-hook#211-setup-phase) (`nixShellDataDir`)

  2. [**actions**](https://github.com/toraritte/shell.nixes/tree/main/_helpers/shell-hook#212-actions-phase) (`cavern`)

  3. [**clean-up**](https://github.com/toraritte/shell.nixes/tree/main/_helpers/shell-hook#213-clean-up-phase) (`rump`)

The items in parentheses refer to attribute names in the `clam.nix` function's input [attribute set] that play a role in the respective phase.

<figure>
  <img src="https://i.imgur.com/Wmw4hl6.jpg" height="42%" width="42%" alt="An empty clam shell slightly opened, photographed on a sandy beach with the ocean and the clear sky as a background."/>
  <figcaption>A mnemonic (By febb, <a href="https://creativecommons.org/licenses/by-sa/3.0" title="Creative Commons Attribution-Share Alike 3.0">CC BY-SA 3.0</a>, <a href="https://commons.wikimedia.org/w/index.php?curid=47254998">Link</a>)</figcaption>
</figure>

```text
├── _helpers
│   └── shell-hook
│       │
│       ├── clam.nix         - the shell script template
│       │
│       ├── inserts          - generic shell script snippets
│       │   │                  that add extra functionality;
│       │   │                  see "2.3 Inserts"
│       │   │
│       │   ├── mix.nix
│       │   └── postgres.nix
│       │
│       └── README.md        - this readme
│
├── elixir-phoenix-postgres  - other project-  or app-specific
├── ...                        shell.nix-es  below  this point
:
```

### 2.1 Phases

#### 2.1.1 Setup phase

> NOTE: This phase doesn't accept any custom shell commands at the moment, only the name of the temporary directory specified by [`nixShellDataDir`][clam_nix_params].

1. Creates a temporary directory (set by [`nixShellDataDir`, see above][clam_nix_params])

  Used to store application-specific data, instead of having those scattered around in the system (e.g., in the user's home directory, `/run`, etc.); it will be deleted when exiting the shell (see **1.3 Clean-up** TODO link section).

2. Makes the path of the temporary directory available in the `NIX_SHELL_DIR` environment variable in the new sub-shell created by [`nix-shell`]

  `NIX_SHELL_DIR` can then be used in custom shell commands (see example usage in [`./inserts/postgres.nix`] for example).

3. Set up empty CLEANUP_CALLBACKS array to register callback functions to be run in the **clean-up phase** TODO link.

#### 2.1.2 Actions phase

> **Default actions:** None

Set up development environment (by including custom shell commands in `cavern`; see **2.2.2 `cavern`**) for your specific language or framework or customize the shell for your purpose. (E.g., start a database instance, set environment variables, download language packages, etc.)

#### 2.1.3 Clean-up phase

> **Default actions:**
>
>     cd $PWD               # (1)
>     rm -rf $NIX_SHELL_DIR # (2)

That is,

1. return to the project directory (see [comment](https://github.com/toraritte/shell.nixes/blob/4ca7310e6826a57e789a6786b007f6c2270a431c/_helpers/shell-hook/clam.nix#L57-L63)), and
2. delete the `$NIX_SHELL_DIR` directory (see **2.1.1 Setup phase** section), but any other clean-up measures need to be provided by the user.

<sup>TODO: Is there a need to retain it? My workflow is usually to (1) enter `nix-shell`, (2) do stuff, and (3) suspend the system at the end of the day/session, so I start in the same environment the next time. This also means if I make changes to the environment, and these won't be reflected when I'll enter it the next time. I would argue that **deleting it is good** because it forces one to update the `shell.nix` on change (and some action will definitely warrant this anyway, such as changing environment variables).</sup>

For example, if a database instance has been started previously, it will keep running when exiting Nix shell, unless it is explicitly stopped in the clean-up phase (via shell commands specified in `rump`; see **2.2.3 `rump`**).

<sup>Not unsetting environment variables is alright, because `nix-shell` starts a sub-shell so these will go out of scope when leaving; [`nix shell` may be another matter though](https://github.com/NixOS/nix/issues/4715).</sup>

### 2.2 [`clam.nix`] parameters

TODO; type signature
```nix
{ nixShellDataDir ? ".nix-shell"
, cavern
, rump ? ""
}:
```

#### 2.2.1 `nixShellDataDir` :: String (default: `.nix-shell`)

The name of the temporary directory created in the **setup phase** (see sections **2. How clam.nix works** and **2.1 Setup** below) when entering the Nix shell to store application-specific data, instead of having those scattered around in the system (e.g., in the user's home directory, `/run`, etc.). This temporary directory will be deleted when exiting the shell (see **1.3 Clean-up** section).

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

## ∞. Pre-requisite concepts <sup>(work in progress)</sup>

### Derivation

TODO

### `$stdenv/setup`

TODO

### `nix-shell`

TODO

<sup>I believe that [`nix-shell`'s Nix manual entry](https://nixos.org/manual/nix/stable/#name-2) is grossly over-simplified, and its behaviour does raise [questions](https://hyp.is/nFTgRHFyEeunHQ9ZFhBBmA/toraritte.github.io/saves/Nix-Package-Manager-Guide-Version-2.3.10.html).</sup>

### `nix-shell` shell hook (or `shellHook`)

Shell hooks (in this context) are shell scripts executed once before entering the sub-shell set up by [`nix-shell`]. From [`nix-shell`'s Nix manual entry][`nix-shell`]:

> If the derivation defines the variable `shellHook`, it will be evaluated after `$stdenv/setup` has been sourced. Since this hook is not executed by regular Nix builds, it allows you to perform initialisation specific to `nix-shell`. For example, the derivation attribute
>
>     shellHook =
>       ''
>         echo "Hello shell"
>       '';
>
> will cause `nix-shell` to print "Hello shell".

+ [How to execute a script once during the shell build?][discourse_git_secret]

