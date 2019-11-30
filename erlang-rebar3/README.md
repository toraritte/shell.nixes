> **Note**
> The   main   source   of    truth   is   always   in
> [`shell.nix`](./shell.nix), with lots  of details in
> the comments.

## 0. start

```text
$ nix-shell
```

The  resulting shell  will have  all the  Rebar3 and
Erlang executables available.

### 0.0 words of caution

this project  is like a  hammer; all i needed  is to
get a  development environment ready  fast, whenever
starting to hack away on a project.

for  a  more  sophisticated and  granular  approach,
please take a look at the
[cw789/elixir_nix_seed](https://github.com/cw789/elixir_nix_seed)
repo. it is also very  educational when one wants to
learn  more  about  nix  and  how  to  organize  nix
scripts.

### 0.3 add environment variables

for example, needed google cloud storage for one project, and just added the following somewhere below `shellhook =`:

```nix
shellhook = ''

  # ...

  ####################################################################
  # allow access to google cloud apis
  # see https://github.com/googlecloudplatform/elixir-samples/tree/master/storage
  ####################################################################

  export google_application_credentials=`cat ./service_account.json`

  # ...
  ''
```
