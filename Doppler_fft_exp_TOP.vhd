----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 14.08.2024 14:04:21
-- Design Name: 
-- Module Name: Doppler_fft_exp_TOP - Behavioral
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
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.std_logic_unsigned.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity Doppler_fft_exp_TOP is
    generic( 
        TIM_GEN_PCOUNT    : integer                       :=  12;                               -- Pulse Count Width
        TIM_GEN_RCOUNT    : integer                       :=  12;                               -- Range Count Width
        DATABUS_WIDTH     : integer                       :=  16;
        CONFIG_DATA       : std_logic_vector(15 downto 0) :=  "0000001101010101";               -- RAM Data Width 
        DOPPLR_FFT        : integer                       :=  512                               -- Config data for FFT IP                    
        );
    Port ( 
        clk_125_p         : in  STD_LOGIC;
        clk_125_n         : in  STD_LOGIC;
        reset             : in  STD_LOGIC;
        mag_out           : out STD_LOGIC_VECTOR((DATABUS_WIDTH   - 1) DOWNTO 0)
        );
end Doppler_fft_exp_TOP;

architecture Behavioral of Doppler_fft_exp_TOP is

    component clk_wiz_0
        port (   
            clk_out1          : out  std_logic;
            -- Status and control signals
            reset             : in   std_logic;
            locked            : out  std_logic;
            clk_in1_p         : in   std_logic;   
            clk_in1_n         : in   std_logic
        );
    end component;
    
    COMPONENT vio_0
        PORT (
            clk        : IN  STD_LOGIC;
            probe_out0 : OUT STD_LOGIC_VECTOR(7 DOWNTO 0) 
        );
    END COMPONENT;

    COMPONENT LUT_Rom
        PORT (
            clka  : IN  STD_LOGIC;
            ena   : IN  STD_LOGIC;
            addra : IN  STD_LOGIC_VECTOR(8  DOWNTO 0);
            douta : OUT STD_LOGIC_VECTOR(31 DOWNTO 0) 
        );
    END COMPONENT;

    COMPONENT  doppler_fft is
        generic(
            TIM_GEN_PCOUNT      : integer;
            DATABUS_WIDTH       : integer;
            CONFIG_DATA         : STD_LOGIC_VECTOR(15 DOWNTO 0);
            DOPPLR_FFT          : integer    
        ); 
        Port( 
            clk                 : in  STD_LOGIC;            
            rst                 : in  STD_LOGIC;
            PulseCountMax       : in  STD_LOGIC_VECTOR((TIM_GEN_PCOUNT - 1) DOWNTO 0);      
            win_out_I           : in  STD_LOGIC_VECTOR((DATABUS_WIDTH  - 1) DOWNTO 0);                  
            win_out_Q           : in  STD_LOGIC_VECTOR((DATABUS_WIDTH  - 1) DOWNTO 0);
            win_valid           : in  STD_LOGIC;
            doppler_fft_out     : out STD_LOGIC_VECTOR((2*DATABUS_WIDTH - 1) DOWNTO 0);
            doppler_fft_valid   : out STD_LOGIC;
            doppler_fft_cpi     : out STD_LOGIC
        );
    END COMPONENT;

    COMPONENT  magnituder is
        generic(
            DATABUS_WIDTH       : integer;  
            TIM_GEN_PCOUNT      : integer;
            TIM_GEN_RCOUNT      : integer
        );
        port(
            clk                 : in  STD_LOGIC;        
            rst                 : in  STD_LOGIC; 
            dfft_out            : in  STD_LOGIC_VECTOR((2*DATABUS_WIDTH - 1) DOWNTO 0);
            dfft_valid          : in  STD_LOGIC;
            PulseCountMax       : in  STD_LOGIC_VECTOR((TIM_GEN_PCOUNT  - 1) DOWNTO 0);
            RangeCountMax       : in  STD_LOGIC_VECTOR((TIM_GEN_RCOUNT  - 1) DOWNTO 0);
            mag_out             : out STD_LOGIC_VECTOR((DATABUS_WIDTH   - 1) DOWNTO 0);
            mag_valid           : out STD_LOGIC;
            mag_cpi             : out STD_LOGIC
        );    
    END COMPONENT;
    
    COMPONENT ila_0
    PORT (
        clk      : IN STD_LOGIC;

        probe0   : IN STD_LOGIC_VECTOR(15 DOWNTO 0); 
        probe1   : IN STD_LOGIC_VECTOR(15 DOWNTO 0); 
        probe2   : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
        probe3   : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
        probe4   : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe5   : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
        probe6   : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
        probe7   : IN STD_LOGIC_VECTOR(15 DOWNTO 0)
        );
    END COMPONENT;
    
    constant rom_samples       : integer := 512;
    constant addr_incr_value   : integer := 4;                                                        -- change the increment value to change the frequency 
    constant downtime          : integer := 512;
    
    signal addr_incr_value_vio : std_logic_vector(7 downto 0);
    signal PulseCountMax       : std_logic_vector((TIM_GEN_PCOUNT  - 1) DOWNTO 0) := x"200";
    signal RangeCountMax       : std_logic_vector((TIM_GEN_RCOUNT  - 1) DOWNTO 0) := x"800"; 
    signal win_out_I           : std_logic_vector((DATABUS_WIDTH   - 1) DOWNTO 0);
    signal win_out_Q           : std_logic_vector((DATABUS_WIDTH   - 1) DOWNTO 0);
    signal win_valid           : std_logic; 
    signal doppler_fft_out     : std_logic_vector((2*DATABUS_WIDTH - 1) DOWNTO 0);  
    signal doppler_fft_valid   : std_logic;
    signal doppler_fft_cpi     : std_logic; 
    signal mag_out_i           : std_logic_vector((DATABUS_WIDTH   - 1) DOWNTO 0);
    signal mag_valid           : std_logic;
    signal mag_cpi             : std_logic;
    signal lut_rom_ena         : std_logic;
    signal lut_rom_addra       : std_logic_vector(8 downto 0);
    signal lut_rom_douta       : std_logic_vector(31 downto 0);
    signal idle_cnt            : std_logic_vector(5 downto 0);
    signal rom_rd_cnt          : std_logic_vector(9 downto 0);
    signal downtime_cnt        : std_logic_vector(9 downto 0);
    signal fft_cnt             : std_logic_vector(15 downto 0);
    signal idle_cnt_en         : std_logic;
    signal rom_rd_cnt_en       : std_logic;
    signal downtime_cnt_en     : std_logic;
    signal locked_rstn         : std_logic;
    signal clock_300MHz        : std_logic;
    
    type lut_rom_rd_SM is (st0_idle, st1_lut_rom_rd, st2_down_time);
    signal state, next_state : lut_rom_rd_SM;
    
