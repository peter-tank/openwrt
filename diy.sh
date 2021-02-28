#!/bin/bash

custom_clones() {
local target=$1
local ret repo_url line url sets branch commit

ret=99
# shortcut-sfe@LINUX_4_9 == flowoffload
repo_url=(
'https://github.com/apollo-ng/luci-theme-darkmatter.git^luci-theme-darkmatter,openwrt-19,97362ca3d70e2d775bc596ad386ba4b1a8a0303b'
'https://github.com/peter-tank/luci-app-clash.git^luci-app-clash,master^c98225e76e140800bed55f858a88ac3896ea462e'
'https://github.com/peter-tank/openwrt-v2ray.git^v2ray,master^d8d09cc9384fb475c478a66ba6c9d1fd4ff39baa'
'https://github.com/peter-tank/luci-app-ssr-plus.git^luci-app-ssr-plus,master^9a6e783863fb967ae43f693cc435766e7be4553d'
'https://github.com/peter-tank/luci-app-frpc.git^luci-app-frpc,master^2c63c14d6e4416a8f46a4d9a63c3da0c12a97693'
'https://github.com/peter-tank/openwrt-frp.git^frp,master^b0db56de80ddd69f9fe7645bfad7a1c813a06cdc'
'https://github.com/peter-tank/luci-app-dnscrypt-proxy2.git^luci-app-dnscrypt-proxy2,master^04cb685803132195705324bf060881a9aed6f8bb'
'https://github.com/peter-tank/openwrt-autorepeater.git^luci-app-autorepeater,master^c6e92219ca33716f5cb0900a765e989b0a0817e3'
'https://github.com/pexcn/openwrt-chinadns-ng.git^chinadns-ng,master^a54e2005680a3ac3ea1e9e6c90ded872e5c7aaf7'
'https://github.com/pexcn/openwrt-dns2tcp.git^dns2tcp,master^dadf60f44cf5c1eeb5dc6414f5d874802ada0a03'
'https://github.com/peter-tank/openwrt-minisign.git^minisign,master^5774230b1d2d7475589becf1dd76db02eeed0e4d'
'https://github.com/shadowsocks/openwrt-shadowsocks.git^shadowsocks-libev,master^123f917c69706147cefb8e1e72c118e7c7da9ce5'
'https://github.com/shadowsocks/openwrt-feeds.git^shadowsocks-feed,master^f820447956c77a412a694022d91c4b812f216d47'
'https://github.com/peter-tank/openwrt-vlmcsd.git^vlmcsd,master^287970f48cca3aea74ac83f5ac0fb7ccac4898f7'
'https://github.com/peter-tank/luci-app-vlmcsd.git^luci-app-vlmcsd,master^2b9317712b3c172da07bb370090e569998c26d3f'
)

#'https://github.com/trojan-gfw/openwrt-trojan.git^openwrt-trojan,master^812be6d80d9fc57db536821ef3d00ea1af9f4eda'
#'https://github.com/peter-tank/luci-app-fullconenat.git^luci-app-fullconenat,master^1f9fb21d627921f95d97370f2cbde16b4ace3974'
#'https://github.com/peter-tank/openwrt-fullconenat.git^iptables-mod-fullconenat,master^57e30de22896ef9b0f60cccf18ad64c1d989c7c0'
#'https://github.com/peter-tank/luci-app-flowoffload.git^luci-app-flowoffload,master^3799eaaa8caf21c5310a59d533991836755aff54'

mkdir -p "$target"
ret=$?
[ $ret -eq 0 ] || return 1
pushd "$target"
for line in ${repo_url[@]}; do
  sets="${line%%,*}"
  url="${sets%%^*}"
  pkg="${sets##*^}"
  sets="${line##*,}"
  branch="${sets%%^*}"
  commit="${sets##*^}"

  #git clone --branch "$branch" --depth 1 --progress -- "$url" "$pkg"
  mkdir "$pkg" && pushd "$pkg"
  ret=$?
  [ $ret -eq 0 ] || return 2
  git init
  git remote add origin "$url"
  git fetch origin "$branch:refs/remotes/origin/$branch"
  #git checkout -b "$branch" "$commit" --track "origin/$branch"
  git checkout -b "$branch" "$commit"
  ret=$?
  popd
  [ $ret -eq 0 ] || return 3
done
popd
ls -la "$target"

return $ret
}

patch_fetched() {
local repo=$1
local target=$2
local patch_helper=$3
local with_kernel=$4
local listf=$5
local device base

local ret rep kernel fc_commit fc_name fc_diff kr repo file dst

ret=99
device=${target##*.}
target=${target%%.*}

kr=$(sed -ne 's/^KERNEL_PATCHVER:=\(.*\)$/\1/p' target/linux/${target}/Makefile)
kernel="${kr}$(sed -ne "s/^LINUX_VERSION-${kr}.*\(\..*\)$/\1/p" include/kernel-version.mk)"

  case $kr in
   4.14 )
           fc_commit=75a282ace767a8a36b3a9c40d7ace96e55575b68
           fc_name=952-net-conntrack-events-support-multiple-registrant.patch
           fc_diff=952_kernel_4.14.154_156.diff
           ;;
   4.19 )
           fc_commit=5a6f9be7242f56aedf91f28bc4274fa4e9f07464
           fc_name=952-net-conntrack-events-support-multiple-registrant.patch
           fc_diff=952_kernel_4.14.154_156.diff
           ;;
   4.9 )
           fc_commit=75a282ace767a8a36b3a9c40d7ace96e55575b68
           fc_name=952-net-conntrack-events-support-multiple-registrant.patch
           fc_diff=
           ;;
  esac

pkg_path() {
  local pkg=$1

  grep -m1 "^${pkg}\," ${listf} | cut -d' ' -f2
}

if [ -z "$patch_helper" ]; then
  case $target in
   ar71xx )
echo "# patch 4300 128M nand" https://dev.archive.openwrt.org/changeset/48456
#backup caldata after flash
#dd if=/dev/mtdblock2 of=/dev/mtdblock10
dst='target/linux/ar71xx/image/legacy.mk'
sed -i -e 's/^\(wndr4300_mtdlayout.*\),23552k(ubi),25600k@\(.*\)$/\1,120832k(ubi),122880k@\2/' ${dst}
grep -Hn ^wndr4300_mtdlayout  ${dst}
   ;;
   ath79 )
echo "# patch for ath79 Large Nand port no needed"
dst='target/linux/ath79/dts/ar9344_netgear_wndr.dtsi'
grep -Hn -A70 partitions  ${dst}
   ;;
   * ) echo "# None Large Nand"
   ;;
  esac

echo "# patch default dnsmasq to dnsmasq-full"
dst='include/target.mk'
sed -i -e 's/^\(DEFAULT_PACKAGES.router:.*\)dnsmasq \(.*\)$/\1dnsmasq-full \2/' ${dst}
grep -Hn -C2 ^DEFAULT_PACKAGES ${dst}

echo "# patch kernel ${kernel} on fullconenat workaround for conflicting with module nf_conntrack_netlink"
# https://github.com/coolsnowwolf/lede/commit/75a282ace767a8a36b3a9c40d7ace96e55575b68
# share patcher for kernel 4.14 & 4.19
if [ "${kr}" == "4.9" ]; then
  file="${fc_name}.${kr}"
