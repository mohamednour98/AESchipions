module TopTB();

  localparam halfPeriod = 1;
  localparam period = 2 * halfPeriod;
  reg[127:0] PTorCT, key;
  wire[127:0] outPTorCT;
  reg clk, startSignal, reset;

  Top TopModule(
    .start(startSignal),
    .clk(clk),
    .reset(reset),
    .data(PTorCT),
    .key(key),
    .encReady(tbReady),
    .outData(outPTorCT)
  );

  always begin
    #(halfPeriod);
    clk = !clk;
  end

  task testEncryption;
    begin: testing
      reg[31:0] PT;
      reg[31:0] CT;    

      PT = 128'h00000000000000000000000000000000;
      CT = 128'h7df76b0c1ab899b33e42f047b91b546f;

      
      startSignal = 1;
      PTorCT = PT;
      // #(period);
      // startSignal = 0;
      // #(period);

      waitReady();

      if(PTorCT == outPTorCT)
        $display("CT == PT");
      else begin
        $display($time);
        $display("CT = %032x", PTorCT);
        $display("PT = %032x", outPTorCT);
      end
    end
  endtask

  task init;
    begin
      clk = 0;
      startSignal = 0;
      key = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    end
  endtask

  task restart;
    begin
      reset = 0;
      #(period);
      reset = 1;
    end
  endtask

  task waitReady;
    begin  
      while(!tbReady)
        begin
          //$display("Waiting");
          #period;
        end
    end
  endtask

  initial begin
    init();
    restart();
    testEncryption();
  end

endmodule