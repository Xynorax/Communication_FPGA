// --- FCR: FIFO Control Register (Address 2, Write-Only) ---
`define FCR_ENA         0      // FIFO Enable
`define FCR_RX_RST      1      // Receiver FIFO Reset (Self-clearing)
`define FCR_TX_RST      2      // Transmitter FIFO Reset (Self-clearing)
`define FCR_DMA_MODE    3      // DMA Mode Select
`define FCR_RX_TRIG     7:6    // RX FIFO Trigger Level (Threshold)

// --- LCR: Line Control Register (Address 3, Read/Write) ---
`define LCR_WLS         1:0    // Word Length Select (5, 6, 7, or 8 bits)
`define LCR_STB         2      // Number of Stop Bits (1, 2 / 1.5 if WLS is 5 bits)
`define LCR_PEN         3      // Enables parity generation
`define LCR_EPS         4      // Odd or even parity
`define LCR_STICK       5      // Forces parity to a certain value
`define LCR_BREAK       6      // Forces TX line to 0 to signal a break
`define LCR_DLAB        7      // Divisor Latch Access Bit, set to 1 to access Baud rate registers

// --- LSR: Line Status Register (Address 5, Read-Only) ---
`define LSR_DR          0      // Data Ready
`define LSR_OE          1      // Overrun Error
`define LSR_PE          2      // Parity Error
`define LSR_FE          3      // Framing Error
`define LSR_BI          4      // Break Interrupt
`define LSR_THRE        5      // Transmitter Holding Register Empty
`define LSR_TEMT        6      // Transmitter Empty (FIFO + Shift Reg)
`define LSR_RXFE        7      // Error in Receiver FIFO