# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an OpenWrt build system for BananaPi R4 router family with MediaTek MT7988 SoC. The project customizes OpenWrt with MediaTek-specific feeds and adds support for 5G modems (Telit FN990, Quectel RM585Q-AE) with custom LuCI applications for modem management.

## Architecture

### Build System
- **Main Build Scripts**:
  - `bpi-r4-openwrt-builder.sh` - Original build with Telit FN990 modem support
  - `build-r4pro-quectel.sh` - BPI-R4 Pro build with Quectel RM585Q-AE modem and dual WiFi 6E
- **Base OpenWrt**: Clones vanilla OpenWrt (master branch, commit 099633be82ee8a75a2f271b90f3a07e6e2c01ffc)
- **MediaTek Feeds**: Clones mtk-openwrt-feeds (commit 35d8f815835b4183fb412b47c055eff8cd7cec5e)
- **Autobuild Framework**: Uses MediaTek's autobuild.sh script for unified building

### Directory Structure
- `openwrt/` - OpenWrt build tree (created during build, not committed)
- `mtk-openwrt-feeds/` - MediaTek OpenWrt feeds (cloned during build)
- `my_files/` - Custom overlays and patches applied to the build
  - Custom feed revisions
  - Modified cmake.mk, defconfig, and build rules
  - QMI protocol handlers for modem connectivity
  - LuCI applications for modem management
- `configs/` - Pre-configured build configurations:
  - `config.basic` - Basic build for all R4 variants
  - `config.crypto.ext` - Build with crypto extensions
  - `config.mm.dbg` - Build with memory debugging
  - `config.telit` - Build with Telit FN990 modem support
  - `config.r4pro-quectel` - BPI-R4 Pro with Quectel RM585Q-AE and dual WiFi 6E

### Custom Components
The build extends OpenWrt with 5G modem support through:
- `sms-tool/` - SMS management utility
- `modemdata-main/` - Core modem data handling package (supports Quectel EC20/25, EP06, EG06/18, EM06/12/160R, RG500/502Q, RM500U, RM520N, RM585Q and Telit FN990)
- `luci-app-modemdata/` - LuCI web interface for modem data
- `luci-app-lite-watchdog/` - Watchdog application
- `luci-app-sms-tool-js/` - JavaScript-based SMS tool interface
- `qmi.sh` - Custom QMI protocol handler (replaces default uqmi handler)

### Build Process Flow
1. Disable SSL verification for git/curl/wget (network environment workaround)
2. Clean previous builds (removes openwrt/ and mtk-openwrt-feeds/)
3. Clone OpenWrt at specific commit
4. Clone MediaTek feeds at specific commit
5. Copy custom files from `my_files/` to override defaults:
   - Feed revisions for locked package versions
   - Modified cmake.mk for build system
   - Custom defconfig and rules for MediaTek autobuild
6. Run MediaTek autobuild framework: `autobuild.sh filogic log_file=make`
7. (Optional extension) Add Telit modem packages and run full build

## Build Commands

### Basic Build (MediaTek Default)
```bash
bash bpi-r4-openwrt-builder.sh
```
This runs the autobuild framework and exits at line 30. For full custom builds, remove the `exit 0` at line 31.

### BPI-R4 Pro Build with Quectel RM585Q-AE (Recommended)
```bash
bash build-r4pro-quectel.sh
```
This script builds for BPI-R4 Pro with:
- Dual WiFi 6E (MT7996E chipset)
- Quectel RM585Q-AE 5G modem support
- Full LuCI web interface with modem management
- All necessary kernel modules and drivers

The script will:
1. Clone and setup OpenWrt and MediaTek feeds
2. Run MediaTek autobuild framework
3. Add modem packages (sms-tool, modemdata, luci apps)
4. Apply BPI-R4 Pro configuration
5. Launch menuconfig for review
6. Build complete firmware

