with HAL;                    use HAL;
with Ada.Characters.Latin_1; use Ada.Characters.Latin_1;

package USB_Demo is
   Buffer          : UInt8_Array (1 .. 128)
   with Volatile;
   --  Buffer : String (1 .. 128)
   --  with Volatile;
   pragma
     Export (Convention => C, Entity => Buffer, External_Name => "in_buffer");
   Packet          : UInt8_Array (1 .. 128)
   with Volatile;
   pragma
     Export (Convention => C, Entity => Packet, External_Name => "in_packet");
   Reply           : UInt8_Array (1 .. 128)
   with Volatile;
   pragma
     Export (Convention => C, Entity => Reply, External_Name => "out_packet");
   Count           : UInt32 := 1
   with Volatile;
   -- Export makes these available for live watch in debugger
   pragma Export (Convention => C, Entity => Count, External_Name => "lcount");
   Length          : UInt32 := 0
   with Volatile;
   pragma
     Export (Convention => C, Entity => Length, External_Name => "rw_length");
   Device_Info_Pkt : aliased constant String :=
     Character'Val (170) & Character'Val (1) & "AdaBMP v0.1.0";
   Device_Info     : constant UInt8_Array (1 .. Device_Info_Pkt'Length)
   with Import, Convention => Ada, Address => Device_Info_Pkt'Address;
   procedure Run;
   procedure SysTick_Handler
   with Export, Convention => C, External_Name => "SysTick_Handler";
   procedure USB_ISR_Handler
   with Export, Convention => C, External_Name => "__usb_handler";
   procedure EXTI4_15_Handler
   with Export, Convention => C, External_Name => "__exti4_15_handler";
end USB_Demo;
