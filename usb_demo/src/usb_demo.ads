with HAL; use HAL;

package USB_Demo is
   Buffer : String (1 .. 128) := (others => ' ')
   with Volatile;
   pragma
     Export (Convention => C, Entity => Buffer, External_Name => "in_buffer");

   Length : UInt32 := 128;
   procedure Run;
end USB_Demo;