### Extended Build with Telit Modem Support
Remove or comment out `exit 0` at line 31 in `bpi-r4-openwrt-builder.sh`, then run:
```bash
bash bpi-r4-openwrt-builder.sh
```
This will:
1. Complete the basic build
2. Copy modem packages to OpenWrt feeds
3. Update and install all feeds
4. Copy custom QMI protocol handler
5. Set correct permissions
6. Apply Telit configuration
7. Launch menuconfig for final adjustments
8. Build with verbose output

### Manual Build After Setup
```bash
cd openwrt
make -j $(nproc) V=s
```

### Update Feeds
```bash
cd openwrt
./scripts/feeds update -a
./scripts/feeds install -a
```

### Configuration
```bash
cd openwrt
make menuconfig
```

### Clean Build
```bash
cd openwrt
make clean
```

### Full Rebuild
```bash
rm -rf openwrt mtk-openwrt-feeds
bash bpi-r4-openwrt-builder.sh
```

## Important Notes

### SSL Verification Disabled
The build script disables SSL verification for git, curl, and wget. This is a workaround for network environments with certificate issues. Remove if not needed:
- Lines 3-9 in `bpi-r4-openwrt-builder.sh`

### Locked Commits
The build uses specific git commits for reproducibility:
- OpenWrt: commit 099633be82ee8a75a2f271b90f3a07e6e2c01ffc (kernel 6.6.116)
- MTK feeds: commit 35d8f815835b4183fb412b47c055eff8cd7cec5e (NETSYS SER fast mode)

### Feed Revision Lock
`my_files/feed_revision` locks OpenWrt feed packages to specific commits:
- packages: 9c563686e2a96ccbad4ad51f8aa636c5322e6821
- luci: 87375a5cf045ac7891eca474919e9e185c734cc3
- routing: 149ea45cc223597262415823bcdca3effc601bc2

### File Overrides
Custom files in `my_files/` override OpenWrt defaults:
- `w-cmake.mk` → `openwrt/include/cmake.mk`
- `w-defconfig` → `mtk-openwrt-feeds/autobuild/unified/filogic/master/defconfig`
- `w-rules` → `mtk-openwrt-feeds/autobuild/unified/filogic/rules`
- `qmi.sh` → `package/network/utils/uqmi/files/lib/netifd/proto/`

### Target Platform
- **Target System**: MediaTek Ralink ARM
- **Subtarget**: Filogic 8x0 (MT798x)
- **Target Devices**:
  - BananaPi BPI-R4 (standard)
  - BananaPi BPI-R4 Pro (with dual WiFi 6E - MT7996E)
  - BananaPi BPI-R4 PoE
  - BananaPi BPI-R4 Lite
  - MediaTek MT7988A/D RFB
- **Kernel**: 6.6.116

### Hardware Features by Model
- **BPI-R4 Standard**: Single WiFi, basic modem support
- **BPI-R4 Pro**: Dual band WiFi 6E (MT7996E), M.2 slot for 5G modems (Quectel RM585Q-AE recommended)
- **BPI-R4 PoE**: PoE support, single WiFi
- **BPI-R4 Lite**: Cost-reduced variant

## Configuration Files

Each config in `configs/` is a complete OpenWrt .config file:
- `basic.defconfig` / `config.basic` - Minimal build for all R4 variants
- `config.crypto.ext` - Adds cryptographic hardware acceleration
- `config.mm.dbg` - Enables memory debugging for troubleshooting
- `config.telit` - Full featured build with Telit FN990 modem support (single WiFi)
- `config.r4pro-quectel` - **Recommended** for BPI-R4 Pro with Quectel RM585Q-AE and dual WiFi 6E

Key differences in `config.r4pro-quectel`:
- Targets BPI-R4 Pro specifically
- Includes MT7996E WiFi 6E drivers (dual band)
- Optimized for Quectel RM585Q-AE 5G modem
- Full USB modem kernel modules (qmi-wwan, cdc-ether, serial drivers)
- LuCI modem management apps pre-configured

To use a specific configuration:
```bash
cp configs/config.r4pro-quectel openwrt/.config
cd openwrt
make menuconfig  # Optional: review/modify
make -j $(nproc) V=s
```
