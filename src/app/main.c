#include "stm32f4xx.h"

int main(void)
{
    //Включаем тактирование порта GPIOB
    SET_BIT(RCC->AHB1ENR, RCC_AHB1ENR_GPIOBEN);

    //Настраиваем пин PB7 на выход (MODER0 = 01)
    CLEAR_BIT(GPIOB->MODER, GPIO_MODER_MODER7);
    SET_BIT(GPIOB->MODER, GPIO_MODER_MODER7_0);

    //Включаем светодиод на постоянное свечение
    SET_BIT(GPIOB->BSRR, GPIO_BSRR_BS7);

    while (1)
    {
    }
}
