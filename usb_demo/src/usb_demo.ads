with HAL;                    use HAL;
with Ada.Characters.Latin_1; use Ada.Characters.Latin_1;

package USB_Demo is
   Buffer : UInt8_Array (1 .. 128)
   with Volatile;
   pragma
     Export (Convention => C, Entity => Buffer, External_Name => "in_buffer");
   Packet : UInt8_Array (1 .. 128)
   with Volatile;
   pragma
     Export (Convention => C, Entity => Packet, External_Name => "packet");
   Reply  : UInt8_Array (1 .. 128)
   with Volatile;
   pragma Export (Convention => C, Entity => Reply, External_Name => "reply");
   Count  : UInt32 := 1
   with Volatile;
   -- Export makes these available for live watch in debugger
   pragma Export (Convention => C, Entity => Count, External_Name => "lcount");
   Length : UInt32 := 0
   with Volatile;
   pragma
     Export (Convention => C, Entity => Length, External_Name => "rw_length");
   procedure Run;
end USB_Demo;
