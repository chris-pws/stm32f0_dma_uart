#include "uart.h"
#define PORT_LED GPIOA
#define PIN_LED GPIO5

int main(void)
{

	volatile int i;

	rcc_init();
	gpio_init();
	nvic_init();
	uart_init();
	dma_init();

	while (1) {

		gpio_toggle(PORT_LED, PIN_LED);	/* LED on/off */
		for (i=0; i<1000000; i++);
		//usart_send_blocking(USART2, 'D');
		uart_send("Hello World!", 12);

	}

	return 0;
}