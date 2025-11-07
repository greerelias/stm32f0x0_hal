-------------------------------------------------------------------------------
--                                                                           --
--                              STM32F0 USB                                  --
--                                                                           --
--                  Copyright (C) 2022      Marc PoulhiÃ¨s                    --
--                                                                           --
--    STM32F0 USB is free software: you can redistribute it and/or           --
--    modify it under the terms of the GNU General Public License as         --
--    published by the Free Software Foundation, either version 3 of the     --
--    License, or (at your option) any later version.                        --
--                                                                           --
--    STM32F0 USB is distributed in the hope that it will be useful,         --
--    but WITHOUT ANY WARRANTY; without even the implied warranty of         --
--    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU       --
--    General Public License for more details.                               --
--                                                                           --
--    You should have received a copy of the GNU General Public License      --
--    along with STM32F0 USB. If not, see <http://www.gnu.org/licenses/>. --
--                                                                           --
-------------------------------------------------------------------------------
--
--  SPDX-License-Identifier: GPL-3.0-or-later

pragma Restrictions (No_Elaboration_Code);

with HAL;
with System;

package STM32.USB_Btable is

   --  TX
   subtype ADDRN_TX_Field is HAL.UInt16;

   type USB_ADDRN_TX_Register is record
      ADDRN_TX : ADDRN_TX_Field := 16#0#;

   end record
   with
     Volatile_Full_Access,
     Object_Size => 16,
     Bit_Order => System.Low_Order_First;

   for USB_ADDRN_TX_Register use
     record
       ADDRN_TX at 0 range 0 .. 15;
     end record;

   subtype COUNTN_TX_Field is HAL.UInt10;

   type USB_COUNTN_TX_Register is record
      COUNTN_TX  : COUNTN_TX_Field := 16#0#;
      Reserved_0 : HAL.UInt6 := 16#0#;
   end record
   with
     Volatile_Full_Access,
     Object_Size => 16,
     Bit_Order => System.Low_Order_First;

   for USB_COUNTN_TX_Register use
     record
       COUNTN_TX at 0 range 0 .. 9;
       Reserved_0 at 0 range 10 .. 15;
     end record;

   --  RX
   subtype ADDRN_RX_Field is HAL.UInt16;

   type USB_ADDRN_RX_Register is record
      ADDRN_RX : ADDRN_RX_Field := 16#0#;

   end record
   with
     Volatile_Full_Access,
     Object_Size => 16,
     Bit_Order => System.Low_Order_First;

   for USB_ADDRN_RX_Register use
     record
       ADDRN_RX at 0 range 0 .. 15;
     end record;

   subtype COUNTN_RX_Field is HAL.UInt10;

   type USB_COUNTN_RX_Register is record
      COUNTN_RX : COUNTN_RX_Field := 16#0#;
      NUM_BLOCK : HAL.UInt5 := 16#0#;
      BL_SIZE   : HAL.Bit := 16#0#;
   end record
   with
     Volatile_Full_Access,
     Object_Size => 16,
     Bit_Order => System.Low_Order_First;

   for USB_COUNTN_RX_Register use
     record
       COUNTN_RX at 0 range 0 .. 9;
       NUM_BLOCK at 0 range 10 .. 14;
       BL_SIZE at 0 range 15 .. 15;
     end record;

   type EP_Group is record
      ADDR_TX  : USB_ADDRN_TX_Register;
      COUNT_TX : USB_COUNTN_TX_Register;
      ADDR_RX  : USB_ADDRN_RX_Register;
      COUNT_RX : USB_COUNTN_RX_Register;
   end record
   with Volatile, Object_Size => 64, Bit_Order => System.Low_Order_First;

   for EP_Group use
     record
       ADDR_TX at 16#0# range 0 .. 15;
       COUNT_TX at 16#2# range 0 .. 15;
       ADDR_RX at 16#4# range 0 .. 15;
       COUNT_RX at 16#6# range 0 .. 15;
     end record;

   type Btable_Type is array (UInt4) of EP_Group with Volatile;

   --  This is the first valid address for the Packet Memory

   Btable_Base : constant System.Address := System'To_Address (16#4000_6000#);

   Btable : aliased Btable_Type
   with Import, Address => Btable_Base;
end STM32.USB_Btable;
