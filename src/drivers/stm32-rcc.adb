--  SPDX-License-Identifier: BSD-3-Clause

--  Copyright 2022 (C) Marc PoulhiÃ¨s
--  This file has been adapted for the STM32F0 (ARM Cortex M4)
--  Beware that most of this has been reused from Ada Drivers Library
--  (https://github.com/AdaCore/Ada_Drivers_Library) and has been
--  tested (as of this writing) in only one very restricted scenario.

with STM32_SVD.Flash;
with STM32_SVD.PWR; use STM32_SVD.PWR;
with STM32_SVD.Flash;
--  Commented out GE
--  with STM32_SVD.CRS; use STM32_SVD.CRS;

package body STM32.RCC is

   procedure Set_Sys_Clock_Source
     (This : in out Rcc_Cfgr; Source : Sys_Clock_Source) is
   begin
      This.Clock_Source := Source;
   end Set_Sys_Clock_Source;

   --  Commented out GE
   --  procedure Enable_Crs (This : in out Rcc_Cfgr) is
   --  begin
   --     This.Use_Crs := True;
   --  end Enable_Crs;

   procedure Set_Sys_Clock (This : in out Rcc_Cfgr; Freq : Positive) is
   begin
      This.Sysclk := Freq;
   end Set_Sys_Clock;

   procedure Set_P_Clock (This : in out Rcc_Cfgr; Freq : Positive) is
   begin
      This.Pclk := Freq;
   end Set_P_Clock;

   function Get_Freq (Source : Sys_Clock_Source) return Positive is
   begin
      case Source is
         when SCS_HSE =>
            return Hse_Freq;

         when SCS_HSI =>
            return Hsi_Freq;

         when SCS_PLL =>
            null;

         when others  =>
            raise Program_Error;
      end case;
   end Get_Freq;

   procedure Enable_Clock (Source : Sys_Clock_Source) is
   begin
      case Source is
         when SCS_HSI =>
            RCC_Periph.CR.HSION := True;
            while not RCC_Periph.CR.HSIRDY loop
               null;
            end loop;

         when SCS_HSE =>
            -- Enable HSE oscillator
            RCC_Periph.CR.HSEBYP := True;
            RCC_Periph.CR.HSEON := True;
            -- Wait until it is ready
            while not RCC_Periph.CR.HSERDY loop
               null;
            end loop;

         when SCS_PLL =>
            Enable_PLL;

         when others  =>
            raise Program_Error;
      end case;
      RCC_Periph.CFGR.SW := Source;
      while not RCC_Periph.CFGR.SWS = Source loop
         null;
      end loop;
   end Enable_Clock;

   procedure Enable_PLL is
   begin
      STM32_SVD.Flash.Flash_Periph.ACR.LATENCY :=
        2#001#; -- FOR > 24mhz maybe change later
      -- Enable PLL
      RCC_Periph.CR.PLLON := True;
      -- Wait until it is ready
      while not RCC_Periph.CR.PLLRDY loop
         null;
      end loop;
   end Enable_PLL;

   procedure Disable_PLL is
   begin
      -- Disable PLL
      RCC_Periph.CR.PLLON := False;
      -- Confirm it is disabled
      while RCC_Periph.CR.PLLRDY loop
         null;
      end loop;
   end Disable_PLL;

   procedure Set_PLL_Source (Source : PLL_Clock_Source) is
   begin
      if RCC_Periph.CR.PLLON then
         Disable_PLL;
      end if;
      RCC_Periph.CFGR.PLLSRC := Source;
      if not RCC_Periph.CR.PLLON then
         Enable_PLL;
      end if;
   end Set_PLL_Source;

   procedure Set_PLL_Multiplier (Multiplier : PLL_Multipler) is
   begin
      if RCC_Periph.CR.PLLON then
         Disable_PLL;
      end if;
      case Multiplier is
         when 2      =>
            RCC_Periph.CFGR.PLLMUL := 2#0000#;

         when 3      =>
            RCC_Periph.CFGR.PLLMUL := 2#0001#;

         when 4      =>
            RCC_Periph.CFGR.PLLMUL := 2#0010#;

         when 5      =>
            RCC_Periph.CFGR.PLLMUL := 2#0011#;

         when 6      =>
            RCC_Periph.CFGR.PLLMUL := 2#0100#;

         when 7      =>
            RCC_Periph.CFGR.PLLMUL := 2#0101#;

         when 8      =>
            RCC_Periph.CFGR.PLLMUL := 2#0110#;

         when 9      =>
            RCC_Periph.CFGR.PLLMUL := 2#0111#;

         when 10     =>
            RCC_Periph.CFGR.PLLMUL := 2#1000#;

         when 11     =>
            RCC_Periph.CFGR.PLLMUL := 2#1001#;

         when 12     =>
            RCC_Periph.CFGR.PLLMUL := 2#1010#;

         when 13     =>
            RCC_Periph.CFGR.PLLMUL := 2#1011#;

         when 14     =>
            RCC_Periph.CFGR.PLLMUL := 2#1100#;

         when 15     =>
            RCC_Periph.CFGR.PLLMUL := 2#1101#;

         when 16     =>
            RCC_Periph.CFGR.PLLMUL := 2#1111#;

         when others =>
            RCC_Periph.CFGR.PLLMUL := 2#0000#;
      end case;
      if not RCC_Periph.CR.PLLON then
         Enable_PLL;
      end if;
   end Set_PLL_Multiplier;

   procedure Set_PLL_Divider (Divider : PLL_Divider) is
   begin
      if RCC_Periph.CR.PLLON then
         Disable_PLL;
      end if;
      case Divider is
         when 1  =>
            RCC_Periph.CFGR2.PREDIV := 2#0000#;

         when 2  =>
            RCC_Periph.CFGR2.PREDIV := 2#0001#;

         when 3  =>
            RCC_Periph.CFGR2.PREDIV := 2#0010#;

         when 4  =>
            RCC_Periph.CFGR2.PREDIV := 2#0011#;

         when 5  =>
            RCC_Periph.CFGR2.PREDIV := 2#0100#;

         when 6  =>
            RCC_Periph.CFGR2.PREDIV := 2#0101#;

         when 7  =>
            RCC_Periph.CFGR2.PREDIV := 2#0110#;

         when 8  =>
            RCC_Periph.CFGR2.PREDIV := 2#0111#;

         when 9  =>
            RCC_Periph.CFGR2.PREDIV := 2#1000#;

         when 10 =>
            RCC_Periph.CFGR2.PREDIV := 2#1001#;

         when 11 =>
            RCC_Periph.CFGR2.PREDIV := 2#1010#;

         when 12 =>
            RCC_Periph.CFGR2.PREDIV := 2#1011#;

         when 13 =>
            RCC_Periph.CFGR2.PREDIV := 2#1100#;

         when 14 =>
            RCC_Periph.CFGR2.PREDIV := 2#1101#;

         when 15 =>
            RCC_Periph.CFGR2.PREDIV := 2#1110#;

         when 16 =>
            RCC_Periph.CFGR2.PREDIV := 2#1111#;
      end case;
      if not RCC_Periph.CR.PLLON then
         Enable_PLL;
      end if;
   end Set_PLL_Divider;

end STM32.RCC;
