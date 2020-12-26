---
layout: page
title: Thesis
permalink: /thesis/
---

## VAD: VHDL Audio Device

*July 2010 - December 2010*

[Download undergraduate thesis project]({{ 'assets/pdf/ronen-agranat-thesis-vad.pdf' | relative_url }})

A dissertation submitted to the Department of Electrical Engineering in fulfilment
of the requirements for the degree of
BSc(Eng) Electrical and Computer Engineering at the University of Cape Town.
Supervisor: Simon Winberg

### Abstract

This fourth-year electrical and computer engineering thesis project details the design and implementation of a general purpose audio device on a Digilent Nexys2 evaluation board, supporting 44.1 KHz 12-bit audio monitoring and playback with 53 seconds of recording time.
The emphasis of the project is on digital logic, VHDL and FPGA’s.

Five track MIDI files can be played, with two polyphonic tracks and a drum track.
The musical notes are synthesised by waveform generators implemented in the hardware domain.
These oscillators are controlled by a software application running on the Microblaze soft core.
The device makes use of external ADC and DAC chips to interact with analogue audio signals.
The project is implemented using Xilinx Embedded Development Kit (EDK) 12.2.

The functional and performance characteristics of the device are investigated with a series of experiments which verify the prototype’s functionality.
These results are used to validate the thesis and prove or disprove the hypotheses.
