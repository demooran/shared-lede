#!/usr/bin/env bash

# modify login IP
#sed -i 's/192.168.1.1/192.168.10.1/g' package/base-files/files/bin/config_generate

# replace geodata source
. $(dirname $0)/../extra-files/update-geodata.sh

# Change Hostname to PRO-MAX
sed -i 's/OpenWrt/PRO-MAX/g' package/base-files/files/bin/config_generate

# Add Argon Background
mkdir -p package/base-files/files/www/luci-static/argon/background
cp $(dirname $0)/../bg.jpg package/base-files/files/www/luci-static/argon/background/background.jpg

# Include Custom Package from Source
mkdir -p package/custom-packages
cp -r $(dirname $0)/../luci-app-vlanwizard package/custom-packages/

# Change SSH Port to 7642
sed -i 's/^#\?Port.*/Port 7642/g' package/network/services/dropbear/files/dropbear.config