else
  file="${fc_name}.4.1x"
fi
if [ -n "${fc_name}" ]; then
dst="target/linux/generic/hack-${kr}/${fc_name}"
cp -vf "${file}" "${dst}"
[ -z "${fc_diff}" -o ! -f "${fc_diff}" ] || patch --verbose -N -p2 -o "${dst}" "${file}" < "${fc_diff}"
else
echo "Skip fullcone"
fi

[ -n "${listf}" ] && {
if [ -n "${fc_name}" ]; then
echo "# patch fullconenat kernel module to v2019.11.20"
file="$(pkg_path fullconenat)/Makefile"
sed -i -e 's/^\(.*\)d4daedd0e25309e822577e92b96ae4c7184abe83/\10cf3b48fd7d2fa81d0297d1fff12bbd0580fc435/' $file
grep -Hn -A8 "^PKG_NAME" $file

echo "# patch firewall to enable flowoffload and fullconenat modes in default & patch fw3 enable FULLCONENAT in default"
dst="$(pkg_path firewall)"
file="${dst}/files/firewall.config"
sed -i -e '/option fullcone/d' $file
sed -i -e '/^config defaults/ {' -e 'n; i\\toption fullcone\t1' -e '}' $file
# for new fw3 patch
sed -i -e '/option masq/ {' -e 'n; i\\toption fullcone\t1' -e '}' $file
sed -i -e '/option flow_offloading/d' $file
sed -i -e '/^config defaults/ {' -e 'n; i\\toption flow_offloading_hw\t1' -e '}' $file
sed -i -e '/^config defaults/ {' -e 'n; i\\toption flow_offloading\t1' -e '}' $file
#sed -i -e 's/option masq.*$/option masq\t0/' $file
grep -Hn -A10 "^config defaults" $file
grep -Hn -B7 "option masq" $file
# https://raw.githubusercontent.com/LGA1150/fullconenat-fw3-patch/4117667ad5f5bfe375323124ba814d93f58d76f8/fullconenat.patch
mkdir -p "${dst}/patches"
mv -vf patch.fw3_fullconenat "${dst}/patches/fullconenat.patch"

file="${dst}/files/firewall.user"
#echo "iptables -t nat -A zone_wan_prerouting -j FULLCONENAT" >> $file
#echo "iptables -t nat -A zone_wan_postrouting -j FULLCONENAT" >> $file
cat -n $file

echo "# patch luci-app-fullconenat to enable FULLCONENAT as default configure"
file="$(pkg_path luci-app-fullconenat)/root/etc/config/fullconenat"
sed -i -e "s/^\(.*option mode \).*$/\1\'all\'/" $file
grep -Hn -A3 "^config fullconenat" $file

echo "# patch luci-app-flowoffload to enable full flowoffload modes again(done by firewall already) & notouch dnsmasq resolvfile option, no force depends on pdnsd-alt"
file="$(pkg_path luci-app-flowoffload)/root/etc/config/flowoffload"
sed -i -e '/option flow_offloading/d' $file
sed -i -e '/^config flow/ {' -e 'n; i\\toption flow_offloading_hw 1' -e '}' $file
sed -i -e '/^config flow/ {' -e 'n; i\\toption flow_offloading 1' -e '}' $file
file="$(pkg_path luci-app-flowoffload)/root/etc/init.d/flowoffload"
sed -i -e '/resolvfile/d' $file

file="$(pkg_path luci-app-flowoffload)/Makefile"
sed -i -e 's/\+pdnsd-alt//g' $file
fi

echo "# fix zoneinfo downloads(redirect to data.iana.org)"
file="$(pkg_path zoneinfo)/Makefile"
sed -i -e 's/http:\/\/www\.iana\.org.*\/releases/http:\/\/data\.iana\.org\/time-zones\/releases/g' $file
grep -Hnr "data\.iana\.org" $file

echo "# bump packages feed for 19.07.0 openvswitch: fix building failure caused by dst_ops api change(from kernel 4.14.162) & fix golang"
file="feeds.conf.default"
sed -i -e 's/d974cd36735353204fac679cb9febd6c9814c326/d0bdd32524d9bf68e1bf675497d9a84a120a952d/' $file
grep -Hn " packages " $file

echo "# fix luci-app-ttyd not well-formed & diasble ttyd by default"
dst="$(pkg_path luci-app-ttyd)"
file="${dst}/htdocs/luci-static/resources/view/ttyd/config.js"
sed -i -e "s/), \(_([\'].*&.*[\'])\));/), \[\1\]);/g" $file
file="${dst}/htdocs/luci-static/resources/view/ttyd/term.js"
grep -Hn "_(.*&" $file
sed -i -e 's/<br>/<br \/>/g' $file
grep -Hn "<br" $file
echo "# force ttyd disabled in default."
file="$(pkg_path ttyd)/files/ttyd.config"
sed -i -e '/^config ttyd/ {' -e 'n; i\\toption enable 0' -e '}' $file
cat -n $file

echo "# remove frpc frps init script"
file="$(pkg_path frp)/Makefile"
#sed -i -e 's/^PKG_VERSION:=.*$/PKG_VERSION:=0.32.0/' $file
#sed -i -e 's/^PKG_RELEASE:=.*$/PKG_RELEASE:=1/' $file
#sed -i -e 's/^PKG_HASH:=.*$/PKG_HASH:=39162780b28c0019207d83919530b573fac0bef8df30f1b6a5860886b0616c67/' $file
sed -i -e "/\/init\.d/d" $file
sed -i -e "/\/etc\/config\//d" $file
grep -Hn -A6 "^PKG_VERSION" $file

echo "# bump libuv to 1.40.0"
file="$(pkg_path libuv)/Makefile"
#wget -O $file https://raw.githubusercontent.com/openwrt/packages/f8ecbf529bad57970e4ff8f90484ba58d06b4a39/libs/libuv/Makefile
grep -Hn -C2 PKG_SOURCE_VERSION $file

echo "# ipt2socks bleeding, (1.1.3-2)"
file="$(pkg_path ipt2socks)/Makefile"
#sed -i -e '/[\t ]*DEPENDS:=/d' $file
#sed -i -e '/^PKG_BUILD_DIR:=/ {' -e 'n; iPKG_BUILD_DEPENDS:=libuv' -e '}' $file
sed -i -e 's/^\(.*\)cfbc2189356aba7fcafb0bc961a95419f313d8a7$/\1c1413335f0b5f15241d7072204902778d122a578/' $file
grep -Hn -A2 PKG_BUILD_DIR:= $file
grep -Hn -C3 TITLE:= $file
grep ^MAKE_FLAGS $file

#echo "# switch trojan to trojan-plus(10.0.3-1) & port reuse enabled & force openssl1.1, boost linking static"
#rm -rf "$(pkg_path trojan)/patches/"
file="$(pkg_path trojan)/Makefile"
#sed -i -e 's/^PKG_VERSION:=.*$/PKG_VERSION:=10.0.3/' $file
#sed -i -e 's/^PKG_RELEASE:=.*$/PKG_RELEASE:=1/' $file

#sed -i -e '/^PKG_SOURCE:/ {' -e 'n; i\PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)' -e '}' $file
#sed -i -e 's/^\(.*\)86cdb2685bb03a63b62ce06545c41189952f1ec4a0cd9147450312ed70956cbc$/\10240f5b4d2a37074ab33b414a8b60d5f5b4778bd226586a2bd9a5c87a12896ed/' $file

#sed -i -e 's/\$(PKG_NAME)/trojan-plus/' $file

#sed -i -e 's/^PKG_SOURCE_URL:=.*tar.gz/PKG_SOURCE_URL:=https:\/\/codeload.github.com\/peter-tank\/trojan-plus\/tar\.gz/' $file

#sed -i -e 's/trojan-gfw\/trojan/peter-tank\/trojan-plus/' $file
#sed -i -e '/^PKG_SOURCE:/ {' -e 'n; i\PKG_SOURCE_PROTO:=git\nPKG_SOURCE_VERSION:=a6394cdd718669b0c7491493a78e61f6f0f899b3\nPKG_MIRROR_HASH:=0240f5b4d2a37074ab33b414a8b60d5f5b4778bd226586a2bd9a5c87a12896ed' -e '}' $file
#sed -i -e '/^[ \t]*PKG_HASH:=.*/d' $file
#sed -i -e 's/^PKG_SOURCE_URL:=.*$/PKG_SOURCE_URL:=https:\/\/github.com\/peter-tank\/trojan-plus.git/' $file
#sed -i -e '/[ \t]*DEPENDS:=.*/ {' -e 'n;s/\+libopenssl//' -e '}' $file
sed -i -e '/[ \t]*DEPENDS:=.*\\$/ {' -e 'n;s/\\//' -e '}' $file
#sed -i -e '/^[ \t]*DEPENDS:=.*/ {' -e 'n;n;/boost/d' -e '}' $file
#sed -i -e 's/^PKG_BUILD_DEPENDS:=.*$/PKG_BUILD_DEPENDS:=openssl1.1 boost\/host/' $file
#sed -i -e 's/-DFORCE_TCP_FASTOPEN=.*\\$/-DFORCE_TCP_FASTOPEN=ON \\/' $file
#sed -i -e '/^CMAKE_OPTIONS/ {' -e 'n; i\\t-DDEFAULT_CONFIG=/etc/trojan.json \\\n\t-DBoost_USE_STATIC_LIBS=ON \\' -e '}' $file
#sed -i -e 's/-DOPENSSL_USE_STATIC_LIBS=.*\\$/-DOPENSSL_USE_STATIC_LIBS=TRUE \\/' $file
#sed -i -e 's/-DBoost_DEBUG=.*\\$/-DBoost_DEBUG=OFF \\/' $file
grep -Hn -A8 "^PKG_NAME" $file
grep -Hn "^PKG_BUILD_DEPENDS" $file
grep -Hn -A25 ^CMAKE_OPTIONS $file

echo "# force openssl version, 1.1.1-g"
file="$(pkg_path openssl1.1)/Makefile"
#sed -i -e 's/^PKG_BUGFIX:=.*$/PKG_BUGFIX:=g/' $file
#sed -i -e 's/^\(.*\)694f61ac11cb51c9bf73f54e771ff6022b0327a43bbdfa1b2f19de1662a6dcbe$/\1ddb04774f1e32f0c49751e21b67216ac87852ceb056b75209af2443400636d46/' $file
grep -Hn -A8 "^PKG_NAME" $file

#echo "# patch redsocks2, no shadowsocks anymore"
#file="$(pkg_path redsocks2)/Makefile"
#sed -i -e 's/^\(.*\)3052eeab75ff1ebd20c22334fbbecd808525bca7$/\18d1f95dc588112afa7ca7cf711725e8e36f7b97e/' $file
#sed -i -e 's/^#\(.*\)$/\1/' $file
#sed -i -e 's/ENABLE_HTTPS_PROXY=true/DISABLE_SHADOWSOCKS="1" ENABLE_STATIC="1" dist/' $file
#sed -i -e 's/^PKG_RELEASE:=.*$/PKG_RELEASE:=2/' $file
#grep -Hn -A3 "define Build\/Compile" $file

echo "# patch luci-app-passwall, remove extra depends"
file="$(pkg_path luci-app-passwall)/Makefile"
sed -i -e 's/[ \t]*default[ \t]*y[ \t]*.*$/\tdefault n/g' $file
sed -i -e 's/\+libcurl//g' $file
sed -i -e 's/\+libmbedtls//g' $file
sed -i -e 's/\+ca-bundle//g' $file
grep -Hn -A3 "config PACKAGE_.*_INCLUDE_" $file
sed -i -e 's/\+PACKAGE_.*$//g' $file
grep -Hn -A3 DEPENDS $file

echo "# patch luci-app-ssr-plus, remove extra depends"
dst="$(pkg_path luci-app-ssr-plus)"
file="${dst}/Makefile"
sed -i -e 's/[ \t]*default[ \t]*y[ \t]*.*$/\tdefault n/g' $file
sed -i -e 's/\+shadowsocksr-libev-alt//g' $file
grep -Hn -A3 "config PACKAGE_.*_INCLUDE_" $file
sed -i -e 's/\+PACKAGE_.*$//g' $file
grep -Hn -A3 DEPENDS $file

echo "## update ipv4 hash:net family inet /etc/china_ssr.txt"
url='http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest'
curl -4sSkL $url | grep CN | grep ipv4 | awk -F'|' '{printf("%s/%d\n", $4, 32-log($5)/log(2))}' > "${dst}/root/etc/china_ssr.txt"

echo "# patch luci-app-clash, remove dashboards & yac, no force depends on libopenssl, libustream-openssl & openssl-util"
dst="$(pkg_path luci-app-clash)"
rm -vrf ${dst}/root/usr/share/clash/dashboard
rm -vrf ${dst}/root/usr/share/clash/yac
rm -vrf ${dst}/root/etc/clash/Country.mmdb
touch ${dst}/root/etc/clash/keep.d
file="${dst}/Makefile"
sed -i -e 's/\+libopenssl//g' $file
sed -i -e 's/\+libustream-openssl//g' $file
sed -i -e 's/\+openssl-util//g' $file

sed -i -e "/\/Country\.mmdb/d" $file
sed -i -e "/\/dashboard/d" $file
sed -i -e "/\/yac/d" $file
sed -i -e '/^define .*install/ {' -e 'n; i\\t\$(INSTALL_DIR) \$(1)/etc/clash/dashboard' -e '}' $file
file="${dst}/root/etc/config/clash"
sed -i -e "s/^\(.*option dash_port \).*$/\1\'0\'/" $file

echo "# bleeding(1.0-beta.22-2), patch & update chinadns-ng database"
dst="$(pkg_path chinadns-ng)/files"
file="${dst}/chinadns-ng.init"
#wget -T30 -O ${dst}/chnroute.txt https://pexcn.me/daily/chnroute/chnroute.txt
#wget -T30 -O ${dst}/chnroute6.txt https://pexcn.me/daily/chnroute/chnroute-v6.txt
url='http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest'
echo "## update ipv4 hash:net family inet /etc/chinadns-ng"
curl -4sSkL $url | grep CN | grep ipv4 | awk -F'|' '{printf("%s/%d\n", $4, 32-log($5)/log(2))}' > ${dst}/chnroute.txt
curl -4sSkL $url | grep CN | grep ipv6 | awk -F'|' '{printf("%s/%d\n", $4, $5)}' > $dst/chnroute6.txt
ls -la "${dst}"

# not pack in actually (binary only)
dst="$(pkg_path chinadns-ng)/Makefile"
sed -i -e "/\/etc\//d" $file

echo "# patch shadowsocks-libev feeds/libsodium to full compile & rm default"
file="$(pkg_path libsodium)/Makefile"
sed -i -e "/--disable-ssp/d" $file
sed -i -e "/CONFIG_LIBSODIUM_MINIMAL/d" $file
grep -Hn -A3 "CONFIGURE_ARGS+=" $file

echo "# dns2tcp bleeding(1.1.0-1), 96aa2bddbb7bc7e263827cb5ebad5116697a000b"
echo "# dns2socks bleeding(2.1-20200218), ec82de936ad004cc940502cd2a1bff5b"

echo "# patch v2ray rm default V2RAY_COMPRESS_UPX y on SMALL_FLASH, bump to bleeding(4.34.0)"
file="$(pkg_path v2ray)/Config.in"
sed -i -e '/SMALL_FLASH/d' $file
grep -Hn -A3 "^config V2RAY_COMPRESS_UPX" $file

file="$(pkg_path v2ray)/Makefile"
#sed -i -e 's/^PKG_VERSION:=.*$/PKG_VERSION:=4\.22\.1/' $file
#sed -i -e 's/^\(.*\)2052ea02ec5569b32748e5c859dcd066fa3818d5caafa70ddaf216576aaec188$/\1474b3aeed069d9867f7603a0544abcc0f31386cef9254423577ab752fc8d4dcc/' $file
grep -Hn -A8 "^PKG_NAME" $file

# force no upx compress
# sed -i -e 's/upx .*$/return true/g' $file
grep -Hn -A3 "^V2RAY_COMPRESS_UPX" $file

#echo "# force dst dir rebuild on sdk/imagbuilder"
#file="scripts/bundle-libraries.sh"
#sed -i -e '/^_md() {/ {' -e 'n;i\\t[ -d "$1" ] && rm -vrf "$1"' -e '}' $file
#grep -Hn -A4 '^_md() {' $file
}

