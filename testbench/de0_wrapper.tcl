# SimVision command script soc.tcl

simvision {

  # Open new waveform window

    window new WaveWindow  -name  "Waves for SoC Example (FPGA version)"
    waveform  using  "Waves for SoC Example (FPGA version)"

  # Add Waves

    waveform  add  -signals  de0_wrapper_stim.CLOCK_50
    waveform  add  -signals  de0_wrapper_stim.KEY
    waveform  add  -signals  de0_wrapper_stim.SW
    waveform  add  -signals  de0_wrapper_stim.LEDG
    waveform  add  -signals  de0_wrapper_stim.HEX0
    waveform  add  -signals  de0_wrapper_stim.HEX1
    waveform  add  -signals  de0_wrapper_stim.HEX2
    waveform  add  -signals  de0_wrapper_stim.HEX3
    waveform  add  -signals  de0_wrapper_stim.dut.soc_inst.HADDR
    waveform  add  -signals  de0_wrapper_stim.dut.soc_inst.HRDATA
    waveform  add  -signals  de0_wrapper_stim.dut.soc_inst.HWDATA
    waveform  add  -signals  de0_wrapper_stim.dut.soc_inst.HWRITE
    waveform  add  -signals  de0_wrapper_stim.dut.soc_inst.HSEL_RAM
    waveform  add  -signals  de0_wrapper_stim.dut.soc_inst.HSEL_SW
    waveform  add  -signals  de0_wrapper_stim.dut.soc_inst.HSEL_DOUT

}

