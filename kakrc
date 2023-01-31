colorscheme triplejelly

hook global RegisterModified '"' %{ nop %sh{
  printf %s "$kak_main_reg_dquote" | pbcopy
}}

# With how this interacts with registers, I think it's easier to use !pbpaste.
# Leaving it commented out in case I change my mind.
# map global user P '!pbpaste<ret>'
# map global user p '<a-!>pbpaste<ret>'
# map global user R '|pbpaste<ret>'

map global normal <space> ","
map global normal , " "

# Doesn't work in iTerm -- requires an iTerm binding to send 0x1b;0xcb for
# <c-semicolon>.
map global normal <c-semicolon> <a-semicolon> -docstring 'swap caret locations'

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

# Highlight trailing whitespace as an error.
add-highlighter global/ regex \h+$ 0:Error

# Keep context around the window borders.
set-option global scrolloff 3,5

# Sort of janky command to align everything that matches the current literal
# selection.
define-command -params 0..1 align-in -docstring 'align all instances of the main selection in an object' %{
    evaluate-commands -draft %sh{
        obj="${1:-p}"
        case "$obj" in
        '%') :;;
        *) obj="<a-i>$obj";;
        esac
        expr="$(printf '%s' "$kak_selection" | sed -Ee 's/^/\\\\Q/;s/\\E/\\E\\\\\\\\E\\\\Q/g')"
        echo "execute-keys '${obj}s${expr}<ret>&'"
    }
}

# Also a janky command to strip whitespace on demand.
define-command strip-ws -docstring 'strip trailing whitespace from buffer' %{
    try %{ execute-keys -draft -save-regs '"' '%s[ \t]+$<ret>d' }
}

# plug.kak -- Plugin manager.
evaluate-commands %sh{
    plugins="$kak_config/plugins"
    mkdir -p "$plugins"
    [ ! -e "$plugins/plug.kak" ] && \
        git clone -q https://github.com/andreyorst/plug.kak.git "$plugins/plug.kak"
    printf "%s\n" "source '$plugins/plug.kak/rc/plug.kak'"
}
plug "andreyorst/plug.kak" noload

plug "nilium/kak-session-name" do %{
    cargo install --force --path .
}

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
        racer-disable-autocomplete
        lsp-enable-window
        lsp-inlay-hints-enable window
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
    hook global WinSetOption filetype=go %{
        smarttab
    }
    hook global WinSetOption filetype=(rust|markdown|kak) %{
        expandtab
    }
}

# Set some base indentation options for Go. These don't depend on smarttab, so
# are left out of that config block.
hook global BufSetOption filetype=go %{
    set-option buffer indentwidth 8
    set-option buffer tabstop 8
}

hook global BufSetOption filetype=(rust|markdown|kak) %{
    set-option buffer indentwidth 4
    set-option buffer tabstop 4
}

# fzf -- using personal branch that displays fzf in a popup. This does mean you
# can't have multiple fzf-s open at a time, which seems like a reasonable limit
# to me.
plug "nilium/fzf.kak" branch "tmux-popup" defer fzf-file %{
    set-option global fzf_file_command 'fd -tf'
} defer fzf-grep %{
    set-option global fzf_grep_command 'rg'
} config %{
    map global user t ': fzf-mode<ret>f' -docstring 'open a file with fzf'
    map global user r ': fzf-mode<ret>g' -docstring 'open a file found with rg'
}

# Automatic pair insertion
plug "alexherbo2/auto-pairs.kak" config %{
    enable-auto-pairs
}

plug "https://gitlab.com/Screwtapello/kakoune-state-save" config %{
    hook global KakBegin .* %{
        state-save-reg-load colon
        state-save-reg-load pipe
        state-save-reg-load slash
    }

    hook global KakEnd .* %{
        state-save-reg-save colon
        state-save-reg-save pipe
        state-save-reg-save slash
    }
}
