with Cortex_M.Systick;

package STM32.SysTick is

   type Clock_Source is (Hclk, Hclk_DIV8);

   SysTick_Interrupt : constant := 15;

   Tick : UInt32 := 0
   with
     Volatile,
     Export,
     Convention    => C,
     External_Name => "db_systick"; --just for debugging remove later

   procedure Configure
     (Source             : Clock_Source;
      Generate_Interrupt : Boolean;
      Reload_Value       : HAL.UInt24);

   procedure Enable;
   --  Enable Systick

   procedure Disable;
   --  Disable Systick

   function Counted_To_Zero return Boolean
   renames Cortex_M.Systick.Counted_To_Zero;
   --  Return the value of the COUNTFLAB bit of the Control and Status Register

   function Counter return HAL.UInt24 renames Cortex_M.Systick.Counter;
   --  Return the current value of the counter

   procedure Increment_Tick;

   function Get_Tick return UInt32;

end STM32.SysTick;
