
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
		reset 	: in 	std_logic
	);
	
end TheSimpleComputer;

architecture arch of TheSimpleComputer is
	
	begin

		process (clock, reset)
			begin
		
		end process;
	
end arch;

