include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-quicksetup
PKG_VERSION:=1.0
PKG_RELEASE:=1

PKG_LICENSE:=Apache-2.0
PKG_MAINTAINER:=Your Name <your@email.com>

LUCI_TITLE:=LuCI Quick Setup Wizard
LUCI_DEPENDS:=+luci-base +wifi-scripts +wpad-basic-mbedtls
LUCI_PKGARCH:=all

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
$(eval $(call BuildPackage,$(PKG_NAME)))