echo "# patch kernel defaults"
file="config/Config-kernel.in"
sed -i -e '/config KERNEL_MIPS_FPU_EMULATOR/ {' -e 'n;n; s/^\(.*\)default.*$/\1default y/' -e '}' $file
sed -i -e '/config KERNEL_SWAP/ {' -e 'n;n; s/^\(.*\)default.*$/\1default y/' -e '}' $file
sed -i -e 's/^\(.*\)default KERNEL_CC_OPTIMIZE_FOR_SIZE.*$/\1default KERNEL_CC_OPTIMIZE_FOR_PERFORMANCE/' $file
grep -Hn -A4 "config KERNEL_MIPS_FPU_EMULATOR" $file
grep -Hn -A3 "config KERNEL_SWAP" $file
tail -n20 $file
ret=0
else

shopt -s globstar
dst="$patch_helper/952-net-conntrack"
mkdir -p "$dst"
base="build_dir/toolchain**/linux-**"
files=$(sed -ne 's/[+-]\{3\} b\/\(.*\)$/\1/p' ${base}/${fc_name})
for f in ${files[@]}; do
  find ${base}/ -mindepth 1 -maxdepth 1 -type f -name "$f" | xargs -t -i cp -vn {} "${dst}"
done
echo "# Kernel structure"
ls -la $base/
[ -z "${fc_diff}" ] || cp -v "${fc_diff}" "$dst"
cp -v "target/linux/generic/hack-${kr}/${fc_name}" "$dst"
[ -n "$with_kernel" ] && cp -v "dl/linux-${kernel}.tar.xz" "$dst"
ls -lha "dl/linux-${kernel}.tar.xz"
echo "# Source downloaded"
find dl/ -type f | tee "$dst/sources.dl"
echo "# Targets builded"
find bin/ -type f | tee "$dst/targets.build"
mv -vf *.buildinfo $dst
ret=0
fi