begin

    mag_out <= mag_out_i;

    clk_wiz_int1 : clk_wiz_0
        port map (  
            clk_out1     => clock_300MHz,
            -- Status and control signals                
            reset        => reset,
            locked       => locked_rstn,                                           -- Active low reset                
            clk_in1_p    => clk_125_p,
            clk_in1_n    => clk_125_n
    );
    
    SYNC_PROC_lut_rom_rd_SM : process(clock_300MHz, reset)
    begin
        if(rising_edge(clock_300MHz)) then
            if(reset = '1') then
                state <= st0_idle;
            else
                state <= next_state;
            end if;
        end if;
    end process;
    
    NEXT_STATE_DECODE_lut_rom_rd_SM : process(state, idle_cnt, rom_rd_cnt, downtime_cnt)
    begin
        next_state <= state;
        case(state) is 
            
            when st0_idle =>
                if(idle_cnt < "01111") then
                    next_state <= st0_idle;
                else
                    next_state <= st1_lut_rom_rd;
                end if;
            
            when st1_lut_rom_rd =>
                if(rom_rd_cnt < (rom_samples-1)) then
                    next_state <= st1_lut_rom_rd;
                else
                    next_state <= st2_down_time;
                end if;
            
            when st2_down_time =>
                if(downtime_cnt <= (downtime-1)) then
                    next_state <= st2_down_time;
                else
                    next_state <= st1_lut_rom_rd;
                end if;
                    
        end case;
    end process;
    
    OUTPUT_DECODE_lut_rom_rd_SM : process (state)
    begin
        case (state) is
            
            when st0_idle =>
                idle_cnt_en     <= '1';
                rom_rd_cnt_en   <= '0';
                downtime_cnt_en <= '0';
                lut_rom_ena     <= '0';
            
            when st1_lut_rom_rd =>
                idle_cnt_en     <= '0';
                rom_rd_cnt_en   <= '1';
                downtime_cnt_en <= '0';
                lut_rom_ena     <= '1';
            
            when st2_down_time  =>
                idle_cnt_en     <= '0';
                rom_rd_cnt_en   <= '0';
                downtime_cnt_en <= '1';
                lut_rom_ena     <= '0';
            
        end case;
    end process;
    
    process(clock_300MHz, reset)
    begin
        if(rising_edge(clock_300MHz)) then
            if(reset = '1') then
                idle_cnt <= (others => '0');
            else
                if(idle_cnt_en = '1') then
                    idle_cnt <= idle_cnt + '1';
                else
                    idle_cnt <= idle_cnt; 
                end if;
            end if;
        end if;
    end process;
    
    vio_0_inst1 : vio_0
        PORT MAP (
            clk        => clock_300MHz,
            probe_out0 => addr_incr_value_vio
    );
    
    process(clock_300MHz, reset)
    begin
        if(rising_edge(clock_300MHz)) then
            if(reset = '1') then
                lut_rom_addra <= (others => '0');
                rom_rd_cnt    <= (others => '0');
            else
                if(rom_rd_cnt_en = '1') then
                    lut_rom_addra <= lut_rom_addra + TO_INTEGER(unsigned(addr_incr_value_vio));          --addr_incr_value; without VIO
                    rom_rd_cnt    <= rom_rd_cnt + 1;
                else
                    lut_rom_addra <= (others => '0'); 
                    rom_rd_cnt    <= (others => '0');
                end if;
            end if;
        end if;
    end process;
 
    process(clock_300MHz, reset)
    begin
        if(rising_edge(clock_300MHz)) then
            if(reset = '1') then
                downtime_cnt <= (others => '0');
            else
                if(downtime_cnt_en = '1') then
                    downtime_cnt <= downtime_cnt + '1';
                else
                    downtime_cnt <= (others => '0'); 
                end if;
            end if;
        end if;
    end process;
    
    process(clock_300MHz, reset)
        begin
            if(rising_edge(clock_300MHz)) then
                if(reset = '1') then
                    win_valid <= '0';
                else
                    win_valid <= lut_rom_ena;
                end if;
            end if;
        end process;
    

    LUT_Rom_inst1 : LUT_Rom
        PORT MAP(
            clka  => clock_300MHz,
            ena   => lut_rom_ena,
            addra => lut_rom_addra,
            douta => lut_rom_douta
        );

    doppler_fft_inst1 : doppler_fft
        generic map(
            TIM_GEN_PCOUNT      => TIM_GEN_PCOUNT,
            DATABUS_WIDTH       => DATABUS_WIDTH,
            CONFIG_DATA         => CONFIG_DATA,
            DOPPLR_FFT          => DOPPLR_FFT
        )
        port map(
            clk                 => clock_300MHz,
            rst                 => reset,
            PulseCountMax       => PulseCountMax,
            win_out_I           => lut_rom_douta(15 downto 0), 
            win_out_Q           => lut_rom_douta(31 downto 16),
            win_valid           => win_valid,
            doppler_fft_out     => doppler_fft_out,
            doppler_fft_valid   => doppler_fft_valid,
            doppler_fft_cpi     => doppler_fft_cpi   
        );
        
    magnituder_inst1 : magnituder
        generic map(
            DATABUS_WIDTH       => DATABUS_WIDTH,
            TIM_GEN_PCOUNT      => TIM_GEN_PCOUNT,
            TIM_GEN_RCOUNT      => TIM_GEN_RCOUNT       
        )
        port map(
            clk                 => clock_300MHz,
            rst                 => reset,
            dfft_out            => doppler_fft_out,
            dfft_valid          => doppler_fft_valid,
            PulseCountMax       => PulseCountMax,
            RangeCountMax       => RangeCountMax,
            mag_out             => mag_out_i,
            mag_valid           => mag_valid,
            mag_cpi             => mag_cpi
        );
        
        
    process(clock_300MHz, reset) 
    begin
        if(rising_edge(clock_300MHz)) then
            if(reset = '1' ) then
                fft_cnt  <= (others => '0');
            else
                if(mag_valid = '1')then
                    fft_cnt <= fft_cnt + '1';
                else
                    fft_cnt <= (others => '0');
                end if;
            end if;
        end if;
    end process;
    
    ila_0_inst1 : ila_0
        PORT MAP (
           clk          => clock_300MHz,
        
           probe0       => lut_rom_douta(15 downto 0), 
           probe1       => lut_rom_douta(31 downto 16), 
           probe2(0)    => win_valid, 
           probe3       => doppler_fft_out, 
           probe4(0)    => doppler_fft_valid,
           probe5       => mag_out_i,
           probe6(0)    => mag_valid,
           probe7       => fft_cnt
        );

end Behavioral;
