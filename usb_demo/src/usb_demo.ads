with HAL;                    use HAL;
with Ada.Characters.Latin_1; use Ada.Characters.Latin_1;

package USB_Demo is
   Buffer   : String (1 .. 128) := (others => ' ')
   with Volatile;
   New_Line : constant String := CR & LF;
   Reply    : constant String := New_Line & "Sent from device: ";
   Greeting : constant String :=
     "Type some text to send to device then press enter." & New_Line;
   Count    : UInt32 := 1
   with Volatile;
   -- Export makes these available for live watch in debugger
   pragma Export (Convention => C, Entity => Count, External_Name => "lcount");
   pragma
     Export (Convention => C, Entity => Buffer, External_Name => "in_buffer");
   Length   : UInt32 := 0
   with Volatile;
   pragma
     Export (Convention => C, Entity => Length, External_Name => "rw_length");
   procedure Run;
   procedure USB_ISR_Handler
   with Export, Convention => C, External_Name => "__usb_handler";
end USB_Demo;
