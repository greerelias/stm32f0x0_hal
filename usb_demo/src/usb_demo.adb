--  with USB.Device.Serial; use USB.Device.Serial;
--  with STM32.USB_Device;  use STM32.USB_Device;
pragma Extensions_Allowed (On);
with HAL;                     use HAL;
with HAL.GPIO;
with STM32.Device;
with STM32.GPIO;              use STM32.GPIO;
with STM32.RCC;               use STM32.RCC;
with STM32.USB_Device;
with STM32_SVD.Flash;
with STM32_SVD.RCC;           use STM32_SVD.RCC;
with USB.Device;              use USB.Device;
with USB.Device.Serial;
with STM32.USB_Serialtrace;   use STM32.USB_Serialtrace;
with Packet_Formatting;       use Packet_Formatting;
with Protocol;                use Protocol;
with Commands;                use Commands;
with System;                  use System;
with System.Storage_Elements; use System.Storage_Elements;
with STM32.USB_Serialtrace;   use STM32.USB_Serialtrace;
with Cortex_M.NVIC;           use Cortex_M.NVIC;

package body USB_Demo is
   Serial          :
     aliased USB.Device.Serial.Default_Serial_Class
               (TX_Buffer_Size => 128, RX_Buffer_Size => 128);
   Stack           : aliased USB.Device.USB_Device_Stack (Max_Classes => 1);
   UDC             : aliased STM32.USB_Device.UDC;
   DTE_Connected   : Boolean := False;
   Connection_Test : Boolean := False;
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
            USB.To_USB_String ("Ada Baremetal Programmer"),
            USB.To_USB_String ("AdaCore/Team 27"),
            USB.To_USB_String ("0001"),
            64)
        /= Ok
      then
         raise Program_Error;
      end if;

      Stack.Start;

      Enable_Interrupt (31);
      loop
         STM32.GPIO.Set (STM32.Device.PA5);
         STM32.GPIO.Clear (STM32.Device.PA5);
      end loop;
   end Run;
   procedure USB_ISR_Handler is
   begin
      Stack.Poll;
      if Serial.List_Ctrl_State.DTE_Is_Present then
         Length := Buffer'Length;
         Serial.Read (Buffer'Address, Length);
         Stack.Poll;
         if Length > 0 then
            if Connection_Test then
               declare
                  Reply_Length : UInt32 := Length;
               begin
                  if Buffer (Integer (Length)) = 0
                    and then Buffer (3) = UInt8 (Data_Packet) --hack fix later
                  then
                     Reply := Buffer;
                     Serial.Read (Buffer'Address, Length);
                     Stack.Poll;
                     Serial.Write (UDC, Reply'Address, Reply_Length);
                  elsif Buffer (3) = UInt8 (End_Test) then
                     Connection_Test := False;
                  end if;
               end;
            else
               -- Length = bytes read
               declare
                  Decoded_Packet : constant UInt8_Array :=
                    Protocol.Decode (Buffer (1 .. Integer (Length - 1)));
               begin
                  if Decoded_Packet'Length <= Packet'Length then
                     Packet (1 .. Decoded_Packet'Length) := Decoded_Packet;
                  end if;

                  if Is_Valid (Decoded_Packet) then
                     case Get_Command (Decoded_Packet) is
                        when Get_Info        =>
                           declare
                              Encoded   : constant UInt8_Array :=
                                Encode (Device_Info);
                              Write_Len : UInt32 :=
                                UInt32 (Encoded'Length) + 1;
                           begin
                              Reply (1 .. Encoded'Length) := Encoded;
                              Reply (Encoded'Length + 1) := 0;
                              Serial.Read (Buffer'Address, Length);
                              Stack.Poll;
                              Serial.Write (UDC, Reply'Address, Write_Len);
                           end;

                        when Test_Connection =>
                           declare
                              Ready_Packet : constant Uint8_Array :=
                                Make_Packet (Ready, (1 .. 0 => 0));
                              Encoded      : constant UInt8_Array :=
                                Encode (Ready_Packet);
                              Write_Len    : UInt32 :=
                                UInt32 (Encoded'Length) + 1;
                           begin
                              Reply (1 .. Encoded'Length) := Encoded;
                              Reply (Encoded'Length + 1) := 0;
                              Serial.Read (Buffer'Address, Length);
                              Stack.Poll;
                              Serial.Write (UDC, Reply'Address, Write_Len);
                              Connection_Test := True;
                           end;

                        when Data_Packet     =>
                           null;

                        when others          =>
                           null;
                     end case;
                  end if;
               end;
            end if;
         end if;
      end if;
   -- Led does not turn back on if device crashes
   end USB_ISR_Handler;


end Usb_Demo;
