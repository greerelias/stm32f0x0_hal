--  SPDX-License-Identifier: BSD-3-Clause

--  Copyright 2022 (C) Marc PoulhiÃ¨s
--  This file has been adapted for the STM32F0 (ARM Cortex M4)
--  Beware that most of this has been reused from Ada Drivers Library
--  (https://github.com/AdaCore/Ada_Drivers_Library) and has been
--  tested (as of this writing) in only one very restricted scenario.
with STM32_SVD.RCC; use STM32_SVD.RCC;


package STM32.RCC is
   subtype Sys_Clock_Source is CFGR_SW_Field;
   SCS_HSI   : constant Sys_Clock_Source := 2#00#; -- HSI/2
   SCS_HSE   : constant Sys_Clock_Source := 2#01#; -- HSI/Prediv
   SCS_PLL   : constant Sys_Clock_Source := 2#10#; -- HSE/Prediv
   subtype PLL_Clock_Source is CFGR_PLLSRC_Field;
   PLL_HSI_2 : PLL_Clock_Source := 2#00#; -- HSI/2
   PLL_HSI   : PLL_Clock_Source := 2#01#; -- HSI/Prediv
   PLL_HSE   : PLL_Clock_Source := 2#10#; -- HSE/Prediv

   type PLL_Multipler is range 2 .. 16;
   type PLL_Divider is range 1 .. 16;
   HSI_Freq   : constant Positive := 8_000_000;
   HSI48_Freq : constant Positive := 48_000_000;
   HSE_Freq   : constant Positive := 8_000_000;

   type Rcc_Cfgr is record
      Hclk          : Natural := 0;
      Pclk          : Natural := 0;
      Sysclk        : Natural := 0;
      Clock_Source  : Sys_Clock_Source := SCS_HSE;
      PLL_Multipler : Integer := 1;
      PLL_Divider   : Integer := 1;
   end record;

   procedure Set_Sys_Clock_Source
     (This : in out Rcc_Cfgr; Source : Sys_Clock_Source);
   -- Commented out GE
   --  procedure Enable_Crs (This : in out Rcc_Cfgr);
   procedure Set_Sys_Clock (This : in out Rcc_Cfgr; Freq : Positive);
   procedure Set_P_Clock (This : in out Rcc_Cfgr; Freq : Positive);
   procedure Enable_Clock (Source : Sys_Clock_Source);
   procedure Enable_PLL;
   procedure Disable_PLL;
   procedure Set_PLL_Source (Source : CFGR_PLLSRC_FIELD);
   procedure Set_PLL_Multiplier (Multiplier : PLL_Multipler);
   procedure Set_PLL_Divider (Divider : PLL_Divider);

end STM32.RCC;
