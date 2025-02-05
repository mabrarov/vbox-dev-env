#!/bin/bash -eux

gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'
gsettings set org.gnome.desktop.interface enable-animations false
gsettings set org.gnome.desktop.interface clock-show-date true
gsettings set org.gnome.desktop.interface menubar-accel ""
gsettings set org.gnome.desktop.interface monospace-font-name "Source Code Pro 11"
gsettings set org.gnome.desktop.screensaver lock-enabled false
gsettings set org.gnome.desktop.session idle-delay 0
gsettings set org.gnome.mutter center-new-windows true
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('xkb', 'ru')]"
gsettings set org.gnome.desktop.sound event-sounds false
gsettings set org.gnome.shell favorite-apps "['firefox.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Terminal.desktop', 'code.desktop', 'jetbrains-idea.desktop', 'jetbrains-goland.desktop', 'jetbrains-clion.desktop']"

gsettings set org.gnome.desktop.wm.keybindings panel-main-menu "[]"
gsettings set org.gnome.desktop.wm.keybindings cycle-panels-backward "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-down "[]"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-right "[]"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-up "[]"
gsettings set org.gnome.desktop.wm.keybindings cycle-group-backward "[]"
gsettings set org.gnome.desktop.wm.keybindings begin-move "[]"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-left "[]"
gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-down "[]"
gsettings set org.gnome.desktop.wm.keybindings activate-window-menu "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-input-source "['<Super>space']"
gsettings set org.gnome.desktop.wm.keybindings switch-input-source-backward "[]"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-last "[]"
gsettings set org.gnome.desktop.wm.keybindings cycle-panels "[]"
gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-up "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-left "[]"
gsettings set org.gnome.desktop.wm.keybindings toggle-maximized "[]"
gsettings set org.gnome.desktop.wm.keybindings begin-resize "[]"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-down "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-last "[]"
gsettings set org.gnome.desktop.wm.keybindings cycle-group "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-up "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-right "[]"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-1 "['<Super>1']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-2 "['<Super>2']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-3 "['<Super>3']"
gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-4 "['<Super>4']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-1 "['<Super><Shift>Home','<Super><Shift>1']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-2 "['<Super><Shift>2']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-3 "['<Super><Shift>3']"
gsettings set org.gnome.desktop.wm.keybindings move-to-workspace-4 "['<Super><Shift>4']"

gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-left "['<Super><Shift>Left']"
gsettings set org.gnome.desktop.wm.keybindings maximize "['<Super>Up']"
gsettings set org.gnome.desktop.wm.keybindings unmaximize "['<Super>Down']"
gsettings set org.gnome.desktop.wm.keybindings panel-run-dialog "['<Super>r']"
gsettings set org.gnome.desktop.wm.keybindings move-to-monitor-right "['<Super><Shift>Right']"
gsettings set org.gnome.desktop.wm.keybindings switch-panels "['<Control><Alt>Tab']"
gsettings set org.gnome.desktop.wm.keybindings switch-panels-backward "['<Shift><Control><Alt>Tab']"
gsettings set org.gnome.desktop.wm.keybindings switch-applications "['<Super>Tab']"
gsettings set org.gnome.desktop.wm.keybindings switch-windows "['<Alt>Tab']"
gsettings set org.gnome.desktop.wm.keybindings switch-applications-backward "['<Shift><Super>Tab']"
gsettings set org.gnome.desktop.wm.keybindings switch-windows-backward "['<Shift><Alt>Tab']"
gsettings set org.gnome.desktop.wm.keybindings switch-group-backward "['<Shift><Super>Above_Tab']"
gsettings set org.gnome.desktop.wm.keybindings switch-group "['<Super>Above_Tab']"
gsettings set org.gnome.desktop.wm.keybindings show-desktop "['<Super>d']"

