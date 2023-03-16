{ pkgs ? import <nixpkgs> {} }:
  pkgs.mkShell {
    buildInputs = [
        pkgs.python39Packages.ansible-core
    ];
}

