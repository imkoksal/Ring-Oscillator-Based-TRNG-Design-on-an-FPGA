## ============================================================
## Zynq-7020 Kusursuz Fiziksel İzolasyon (GENİŞLETİLMİŞ KUTULAR)
## Kutu Boyutları: 8x10 Slice (Kapasite: ~320 LUT)
## ============================================================
## ============================================================
## PYNQ-Z1 (Zynq-7020) Pin Constraints
## ============================================================

## 125 MHz Dahili Saat
set_property PACKAGE_PIN H16 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

## Switches & Buttons
set_property PACKAGE_PIN M20 [get_ports en]
set_property IOSTANDARD LVCMOS33 [get_ports en]

set_property PACKAGE_PIN D19 [get_ports rst]
set_property IOSTANDARD LVCMOS33 [get_ports rst]

## LEDs (Çıkışlar)
# set_property PACKAGE_PIN R14 [get_ports out]
## set_property IOSTANDARD LVCMOS33 [get_ports out]

## set_property PACKAGE_PIN P14 [get_ports out_inv]
## set_property IOSTANDARD LVCMOS33 [get_ports out_inv]

## ============================================================
## Clock & Combinatorial Loop Constraints
## ============================================================
set_false_path -from [get_ports {en rst}]

## Eski dar filtre yerine, ro_row hiyerarşisi altındaki "tüm" kabloları kapsayan geniş filtre:
set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets -hierarchical -filter {NAME =~ *ro_row*}]
set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets -hierarchical -filter {NAME =~ *ro_inst*}]
set_property ALLOW_COMBINATORIAL_LOOPS TRUE [get_nets -hierarchical -filter {NAME =~ *fred_gen*}]

set_property SEVERITY Warning [get_drc_checks LUTLP-1]

set_false_path -to [get_pins -hierarchical -filter {NAME =~ *ro_row*.ro_inst/sample_reg/D}]


# --- ROW 0 (Y: 0 - 9) ---
create_pblock pblock_ro_0
add_cells_to_pblock [get_pblocks pblock_ro_0] [get_cells {ro_row[0].ro_inst}]
resize_pblock [get_pblocks pblock_ro_0] -add {SLICE_X22Y0:SLICE_X29Y9}
set_property CONTAIN_ROUTING TRUE [get_pblocks pblock_ro_0]
set_property EXCLUDE_PLACEMENT TRUE [get_pblocks pblock_ro_0]

create_pblock pblock_ro_1
add_cells_to_pblock [get_pblocks pblock_ro_1] [get_cells {ro_row[1].ro_inst}]
resize_pblock [get_pblocks pblock_ro_1] -add {SLICE_X50Y0:SLICE_X57Y9}
set_property CONTAIN_ROUTING TRUE [get_pblocks pblock_ro_1]
set_property EXCLUDE_PLACEMENT TRUE [get_pblocks pblock_ro_1]

create_pblock pblock_ro_2
add_cells_to_pblock [get_pblocks pblock_ro_2] [get_cells {ro_row[2].ro_inst}]
resize_pblock [get_pblocks pblock_ro_2] -add {SLICE_X78Y0:SLICE_X85Y9}
set_property CONTAIN_ROUTING TRUE [get_pblocks pblock_ro_2]
set_property EXCLUDE_PLACEMENT TRUE [get_pblocks pblock_ro_2]

create_pblock pblock_ro_3
add_cells_to_pblock [get_pblocks pblock_ro_3] [get_cells {ro_row[3].ro_inst}]
resize_pblock [get_pblocks pblock_ro_3] -add {SLICE_X104Y0:SLICE_X111Y9}
set_property CONTAIN_ROUTING TRUE [get_pblocks pblock_ro_3]
set_property EXCLUDE_PLACEMENT TRUE [get_pblocks pblock_ro_3]

# --- ROW 1 (Y: 20 - 29) ---
create_pblock pblock_ro_4
add_cells_to_pblock [get_pblocks pblock_ro_4] [get_cells {ro_row[4].ro_inst}]
resize_pblock [get_pblocks pblock_ro_4] -add {SLICE_X22Y20:SLICE_X29Y29}
set_property CONTAIN_ROUTING TRUE [get_pblocks pblock_ro_4]
set_property EXCLUDE_PLACEMENT TRUE [get_pblocks pblock_ro_4]

