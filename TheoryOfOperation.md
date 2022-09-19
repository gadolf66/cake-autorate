# CAKE-autorate - Theory of Operation

_As noted in the main README:_
CAKE-autorate is a script that automatically adapts CAKE Smart Queue Management (SQM) bandwidth settings by measuring traffic load and RTT times. This is designed for variable bandwidth connections such as LTE, and is not intended for use on connections that have a stable, fixed bandwidth.

The script starts several concurrent processes:

* maintain_pingers - ping reflectors (external hosts) 
and monitor the ping times/latency to those reflectors

* monitor\_achieved\_rates - continually compute the
amount of data sent/received per time interval

* the "main" loop - periodically compare latency and
up/down data rates to determine whether to adjust
CAKE parameters up or down.

## maintain_pingers()

This routine starts pingers to several reflectors from the array
`${reflectors}` to get a measure of the latency.
Each of the reflectors has associated with it a PID,
a fifo that records the output of the `ping` command,
and a counter of `${reflector_offences}` _(Not sure what "offences" are...)_

This routine appears to be responsible for detecting a failure
of a pinger and either ignoring it or substituting a new one.


```
# tail /tmp/cake-autorate/pinger_0_fifo
# Note 0.2 sec interval between entries 
1661601024.393020] 64 bytes from 1.1.1.1: icmp_seq=313 ttl=58 time=12.2 ms
1661601024.593595] 64 bytes from 1.1.1.1: icmp_seq=314 ttl=58 time=12.2 ms
1661601024.794034] 64 bytes from 1.1.1.1: icmp_seq=315 ttl=58 time=12.1 ms
1661601024.994740] 64 bytes from 1.1.1.1: icmp_seq=316 ttl=58 time=12.4 ms
1661601025.195587] 64 bytes from 1.1.1.1: icmp_seq=317 ttl=58 time=12.5 ms
1661601025.395062] 64 bytes from 1.1.1.1: icmp_seq=318 ttl=58 time=12.1 ms
1661601025.595564] 64 bytes from 1.1.1.1: icmp_seq=319 ttl=58 time=12.2 ms
```

## monitor\_reflector\_responses()

Reads each pinger's fifo, and writes lines to the shared
fifo (`/tmp/cake-autorate/ping_fifo`) that look like this.

```
Timestamp  Reflector Seq  RTT_Baseline RTT   RTT_Delta
57.993174] 1.0.0.1 	 100  10731        11500 769
```
* RTT: Actual RTT
* RTT\_Baseline: pinger's history, smoothed by alpha
* RTT\_Delta: difference between baseline and current sample

```
root@Belkin-RT3200:/tmp/cake-autorate# tail ping_fifo
57.993174] 1.0.0.1 100 10731 11500 769
16898] 8.8.8.8 99 15170 16100 930
.070393] 8.8.4.4 98 15419 16100 681
871] 1.1.1.1 102 10799 11400 601
.194177] 1.0.0.1 101 10731 11700 969
58.217322] 8.8.8.8 100 15170 16000 830
70854] 8.8.4.4 99 15419 16100 681
58.346771] 1.1.1.1 103 10799 11500 701
58.395154] 1.0.0.1 102 10731 11600 869
417103] 8.8.8.8 101 15171 16400
```

## "main loop"

Reads `/tmp/cake-autorate/ping_fifo` and determine whether rtt_delta_us has changed enough to warrant changing CAKE parameters 


## Questions:

1. I have the sense that the code compares a "current RTT" to some "longer-term RTT" and if the RTT is increasing it decreases 
the CAKE parameters. Is that what's happening when bufferbloat_detected is assigned in the main loop?
Which variable(s) hold the current latency/measurement that's
being used for the comparison?

2. Might it make sense to pass all the
"$dl-related" and "$ul-related" variables
as variables in an associative array? That is:

   | Current Variable | Associative Array |
   |------------|----------|
   | `$dl_if` | `$dl[if]` |
   |`$dl_load_condition`	|	`$dl[load_condition]` |
   |`$dl_shaper_rate_kbps`	|	`$dl[shaper_rate_kbps]` |
   | ... etc...	| 	... etc ... |

   It then lets us simplify function calls like
`classify_load ... $long $list $of $arguments...` to
`classify_load $dl`

3. In `monitor_reflector_responses`, why compute delta before smoothing rtt\_baseline\_us?

   ```
		rtt_delta_us=$(( $rtt_us-$rtt_baseline_us ))

		alpha=$(( (( $rtt_delta_us >=0 )) ? $alpha_baseline_increase : $alpha_baseline_decrease ))

		rtt_baseline_us=$(( ( (1000-$alpha)*$rtt_baseline_us+$alpha*$rtt_us )/1000 ))

		printf '%s %s %s %s %s %s\n' "$timestamp" "$reflector" "$seq" "$rtt_baseline_us" "$rtt_us" "$rtt_delta_us" > /tmp/cake-autorate/ping_fifo
   ```

4. Does `monitor_reflector_responses` return `rtt_baseline_us`? Or does writing it to the shared fifo suffice?

5. Should `medium_load_thr` be different from `high_load_thr` in _cake-autorate-config.sh_? (Both are set to 0.75 in main branch)
6. Does `maintain_pingers` need to be called a second time near the end of the file?
7. Maybe running as service should change to `output_processing_stats=0` & `output_cake_changes=0` by default...
8. How can we test if `sustained_idle_sleep_thr_s` works?
What conditions should cause pinging to stop?

