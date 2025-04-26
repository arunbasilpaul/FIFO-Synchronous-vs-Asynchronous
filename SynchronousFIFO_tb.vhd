library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity SynchronousFIFOTestBench is
end SynchronousFIFOTestBench;

architecture test of SynchronousFIFOTestBench is

	constant FIFO_DEPTH : integer := 2;
	constant DATA_WIDTH : integer := 8;

	component SynchronousFIFO is
	generic(
		FIFO_DEPTH : integer := 2;  -- The maximum number of entries that can be stored
		DATA_WIDTH : integer := 8    -- The maximum number of bits per word in a single FIFO entry
	);
	port(
		clk      : in  std_logic;
		reset    : in  std_logic;
		write_en : in  std_logic;
		read_en  : in  std_logic;
		data_in  : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
		full     : out std_logic;
		empty    : out std_logic;
		data_out : out std_logic_vector(DATA_WIDTH - 1 downto 0)
	);
	end component;

	signal t_clk, t_reset, t_write_en, t_read_en, t_full, t_empty : std_logic := '0';
	signal t_data_in, t_data_out : std_logic_vector(DATA_WIDTH - 1 downto 0) := (others => '0');

	constant CLK_PERIOD : time := 10 ns;

	begin
		UUT: SynchronousFIFO
			generic map(
				FIFO_DEPTH => FIFO_DEPTH,
				DATA_WIDTH => DATA_WIDTH
			)
			port map(
				clk      => t_clk,
				reset    => t_reset,
				write_en => t_write_en,
				read_en  => t_read_en,
				data_in  => t_data_in,
				full     => t_full,
				empty    => t_empty,
				data_out => t_data_out
			);

		clk_process: process begin
			while true loop
				t_clk <= '0';
				wait for CLK_PERIOD/2;
				t_clk <= '1';
				wait for CLK_PERIOD/2;
			end loop;
		end process;

		input_process: process begin
			
			wait for CLK_PERIOD/2;
			t_reset <= '1';

			wait for CLK_PERIOD*5;
			t_reset <= '0';
			t_write_en <= '1';
			t_data_in <= "10101011";

			wait for CLK_PERIOD*2;
			t_write_en <= '0';
	
			wait for CLK_PERIOD*2;
			t_write_en <= '1';
			t_data_in <= "11111011";

			wait for 5*CLK_PERIOD;
			t_write_en <= '0';
			t_read_en <= '1';

			wait for CLK_PERIOD;
			t_write_en <= '0';

			wait for CLK_PERIOD*2;
			t_write_en <= '1';

			wait for CLK_PERIOD*2;
			t_write_en <= '0';
			
			wait;

		end process;
	
end test;