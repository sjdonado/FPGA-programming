-----------------------------------------------------
-- VHDL FSM (Finite State Machine) modeling
-- (ESD book Figure 2.7)
-- by Weijun Zhang, 04/2001
--
-- FSM model consists of two concurrent processes
-- state_reg and comb_logic
-- we use case statement to describe the state 
-- transistion. All the inputs and signals are
-- put into the process sensitive list.  
-----------------------------------------------------

library ieee ;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

-----------------------------------------------------

entity vga is
	port(
		clk: in STD_LOGIC;
		vga_hs, vga_vs: out STD_LOGIC;
		vga_r, vga_g, vga_b: out STD_LOGIC_VECTOR(7 downto 0); 
		led_0 : out STD_LOGIC_VECTOR (6 downto 0);
		led_1 : out STD_LOGIC_VECTOR (6 downto 0);
		vga_clck_out : out STD_LOGIC;
		ps2_keyboard: in STD_LOGIC;
		keyboard_clock: in STD_LOGIC
	);
end vga;

-----------------------------------------------------

architecture FSM of vga is

	signal vga_clk, reset : STD_LOGIC := '0';
	signal vga_addr : STD_LOGIC_VECTOR(10 downto 0);
	signal vga_data : STD_LOGIC_VECTOR(7 downto 0);
	signal vga_hgrid : STD_LOGIC_VECTOR(79 downto 0);
	signal vga_vgrid : STD_LOGIC_VECTOR(29 downto 0);
	signal vga_hgrid_count : integer range 0 to 79:=0;
	signal vga_vgrid_count : integer range 0 to 29:=0;
	signal vga_vpos :	integer range 0 to 525;
	signal key : STD_LOGIC_VECTOR(7 downto 0);
	signal keyboard_input: STD_LOGIC_VECTOR (10 downto 0);
	signal keyboard_last: STD_LOGIC_VECTOR (7 downto 0);
	signal keyboard_count: integer range 0 to 2; 
	signal counter: integer range 0 to 10;
   constant miliseconds: integer := 50000;
   constant microseconds: integer := 50;

    component PLL is
        port (
            clk_in_clk  : in  std_logic := 'X'; -- clk
            clk_out_clk : out std_logic;        -- clk
            reset_reset : in  std_logic := 'X'  -- reset
        );
    end component PLL;
	
	component sync is
		port(
			CLK: IN STD_LOGIC;
			DATA_HGRID : STD_LOGIC_VECTOR(79 downto 0);
			DATA_VGRID : STD_LOGIC_VECTOR(29 downto 0);
			HSYNC, VSYNC: OUT STD_LOGIC;
			R, G, B: OUT STD_LOGIC_VECTOR(7 downto 0);
			VGA_VPOS : OUT INTEGER RANGE 0 TO 525
		);
	end component sync;
		
	component font_rom is
		port(
			clock: in std_logic;
			addr: in std_logic_vector(10 downto 0);
			data: out std_logic_vector(7 downto 0)
		);
	end component font_rom;
	
	function getOutputLed(number : STD_LOGIC_VECTOR) return STD_LOGIC_VECTOR is
	begin
		case number is
			 when "0000" => return "1000000"; -- 0  
			 when "0001" => return "1111001"; -- 1
			 when "0010" => return "0100100"; -- 2
			 when "0011" => return "0110000"; -- 3
			 when "0100" => return "0011001"; -- 4
			 when "0101" => return "0010010"; -- 5
			 when "0110" => return "0000010"; -- 6
			 when "0111" => return "1111000"; -- 7
			 when "1000" => return "0000000"; -- 8
			 when "1001" => return "0010000"; -- 9
			 when "1010" => return "0000010"; -- A
			 when "1011" => return "0000011"; -- b
			 when "1100" => return "1000110"; -- C
			 when "1101" => return "0100001"; -- d
			 when "1110" => return "0000110"; -- E
			 when "1111" => return "0001110"; -- F
		end case;
	end getOutputLed;
	
	function toAscii(number : STD_LOGIC_VECTOR) return STD_LOGIC_VECTOR is
	begin
		case number is
		  when x"45" => return x"30";  -- 0 
		  when x"16" => return x"31";  -- 1 
		  when x"1e" => return x"32";  -- 2 
		  when x"26" => return x"33";  -- 3 
		  when x"25" => return x"34";  -- 4 
		  when x"2e" => return x"35";  -- 5 
		  when x"36" => return x"36";  -- 6 
		  when x"3d" => return x"37";  -- 7 
		  when x"3e" => return x"38";  -- 8 
		  when x"46" => return x"39";  -- 9 
		  when x"1c" => return x"41";  -- A 
		  when x"32" => return x"42";  -- B 
		  when x"21" => return x"43";  -- C 
		  when x"23" => return x"44";  -- D 
		  when x"24" => return x"45";  -- E 
		  when x"2b" => return x"46";  -- F 
		  when x"34" => return x"47";  -- G 
		  when x"33" => return x"48";  -- H 
		  when x"43" => return x"49";  -- I 
		  when x"3b" => return x"4a";  -- J 
		  when x"42" => return x"4b";  -- K 
		  when x"4b" => return x"4c";  -- L 
		  when x"3a" => return x"4d";  -- M 
		  when x"31" => return x"4e";  -- N 
		  when x"44" => return x"4f";  -- O 
		  when x"4d" => return x"50";  -- P 
		  when x"15" => return x"51";  -- Q 
		  when x"2d" => return x"52";  -- R 
		  when x"1b" => return x"53";  -- S 
		  when x"2c" => return x"54";  -- T 
		  when x"3c" => return x"55";  -- U 
		  when x"2a" => return x"56";  -- V 
		  when x"1d" => return x"57";  -- W 
		  when x"22" => return x"58";  -- X 
		  when x"35" => return x"59";  -- Y 
		  when x"1a" => return x"5a";  -- Z
		  when x"29" => return x"20";  -- space
		  when others =>
				return x"00";
		end case; 
	end toAscii;
	
begin

	c1: sync port map(vga_clk, vga_data, vga_hs, vga_vs, vga_r, vga_g, vga_b, vga_vpos);
	c2: PLL port map(clk, vga_clk, reset);
	c3: font_rom port map(vga_clk, vga_addr, vga_data);
	vga_clck_out <= vga_clk;
	
	font_writter: process(vga_vpos, key)
	begin
 		
	end process;
	
	keyboardHandler: process(keyboard_clock)
	begin
 		if (falling_edge(keyboard_clock)) then
			keyboard_input(counter) <= ps2_keyboard; 
			counter <= counter + 1;
			if(counter = 10) then
				if(keyboard_input(8 downto 1) /= x"f0") then
					key <= keyboard_input(8 downto 1);
					vga_hgrid(vga_hgrid_count) <= toAscii(key) & std_logic_vector(to_unsigned(vga_vpos, 3));
					
					vga_hgrid_count <= vga_hgrid_count + 1;
					
					if(vga_hgrid_count > 79) then
						vga_hgrid_count <= 0;
						vga_vgrid(vga_vgrid_count) <= vga_hgrid;
						vga_vgrid_count <= vga_vgrid_count + 1;
					end if;
					
					if(vga_vgrid_count > 29) then
						vga_hgrid_count <= 0;
					end if;
					
					led_0 <= getOutputLed(key(3 downto 0));
					led_1 <= getOutputLed(key(7 downto 4));
				end if;
				keyboard_last <= keyboard_input(8 downto 1);
				counter <= 0;
			end if;
		end if;
	end process;
end FSM;

-----------------------------------------------------