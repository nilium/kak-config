colorscheme desertex

hook global RegisterModified '"' %{ nop %sh{
  printf %s "$kak_main_reg_dquote" | pbcopy
}}

# With how this interacts with registers, I think it's easier to use !pbpaste.
# Leaving it commented out in case I change my mind.
# map global user P '!pbpaste<ret>'
# map global user p '<a-!>pbpaste<ret>'
# map global user R '|pbpaste<ret>'

declare-user-mode buffer-nav

# Easier buffer navigation, based on my Vim bindings.
map global buffer-nav n ':buffer-next<ret>' -docstring 'go to next buffer'
map global buffer-nav p ':buffer-previous<ret>' -docstring 'go to previous buffer'

# Add intermediate mode for ,b mappings.
map global user b ':enter-user-mode buffer-nav<ret>' -docstring 'enter buffer-nav mode'
map global user q ':delete-buffer<ret>' -docstring 'close buffer'

# Convenience mappings because alt keys are hard for my hands.
map global user v <a-i> -docstring 'select inner object'
map global user V <a-a> -docstring 'select whole object'

# Add an extra tmux command to open a popup. Because...
define-command -params 1.. -shell-completion -docstring 'open a tmux popup' tmux-terminal-popup %{
    tmux-terminal-impl 'display-popup -E' %arg{@}
}

# Vague emulation of Vim split and vsplit, just to be a little easier on muscle
# memory.
define-command -params 0..1 -file-completion -docstring 'split horizontally' split %{
    tmux-terminal-vertical kak -c %val{session} %arg{@}
}

define-command -params 0..1 -file-completion -docstring 'split vertically' vsplit %{
    tmux-terminal-horizontal kak -c %val{session} %arg{@}
}

map global user \" ':split<ret>' -docstring 'split horizontally'
map global user | ':vsplit<ret>' -docstring 'split vertically'

# Add line number column.
add-highlighter global/line-numbers number-lines -relative

# plug.kak -- Plugin manager.
evaluate-commands %sh{
    plugins="$kak_config/plugins"
    mkdir -p "$plugins"
    [ ! -e "$plugins/plug.kak" ] && \
        git clone -q https://github.com/andreyorst/plug.kak.git "$plugins/plug.kak"
    printf "%s\n" "source '$plugins/plug.kak/rc/plug.kak'"
}
plug "andreyorst/plug.kak" noload

# parinfer -- matches braces in s-exprs.
plug "eraserhd/parinfer-rust" do %{
    cargo install --force --path .
} config %{
    hook global WinSetOption filetype=(clojure|lisp|scheme|racket|fennel) %{
        parinfer-enable-window -smart
    }
}

# LSP support.
plug "kak-lsp/kak-lsp" do %{
    cargo install --locked --force --path .
    # optional: if you want to use specific language servers
    mkdir -p ~/.config/kak-lsp
    cp -n kak-lsp.toml ~/.config/kak-lsp/
} config %{
    hook global WinSetOption filetype=(rust|go) %{
        lsp-enable-window
        lsp-inlay-hints-enable window
        lsp-auto-signature-help-enable
        hook window BufWritePre .* lsp-formatting-sync
    }
}

# Modeline
plug "andreyorst/powerline.kak" defer powerline %{
    powerline-separator global bars
    powerline-format global 'git bufname mode_info filetype lsp session client line_column position'
} defer powerline_desertex %{
    powerline-theme desertex
} config %{
    powerline-start
}

# Indentation
plug "andreyorst/smarttab.kak" config %{
    hook global WinSetOption filetype=(go) %{
        smarttab
    }
}

# Set some base indentation options for Go. These don't depend on smarttab, so
# are left out of that config block.
hook global BufSetOption filetype=(go) %{
    set-option buffer indentwidth 8
    set-option buffer tabstop 8
}

# fzf
plug "andreyorst/fzf.kak" defer fzf-file %{
    set-option global fzf_file_command 'fd -tf'
} defer fzf-grep %{
    set-option global fzf_grep_command 'rg'
} config %{
    map global user t ': fzf-mode<ret>f' -docstring 'open a file with fzf'
    map global user r ': fzf-mode<ret>g' -docstring 'open a file found with rg'
}
