> **Note**
> The   main   source   of    truth   is   always   in
> [`shell.nix`](./shell.nix), with lots  of details in
> the comments.

`clam-shell.nix` is an experiment to modularize `shell.nix`es in this repo, and is subject to break at the moment. `shell.nix` is the original, old-school one that I use in production for now.

## 0. Start

```text
$ nix-shell
```

This will  drop to a  shell with Elixir, Erlang, Phoenix, and  PostgreSQL installed, and a
latter server  will already  be spun up.  From there
one can use all the familiar Mix commands.
(See `shell.nix`es for the version numbers.)

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

If the issue is with not being able to connect to PostgreSQL, definitely try these:

+ https://gist.github.com/toraritte/f8c7fe001365c50294adfe8509080201#file-configure-postgres-to-allow-remote-connection-md

+ https://stackoverflow.com/questions/24504680/connect-to-postgres-server-on-google-compute-engine

+ https://stackoverflow.com/questions/47794979/connecting-to-postgres-server-on-google-compute-engine

#### 0.2.0 `psql: error: could not connect to server: No such file or directory`

Full error message:

```
psql: error: could not connect to server: No such file or directory
        Is the server running locally and accepting
        connections on Unix domain socket "/run/postgresql/.s.PGSQL.5432"?
```

I spend about 30-60 minutes each year debugging this issue, so finally adding this section as a reminder to self.

First off, check if PostgreSQL is running (which is highly likely):

1. By filtering `ps`:
   ```
   $ ps ax | grep postgres
   20777 ?        Ss     0:00 /nix/store/n4j3p6qq48292kr3ri7kgm7ldvm74mzi-postgresql-13.4/bin/postgres -D /home/toraritte/clones/shell.nixes/lofa/.nix-shell/db -c unix_socket_directories=/home/toraritte/clones/shell.nixes/lofa/.nix-shell/db -c listen_addresses=* -c log_destination=stderr -c logging_collector=on -c log_directory=log -c log_filename=postgresql-%Y-%m-%d_%H%M%S.log -c log_min_messages=info -c log_min_error_statement=info -c log_connections=on
   20779 ?        Ss     0:00 postgres: logger
   20782 ?        Ss     0:00 postgres: checkpointer
   20783 ?        Ss     0:00 postgres: background writer
   20784 ?        Ss     0:00 postgres: walwriter
   20785 ?        Ss     0:00 postgres: autovacuum launcher
   20786 ?        Ss     0:00 postgres: stats collector
   20787 ?        Ss     0:00 postgres: logical replication launcher
   21503 pts/18   S+     0:00 ag --hidden postgres
   ```

2. or via `netcat`:

   ```
   $ nc -zv localhost 5432
   Connection to localhost (::1) 5432 port [tcp/postgresql] succeeded!
   
   ```

If PostgreSQL is running, the usually the solution is using `-h localhost`, `--host=localhost`, `-h $PGDATA`, or `--host=$PGDATA` with every PostgreSQL command (e.g., `psql`, `createdb`). (All the listed forms are equivalent.)

The answer lies somewhere in [`man psql`](https://www.postgresql.org/docs/13/app-psql.html) and [19.1. The pg_hba.conf File](https://www.postgresql.org/docs/9.1/auth-pg-hba-conf.html) but forgot to write it down years ago when I figured it out...

#### 0.2.1 Another server already running ("port 5432 already in use")

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

   # This will usually suffice for testing:
   $ psql --host=$PGDATA --username=$(whoami) --dbname=$(whoami) --port=5433
   ```

   See the [`psql` doc](https://www.postgresql.org/docs/current/app-psql.html) for more.

#### 0.2.2 `psql: error: FATAL:  database "db_name" does not exist`

Using [1.3. Creating a Database](https://www.postgresql.org/docs/current/tutorial-createdb.html) with `-h | --host`:

```
$ createdb db_name --host=$PGDATA

# or
$ createdb $(whoami) --host=$PGDATA
```

#### 0.2.2 Starting `phx.server` results in `port: 4000]) for reason :eaddrinuse (address already in use)`

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
