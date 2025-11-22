--  with USB.Device.Serial; use USB.Device.Serial;
--  with STM32.USB_Device;  use STM32.USB_Device;
pragma Extensions_Allowed (On);
with HAL.GPIO;
with STM32.Device;
with STM32.GPIO;            use STM32.GPIO;
with STM32.RCC;             use STM32.RCC;
with STM32.USB_Device;
with STM32_SVD.Flash;
with STM32_SVD.RCC;         use STM32_SVD.RCC;
with USB.Device;            use USB.Device;
with USB.Device.Serial;
with STM32.USB_Serialtrace; use STM32.USB_Serialtrace;

package body USB_Demo is
   Serial :
     aliased USB.Device.Serial.Default_Serial_Class
               (TX_Buffer_Size => 128, RX_Buffer_Size => 128);
   Stack  : aliased USB.Device.USB_Device_Stack (Max_Classes => 1);
   UDC    : aliased STM32.USB_Device.UDC;

   procedure Run is
   begin

      -- Enable syscfg and power clock (not sure if needed)
      RCC_Periph.APB2ENR.SYSCFGEN := True;
      while not RCC_Periph.APB2ENR.SYSCFGEN loop
         null;
      end loop;
      RCC_Periph.APB1ENR.PWREN := True;
      while not RCC_Periph.APB1ENR.PWREN loop
         null;
      end loop;

      -- Set flash latency to 1 wait state for sysclk > 24mhz
      -- Should move this to RCC
      STM32_SVD.Flash.Flash_Periph.ACR.LATENCY := 2#001#;
      Enable_Clock (SCS_HSE);
      Set_PLL_Source (PLL_HSE);
      Set_PLL_Divider (1);
      Set_PLL_Multiplier (6);
      Enable_Clock (SCS_PLL);

      -- Enable GPIOF clock (For external osc, not sure if needed)
      STM32.Device.Enable_Clock (STM32.Device.GPIO_F);
      -- Enable GPIOA clock
      STM32.Device.Enable_Clock (STM32.Device.GPIO_A);

      -- Setup MCO pin to check clock output
      RCC_Periph.CFGR.PLLNODIV := True;
      RCC_Periph.CFGR.MCOPRE := 2#000#;
      RCC_Periph.CFGR.MCO := 2#0111#;
      while not RCC_Periph.CFGR.PLLNODIV loop
         null;
      end loop;
      Configure_IO
        (STM32.Device.PA5,
         Config =>
           (Mode        => Mode_Out,
            Resistors   => Floating,
            Output_Type => Push_Pull,
            Speed       => Speed_High));

      Configure_IO
        (STM32.Device.PA8,
         Config =>
           (Mode           => Mode_AF,
            Resistors      => Floating,
            AF_Output_Type => Push_Pull,
            AF_Speed       => Speed_High,
            AF             => STM32.Device.GPIO_AF_MCO_0));

      -- Setup USB stack
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
         STM32.GPIO.Clear (STM32.Device.PA5);
         if Serial.List_Ctrl_State.DTE_Is_Present then
            -- Reads characters from host serial port.
            -- GTKTerm sends a character as soon as it is typed so this reads one
            -- character at time.
            Serial.Read (Buffer (Integer (Count) .. 128), Length);
            if Length > 0 then
               if Buffer (Integer (Count)) = CR then
                  -- If enter is pressed print buffer to host
                  Serial.Write (UDC, Reply, Reply_Len);
                  Serial.Write (UDC, Buffer (1 .. Integer (Count)), Count);
                  Serial.Write (UDC, New_Line, NL_Len);
                  Count := 1;
               else
                  -- Echo characters typed back to host
                  Serial.Write
                    (UDC, Buffer (Integer (Count) .. Integer (Count)), Length);
                  Count := Count + 1;
               end if;
            end if;
         end if;
         STM32.GPIO.Set (STM32.Device.PA5);
      end loop;
   end Run;
end Usb_Demo;
