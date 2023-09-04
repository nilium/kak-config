colorscheme triplejelly

define-command -params 0 -docstring 'open user config' edit-config %{
    edit "%val{config}/kakrc"
}

hook global RegisterModified '"' %{ nop %sh{
  printf %s "$kak_main_reg_dquote" | pbcopy
}}

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

# Doesn't work in iTerm -- requires an iTerm binding to send 0x1b;0xcb for
# <c-semicolon>.
map global normal <c-semicolon> <a-semicolon> -docstring 'swap caret locations'

# Buffer switching
map global goto n '<esc>:buffer-next<ret>' -docstring 'go to next buffer'
map global goto p '<esc>:buffer-previous<ret>' -docstring 'go to previous buffer'
map global goto q '<esc>:delete-buffer<ret>' -docstring 'delete buffer'
# Take some of the G mappings and add them to g
map global goto L '<esc>Gl'      -docstring 'extend selection to line end'
map global goto H '<esc>Gh'      -docstring 'extend selection to line begin'
map global goto G '<esc>Gg'      -docstring 'extend selection to buffer top'
map global goto E '<esc>Ge'      -docstring 'extend selection to buffer end'
map global goto I '<esc>Gi'      -docstring 'extend selection to line non blank start'
map global goto '<gt>' '<esc>G.' -docstring 'extend selection to last buffer change'

# Match mode, similar to what helix does.
declare-user-mode match

map global normal m ':enter-user-mode match<ret>'     -docstring 'match mode'
map global match m m                                  -docstring 'select next enclosed'
map global match M M                                  -docstring 'extend to next enclosed'
map global match n <a-m>                              -docstring 'select previous enclosed'
map global match N <a-M>                              -docstring 'extend to previous enclosed'

