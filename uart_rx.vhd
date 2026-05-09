-- uart_rx.vhd: UART controller - receiving (RX) side
-- Author(s): Tomas Kolarik (xkolart01)

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;



-- Entity declaration (DO NOT ALTER THIS PART!)
entity UART_RX is
    port(
        CLK      : in std_logic;
        RST      : in std_logic;
        DIN      : in std_logic;
        DOUT     : out std_logic_vector(7 downto 0);
        DOUT_VLD : out std_logic
    );
end entity;



-- Architecture implementation (INSERT YOUR IMPLEMENTATION HERE)
architecture behavioral of UART_RX is

    -- Shift register output for DOUT (8 bits)
    signal shift_reg : std_logic_vector(7 downto 0);
    -- Clock pulse counter (from 0 to 15)
    signal clk_cnt : std_logic_vector(3 downto 0);
    -- Received Bit counter (from 0 to 8)
    signal bit_cnt : std_logic_vector(3 downto 0);
    -- Signal for pushing a bit from DIN to the shift register
    signal shift_en : std_logic;
    -- Reset signal for the clock counter driven by the FSM
    signal clk_rst : std_logic;
    -- Reset signal for the bit counter driven by the FSM
    signal bit_rst : std_logic;

begin

    shift_register: process(CLK, RST)
    begin
        if RST = '1' then
            shift_reg <= (others => '0');
        elsif rising_edge(CLK) then
            if shift_en = '1' then
                shift_reg <= DIN & shift_reg(7 downto 1); -- UART sends LSB first; after 8 shifts DOUT keeps the normal bit order
            end if;
        end if;
    end process;

    clock_counter: process(CLK, RST)
    begin
        if RST = '1' then
            clk_cnt <= (others => '0');
        elsif rising_edge(CLK) then
            if clk_rst = '1' then
                clk_cnt <= (others => '0');
            else
                clk_cnt <= clk_cnt + 1;
            end if;
        end if;
    end process;

    bit_counter: process(CLK, RST)
    begin
        if RST = '1' then
            bit_cnt <= (others => '0');
        elsif rising_edge(CLK) then
            if bit_rst = '1' then
                bit_cnt <= (others => '0');
            elsif shift_en = '1' then
                bit_cnt <= bit_cnt + 1; -- Increment only when the FSM samples a data bit
            end if;
        end if;
    end process;

    -- Instance of RX FSM
    fsm: entity work.UART_RX_FSM
    port map (
        CLK => CLK,
        RST => RST,
        DIN => DIN,
        CLK_CNT => clk_cnt,
        BIT_CNT => bit_cnt,

        CLK_RST => clk_rst,
        BIT_RST => bit_rst,
        SHIFT_EN => shift_en,
        DOUT_VLD => DOUT_VLD
    );

     DOUT <= shift_reg; -- DOUT always corresponds to shift_reg, guaranteed valid when DOUT_VLD is 1
end architecture;
