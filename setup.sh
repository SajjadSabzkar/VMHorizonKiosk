  #!/bin/bash

USR=$SUDO_USER

if [ "$USR" == "" ]; then
  echo "You must run this Script with 'sudo'"
  exit 0
fi

interface=$(ip -br addr show up | grep -oP '^\S+(?=.*\s\d{1,3}(\.\d{1,3}){3}/)' | grep -v '^lo$')

#read username
read -p "Enter username: " username


# ==== TODO
#cd /tmp
#mkdir horizon
#cd horizon
#rm *deb > /dev/null 2>&1
#chmod +x VMware-Horizon-Client-5.5.6-21405009.x64.bundle
#./VMware-Horizon-Client-5.5.6-21405009.x64.bundle

#cd ..
#rm -rf horizon
# ==== TODO




sudo tee /usr/local/bin/WaitNetwork > /dev/null << 'EOF'
#!/bin/bash
INTERFACE=$(ip -br addr show up | grep -oP '^\S+(?=.*\s\d{1,3}(\.\d{1,3}){3}/)' | grep -v '^lo$')
while true; do
    IP=$(ip -4 addr show ${INTERFACE} | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '^127\.')
    if [ ! -z "${IP}" ]; then
        echo "IP address assigned: ${IP}"
        /usr/bin/vmware-view &>/dev/null &
        break
    fi
    echo "Waiting for Network ..."
    sleep 5
done

exit 0
EOF

# Make the script executable
sudo chmod +x /usr/local/bin/WaitNetwork

usermod -a -G audio $USR

# Config autostart app 
mv  /home/${USR}/.config/openbox/autostart  /home/${USR}/.config/openbox/autostart.old 2>/dev/null
cat >  /home/${USR}/.config/openbox/autostart <<EOF
#
# These things are run when an Openbox X Session is started.
# You may place a similar script in $HOME/.config/openbox/autostart
# to run user-specific things.
#

# If you want to use GNOME config tools...
#
#if test -x /usr/lib/x86_64-linux-gnu/gnome-settings-daemon >/dev/null; then
#  /usr/lib/x86_64-linux-gnu/gnome-settings-daemon &
#elif which gnome-settings-daemon >/dev/null 2>&1; then
#  gnome-settings-daemon &
#fi

# If you want to use XFCE config tools...
#
#xfce-mcs-manager &

## Group start:
## 1. nitrogen - restores wallpaper
## 2. compositor - start
## 3. sleep - give compositor time to start
## 4. tint2 panel
nitrogen --restore &
cbpp-compositor --start &
tint2 &

## Set root window colour 
hsetroot -solid "#2E3436" &

#conky
conky -q &
terminator -e /usr/local/bin/WaitNetwork &
xautolock -time 1000 -locker "screen_lock"&
EOF

#config conky
mv /home/${USR}/.conkyrc /home/${USR}/.conkyrc.old
cat << EOF > /home/${USR}/.conkyrc
# conky configuration
#
# The list of variables has been removed from this file in favour
# of keeping the documentation more maintainable.
# Check http://conky.sf.net for an up-to-date-list.
#
# For ideas about how to modify conky, please see:
# http://conky.sourceforge.net/variables.html
#
# For help with conky, please see:
# http://conky.sourceforge.net/documentation.html
#
# Enjoy! :)
##############################################
# Settings
##############################################
background yes
use_xft yes
xftfont Liberation Sans:size=9
xftalpha 1
update_interval 1.0
total_run_times 0
own_window yes
own_window_transparent yes
own_window_type desktop
#own_window_argb_visual yes
own_window_hints undecorated,below,sticky,skip_taskbar,skip_pager
double_buffer yes
minimum_size 200 200
maximum_width 240
draw_shades no
draw_outline no
draw_borders no
draw_graph_borders no
default_color 656667
default_shade_color 000000
default_outline_color 828282
alignment top_right
gap_x 12
gap_y 56
no_buffers yes
uppercase no
cpu_avg_samples 2
override_utf8_locale no
##############################################
#  Output
##############################################
TEXT
S Y S T E M    I N F O
\${hr}
Host:\$alignr\$nodename
Uptime:\$alignr\$uptime
RAM:\$alignr\$mem/\$memmax
Swap usage:\$alignr\$swap/\$swapmax
Disk usage:\$alignr\${fs_used /}/\${fs_size /}
CPU usage:\$alignr\${cpu cpu0}%
Local IP:\$alignr\${addr ${interface}}
DOWN: \${downspeed ${interface}}/s\$alignr UP: \${upspeed ${interface}}/s
# ip link
EOF

