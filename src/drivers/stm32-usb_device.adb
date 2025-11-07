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
with STM32_SVD.USB; use STM32_SVD.USB;
with STM32_SVD.RCC; use STM32_SVD.RCC;

with STM32.GPIO;            use STM32.GPIO;
with STM32.USB_Btable;      use STM32.USB_Btable;
with STM32.USB_Serialtrace; use STM32.USB_Serialtrace;

package body STM32.USB_Device is

   --  The Packet Memory can be (according to the documentation) accessed using
   --  both 8-bits and 16-bits. Oddly, using byte access yields incorrect
   --  result with half of the bytes incorrect. Using 16-bits accesses is
   --  working as expected.
   --  All data moves to/from the packet memory must use this procedure.

   --  Fake memory-mapped registers (Btable) are not subject to this
   --  restrictions as they should all translate to 16-bits accesses correctly
   --  aligned.

   procedure HalfWord_Copy (Dst, Src : System.Address; Count : Natural) is
      use System.Storage_Elements;
      use System;

      type Vol_2Byte is new Interfaces.Unsigned_16 with Volatile_Full_Access;
      type Vol_2Byte_Array is
        array (Natural range 1 .. (Count + 1) / 2) of Vol_2Byte;

      Src_Arr : Vol_2Byte_Array
      with Address => Src;
      Dst_Arr : Vol_2Byte_Array
      with Address => Dst;

   begin
      if Src /= Dst then
         Dst_Arr := Src_Arr;
      end if;
   end HalfWord_Copy;


   --  The SVD package exports 1 type per register, which is handy in some
   --  context.
   --  In the case of the EPxR registers which are used to control USB
   --  endpoints, having an array is a better design.
   --  Erase the index from the type and allow the use of array indexing.
   type EPR_Register is new EP0R_Register;

   type EPR_Registers is
     array (UInt4 range 0 .. Num_Endpoints - 1) of EPR_Register
   with Size => 32 * Num_Endpoints, Volatile;

   EPRS : aliased EPR_Registers
   with Import, Address => USB_Periph.EP0R'Address;

   function Endpoint_Buffer_Address
     (This : in out UDC; Ep : USB.EP_Addr) return System.Address;
   --  Returns the address in the Packet Memory of the allocated buffer for the
   --  given Endpoint.

   function Get_EPR_With_Invariant
     (Current : EPR_Register) return EPR_Register;
   --  The EPR register have some fields that can only be flipped by writing a
   --  specific value. This function takes a value (usually read from the EPR
   --  register) and returns a copy with all fields using this flip mechanism
   --  set to the "do nothing" value. Meaning that writing back this value to
   --  the register would not change anything to the actual value of the
   --  register.

   procedure Copy_Endpoint_Rx_Buffer (This : in out UDC; Num : USB.EP_Id);
   --  Copy the data from the RX buffer associated with the enpoint to the
   --  allocated user buffer.

   procedure Reset_ISTR is
   begin
      USB_Periph.ISTR := (others => <>);
   end Reset_ISTR;

   overriding
   procedure Initialize (This : in out UDC) is
      DM_Pin : constant GPIO_Point := PA11;
      DP_Pin : constant GPIO_Point := PA12;
      use System.Storage_Elements;
   begin
      Init_Serialtrace; -- DEBUG

      --  StartLog ("> Initialize");

      Enable_Clock (DM_Pin & DP_Pin);

      Configure_IO (DM_Pin & DP_Pin, (Mode => Mode_In, Resistors => Floating));

      --  Should be UBSEN but SVD is wrong. Should fix it.
      RCC_Periph.APB1ENR.USBRST := True;

      RCC_Periph.APB1RSTR.USBRST := True;
      RCC_Periph.APB1RSTR.USBRST := False;

      Delay_Cycles (72);
      -- wait a bit

      USB_Periph.CNTR.PDWN := False;
      Delay_Cycles (72);

      for M in 0 .. 1023 loop
         declare
            Packet_Memory : UInt8
            with Address => Packet_Buffer_Base + Packet_Buffer_Offset (M);
         begin
            Packet_Memory := 0;
         end;
      end loop;

      Reset_ISTR;

      USB_Periph.CNTR :=
        (RESETM         => True,
         SUSPM          => True,
         WKUPM          => True,
         CTRM           => True,
         Reserved_6_6   => 0,
         Reserved_16_31 => 0,
         others         => False);

      --  Clear FRES. When set, RESET is forced and EP*R registers will be
      --  mostly forced to their reset state.
      -- USB_Periph.CNTR := (USB_Periph.CNTR with delta
      --                     FRES => False);

      --  Btable points to start of Packet Memory.

      --  First 64 bytes of PM are used for storing 4*16-bits * 8 EP descriptors
      --  (BTABLE)
      USB_Periph.BTABLE.BTABLE := 0;

      --  Enable Pull Up for Full Speed
      USB_Periph.BCDR.DPPU := True;

   --      EndLog ("< Initialize");
   end Initialize;

   procedure Allocate_Endpoint_Buffer
     (This : in out UDC; Ep : EP_Addr; Len : USB.Packet_Size)
   is
      use System.Storage_Elements;
      Offset : Packet_Buffer_Offset;

      Use_32b_block : Boolean := False;
      Num_Blocks    : Natural := 0;

   begin
      --      StartLog ("> Allocate_Endpoint_Buffer "
      --                  & Ep.Num'Image & ", Dir " & Ep.Dir'Image & " Len: " & Len'Image);

      if Ep.Num = 0 then

         --  Use the first Packet Memory for Control EP, always.
         --  /----------\
         --  |COUNT7_TX | 62-63
         --  |----------|
         --  |ADDR7_RX  | 60-61
         --  |----------|
         --  |COUNT7_TX | 58-59
         --  |----------|
         --  |ADDR7_TX  | 56-57

         --  ~~~~~~~~~~~~~~
         --
         --  ~~~~~~~~~~~~~~
         --  |ADDR2_RX  |
         --  |----------|
         --  |COUNT1_TX | 14-15
         --  |----------|
         --  |ADDR1_RX  | 12-13
         --  |----------|
         --  |COUNT1_TX | 10-11
         --  |----------|
         --  |ADDR1_TX  | 8-9
         --  |----------|
         --  |COUNT0_RX | 6-7
         --  |----------|
         --  |ADDR0_RX  | 4-5
         --  |----------|
         --  |COUNT0_TX | 2-3
         --  |----------|
         --  |ADDR0_TX  | 0-1  <---- Start of PM (BTABLE := 0)
         --  \----------/

         --  Always allocate 64 bytes for each direction for EP 0
         --  The memory starts being allocated after the BTABLE above (from
         --  offset 0 to 63).

         --  (0, In) (aka. TX) is at offset 64
         if Ep.Dir = EP_In then
            Offset := Num_Endpoints * 8;
         else
            --  (0, Out) (aka. RX) is at offset 128
            Offset := Num_Endpoints * 8 + 64;
         end if;

      else
         --  In EP memory, always align on half-words
         Offset := Allocate_Buffer (This, Natural (Len));
      end if;

      case Ep.Dir is
         when EP_In  =>
            This.EP_Status (Ep.Num).Tx_Buffer_Offset := Offset;

         when EP_Out =>
            if Len <= 62 then
               Num_Blocks := Integer (Len) / 2;
            else
               Num_Blocks := Integer (Len) / 32;
               Use_32b_block := True;
            end if;

            This.EP_Status (Ep.Num).Rx_Buffer_Offset := Offset;
            This.EP_Status (Ep.Num).Rx_Use_32b := Use_32b_block;
            This.EP_Status (Ep.Num).Rx_Num_Blocks := Num_Blocks;
      end case;

   --      EndLog ("< Allocate Endpoint Buffer");
   end Allocate_Endpoint_Buffer;

   --  Allocates 2 memory buffers:
   --  - a user buffer in RAM, used in the API, and the *only* thing that gets
   --  out of this package.
   --  - a packet buffer in packet memory. Used by the hardware, with
   --  particular constraint. Never to be seen outside of the package.

   overriding
   function Request_Buffer
     (This : in out UDC; Ep : EP_Addr; Len : USB.Packet_Size)
      return System.Address
   is
      Mcu_Facing_Mem : System.Address;
   begin
      --      StartLog ("> Request buffer "
      --                & Ep.Num'Image & ", Dir " & Ep.Dir'Image & " Len: " & Len'Image);

      --  Init hw & allocate in packet memory
      This.Allocate_Endpoint_Buffer (Ep, Len);

      Mcu_Facing_Mem :=
        Standard.USB.Utils.Allocate (This.Alloc, Alignment => 4, Len => Len);

      case Ep.Dir is
         when EP_In  =>
            This.EP_Status (Ep.Num).Tx_User_Buffer_Address := Mcu_Facing_Mem;
            This.EP_Status (Ep.Num).Tx_User_Buffer_Len := Len;

         when EP_Out =>
            This.EP_Status (Ep.Num).Rx_User_Buffer_Address := Mcu_Facing_Mem;
            This.EP_Status (Ep.Num).Rx_User_Buffer_Len := Len;
      end case;

      --      EndLog ("< Request buffer");

      return Mcu_Facing_Mem;
   end Request_Buffer;

   overriding
   procedure Start (This : in out UDC) is
   begin
      --      StartLog ("> Start");

      USB_Periph.CNTR :=
        (USB_Periph.CNTR
         with delta
           FRES   => False,
           RESETM => True,
           SUSPM  => True,
           WKUPM  => True,
           CTRM   => True);
      Reset_ISTR;

      --  Btable points to start of Packet Memory.
      --  First 64 bytes of PM are used for storing 4*16-bits * 8 EP
      --  descriptors.
      USB_Periph.BTABLE.BTABLE := 0;

      --  Enable Pull Up for Full Speed
      USB_Periph.BCDR.DPPU := True;

   --      EndLog ("< Start");
   end Start;

   overriding
   procedure Reset (This : in out UDC) is
   begin
      --      StartLog ("> Reset");
      ----      Log ("Disabling RX/TX for all EP > 0 (1..8)");

      --  Reset ALL Endpoint except for 0 (control)
      --  EP 0 should be setup by controller when doing reset.
      for Ep in EPR_Registers'First + 1 .. EPR_Registers'Last loop
         declare
            UPR : EPR_Register renames EPRS (Ep);
            Cur : constant EPR_Register := UPR;
         begin
            EPRS (Ep) :=
              (Get_EPR_With_Invariant (Cur)
               with delta
                 STAT_RX => Cur.STAT_RX xor 0,
                 STAT_TX => Cur.STAT_TX xor 0);
         end;
      end loop;

      --      Log ("Reseting allocator state");
      --  Deallocate all buffer except for Control
      --  HACK: should be done elsewhere. 64 bytes for Btable, 64 bytes for RX,
      --  64 bytes for TX.

      This.Next_Buffer :=
        System.Storage_Elements.Storage_Offset (Num_Endpoints * 8 + 128);

   --      EndLog ("< Reset");
   end Reset;

   procedure Clear_Ctr_Tx (Ep : EP_Id) is
      UPR : EPR_Register renames EPRS (Ep);
      Cur : constant EPR_Register := UPR;
   begin
      UPR := (Get_EPR_With_Invariant (Cur) with delta CTR_TX => False);
   end Clear_Ctr_Tx;

   procedure Clear_Ctr_Rx (Ep : EP_Id) is
      UPR : EPR_Register renames EPRS (Ep);
      Cur : constant EPR_Register := UPR;
   begin
      UPR := (Get_EPR_With_Invariant (Cur) with delta CTR_RX => False);
   end Clear_Ctr_Rx;

   pragma Warnings (Off, "is not referenced");
   function Setup_Data_Image (R : Setup_Data) return String is
   begin
      return
        "SetupData Rtype: "
        & "(Rec: "
        & R.RType.Recipient'Image
        & ", Typ:"
        & R.RType.Typ'Image
        & " Dir: "
        & (if R.RType.Dir = Device_To_Host then "D2H" else "H2D")
        & "),"
        & "Request: "
        & R.Request'Image
        & " ,"
        & "Value: "
        & R.Value'Image
        & " ,"
        & "Index: "
        & R.Index'Image
        & ","
        & "Length: "
        & R.Length'Image;
   end Setup_Data_Image;

   function Istr_Image (Istr : in ISTR_Register) return String is
      Res : String :=
        "EPID: 00, DIR: XXX, L1R: 0, ESOF: 0, SOF: 0, RST: 0, SUSP: 0, WKUP: 0, ERR: 0, PMAOVR: 0, CTR: 0";
   begin
      Res (Res'First + 6 .. Res'First + 7) := Istr.EP_ID'Image;
      Res (Res'First + 15 .. Res'First + 17) :=
        (if Istr.DIR then "OUT" else " IN");
      Res (Res'First + 25) := (if Istr.L1REQ then '1' else '0');

      Res (Res'First + 34) := (if Istr.ESOF then '1' else '0');
      Res (Res'First + 42) := (if Istr.SOF then '1' else '0');
      Res (Res'First + 50) := (if Istr.RESET then '1' else '0');
      Res (Res'First + 59) := (if Istr.SUSP then '1' else '0');
      Res (Res'First + 68) := (if Istr.WKUP then '1' else '0');
      Res (Res'First + 76) := (if Istr.ERR then '1' else '0');
      Res (Res'First + 87) := (if Istr.PMAOVR then '1' else '0');
      Res (Res'First + 95) := (if Istr.CTR then '1' else '0');

      return Res;
   end Istr_Image;

   -- procedure Reset_EP_Status (This : in out UDC) is
   -- begin
   --    for Ep in EPR_Registers'range when This.EP_Status (Ep).Valid loop
   --       This.EP_Status (Ep).Rx_User_Buffer_Address := System.Null_Address;
   --       This.EP_Status (Ep).Rx_User_Buffer_Len := 0;

   --       This.EP_Status (Ep).Tx_User_Buffer_Address := System.Null_Address;
   --       This.EP_Status (Ep).Tx_User_Buffer_Len := 0;
   --    end loop;
   -- end Reset_EP_Status;

   function EPR_Image (Epr : EPR_Register) return String is
   begin
      return
        "EA:"
        & Epr.EA'Image
        & " STAT_TX:"
        & Epr.STAT_TX'Image
        & " DTOG_TX: "
        & Epr.DTOG_TX'Image
        & " CRT_TX: "
        & Epr.CTR_TX'Image
        & " CTR_TX: "
        & Epr.CTR_TX'Image
        & " EP_KIND: "
        & Epr.EP_KIND'Image
        & " EP_TYPE: "
        & Epr.EP_TYPE'Image
        & " SETUP: "
        & Epr.SETUP'Image
        & " STAT_RX: "
        & Epr.STAT_RX'Image
        & " DTOG_RX: "
        & Epr.DTOG_RX'Image
        & " CTR_RX: "
        & Epr.CTR_RX'Image;
   end EPR_Image;

   overriding
   function Poll (This : in out UDC) return UDC_Event is
      --  Neutral ISTR register values
      Neutral_Istr : constant ISTR_Register :=
        (EP_ID => 0, Reserved_5_6 => 0, Reserved_16_31 => 0, others => True);
      Istr         : ISTR_Register renames USB_Periph.ISTR;
      Cur_Istr     : constant ISTR_Register := Istr;
   begin
      if Cur_Istr.RESET then
         --  Clear RESET by writing 0. Writing 1 in other fields leave them unchanged.
         Startlog ("## Reset");
         --         Log ("!! Reset RECEIVED");
         --         Log ("ISTR: " & Istr_Image (Cur_Istr));

         -- This.Reset_EP_Status;

         Istr :=
           (Neutral_Istr with delta RESET => False --  Clear
           );

         --         EndLog("## return RESET to controller");
         --  This.Reset;
         return (Kind => USB.HAL.Device.Reset);

      elsif Cur_Istr.WKUP then
         --  See rm0091 p871

         --  Clear WKUP by writing 0. Writing 1 in other fields leave them unchanged.
         Istr :=
           (Neutral_Istr with delta WKUP => False --  Clear
           );
         USB_Periph.CNTR.FSUSP := False;

      elsif Cur_Istr.SUSP then
         --  Clear SUSP by writing 0. Writing 1 in other fields leave them unchanged.
         Istr :=
           (Neutral_Istr with delta SUSP => False  -- Clear
           );

      elsif Cur_Istr.CTR then
         declare
            EP_Id        : constant UInt4 := Istr.EP_ID;
            EP_Data_Size : UInt10;
         begin
            Startlog ("## CTR", 2);
            --            Log ("Poll " & Istr_Image (Cur_Istr), 2);
            --            Log ("EPR: " & EPR_Image (EPRS(EP_Id)), 2);

            if EPRS (EP_Id).CTR_RX then
               if EPRS (EP_Id).SETUP then
                  --                  Log ("EPR (clr): " & EPR_Image (EPRS(EP_Id)), 2);
                  declare
                     Req : Setup_Data;
                  begin
                     HalfWord_Copy
                       (Req'Address,
                        This.Endpoint_Buffer_Address ((EP_Id, EP_Out)),
                        Natural (Req'Size));
                     --                     Log (" --> SETUP " & Setup_Data_Image (Req), 2, -1);
                     ----                     Endlog("## return Setup_Request");

                     Clear_Ctr_Rx (EP_Id);  --  ACK the reception

                     return
                       (Kind   => Setup_Request,
                        Req    => Req,
                        Req_Ep => Ep_Id); --  Always EP 0
                  end;
               else

                  -- OUT transaction, RX from device PoV
                  -- Need to copy DATA from EP buffer to app buffer.
                  EP_Data_Size := Btable (Ep_Id).COUNT_RX.COUNTN_RX;
                  Copy_Endpoint_Rx_Buffer (This, EP_Id);

                  Clear_Ctr_Rx (EP_Id);  --  ACK the reception

                  ----                  Log (" --> TRANSFER OUT/RX OK", 2);
                  --                  Endlog("## return Transfer_Complete");
                  return
                    (Kind => Transfer_Complete,
                     EP   => (EP_Id, EP_Out),
                     BCNT => USB.Packet_Size (EP_Data_Size));
               end if;
            end if;

            if not EPRS (EP_Id).CTR_TX then
               raise Program_Error with "CTR_TX should be set";
            end if;

            --  If we are here, then CTR_TX must be set.

            --  IN transaction, TX from device PoV
            --  Only need to ACK and report back the number of bytes sent.

            EP_Data_Size := Btable (Ep_Id).COUNT_TX.COUNTN_TX;

            Clear_Ctr_Tx (EP_Id);  -- ACK the transmission
            --            Log (" --> TRANSFER IN/TX OK (" & EP_Data_Size'Image & ")");
            --            Endlog ("## return Transfer_Complete");
            return
              (Kind => Transfer_Complete,
               EP   => (EP_Id, EP_In),
               BCNT => USB.Packet_Size (EP_Data_Size));
         end;
      end if;
      return No_Event;
   end Poll;

   function Endpoint_Buffer_Address
     (This : in out UDC; Ep : USB.EP_Addr) return System.Address
   is
      use System.Storage_Elements;
   begin
      case EP.Dir is
         when EP_Out =>
            return
              This.EP_Status (Ep.Num).Rx_Buffer_Offset + Packet_Buffer_Base;

         when EP_In  =>
            return
              This.EP_Status (Ep.Num).Tx_Buffer_Offset + Packet_Buffer_Base;
      end case;
   end Endpoint_Buffer_Address;

   function Send_Would_Block (This : UDC; Ep : EP_Id) return Boolean is
      UPR : EPR_Register renames EPRS (Ep);
      Cur : constant EPR_Register := UPR;
   begin
      return Cur.STAT_TX = 3;
   end Send_Would_Block;

   overriding
   procedure EP_Send_Packet
     (This : in out UDC; Ep : EP_Id; Len : USB.Packet_Size)
   is
      Src_User_Buffer : constant System.Address :=
        This.EP_Status (Ep).Tx_User_Buffer_Address;

      UPR : EPR_Register renames EPRS (Ep);
      Cur : constant EPR_Register := UPR;
   begin
      --      StartLog ("> EP_Send_Packet " & Ep'Image, 3);

      --  If VALID (3), there must be a pending write...
      --  Better panic than do garbage
      if Cur.STAT_TX = 3 then
         raise Program_Error with "Would block";
      end if;

      HalfWord_Copy
        (This.Endpoint_Buffer_Address ((Ep, USB.EP_In)),
         Src_User_Buffer,
         Natural (Len));

      Btable (Ep).COUNT_TX.COUNTN_TX := UInt10 (Len);

      --  Set STAT_TX to VALID
      UPR :=
        (Get_EPR_With_Invariant (Cur) with delta STAT_TX => Cur.STAT_TX xor 3);

   --      EndLog ("< EP_Send_Packet", 3);
   end EP_Send_Packet;

   function Get_EPR_With_Invariant (Current : EPR_Register) return EPR_Register
   is
   begin

      --  Invariant fields as described in the doc (RM0091 p883).
      --  When doing RMW, the recommended way is
      --  - load value from register
      --  - write 'invariant' values in fields that can only be modified by the
      --    hw
      --  - modify other fields
      --  - write back the register

      return
        (Current
         with delta
           CTR_RX  => True,
           DTOG_RX => False,
           STAT_RX => 0,
           CTR_TX  => True,
           DTOG_TX => False,
           STAT_TX => 0);
   end Get_EPR_With_Invariant;

   --  Allocates an EP
   --  Resets its registers.
   --  Buffers must have been allocated before.
   overriding
   procedure EP_Setup (This : in out UDC; EP : EP_Addr; Typ : EP_Type) is

      UPR : EPR_Register renames EPRS (Ep.Num);

      type EP_Type_Mapping_T is array (EP_Type) of UInt2;
      EPM : constant EP_Type_Mapping_T :=
        [Bulk => 0, Control => 1, Isochronous => 2, Interrupt => 3];

      type EP_Type_Mapping_T2 is array (EP_Type) of String (1 .. 4);
      EPM2 : constant EP_Type_Mapping_T2 :=
        [Bulk        => "BULK",
         Control     => "CTRL",
         Isochronous => "ISO ",
         Interrupt   => "INT "];

      Cur : constant EPR_Register := UPR;
      Tmp : EPR_Register;

   begin
      --      StartLog ("> EP_Setup " & EP.Num'Image & ", "
      --  & (if EP.Dir = EP_In then "IN" else "OUT")
      --  & " Typ: " & EPM2(Typ));

      if Ep.Num > Num_Endpoints then
         raise Program_Error with "Invalid endpoint number";
      end if;


      --  Write BTABLE entry
      case Ep.Dir is
         when EP_In  =>
            Btable (Ep.Num).ADDR_TX :=
              ((ADDRN_TX =>
                  UInt16 (This.EP_Status (Ep.Num).Tx_Buffer_Offset)));
            Btable (Ep.Num).COUNT_TX.COUNTN_TX := 0;

         when EP_Out =>
            Btable (Ep.Num).ADDR_RX :=
              (ADDRN_RX => UInt16 (This.EP_Status (Ep.Num).Rx_Buffer_Offset));

            Btable (Ep.Num).COUNT_RX :=
              (BL_SIZE   =>
                 Bit (if This.EP_Status (Ep.Num).Rx_Use_32b then 1 else 0),
               NUM_BLOCK => UInt5 (This.EP_Status (Ep.Num).Rx_Num_Blocks),
               others    => 0);
      end case;

      This.EP_Status (EP.Num).Typ := Typ;
      This.EP_Status (EP.Num).Valid := True;

      --      Log("EPR      : " & EPR_Image(UPR));
      Tmp :=
        (Get_EPR_With_Invariant (Cur)
         with delta

           DTOG_TX =>
             (if EP.Dir = EP_In then False xor Cur.DTOG_TX else False),
           DTOG_RX =>
             (if EP.Dir = EP_Out then False xor Cur.DTOG_RX else False),
           CTR_RX  => False,
           CTR_TX  => False,
           EP_KIND => False,
           EA      => EP.Num,
           EP_TYPE => EPM (Typ),

           -- NAK RX/TX for corresponding Direction
           STAT_TX => (if EP.Dir = EP_In then Cur.STAT_TX xor 2 else 0),
           STAT_RX => (if EP.Dir = EP_Out then Cur.STAT_RX xor 2 else 0));
      --      Log("Tmp      : " & EPR_Image(Tmp));
      UPR := Tmp;

   --      Log("EPR (set): " & EPR_Image(UPR));

   --      Log("btable: addr_rx" & Btable(Ep.Num).ADDR_RX.ADDRN_RX'Image &
   --  " count_rx: " & Btable(Ep.Num).COUNT_RX.COUNTN_RX'Image &
   --  " bl: " & Btable(Ep.Num).COUNT_RX.BL_SIZE'Image &
   --  " nb: " & Btable(Ep.Num).COUNT_RX.NUM_BLOCK'Image &
   --  " addr_tx: " & Btable(Ep.Num).ADDR_TX.ADDRN_TX'Image &
   --  " count_tx: " & Btable(Ep.Num).COUNT_TX.COUNTN_TX'Image);

   --      EndLog ("< EP_Setup");
   end EP_Setup;

   --  Set the endpoint in a state ready for EP_Out/RX transactions.
   --  NOTE: Maybe check the buffer address. Should be a user buffer
   --  or a packet buffer address already assigned. We should not touch BTABLE
   --  here.
   overriding
   procedure EP_Ready_For_Data
     (This  : in out UDC;
      EP    : EP_Id;
      Size  : USB.Packet_Size;
      Ready : Boolean := True)
   is
      UPR : EPR_Register renames EPRS (Ep);
      Cur : constant EPR_Register := UPR;
   begin
      --      StartLog ("> EP_Ready_For_Data " & EP'Image
      --                  & " len: " & Size'Image & " ready: " & Ready'Image, 2);

      --      Log ("EPR      : " & EPR_Image(UPR));

      --  nothing ready, still waiting
      if Cur.STAT_RX = 3 then
         --         EndLog ("< EP_Ready_For_Data (EP already ready to receive data)", 2);
         return;
      end if;

      if Ready then
         --  Set STAT_RX to VALID (0b11) to enable data reception.
         UPR :=
           (Get_EPR_With_Invariant (Cur)
            with delta STAT_RX => Cur.STAT_RX xor 3);
      else
         --  Set to NAK if not ready (why is it needed??)
         UPR :=
           (Get_EPR_With_Invariant (Cur)
            with delta STAT_RX => Cur.STAT_RX xor 2);
      end if;

   --      Log ("EPR (set): " & EPR_Image(UPR));
   --      EndLog ("< EP_Ready_For_Data", 2);
   end EP_Ready_For_Data;

   overriding
   procedure EP_Stall (This : in out UDC; EP : EP_Addr; Set : Boolean := True)
   is
      UPR : EPR_Register renames EPRS (Ep.Num);
      Cur : constant EPR_Register := UPR;
      V   : constant UInt2 := (if Set then 1 else 2);
   begin
      --      StartLog ("> EP_Stall " & EP.Num'Image & " set: " & Set'Image);

      case Ep.Dir is
         when USB.EP_In  =>
            UPR :=
              (Get_EPR_With_Invariant (Cur)
               with delta STAT_TX => Cur.STAT_TX xor V);

            if not Set then
               UPR :=
                 (Get_EPR_With_Invariant (Cur)
                  with delta DTOG_TX => False xor Cur.DTOG_TX);
            end if;

         when USB.EP_Out =>
            UPR :=
              (Get_EPR_With_Invariant (Cur)
               with delta STAT_RX => Cur.STAT_RX xor V);
            if not Set then
               UPR :=
                 (Get_EPR_With_Invariant (Cur)
                  with delta DTOG_RX => False xor Cur.DTOG_RX);
            end if;
      end case;
   --      EndLog ("< EP_Stall");
   end EP_Stall;

   overriding
   procedure Set_Address (This : in out UDC; Addr : UInt7) is
   begin
      --      StartLog ("> Set_Address " & Addr'Image);

      USB_Periph.DADDR.ADD := Addr;
      USB_Periph.DADDR.EF := True;
   --      EndLog ("< Set_Address");
   end Set_Address;

   procedure Copy_Endpoint_Rx_Buffer (This : in out UDC; Num : USB.EP_Id) is
      use System.Storage_Elements;
      use System;

      Length         : constant Storage_Offset :=
        Storage_Offset (Btable (Num).COUNT_RX.COUNTN_RX);
      Source_Address : constant Address :=
        This.Endpoint_Buffer_Address ((Num => Num, Dir => USB.EP_Out));
      Target_Address : constant Address :=
        This.EP_Status (Num).Rx_User_Buffer_Address;

   begin
      --      StartLog ("Copy_Endpoint_Rx_Buffer " & Num'Image);

      if Length = 0 or else Target_Address = System.Null_Address then
         return;
      end if;

      HalfWord_Copy (Target_Address, Source_Address, Natural (Length));

   --      EndLog ("< Copy_Endpoint_Rx_Buffer");
   end Copy_Endpoint_Rx_Buffer;

   function Allocate_Buffer
     (This : in out UDC; Size : Natural) return Packet_Buffer_Offset
   is
      use System.Storage_Elements;
      Addr  : Packet_Buffer_Offset := This.Next_Buffer;
      A     : constant Natural := Natural (Addr) mod 16;
      Extra : constant Natural := 16 - A;
   begin
      if A /= 0 then
         Addr := Addr + Storage_Offset (Extra);
      end if;

      This.Next_Buffer :=
        This.Next_Buffer + Storage_Offset (Extra) + Storage_Offset (Size);
      return Addr;
   end Allocate_Buffer;

end STM32.USB_Device;
