# TorchSDE without torch in closure
# Package name: torchsde-python313
#
# Overrides stock torchsde to remove torch from propagatedBuildInputs.
# torch is provided at runtime by the environment (via build-pytorch),
# not bundled in this package's closure. This prevents ABI mismatches
# when two different torch versions end up merged in the same env.

{ pkgs ? import <nixpkgs> {} }:

let
  # Import nixpkgs at a specific revision (pinned for version consistency)
  nixpkgs_pinned = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/fe5e41d7ffc0421f0913e8472ce6238ed0daf8e3.tar.gz";
  }) {
    config = { allowUnfree = true; };
  };

in nixpkgs_pinned.python3Packages.torchsde.overridePythonAttrs (oldAttrs: {
  pname = "torchsde-python313";

  # Remove torch from propagated deps — torch is provided by the runtime
  # environment via build-pytorch, not bundled in this package's closure
  propagatedBuildInputs = nixpkgs_pinned.lib.filter
    (p: (p.pname or "") != "torch")
    (oldAttrs.propagatedBuildInputs or []);

  # Add the relax-deps hook so pythonRemoveDeps is actually processed,
  # then strip torch from the wheel metadata so pythonRuntimeDepsCheckHook
  # doesn't fail when torch isn't in this derivation's closure
  nativeBuildInputs = (oldAttrs.nativeBuildInputs or []) ++ [
    nixpkgs_pinned.python3Packages.pythonRelaxDepsHook
  ];
  pythonRemoveDeps = [ "torch" ];

  # torchsde imports torch at module level; skip both the import check
  # and tests since torch isn't in this derivation's closure
  pythonImportsCheck = [];
  doCheck = false;

  postInstall = (oldAttrs.postInstall or "") + ''
    echo 1 > $out/.metadata-rev
  '';

  meta = oldAttrs.meta // {
    description = "TorchSDE (differentiable SDE solvers) without torch in closure";
  };
})