gsettings set org.gnome.settings-daemon.plugins.media-keys screenreader "[]"
gsettings set org.gnome.settings-daemon.plugins.media-keys magnifier "[]"
gsettings set org.gnome.settings-daemon.plugins.media-keys magnifier-zoom-out "[]"
gsettings set org.gnome.settings-daemon.plugins.media-keys magnifier-zoom-in "[]"
gsettings set org.gnome.settings-daemon.plugins.media-keys screencast "[]"

# https://askubuntu.com/questions/597395/how-to-set-custom-keyboard-shortcuts-from-terminal
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ name 'Terminal'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ command 'gnome-terminal'
gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/ binding '<Super>t'
gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']"

# Do not use F10 for activation of GNOME Terminal menu
gsettings set org.gnome.Terminal.Legacy.Settings menu-accelerator-enabled false
# Use F12 to toggle menu bar visibility
gsettings set org.gnome.Terminal.Legacy.Keybindings:/org/gnome/terminal/legacy/keybindings/ toggle-menubar "'F12'"
# Hide menu bar in GNOME Terminal by default
gsettings set org.gnome.Terminal.Legacy.Settings default-show-menubar false
# Set GNOME Terminal default geometry
profile=$(gsettings get org.gnome.Terminal.ProfilesList default)
profile=${profile:1:-1} # remove leading and trailing single quotes
gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$profile/" default-size-columns 140
gsettings set "org.gnome.Terminal.Legacy.Profile:/org/gnome/terminal/legacy/profiles:/:$profile/" default-size-rows 35
gsettings set org.gnome.Terminal.Legacy.Settings theme-variant 'dark'

gsettings set org.gnome.nautilus.list-view default-visible-columns "['name', 'size', 'type', 'date_modified']"
gsettings set org.gnome.nautilus.list-view default-column-order "['name', 'date_modified', 'type', 'size']"
gsettings set org.gnome.nautilus.preferences default-folder-viewer "'list-view'"
gsettings set org.gnome.nautilus.preferences show-hidden-files true

# Hide top bar in GNOME and enable Dash to Dock extension
gsettings set org.gnome.shell enabled-extensions "['alternate-tab@gnome-shell-extensions.gcampax.github.com', 'hidetopbar@mathieu.bidon.ca', 'dash-to-dock@micxgx.gmail.com', 'just-perfection-desktop@just-perfection']"

gnome_extensions_user_dir="${HOME}/.local/share/gnome-shell/extensions"

# Configure Dash to Dock GNOME extension to look like Ubuntu Dock
dash_to_dock_gnome_extensions_dir="${gnome_extensions_user_dir}/dash-to-dock@micxgx.gmail.com"
gsettings --schemadir "${dash_to_dock_gnome_extensions_dir}/schemas" \
  set org.gnome.shell.extensions.dash-to-dock apply-custom-theme true
gsettings --schemadir "${dash_to_dock_gnome_extensions_dir}/schemas" \
  set org.gnome.shell.extensions.dash-to-dock autohide true
gsettings --schemadir "${dash_to_dock_gnome_extensions_dir}/schemas" \
  set org.gnome.shell.extensions.dash-to-dock click-action "'previews'"
gsettings --schemadir "${dash_to_dock_gnome_extensions_dir}/schemas" \
  set org.gnome.shell.extensions.dash-to-dock custom-theme-shrink true
gsettings --schemadir "${dash_to_dock_gnome_extensions_dir}/schemas" \
  set org.gnome.shell.extensions.dash-to-dock dock-fixed true
gsettings --schemadir "${dash_to_dock_gnome_extensions_dir}/schemas" \
  set org.gnome.shell.extensions.dash-to-dock extend-height true
gsettings --schemadir "${dash_to_dock_gnome_extensions_dir}/schemas" \
  set org.gnome.shell.extensions.dash-to-dock dock-position "'LEFT'"
gsettings --schemadir "${dash_to_dock_gnome_extensions_dir}/schemas" \
  set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 48
gsettings --schemadir "${dash_to_dock_gnome_extensions_dir}/schemas" \
  set org.gnome.shell.extensions.dash-to-dock show-trash false

