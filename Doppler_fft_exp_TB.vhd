----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 14.08.2024 16:17:39
-- Design Name: 
-- Module Name: Doppler_fft_exp_TB - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Doppler_fft_exp_TB is
--  Port ( );
end Doppler_fft_exp_TB;

architecture Behavioral of Doppler_fft_exp_TB is

    component Doppler_fft_exp_TOP is
    generic( 
        TIM_GEN_PCOUNT    : integer;                               -- Pulse Count Width
        TIM_GEN_RCOUNT    : integer;                               -- Range Count Width
        DATABUS_WIDTH     : integer;
        CONFIG_DATA       : std_logic_vector(15 downto 0);         -- RAM Data Width 
        DOPPLR_FFT        : integer                                -- Config data for FFT IP                    
        );
    Port ( 
        clock             : in STD_LOGIC;
        reset             : in STD_LOGIC
        );
    end component;
    
    constant TIM_GEN_PCOUNT    : integer                       :=  12;                               -- Pulse Count Width
    constant TIM_GEN_RCOUNT    : integer                       :=  12;                               -- Range Count Width
    constant DATABUS_WIDTH     : integer                       :=  16;
    constant CONFIG_DATA       : std_logic_vector(15 downto 0) :=  "0000001101010101";               -- RAM Data Width 
    constant DOPPLR_FFT        : integer                       :=  512;                              -- Config data for FFT IP 
    
    signal clock, reset : std_logic := '0';

begin

    clock        <= not clock  after 1.6666666655ns;
    reset        <= '1', '0'   after 500ns;

    DUT : Doppler_fft_exp_TOP
        generic map(
            TIM_GEN_PCOUNT => TIM_GEN_PCOUNT,
            TIM_GEN_RCOUNT => TIM_GEN_RCOUNT,
            DATABUS_WIDTH  => DATABUS_WIDTH,
            CONFIG_DATA    => CONFIG_DATA,
            DOPPLR_FFT     => DOPPLR_FFT       
        )
        port map(
            clock          => clock,
            reset          => reset
        );

end Behavioral;