return $ret
}

append_pkglist() {
local spath=$1
local listf=$2

[ -z "${listf}" -o ! -d "${spath}" ] && return 1
ret=99
PKG_NAME() { echo ${PKG_NAME:-ERROR_PKG_NAME}; }
PKG_VERSION() { echo ${PKG_VERSION:-ERROR_PKG_VERSION}; }
module() { echo SKIPED; }
call() {
  local act=$1
  local pdir=$2
  local pkg=$3
  local com=$4

  case $act in
    BuildPackage|PECLPackage|KernelPackage )
      echo ${pkg},${com} ${pdir} >> ${listf}
      ;;
    * )
      ;;
  esac

  [ -f "${pdir}/Makefile" ] || return 99
  rm -vrf build_dir/*/${pkg}
  #make ${pdir}/compile V=s
  return $?
}
echo "# packages collecting [$spath]..."
# spath=custom/openwrt-packages
find -L $spath/ -mindepth 1 -name "Makefile" -type f | xargs -i awk -f parse_package.awk {} > ${listf}.o
. $listf.o
return 0
}

del_pkgs() {
local lfeed=$1
local lean=$2
local ncoms ncom dir opk

[ -f "${lfeed}" -a -f "${lean}" ] || return 1

ncoms=$(cut -d ',' -f2 ${lfeed} | cut -d ' ' -f1 | sort | uniq)
echo "### force remove duplicated from [${lean}]..."
for ncom in ${ncoms}; do
  dir=$(grep -m1 "^[^,]*\,${ncom} " ${lean} | cut -d' ' -f2)
  [ -n "${dir}" -a -d "${dir}" ] || continue
  opk=$(grep -m1 "^[^,]*\,${ncom} " ${lean} | cut -d',' -f1)
  grep "^${opk}\," ${lean}
  echo "    - ${dir}"
  grep "^${opk}\," ${lfeed}
  rm -rf ${dir}
done

return 0
}

pkg_update() {
  local lcust=$1
  local lfeed=$2
  local custd=${3:-package/openwrt-packages}
  local ltarget=${4:-openwrt_packages.buildinfo}
  local npkg npk opk src dst depth

  [ -z "${lfeed}" ] && return 1
  npkg=$(cut -d ',' -f 1 ${lcust} | sort | uniq)
  echo "# ${lcust} -> ${lfeed} ..."
  for npk in $npkg; do
    echo "# checking: [$npk]..."
    opk=$(grep -m1 "^${npk}\," ${lfeed} | cut -d',' -f1)
    src=$(grep -m1 "^${npk}\," ${lcust} | cut -d' ' -f2)
    if [ "${npk}"x == "${opk}"x ]; then
      echo "* replace feeds: [$opk]..."
      grep "^${opk}\," ${lfeed}
      dst=$(grep -m1 "^${opk}\," ${lfeed} | cut -d' ' -f2)
    else
      echo "? checking news: [$npk]..."
      [ -d "${custd}" ] || mkdir -p ${custd}
      cat /dev/null > ${ltarget}
      append_pkglist ${custd} ${ltarget} >/dev/null
      dst=$(grep -m1 "^${npk}\," ${ltarget} | cut -d' ' -f2)
      if [ -n "${dst}" ]; then grep "^${npk}\." ${ltarget}; else dst="${custd}/${npk}"; fi
    fi
    [ -n "${dst}" ] && {
      [ -L "${dst}" ] || {
        rm -rf "${dst}"
        cp -rf "${src}" "${dst}"
      }
      depth=$(sed -e 's/[^/]*\//\.\.\//g' <<< ${dst})
      depth=$(ln -vnsfT "${depth%%${depth##*/}}${src}" "${dst}" 2>&1)
      [ -L "${dst}" ] && echo ${depth}
    }
    grep "^${npk}\," ${lcust}
  done

