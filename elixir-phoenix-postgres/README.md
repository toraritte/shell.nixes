## 0. Start

```text
$ nix-shell
```

This will  drop to a  shell with Elixir  1.9, Erlang
R21, Phoenix 1.4.9, and  PostgreSQL installed, and a
latter server  will already  be spun up.  From there
one can use all the familiar Mix commands.

A  `.nix-shell` folder  will  be  created that  will
contain all  PostgreSQL- and Mix-related  files with
appropriate environment variables set up.

### 0.0 Words of caution

This project  is like a  hammer; all I needed  is to
get a  development environment ready  fast, whenever
starting to hack away on a project.

For  a  more  sophisticated and  granular  approach,
please take a look at the
[cw789/elixir_nix_seed](https://github.com/cw789/elixir_nix_seed)
repo. It is also very  educational when one wants to
learn  more  about  Nix  and  how  to  organize  Nix
scripts.

### 0.1 About [`_backup`](./_backup)

Had
[some issues installing Hex on my NixOS laptop](https://elixirforum.com/t/mix-local-hex-consumes-all-memory),
so if  the `_backup` folder is  present, `shell.nix`
will just  copy an offline  save of Hex  and Phoenix
1.4.9 to the project.

If  the folder  is deleted,  then the  usual install
routine  will run  (i.e., `mix  local.hex` and  `mix
archive.install hex phx_new`).

Tried this on recent  install of Ubuntu, no problems
there.

### 0.2 Possible issues

#### 0.2.0 Another server already running ("port 5432 already in use")

> TODO
>
> Obviously,  Nix's  purpose   is  to  automate  these
> manual configurations (such as  changing a port, and
> changing  any dependent  app  configs  with it),  so
> figure it out.

1. Uncomment the  line below the comment  `PORT ALREADY
   IN USE` in `shell.nix`,  and use another port (e.g.,
   5433).

2. Update  the used  Mix environment's  config file.
   For example, `config/dev.exs`:

   ```elixir
   config :anv, ANV.Repo,
     username: "your_username",
     password: "postgres",
     database: "db_name",
     # ...
     port: 5433
   ```

3. (Optional)  If  one  wants  to  connect  to  the
   PostgreSQL console:

   ```
   $ psql --host=$PGDATA --username=your_username --dbname=db_name --port=5433
   ```

   See the [`psql` doc](https://www.postgresql.org/docs/current/app-psql.html) for more.

#### 0.2.1 Starting `phx.server` results in `port: 4000]) for reason :eaddrinuse (address already in use)`

Another server  is already  running on  the machine,
hence port 4000 is taken.  Either stop that, or edit
`dev.exs` according to this
[Stackoverflow answer](https://stackoverflow.com/a/37912696/1498178):

> Edit your `config/dev.exs` and change the Endpoint http port like the following:
>
> ```elixir
> config :my_app, MyApp.Endpoint,
>   http: [port: System.get_env("PORT") || 4000],
> ```
>
> This allows the port to be set, or left as the default `4000`:
>
> ```text
> $ PORT=4002 mix phx.server
> $ PORT=4002 iex -S mix phx.server
>
> # will run on port 4000
> $ mix phoenix.server
> ```

### 0.3 Add environment variables

For example, needed Google Cloud Storage for one project, and just added the following somewhere below `shellHook =`:

```nix
shellHook = ''

  # ...

  ####################################################################
  # Allow access to Google Cloud APIs
  # See https://github.com/GoogleCloudPlatform/elixir-samples/tree/master/storage
  ####################################################################

  export GOOGLE_APPLICATION_CREDENTIALS=`cat ./service_account.json`

  # ...
  ''
```

## 1. Start a new Phoenix project

```text
$ nix-shell
```

Whichever  method  one  uses  below,  always  **edit
the  appropriate  environment config  file**  (e.g.,
`config/dev.exs`)   **with  the   correct  PostreSQL
credentials**. The default is

```elixir
config :anv, ANV.Repo,
  username: "postgres",
  password: "postgres",
```

but the username should be one's own username.

### 1.0 Into the current directory

```text
$ mix phx.new .
```

This will infer the main module's name from the name
of the  current directory, and drop  everything into
the project root.

Subsequent  `nix-shell`   calls  will  automatically
invoke `mix deps.get`  and `mix ecto.setup` (defined
in  `mix.exs`;   create  &  migrate  repo   and  run
`seeds.exs`).

#### 1.0.0 `.gitignore`

Delete  `_backup`  directory  if  you  have  no  Hex
install issues,  and may want to  put `shell.nix` in
`.gitignore`, unless modified  with project specific
stuff.

### 1.1 Into a sub-directory

```text
$ mix phx.new a_project
```

This will create a sub-directory, and just `cd` into
it; all commands will work.

The  automatic Mix  commands won't  run (`shell.nix`
only looks for a  `mix.exs` in the local directory),
but either modify `shell.nix`  with one's project, or
do it manually.
