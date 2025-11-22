with HAL;                    use HAL;
with Ada.Characters.Latin_1; use Ada.Characters.Latin_1;

package USB_Demo is
   Buffer    : String (1 .. 128) := (others => ' ')
   with Volatile;
   New_Line  : constant String := CR & LF;
   Reply     : constant String := New_Line & "Sent from device: ";
   -- Length arguements to Serial.Write have to be a variable
   -- no constants/literals permitted
   NL_Len    : Uint32 := Uint32 (New_Line'Length);
   Reply_Len : Uint32 := Uint32 (Reply'Length);

   Count : UInt32 := 1
   with Volatile;
   pragma Export (Convention => C, Entity => Count, External_Name => "lcount");
   pragma
     Export (Convention => C, Entity => Buffer, External_Name => "in_buffer");

   Length : UInt32 := 0
   with Volatile;
   pragma
     Export (Convention => C, Entity => Length, External_Name => "in_length");
   procedure Run;
end USB_Demo;
