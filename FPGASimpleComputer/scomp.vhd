LIBRARY IEEE;
LIBRARY ALTERA_MF;
LIBRARY LPM;

USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE ALTERA_MF.ALTERA_MF_COMPONENTS.ALL;
USE LPM.LPM_COMPONENTS.ALL;

ENTITY SCOMP IS
  PORT(
    CLOCK    : IN    STD_LOGIC;
	RESETN   : IN    STD_LOGIC;
	PCINT    : IN    STD_LOGIC_VECTOR( 3 DOWNTO 0)
  );
END SCOMP;


ARCHITECTURE a OF SCOMP IS
  
	TYPE STATE_TYPE IS (

		RESET_PC,
		FETCH,
		DECODE,
		EX_LOAD,
		EX_STORE,
		EX_STORE2,
		EX_ADD,
		EX_SUB,
		EX_JUMP,
		EX_JNEG,
		EX_JPOS,
		EX_JZERO,
		EX_AND,
		EX_OR,
		EX_XOR,
		EX_SHIFT,
		EX_ADDI,
		EX_ILOAD,
		EX_ISTORE,
		EX_CALL,
		EX_RETURN,
		EX_IN,
		EX_OUT,
		EX_OUT2,


		EX_MOVR,
		EX_ADDR,
		EX_SUBR,
		EX_ADDIR,

		EX_ANDR,
		EX_ORR,

		EX_CMP,
		EX_LT,
		EX_GT
	);
  

	TYPE STACK_TYPE IS ARRAY (0 TO 9) OF STD_LOGIC_VECTOR(10 DOWNTO 0);

	SIGNAL STATE        : STATE_TYPE;
	SIGNAL PC_STACK     : STACK_TYPE;

	SIGNAL AC           : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL AC_SAVED     : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL AC_SHIFTED   : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL IR           : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL MDR          : STD_LOGIC_VECTOR(15 DOWNTO 0);
	SIGNAL PC           : STD_LOGIC_VECTOR(10 DOWNTO 0);
	SIGNAL PC_SAVED     : STD_LOGIC_VECTOR(10 DOWNTO 0);
	SIGNAL MEM_ADDR     : STD_LOGIC_VECTOR(10 DOWNTO 0);
	SIGNAL MW           : STD_LOGIC;



  BEGIN
  
    -- Use altsyncram component for unified program and data memory
	MEMORY : altsyncram
	GENERIC MAP (
		intended_device_family => "Cyclone",
		width_a          => 16,
		widthad_a        => 11,
		numwords_a       => 2048,
		operation_mode   => "SINGLE_PORT",
		outdata_reg_a    => "UNREGISTERED",
		indata_aclr_a    => "NONE",
		wrcontrol_aclr_a => "NONE",
		address_aclr_a   => "NONE",
		outdata_aclr_a   => "NONE",
		init_file        => "example.mif",
		lpm_hint         => "ENABLE_RUNTIME_MOD=NO",
		lpm_type         => "altsyncram"
	)
	PORT MAP (
		wren_a    => MW,
		clock0    => NOT(CLOCK),
		address_a => MEM_ADDR,
		data_a    => AC,
		q_a       => MDR
	);
	
	
	-- Use LPM function to shift AC using the SHIFT instruction
	SHIFTER: LPM_CLSHIFT
	GENERIC MAP (
		lpm_width     => 16,
		lpm_widthdist => 4,
		lpm_shifttype => "ARITHMETIC"
	)
	PORT MAP (
		data      => AC,
		distance  => IR(3 DOWNTO 0),
		direction => IR(4),
		result    => AC_SHIFTED
	);

	-- Use LPM function to drive I/O bus
	--IO_BUS: LPM_BUSTRI
	--GENERIC MAP (
	--	lpm_width => 16
	--)
	--PORT MAP (
	--	data     => AC,
	--	enabledt => IO_WRITE_INT,
	--	tridata  => IO_DATA
	--);
	
	
	
    --IO_ADDR  <= IR(7 DOWNTO 0);

	WITH STATE SELECT MEM_ADDR <=
		PC WHEN FETCH,
		IR(10 DOWNTO 0) WHEN OTHERS;

	--WITH STATE SELECT IO_CYCLE <=
	--	'1' WHEN EX_IN,
	--	'1' WHEN EX_OUT2,
	--	'0' WHEN OTHERS;

	--IO_WRITE <= IO_WRITE_INT;


    PROCESS (CLOCK, RESETN)
      BEGIN
        
        IF (RESETN = '0') THEN          -- Active low, asynchronous reset
			STATE <= RESET_PC;
		ELSIF (RISING_EDGE(CLOCK)) THEN
			CASE STATE IS
				WHEN RESET_PC =>
					MW        <= '0';          -- Clear memory write flag
					PC        <= "00000000000"; -- Reset PC to the beginning of memory, address 0x000
					AC        <= x"0000";      -- Clear AC register
					--IO_WRITE_INT <= '0';
					STATE     <= FETCH;

				WHEN FETCH =>
					MW    <= '0';       -- Clear memory write flag
					IR    <= MDR;       -- Latch instruction into the IR
					--IO_WRITE_INT <= '0';       -- Lower IO_WRITE after an OUT

				WHEN DECODE =>
					CASE IR(15 downto 11) IS
						WHEN "00000" =>       -- No Operation (NOP)
							STATE <= FETCH;
						WHEN "00001" =>       -- LOAD
							STATE <= EX_LOAD;
						WHEN "00010" =>       -- STORE
							STATE <= EX_STORE;
						WHEN "00011" =>       -- ADD
							STATE <= EX_ADD;
						WHEN "00100" =>       -- SUB
							STATE <= EX_SUB;
						WHEN "00101" =>       -- JUMP
							STATE <= EX_JUMP;
						WHEN "00110" =>       -- JNEG
							STATE <= EX_JNEG;
						WHEN "00111" =>       -- JPOS
							STATE <= EX_JPOS;
						WHEN "01000" =>       -- JZERO
							STATE <= EX_JZERO;
						WHEN "01001" =>       -- AND
							STATE <= EX_AND;
						WHEN "01010" =>       -- OR
							STATE <= EX_OR;
						WHEN "01011" =>       -- XOR
							STATE <= EX_XOR;
						WHEN "01100" =>       -- SHIFT
							STATE <= EX_SHIFT;
						WHEN "01101" =>       -- ADDI
							STATE <= EX_ADDI;
						WHEN "01110" =>       -- ILOAD
							STATE <= EX_ILOAD;
						WHEN "01111" =>       -- ISTORE
							STATE <= EX_ISTORE;
						WHEN "10000" =>       -- CALL
							STATE <= EX_CALL;
						WHEN "10001" =>       -- RETURN
							STATE <= EX_RETURN;
						

						-- 
						-- Register-to-Register Operations
						--
						-- Harrison

						WHEN "11000" =>
							STATE <= EX_MOVR;

						WHEN "11001" =>
							STATE <= EX_SUBR;

						WHEN "11010" =>
							STATE <= EX_ADDIR;

						WHEN "11011" =>
							STATE <= EX_ANDR;

						WHEN "11100" => 
							STATE <= EX_ORR;


						-- Comparisons
						--

						WHEN "11101" =>
							STATE <= EX_CMP;

						WHEN "11110" =>
							STATE <= EX_LT;

						WHEN "11111" =>
							STATE <= EX_GT;


						WHEN OTHERS =>
							STATE <= FETCH;      -- Invalid opcodes default to NOP
					END CASE;





				WHEN EX_LOAD =>
					AC    <= MDR;            -- Latch data from MDR (memory contents) to AC
					STATE <= FETCH;

				WHEN EX_STORE =>
					MW    <= '1';            -- Raise MW to write AC to MEM
					STATE <= EX_STORE2;

				WHEN EX_STORE2 =>
					MW    <= '0';            -- Drop MW to end write cycle
					STATE <= FETCH;

				WHEN EX_ADD =>
					AC    <= AC + MDR;
					STATE <= FETCH;

				WHEN EX_SUB =>
					AC    <= AC - MDR;
					STATE <= FETCH;

				WHEN EX_JUMP =>
					PC    <= IR(10 DOWNTO 0);
					STATE <= FETCH;

				WHEN EX_JNEG =>
					IF (AC(15) = '1') THEN
						PC    <= IR(10 DOWNTO 0);
					END IF;

				STATE <= FETCH;

				WHEN EX_JPOS =>
					IF ((AC(15) = '0') AND (AC /= x"0000")) THEN
						PC    <= IR(10 DOWNTO 0);
					END IF;
					STATE <= FETCH;

				WHEN EX_JZERO =>
					IF (AC = x"0000") THEN
						PC    <= IR(10 DOWNTO 0);
					END IF;
					STATE <= FETCH;

				WHEN EX_AND =>
					AC    <= AC AND MDR;
					STATE <= FETCH;

				WHEN EX_OR =>
					AC    <= AC OR MDR;
					STATE <= FETCH;

				WHEN EX_XOR =>
					AC    <= AC XOR MDR;
					STATE <= FETCH;

				WHEN EX_SHIFT =>
					AC    <= AC_SHIFTED;
					STATE <= FETCH;

				WHEN EX_ADDI =>
					AC    <= AC + (IR(10) & IR(10) & IR(10) &
					 IR(10) & IR(10) & IR(10 DOWNTO 0));
					STATE <= FETCH;

				WHEN EX_ILOAD =>
					IR(10 DOWNTO 0) <= MDR(10 DOWNTO 0);
					STATE <= EX_LOAD;

				WHEN EX_ISTORE =>
					IR(10 DOWNTO 0) <= MDR(10 DOWNTO 0);
					STATE          <= EX_STORE;

				WHEN EX_CALL =>
					FOR i IN 0 TO 8 LOOP
						PC_STACK(i + 1) <= PC_STACK(i);
					END LOOP;
					PC_STACK(0) <= PC;
					PC          <= IR(10 DOWNTO 0);
					STATE       <= FETCH;

				WHEN EX_RETURN =>
					FOR i IN 0 TO 8 LOOP
						PC_STACK(i) <= PC_STACK(i + 1);
					END LOOP;
					PC          <= PC_STACK(0);
					STATE       <= FETCH;


				--
				-- Register-to-Register Operations
				--

				WHEN EX_MOVR =>

					


					STATE <= FETCH;

				WHEN EX_ADDR =>

					

					STATE <= FETCH;




				WHEN EX_SUBR =>

					
					STATE 	<= FETCH;


				WHEN EX_ADDIR =>

					

					STATE <= FETCH;

				WHEN EX_ANDR =>

					

					STATE <= FETCH;

				WHEN EX_ORR =>

					

					STATE <= FETCH;


				WHEN EX_CMP =>

					

					STATE <= FETCH;



				WHEN OTHERS =>
					STATE <= FETCH;          -- If an invalid state is reached, return to FETCH
					
			END CASE;
		END IF;
      END PROCESS;   
  END a;
