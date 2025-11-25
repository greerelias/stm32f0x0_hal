with HAL;                    use HAL;
with Ada.Characters.Latin_1; use Ada.Characters.Latin_1;
with Ada.Streams;            use Ada.Streams;

package USB_Demo is
   Buffer : Stream_Element_Array (1 .. 128)
   with Volatile;
   Packet : Stream_Element_Array (1 .. 128)
   with Volatile;
   Reply  : Stream_Element_Array (1 .. 128)
   with Volatile;
   Count  : UInt32 := 1
   with Volatile;
   -- Export makes these available for live watch in debugger
   pragma Export (Convention => C, Entity => Count, External_Name => "lcount");
   pragma
     Export (Convention => C, Entity => Buffer, External_Name => "in_buffer");
   pragma
     Export (Convention => C, Entity => Packet, External_Name => "packet");
   pragma Export (Convention => C, Entity => Reply, External_Name => "reply");
   Length : UInt32 := 0
   with Volatile;
   pragma
     Export (Convention => C, Entity => Length, External_Name => "rw_length");
   procedure Run;
end USB_Demo;
