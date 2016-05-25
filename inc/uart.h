#ifndef UART_H
#include <libopencm3/stm32/usart.h>
#include <libopencm3/stm32/gpio.h>
#include <libopencm3/stm32/rcc.h>
#include <libopencm3/stm32/dma.h>
#include <libopencm3/stm32/f0/nvic.h>

//void uart_receive(volatile void* data, int length);
void uart_send(volatile void* data, int length);
void rcc_init(void);
void gpio_init(void);
void uart_init(void);
void dma_init(void);

#define UART_H
#endif