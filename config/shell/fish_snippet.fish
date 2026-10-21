# ========================================================
# RoxyOS Fish Shell Customization
# Sapphire & Celestial Cyan water-magic theme
# ========================================================

alias roxyfetch="fastfetch"

# Terminal greeting with Fastfetch
function fish_greeting
    if status is-interactive; and test -z "$ANTIGRAVITY_AGENT"; and test -z "$MCPSERVER"; and test "$TERM" != "dumb"
        fastfetch
    end
end

# Water-Magic Two-Line Prompt
function fish_prompt
    set -l last_status $status
    set -l cyan (set_color 38bdf8)
    set -l sapphire (set_color 0284c7)
    set -l white (set_color f8fafc)
    set -l gold (set_color facc15)
    set -l normal (set_color normal)

    echo -n "$sapphire╭─$cyan✧ $white"(prompt_pwd)" $cyan"
    if test $last_status -eq 0
        echo -n "$cyan➜ "
    else
        echo -n "$gold➜ "
    end
    echo -n "$normal"
end

function fish_right_prompt
    set -l sapphire (set_color 0284c7)
    set -l normal (set_color normal)
    echo -n "$sapphire[RoxyOS]$normal"
end
