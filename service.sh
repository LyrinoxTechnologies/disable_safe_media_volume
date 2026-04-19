#!/system/bin/sh

MODPATH=${0%/*}
LOGFILE="$MODPATH/log.txt"
PIDFILE="$MODPATH/service.pid"

exec 2>>"$LOGFILE"
set -x

# -----------------------------
# Logging
# -----------------------------
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> "$LOGFILE"
}

# -----------------------------
# Cleanup
# -----------------------------
cleanup() {
    log "Service stopping gracefully"
    rm -f "$PIDFILE"
    exit 0
}

# Trap signals for graceful shutdown
trap cleanup SIGTERM SIGINT SIGHUP

# -----------------------------
# Prevent duplicate instances
# -----------------------------
if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
    log "Service already running, exiting"
    exit 0
fi
echo $$ > "$PIDFILE"

# -----------------------------
# Wait for boot
# -----------------------------
log "Waiting for boot completion..."

until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 1
done

log "Boot completed, waiting for system services..."
sleep 40

# Wait for settings provider
until settings get global device_provisioned >/dev/null 2>&1; do
    sleep 2
done

log "System fully ready"

# -----------------------------
# Apply Audio Props (base)
# -----------------------------
if [ -f "$MODPATH/audio_props.sh" ]; then
    log "Applying base audio props..."
    sh "$MODPATH/audio_props.sh"
    log "Base props applied"
else
    log "No audio_props.sh found"
fi

# -----------------------------
# Safe Resampler Configuration
# -----------------------------
apply_resampler() {
    log "Applying high-quality resampler (quality=7)"
    setprop af.resampler.quality 7
}

# -----------------------------
# CSD / Safe Volume Killer
# -----------------------------
disable_csd() {
    # --- Primary: cmd audio (stable across Android versions) ---
    # Zeros the EN 50332-3 dose accumulator directly in AudioService
    cmd audio set-sound-dose-value 0.0 >/dev/null 2>&1
    cmd audio reset-sound-dose-timeout >/dev/null 2>&1

    # --- Legacy safe volume layer (belt-and-suspenders) ---
    settings put global audio_safe_volume_state 0 >/dev/null 2>&1
    settings put system safe_headset_volume_index 100 >/dev/null 2>&1
}

# -----------------------------
# Initial Execution
# -----------------------------
log "Running initial configuration..."

apply_resampler
disable_csd

log "Initial setup complete"

# -----------------------------
# Enforcement Loop (adaptive)
# -----------------------------
ITERATION=0

log "Entering enforcement loop"

while true; do

    # Stop if module disabled
    if [ -f "$MODPATH/disable" ]; then
        log "Disable flag detected"
        cleanup
    fi

    ITERATION=$((ITERATION + 1))
    log "Run #$ITERATION"

    disable_csd

    # Re-apply resampler occasionally (in case system overrides)
    if [ $((ITERATION % 10)) -eq 0 ]; then
        log "Re-applying resampler config"
        apply_resampler
    fi

    # Adaptive timing:
    # Early boot = aggressive
    # Later = relaxed
    if [ "$ITERATION" -lt 10 ]; then
        SLEEP_TIME=30
    else
        SLEEP_TIME=120
    fi

    sleep "$SLEEP_TIME" &
    SLEEP_PID=$!
    wait $SLEEP_PID 2>/dev/null || true

done