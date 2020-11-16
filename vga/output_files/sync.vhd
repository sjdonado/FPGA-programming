
library ieee ;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

ENTITY sync IS
	PORT(
		CLK: IN STD_LOGIC;
		DATA_HGRID : STD_LOGIC_VECTOR(79 downto 0);
		DATA_VGRID : STD_LOGIC_VECTOR(29 downto 0);
		HSYNC, VSYNC: OUT STD_LOGIC;
		R, G, B: OUT STD_LOGIC_VECTOR(7 downto 0);
		VGA_VPOS : OUT INTEGER RANGE 0 TO 525:=0
	);
END sync;


ARCHITECTURE MAIN OF sync IS
	SIGNAL HPOS: INTEGER RANGE 0 TO 800:=0;
	SIGNAL VPOS: INTEGER RANGE 0 TO 525:=0;
	SIGNAL H_COUNT : INTEGER RANGE 0 TO 79:=0;
	SIGNAL V_COUNT : INTEGER RANGE 0 TO 29:=0;

	BEGIN
		PROCESS(CLK)
		 BEGIN
			IF(CLK'EVENT AND CLK='1') THEN
				VGA_VPOS <= VPOS;
				IF((HPOS > 160 AND HPOS < 640) AND (VPOS > 45 AND VPOS < 480)) THEN
					IF(DATA(H_COUNT, V_COUNT) = '1') THEN
						R<=(others=>'1');
						G<=(others=>'1');
						B<=(others=>'1');
					ELSE
						R<=(others=>'0');
						G<=(others=>'0');
						B<=(others=>'0');
					END IF;
				END IF;
				IF(HPOS < 800) THEN
					IF(HPOS > 160 AND HPOS MOD 8 = 0) THEN
						H_COUNT <= H_COUNT + 1;
					END IF;
					HPOS <= HPOS + 1;
				ELSE
					H_COUNT <= 0;
					HPOS <= 0;
					IF(VPOS < 525) THEN
						IF(VPOS > 45 AND VPOS MOD 16 = 0) THEN
							V_COUNT <= V_COUNT + 1;
						END IF;
					  VPOS <= VPOS + 1;
					ELSE
						V_COUNT <= 0;
						VPOS <= 0; 
					END IF;
				END IF;
				IF((HPOS > 0 AND HPOS < 160) OR (VPOS > 0 AND VPOS < 45)) THEN
					R<=(others=>'0');
					G<=(others=>'0');
					B<=(others=>'0');
				END IF;
					IF(HPOS>16 AND HPOS<112) THEN
						HSYNC<='0';
					ELSE
						HSYNC<='1';
					END IF;
					IF(VPOS>10 AND VPOS<12) THEN
						VSYNC<='0';
					ELSE
						VSYNC<='1';
					END IF;
			END IF;
		END PROCESS;
 END MAIN;