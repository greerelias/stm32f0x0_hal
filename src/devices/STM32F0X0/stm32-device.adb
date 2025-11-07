with System;        use System;
with System.Machine_Code;
with STM32_SVD.RCC; use STM32_SVD.RCC;

package body STM32.Device is

   --  FIXME  ADL_Config.High_Speed_External_Clock;
   --  No board, so no ADL_Config
   HSE_VALUE : constant := 0;
   --  External oscillator in Hz

   HSI_VALUE : constant := 8_000_000;
   --  Internal oscillator in Hz

   HSI48_VALUE : constant := 48_000_000;
   --  internal oscillator in Hz

   HPRE_Presc_Table : constant array (UInt4) of UInt32 :=
     [1, 1, 1, 1, 1, 1, 1, 1, 2, 4, 8, 16, 64, 128, 256, 512];

   PPRE_Presc_Table : constant array (UInt3) of UInt32 :=
     [1, 1, 1, 1, 2, 4, 8, 16];

   procedure Delay_Cycles (Cycles : UInt32) is
      use System.Machine_Code;
      use ASCII;
      Tmp : constant UInt32 := 1 + Cycles / 2;
   begin
      Asm
        ("1:" & LF & HT & "sub %0, #1" & LF & HT & "bne 1b" & LF & HT,
         Inputs   => (UInt32'Asm_Input ("r", Tmp)),
         Clobber  => "r3",
         Volatile => True);
   end Delay_Cycles;

   ------------------------------
   -- GPIO_Port_Representation --
   ------------------------------

   function GPIO_Port_Representation (Port : GPIO_Port) return UInt4 is
   begin
      --  TODO: rather ugly to have this board-specific range here
      if Port'Address = GPIOA_Base then
         return 0;
      elsif Port'Address = GPIOB_Base then
         return 1;
      elsif Port'Address = GPIOC_Base then
         return 2;
      elsif Port'Address = GPIOD_Base then
         return 3;
      --  elsif Port'Address = GPIOE_Base then -- Commented Out 11/4/25. GPIOE is undefined
      --     return 4;
      elsif Port'Address = GPIOF_Base then
         return 5;
      else
         raise Program_Error;
      end if;
   end GPIO_Port_Representation;

   ------------------
   -- Enable_Clock --
   ------------------

   procedure Enable_Clock (This : aliased in out GPIO_Port) is
   begin
      if This'Address = GPIOA_Base then
         RCC_Periph.AHBENR.IOPAEN := True;
      elsif This'Address = GPIOB_Base then
         RCC_Periph.AHBENR.IOPBEN := True;
      elsif This'Address = GPIOC_Base then
         RCC_Periph.AHBENR.IOPCEN := True;
      elsif This'Address = GPIOD_Base then
         RCC_Periph.AHBENR.IOPDEN := True;
      --  There is an error in the SVD file where this BIT (21 in
      --  RCC_AHBENR) is missing.
      --  elsif This'Address = GPIOE_Base then
      --    RCC_Periph.AHBENR.IOPEEN := True;
      elsif This'Address = GPIOF_Base then
         RCC_Periph.AHBENR.IOPFEN := True;
      else
         raise Unknown_Device;
      end if;
   end Enable_Clock;

   ------------------
   -- Enable_Clock --
   ------------------

   procedure Enable_Clock (Point : GPIO_Point) is
   begin
      Enable_Clock (Point.Periph.all);
   end Enable_Clock;

   ------------------
   -- Enable_Clock --
   ------------------

   procedure Enable_Clock (Points : GPIO_Points) is
   begin
      for Point of Points loop
         Enable_Clock (Point.Periph.all);
      end loop;
   end Enable_Clock;

   -----------
   -- Reset --
   -----------

   procedure Reset (This : aliased in out GPIO_Port) is
   begin
      if This'Address = GPIOA_Base then
         RCC_Periph.AHBRSTR.IOPARST := True;
         RCC_Periph.AHBRSTR.IOPARST := False;
      elsif This'Address = GPIOB_Base then
         RCC_Periph.AHBRSTR.IOPBRST := True;
         RCC_Periph.AHBRSTR.IOPBRST := False;
      elsif This'Address = GPIOC_Base then
         RCC_Periph.AHBRSTR.IOPCRST := True;
         RCC_Periph.AHBRSTR.IOPCRST := False;
      elsif This'Address = GPIOD_Base then
         RCC_Periph.AHBRSTR.IOPDRST := True;
         RCC_Periph.AHBRSTR.IOPDRST := False;

      --  There is an error in the SVD file where this BIT (21 in RCC_AHBRSTR) is
      --  missing.
      --  elsif This'Address = GPIOE_Base then
      --     RCC_Periph.AHBRSTR.IOPERST := True;
      --     RCC_Periph.AHBRSTR.IOPERST := False;
      elsif This'Address = GPIOF_Base then
         RCC_Periph.AHBRSTR.IOPFRST := True;
         RCC_Periph.AHBRSTR.IOPFRST := False;
      else
         raise Unknown_Device;
      end if;
   end Reset;

   -----------
   -- Reset --
   -----------

   procedure Reset (Point : GPIO_Point) is
   begin
      Reset (Point.Periph.all);
   end Reset;

   -----------
   -- Reset --
   -----------

   procedure Reset (Points : GPIO_Points) is
      Do_Reset : Boolean;
   begin
      for J in Points'Range loop
         Do_Reset := True;
         for K in Points'First .. J - 1 loop
            if Points (K).Periph = Points (J).Periph then
               Do_Reset := False;

               exit;
            end if;
         end loop;

         if Do_Reset then
            Reset (Points (J).Periph.all);
         end if;
      end loop;
   end Reset;

   ------------------
   -- Enable_Clock --
   ------------------

   procedure Enable_Clock (This : aliased in out USART) is
   begin
      if This.Periph.all'Address = USART1_Base then
         RCC_Periph.APB2ENR.USART1EN := True;
      elsif This.Periph.all'Address = USART2_Base then
         RCC_Periph.APB1ENR.USART2EN := True;
      elsif This.Periph.all'Address = USART3_Base then
         RCC_Periph.APB1ENR.USART3EN := True;
      elsif This.Periph.all'Address = USART4_Base then
         RCC_Periph.APB1ENR.USART4EN := True;
      else
         raise Unknown_Device;
      end if;
   end Enable_Clock;

   -----------
   -- Reset --
   -----------

   procedure Reset (This : aliased in out USART) is
   begin
      if This.Periph.all'Address = USART1_Base then
         RCC_Periph.APB2RSTR.USART1RST := True;
         RCC_Periph.APB2RSTR.USART1RST := False;
      elsif This.Periph.all'Address = USART2_Base then
         RCC_Periph.APB1RSTR.USART2RST := True;
         RCC_Periph.APB1RSTR.USART2RST := False;
      elsif This.Periph.all'Address = USART3_Base then
         RCC_Periph.APB1RSTR.USART3RST := True;
         RCC_Periph.APB1RSTR.USART3RST := False;
      elsif This.Periph.all'Address = USART4_Base then
         RCC_Periph.APB1RSTR.USART4RST := True;
         RCC_Periph.APB1RSTR.USART4RST := False;
      else
         raise Unknown_Device;
      end if;
   end Reset;

   ------------------------------
   -- System_Clock_Frequencies --
   ------------------------------

   function System_Clock_Frequencies return RCC_System_Clocks is
      Source : constant UInt2 := RCC_Periph.CFGR.SWS;
      Result : RCC_System_Clocks;
   begin

      case Source is
         when 0 =>
            --  HSI as source
            Result.SYSCLK := HSI_VALUE;

         when 1 =>
            --  HSE as source
            Result.SYSCLK := HSE_VALUE;

         when 2 =>
            --  PLL as source
            declare
               Input_Source : constant Uint2 := RCC_Periph.CFGR.PLLSRC;
               Prediv       : constant UInt32 :=
                 UInt32 (RCC_Periph.CFGR2.PREDIV);
               Pllmul       : constant UInt32 :=
                 UInt32 (RCC_Periph.CFGR.PLLMUL);
               Pllval       : UInt32 := HSI_VALUE;
            begin
               case Input_Source is
                  when 0 =>
                     Pllval := HSI_VALUE / 2;

                  when 1 =>
                     Pllval := HSI_VALUE / Prediv;

                  when 2 =>
                     Pllval := HSE_VALUE / Prediv;

                  when 3 =>
                     Pllval := HSI48_VALUE / Prediv;
               end case;

               Pllval := Pllval * Pllmul;

               Result.SYSCLK := Pllval;
            end;

         when 3 =>
            Result.SYSCLK := HSI48_VALUE;
      end case;

      declare
         HPRE : constant UInt4 := RCC_Periph.CFGR.HPRE;
         PPRE : constant UInt3 := RCC_Periph.CFGR.PPRE;
      begin
         Result.HCLK := Result.SYSCLK / HPRE_Presc_Table (HPRE);
         Result.PCLK := Result.HCLK / PPRE_Presc_Table (PPRE);
      end;

      return Result;
   end System_Clock_Frequencies;

   procedure Enable_Clock (This : in out Timer) is
   begin
      if This'Address = TIM1_Base then
         RCC_Periph.APB2ENR.TIM1EN := True;
      -- Commented out GE
      --  elsif This'Address = TIM2_Base then
      --     RCC_Periph.APB1ENR.TIM2EN := True;
      elsif This'Address = TIM3_Base then
         RCC_Periph.APB1ENR.TIM3EN := True;

      elsif This'Address = TIM14_Base then
         RCC_Periph.APB1ENR.TIM14EN := True;
      elsif This'Address = TIM15_Base then
         RCC_Periph.APB2ENR.TIM15EN := True;
      elsif This'Address = TIM16_Base then
         RCC_Periph.APB2ENR.TIM16EN := True;
      elsif This'Address = TIM17_Base then
         RCC_Periph.APB2ENR.TIM17EN := True;

      elsif This'Address = TIM6_Base then
         RCC_Periph.APB1ENR.TIM6EN := True;
      elsif This'Address = TIM7_Base then
         RCC_Periph.APB1ENR.TIM7EN := True;

      else
         raise Unknown_Device;
      end if;
   end Enable_Clock;

   -----------
   -- Reset --
   -----------

   procedure Reset (This : in out Timer) is
   begin
      if This'Address = TIM1_Base then
         RCC_Periph.APB2RSTR.TIM1RST := True;
         RCC_Periph.APB2RSTR.TIM1RST := False;
      -- Commented Out GE
      --  elsif This'Address = TIM2_Base then
      --     RCC_Periph.APB1RSTR.TIM2RST := True;
      --     RCC_Periph.APB1RSTR.TIM2RST := False;
      elsif This'Address = TIM3_Base then
         RCC_Periph.APB1RSTR.TIM3RST := True;
         RCC_Periph.APB1RSTR.TIM3RST := False;

      elsif This'Address = TIM14_Base then
         RCC_Periph.APB1RSTR.TIM14RST := True;
         RCC_Periph.APB1RSTR.TIM14RST := False;
      elsif This'Address = TIM15_Base then
         RCC_Periph.APB2RSTR.TIM15RST := True;
         RCC_Periph.APB2RSTR.TIM15RST := False;
      elsif This'Address = TIM16_Base then
         RCC_Periph.APB2RSTR.TIM16RST := True;
         RCC_Periph.APB2RSTR.TIM16RST := False;
      elsif This'Address = TIM17_Base then
         RCC_Periph.APB2RSTR.TIM17RST := True;
         RCC_Periph.APB2RSTR.TIM17RST := False;

      elsif This'Address = TIM6_Base then
         RCC_Periph.APB1RSTR.TIM6RST := True;
         RCC_Periph.APB1RSTR.TIM6RST := False;
      elsif This'Address = TIM7_Base then
         RCC_Periph.APB1RSTR.TIM7RST := True;
         RCC_Periph.APB1RSTR.TIM7RST := False;

      else
         raise Unknown_Device;
      end if;
   end Reset;
end STM32.Device;