# Config Openbox Menu
mv  /home/${USR}/.config/openbox/menu.xml  /home/${USR}/.config/openbox/menu.xml.old 2>/dev/null

cat >  /home/${USR}/.config/openbox/menu.xml <<EOF

<?xml version="1.0" encoding="UTF-8"?>

<openbox_menu xmlns="http://openbox.org/"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://openbox.org/
                file:///usr/share/openbox/menu.xsd">

<menu id="root-menu" label="Openbox 3">
  <item label="Terminal emulator">
    <action name="Execute"><execute>x-terminal-emulator</execute></action>
  </item>

<item label="Horizon Client View">
  e <action name="Execute">
  <execute>/usr/bin/vmware-view</execute></action>
  </item>
  <separator />
  <item label="Reboot">
    <action name="Execute">
        <prompt>
            Are you sure you want to reboot?
        </prompt>
        <execute>
            systemctl reboot -i
        </execute>
    </action>
</item>

<item label="Shutdown">
    <action name="Execute">
        <prompt>
            Are you sure you want to shutdown?
        </prompt>
        <execute>
            systemctl poweroff -i
        </execute>
    </action>
</item>
</menu>

</openbox_menu>

EOF


# enable autologin for current User
sed -i "s/^# autologin=.*/autologin=$USR/" /etc/lxdm/default.conf

#Remove nm-applet from tint2
mv /etc/xdg/autostart/nm-applet.desktop /etc/xdg/autostart/nm-applet.desktop.old 2>/dev/null

#setting up username for horizon 
cp   /home/${USR}/.vmware/view-preferences   /home/${USR}/.vmware/view-preferences.old
cat >  /home/${USR}/.vmware/view-preferences <<EOF
view.defaultUser = '${username}'
view.allowSslProxy = 'FALSE'
view.autoConnectBroker = 'hrz-connection.hostname.local'
view.autoHideToolbar = 'FALSE'
view.defaultBroker = 'hrz-connection.hostname.local'
view.shareRemovableStorage = 'FALSE'
view.showSharingPromptDialog = 'FALSE'
view.sslVerificationMode = '3'
view.usbAutoConnectAtStartUp = 'TRUE'
view.usbAutoConnectOnInsert = 'TRUE'
EOF


#configure nitrogen background
mv  /home/${USR}/.config/nitrogen/bg-saved.cfg  /home/${USR}/.config/nitrogen/bg-saved.cfg.old 2>/dev/null
mv  /home/${USR}/.config/nitrogen/nitrogen.cfg  /home/${USR}/.config/nitrogen/nitrogen.cfg.old 2>/dev/null
cat >  /home/${USR}/.config/nitrogen/bg-saved.cfg <<EOF

[:0.0]
file=/usr/share/backgrounds/default-tile.png
mode=1
bgcolor=#2e3436

[xin_-1]
file= /home/${USR}/images/wallpapers/shared/bluebird.svg
mode=4
bgcolor=#000000
EOF

cat >  /home/${USR}/.config/nitrogen/nitrogen.cfg <<EOF
[geometry]
posx=902
posy=237
sizex=450
sizey=500

[nitrogen]
view=list
recurse=true
sort=alpha
icon_caps=false
dirs=/usr/share/backgrounds;

EOF

# Change Theme 
NEW_THEME="Bear2"

RC_XML="/home/${USR}/.config/openbox/rc.xml"

if [[ -f "$RC_XML" ]]; then
    awk -v new_theme="$NEW_THEME" '
    BEGIN { found=0 }
    /<theme>/ { found=1 }
    found && /<name>/ {
        gsub(/<name>.*<\/name>/, "<name>" new_theme "</name>")
        found=0
    }
    { print }
    ' "$RC_XML" > "$RC_XML.tmp" && mv "$RC_XML.tmp" "$RC_XML"
    
    openbox --reconfigure
    
    echo "Theme changed to $NEW_THEME and Openbox reconfigured."
else
    echo "Error: rc.xml file not found at $RC_XML"
fi

# Change VmHorizon To maximize
XML_FILE="/home/${USR}/.config/openbox/rc.xml"

new_code='
  <application class="Vmware-view" name="vmware-view" role="" type="normal">
    <maximized>yes</maximized>
  </application>
'

awk -v new_code="$new_code" '
  /<applications>/ {
    print
    print new_code
    next
  }
  { print }
' "$XML_FILE" > tmpfile && mv tmpfile "$XML_FILE"



#systemctl reboot
