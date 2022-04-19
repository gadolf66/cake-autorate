#!/bin/bash

# config.sh sets up defaults for CAKE-autorate

# config.sh is a part of CAKE-autorate
# CAKE-autorate automatically adjusts bandwidth for CAKE in dependence on detected load and RTT

# Author: @Lynx (OpenWrt forum)
# Inspiration taken from: @moeller0 (OpenWrt forum)

# *** OUTPUT OPTIONS ***

output_processing_stats=1 # enable (1) or disable (0) output monitoring lines showing processing stats
output_cake_changes=0     # enable (1) or disable (0) output monitoring lines showing cake bandwidth changes
debug=0			  # enable (1) or disable (0) out of debug lines

# *** STANDARD CONFIGURATION OPTIONS ***

dl_if=ifb-wgp-pbr # download interface
ul_if=wan         # upload interface

reflector_ping_interval_s=0.2 # (seconds, e.g. 0.2s or 2s)

# list of reflectors to use
reflectors=("1.1.1.1" "1.0.0.1" "8.8.8.8" "8.8.4.4")

# delay threshold in ms is the extent of RTT increase to classify as a delay
# this is automatically adjusted based on maximum on the wire packet size
delay_thr_ms=25 # base extent of RTT increase to classify as a delay

min_dl_shaper_rate_kbps=10000  # minimum bandwidth for download (Kbit/s)
base_dl_shaper_rate_kbps=25000 # steady state bandwidth for download (Kbit/s)
max_dl_shaper_rate_kbps=80000  # maximum bandwidth for download (Kbit/s)

min_ul_shaper_rate_kbps=25000  # minimum bandwidth for upload (Kbit/s)
base_ul_shaper_rate_kbps=30000 # steady state bandwidth for upload (KBit/s)
max_ul_shaper_rate_kbps=35000  # maximum bandwidth for upload (Kbit/s)

# sleep functionality saves unecessary pings and CPU cycles by
# pausing all active pingers when connection is not in active use
enable_sleep_function=1 # enable (1) or disable (0) sleep functonality 
connection_active_thr_kbps=500 # threshold in Kbit/s below which dl/ul is considered idle
sustained_idle_sleep_thr_s=60  # time threshold to put pingers to sleep on sustained dl/ul achieved rate < idle_thr (seconds)

# *** ADVANCED CONFIGURATION OPTIONS ***

# interval for monitoring achieved rx/tx rates
# this is automatically adjusted based on maximum on the wire packet size
monitor_achieved_rates_interval_ms=100 # (milliseconds) 

bufferbloat_detection_window=4  # number of delay samples to retain in detection window
bufferbloat_detection_thr=2     # number of delayed samples for bufferbloat detection

alpha_baseline_increase=0.001 # how rapidly baseline RTT is allowed to increase
alpha_baseline_decrease=0.9   # how rapidly baseline RTT is allowed to decrease

achieved_rate_adjust_bufferbloat=0.9 # how rapidly to reduce achieved rate upon detection of bufferbloat 
shaper_rate_adjust_bufferbloat=0.9   # how rapidly to reduce shaper rate upon detection of bufferbloat 
shaper_rate_adjust_load_high=1.01    # how rapidly to increase shaper rate upon high load detected 
shaper_rate_adjust_load_low=0.98     # how rapidly to return to base shaper rate upon low load detected 

medium_load_thr=0.25 # % of currently set bandwidth for detecting medium load
high_load_thr=0.75   # % of currently set bandwidth for detecting high load

bufferbloat_refractory_period_ms=300 # (milliseconds)
decay_refractory_period_ms=1000 # (milliseconds)

global_ping_response_timeout_s=10 # timeout to set shaper rates to min on no ping response whatsoever (seconds)

interface_init_wait_time_s=60 # timeout for waiting for rx/tx paths to come up, else script exits (seconds)

# verify these are correct using 'cat /sys/class/...'
case "${dl_if}" in
    \veth*)
        rx_bytes_path="/sys/class/net/${dl_if}/statistics/tx_bytes"
        ;;
    \ifb*)
        rx_bytes_path="/sys/class/net/${dl_if}/statistics/tx_bytes"
        ;;
    *)
        rx_bytes_path="/sys/class/net/${dl_if}/statistics/rx_bytes"
        ;;
esac

case "${ul_if}" in
    \veth*)
        tx_bytes_path="/sys/class/net/${ul_if}/statistics/rx_bytes"
        ;;
    \ifb*)
        tx_bytes_path="/sys/class/net/${ul_if}/statistics/rx_bytes"
        ;;
    *)
        tx_bytes_path="/sys/class/net/${ul_if}/statistics/tx_bytes"
        ;;
esac

if (( $debug )) ; then
    echo "rx_bytes_path: $rx_bytes_path"
    echo "tx_bytes_path: $tx_bytes_path"
fi
