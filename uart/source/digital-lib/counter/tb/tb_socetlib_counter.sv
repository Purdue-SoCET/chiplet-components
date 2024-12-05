// Author:      Huy-Minh Tran
// Description: Counter Testbench

// 0.5um D-FlipFlop Timing Data Estimates:
// Data Propagation delay (clk->Q): 670ps
// Setup time for data relative to clock: 190ps
// Hold time for data relative to clock: 10ps

`ifndef NUM_BIT_CNT
    `define NUM_BIT_CNT 4
`endif

module tb_socetlib_counter();

  // Define local parameters used by the test bench
  localparam  CLK_PERIOD    = 2.5;
  localparam  FF_SETUP_TIME = 0.190;
  localparam  FF_HOLD_TIME  = 0.100;
  localparam  CHECK_DELAY   = (CLK_PERIOD - FF_SETUP_TIME); // Check right before the setup time starts
  
  localparam  INACTIVE_VALUE     = 1'b0;
  localparam  RESET_OUTPUT_VALUE = INACTIVE_VALUE;
  
  // Declare DUT portmap signals
  reg tb_clk;
  reg tb_nRST;
  reg tb_clear;
  reg tb_count_enable;
  reg [(`NUM_BIT_CNT - 1):0] tb_overflow_val;
  reg [(`NUM_BIT_CNT - 1):0] tb_count_out;
  reg tb_overflow_flag;
  
  // Declare test bench signals
  integer tb_test_num;
  string tb_test_case;
  integer tb_stream_test_num;
  string tb_stream_check_tag;
  integer i;
  
  // Task for standard DUT reset procedure
  task reset_dut;
  begin
    // Activate the reset
    tb_nRST = 1'b0;
    // Maintain the reset for more than one cycle
    @(posedge tb_clk);
    @(posedge tb_clk);

    // Wait until safely away from rising edge of the clock before releasing
    @(negedge tb_clk);
    tb_nRST = 1'b1;
    tb_count_enable = 1'b0;
    // Leave out of reset for a couple cycles before allowing other stimulus
    // Wait for negative clock edges, 
    // since inputs to DUT should normally be applied away from rising clock edges
    @(negedge tb_clk);
   
  end
  endtask

  // Task to cleanly and consistently check DUT output values
  task check_output_count;
    input logic [(`NUM_BIT_CNT - 1):0] expected_count;
    input string check_tag;
  begin
    if(expected_count == tb_count_out) begin // Check passed
      $info("Correct count output %s during %s test case", check_tag, tb_test_case);
    end
    else begin // Check failed
      $error("Incorrect count output %s during %s test case", check_tag, tb_test_case);
    end
  end
  endtask

  // Task to cleanly and consistently check for correct values during MetaStability Test Cases
  task check_output_overflow;
    input logic  expected_flag;
    input string check_tag;
  begin
    if(expected_flag == tb_overflow_flag) begin // Check passed
      $info("Correct overflow flag output %s during %s test case", check_tag, tb_test_case);
    end
    else begin // Check failed
      $error("Incorrect count output %s during %s test case", check_tag, tb_test_case);
    end
  end
  endtask

  task clear;
    tb_clear = 1'b1;
    @(posedge tb_clk);
    tb_clear = 1'b0;
  endtask
  // Clock generation block
  always
  begin
    // Start with clock low to avoid false rising edge events at t=0
    tb_clk = 1'b0;
    // Wait half of the clock period before toggling clock value (maintain 50% duty cycle)
    #(CLK_PERIOD/2.0);
    tb_clk = 1'b1;
    // Wait half of the clock period before toggling clock value via rerunning the block (maintain 50% duty cycle)
    #(CLK_PERIOD/2.0);
  end
  
  // DUT Port map
  socetlib_counter #(.BITS_WIDTH(`NUM_BIT_CNT)) DUT(.clk(tb_clk), .nRST(tb_nRST), .clear(tb_clear), .count_enable(tb_count_enable)
    , .overflow_val(tb_overflow_val), .count_out(tb_count_out), .overflow_flag(tb_overflow_flag));
  
  // Test bench main process
  initial
  begin
    // Initialize all of the test inputs
    tb_nRST  = 1'b1;              // Initialize to be inactive
    tb_clear  = 0; // Initialize input to inactive  value
    tb_test_num = 0;               // Initialize test case counter
    tb_test_case = "Test bench initializaton";
    tb_stream_test_num = 0;
    tb_stream_check_tag = "N/A";

    //TEST 1: 
    tb_test_num = tb_test_num + 1;
    tb_test_case = "Power on Reset";
    #(0.1);
    tb_nRST  = 1'b0;    // Activate reset
    
    #(CLK_PERIOD * 0.5);

    // Check that internal state was correctly reset
    check_output_count(RESET_OUTPUT_VALUE, 
                  "after reset applied");
    
    // Check that the reset value is maintained during a clock cycle
    #(CLK_PERIOD);
    check_output_count(RESET_OUTPUT_VALUE, 
                  "after clock cycle while in reset");
    
    // Release the reset away from a clock edge
    @(posedge tb_clk);
    #(2 * FF_HOLD_TIME);
    tb_nRST  = 1'b1;   // Deactivate the chip reset
    #0.1;
    // Check that internal state was correctly keep after reset release
    check_output_count(RESET_OUTPUT_VALUE, 
                  "after reset was released");

    //TEST 2:  
    @(negedge tb_clk); 
    tb_test_num = tb_test_num + 1;
    tb_test_case = "overflow for a overflow value that is not a power of two";
    // Start out with inactive value and reset the DUT to isolate from prior tests
    tb_count_enable = INACTIVE_VALUE;
    reset_dut();

    // Assign test case stimulus
    tb_overflow_val = 4'd3;
    tb_count_enable = 1'b1;
    tb_clear = 1'b0;
    
    // Wait for DUT to process stimulus before checking results
    @(posedge tb_clk); 
    @(posedge tb_clk);
    @(posedge tb_clk);
    #(CHECK_DELAY);
    check_output_count(4'd3, "third count");
    check_output_overflow(1'b1, "overflow value");
    @(posedge tb_clk);
    #(CHECK_DELAY);
    // Check results
    check_output_count(4'd1, "after processing flag");
    check_output_overflow(1'b0, "overflow reset");
    
    //TEST 3:
    @(negedge tb_clk); 
    tb_test_num = tb_test_num + 1;
    tb_test_case = "Continuous Counting";
    // Start out with inactive value and reset the DUT to isolate from prior tests
    tb_count_enable = INACTIVE_VALUE;
    reset_dut();
    
    // Assign test case stimulus
    tb_overflow_val = 4'd15;
    tb_count_enable = 1'b1;
    tb_clear = 1'b0;

    for(i = 0; i < 15; i++) begin
        @(posedge tb_clk);
    end
  
    #(CHECK_DELAY);
    check_output_count(4'd15, "after counting");
    check_output_overflow(1'b1, "overflow set");
    
    @(posedge tb_clk);
    #(CHECK_DELAY);
    check_output_count(4'd1, "after counting");
    check_output_overflow(1'b0, "overflow reset");
  end
endmodule
