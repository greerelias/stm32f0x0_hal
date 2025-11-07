	.syntax unified

#if defined(__SOFTFP__)
	.cpu cortex-m0
#else
        /* FPU support means at least cortex-m4 compatibility */
        .cpu cortex-m4
#endif

        .thumb

	.text
	.globl __vectors
	.p2align 9
	.section .vectors,"a"
__vectors:
	/* Cortex-M core interrupts */
	.word   __stack_end              /* stack top address */
	.word   Reset_Handler            /* 1 Reset */
	.word   NMI_Handler              /* 2 NMI. */
	.word   HardFault_Handler        /* 3 Hard fault. */
	.word   MemoryManagement_Handler /* 4 Mem manage. */
	.word   BusFault_Handler         /* 5 Bus fault. */
	.word   UsageFault_Handler       /* 6 Usage fault. */
	.word   Reserved_Handler         /* 7 reserved. */
	.word   Reserved_Handler         /* 8 reserved. */
	.word   Reserved_Handler         /* 9 reserved. */
	.word   Reserved_Handler         /* 10 reserved. */
	.word   SVC_Handler              /* 11 SVCall. */
	.word   DebugMon_Handler         /* 12 Breakpoint. */
	.word   Reserved_Handler         /* 13 reserved. */
	.word   PendSV_Handler           /* 14 PendSV. */
	.word   SysTick_Handler          /* 15 Systick. */
	/* MCU interrupts */
        .word __wwdg_handler /* 0 */
        .word __pvd_vddio2_handler /* 1 */
        .word __rtc_handler /* 2 */
        .word __flash_handler /* 3 */
        .word __rcc_crs_handler /* 4 */
        .word __exti0_1_handler /* 5 */
        .word __exti2_3_handler /* 6 */
        .word __exti4_5_handler /* 7 */
        .word __tsc_handler /* 8 */
        .word __dma_ch1_handler /* 9 */
        .word __dma_ch2_3_handler /* 10 */
        .word __dma_ch4_5_6_7_handler /* 11 */
        .word __adc_comp_handler /* 12 */
        .word __tim1_brk_up_handler /* 13 */
        .word __tim1_cc_handler /* 14 */
        .word __tim2_handler /* 15 */
        .word __tim3_handler /* 16 */
        .word __tim6_dac_handler /* 17 */
        .word __tim7_handler /* 18 */
        .word __tim14_handler /* 19 */
        .word __tim15_handler /* 20 */
        .word __tim16_handler /* 21 */
        .word __tim17_handler /* 22 */
        .word __isc1_handler /* 23 */
        .word __isc2_handler /* 24 */
        .word __spi1_handler /* 25 */
        .word __spi2_handler /* 26 */
        .word __usart1_handler /* 27 */
        .word __usart2_handler /* 28 */
        .word __usart3_4_5_6_7_8_handler /* 29 */
        .word __cec_can_handler /* 30 */
        .word __usb_handler /* 31 */

   .weak      __wwdg_handler
   .thumb_set __wwdg_handler,__common_int_handler
   .weak      __pvd_vddio2_handler
   .thumb_set __pvd_vddio2_handler,__common_int_handler
   .weak      __rtc_handler
   .thumb_set __rtc_handler,__common_int_handler
   .weak      __flash_handler
   .thumb_set __flash_handler,__common_int_handler
   .weak      __rcc_crs_handler
   .thumb_set __rcc_crs_handler,__common_int_handler
   .weak      __exti0_1_handler
   .thumb_set __exti0_1_handler,__common_int_handler
   .weak      __exti2_3_handler
   .thumb_set __exti2_3_handler,__common_int_handler
   .weak      __exti4_5_handler
   .thumb_set __exti4_5_handler,__common_int_handler
   .weak      __tsc_handler
   .thumb_set __tsc_handler,__common_int_handler
   .weak      __dma_ch1_handler
   .thumb_set __dma_ch1_handler,__common_int_handler
   .weak      __dma_ch2_3_handler
   .thumb_set __dma_ch2_3_handler,__common_int_handler
   .weak      __dma_ch4_5_6_7_handler
   .thumb_set __dma_ch4_5_6_7_handler,__common_int_handler
   .weak      __adc_comp_handler
   .thumb_set __adc_comp_handler,__common_int_handler
   .weak      __tim1_brk_up_handler
   .thumb_set __tim1_brk_up_handler,__common_int_handler
   .weak      __tim1_cc_handler
   .thumb_set __tim1_cc_handler,__common_int_handler
   .weak      __tim2_handler
   .thumb_set __tim2_handler,__common_int_handler
   .weak      __tim3_handler
   .thumb_set __tim3_handler,__common_int_handler
   .weak      __tim6_dac_handler
   .thumb_set __tim6_dac_handler,__common_int_handler
   .weak      __tim7_handler
   .thumb_set __tim7_handler,__common_int_handler
   .weak      __tim14_handler
   .thumb_set __tim14_handler,__common_int_handler
   .weak      __tim15_handler
   .thumb_set __tim15_handler,__common_int_handler
   .weak      __tim16_handler
   .thumb_set __tim16_handler,__common_int_handler
   .weak      __tim17_handler
   .thumb_set __tim17_handler,__common_int_handler
   .weak      __isc1_handler
   .thumb_set __isc1_handler,__common_int_handler
   .weak      __isc2_handler
   .thumb_set __isc2_handler,__common_int_handler
   .weak      __spi1_handler
   .thumb_set __spi1_handler,__common_int_handler
   .weak      __spi2_handler
   .thumb_set __spi2_handler,__common_int_handler
   .weak      __usart1_handler
   .thumb_set __usart1_handler,__common_int_handler
   .weak      __usart2_handler
   .thumb_set __usart2_handler,__common_int_handler
   .weak      __usart3_4_5_6_7_8_handler
   .thumb_set __usart3_4_5_6_7_8_handler,__common_int_handler
   .weak      __cec_can_handler
   .thumb_set __cec_can_handler,__common_int_handler
   .weak      __usb_handler
   .thumb_set __usb_handler,__common_int_handler

	.text

   .weak      __unknown_interrupt_handler
   .thumb_set __unknown_interrupt_handler,__common_int_handler

