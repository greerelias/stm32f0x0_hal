pragma Style_Checks (Off);

--  This spec has been automatically generated from STM32F0x0.svd

pragma Restrictions (No_Elaboration_Code);

with System;

--  STM32F0x0

package STM32_SVD is
   pragma Preelaborate;

   --------------------
   -- Base addresses --
   --------------------

   CRC_Base    : constant System.Address := System'To_Address (16#40023000#);
   GPIOF_Base  : constant System.Address := System'To_Address (16#48001400#);
   GPIOD_Base  : constant System.Address := System'To_Address (16#48000C00#);
   GPIOC_Base  : constant System.Address := System'To_Address (16#48000800#);
   GPIOB_Base  : constant System.Address := System'To_Address (16#48000400#);
   GPIOA_Base  : constant System.Address := System'To_Address (16#48000000#);
   SPI1_Base   : constant System.Address := System'To_Address (16#40013000#);
   SPI2_Base   : constant System.Address := System'To_Address (16#40003800#);
   PWR_Base    : constant System.Address := System'To_Address (16#40007000#);
   I2C1_Base   : constant System.Address := System'To_Address (16#40005400#);
   I2C2_Base   : constant System.Address := System'To_Address (16#40005800#);
   IWDG_Base   : constant System.Address := System'To_Address (16#40003000#);
   WWDG_Base   : constant System.Address := System'To_Address (16#40002C00#);
   TIM1_Base   : constant System.Address := System'To_Address (16#40012C00#);
   TIM2_Base   : constant System.Address :=
     System'To_Address
       (16#40012C00#); -- Commented: 11/4/25. Declaring variable so alr build works
   TIM3_Base   : constant System.Address := System'To_Address (16#40000400#);
   TIM14_Base  : constant System.Address := System'To_Address (16#40002000#);
   TIM6_Base   : constant System.Address := System'To_Address (16#40001000#);
   TIM7_Base   : constant System.Address := System'To_Address (16#40001400#);
   EXTI_Base   : constant System.Address := System'To_Address (16#40010400#);
   NVIC_Base   : constant System.Address := System'To_Address (16#E000E100#);
   DMA1_Base   : constant System.Address := System'To_Address (16#40020000#);
   RCC_Base    : constant System.Address := System'To_Address (16#40021000#);
   SYSCFG_Base : constant System.Address := System'To_Address (16#40010000#);
   ADC_Base    : constant System.Address := System'To_Address (16#40012400#);
   USART1_Base : constant System.Address := System'To_Address (16#40013800#);
   USART2_Base : constant System.Address := System'To_Address (16#40004400#);
   USART3_Base : constant System.Address := System'To_Address (16#40004800#);
   USART4_Base : constant System.Address := System'To_Address (16#40004C00#);
   USART6_Base : constant System.Address := System'To_Address (16#40011400#);
   USART5_Base : constant System.Address := System'To_Address (16#40005000#);
   RTC_Base    : constant System.Address := System'To_Address (16#40002800#);
   TIM15_Base  : constant System.Address := System'To_Address (16#40014000#);
   TIM16_Base  : constant System.Address := System'To_Address (16#40014400#);
   TIM17_Base  : constant System.Address := System'To_Address (16#40014800#);
   Flash_Base  : constant System.Address := System'To_Address (16#40022000#);
   DBGMCU_Base : constant System.Address := System'To_Address (16#40015800#);
   USB_Base    : constant System.Address := System'To_Address (16#40005C00#);
   SCB_Base    : constant System.Address := System'To_Address (16#E000ED00#);
   STK_Base    : constant System.Address := System'To_Address (16#E000E010#);

end STM32_SVD;
