{ config, pkgs, lib, ... }:

{
    enable = true;
    autocd = false;
    oh-my-zsh.enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    plugins = [
    {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
    }
    {
        name = "powerlevel10k-config";
        src = lib.cleanSource ./.;
        file = "p10k.zsh";
    }
    ];

    shellAliases = {
    # Aliases
        ls="colorls";
        lc="colorls -lA --sd";
        cd="z";
        cat="bat";
        vi="nvim";
        vim="nvim";
    };
 
    initContent = lib.mkBefore ''
    #   ssh public key authentication
    #   export GPG_TTY="$(tty)"
        export SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
        gpgconf --launch gpg-agent

        # Define variables for directories
        export PATH=$HOME/.local/share/bin:$PATH

        # Remove history data we don't want to see
        export HISTIGNORE="pwd:ls:cd"

        # Ripgrep alias
        alias search=rg -p --glob '!node_modules/*'  $@

        # Emacs is my editor
        export ALTERNATE_EDITOR=""
        export EDITOR="nvim"
        export VISUAL="nvim"

        # nix shortcuts
        shell() {
            nix-shell '<nixpkgs>' -A "$1"
        }

        # -- Use fd instead of fzf --
        export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
        export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
        export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

        # Use fd (https://github.com/sharkdp/fd) for listing path candidates.
        # - The first argument to the function ($1) is the base path to start traversal
        # - See the source code (completion.{bash,zsh}) for the details.
        _fzf_compgen_path() {
        fd --hidden --exclude .git . "$1"
        }

        # Use fd to generate the list for directory completion
        _fzf_compgen_dir() {
        fd --type=d --hidden --exclude .git . "$1"
        }

        export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :500 {}'"
        export FZF_ALT_C_OPTS="--preview 'eza --tree --color=always {} | head -200'"

        # Advanced customization of fzf options via _fzf_comprun function
        # - The first argument to the function is the name of the command.
        # - You should make sure to pass the rest of the arguments to fzf.
        _fzf_comprun() {
        local command=$1
        shift

        case "$command" in
            cd)           fzf --preview 'eza --tree --color=always {} | head -200' "$@" ;;
            export|unset) fzf --preview "eval 'echo $'{}"         "$@" ;;
            ssh)          fzf --preview 'dig {}'                   "$@" ;;
            *)            fzf --preview "bat -n --color=always --line-range :500 {}" "$@" ;;
        esac
        }
    '';
}