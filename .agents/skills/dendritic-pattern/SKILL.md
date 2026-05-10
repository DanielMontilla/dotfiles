---
name: dendritic-pattern
description: Implement Nixpkgs dendritic pattern. Use when user mentions dendritic, flake-parts module system architecture, or organizing NixOS/home-manager configs. Includes migration checklists and file structure.
---

# Dendritic Pattern Skill

Pattern: Every Nix file (except entry points) = top-level module.

## When Use

User mentions: dendritic, flake-parts module system, organizing NixOS/home-manager configs, or migrating traditional Nix setup.

## Core Concept

- Top-level `flake.nix`/`default.nix` evaluates configuration via `lib.evalModules`
- Every other `.nix` file = module of top-level config
- File path = feature name
- Lower-level configs (NixOS, home-manager) stored as `deferredModule` option values
- Modules access shared values via top-level `config`

## File Structure

```
.
├── flake.nix                    # Entry point: imports all top-level modules
├── flake-parts.nix             # Top-level flake-parts + module system config
└── features/
    ├── default.nix             # Imports all feature modules (lib.filesystem.libRecursiveMerge)
    ├── nixos/                  # Feature: NixOS configuration
    │   └── default.nix         # Imports all nixos/*.nix feature modules
    ├── home-manager/           # Feature: home-manager configuration
    │   └── default.nix         # Imports all home-manager/*.nix feature modules
    └── packages/               # Feature: shared packages
        └── default.nix
```

## Minimal flake.nix

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs:
    inputs.flake-parts.lib.injectModules (self: {
      perSystem = { system, ... }: {
        _module.args.pkgs = import inputs.nixpkgs { inherit system; };
      };
      flake = {
        defaultPackage.* = self.packages.*; # dummy
      };
    }) // {
      checks = builtins.mapAttrs (_: lib.flip lib.nixosSystem {
        modules = [inputs.flake-parts.lib.injectModules self];
      }) self.nixosConfigurations;
    };
}
```

## Minimal flake-parts.nix

```nix
{
  imports = [
    inputs.flake-parts.modules.flake-parts-modules
  ];

  storedModules = {
    nixos = lib.nvim.lib.mkNixosModules ./nixos;
    home-manager = lib.nvim.lib.mkHomeManagerModules ./home-manager;
    packages = import ./packages;
  };

  perSystem = { system, pkgs, ... }: {
    options = {
      packages = lib.mkOption {
        type = lib.types.lines; # example: just concatenates all packages
        default = "";
      };
    };
    config = {
      packages = lib.concatMapStringsSep "\n" (m: m.packages or "") (lib.attrValues storedModules.nixos);
    };
  };
}
```

## Feature Module Example

```nix
# features/nixos/default.nix
{ lib, storedModules, ... }:
{
  imports = lib.mapAttrsToList (name: _:
    lib.nixosModule ./nixos/${name}
  ) builtins.readDir./nixos;
}
```

## Feature NixOS Sub-Module

```nix
# features/nixos/desktop.nix
{ config, lib, pkgs, ... }:
{
  options = {
    deferredModule = lib.mkOption {
      type = lib.types.deferredModule;
      default = {};
    };
  };
  config = {
    deferredModule = {
      imports = [./hardware.nix];
      config = {
        services.xserver.enable = true;
        environment.systemPackages = with pkgs; [vim git];
      };
    };
  };
}
```

## Sharing Values Across Features

```nix
# features/packages/default.nix
{ lib, storedModules, ... }:
{
  options.shared-packages = lib.mkOption {
    type = lib.types.listOf lib.types.package;
    default = [];
  };
  config = {
    shared-packages = with pkgs; [git curl wget];
  };
}
```

```nix
# features/nixos/desktop.nix - accessing shared packages
{ config, lib, pkgs, storedModules, ... }:
{
  config.deferredModule.config = {
    environment.systemPackages = storedModules.packages.shared-packages
      ++ (with pkgs; [firefox]);
  };
}
```

## Migration Checklists

### Phase 1: Preparation

- [ ] Audit current config structure
- [ ] Identify all NixOS/home-manager module files
- [ ] List all `specialArgs` passed between configs
- [ ] Identify shared packages, functions, constants
- [ ] Map each file to its feature (1 feature per file)

### Phase 2: Entry Points

- [ ] Create `flake.nix` with flake-parts + module system evaluation
- [ ] Create `flake-parts.nix` with `storedModules` for each config type
- [ ] Verify entry points evaluate without errors

### Phase 3: Extract Features

- [ ] Create `features/` directory
- [ ] Create `features/default.nix` importing all feature modules
- [ ] For each existing config file:
  - [ ] Determine its feature
  - [ ] Move to `features/<feature>/<name>.nix`
  - [ ] Add `deferredModule` option
  - [ ] Wrap existing config in `config.deferredModule`

### Phase 4: Remove specialArgs

- [ ] Identify all `specialArgs` usage
- [ ] For each `specialArgs` value:
  - [ ] Create top-level option in `flake-parts.nix`
  - [ ] Remove from lower-level configs
  - [ ] Access via `storedModules` instead
- [ ] Verify all cross-feature references work

### Phase 5: Verify

- [ ] `nix flake check` passes
- [ ] All NixOS configurations build
- [ ] All home-manager configurations apply
- [ ] No `specialArgs` remnants remain

## Common Patterns

### Importing All Files Recursively

```nix
lib.mapAttrsToList (name: _: ./${name})
  (builtins.readDir./features)
```

### NixOS Module Helper

```nix
lib.nixosModule = path: lib.nixosSystem {
  modules = [path];
  inherit specialArgs;
};
```

### Home-Manager Module Helper

```nix
lib.homeManagerModule = path: {
  imports = [path];
  _module.args = { inherit specialArgs; };
};
```

## Anti-Patterns to Avoid

- ❌ `specialArgs` pass-thru (use top-level `config` instead)
- ❌ One file = multiple features (split it)
- ❌ File paths encoding config type (use `deferredModule` type instead)
- ❌ Entry point files as modules (only `flake.nix`, `flake-parts.nix` are entry points)

## Links

- [Dendritic Pattern](https://github.com/mightyiam/dendritic)
- [flake-parts.modules](https://flake.parts/options/flake-parts-modules.html)
- [deferredModule type](https://nixos.org/manual/nixos/stable/#sec-option-types-submodule)
