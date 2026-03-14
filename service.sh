#!/system/bin/sh
MODPATH=${0%/*}
exec 2>$MODPATH/log.txt
set -x

until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 1
done

# Legacy safe media volume settings
settings put global audio_safe_volume_state 0
settings put global safe_headset_volume 0
settings put system volume_link_notification 1
settings delete global audio_safe_media_volume_index
settings put system safe_headset_volume_index 100

# CSD (Content Sound Dosimetry) - EU Android 14+ enforcement
settings put global audio_safe_csd_enabled 0
settings put global audio_safe_csd_dose 0
