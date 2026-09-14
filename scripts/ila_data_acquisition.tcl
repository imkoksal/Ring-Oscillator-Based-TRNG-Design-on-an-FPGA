# ILA Veri Okuyucu - Kararlı ve Temiz Versiyon

# AYARLAR
set num_captures 70001
set start_index 0
set save_dir "~/csv_design" # CHANGE YOUR SAVING DIRECTORY HERE AND UPDATE IT ON THE C AND PYTHON FILES
set ila_name "hw_ila_1"
set valid_keyword "valid"
set word_keyword "shift_reg_word"

# Çıktı dizini kontrolü
if {![file exists $save_dir]} {
    file mkdir $save_dir
}

# CSV İŞLEYİCİ
proc process_word_csv {raw_file out_file word_kw valid_kw} {
    if {[catch {open $raw_file r} in_fp]} { 
        puts "HATA: Geçici dosya açılamadı: $raw_file"
        return 
    }
    
    gets $in_fp header_line
    set headers [split $header_line ","]
    
    set word_idx -1
    set valid_idx -1
    set idx 0
    
    foreach h $headers {
        if {[string first $word_kw $h] != -1}  { set word_idx $idx }
        if {[string first $valid_kw $h] != -1} { set valid_idx $idx }
        incr idx
    }
    
    if {$valid_idx == -1 || $word_idx == -1} {
        puts "HATA: Aranan sütunlar bulunamadı!"
        puts "Arananlar: Word='$word_kw', Valid='$valid_kw'"
        puts "Mevcut Başlıklar: $headers"
        close $in_fp
        return
    }

    set out_fp [open $out_file w]
    fconfigure $out_fp -buffering full -buffersize 65536
    
    puts $out_fp [lindex $headers $word_idx]
    gets $in_fp radix_line
    
    while {[gets $in_fp line] >= 0} {
        set values [split $line ","]
        set v [string trim [lindex $values $valid_idx]]
        
        if {$v eq "1" || $v eq "1'b1" || $v eq "0x1"} {
            puts $out_fp [lindex $values $word_idx]
        }
    }
    
    close $in_fp
    close $out_fp
}

puts " --- İşlem Başladı ---"

set temp_file "${save_dir}/temp_raw_trng.csv"

for {set i 0} {$i < $num_captures} {incr i} {
    set file_index [expr {$start_index + $i}]
    
    if {$i % 100 == 0} {
        puts "İlerleme: $i / $num_captures (Dosya: iladata${file_index}_word.csv)"
    }

    # 1. ILA tetikle ve bekle
    run_hw_ila -quiet [get_hw_ilas $ila_name]
    wait_on_hw_ila -quiet [get_hw_ilas $ila_name]
    
    # 2. Veriyi donanımdan çek (current_hw_ila_data otomatik güncellenir)
    upload_hw_ila_data -quiet [get_hw_ilas $ila_name]

    # 3. Geçici dosyaya yaz
    write_hw_ila_data -force -quiet -csv_file $temp_file [current_hw_ila_data]

    # 4. Word dosyasını filtreleyip oluştur
    set word_final "${save_dir}/iladata${file_index}_word.csv"
    process_word_csv $temp_file $word_final $word_keyword $valid_keyword
}

# Geçici dosyayı sil
if {[file exists $temp_file]} { file delete -force $temp_file }

puts "--- İşlem Tamamlandı ---"