return 0
}

custom_configure() {
local repo=$1
local target=$2
local CONFIG_FILE=${3:-.config}
local rebuild=$4
local device common mtype

  case $target in
   ar71xx.WNDR4300V1|ar71xx.WNDR3700V4 )
   echo "# legacy Large Nand ar71xx"
   device=${target##*.}
   target=${target%%.*}
   ;;
   ath79.netgear_wndr3700-v4|ath79.netgear_wndr4300 )
   echo "# port Large Nand to ath79"
   device=${target##*.}
   target=${target%%.*}
   ;;
   ar71xx|ath79 ) echo "# Package compile only."
   ;;
   * ) echo "# Not Supported target: [$target]."
   return 1
   ;;
  esac

mtype=m
echo "# custom configure...[${target}_${device}]"
[ -z "$repo" -o -z "${device}" ] && mtype=y
rm -vf .config*
touch "$CONFIG_FILE"

common=n
[ -z "$rebuild" ] && common=y

if [ -z "$rebuild" ]; then
cat >> $CONFIG_FILE <<EOF
CONFIG_PACKAGE_base-files=y
# ignore SDK packages
CONFIG_SDK=y
#imagebuilder
CONFIG_IB=y
#CONFIG_IB_STANDALONE
# CONFIG_MAKE_TOOLCHAIN
EOF
else
cat >> $CONFIG_FILE <<EOF
# CONFIG_PACKAGE_base-files is not set
# CONFIG_SDK is not set
# CONFIG_IB is not set
# CONFIG_IB_STANDALONE is not set
# CONFIG_MAKE_TOOLCHAIN
EOF
fi

# 固件选择:
if [ -n "${device}" ]; then
cat >> $CONFIG_FILE <<EOF
CONFIG_HAS_DEVICES=y
CONFIG_HAS_SUBTARGETS=y
CONFIG_TARGET_SUBTARGET="nand"
CONFIG_TARGET_MULTI_PROFILE=y
CONFIG_TARGET_ALL_PROFILES=y
CONFIG_TARGET_PROFILE="DEVICE_${device}"
CONFIG_TARGET_${target}=y
CONFIG_TARGET_${target}_nand=y
CONFIG_TARGET_${target}_nand_DEVICE_${device}=y
CONFIG_TARGET_DEVICE_PACKAGES_${target}_nand_DEVICE_${device}=""
CONFIG_EFI_IMAGES=y
CONFIG_TARGET_IMAGES_GZIP=y
#CONFIG_TARGET_SQUASHFS_BLOCK_SIZE=256
CONFIG_ALL_KMODS=$common
CONFIG_ALL_NONSHARED=$common
#CONFIG_ALL=$common
# CONFIG_DEVEL is not set
EOF
else
cat >> $CONFIG_FILE <<EOF
# CONFIG_HAS_DEVICES is not set
# CONFIG_HAS_SUBTARGETS is not set
CONFIG_TARGET_SUBTARGET=""
# CONFIG_TARGET_MULTI_PROFILE is not set
# CONFIG_TARGET_ALL_PROFILES is not set
CONFIG_TARGET_PROFILE=""
CONFIG_TARGET_${target}=y
CONFIG_TARGET_${target}_nand=y
# CONFIG_EFI_IMAGES is not set
CONFIG_ALL_KMODS=y
CONFIG_ALL_NONSHARED=y
CONFIG_ALL=y
CONFIG_DEVEL=y
EOF
fi

# 通用编译选项:
cat >> $CONFIG_FILE <<EOF
#CONFIG_DOWNLOAD_FOLDER="../dl"

# process core dump
#CONFIG_KERNEL_ELF_CORE=y
#CONFIG_EXTERNAL_CPIO=""
# for aarch
#CONFIG_USE_UCLIBCXX=y

# CONFIG_COLLECT_KERNEL_DEBUG is not set
CONFIG_USE_SSTRIP=y
#CONFIG_HAVE_DOT_CONFIG=y
CONFIG_BUILDBOT=y
CONFIG_MODULES=y
# CONFIG_CCACHE is not set
CONFIG_AUTOREBUILD=y

# CONFIG_KERNEL_KALLSYMS is not set
CONFIG_TARGET_PER_DEVICE_ROOTFS=y
CONFIG_AUTOREMOVE=y
# CONFIG_PER_FEED_REPO_ADD_COMMENTED is not set
EOF

# IPv6支持:
cat >> $CONFIG_FILE <<EOF
CONFIG_IPV6=y
CONFIG_PACKAGE_kmod-ip6tables=y
CONFIG_PACKAGE_dnsmasq_full_dhcpv6=y
CONFIG_PACKAGE_ipv6helper=y
EOF

# 多文件系统支持:
cat >> $CONFIG_FILE <<EOF
CONFIG_PACKAGE_kmod-fs-nfs=y
CONFIG_PACKAGE_kmod-fs-nfs-common=y
CONFIG_PACKAGE_kmod-fs-nfs-v3=y
CONFIG_PACKAGE_kmod-fs-nfs-v4=y
CONFIG_PACKAGE_kmod-fs-ntfs=y
CONFIG_PACKAGE_kmod-fs-squashfs=y
EOF

# USB3.0支持:
cat >> $CONFIG_FILE <<EOF
CONFIG_PACKAGE_kmod-usb-ohci=y
CONFIG_PACKAGE_kmod-usb-ohci-pci=y
CONFIG_PACKAGE_kmod-usb2=y
CONFIG_PACKAGE_kmod-usb2-pci=y
CONFIG_PACKAGE_kmod-usb3=y
# broken
# CONFIG_PACKAGE_modemmanager is not set

# CONFIG_PACKAGE_python3-more-itertools is not set
EOF

# FULLCONENAT iptables extension
cat >> $CONFIG_FILE <<EOF
CONFIG_PACKAGE_iptables-mod-fullconenat=y
# not for kerne (@!LINUX_3_18 @!LINUX_4_9)
CONFIG_NF_CONNTRACK_EVENTS=y
CONFIG_NF_CONNTRACK_CHAIN_EVENTS=y
CONFIG_PACKAGE_fullconenat=y
# KernelPackage xt_FULLCONENAT.ko (dmesg | grep FULL)
CONFIG_PACKAGE_ipt-fullconenat=y
# iptables -t nat -A zone_wan_prerouting -j FULLCONENAT
# iptables -t nat -A zone_wan_postrouting -j FULLCONENAT
CONFIG_PACKAGE_luci-app-fullconenat=y
# bbr
CONFIG_PACKAGE_kmod-tcp-bbr=y
# luci-app-flowoffload extra depends: pdnsd-alt
CONFIG_PACKAGE_luci-app-flowoffload=$mtype
EOF

