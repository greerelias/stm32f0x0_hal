with Cortex_M.NVIC; use Cortex_M.NVIC;

package body STM32.SysTick is

   procedure Configure
     (Source             : Clock_Source;
      Generate_Interrupt : Boolean;
      Reload_Value       : HAL.UInt24) is
   begin
      Cortex_M.Systick.Configure
        (Source             =>
           (case Source is
              when Hclk      => Cortex_M.Systick.CPU_Clock,
              when Hclk_DIV8 => Cortex_M.Systick.External_Clock),
         Generate_Interrupt => Generate_Interrupt,
         Reload_Value       => Reload_Value);
   end Configure;

   procedure Enable is
   begin
      Enable_Interrupt (SysTick_Interrupt);
      Cortex_M.Systick.Enable;
   end Enable;

   procedure Disable is
   begin
      Disable_Interrupt (SysTick_Interrupt);
      Cortex_M.Systick.Disable;
   end Disable;

   procedure Increment_Tick is
   begin
      Tick := Tick + 1;
   end Increment_Tick;

   function Get_Tick return UInt32 is
   begin
      return Tick;
   end Get_Tick;

end STM32.SysTick;
