
--
-- The Simple Computer
-- 
-- A very simple 8 bit computer that my professor designed, and I built.
-- Now I am building an FPGA version of that processor.
--
-- Harrison Statham 
--


library ieee;
library altera_mf;
library lpm;

use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

use altera_mf.altera_mf_components.all;
use lpm.lpm_components.all;


entity TheSimpleComputer is
	
	port(
		clock 	: in 	std_logic;
		reset 	: in 	std_logic;
		program : in 	std_logic
	);
	
end TheSimpleComputer;


architecture arch of TheSimpleComputer is
	
	
	-- 
	-- States
	-- Define the various states that the computer can be in.
	--
	--
	type state_t is (
		
		reset_vsc,
		
		fetch,
		decode,
		
		exec_load,
		exec_store,
		exec_store2,
		exec_add,
		exec_complement,
		exec_branch_not_negative,
		exec_shift,
		exec_stack
	);
	
	signal state 	: state_t;
	
	--
	-- Internal Registers
	--
	-- IR 	= Instruction Register 			Stores the current instruction that is being executed.
	-- MAR 	= Memory Address Register 		Stores the address to read/write from in memory.
	-- MDR 	= Memory Data Register 			Stores the data to be read/written in to memory.
	-- PC 	= Program Counter 				Stores the current instruction being executed.
	-- AC 	= Accumulator 	
	--
	
	signal IR 		: std_logic_vector(7 downto 0);
	signal MAR 		: std_logic_vector(7 downto 0);
	signal MDR 		: std_logic_vector(7 downto 0);
	signal PC 		: std_logic_vector(7 downto 0);
	signal AC 		: std_logic_vector(7 downto 0);
	signal AC_SHIFT : std_logic_vector(7 downto 0);
	
	
	begin
		
		
		
		--
		-- Shifter
		--
		-- Create an instance of the LPM_CLSHIFT
		-- and give it the appropriate parameters.
		--
		
		shift_unit: LPM_CLSHIFT
		generic map(
		
			lpm_width 		=>	8,
			lpm_widthdist 	=> 	4,
			lpm_shifttype 	=> 	"ARITHMETIC"
		)
		port map (
			
			data 			=> 	AC,
			distance 		=> 	IR(3 downto 0),
			direction 		=> 	IR(4),
			result 			=> 	AC_SHIFTED
		);
		
		
		
		
		
		process (clock, reset, program)
			begin
			
			
			--
			-- Are we resetting the computer?
			--
			
			if(reset = '1') then
				
				state <= reset_vsc;
		
			elsif(rising_edge(clock)) then
				
				--
				-- Consider all the states the computer can be in.
				--
				
				case state is
					
					--
					-- reset_vsc
					--
					-- Clear the PC, and AC when we are in the reset state.
					--
					
					when reset_vsc =>
						
						PC 	<= "00000000";
						AC  <= "00000000";
						
						-- MW <= '0';
						
						state <= fetch;
					
					
					
					--
					-- fetch
					-- 
					-- Fetch the instruction to be executed.
					-- 
					
					when fetch =>
						
						-- MW <= '0'
						IR 	<= MDR;
						
					
					
					--
					-- decode
					--
					-- Determine what to do after the instruction has been fetched.
					-- 
					--	
					
					when decode =>
						
						case IR(7 downto 5) is
						
							when "000" => 	state <= fetch;
							when "001" => 	state <= exec_load;
							when "010" => 	state <= exec_store;
							when "011" => 	state <= exec_add;
							when "100" => 	state <= exec_complement;
							when "101" => 	state <= exec_branch_not_negative;
							when "110" => 	state <= exec_shift;
							when "111" => 	state <= exec_stack;
							
						-- end case IR(7 downto 5) is ...
						end case;
						
					
					
					--
					-- exec_load
					--
					-- Load a byte into the accumulator. 
					--
					when exec_load =>
						
						AC 		<= MDR;
						state 	<= fetch;
						
					
					--
					-- exec_store
					-- 
					-- Store the byte in the accumulator into memory at 
					-- the address supplied in MAR.
					
					when exec_store =>
						
						MW 		<= '1';
						state 	<= exec_store2;
						
					when exec_store2 =>
						
						MW 		<= '0';
						state 	<= fetch;
					
					
					--
					-- exec_add
					--
					-- Add the contents in the AC and MDR together
					-- and store the new result back in AC.	
					--
					
					when exec_add =>
						
						AC 		<= AC + MDR;
						state 	<= fetch;
					
					
					-- 
					-- exec_complement
					--
					-- Take the ones complement of the data in the accumulator
					-- and write the result back to the accumulator.
					--
					when exec_complement =>
					
						AC 		<= not AC;
						state 	<= fetch;
					
					
					
					--
					-- exec_branch_not_negative
					--
					-- Branch if the value in the accumulator is NOT negative.
					--
					
					when exec_branch_not_negative =>
						
						-- do some branching here.
						state 	<= fetch;
					
					
					
					--
					-- exec_shift
					--
					-- Shift data in the accumulator right or left.
					--
					when exec_shift =>
					
						AC 		<= AC_SHIFTED;
						state 	<= fetch;
						
					
					--
					-- exec_stack
					--
					-- Push/Pop items onto/off the stack.
					--
					
					when exec_stack =>
						
						
						state 	<= fetch;
				
				-- end case state is...
				end case;
			
			-- end if(reset = '1')
			end if;
		
		-- end process(clock, program, reset)...
		end process;
end arch;

