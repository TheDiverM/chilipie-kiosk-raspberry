# setter terminal rett
echo -e "$(tput -Txterm-256color bold)$1$(tput -Txterm-256color sgr 0)"

function working {
  echo-bold "\n[WORKING] $1"
}
function question {
  echo-bold "\n[QUESTION] $1"
}

#setter navn på maskin
sudo hostnamectl set-hostname McMox-Kiosk
sudo perl -i -p0e 's/raspberrypi/McMox-Kiosk/g' /etc/hosts # "perl" is more cross-platform than "sed -i"



#setter info om versjon
TAG=3.1.12
echo -e "$TAG\n\nhttps://github.com/futurice/chilipie-kiosk" > ../home/.mcmox-kiosk-version

# tar backup av originale boot filer
#BOOT_CMDLINE_TXT="$MOUNTED_BOOT_VOLUME/cmdline.txt"
BOOT_CMDLINE_TXT="/boot/cmdline.txt"
#BOOT_CONFIG_TXT="$MOUNTED_BOOT_VOLUME/config.txt"
BOOT_CONFIG_TXT="/boot/config.txt"


sudo cp -v "$BOOT_CMDLINE_TXT" "$BOOT_CMDLINE_TXT.backup"
sudo cp -v "$BOOT_CONFIG_TXT" "$BOOT_CONFIG_TXT.backup"

#setter korrekt environment
LOCALE="nb_NO.UTF-8 UTF-8" # or e.g. "fi_FI.UTF-8 UTF-8" for Finland
LANGUAGE="nb_NO.UTF-8" # should match above
echo $LOCALE | sudo tee /etc/locale.gen
sudo locale-gen
echo -e \"LANGUAGE=$LANGUAGE\nLC_ALL=$LANGUAGE\" | sudo tee /etc/environment


# Setter opp 3 skjermer
sudo ln -fs /lib/systemd/system/getty@.service /etc/systemd/system/getty.target.wants/getty@tty1.service
sudo ln -fs /lib/systemd/system/getty@.service /etc/systemd/system/getty.target.wants/getty@tty2.service
sudo ln -fs /lib/systemd/system/getty@.service /etc/systemd/system/getty.target.wants/getty@tty3.service
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d
sudo mkdir -p /etc/systemd/system/getty@tty2.service.d
sudo mkdir -p /etc/systemd/system/getty@tty3.service.d
echo -e '[Service]\nExecStart=\nExecStart=-/sbin/agetty --autologin pi --noclear %I xterm\n' | sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf
echo -e '[Service]\nExecStart=\nExecStart=-/sbin/agetty --autologin pi --noclear %I xterm\n' | sudo tee /etc/systemd/system/getty@tty2.service.d/autologin.conf
echo -e '[Service]\nExecStart=\nExecStart=-/sbin/agetty --autologin pi --noclear %I xterm\n' | sudo tee /etc/systemd/system/getty@tty3.service.d/autologin.conf


#setter timezone
TIMEZONE=Europe/Oslo
echo $TIMEZONE | sudo tee /etc/timezone && sudo dpkg-reconfigure --frontend noninteractive tzdata

#setter norsk tastatur
KEYBOARD=no
echo -e 'XKBMODEL="pc105"\nXKBLAYOUT="$KEYBOARD"\nXKBVARIANT=""\nXKBOPTIONS=""\nBACKSPACE="guess"\n' | sudo tee /etc/default/keyboard && sudo dpkg-reconfigure --frontend noninteractive keyboard-configuration"

# "Silencing console logins # this is to avoid a brief flash of the console login before X comes up
sudo rm /etc/profile.d/sshpwd.sh /etc/profile.d/wifi-check.sh # remove warnings about default password and WiFi country (https://raspberrypi.stackexchange.com/a/105234)
touch .hushlogin # https://scribles.net/silent-boot-on-raspbian-stretch-in-console-mode/
sudo perl -i -p0e 's#--autologin pi#--skip-login --noissue --login-options \"-f pi\" #g' /etc/systemd/system/getty@tty1.service.d/autologin.conf # "perl" is more cross-platform than "sed -i"


#installerer programmer

#"Installing packages"
sudo apt-get update && DEBIAN_FRONTEND=noninteractive sudo apt-get install -y vim matchbox-window-manager unclutter mailutils nitrogen jq chromium-browser xserver-xorg xinit rpd-plym-splash xdotool rng-tools xinput-calibrator cec-utils
# We install mailutils just so that you can check "mail" for cronjob output


# kopier inn filer for default oppsett
# fra /home katalogen


# working Setter boot bilde, legg inn rett bilde
sudo rm /usr/share/plymouth/themes/pix/splash.png && sudo ln -s /home/pi/background.png /usr/share/plymouth/themes/pix/splash.png

# installing rpi-connect
sudo apt-get -y install rpi-connect


# Installing default crontab
ssh "crontab /home/pi/crontab.example"


# "Making boot quieter (part 1)" # https://scribles.net/customizing-boot-up-screen-on-raspberry-pi/
echo "Updating: $BOOT_CONFIG_TXT"
sudo perl -i -p0e "s/#disable_overscan=1/disable_overscan=1/g" "$BOOT_CONFIG_TXT" # "perl" is more cross-platform than "sed -i"
sudo echo -e "\ndisable_splash=1" >> "$BOOT_CONFIG_TXT"


# "Making boot quieter (part 2)" # https://scribles.net/customizing-boot-up-screen-on-raspberry-pi/
echo "You may want to revert these changes if you ever need to debug the startup process"
echo "Updating: $BOOT_CMDLINE_TXT"
cat "$BOOT_CMDLINE_TXT" \
  | sed 's/console=tty1/console=tty3/' \
  | sed 's/$/ splash plymouth.ignore-serial-consoles logo.nologo vt.global_cursor_default=0/' \
  > temp
mv temp "$BOOT_CMDLINE_TXT"