create_pblock pblock_ro_5
add_cells_to_pblock [get_pblocks pblock_ro_5] [get_cells {ro_row[5].ro_inst}]
resize_pblock [get_pblocks pblock_ro_5] -add {SLICE_X50Y20:SLICE_X57Y29}
set_property CONTAIN_ROUTING TRUE [get_pblocks pblock_ro_5]
set_property EXCLUDE_PLACEMENT TRUE [get_pblocks pblock_ro_5]

create_pblock pblock_ro_6
add_cells_to_pblock [get_pblocks pblock_ro_6] [get_cells {ro_row[6].ro_inst}]
resize_pblock [get_pblocks pblock_ro_6] -add {SLICE_X78Y20:SLICE_X85Y29}
set_property CONTAIN_ROUTING TRUE [get_pblocks pblock_ro_6]
set_property EXCLUDE_PLACEMENT TRUE [get_pblocks pblock_ro_6]

create_pblock pblock_ro_7
add_cells_to_pblock [get_pblocks pblock_ro_7] [get_cells {ro_row[7].ro_inst}]
resize_pblock [get_pblocks pblock_ro_7] -add {SLICE_X104Y20:SLICE_X111Y29}
set_property CONTAIN_ROUTING TRUE [get_pblocks pblock_ro_7]
set_property EXCLUDE_PLACEMENT TRUE [get_pblocks pblock_ro_7]

# --- ROW 2 (Y: 40 - 49) ---
create_pblock pblock_ro_8
add_cells_to_pblock [get_pblocks pblock_ro_8] [get_cells {ro_row[8].ro_inst}]
resize_pblock [get_pblocks pblock_ro_8] -add {SLICE_X22Y40:SLICE_X29Y49}
set_property CONTAIN_ROUTING TRUE [get_pblocks pblock_ro_8]
set_property EXCLUDE_PLACEMENT TRUE [get_pblocks pblock_ro_8]

create_pblock pblock_ro_9
add_cells_to_pblock [get_pblocks pblock_ro_9] [get_cells {ro_row[9].ro_inst}]
resize_pblock [get_pblocks pblock_ro_9] -add {SLICE_X50Y40:SLICE_X57Y49}
set_property CONTAIN_ROUTING TRUE [get_pblocks pblock_ro_9]
set_property EXCLUDE_PLACEMENT TRUE [get_pblocks pblock_ro_9]

create_pblock pblock_ro_10
add_cells_to_pblock [get_pblocks pblock_ro_10] [get_cells {ro_row[10].ro_inst}]
resize_pblock [get_pblocks pblock_ro_10] -add {SLICE_X78Y40:SLICE_X85Y49}
set_property CONTAIN_ROUTING TRUE [get_pblocks pblock_ro_10]
set_property EXCLUDE_PLACEMENT TRUE [get_pblocks pblock_ro_10]

create_pblock pblock_ro_11
add_cells_to_pblock [get_pblocks pblock_ro_11] [get_cells {ro_row[11].ro_inst}]
resize_pblock [get_pblocks pblock_ro_11] -add {SLICE_X104Y40:SLICE_X111Y49}
set_property CONTAIN_ROUTING TRUE [get_pblocks pblock_ro_11]
set_property EXCLUDE_PLACEMENT TRUE [get_pblocks pblock_ro_11]

# --- ROW 3 (Y: 60 - 69) ---
create_pblock pblock_ro_12
add_cells_to_pblock [get_pblocks pblock_ro_12] [get_cells {ro_row[12].ro_inst}]
resize_pblock [get_pblocks pblock_ro_12] -add {SLICE_X22Y60:SLICE_X29Y69}
set_property CONTAIN_ROUTING TRUE [get_pblocks pblock_ro_12]
set_property EXCLUDE_PLACEMENT TRUE [get_pblocks pblock_ro_12]

