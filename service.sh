#!/system/bin/sh
MODPATH=${0%/*}
exec 2>$MODPATH/log.txt
set -x

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOGFILE"
}

# Cleanup function for graceful exit
cleanup() {
    log "Service stopping gracefully"
    exit 0
}

# Trap signals for graceful shutdown
trap cleanup SIGTERM SIGINT SIGHUP

log "Service sarted, waiting for boot completion"

until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 1
done

log "Boot commpleted, waiting for AudioService configuration"

# wait for AudioService to finish configuring
sleep 35

# -- Audio Quality Props --
if [ -f "$MODPATH/audio_props.sh" ]; then
    log "Applying audio quality props..."
    sh "$MODPATH/audio_props.sh"
    log "Audio props applied"
else
    log "No audio_props.sh found, skipping..."
fi

disable_csd() {
    # Disable safe media volume via binder
    service call audio 102 > /dev/null 2>&1

    # Disable CSD via binder
    service call audio 198 i32 0 > /dev/null 2>&1

    # Clear persisted CSD records so they don't reload on next boot
    settings delete global audio_safe_csd_current_value > /dev/null 2>&1
    settings delete global audio_safe_csd_dose_records > /dev/null 2>&1
    settings delete global audio_safe_csd_next_warning > /dev/null 2>&1

    # Reset runtime CSD acccumulator to zero
    service call audio 108 f 0.0 > /dev/null 2>&1

    # Legacy safe media volume settings
    settings put global audio_safe_volume_state 0 > /dev/null 2>&1
    settings put global safe_headset_volume 0 > /dev/null 2>&1
    settings delete global audio_safe_media_volume_index > /dev/null 2>&1
    settings put system safe_headset_volume_index 100 > /dev/null 2>&1

    # CSD settings
    settings put global audio_safe_csd_enabled 0 > /dev/null 2>&1
    settings put global audio_safe_csd_dose 0 > /dev/null 2>&1
}

# -- Initial CSD Disable --
log "Applying initial CSD disable..."
disable_csd
log "CSD Disabled successfully"

# -- Main loop --
log "Entering maintenance loop (5 Minute Interval)"

ITERATION=0
while true; do
    sleep 300 &
    SLEEP_PID=$!
    wait $SLEEP_PID 2>/dev/null

    # Check if module is disabled
    if [ -f "$MODPATH/disable" ]; then
        log "Module disable flag detected, stopping service"
        cleanup
    fi

    ITERATION=$((ITERATION + 1))
    log "Maintenance run #$ITERATION"
    disable_csd
done