# kmods:
cat >> $CONFIG_FILE <<EOF
CONFIG_PACKAGE_kmod-lib-crc-ccitt=y
CONFIG_PACKAGE_kmod-lib-textsearch=y
CONFIG_PACKAGE_kmod-ipt-conntrack=y
CONFIG_PACKAGE_kmod-ipt-conntrack-extra=y
CONFIG_PACKAGE_kmod-ipt-core=y
CONFIG_PACKAGE_kmod-ipt-filter=y
CONFIG_PACKAGE_kmod-ipt-ipopt=y
CONFIG_PACKAGE_kmod-ipt-ipsec=y
CONFIG_PACKAGE_kmod-ipt-ipset=y
CONFIG_PACKAGE_kmod-ipt-nat=y
CONFIG_PACKAGE_kmod-ipt-offload=y
CONFIG_PACKAGE_kmod-ipt-raw=y
CONFIG_PACKAGE_kmod-ipt-tproxy=y
CONFIG_PACKAGE_kmod-nf-conntrack=y
CONFIG_PACKAGE_kmod-nf-conntrack-netlink=y
CONFIG_PACKAGE_kmod-nf-conntrack6=y
CONFIG_PACKAGE_kmod-nf-flow=y
CONFIG_PACKAGE_kmod-nf-ipt=y
CONFIG_PACKAGE_kmod-nf-ipt6=y
CONFIG_PACKAGE_kmod-nf-nat=y
CONFIG_PACKAGE_kmod-nf-reject=y
CONFIG_PACKAGE_kmod-nf-reject6=y
CONFIG_PACKAGE_kmod-nfnetlink=y
CONFIG_PACKAGE_kmod-nft-bridge=y
CONFIG_PACKAGE_kmod-nft-core=y
CONFIG_PACKAGE_kmod-nft-netdev=y
# FTP protocol
CONFIG_PACKAGE_kmod-nf-nathelper=y
# SIP protocol
CONFIG_PACKAGE_kmod-nf-nathelper-extra=y
EOF

# 常用LuCI插件选择:
cat >> $CONFIG_FILE <<EOF
CONFIG_LUCI_LANG_zh-cn=y
CONFIG_PACKAGE_zoneinfo-asia=y
CONFIG_PACKAGE_luci-i18n-base-zh-cn=y
CONFIG_PACKAGE_luci-app-webadmin=y
CONFIG_PACKAGE_luci-app-hd-idle=y
# relay proto for bridge sta, Firewall/forward accept (covered network + wan)
CONFIG_PACKAGE_luci-proto=y
# wg genkey | tee privkey | wg pubkey > pubkey
CONFIG_PACKAGE_kmod-wireguard=y
# wireguard extra depends: kmod-udptunne4 kmod-udptunne6
CONFIG_PACKAGE_kmod-udptunne4=y
CONFIG_PACKAGE_kmod-udptunne6=y
CONFIG_PACKAGE_wireguard=$mtype
CONFIG_PACKAGE_wireguard-tools=y
CONFIG_PACKAGE_luci-app-wireguard=y
CONFIG_PACKAGE_luci-app-minidlna=y
CONFIG_PACKAGE_luci-app-openvpn=y
# lean defaults
CONFIG_PACKAGE_luci-app-sqm=y
CONFIG_PACKAGE_luci-app-upnp=y
CONFIG_PACKAGE_luci-app-arpbind=y
CONFIG_PACKAGE_luci-app-pptp-server=y
CONFIG_PACKAGE_luci-app-usb-printer=y
CONFIG_PACKAGE_luci-app-samba=y
EOF

# LuCI主题:
cat >> $CONFIG_FILE <<EOF
CONFIG_PACKAGE_luci-theme-material=y
CONFIG_PACKAGE_luci-theme-openwrt=y
CONFIG_PACKAGE_luci-theme-darkmatter=m
CONFIG_PACKAGE_luci-theme-netgear-mc=m
EOF

# official
cat >> $CONFIG_FILE <<EOF
CONFIG_PACKAGE_cgi-io=y
CONFIG_PACKAGE_libiwinfo-lua=y
CONFIG_PACKAGE_liblua=y
CONFIG_PACKAGE_liblucihttp=y
CONFIG_PACKAGE_liblucihttp-lua=y
CONFIG_PACKAGE_libubus-lua=y
CONFIG_PACKAGE_lua=y
CONFIG_PACKAGE_uhttpd=y
CONFIG_PACKAGE_luci=y
CONFIG_PACKAGE_luci-app-firewall=y
CONFIG_PACKAGE_luci-app-opkg=y
CONFIG_PACKAGE_luci-base=y
CONFIG_PACKAGE_luci-lib-ip=y
CONFIG_PACKAGE_luci-lib-jsonc=y
CONFIG_PACKAGE_luci-lib-nixio=y
CONFIG_PACKAGE_luci-mod-admin-full=y
CONFIG_PACKAGE_luci-mod-network=y
CONFIG_PACKAGE_luci-mod-status=y
CONFIG_PACKAGE_luci-mod-system=y
CONFIG_PACKAGE_luci-proto-ipv6=y
CONFIG_PACKAGE_luci-proto-ppp=y
CONFIG_PACKAGE_luci-theme-bootstrap=y
CONFIG_PACKAGE_rpcd=y
CONFIG_PACKAGE_rpcd-mod-file=y
CONFIG_PACKAGE_rpcd-mod-iwinfo=y
CONFIG_PACKAGE_rpcd-mod-luci=y
CONFIG_PACKAGE_rpcd-mod-rrdns=y
CONFIG_PACKAGE_jshn=y
CONFIG_PACKAGE_jsonfilter=y
EOF

