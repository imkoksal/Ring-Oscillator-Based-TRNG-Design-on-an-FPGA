# Data Acquisition
To start the data acquisition, write "source <enter .tcl directory>/ila_data_acquisition.tcl" in your Vivado tcl console after you've uploaded your bitstream onto your board. You can specify your desired saving directory in the tcl file  with changing the default < set save_dir "~/csv_design" > command.

# Getting the Whole Bitstream
To have the outputs be verified using the test from NIST you'll need to concatenate the csv files found in the csv_design section(about 70k csv files). The python file will ask you range of files need to be concatenated. first enter 0 then 70000. 
