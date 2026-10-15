#!/usr/bin/with-contenv bashio

JA_VID="$(bashio::config 'usb_vid')"
JA_PID="$(bashio::config 'usb_pid')"
SERVER_NAME="$(bashio::config 'server_name' | tr -cd 'A-Za-z0-9 _-')"
[ -n "$SERVER_NAME" ] || SERVER_NAME="HA-Jablotron"

reset_usb() {
  local found=0 d v p busnum devnum devpath
  bashio::log.info "USB reset: hladam ${JA_VID}:${JA_PID} ..."
  for d in /sys/bus/usb/devices/*; do
    [ -f "$d/idVendor" ] || continue
    v=$(cat "$d/idVendor" 2>/dev/null)
    p=$(cat "$d/idProduct" 2>/dev/null)
    if [ "$v" = "$JA_VID" ] && [ "$p" = "$JA_PID" ]; then
      found=1
      busnum=$(cat "$d/busnum" 2>/dev/null)
      devnum=$(cat "$d/devnum" 2>/dev/null)
      devpath=$(printf "/dev/bus/usb/%03d/%03d" "$busnum" "$devnum")
      bashio::log.info "Najdene $d -> $devpath, viazem kernel driver spat (USBDEVFS_CONNECT)"
      if /usr/local/bin/usbreset "$devpath"; then
        bashio::log.info "USB vratene kernelu -> /dev/hidraw* by sa mal vratit (reload integracie alebo 'ha core restart')"
      else
        bashio::log.warning "usbreset ZLYHAL pre $devpath"
      fi
      sleep 1
    fi
  done
  if [ "$found" != "1" ]; then
    bashio::log.warning "${JA_VID}:${JA_PID} NEnajdeny v /sys (je ustredna pripojena USB?)"
  fi
}

on_stop() {
  bashio::log.info "Add-on sa zastavuje, vraciam USB kernelu..."
  pkill -x vhusbd 2>/dev/null
  sleep 1
  reset_usb
  exit 0
}
trap on_stop SIGTERM SIGINT

reset_usb

cd /root || exit 1
cat > config.ini <<EOF
[General]
ServerName=${SERVER_NAME}
EOF

/usr/sbin/vhusbd &
sleep 1
bashio::log.info "VirtualHere bezi na TCP 7575 (server '${SERVER_NAME}'). Zdielaj Jablotron USB v klientovi."

while true; do
  sleep 3600 &
  wait $!
done
