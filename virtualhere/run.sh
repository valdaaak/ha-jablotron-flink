#!/usr/bin/with-contenv bashio

JA_VID="$(bashio::config 'usb_vid')"
JA_PID="$(bashio::config 'usb_pid')"
SERVER_NAME="$(bashio::config 'server_name' | tr -cd 'A-Za-z0-9 _-')"
[ -n "$SERVER_NAME" ] || SERVER_NAME="HA-Jablotron"

reset_usb() {
  local found=0 d v p busnum devnum devpath
  bashio::log.info "USB rebind: looking for ${JA_VID}:${JA_PID} ..."
  for d in /sys/bus/usb/devices/*; do
    [ -f "$d/idVendor" ] || continue
    v=$(cat "$d/idVendor" 2>/dev/null)
    p=$(cat "$d/idProduct" 2>/dev/null)
    if [ "$v" = "$JA_VID" ] && [ "$p" = "$JA_PID" ]; then
      found=1
      busnum=$(cat "$d/busnum" 2>/dev/null)
      devnum=$(cat "$d/devnum" 2>/dev/null)
      devpath=$(printf "/dev/bus/usb/%03d/%03d" "$busnum" "$devnum")
      bashio::log.info "Found $d -> $devpath, rebinding kernel driver (USBDEVFS_CONNECT)"
      if /usr/local/bin/usbreset "$devpath"; then
        bashio::log.info "USB returned to kernel -> /dev/hidraw* should be back (reload the integration or restart HA Core)"
      else
        bashio::log.warning "usbreset FAILED for $devpath"
      fi
      sleep 1
    fi
  done
  if [ "$found" != "1" ]; then
    bashio::log.warning "${JA_VID}:${JA_PID} NOT found in /sys (is the panel connected via USB?)"
  fi
}

on_stop() {
  bashio::log.info "Add-on stopping, returning USB to the kernel..."
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
bashio::log.info "VirtualHere running on TCP 7575 (server '${SERVER_NAME}'). Use the Jablotron device from the VirtualHere client."

while true; do
  sleep 3600 &
  wait $!
done
