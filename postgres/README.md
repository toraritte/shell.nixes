## NOTE / TODO

This will create a `.nix-shell` directory to house runtime files, and will also tear it down ([soundtrack](https://www.youtube.com/watch?v=HO7XHXGCbCQ)) after exiting the `nix-shell`. The problem is that this behaviour makes it less composable (e.g., with `nginx_shell.nix` that also sets up a temporary directory.

+ What if each `shell.nix` sets up its own dedicated directory that could be deleted on their own discretion? 

  For example, `postgres_shell.nix` does not need to retain its own because that PostgreSQL instance is for dev purposes anyway (just look at the permissions in the `shell-hook.sh`). `nginx_shell.nix` needs the temporary directory for the logs that may need to be retained (or, even better, should be timestamped to distinguish each run).
