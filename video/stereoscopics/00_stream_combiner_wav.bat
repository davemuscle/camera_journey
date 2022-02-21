ghdl -a ../../cdc/pulse_sync_handshake.vhd
ghdl -a ../../bram/inferred_ram.vhd

ghdl -a ../timing/video_timing_generator.vhd

ghdl -a ../../fifo/async_fifo.vhd

ghdl -a stream_combiner.vhd

ghdl -a stream_combiner_tb.vhd
ghdl -r stream_combiner_tb --stop-time=10000us --wave=stream_combiner_tb.ghw


pause