# Always hide GNOME top bar
hide_top_bar_gnome_extensions_dir="${gnome_extensions_user_dir}/hidetopbar@mathieu.bidon.ca"
gsettings --schemadir "${hide_top_bar_gnome_extensions_dir}/schemas" \
  set org.gnome.shell.extensions.hidetopbar enable-active-window "false"
gsettings --schemadir "${hide_top_bar_gnome_extensions_dir}/schemas" \
  set org.gnome.shell.extensions.hidetopbar enable-intellihide "false"

just_perfection_gnome_extensions_dir="${gnome_extensions_user_dir}/just-perfection-desktop@just-perfection"
# Remove Activities button from GNOME top bar
gsettings --schemadir "${just_perfection_gnome_extensions_dir}/schemas" \
  set org.gnome.shell.extensions.just-perfection activities-button false
# Start GNOME to Desktop and not to Overview
gsettings --schemadir "${just_perfection_gnome_extensions_dir}/schemas" \
  set org.gnome.shell.extensions.just-perfection startup-status 0

# Desktop background
gsettings set org.gnome.desktop.background color-shading-type "'solid'"
gsettings set org.gnome.desktop.background picture-options "'none'"
gsettings set org.gnome.desktop.background primary-color "'#425265'"

# Locks screen background
gsettings set org.gnome.desktop.screensaver color-shading-type "'solid'"
gsettings set org.gnome.desktop.screensaver picture-options "'none'"
gsettings set org.gnome.desktop.screensaver primary-color "'#425265'"

# Maximize window by double click on its title
gsettings set org.gnome.desktop.wm.preferences action-double-click-titlebar "'toggle-maximize'"
# Show minimize and maximize buttons in window title
gsettings set org.gnome.desktop.wm.preferences button-layout "'appmenu:minimize,maximize,close'"

# Do not highlight current line in GNOME Text Editor
gsettings set org.gnome.gedit.preferences.editor highlight-current-line false

# Disable virtual console hotkeys Ctrl+Alt+Fn
# Refer to https://askubuntu.com/questions/1331935/disable-virtual-console-hotkeys-ctrlaltf7-and-higher
gsettings set org.gnome.mutter.wayland.keybindings switch-to-session-1 "['']"
gsettings set org.gnome.mutter.wayland.keybindings switch-to-session-2 "['']"
gsettings set org.gnome.mutter.wayland.keybindings switch-to-session-3 "['']"
gsettings set org.gnome.mutter.wayland.keybindings switch-to-session-4 "['']"
gsettings set org.gnome.mutter.wayland.keybindings switch-to-session-5 "['']"
gsettings set org.gnome.mutter.wayland.keybindings switch-to-session-6 "['']"
gsettings set org.gnome.mutter.wayland.keybindings switch-to-session-7 "['']"
gsettings set org.gnome.mutter.wayland.keybindings switch-to-session-8 "['']"
gsettings set org.gnome.mutter.wayland.keybindings switch-to-session-9 "['']"
gsettings set org.gnome.mutter.wayland.keybindings switch-to-session-10 "['']"
gsettings set org.gnome.mutter.wayland.keybindings switch-to-session-11 "['']"
gsettings set org.gnome.mutter.wayland.keybindings switch-to-session-12 "['']"

# Disable Ctrl+Shift+U as default hotkey for entering unicode character, because this hotkey is used in IntelliJ IDEA.
# Refer to:
# https://youtrack.jetbrains.com/issue/IJPL-122452/Toggle-Case-Ctrl-Shift-U-not-working-under-Gnome-Linux
# https://superuser.com/a/1392682
gsettings set org.freedesktop.ibus.panel.emoji unicode-hotkey "@as []"

# Do not turn on power-save profile on low battery
gsettings set org.gnome.settings-daemon.plugins.power power-saver-profile-on-low-battery false
# Do not suspend automatically when there is no activity
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type "'nothing'"
gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type "'nothing'"