create_pblock pblock_ro_13
add_cells_to_pblock [get_pblocks pblock_ro_13] [get_cells {ro_row[13].ro_inst}]
resize_pblock [get_pblocks pblock_ro_13] -add {SLICE_X50Y60:SLICE_X57Y69}
set_property CONTAIN_ROUTING TRUE [get_pblocks pblock_ro_13]
set_property EXCLUDE_PLACEMENT TRUE [get_pblocks pblock_ro_13]

create_pblock pblock_ro_14
add_cells_to_pblock [get_pblocks pblock_ro_14] [get_cells {ro_row[14].ro_inst}]
resize_pblock [get_pblocks pblock_ro_14] -add {SLICE_X78Y60:SLICE_X85Y69}
set_property CONTAIN_ROUTING TRUE [get_pblocks pblock_ro_14]
set_property EXCLUDE_PLACEMENT TRUE [get_pblocks pblock_ro_14]

create_pblock pblock_ro_15
add_cells_to_pblock [get_pblocks pblock_ro_15] [get_cells {ro_row[15].ro_inst}]
resize_pblock [get_pblocks pblock_ro_15] -add {SLICE_X104Y60:SLICE_X111Y69}
set_property CONTAIN_ROUTING TRUE [get_pblocks pblock_ro_15]
set_property EXCLUDE_PLACEMENT TRUE [get_pblocks pblock_ro_15]

# --- ROW 4 (Y: 80 - 89) ---
create_pblock pblock_ro_16
add_cells_to_pblock [get_pblocks pblock_ro_16] [get_cells {ro_row[16].ro_inst}]
resize_pblock [get_pblocks pblock_ro_16] -add {SLICE_X22Y80:SLICE_X29Y89}
set_property CONTAIN_ROUTING TRUE [get_pblocks pblock_ro_16]
set_property EXCLUDE_PLACEMENT TRUE [get_pblocks pblock_ro_16]

create_pblock pblock_ro_17
add_cells_to_pblock [get_pblocks pblock_ro_17] [get_cells {ro_row[17].ro_inst}]
resize_pblock [get_pblocks pblock_ro_17] -add {SLICE_X50Y80:SLICE_X57Y89}
set_property CONTAIN_ROUTING TRUE [get_pblocks pblock_ro_17]
set_property EXCLUDE_PLACEMENT TRUE [get_pblocks pblock_ro_17]

create_pblock pblock_ro_18
add_cells_to_pblock [get_pblocks pblock_ro_18] [get_cells {ro_row[18].ro_inst}]
resize_pblock [get_pblocks pblock_ro_18] -add {SLICE_X78Y80:SLICE_X85Y89}
set_property CONTAIN_ROUTING TRUE [get_pblocks pblock_ro_18]
set_property EXCLUDE_PLACEMENT TRUE [get_pblocks pblock_ro_18]

create_pblock pblock_ro_19
add_cells_to_pblock [get_pblocks pblock_ro_19] [get_cells {ro_row[19].ro_inst}]
resize_pblock [get_pblocks pblock_ro_19] -add {SLICE_X104Y80:SLICE_X111Y89}
set_property CONTAIN_ROUTING TRUE [get_pblocks pblock_ro_19]
set_property EXCLUDE_PLACEMENT TRUE [get_pblocks pblock_ro_19]

# --- ROW 5 (Y: 100 - 109) ---
create_pblock pblock_ro_20
add_cells_to_pblock [get_pblocks pblock_ro_20] [get_cells {ro_row[20].ro_inst}]
resize_pblock [get_pblocks pblock_ro_20] -add {SLICE_X22Y100:SLICE_X29Y109}
set_property CONTAIN_ROUTING TRUE [get_pblocks pblock_ro_20]
set_property EXCLUDE_PLACEMENT TRUE [get_pblocks pblock_ro_20]

create_pblock pblock_ro_21
add_cells_to_pblock [get_pblocks pblock_ro_21] [get_cells {ro_row[21].ro_inst}]
resize_pblock [get_pblocks pblock_ro_21] -add {SLICE_X50Y100:SLICE_X57Y109}
set_property CONTAIN_ROUTING TRUE [get_pblocks pblock_ro_21]
set_property EXCLUDE_PLACEMENT TRUE [get_pblocks pblock_ro_21]

