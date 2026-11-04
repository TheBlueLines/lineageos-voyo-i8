#!/bin/bash
D=~/los/hardware/interfaces/audio/core/all-versions/default
ls $D
grep -nE "mStream->(update_source_metadata|update_sink_metadata|set_event_callback|get_active_microphones|set_microphone_direction|set_microphone_field_dimension|set_playback_rate_parameters|get_playback_rate_parameters|get_dual_mono_mode|set_dual_mono_mode|get_audio_description_mix_level|set_audio_description_mix_level|set_latency_mode|get_recommended_latency_modes|set_latency_mode_callback|set_presentation)" $D/*.cpp | cut -c1-170
grep -nE "mDevice->(get_microphones|set_audio_port_config|get_audio_port_v7|set_device_connected_state|get_audio_port)" $D/*.cpp | cut -c1-170
cd ~/los/hardware/interfaces && git status --short | head
