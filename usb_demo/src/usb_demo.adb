--  with USB.Device.Serial; use USB.Device.Serial;
--  with STM32.USB_Device;  use STM32.USB_Device;
pragma Extensions_Allowed (On);
with HAL.GPIO;
with STM32.Device;
with STM32.GPIO;
with STM32.RCC;  use STM32.RCC;
with STM32.USB_Device;
with USB.Device; use USB.Device;
with USB.Device.Serial;

package body USB_Demo is
   --  Declare USB components at the library level to ensure they are not
   --  allocated on the stack.
   Serial :
     aliased USB.Device.Serial.Default_Serial_Class
               (TX_Buffer_Size => 128, RX_Buffer_Size => 128);
   Stack  : aliased USB.Device.USB_Device_Stack (Max_Classes => 1);
   UDC    : aliased STM32.USB_Device.UDC;

   procedure Run is
      --  All USB components are now declared at the library level.

   begin
      Enable_Clock (SCS_HSE);
      Set_PLL_Source (PLL_HSE);
      Set_PLL_Divider (1);
      Set_PLL_Multiplier (6);
      Enable_Clock (SCS_PLL);

      STM32.Device.Enable_Clock (STM32.Device.GPIO_A);
      STM32.GPIO.Set_Mode (STM32.Device.PA5, HAL.GPIO.Output);

      if not Stack.Register_Class (Serial'Access) then
         raise Program_Error;
      end if;

      if Stack.Initialize
           (UDC'Access,
            USB.To_USB_String ("Test"),
            USB.To_USB_String ("USB Test"),
            USB.To_USB_String ("USB Test"),
            64)
        /= Ok
      then
         raise Program_Error;
      end if;

      Stack.Start;

      loop
         Stack.Poll;
         STM32.GPIO.Set (STM32.Device.PA5);
         STM32.Device.Delay_Cycles (5000000);
         STM32.GPIO.Clear (STM32.Device.PA5);
         STM32.Device.Delay_Cycles (5000000);
         null;
      end loop;
   end Run;
end Usb_Demo;
