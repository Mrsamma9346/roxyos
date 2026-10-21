# ========================================================
# RoxyOS Powerlevel10k & Prompt Customization
# Sapphire & Celestial Cyan water-magic theme
# ========================================================
typeset -g POWERLEVEL9K_OS_ICON_CONTENT_EXPANSION='✧ RoxyOS'
typeset -g POWERLEVEL9K_OS_ICON_FOREGROUND=15
typeset -g POWERLEVEL9K_OS_ICON_BACKGROUND=31
typeset -g POWERLEVEL9K_DIR_BACKGROUND=24
typeset -g POWERLEVEL9K_DIR_FOREGROUND=255
typeset -g POWERLEVEL9K_PROMPT_CHAR_OK_{VIINS,VICMD,VIVIS,VIOWR}_FOREGROUND=39

# RoxyOS Terminal Greeting & Aliases
alias roxyfetch="fastfetch"
if [[ -o interactive ]] && [[ -z "$ANTIGRAVITY_AGENT" ]] && [[ -z "$MCPSERVER" ]] && [[ "$TERM" != "dumb" ]]; then
  fastfetch
fi
