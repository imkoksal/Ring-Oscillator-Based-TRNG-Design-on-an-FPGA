import csv
import os

# KLASÖR YOLLARI
klasor_yolu = r'/home/mustafa/Documents/bitirme/digdes/deneme/den5/csv_design'
cikis_klasoru = r'/home/mustafa/Documents/bitirme/digdes/deneme/den5/birlesmis_cikis'

# Probes and their nominal bit widths
SUFFIX_WIDTHS = {
    'bit': 1,
    'byte': 8,
    'hword': 16,
    'word': 32,
}

def dosyalari_birlestir():
    try:
        baslangic = int(input("Başlangıç dosya numarasını girin (Örn: 100): "))
        bitis = int(input("Bitiş dosya numarasını girin (Örn: 150): "))
        secilen_suffix = 'word'
    except ValueError:
        print("HATA: Lütfen sayısal değerleri doğru girin.")
        return

    # Kullanıcı boş geçerse varsayılan olarak 'bit' kabul et
    if not secilen_suffix:
        secilen_suffix = 'word'

    if secilen_suffix not in SUFFIX_WIDTHS:
        print(f"HATA: Geçersiz probe tipi. Lütfen şunlardan birini girin: {list(SUFFIX_WIDTHS.keys())}")
        return

    nominal_width = SUFFIX_WIDTHS[secilen_suffix]
    birlesik_ikili_veri = []
    islenen_dosya_sayisi = 0

    print(f"\n{baslangic} ile {bitis} arasındaki '{secilen_suffix}' dosyaları birleştiriliyor...\n")

    for i in range(baslangic, bitis + 1):
        dosya_adi_csv = f"iladata{i}_{secilen_suffix}.csv"
        giris_dosyasi = os.path.join(klasor_yolu, dosya_adi_csv)

        if not os.path.exists(giris_dosyasi):
            print(f"  Atlandı: {dosya_adi_csv} bulunamadı.")
            continue

        try:
            with open(giris_dosyasi, 'r', newline='', encoding='utf-8') as f:
                reader = csv.reader(f)
                for row in reader:
                    if not row:
                        continue
                    hex_deger = row[0].strip()
                    try:
                        if hex_deger.startswith('0x') or hex_deger.startswith('0X'):
                            sayi = int(hex_deger, 16)
                        else:
                            sayi = int(hex_deger, 16)

                        bitlen = sayi.bit_length()
                        width = nominal_width if nominal_width > bitlen else max(nominal_width, bitlen, 1)
                        birlesik_ikili_veri.append(f"{sayi:0{width}b}")
                    except ValueError:
                        # Başlık (header) veya geçersiz satırları atla
                        continue
            islenen_dosya_sayisi += 1
        except Exception as e:
            print(f"[{dosya_adi_csv}] okunurken hata oluştu: {e}")

    # Bütün listeyi tek bir string'e dönüştür
    nihai_string = "".join(birlesik_ikili_veri)
    toplam_bit = len(nihai_string)

    if toplam_bit > 0:
        if not os.path.exists(cikis_klasoru):
            os.makedirs(cikis_klasoru, exist_ok=True)

        # Yeni dosyanın adını otomatik olarak belirle
        cikis_dosyasi_adi = f"BİRLESİK_VERİ_{secilen_suffix}_{baslangic}den_{bitis}e.txt"
        cikis_dosyasi = os.path.join(cikis_klasoru, cikis_dosyasi_adi)
        
        with open(cikis_dosyasi, 'w', encoding='utf-8') as f:
            f.write(nihai_string)

        print("\n" + "=" * 70)
        print("BİRLEŞTİRME İŞLEMİ TAMAMLANDI")
        print("=" * 70)
        print(f"Başarıyla birleştirilen dosya sayısı : {islenen_dosya_sayisi}")
        print(f"Elde edilen TOPLAM BİT SAYISI        : {toplam_bit:,} bit")
        print(f"Oluşturulan Çıktı Dosyası            : {cikis_dosyasi_adi}")
        print("-" * 70)
        
        # NIST Limitleri Kontrolü
        if toplam_bit >= 1000000:
            print(" DURUM: MÜKEMMEL! 1.000.000 bit barajını aştınız.")
            print("        Artık Random Excursions dahil tüm 14 NIST testini uygulayabilirsiniz.")
        elif toplam_bit >= 387840:
            print(" DURUM: İYİ. 387.840 bit barajını aştınız.")
            print("        Universal testine girebilirsiniz, ancak Random Excursions için eksik veriniz var.")
        else:
            print(" DURUM: UYARI. 387 bin barajının altındasınız.")
            print("        En ağır karmaşıklık testleri (Matrix Rank, Universal) için veri toplamaya devam etmelisiniz.")
        print("=" * 70)
    else:
        print("\nHATA: Birleştirilecek geçerli veri bulunamadı. Klasör yolunu veya dosya numaralarını kontrol edin.")

if __name__ == "__main__":
    dosyalari_birlestir()
