#!/bin/bash

# BPI-R4 Pro Build Script with Quectel RM585Q-AE 5G Modem
# This script builds OpenWrt for BPI-R4 Pro with:
# - Dual WiFi 6E (MT7996E)
# - Quectel RM585Q-AE 5G modem support
# - LuCI web interface with modem management

# Trust all domains: disable SSL verification for the duration of this script
export GIT_SSL_NO_VERIFY=1
git config --global http.sslVerify false || true

# make curl/wget skip certificate checks (local wrappers)
curl() { command curl -k "$@"; }
wget() { command wget --no-check-certificate "$@"; }

#rm -rf openwrt
#rm -rf mtk-openwrt-feeds

# Clone OpenWrt at specific commit
GIT_SSL_NO_VERIFY=1 git -c http.sslVerify=false clone --branch master https://github.com/openwrt/openwrt.git openwrt || true
#cd openwrt; git checkout 099633be82ee8a75a2f271b90f3a07e6e2c01ffc; cd -;		#kernel: bump 6.6 to 6.6.116

# Clone MediaTek feeds at specific commit
GIT_SSL_NO_VERIFY=1 git -c http.sslVerify=false clone https://git01.mediatek.com/openwrt/feeds/mtk-openwrt-feeds || true
#cd mtk-openwrt-feeds; git checkout 35d8f815835b4183fb412b47c055eff8cd7cec5e; cd -;	#[kernel-6.12][common][eth][Add NETSYS SER fast mode]

# Copy feed revision to lock package versions
\cp -r my_files/feed_revision mtk-openwrt-feeds/autobuild/unified/

# Copy custom files for MediaTek build system
\cp -r my_files/w-cmake.mk openwrt/include/cmake.mk
\cp -r my_files/w-defconfig mtk-openwrt-feeds/autobuild/unified/filogic/master/defconfig
\cp -r my_files/w-rules mtk-openwrt-feeds/autobuild/unified/filogic/rules

# Run MediaTek autobuild framework
cd openwrt
bash ../mtk-openwrt-feeds/autobuild/unified/autobuild.sh filogic log_file=make

# Add Quectel modem packages to OpenWrt feeds
echo "Installing Quectel modem support packages..."
\cp -r ../my_files/sms-tool/ feeds/packages/utils/sms-tool
\cp -r ../my_files/modemdata-main/ feeds/packages/utils/modemdata
\cp -r ../my_files/luci-app-modemdata-main/luci-app-modemdata/ feeds/luci/applications
\cp -r ../my_files/luci-app-lite-watchdog/ feeds/luci/applications
\cp -r ../my_files/luci-app-sms-tool-js-main/luci-app-sms-tool-js/ feeds/luci/applications

# Update and install all feeds
./scripts/feeds update -a
./scripts/feeds install -a

# Copy custom QMI protocol handler for better modem compatibility
\cp -r ../my_files/qmi.sh package/network/utils/uqmi/files/lib/netifd/proto/
chmod -R 755 package/network/utils/uqmi/files/lib/netifd/proto
chmod -R 755 feeds/luci/applications/luci-app-modemdata/root
chmod -R 755 feeds/luci/applications/luci-app-sms-tool-js/root
chmod -R 755 feeds/packages/utils/modemdata/files/usr/share

# Apply BPI-R4 Pro with Quectel configuration
echo "Applying BPI-R4 Pro with Quectel RM585Q-AE configuration..."
\cp -r ../configs/config.r4pro-quectel .config

# Launch menuconfig for any final adjustments
echo "======================================================================"
echo "Configuration applied for BPI-R4 Pro with Quectel RM585Q-AE"
echo "Target: BananaPi BPI-R4 Pro"
echo "WiFi: Dual band WiFi 6E (MT7996E)"
echo "Modem: Quectel RM585Q-AE 5G"
echo "======================================================================"
echo ""
echo "Review the configuration in menuconfig (will launch automatically)"
echo "Press any key to continue..."
read -n 1 -s

make menuconfig

# Build with verbose output
echo "Starting build process..."
make -j $(nproc) V=s
