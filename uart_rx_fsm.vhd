-- uart_rx_fsm.vhd: UART controller - finite state machine controlling RX side
-- Author(s): Tomas Kolarik (xkolart01)

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;



entity UART_RX_FSM is
    port(
       CLK : in std_logic;
       RST : in std_logic;
       DIN : in std_logic;
       -- CLK_CNT ... Clock pulse counter (from 0 to 15)
       CLK_CNT : in std_logic_vector(3 downto 0);
       -- BIT_CNT ... Received bit counter (from 0 to 8)
       BIT_CNT : in std_logic_vector(3 downto 0);

       -- CLK_RST ... Clock pulse counter reset signal
       CLK_RST : out std_logic;
       -- BIT_RST ... RX'd bit counter reset signal
       BIT_RST : out std_logic;
       -- SHIFT_EN ... Add bit pulse for shift register
       SHIFT_EN : out std_logic;

       DOUT_VLD : out std_logic
    );
end entity;



architecture behavioral of UART_RX_FSM is

    type t_state is (IDLE, START, DATA, STOP);
    signal state : t_state;
    signal next_state : t_state;

begin

    state_register: process(CLK, RST)
    begin
        if RST = '1' then
            state <= IDLE;
        elsif rising_edge(CLK) then
            state <= next_state;
        end if;
    end process;

    next_state_logic: process(state, DIN, CLK_CNT, BIT_CNT)
    begin
        next_state <= state;

        case state is
            when IDLE =>
                if DIN = '0' then -- START BIT
                    next_state <= START;
                end if;
            when START =>
                if CLK_CNT = "0111" then -- CLK_CNT = 7 ... we're in the middle of the start bit
                    next_state <= DATA;
                end if;
            when DATA =>
                if BIT_CNT = "1000" then -- BIT_CNT = 8 ... BYTE successfully serialized
                    next_state <= STOP;
                end if;
            when STOP =>
                if CLK_CNT = "1111" then -- CLK_CNT = 15 ... return to idle
                    next_state <= IDLE;
                end if;
            when others =>
                next_state <= IDLE;
        end case;
    end process;

    output_logic: process(state, DIN, CLK_CNT, BIT_CNT)
    begin
        CLK_RST <= '0';
        BIT_RST <= '0';
        SHIFT_EN <= '0';
        DOUT_VLD <= '0';

        case state is
            when IDLE =>
                if DIN = '0' then -- Transmission start, reset CLK_CNT and BIT_CNT
                    CLK_RST <= '1';
                    BIT_RST <= '1';
                end if;
            when START =>
                if CLK_CNT = "0111" then -- DATA transition? Reset CLK_CNT
                    CLK_RST <= '1';
                end if;
            when DATA =>
                if CLK_CNT = "1111" then -- BIT read? Reset CLK_CNT and PUSH bit onto shift register
                    CLK_RST <= '1';
                    SHIFT_EN <= '1';
                elsif BIT_CNT = "1000" then -- All bits read? Transition to STOP, reset BIT_CNT and send DOUT_VLD
                    BIT_RST <= '1';
                    DOUT_VLD <= '1';
                end if;
            when STOP =>
                if CLK_CNT = "1111" then -- IDLE transition? Reset CLK_CNT
                    CLK_RST <= '1';
                end if;
            when others =>
                -- Do nothing, covered by default outputs above
                null;
        end case;
    end process;

end architecture;
