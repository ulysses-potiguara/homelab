#!/bin/bash

# Default values (failsafe)
POWER_CLAMP=0 # 0-100: % of idle cycles
NO_TURBO=0 # 0: enable turbo, 1: disable turbo
MAX_CLOCK=3300000 # value in kHz
MIN_CLOCK=800000 # value in kHz
GOVERNOR="performance" # performance, powersave, ondemand, conservative, schedutil - not all values can be supported by your CPU
PL1=6000000 # value in uW - Sustained Power Limit (long-term)
PL2=20000000 # value in uW - Burst Power Limit (short-term)

if [[ "$1" == "--performance" ]]; then
    echo -e "Performance mode\n️️⚠ This configuration can OVERHEAT the homelab. Use with caution!\n🌡️Always monitor the temperatures🌡️"
    POWER_CLAMP=0
    NO_TURBO=0
    MAX_CLOCK=3300000
    MIN_CLOCK=800000
    GOVERNOR="performance"
    PL1=20000000
    PL2=20000000
elif [[ "$1" == "--throttler" ]]; then
    echo "Throttling..."
    POWER_CLAMP=0
    NO_TURBO=1
    MAX_CLOCK=1100000
    MIN_CLOCK=800000
    GOVERNOR="powersave"
    PL1=6000000
    PL2=6000000
else
    echo "Using default values"
fi

echo $POWER_CLAMP | tee /sys/class/thermal/cooling_device9/cur_state > /dev/null 2>&1
echo $NO_TURBO | tee /sys/devices/system/cpu/intel_pstate/no_turbo > /dev/null 2>&1
echo $MAX_CLOCK | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_max_freq > /dev/null 2>&1
echo $MIN_CLOCK | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_min_freq > /dev/null 2>&1
echo $GOVERNOR | tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor > /dev/null 2>&1
echo $PL1 | tee /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw > /dev/null 2>&1
echo $PL2 | tee /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw > /dev/null 2>&1