# Set up m sub-modes
define-command -params 2 -hidden define-match-commands %{
    map global %arg{1} -docstring 'parenthesis block'             'b'           "%arg{2}b"
    map global %arg{1} -docstring 'parenthesis block'             '('           "%arg{2}("
    map global %arg{1} -docstring 'parenthesis block'             ')'           "%arg{2})"
    map global %arg{1} -docstring 'brace block'                   'B'           "%arg{2}B"
    map global %arg{1} -docstring 'brace block'                   '{'           "%arg{2}{"
    map global %arg{1} -docstring 'brace block'                   '}'           "%arg{2}}"
    map global %arg{1} -docstring 'bracket block'                 'r'           "%arg{2}r"
    map global %arg{1} -docstring 'bracket block'                 '['           "%arg{2}["
    map global %arg{1} -docstring 'bracket block'                 ']'           "%arg{2}]"
    map global %arg{1} -docstring 'angle block'                   'a'           "%arg{2}a"
    map global %arg{1} -docstring 'angle block'                   '<lt>'        "%arg{2}<lt>"
    map global %arg{1} -docstring 'angle block'                   '<gt>'        "%arg{2}<gt>"
    map global %arg{1} -docstring 'double quote string'           '"'           "%arg{2}"""
    map global %arg{1} -docstring 'double quote string'           'Q'           "%arg{2}Q"
    map global %arg{1} -docstring 'single quote string'           ''''          "%arg{2}''"
    map global %arg{1} -docstring ',single quote string'          'q'           "%arg{2}q"
    map global %arg{1} -docstring 'grave quote string'            '`'           "%arg{2}`"
    map global %arg{1} -docstring 'grave quote string'            'g'           "%arg{2}g"
    map global %arg{1} -docstring 'word'                          'w'           "%arg{2}w"
    map global %arg{1} -docstring 'WORD'                          'W'           "%arg{2}<a-w>"
    map global %arg{1} -docstring 'sentence'                      's'           "%arg{2}s"
    map global %arg{1} -docstring 'paragraph'                     'p'           "%arg{2}p"
    map global %arg{1} -docstring 'whitespaces'                   '<space>'     "%arg{2}<space>"
    map global %arg{1} -docstring 'indent'                        'i'           "%arg{2}i"
    map global %arg{1} -docstring 'argument'                      'u'           "%arg{2}u"
    map global %arg{1} -docstring 'number'                        'n'           "%arg{2}n"
    map global %arg{1} -docstring 'custom object desc'            'c'           "%arg{2}c"
    map global %arg{1} -docstring 'run command in object context' '<semicolon>' "%arg{2}<semicolon>"
}

declare-user-mode match-inner
map global match i ':enter-user-mode match-inner<ret>' -docstring 'select inner objects'
define-match-commands match-inner '<a-i>'

declare-user-mode match-around
map global match a ':enter-user-mode match-around<ret>' -docstring 'select around objects'
define-match-commands match-around '<a-a>'

# Default to extending selection
map global normal T '<a-t>'
map global normal '<a-t>' T
map global normal F '<a-f>'
map global normal '<a-f>' F

# Clipboard
map global user '<space>' '<semicolon>,' -docstring 'clear selection'
map global user y '<a-|>pbcopy<ret>' -docstring 'copy selection to clipboard'
map global user p '<a-!>pbpaste<ret>' -docstring 'append clipboard after selection'
map global user P '!pbpaste<ret>' -docstring 'insert clipboard before selection'
map global user r '|pbpaste<ret>' -docstring 'replace selection with clipboard'

# Make n and N non-selection and v-n and v-N add selections
map global normal N '<a-n>'

# Add a basic selection mode for modal n/N instead of alt keys
map global normal <c-v> V
map global 'view' v '<esc>' -docstring 'exit view mode'
map global 'view' V '<esc>' -docstring 'exit view mode'
map global normal v ':enter-user-mode -lock multiselect<ret>'
declare-user-mode multiselect
map global multiselect -docstring 'add next search result to selection' 'n' 'N'
map global multiselect -docstring 'add prior search result to selection' 'N' '<a-N>'
map global multiselect j J -docstring 'extend selection down'
map global multiselect h H -docstring 'extend selection left'
map global multiselect l L -docstring 'extend selection right'
map global multiselect k K -docstring 'extend selection up'
map global multiselect v '<esc>' -docstring 'exit selection mode'

# Use tmux for splits:

# Add an extra tmux command to open a popup. Because...
define-command -params 1.. -shell-completion -docstring 'open a tmux popup' tmux-terminal-popup %{
    tmux-terminal-impl 'display-popup -E' %arg{@}
}

# Vague emulation of Vim split and vsplit, just to be a little easier on muscle
# memory.
define-command -params 0..1 -file-completion -docstring 'split horizontally' split %{
    tmux-terminal-vertical kak -c %val{session} %arg{@}
}

alias global hsplit split

define-command -params 0..1 -file-completion -docstring 'split vertically' vsplit %{
    tmux-terminal-horizontal kak -c %val{session} %arg{@}
}

map global user \" ':split<ret>' -docstring 'split horizontally'
map global user | ':vsplit<ret>' -docstring 'split vertically'

# Add line number column.
add-highlighter global/line-numbers number-lines -relative

# Highlight trailing whitespace as an error.
add-highlighter global/ regex \h+$ 0:Error

# Highlight matching symbols.
add-highlighter global/show-matching show-matching

# Keep context around the window borders.
set-option global scrolloff 3,5

# Format with comment
declare-option -docstring 'fmt buffer width' int fmt_textwidth 80
declare-option -docstring 'fmt command to use' str fmt_command %sh{
    for cmd in gfmt fmt; do
        if command -v $cmd; then break; fi
    done
}
define-command -params 0..1 'reformat' %{
    execute-keys -itersel %sh{ echo "x|$kak_opt_fmt_command -w${1:-$kak_opt_fmt_textwidth} -p$kak_quoted_opt_comment_line<ret>" }
}

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

# Use kak-bundle instead of plug, even if it's kinda janky and doesn't appear
# to work as well as plug.
evaluate-commands %sh{
  # We're assuming the default bundle_path here...
  plugins="$kak_config/bundle"
  mkdir -p "$plugins"
  [ ! -e "$plugins/kak-bundle" ] && \
    git clone -q https://github.com/jdugan6240/kak-bundle "$plugins/kak-bundle"
  printf "%s\n" "source '$plugins/kak-bundle/rc/kak-bundle.kak'"
}
bundle-noload kak-bundle https://github.com/jdugan6240/kak-bundle

bundle kak-session-name "https://github.com/nilium/kak-session-name" %{
} %{
    cargo install --force --path .
}

# parinfer -- matches braces in s-exprs.
bundle parinfer-rust "https://github.com/eraserhd/parinfer-rust" %{
    hook global WinSetOption filetype=(clojure|lisp|scheme|racket|fennel) %{
        parinfer-enable-window -smart
    }
} %{
    cargo install --force --path .
}

bundle kakoune-surround "https://github.com/h-youhei/kakoune-surround" %{
    map global match s ':surround<ret>'        -docstring 'add surround'
    map global match d ':delete-surround<ret>' -docstring 'delete surround'
    map global match r ':change-surround<ret>' -docstring 'replace surround'
}

# LSP support.
bundle kak-lsp "https://github.com/kak-lsp/kak-lsp" %{
    hook global WinSetOption filetype=(rust|go) %{
        try %{ racer-disable-autocomplete }
        lsp-enable-window
        lsp-inlay-hints-enable window
        hook window BufWritePre .* %{ try lsp-formatting-sync }
        map window normal <C-k> ': lsp-code-actions<ret>'
        map window normal <C-K> ': lsp-code-lens<ret>'
        map window user k ': lsp-hover<ret>'
        map window user K ': lsp-hover-buffer<ret>'
    }

    hook global WinSetOption filetype=(go) %{
        hook buffer BufWritePre .* %{ try %{ lsp-code-action-sync 'Organize Imports' } }
    }

    map global normal -docstring 'show hover information for cursor' <c-k> ': lsp-hover<ret>'
    map global user -docstring 'show hover information for cursor' k ': lsp-hover<ret>'
} %{
    cargo install --locked --force --path .
}

# Indentation
bundle smarttab.kak "https://github.com/andreyorst/smarttab.kak" %{
    hook global WinSetOption filetype=go %{
        smarttab
    }
    hook global WinSetOption filetype=(rust|markdown|kak) %{
        expandtab
    }
}

# fzf -- using personal branch that displays fzf in a popup. This does mean you
# can't have multiple fzf-s open at a time, which seems like a reasonable limit
# to me.
bundle fzf.kak "git clone -b tmux-popup https://github.com/nilium/fzf.kak" %{
    require-module fzf-file
    set-option global fzf_file_command 'fd -tf'

    require-module fzf-grep
    set-option global fzf_grep_command 'rg'

    map global user t ': fzf-mode<ret>f' -docstring 'open a file with fzf'
    map global user g ': fzf-mode<ret>g' -docstring 'open a file found with rg'
    map global user b ': fzf-mode<ret>b' -docstring 'open a buffer with fzf'
}

# Automatic pair insertion
# Pending https://github.com/mawww/kakoune/issues/3600
# bundle auto-pairs.kak "https://github.com/alexherbo2/auto-pairs.kak" %{
#     enable-auto-pairs
# }

bundle kakoune-state-save "https://gitlab.com/Screwtapello/kakoune-state-save" %{
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

bundle-customload kak-tree-sitter "https://github.com/phaazon/kak-tree-sitter" %{
    eval %sh{ kak-tree-sitter -dks --session $kak_session }
} %{
    cargo install --locked --path kak-tree-sitter kak-tree-sitter
    cargo install --locked --path ktsctl ktsctl
}
