pragma Style_Checks (Off);

--  This spec has been automatically generated from STM32F0x0.svd

pragma Restrictions (No_Elaboration_Code);

with HAL;
with System;

package STM32_SVD.DBGMCU is
   pragma Preelaborate;

   ---------------
   -- Registers --
   ---------------

   subtype IDCODE_DEV_ID_Field is HAL.UInt12;
   subtype IDCODE_DIV_ID_Field is HAL.UInt4;
   subtype IDCODE_REV_ID_Field is HAL.UInt16;

   --  MCU Device ID Code Register
   type IDCODE_Register is record
      --  Read-only. Device Identifier
      DEV_ID : IDCODE_DEV_ID_Field;
      --  Read-only. Division Identifier
      DIV_ID : IDCODE_DIV_ID_Field;
      --  Read-only. Revision Identifier
      REV_ID : IDCODE_REV_ID_Field;
   end record
     with Volatile_Full_Access, Object_Size => 32,
          Bit_Order => System.Low_Order_First;

   for IDCODE_Register use record
      DEV_ID at 0 range 0 .. 11;
      DIV_ID at 0 range 12 .. 15;
      REV_ID at 0 range 16 .. 31;
   end record;

   --  Debug MCU Configuration Register
   type CR_Register is record
      --  unspecified
      Reserved_0_0  : HAL.Bit := 16#0#;
      --  Debug Stop Mode
      DBG_STOP      : Boolean := False;
      --  Debug Standby Mode
      DBG_STANDBY   : Boolean := False;
      --  unspecified
      Reserved_3_31 : HAL.UInt29 := 16#0#;
   end record
     with Volatile_Full_Access, Object_Size => 32,
          Bit_Order => System.Low_Order_First;

   for CR_Register use record
      Reserved_0_0  at 0 range 0 .. 0;
      DBG_STOP      at 0 range 1 .. 1;
      DBG_STANDBY   at 0 range 2 .. 2;
      Reserved_3_31 at 0 range 3 .. 31;
   end record;

   --  Debug MCU APB1 freeze register
   type APB1_FZ_Register is record
      --  unspecified
      Reserved_0_0           : HAL.Bit := 16#0#;
      --  TIM3 counter stopped when core is halted
      DBG_TIM3_STOP          : Boolean := False;
      --  unspecified
      Reserved_2_3           : HAL.UInt2 := 16#0#;
      --  TIM6 counter stopped when core is halted
      DBG_TIM6_STOP          : Boolean := False;
      --  TIM7 counter stopped when core is halted
      DBG_TIM7_STOP          : Boolean := False;
      --  unspecified
      Reserved_6_7           : HAL.UInt2 := 16#0#;
      --  TIM14 counter stopped when core is halted
      DBG_TIM14_STOP         : Boolean := False;
      --  unspecified
      Reserved_9_10          : HAL.UInt2 := 16#0#;
      --  Debug window watchdog stopped when core is halted
      DBG_WWDG_STOP          : Boolean := False;
      --  Debug independent watchdog stopped when core is halted
      DBG_IWDG_STOP          : Boolean := False;
      --  unspecified
      Reserved_13_20         : HAL.UInt8 := 16#0#;
      --  SMBUS timeout mode stopped when core is halted
      DBG_I2C1_SMBUS_TIMEOUT : Boolean := False;
      --  unspecified
      Reserved_22_31         : HAL.UInt10 := 16#0#;
   end record
     with Volatile_Full_Access, Object_Size => 32,
          Bit_Order => System.Low_Order_First;

   for APB1_FZ_Register use record
      Reserved_0_0           at 0 range 0 .. 0;
      DBG_TIM3_STOP          at 0 range 1 .. 1;
      Reserved_2_3           at 0 range 2 .. 3;
      DBG_TIM6_STOP          at 0 range 4 .. 4;
      DBG_TIM7_STOP          at 0 range 5 .. 5;
      Reserved_6_7           at 0 range 6 .. 7;
      DBG_TIM14_STOP         at 0 range 8 .. 8;
      Reserved_9_10          at 0 range 9 .. 10;
      DBG_WWDG_STOP          at 0 range 11 .. 11;
      DBG_IWDG_STOP          at 0 range 12 .. 12;
      Reserved_13_20         at 0 range 13 .. 20;
      DBG_I2C1_SMBUS_TIMEOUT at 0 range 21 .. 21;
      Reserved_22_31         at 0 range 22 .. 31;
   end record;

   --  Debug MCU APB2 freeze register
   type APB2_FZ_Register is record
      --  unspecified
      Reserved_0_10  : HAL.UInt11 := 16#0#;
      --  TIM1 counter stopped when core is halted
      DBG_TIM1_STOP  : Boolean := False;
      --  unspecified
      Reserved_12_15 : HAL.UInt4 := 16#0#;
      --  TIM15 counter stopped when core is halted
      DBG_TIM15_STOP : Boolean := False;
      --  TIM16 counter stopped when core is halted
      DBG_TIM16_STOP : Boolean := False;
      --  TIM17 counter stopped when core is halted
      DBG_TIM17_STOP : Boolean := False;
      --  unspecified
      Reserved_19_31 : HAL.UInt13 := 16#0#;
   end record
     with Volatile_Full_Access, Object_Size => 32,
          Bit_Order => System.Low_Order_First;

   for APB2_FZ_Register use record
      Reserved_0_10  at 0 range 0 .. 10;
      DBG_TIM1_STOP  at 0 range 11 .. 11;
      Reserved_12_15 at 0 range 12 .. 15;
      DBG_TIM15_STOP at 0 range 16 .. 16;
      DBG_TIM16_STOP at 0 range 17 .. 17;
      DBG_TIM17_STOP at 0 range 18 .. 18;
      Reserved_19_31 at 0 range 19 .. 31;
   end record;

   -----------------
   -- Peripherals --
   -----------------

   --  Debug support
   type DBGMCU_Peripheral is record
      --  MCU Device ID Code Register
      IDCODE  : aliased IDCODE_Register;
      --  Debug MCU Configuration Register
      CR      : aliased CR_Register;
      --  Debug MCU APB1 freeze register
      APB1_FZ : aliased APB1_FZ_Register;
      --  Debug MCU APB2 freeze register
      APB2_FZ : aliased APB2_FZ_Register;
   end record
     with Volatile;

   for DBGMCU_Peripheral use record
      IDCODE  at 16#0# range 0 .. 31;
      CR      at 16#4# range 0 .. 31;
      APB1_FZ at 16#8# range 0 .. 31;
      APB2_FZ at 16#C# range 0 .. 31;
   end record;

   --  Debug support
   DBGMCU_Periph : aliased DBGMCU_Peripheral
     with Import, Address => DBGMCU_Base;

end STM32_SVD.DBGMCU;
