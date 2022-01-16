# nix

[![uses nix](https://img.shields.io/badge/uses-nix-%237EBAE4)](https://nixos.org/)

_everett's nixpkgs setup and overlays_

## install

```bash
# install nix
## linux and mac
curl -L https://nixos.org/nix/install | sh

# configure nix
mkdir -p ~/.config/nix/
echo -e 'max-jobs = auto\ntarball-ttl = 0\nexperimental-features = nix-command flakes' >>~/.config/nix/nix.conf

# cachix (optional)
nix-env -iA nixpkgs.cachix
# on multi-user, this may require sudo!
cachix use jacobi

# install home manager (if using it)
echo "export NIX_PATH=/nix/var/nix/profiles/per-user/$USER/channels:nixpkgs=/nix/var/nix/profiles/per-user/root/channels/nixpkgs:/nix/var/nix/profiles/per-user/root/channels" | sudo tee -a /etc/profile
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install

# pull repo into ~/.config/nixpkgs/
cd ~/.config/nixpkgs
rm home.nix

# read only
git clone https://github.com/everettberry/nix.git .

# write access (requires a ssh key)
git clone git@github.com:everettberry/nix.git .

# enable home-manager
home-manager switch
```
