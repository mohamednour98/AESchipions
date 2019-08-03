module InvSubBox(
  beforeSub[31:0],
  afterSub[31:0]
);

  wire [7:0] invBox[0:255];

  assign afterSub[31 : 24] = invBox[beforeSub[31 : 24]];
  assign afterSub[23 : 16] = invBox[beforeSub[23 : 16]];
  assign afterSub[15 : 08] = invBox[beforeSub[15 : 08]];
  assign afterSub[07 : 00] = invBox[beforeSub[07 : 00]];

  assign invBox[8'h00] = 8'h52;
  assign invBox[8'h01] = 8'h09;
  assign invBox[8'h02] = 8'h6a;
  assign invBox[8'h03] = 8'hd5;
  assign invBox[8'h04] = 8'h30;
  assign invBox[8'h05] = 8'h36;
  assign invBox[8'h06] = 8'ha5;
  assign invBox[8'h07] = 8'h38;
  assign invBox[8'h08] = 8'hbf;
  assign invBox[8'h09] = 8'h40;
  assign invBox[8'h0a] = 8'ha3;
  assign invBox[8'h0b] = 8'h9e;
  assign invBox[8'h0c] = 8'h81;
  assign invBox[8'h0d] = 8'hf3;
  assign invBox[8'h0e] = 8'hd7;
  assign invBox[8'h0f] = 8'hfb;
  assign invBox[8'h10] = 8'h7c;
  assign invBox[8'h11] = 8'he3;
  assign invBox[8'h12] = 8'h39;
  assign invBox[8'h13] = 8'h82;
  assign invBox[8'h14] = 8'h9b;
  assign invBox[8'h15] = 8'h2f;
  assign invBox[8'h16] = 8'hff;
  assign invBox[8'h17] = 8'h87;
  assign invBox[8'h18] = 8'h34;
  assign invBox[8'h19] = 8'h8e;
  assign invBox[8'h1a] = 8'h43;
  assign invBox[8'h1b] = 8'h44;
  assign invBox[8'h1c] = 8'hc4;
  assign invBox[8'h1d] = 8'hde;
  assign invBox[8'h1e] = 8'he9;
  assign invBox[8'h1f] = 8'hcb;
  assign invBox[8'h20] = 8'h54;
  assign invBox[8'h21] = 8'h7b;
  assign invBox[8'h22] = 8'h94;
  assign invBox[8'h23] = 8'h32;
  assign invBox[8'h24] = 8'ha6;
  assign invBox[8'h25] = 8'hc2;
  assign invBox[8'h26] = 8'h23;
  assign invBox[8'h27] = 8'h3d;
  assign invBox[8'h28] = 8'hee;
  assign invBox[8'h29] = 8'h4c;
  assign invBox[8'h2a] = 8'h95;
  assign invBox[8'h2b] = 8'h0b;
  assign invBox[8'h2c] = 8'h42;
  assign invBox[8'h2d] = 8'hfa;
  assign invBox[8'h2e] = 8'hc3;
  assign invBox[8'h2f] = 8'h4e;
  assign invBox[8'h30] = 8'h08;
  assign invBox[8'h31] = 8'h2e;
  assign invBox[8'h32] = 8'ha1;
  assign invBox[8'h33] = 8'h66;
  assign invBox[8'h34] = 8'h28;
  assign invBox[8'h35] = 8'hd9;
  assign invBox[8'h36] = 8'h24;
  assign invBox[8'h37] = 8'hb2;
  assign invBox[8'h38] = 8'h76;
  assign invBox[8'h39] = 8'h5b;
  assign invBox[8'h3a] = 8'ha2;
  assign invBox[8'h3b] = 8'h49;
  assign invBox[8'h3c] = 8'h6d;
  assign invBox[8'h3d] = 8'h8b;
  assign invBox[8'h3e] = 8'hd1;
  assign invBox[8'h3f] = 8'h25;
  assign invBox[8'h40] = 8'h72;
  assign invBox[8'h41] = 8'hf8;
  assign invBox[8'h42] = 8'hf6;
  assign invBox[8'h43] = 8'h64;
  assign invBox[8'h44] = 8'h86;
  assign invBox[8'h45] = 8'h68;
  assign invBox[8'h46] = 8'h98;
  assign invBox[8'h47] = 8'h16;
  assign invBox[8'h48] = 8'hd4;
  assign invBox[8'h49] = 8'ha4;
  assign invBox[8'h4a] = 8'h5c;
  assign invBox[8'h4b] = 8'hcc;
  assign invBox[8'h4c] = 8'h5d;
  assign invBox[8'h4d] = 8'h65;
  assign invBox[8'h4e] = 8'hb6;
  assign invBox[8'h4f] = 8'h92;
  assign invBox[8'h50] = 8'h6c;
  assign invBox[8'h51] = 8'h70;
  assign invBox[8'h52] = 8'h48;
  assign invBox[8'h53] = 8'h50;
  assign invBox[8'h54] = 8'hfd;
  assign invBox[8'h55] = 8'hed;
  assign invBox[8'h56] = 8'hb9;
  assign invBox[8'h57] = 8'hda;
  assign invBox[8'h58] = 8'h5e;
  assign invBox[8'h59] = 8'h15;
  assign invBox[8'h5a] = 8'h46;
  assign invBox[8'h5b] = 8'h57;
  assign invBox[8'h5c] = 8'ha7;
  assign invBox[8'h5d] = 8'h8d;
  assign invBox[8'h5e] = 8'h9d;
  assign invBox[8'h5f] = 8'h84;
  assign invBox[8'h60] = 8'h90;
  assign invBox[8'h61] = 8'hd8;
  assign invBox[8'h62] = 8'hab;
  assign invBox[8'h63] = 8'h00;
  assign invBox[8'h64] = 8'h8c;
  assign invBox[8'h65] = 8'hbc;
  assign invBox[8'h66] = 8'hd3;
  assign invBox[8'h67] = 8'h0a;
  assign invBox[8'h68] = 8'hf7;
  assign invBox[8'h69] = 8'he4;
  assign invBox[8'h6a] = 8'h58;
  assign invBox[8'h6b] = 8'h05;
  assign invBox[8'h6c] = 8'hb8;
  assign invBox[8'h6d] = 8'hb3;
  assign invBox[8'h6e] = 8'h45;
  assign invBox[8'h6f] = 8'h06;
  assign invBox[8'h70] = 8'hd0;
  assign invBox[8'h71] = 8'h2c;
  assign invBox[8'h72] = 8'h1e;
  assign invBox[8'h73] = 8'h8f;
  assign invBox[8'h74] = 8'hca;
  assign invBox[8'h75] = 8'h3f;
  assign invBox[8'h76] = 8'h0f;
  assign invBox[8'h77] = 8'h02;
  assign invBox[8'h78] = 8'hc1;
  assign invBox[8'h79] = 8'haf;
  assign invBox[8'h7a] = 8'hbd;
  assign invBox[8'h7b] = 8'h03;
  assign invBox[8'h7c] = 8'h01;
  assign invBox[8'h7d] = 8'h13;
  assign invBox[8'h7e] = 8'h8a;
  assign invBox[8'h7f] = 8'h6b;
  assign invBox[8'h80] = 8'h3a;
  assign invBox[8'h81] = 8'h91;
  assign invBox[8'h82] = 8'h11;
  assign invBox[8'h83] = 8'h41;
  assign invBox[8'h84] = 8'h4f;
  assign invBox[8'h85] = 8'h67;
  assign invBox[8'h86] = 8'hdc;
  assign invBox[8'h87] = 8'hea;
  assign invBox[8'h88] = 8'h97;
  assign invBox[8'h89] = 8'hf2;
  assign invBox[8'h8a] = 8'hcf;
  assign invBox[8'h8b] = 8'hce;
  assign invBox[8'h8c] = 8'hf0;
  assign invBox[8'h8d] = 8'hb4;
  assign invBox[8'h8e] = 8'he6;
  assign invBox[8'h8f] = 8'h73;
  assign invBox[8'h90] = 8'h96;
  assign invBox[8'h91] = 8'hac;
  assign invBox[8'h92] = 8'h74;
  assign invBox[8'h93] = 8'h22;
  assign invBox[8'h94] = 8'he7;
  assign invBox[8'h95] = 8'had;
  assign invBox[8'h96] = 8'h35;
  assign invBox[8'h97] = 8'h85;
  assign invBox[8'h98] = 8'he2;
  assign invBox[8'h99] = 8'hf9;
  assign invBox[8'h9a] = 8'h37;
  assign invBox[8'h9b] = 8'he8;
  assign invBox[8'h9c] = 8'h1c;
  assign invBox[8'h9d] = 8'h75;
  assign invBox[8'h9e] = 8'hdf;
  assign invBox[8'h9f] = 8'h6e;
  assign invBox[8'ha0] = 8'h47;
  assign invBox[8'ha1] = 8'hf1;
  assign invBox[8'ha2] = 8'h1a;
  assign invBox[8'ha3] = 8'h71;
  assign invBox[8'ha4] = 8'h1d;
  assign invBox[8'ha5] = 8'h29;
  assign invBox[8'ha6] = 8'hc5;
  assign invBox[8'ha7] = 8'h89;
  assign invBox[8'ha8] = 8'h6f;
  assign invBox[8'ha9] = 8'hb7;
  assign invBox[8'haa] = 8'h62;
  assign invBox[8'hab] = 8'h0e;
  assign invBox[8'hac] = 8'haa;
  assign invBox[8'had] = 8'h18;
  assign invBox[8'hae] = 8'hbe;
  assign invBox[8'haf] = 8'h1b;
  assign invBox[8'hb0] = 8'hfc;
  assign invBox[8'hb1] = 8'h56;
  assign invBox[8'hb2] = 8'h3e;
  assign invBox[8'hb3] = 8'h4b;
  assign invBox[8'hb4] = 8'hc6;
  assign invBox[8'hb5] = 8'hd2;
  assign invBox[8'hb6] = 8'h79;
  assign invBox[8'hb7] = 8'h20;
  assign invBox[8'hb8] = 8'h9a;
  assign invBox[8'hb9] = 8'hdb;
  assign invBox[8'hba] = 8'hc0;
  assign invBox[8'hbb] = 8'hfe;
  assign invBox[8'hbc] = 8'h78;
  assign invBox[8'hbd] = 8'hcd;
  assign invBox[8'hbe] = 8'h5a;
  assign invBox[8'hbf] = 8'hf4;
  assign invBox[8'hc0] = 8'h1f;
  assign invBox[8'hc1] = 8'hdd;
  assign invBox[8'hc2] = 8'ha8;
  assign invBox[8'hc3] = 8'h33;
  assign invBox[8'hc4] = 8'h88;
  assign invBox[8'hc5] = 8'h07;
  assign invBox[8'hc6] = 8'hc7;
  assign invBox[8'hc7] = 8'h31;
  assign invBox[8'hc8] = 8'hb1;
  assign invBox[8'hc9] = 8'h12;
  assign invBox[8'hca] = 8'h10;
  assign invBox[8'hcb] = 8'h59;
  assign invBox[8'hcc] = 8'h27;
  assign invBox[8'hcd] = 8'h80;
  assign invBox[8'hce] = 8'hec;
  assign invBox[8'hcf] = 8'h5f;
  assign invBox[8'hd0] = 8'h60;
  assign invBox[8'hd1] = 8'h51;
  assign invBox[8'hd2] = 8'h7f;
  assign invBox[8'hd3] = 8'ha9;
  assign invBox[8'hd4] = 8'h19;
  assign invBox[8'hd5] = 8'hb5;
  assign invBox[8'hd6] = 8'h4a;
  assign invBox[8'hd7] = 8'h0d;
  assign invBox[8'hd8] = 8'h2d;
  assign invBox[8'hd9] = 8'he5;
  assign invBox[8'hda] = 8'h7a;
  assign invBox[8'hdb] = 8'h9f;
  assign invBox[8'hdc] = 8'h93;
  assign invBox[8'hdd] = 8'hc9;
  assign invBox[8'hde] = 8'h9c;
  assign invBox[8'hdf] = 8'hef;
  assign invBox[8'he0] = 8'ha0;
  assign invBox[8'he1] = 8'he0;
  assign invBox[8'he2] = 8'h3b;
  assign invBox[8'he3] = 8'h4d;
  assign invBox[8'he4] = 8'hae;
  assign invBox[8'he5] = 8'h2a;
  assign invBox[8'he6] = 8'hf5;
  assign invBox[8'he7] = 8'hb0;
  assign invBox[8'he8] = 8'hc8;
  assign invBox[8'he9] = 8'heb;
  assign invBox[8'hea] = 8'hbb;
  assign invBox[8'heb] = 8'h3c;
  assign invBox[8'hec] = 8'h83;
  assign invBox[8'hed] = 8'h53;
  assign invBox[8'hee] = 8'h99;
  assign invBox[8'hef] = 8'h61;
  assign invBox[8'hf0] = 8'h17;
  assign invBox[8'hf1] = 8'h2b;
  assign invBox[8'hf2] = 8'h04;
  assign invBox[8'hf3] = 8'h7e;
  assign invBox[8'hf4] = 8'hba;
  assign invBox[8'hf5] = 8'h77;
  assign invBox[8'hf6] = 8'hd6;
  assign invBox[8'hf7] = 8'h26;
  assign invBox[8'hf8] = 8'he1;
  assign invBox[8'hf9] = 8'h69;
  assign invBox[8'hfa] = 8'h14;
  assign invBox[8'hfb] = 8'h63;
  assign invBox[8'hfc] = 8'h55;
  assign invBox[8'hfd] = 8'h21;
  assign invBox[8'hfe] = 8'h0c;
  assign invBox[8'hff] = 8'h7d;

endmodule