.macro weak_handler name
	.thumb_func
.weak \name
.type \name, %function
\name:
0:	b 0b
	.size \name, . - \name
.endm

weak_handler NMI_Handler
weak_handler HardFault_Handler
weak_handler MemoryManagement_Handler
weak_handler BusFault_Handler
weak_handler UsageFault_Handler
weak_handler Reserved_Handler
weak_handler SVC_Handler
weak_handler DebugMon_Handler
weak_handler PendSV_Handler
weak_handler SysTick_Handler
weak_handler __common_int_handler

        /*********/
        /* .data */
        /*********/
        .section .data.argv
argv_str:
        .ascii  "main\0"

        .align 4
argv:
        .word argv_str
        .word 0

        /*****************/
        /* Reset_Handler */
        /*****************/

	.text
	.thumb_func
	.globl Reset_Handler

Reset_Handler:
	/* ARMv6-M does not initialise LR, but many tools expect it to be 0xFFFF_FFFF
         * when reaching the first call frame, so we set it at startup.
         * ARMv7-M and above initialise LR to 0xFFFF_FFFF at reset. */
        ldr r4,=0xffffffff
        mov lr,r4

	/* Set the stack pointer */
	ldr	r1,=__stack_end
	mov     sp, r1

	/* Copy .data */
	.thumb_func
_startup_copy_data:
	ldr	r0,=__data_start
	ldr	r1,=__data_words
	ldr	r2,=__data_load
	cmp     r1,#0
	beq     1f
0:	ldr	r4,[r2]
	str	r4,[r0]
        adds    r2,#4
        adds    r0,#4
	subs	r1,r1,#1
	bne	0b
1:
        .size _startup_copy_data, . - _startup_copy_data

	/* Clear .bss */
	.thumb_func
_startup_clear_bss:
	ldr	r0,=__bss_start
	ldr	r1,=__bss_words
	movs	r2,#0
	cmp     r1,#0
	beq     1f
0:	str	r2,[r0]
        adds    r0,#4
	subs	r1,r1,#1
	bne	0b
1:
        .size _startup_clear_bss, . - _startup_clear_bss

#if !defined(__SOFTFP__)
        /**************/
        /* Enable FPU */
        /**************/

        movw     r0,#0xED88
        movt     r0,#0xE000
        ldr      r1,[r0]
        orr      r1,r1,#(0xF << 20)
        str      r1,[r0]

        dsb
        isb
#endif

        /* Call static constructors */
.weak __libc_init_array
        ldr     r5,=__libc_init_array
        cmp     r5,#0
        beq     .skip_libc_init
        blx     r5
.skip_libc_init:

        /* Call main, with argc, argv */
        movs    r0,#1
        ldr	r1,=argv
        bl	main

        /* Save main's return value */
        mov r4, r0

        /* static destructors */
.weak __libc_fini_array
        ldr     r5,=__libc_fini_array
        cmp     r5,#0
        beq     .skip_libc_fini
        blx     r5
.skip_libc_fini:

        /* Restore main's return value */
        mov r0, r4

        bl	_exit
        bl	Reset_Handler
	.size Reserved_Handler, . - Reset_Handler