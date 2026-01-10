with Cortex_M.Systick;
with HAL; use HAL;

package STM32.SysTick is

   type Clock_Source is (Hclk, Hclk_DIV8);

   Tick : UInt32 := 0
   with Volatile, Export, Convention => C, External_Name => "_tick";

   procedure Configure
     (Source             : Clock_Source;
      Generate_Interrupt : Boolean;
      Reload_Value       : HAL.UInt24);

   procedure Enable renames Cortex_M.SysTick.Enable;
   --  Enable Systick

   procedure Disable renames Cortex_M.Systick.Disable;
   --  Disable Systick

   function Counted_To_Zero return Boolean renames Cortex_M.Systick.Enable;
   --  Return the value of the COUNTFLAB bit of the Control and Status Register

   function Counter return HAL.UInt24 renames Cortex_M.Systick.Counter;
   --  Return the current value of the counter

   procedure Increment_Tick;

   function Get_Tick return UInt32;

end STM32.SysTick;