# 常用软件包:
cat >> $CONFIG_FILE <<EOF
# nas
CONFIG_PACKAGE_block-mount=y
CONFIG_PACKAGE_automount=y
CONFIG_PACKAGE_autosamba=y
# router
# ttyd extra depends: libuv libwebsockets-full
CONFIG_PACKAGE_libwebsockets-full=$mtype
CONFIG_PACKAGE_ttyd=$mtype
CONFIG_PACKAGE_luci-app-ttyd=$mtype
# pptpd extra depends: kmod-iptunnel
CONFIG_PACKAGE_kmod-iptunnel=y
CONFIG_PACKAGE_pptpd=y
CONFIG_PACKAGE_rp-pppoe-common=y
CONFIG_PACKAGE_rp-pppoe-relay=y
CONFIG_PACKAGE_rp-pppoe-server=y
CONFIG_PACKAGE_ppp=y
CONFIG_PACKAGE_ppp-mod-pppoe=y
CONFIG_PACKAGE_luci-proto-ppp=y
CONFIG_PACKAGE_luci-proto-ipv6=y
CONFIG_PACKAGE_luci-app-pppoe-relay=y
CONFIG_PACKAGE_luci-app-pppoe-server=y
CONFIG_PACKAGE_libmbedtls=y
CONFIG_PACKAGE_wpad-openssl=y
# CONFIG_PACKAGE_wpad-basic-wolfssl is not set
# CONFIG_PACKAGE_libustream-wolfssl is not set
CONFIG_PACKAGE_luci-ssl-openssl=y
CONFIG_PACKAGE_curl=y
CONFIG_LIBCURL_OPENSSL=y
CONFIG_PACKAGE_libopenssl=y
# CONFIG_PACKAGE_libopenssl1.1 is not set
CONFIG_PACKAGE_libopenssl-conf=y
CONFIG_PACKAGE_openssl-util=y
CONFIG_PACKAGE_libustream-openssl=y
CONFIG_OPENSSL_OPTIMIZE_SPEED=y
CONFIG_OPENSSL_WITH_TLS13=y
CONFIG_OPENSSL_WITH_CHACHA_POLY1305=y
CONFIG_OPENSSL_WITH_PSK=y
CONFIG_OPENSSL_ENGINE=y
CONFIG_DNSDIST_OPENSSL=y
CONFIG_PACKAGE_bash=y
CONFIG_PACKAGE_htop=y
CONFIG_PACKAGE_nano=m
CONFIG_PACKAGE_screen=m
CONFIG_PACKAGE_coreutils-nohup=y
CONFIG_PACKAGE_coreutils-base64=y
CONFIG_PACKAGE_diffutils=y
CONFIG_PACKAGE_tree=y
CONFIG_PACKAGE_vim-fuller=m
CONFIG_PACKAGE_iwinfo=y
CONFIG_PACKAGE_iptables-mod-tproxy=y
CONFIG_PACKAGE_iptables-mod-filter=y
CONFIG_PACKAGE_iptables-mod-ipopt=y
CONFIG_PACKAGE_iptables-mod-extra=y
CONFIG_PACKAGE_iptables-mod-nat-extra=y
CONFIG_PACKAGE_ipset=y
CONFIG_PACKAGE_ip-full=y
CONFIG_PACKAGE_kmod-nf-ipt=y
CONFIG_PACKAGE_kmod-nf-nat=y
CONFIG_PACKAGE_tcping=y
CONFIG_PACKAGE_libmbedtls=y
CONFIG_PACKAGE_ca-bundle=y
CONFIG_PACKAGE_curl=y
CONFIG_LIBCURL_MBEDTLS=y
# wget extra depends: libpcre zlib libpthread librt
CONFIG_PACKAGE_librt=y
CONFIG_PACKAGE_libpcre=y
CONFIG_PACKAGE_libpthread=y
CONFIG_PACKAGE_wget=y
CONFIG_PACKAGE_unzip=y
CONFIG_PACKAGE_nslookup=y
CONFIG_PACKAGE_macchanger=y
CONFIG_PACKAGE_gawk=y
CONFIG_PACKAGE_macchanger=y
CONFIG_PACKAGE_miniupnpc=y
# minidlna extra depends: libsqlite libflac libffmpeg-audio-dec libexif libjpeg libid3tag libvorbis libuuid
CONFIG_PACKAGE_minidlna=y
CONFIG_PACKAGE_luci-app-upnp=y
# miniupnpd extra depends: libuuid
CONFIG_PACKAGE_miniupnpd=y
CONFIG_PACKAGE_luci-app-minidlna=y
CONFIG_PACKAGE_luci-app-ddns=y
CONFIG_PACKAGE_ddns-scripts=y
CONFIG_PACKAGE_ddns-scripts_cloudflare.com=y
CONFIG_PACKAGE_frpc=m
CONFIG_PACKAGE_frps=m
CONFIG_PACKAGE_luci-app-frpc=m
CONFIG_PACKAGE_haproxy=m
CONFIG_PACKAGE_kcptun-client=m
CONFIG_PACKAGE_brook=m
CONFIG_PACKAGE_verysync=m
CONFIG_PACKAGE_luci-app-verysync=m
CONFIG_PACKAGE_nginx=m
CONFIG_PACKAGE_php7=m
CONFIG_PACKAGE_php7-fpm=m
CONFIG_PACKAGE_php7-mod-curl=m
CONFIG_PACKAGE_php7-mod-gd=m
CONFIG_PACKAGE_php7-mod-iconv=m
CONFIG_PACKAGE_php7-mod-json=m
CONFIG_PACKAGE_php7-mod-mbstring=m
CONFIG_PACKAGE_php7-mod-opcache=m
CONFIG_PACKAGE_php7-mod-session=m
CONFIG_PACKAGE_php7-mod-zip=m
CONFIG_PACKAGE_luci-app-kodexplorer=m
# libuv lib for ipt2socks/dns2tcp
CONFIG_PACKAGE_libuv=$mtype
CONFIG_PACKAGE_luci-app-ramfree=y
CONFIG_PACKAGE_luci-app-control-timewol=y
CONFIG_PACKAGE_luci-app-control-mia=y
# KMS
CONFIG_PACKAGE_vlmcsd=$mtype
CONFIG_PACKAGE_luci-app-vlmcsd=$mtype
EOF

# GFW软件包:
cat >> $CONFIG_FILE <<EOF
CONFIG_PACKAGE_luci-compat=y
CONFIG_PACKAGE_luci-lib-ipkg=y
CONFIG_PACKAGE_luci-app-autorepeater=y
CONFIG_PACKAGE_luci-app-dnscrypt-proxy2=y
CONFIG_PACKAGE_dns2socks=$mtype
CONFIG_PACKAGE_microsocks=$mtype
CONFIG_PACKAGE_dns2tcp=$mtype
CONFIG_PACKAGE_ipt2socks=$mtype

CONFIG_PACKAGE_redsocks=$mtype
CONFIG_PACKAGE_redsocks2=$mtype

CONFIG_PACKAGE_libstdcpp=$mtype

CONFIG_PACKAGE_boost=y
CONFIG_boost-static-and-shared-libs=$mtype
CONFIG_boost-runtime-shared=y
# CONFIG_boost-libs-all is not set
# CONFIG_boost-test-pkg is not set
# CONFIG_boost-graph-parallel is not set
CONFIG_PACKAGE_boost-date_time=y
CONFIG_PACKAGE_boost-program_options=y
CONFIG_PACKAGE_boost-system=y
# trojan exra depends: libstdcpp
# CONFIG_PACKAGE_trojan7 is not set
CONFIG_PACKAGE_trojan=$mtype

CONFIG_PACKAGE_v2ray=$mtype
CONFIG_PACKAGE_xray-core=$mtype
CONFIG_V2RAY_JSON_INTERNAL=y
CONFIG_V2RAY_EXCLUDE_V2CTL=y
CONFIG_V2RAY_EXCLUDE_ASSETS=y
# CONFIG_V2RAY_COMPRESS_UPX is not set
CONFIG_V2RAY_DISABLE_CUSTOM=y
CONFIG_V2RAY_DISABLE_DNS=y
CONFIG_V2RAY_DISABLE_DNS_PROXY=y
CONFIG_V2RAY_DISABLE_LOG=y
CONFIG_V2RAY_DISABLE_POLICY=y
CONFIG_V2RAY_DISABLE_ROUTING=y
CONFIG_V2RAY_DISABLE_STATISTICS=y
CONFIG_V2RAY_DISABLE_BLACKHOLE_PROTO=y
CONFIG_V2RAY_DISABLE_SHADOWSOCKS_PROTO=y
# CONFIG_V2RAY_DISABLE_REVERSE is not set
# CONFIG_V2RAY_DISABLE_DOMAIN_SOCKET_TRANS is not set

