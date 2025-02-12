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

-----------------------------------------------------

entity keyboard is
	port(
   clk:		in std_logic;	
	led_0 : out STD_LOGIC_VECTOR (6 downto 0);
	led_1 : out STD_LOGIC_VECTOR (6 downto 0);
	ps2_keyboard: in STD_LOGIC;
	keyboard_clock: in STD_LOGIC;
	lcd_sw: in STD_LOGIC;
	lcd_rw, lcd_rs, lcd_en: OUT STD_LOGIC;
	lcd_data: out STD_LOGIC_VECTOR (7 downto 0)
	);
	
	end keyboard;

-----------------------------------------------------

architecture FSM of keyboard is

	signal key : STD_LOGIC_VECTOR(7 downto 0);
	signal keyboard_input: STD_LOGIC_VECTOR (10 downto 0);
	signal counter : integer range 0 to 10; 
	type state_type is (power_on, config_lcd, power_on_lcd, clean_lcd, cursor_config_lcd, ready_state, done_state);    --Define dfferent states to control the LCD
   signal lcd_state: state_type;
   constant miliseconds: integer := 50000;
   constant microseconds: integer := 50;
		
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
		  when others =>
				return x"30";
		end case; 
	end toAscii;
	
	 
begin

	comb_logic: process(clk)
	variable count: integer := 0;
	begin
		if (clk'event and clk='1') then
		  case lcd_state is
			 when power_on =>
			  if (count < 50*miliseconds) then    --Wait for the LCD to start all its components
					count := count + 1;
					lcd_state <= power_on;
				else
					lcd_en <= '0';
					count := 0; 
					lcd_state <= config_lcd;
				end if;
				--From this point we will send diffrent configuration commands as shown in class
				--You should check the manual to understand what configurations we are sending to
				--The display. You have to wait between each command for the LCD to take configurations.
			 when config_lcd =>
				if (count = 0) then
					count := count +1;
					lcd_rs <= '0';
					lcd_rw <= '0';
					lcd_data <= "00111000";
					lcd_en <= '1';
					lcd_state <= config_lcd;
				elsif (count < 1*miliseconds) then
					count := count + 1;
					lcd_state <= config_lcd;
				else
					lcd_en <= '0';
					count := 0;
					lcd_state <= power_on_lcd;
				end if;
			 when power_on_lcd =>
				if (count = 0) then
					count := count +1;
					lcd_data <= "00001111";				
					lcd_en <= '1';
					lcd_state <= power_on_lcd;
				elsif (count < 1*miliseconds) then
					count := count + 1;
					lcd_state <= power_on_lcd;
				else
					lcd_en <= '0';
					count := 0;
					lcd_state <= clean_lcd;
				end if;
			 when clean_lcd =>	
				if (count = 0) then
					count := count +1;
					lcd_data <= "00000001";				
					lcd_en <= '1';
					lcd_state <= clean_lcd;
				elsif (count < 1*miliseconds) then
					count := count + 1;
					lcd_state <= clean_lcd;
				else
					lcd_en <= '0';
					count := 0;
					lcd_state <= cursor_config_lcd;
				end if;
			 when cursor_config_lcd =>	
				if (count = 0) then
					count := count +1;
					lcd_data <= "00000100";				
					lcd_en <= '1';
					lcd_state <= cursor_config_lcd;
				elsif (count < 1*miliseconds) then
					count := count + 1;
					lcd_state <= cursor_config_lcd;
				else
					lcd_en <= '0';
					count := 0;
					lcd_state <= ready_state;
				end if;
				--The display is now configured now it you just can send data to de LCD 
				--In this example we are just sending letter A, for this project you
				--Should make it variable for what has been pressed on the keyboard.
			 when ready_state =>	
				if (count = 0) then
					lcd_rs <= '1';
					lcd_rw <= '0';
					lcd_en <= '1';
					lcd_data <= toAscii(key);
					count := count +1;
					lcd_state <= ready_state;
				elsif (count < 1*miliseconds) then
					count := count + 1;
					lcd_state <= ready_state;
				else
					lcd_en <= '0';
					count := 0;
					lcd_state <= done_state;
				end if;
			  when done_state =>
			   if (counter = 10) then
					lcd_state <= ready_state;
				else
					lcd_state <= done_state;
				end if;
			 when others =>
				lcd_state <= power_on;
		  end case;
		end if;
	end process;
	

	keyboardHandler: process(keyboard_clock)
	begin
 		if (falling_edge(keyboard_clock)) then
			keyboard_input(counter) <= ps2_keyboard; 
			counter <= counter + 1;
			if(counter = 10) then
				key <= keyboard_input(8 downto 1);
				led_0 <= getOutputLed(key(3 downto 0));
				led_1 <= getOutputLed(key(7 downto 4));
				counter <= 0;
			end if;  
		end if;
	end process;
	

end FSM;

-----------------------------------------------------