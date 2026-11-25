# https://github.com/TenkyuChimata/linux-wireless-reg-unlocked
# https://aur.archlinux.org/packages/iwlwifi-lar-disable-dkms
# https://gitee.com/tianqi256/iwlwifi-force-mcc

_srcname=iwlwifi
pkgname=${_srcname}-dkms
pkgver=7.3.6
pkgrel=1
pkgdesc="Intel wireless chips driver from linux ($pkgver) with patch for lar_disable and force_mcc parameter 5GHz band support"
arch=('any')
url="https://wireless.wiki.kernel.org/en/users/drivers/iwlwifi"
license=('GPL-2.0-only')
depends=('dkms')
source=("iwlwifi-v${pkgver}.tar.gz"
        "dkms.conf"
        "0001-iwlwifi-add-lar_disable.patch"
        "0002-iwlwifi-nvm-unlock-6ghz-and-relax-channel-flags.patch"
        "0003-iwlwifi-add-force_mcc.patch")
sha256sums=('cba0b9c9b663947fe9783be81283374c3a46fc9e0117cf420d6b9b1e32cca16f'
            'f17ed01e8bfb36dfbf62982a29ad87b5c4ac86d8a5b2fb33716f844c3ff12824'
            'da2ab52ccdef2b93088c9e0c56bc1c166bf748d021b529cb2af2ff6c5d9e85cc'
            '96f91b3ff8d5caafe4939cb22bb455d34d107d08e14cf3af6dbb47ef70553732'
            'ade4d49f6cd1690c46a78cab1894d76d63f81e0fbd0491fe3301fc6649f16a8a')

options=(!strip)

prepare() {
  cd "$srcdir/iwlwifi"

  # https://www.mail-archive.com/linux-kernel@vger.kernel.org/msg1910510.html
  sed -i 's|$(srctree)/||' {d,m}vm/Makefile
  patch -Np6 -i "$srcdir/0001-iwlwifi-add-lar_disable.patch"
  patch -Np6 -i "$srcdir/0002-iwlwifi-nvm-unlock-6ghz-and-relax-channel-flags.patch"
  patch -Np6 -i "$srcdir/0003-iwlwifi-add-force_mcc.patch"
}


package() {

  # Install dkms.conf
  install -Dm644 dkms.conf "${pkgdir}/usr/src/${_srcname}-${pkgver}/dkms.conf"
  
  # Install sources (including Makefile)
  cp -rT iwlwifi "${pkgdir}/usr/src/${_srcname}-${pkgver}"

  # Set name and version
  sed -e "s/@PKGNAME@/${_srcname}/" \
      -e "s/@PKGVER@/${pkgver}/" \
      -i "${pkgdir}"/usr/src/${_srcname}-${pkgver}/dkms.conf
}
