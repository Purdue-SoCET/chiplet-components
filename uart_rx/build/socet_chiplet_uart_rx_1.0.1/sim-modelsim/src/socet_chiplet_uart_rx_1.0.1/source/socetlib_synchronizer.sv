
module socetlib_synchronizer#(
    parameter bit RESET_STATE = 1'b1,
    parameter int STAGES = 2
)(
    input CLK,
    input nRST,
    input async_in,
    output logic sync_out
);

    // Test parameters
    if(STAGES < 2) begin
        $error("socetlib_synchronizer: STAGES must be at least 2!");
    end else if(STAGES > 3) begin
        $error("socetlib_synchronizer: Are you SURE you wanted more than 3 stages of synchronizer???");
    end

    logic [STAGES-1:0] stages;
    logic [STAGES-1:0] reset_val;

    assign reset_val = {STAGES{RESET_STATE}};

    always_ff @(posedge CLK, negedge nRST) begin
        if(!nRST) begin
            stages <= reset_val;
        end else begin
            stages <= {async_in, stages[STAGES-1:1]};
        end
    end

    assign sync_out = stages[0];

endmodule