create_pblock pblock_ro_22
add_cells_to_pblock [get_pblocks pblock_ro_22] [get_cells {ro_row[22].ro_inst}]
resize_pblock [get_pblocks pblock_ro_22] -add {SLICE_X78Y100:SLICE_X85Y109}
set_property CONTAIN_ROUTING TRUE [get_pblocks pblock_ro_22]
set_property EXCLUDE_PLACEMENT TRUE [get_pblocks pblock_ro_22]

create_pblock pblock_ro_23
add_cells_to_pblock [get_pblocks pblock_ro_23] [get_cells {ro_row[23].ro_inst}]
resize_pblock [get_pblocks pblock_ro_23] -add {SLICE_X104Y100:SLICE_X111Y109}
set_property CONTAIN_ROUTING TRUE [get_pblocks pblock_ro_23]
set_property EXCLUDE_PLACEMENT TRUE [get_pblocks pblock_ro_23]

# --- ROW 6 (Y: 120 - 129) ---
create_pblock pblock_ro_24
add_cells_to_pblock [get_pblocks pblock_ro_24] [get_cells {ro_row[24].ro_inst}]
resize_pblock [get_pblocks pblock_ro_24] -add {SLICE_X22Y120:SLICE_X29Y129}
set_property CONTAIN_ROUTING TRUE [get_pblocks pblock_ro_24]
set_property EXCLUDE_PLACEMENT TRUE [get_pblocks pblock_ro_24]

create_pblock pblock_ro_25
add_cells_to_pblock [get_pblocks pblock_ro_25] [get_cells {ro_row[25].ro_inst}]
resize_pblock [get_pblocks pblock_ro_25] -add {SLICE_X50Y120:SLICE_X57Y129}
set_property CONTAIN_ROUTING TRUE [get_pblocks pblock_ro_25]
set_property EXCLUDE_PLACEMENT TRUE [get_pblocks pblock_ro_25]

create_pblock pblock_ro_26
add_cells_to_pblock [get_pblocks pblock_ro_26] [get_cells {ro_row[26].ro_inst}]
resize_pblock [get_pblocks pblock_ro_26] -add {SLICE_X78Y120:SLICE_X85Y129}
set_property CONTAIN_ROUTING TRUE [get_pblocks pblock_ro_26]
set_property EXCLUDE_PLACEMENT TRUE [get_pblocks pblock_ro_26]

create_pblock pblock_ro_27
add_cells_to_pblock [get_pblocks pblock_ro_27] [get_cells {ro_row[27].ro_inst}]
resize_pblock [get_pblocks pblock_ro_27] -add {SLICE_X104Y120:SLICE_X111Y129}
set_property CONTAIN_ROUTING TRUE [get_pblocks pblock_ro_27]
set_property EXCLUDE_PLACEMENT TRUE [get_pblocks pblock_ro_27]

# --- ROW 7 (Y: 140 - 149) En Üst (Sadece 3 Adet) ---
create_pblock pblock_ro_28
add_cells_to_pblock [get_pblocks pblock_ro_28] [get_cells {ro_row[28].ro_inst}]
resize_pblock [get_pblocks pblock_ro_28] -add {SLICE_X22Y140:SLICE_X29Y149}
set_property CONTAIN_ROUTING TRUE [get_pblocks pblock_ro_28]
set_property EXCLUDE_PLACEMENT TRUE [get_pblocks pblock_ro_28]

create_pblock pblock_ro_29
add_cells_to_pblock [get_pblocks pblock_ro_29] [get_cells {ro_row[29].ro_inst}]
resize_pblock [get_pblocks pblock_ro_29] -add {SLICE_X50Y140:SLICE_X57Y149}
set_property CONTAIN_ROUTING TRUE [get_pblocks pblock_ro_29]
set_property EXCLUDE_PLACEMENT TRUE [get_pblocks pblock_ro_29]

create_pblock pblock_ro_30
add_cells_to_pblock [get_pblocks pblock_ro_30] [get_cells {ro_row[30].ro_inst}]
resize_pblock [get_pblocks pblock_ro_30] -add {SLICE_X78Y140:SLICE_X85Y149}
set_property CONTAIN_ROUTING TRUE [get_pblocks pblock_ro_30]
set_property EXCLUDE_PLACEMENT TRUE [get_pblocks pblock_ro_30]