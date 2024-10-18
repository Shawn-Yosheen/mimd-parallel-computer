# SimVision command script soc.tcl

simvision {

  # Open new waveform window

    window new WaveWindow  -name  "Waves for SoC Example (FPGA version)"
    waveform  using  "Waves for SoC Example (FPGA version)"

  # Add Waves

    waveform  add  -signals  soc_stim.HCLK
    waveform  add  -signals  soc_stim.HRESETn
    waveform  add  -signals  soc_stim.Switches
    waveform  add  -signals  soc_stim.Buttons
    waveform  add  -signals  soc_stim.DataOut
    waveform  add  -signals  soc_stim.DataValid
    waveform  add  -signals  soc_stim.LOCKUP
    waveform  add  -signals  soc_stim.dut.HADDR
    waveform  add  -signals  soc_stim.dut.HRDATA
    waveform  add  -signals  soc_stim.dut.HWDATA
    waveform  add  -signals  soc_stim.dut.HWRITE
    waveform  add  -signals  soc_stim.dut.HSEL_RAM
    waveform  add  -signals  soc_stim.dut.HSEL_SW
    waveform  add  -signals  soc_stim.dut.HSEL_DOUT
    waveform  add  -signals  soc_stim.dut.HSEL_RX
    waveform  add  -signals  soc_stim.dut.HSEL_TX

}