CONFIG_PACKAGE_pdnsd-alt=$mtype
CONFIG_PACKAGE_chinadns-ng=$mtype

# luci-app-ssr-plus extra depends: ip-full pdnsd-alt
CONFIG_PACKAGE_luci-app-ssr-plus=$mtype
# luci-app-passwall extra depends: ca-certificates wget curl bash chinadns-ng
CONFIG_PACKAGE_ca-certificates=$mtype
CONFIG_PACKAGE_luci-app-passwall=$mtype
# luci-app-clash extra depends: openssl-util kmod-tun bash
CONFIG_PACKAGE_openssl-util=$mtype
CONFIG_PACKAGE_kmod-tun=$mtype
CONFIG_PACKAGE_luci-app-clash=$mtype

# for server+client+tunnel
CONFIG_PACKAGE_shadowsocksr-libev=m
# for client
CONFIG_PACKAGE_shadowsocksr-libev-alt=m
# for server
CONFIG_PACKAGE_shadowsocksr-libev-server=m
# for tunnel
CONFIG_PACKAGE_shadowsocksr-libev-ssr-local=m

# static libs for shadowsocks fails on MIPS in src/resolv.c
# Unsupported jump between ISA modes; consider recompiling with interlinking enabled.
# https://github.com/raspberrypi/linux/commit/758d807ab5750c86028acdafaaa4c503e9ccddbc
CONFIG_PACKAGE_c-ares=$mtype
CONFIG_PACKAGE_libev=$mtype
CONFIG_PACKAGE_libsodium=$mtype
# for client
CONFIG_PACKAGE_shadowsocks-libev=$mtype
# for server
CONFIG_PACKAGE_shadowsocks-libev-server=m
# CONFIG_SHADOWSOCKS_STATIC_LINK is not set
# for plugin
CONFIG_PACKAGE_v2ray-plugin=m
# CONFIG_LIBSODIUM_MINIMAL is not set

# no remove on orphan
# CONFIG_PACKAGE_luci-app-dnscrypt-proxy2_INCLUDE_minisign is not set
CONFIG_PACKAGE_minisign=y

# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_ShadowsocksR is not set
# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_V2ray is not set
# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_ipt2socks is not set
# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_pdnsd is not set
# CONFIG_PACKAGE_luci-app_passwall_INCLUDE_ChinaDNS_NG is not set
# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_INCLUDE_Shadowsocks is not set
# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_Shadowsocks_socks is not set
# CONFIG_PACKAGE_luci-app-passwall_INCLUDE_INCLUDE_Shadowsocks_Server is not set

# CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_INCLUDE_ShadowsocksR is not set
# CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_ShadowsocksR_Socks is not set
# CONFIG_PACKAGE_luci-app-ssr-plus_INCLUDE_INCLUDE_ShadowsocksR_Server is not set

# CONFIG_PACKAGE_libffmpeg-audio-dec is not set
EOF

# 取消编译VMware镜像以及镜像填充 (不要删除被缩进的注释符号):
cat >> $CONFIG_FILE <<EOF
# CONFIG_TARGET_IMAGES_PAD is not set
# CONFIG_VMDK_IMAGES is not set
EOF

# version set
cat >> $CONFIG_FILE <<EOF
CONFIG_IMAGEOPT=y
# CONFIG_VERSIONOPT is not set
# CONFIG_VERSION_FILENAMES is not set
CONFIG_VERSION_PRODUCT="LargeNand"
CONFIG_VERSION_REPO="http://downloads.openwrt.org/releases/${repo}"
EOF

cat -bt $CONFIG_FILE
# ========================固件定制部分结束========================
ret=$?

return $ret
}

custom_makes() {
local lfeed=$1
local log=${2:-custom_makes.buildinfo}
local pkgs=$3
local ret repo pkg opk src

ret=0
[ -z "$pkgs" -o ! -f $lfeed ] && return 1
for pkg in $pkgs; do
  echo "# checking: [$pkg]..."
  opk=$(grep -m1 "^[^,]*\,${pkg} " ${lfeed} | cut -d',' -f1)
  src=$(grep -m1 "^${opk}\," ${lfeed} | cut -d' ' -f2)
  if [ -n "${src}" -a -f "${src}/Makefile" ]; then
    echo "### Compile ${src}..."
    stat -c%N ${src}
    grep "^${opk}\," ${lfeed} | tee -a $log
    make "package/${pkg}/compile" -j$(nproc) V=s
    ret=0
    [ ${ret} -ne 0 ] && break
  else
    echo "### Error package skiped: [${pkg}] ${src}"
  fi
done
cat $log
rm -vf $log

return $ret
}

clean_files() {
local src=$1
local files=$2
local cf depth

depth=5
[[ "$files" == '*' ]] && depth=1
for cf in $files; do
  find -L $src/ -maxdepth $depth -type f -name "${cf}" | xargs -t -i rm -f {}
done
}

move_files() {
local src=$1
local files=$2
local dst=$3
local regex=${4}
local cf depth

[ -z "$dst" ] && return 0
[[ -d "${dst}" ]] || mkdir -vp "${dst}"

[[ "$files" =~ \ |\' ]] && regex=${regex:-_*.ipk}
depth=5

# for common images only
[[ "$files" == '*' ]] && depth=1
for cf in $files; do
  echo "${cf}${regex}"
  find -L $src/ -maxdepth ${depth} -type f -name "${cf}${regex}" | xargs -t -i mv -vf {} "$dst"
done

du -L -Phsc $dst/
return 0
}

move_dir() {
local src=$1
local dst=$2

[[ -d "${src}" ]] || mkdir -vp "${src}"
mv -vf "${src}" "${dst}"

du -L -Phsc $dst/
return 0
}

cpbuild_info() {
local src=$1
local files=$2
local name

[ -z "$file" ] && return 0
shift 2
while [ -n "$1" ]; do
for name in $files; do
  find -L ${src}/ -mindepth 1 -maxdepth 1 -type f -name "${name}" | xargs -t -i cp -vnf {} "$1"
done
shift 1
done
}

cache_build() {
local dst src

while [ -n "${1}" ]; do
  dst=../${1##*/}
  src=$(sed -e 's/[^/]*\//\.\.\//g' <<< ${1})
  ln -vnsfT "../${src}" "${1}"
  [ -e "${dst}" ] || mkdir -vp "${dst}"
  [ -L "${1}" ] || {
#   shopt -s dotglob nullglob
    mv -vft "${dst}" ${1}/*
    rm -vrf ${1}
    ln -vnsfT "../${src}" "${1}"
  }
  du -L -Phsc ${dst}/ | grep -e "[0-9]M"$'\x09'
  shift 1
done

return 0
}

cache_key() {
local srcf=$1
local cache_path=$2
local hashfile=$(head -n3 $srcf)

md5sum <<< "$hashfile cache: $cache_path" | cut -d' ' -f 1
}

action=$1
shift 1
$action "$@"
