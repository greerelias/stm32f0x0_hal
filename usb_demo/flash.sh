#!/bin/bash

# This script runs OpenOCD to program, verify, and reset an STM32F0x target
# using an ST-Link interface.

echo "Starting OpenOCD to program the STM32F070RB..."

openocd -f interface/stlink.cfg \
        -f target/stm32f0x.cfg \
        -c "program bin/usb_demo verify reset exit"

echo "Flashing process finished."