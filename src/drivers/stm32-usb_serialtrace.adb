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
--    along with STM32F0 USB. If not, see <http://www.gnu.org/licenses/>.    --
--                                                                           --
-------------------------------------------------------------------------------
--
--  SPDX-License-Identifier: GPL-3.0-or-later

with STM32.Device;  use STM32.Device;
with STM32.USARTs;  use STM32.USARTs;
with STM32.GPIO;    use STM32.GPIO;
with STM32_SVD.USB; use STM32_SVD.USB;

package body STM32.USB_Serialtrace is
   Indent : Natural := 0;
   TX_Pin : constant GPIO_Point := PB6;
   RX_Pin : constant GPIO_Point := PB7;

   Log_Enabled : constant Boolean := True;
   Log_Level   : constant Integer := 3;

   procedure Init_Serialtrace is
   begin
      if not Log_Enabled then
         return;
      end if;

      Enable_Clock (USART_1);
      Enable_Clock (RX_Pin & TX_Pin);
      Configure_IO
        (RX_Pin & TX_Pin,
         (Mode           => Mode_AF,
          AF             => GPIO_B_AF_USART1_0,
          Resistors      => Pull_Up,
          AF_Speed       => Speed_50MHz,
          AF_Output_Type => Push_Pull));

      Disable (USART_1);

      Set_Oversampling_Mode (USART_1, Oversampling_By_16);
      Set_Baud_Rate (USART_1, 115_200);
      Set_Mode (USART_1, Tx_Rx_Mode);
      Set_Stop_Bits (USART_1, Stopbits_1);
      Set_Word_Length (USART_1, Word_Length_8);
      Set_Parity (USART_1, No_Parity);
      Set_Flow_Control (USART_1, No_Flow_Control);

      Enable (USART_1);
      --  Log ("START");
      --  Log ("--");
   end Init_Serialtrace;

   procedure Await_Send_Ready (This : USART) is
   begin
      loop
         exit when Tx_Ready (This);
      end loop;
   end Await_Send_Ready;

   procedure Put_Blocking (This : in out USART; Data : UInt16) is
   begin
      Await_Send_Ready (This);
      Transmit (This, UInt9 (Data));
   end Put_Blocking;

   procedure Log (S : String; L : Integer := 1; Deindent : Integer := 0) is
   begin
      if not Log_Enabled or else L < Log_Level then
         return;
      end if;

      for I in 0 .. Indent loop
         Put_Blocking (USART_1, Character'Pos ('|'));
         Put_Blocking (USART_1, Character'Pos (' '));
      end loop;

      if USB_Periph.ISTR.RESET then
         Put_BLocking (USART_1, Character'Pos ('+'));
      else
         Put_BLocking (USART_1, Character'Pos (' '));
      end if;

      for C of S loop
         Put_Blocking (USART_1, Character'Pos (C));
      end loop;
      Put_Blocking (USART_1, UInt16 (13)); -- CR
      Put_Blocking (USART_1, UInt16 (10)); -- LF

      Indent := Indent + Deindent;
   end Log;

   procedure StartLog (S : String; L : Integer := 1) is
   begin
      if not Log_Enabled or else L < Log_Level then
         return;
      end if;

      Log (S, L);
      Indent := Indent + 1;
   end StartLog;

   procedure EndLog (S : String; L : Integer := 1) is
   begin
      if not Log_Enabled or else L < Log_Level then
         return;
      end if;

      Indent := Indent - 1;
      Log (S, L);
   end EndLog;

end STM32.USB_Serialtrace;
