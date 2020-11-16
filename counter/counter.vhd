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

entity counter is
	port(		
	speed: in STD_LOGIC_VECTOR(2 downto 0);
	reset : in STD_LOGIC;
	led_0 : out STD_LOGIC_VECTOR (6 downto 0);
	led_1 : out STD_LOGIC_VECTOR (6 downto 0);
	sw_dir : in STD_LOGIC;
	sw_freq : in STD_LOGIC;
	clk_50Mhz : in  std_logic);
end counter;

-----------------------------------------------------

architecture FSM of counter is

	signal number: STD_LOGIC_VECTOR (7 downto 0);
	signal prescaler_counter: integer range 0 to 49999999 := 0;
   signal new_clock : std_logic := '0';
	
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
	
	function swPrescaler(sw_freq : STD_LOGIC) return integer is
	begin
		if (sw_freq='1') then
			return 12499999;
		else
			return 49999999;
		end if;
	end swPrescaler;
	 
begin

	-- cocurrent process#1: counting
	counting: process(speed, reset, new_clock, number, sw_dir)
	begin
		if (reset='1') then
			number <= (others => '0');
		elsif (new_clock'event and new_clock='1') then
			case speed is
				when "100" =>
					if(sw_dir='0') then 
						number <= number + x"01";
					else
						number <= number - x"01";
					end if;
				when "010" =>
					if(sw_dir='0') then 
						number <= number + x"02";
					else
						number <= number - x"02";
					end if;
				when "001" =>
					if(sw_dir='0') then 
						number <= number + x"03";
					else
						number <= number - x"03";
					end if;
				when others => number <= number;
			end case;
		end if;
	end process;
	
	-- cocurrent process#2: parse Altera clock
	countClock: process(clk_50Mhz, prescaler_counter, new_clock, sw_freq)
    begin
        if rising_edge(clk_50Mhz) then
            prescaler_counter <= prescaler_counter + 1;
            if(prescaler_counter > swPrescaler(sw_freq)) then
                new_clock <= not new_clock;
                prescaler_counter <= 0;
            end if;
        end if;
    end process;

	-- cocurrent process#3: displaying numbers
	displaying: process(number)
	begin
		led_0 <= getOutputLed(number(3 downto 0));
		led_1 <= getOutputLed(number(7 downto 4));
	end process;	
	

end FSM;

-----------------------------------------------------
