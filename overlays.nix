[
  (prev: next:
    (x: { hax = x; })
      (
        with next;
        with lib;
        with builtins;
        lib // rec {
          inherit (stdenv) isLinux isDarwin isAarch64;
          inherit (pkgs) fetchFromGitHub;

          isM1 = isDarwin && isAarch64;
          isNixOS = isLinux && (builtins.match ".*ID=nixos.*" (builtins.readFile /etc/os-release)) == [ ];
          isAndroid = isAarch64 && !isDarwin && !isNixOS;
          isUbuntu = isLinux && (builtins.match ".*ID=ubuntu.*" (builtins.readFile /etc/os-release)) == [ ];
          isNixDarwin = builtins.getEnv "NIXDARWIN_CONFIG" != "";

          attrIf = check: name: if check then name else null;

          jpetrucciani = with builtins; fromJSON (readFile ./sources/jpetrucciani.json);
          cobi = import (
            next.pkgs.fetchFromGitHub
              {
                inherit (jpetrucciani) rev sha256;
                owner = "jpetrucciani";
                repo = "nix";
              });
        }
      ))
  (prev: next: {
    _nix_hash = with next; with hax; repo: branch: name: (
      writeShellScriptBin "nix_hash_${name}" ''
        ${nix-prefetch-git}/bin/nix-prefetch-git \
          --quiet \
          --no-deepClone \
          --branch-name ${branch} \
          https://github.com/${repo}.git | \
        ${jq}/bin/jq '{ rev: .rev, sha256: .sha256 }'
      ''
    );
    nix_hash_unstable = prev._nix_hash "NixOS/nixpkgs" "nixpkgs-unstable" "unstable";
    nix_hash_jpetrucciani = prev._nix_hash "jpetrucciani/nix" "main" "jpetrucciani";
    nix_hash_hm = prev._nix_hash "nix-community/home-manager" "master" "hm";
    home-packages = (import ../home.nix).home.packages;
  })
]
