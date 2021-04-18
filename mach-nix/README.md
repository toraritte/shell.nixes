The `shell.nix` has originally been written because [`mach-nix`](https://github.com/DavHau/mach-nix) is not in the [Nixpkgs repo](https://github.com/NixOS/nixpkgs) yet and so could call it with `nix-shell -p`, but as it turns out [one can call such Nix expression with `nix-shell`](https://discourse.nixos.org/t/how-to-invoke-nix-shell-p-for-packages-not-in-nixpkgs/12475) as well.

### Traditional way

```shell
nix-shell -p '(callPackage (fetchTarball https://github.com/DavHau/mach-nix/tarball/3.0.2) {}).mach-nix'
```

### Nix flakes

That is, if 

  1. [flakes support is enabled](https://nixos.wiki/wiki/Flakes#:~:text=Installing%20flakes) (at least, at the time of writing this, flakes are not yet enabled by default), and 
  
  2. the target repo also supports flakes (right?...),

one can do:

```shell
nix shell github:DavHau/mach-nix
```

Quoting [the rest](https://discourse.nixos.org/t/how-to-invoke-nix-shell-p-for-packages-not-in-nixpkgs/12475/3) verbatim because I have yet to understand it:

> I would just capture `mach-nix` in your `shell.nix` or `devShell` in your `flake.nix`. Then pair it with [`direnv`](https://direnv.net/) to allow you to bring it into your shell when you need it for a particular project.
