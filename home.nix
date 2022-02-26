let
  pkgs = import ./default.nix { };
  inherit (pkgs.hax) isDarwin isLinux isM1 isNixOs isUbuntu isAndroid fetchFromGitHub;

  firstName = "everett";
  lastName = "berry";
  personalEmail = "";
  workEmail = "";

  onAws = builtins.getEnv "USER" == "ubuntu";
  promptChar = ">";

  # home-manager pin
  hm = with builtins; fromJSON (readFile ./sources/home-manager.json);
  home-manager = fetchFromGitHub {
    inherit (hm) rev sha256;
    owner = "nix-community";
    repo = "home-manager";
  };

  jpetrucciani = with builtins; fromJSON (readFile ./sources/jpetrucciani.json);
  cobi = import
    (fetchFromGitHub
      {
        inherit (jpetrucciani) rev sha256;
        owner = "jpetrucciani";
        repo = "nix";
      })
    { };

  sessionVariables = {
    EDITOR = "nano";
    HISTCONTROL = "ignoreboth";
    PAGER = "less";
    LESS = "-iR";
    BASH_SILENCE_DEPRECATION_WARNING = "1";
  };

in
with pkgs.hax; {
  nixpkgs.overlays = import ./overlays.nix;
  nixpkgs.config = { allowUnfree = true; };

  programs.home-manager.enable = true;
  programs.home-manager.path = "${home-manager}";
  _module.args.pkgs = pkgs;

  programs.htop.enable = true;
  programs.dircolors.enable = true;

  home = {
    username =
      if isDarwin then
        firstName
      else
        (if onAws then "ubuntu" else firstName);
    homeDirectory =
      if isDarwin then
        "/Users/${firstName}"
      else
        (if onAws then "/home/ubuntu" else "/home/${firstName}");
    stateVersion = "21.11";
    inherit sessionVariables;

    packages = with pkgs;
      lib.flatten [
        awscli2
        atool
        bash-completion
        bashInteractive_5
        bat
        cachix
        coreutils-full
        curl
        diffutils
        docker-client
        dos2unix
        ed
        exa
        fd
        figlet
        file
        fq
        gawk
        gcc
        gitAndTools.delta
        gnugrep
        gnupg
        gnused
        gnumake
        gnutar
        gron
        gzip
        hadolint
        jq
        just
        less
        libarchive
        libnotify
        lolcat
        loop
        lsof
        man-pages
        moreutils
        nano
        nodejs
        ncdu
        neofetch
        netcat-gnu
        nix-info
        nix_2_5
        nmap
        openssh
        pup
        ranger
        re2c
        redshift
        ripgrep
        ripgrep-all
        rlwrap
        rnix-lsp
        rsync
        scc
        sd
        shellcheck
        shfmt
        sox
        statix
        swaks
        time
        tealdeer
        tmux
        unzip
        watch
        wget
        which
        yank
        yq-go
        zip

        # python
        (python39.withPackages (pkgs: with pkgs; [
          # interactive
          (lib.optional isLinux bpython)

          # linting
          bandit
          black
          mypy
          flake8
          pylint

          # common use case
          httpx
          requests

          # text
          anybadge
          tabulate
          beautifulsoup4

          # api
          fastapi
          uvicorn

          # data
          numpy
          pandas
          scipy
        ]))

        # kubernetes
        kubectl
        kubectx

        # load in my custom checked bash scripts
        cobi.aws_bash_scripts
        cobi.general_bash_scripts
        cobi.docker_bash_scripts
        cobi.k8s_bash_scripts
        cobi.hax.comma

        # overlays
        nix_hash_unstable
        nix_hash_jpetrucciani
        nix_hash_hm

        # sounds
        cobi.meme_sounds
      ];
  };

  programs.bash = {
    enable = true;
    inherit sessionVariables;
    historyFileSize = -1;
    historySize = -1;
    shellAliases = {
      ls = "ls --color=auto";
      l = "${pkgs.exa}/bin/exa -alFT -L 1";
      ll = "ls -ahlFG";
      mkdir = "mkdir -pv";
      hm = "home-manager";
      ncdu = "${pkgs.ncdu}/bin/ncdu --color dark -ex";
      fzfp = "${pkgs.fzf}/bin/fzf --preview 'bat --style=numbers --color=always {}'";
      strip = ''
        ${pkgs.gnused}/bin/sed -E 's#^\s+|\s+$##g'
      '';

      # git
      g = "git";
      ga = "git add -A .";
      cm = "git commit -m ";

      # misc
      space = "du -Sh | sort -rh | head -10";
      now = "date +%s";
      uneek = "awk '!a[$0]++'";
    };
    initExtra = ''
      HISTCONTROL=ignoreboth
      set +h
      # fix for weird ubuntu error
      export PATH="$PATH:$HOME/.bin/"
      export PATH="$PATH:$HOME/.npm/bin/"

      _kube_contexts() {
        local curr_arg;
        curr_arg=''${COMP_WORDS[COMP_CWORD]}
        COMPREPLY=( $(compgen -W "- $(kubectl config get-contexts --output='name')" -- $curr_arg ) );
      }

      _kube_namespaces() {
        local curr_arg;
        curr_arg=''${COMP_WORDS[COMP_CWORD]}
        COMPREPLY=( $(compgen -W "- $(kubectl get namespaces -o=jsonpath='{range .items[*].metadata.name}{@}{"\n"}{end}')" -- $curr_arg ) );
      }

      # additional aliases
      [[ -e ~/.aliases ]] && source ~/.aliases

      # bash completions
      export XDG_DATA_DIRS="$HOME/.nix-profile/share:''${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
      source <(kubectl completion bash)
      source <(just --completions bash)
      source ~/.nix-profile/etc/profile.d/bash_completion.sh
      source ~/.nix-profile/share/bash-completion/completions/docker
      source ~/.nix-profile/share/bash-completion/completions/git
      source ~/.nix-profile/share/bash-completion/completions/ssh
      complete -o bashdefault -o default -o nospace -F __git_wrap__git_main g
      complete -F _docker d
      complete -F __start_kubectl k
      complete -F _kube_contexts kubectx kx
      complete -F _kube_namespaces kubens kns
    '';
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.readline = {
    enable = true;
    variables = {
      show-all-if-ambiguous = true;
      skip-completed-text = true;
      bell-style = false;
    };
    bindings = {
      "\\e[1;5D" = "backward-word";
      "\\e[1;5C" = "forward-word";
      "\\e[5D" = "backward-word";
      "\\e[5C" = "forward-word";
      "\\e\\e[D" = "backward-word";
      "\\e\\e[C" = "forward-word";
    };
  };

  programs.mcfly = {
    enable = false;
    enableBashIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableBashIntegration = false;
    defaultCommand = "fd -tf -c always -H --ignore-file ${./ignore} -E .git";
    defaultOptions = words "--ansi --reverse --multi --filepath-word";
  };

  programs.nnn = {
    enable = true;
  };

  home.file = {
    sqliterc = {
      target = ".sqliterc";
      text = ''
        .output /dev/null
        .headers on
        .mode column
        .prompt "> " ". "
        .separator ROW "\n"
        .nullvalue NULL
        .output stdout
      '';
    };
    prettierrc = {
      target = ".prettierrc.js";
      text = ''
        const config = {
          printWidth: 100,
          arrowParens: 'always',
          singleQuote: true,
          tabWidth: 2,
          useTabs: false,
          semi: true,
          bracketSpacing: false,
          jsxBracketSameLine: false,
          requirePragma: false,
          proseWrap: 'preserve',
          trailingComma: 'all',
        };
        module.exports = config;
      '';
    };
    ${attrIf isLinux "gpgconf"} = {
      target = ".gnupg/gpg.conf";
      text = ''
        use-agent
        pinentry-mode loopback
      '';
    };
    ${attrIf isLinux "gpgagentconf"} = {
      target = ".gnupg/gpg-agent.conf";
      text = ''
        allow-loopback-pinentry
      '';
    };
  };

  # starship config
  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      character = {
        success_symbol = "[${promptChar}](bright-green)";
        error_symbol = "[${promptChar}](bright-red)";
      };
      golang = {
        style = "fg:#00ADD8";
        symbol = "go ";
      };
      directory.style = "fg:#d442f5";
      nix_shell = {
        pure_msg = "";
        impure_msg = "";
        format = "via [$symbol$state($name)]($style) ";
      };
      kubernetes = {
        disabled = false;
        style = "fg:#326ce5";
      };
      terraform = {
        disabled = false;
        format = "via [$symbol $version]($style) ";
        symbol = "🌴";
      };
      nodejs = { symbol = "⬡ "; };
      hostname = {
        style = "bold fg:46";
      };
      username = {
        style_user = "bold fg:93";
      };

      # disabled plugins
      aws.disabled = true;
      cmd_duration.disabled = true;
      gcloud.disabled = true;
      package.disabled = true;
    };
  };

  # gitconfig
  programs.git = {
    enable = true;
    package = pkgs.gitAndTools.gitFull;
    userName = "${firstName} ${lastName}";
    userEmail = if isDarwin then workEmail else personalEmail;
    aliases = {
      branch-name = "!git rev-parse --abbrev-ref HEAD";
      # Push current branch
      put = "!git push origin $(git branch-name)";
      # Pull without merging
      get = "!git pull origin $(git branch-name) --ff-only";
    };
    extraConfig = {
      color.ui = true;
      push.default = "simple";
      pull.ff = "only";
      checkout.defaultRemote = "origin";
      core = {
        editor = if isDarwin then "code --wait" else "nano";
        pager = "delta --dark";
      };
      rebase.instructionFormat = "<%ae >%s";
    };
  };

  # fix vscode
  imports =
    if isNixOS then [
      "${fetchTarball "https://github.com/msteen/nixos-vscode-server/tarball/bc28cc2a7d866b32a8358c6ad61bea68a618a3f5"}/modules/vscode-server/home.nix"
    ] else [ ];

  ${attrIf isNixOS "services"}.vscode-server.enable = isNixOS;
}
