--  with USB.Device.Serial; use USB.Device.Serial;
--  with STM32.USB_Device;  use STM32.USB_Device;
pragma Extensions_Allowed (On);
with HAL.GPIO;
with STM32.Device;
with STM32.GPIO; use STM32.GPIO;
with STM32.RCC;  use STM32.RCC;

procedure Usb_Demo is
begin
   Enable_Clock (SCS_HSE);
   Set_PLL_Source (PLL_HSE);
   Set_PLL_Divider (1);
   Set_PLL_Multiplier (6);
   Enable_Clock (SCS_PLL);

   STM32.Device.Enable_Clock (STM32.Device.GPIO_A);
   STM32.GPIO.Set_Mode (STM32.Device.PA5, HAL.GPIO.Output);

   --  Stack : USB.Device.USB_Device_Stack (Max_Classes => 1);
   --  UDC : aliased STM32.USB_Device.UDC;
   loop
      STM32.GPIO.Set (STM32.Device.PA5);
      STM32.Device.Delay_Cycles (5000000);
      STM32.GPIO.Clear (STM32.Device.PA5);
      STM32.Device.Delay_Cycles (5000000);
      null;
   end loop;
end Usb_Demo;
