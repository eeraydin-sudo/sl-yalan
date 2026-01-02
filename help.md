# Bullshit (Yalan) LSL Script Analizi ve Kullanım Kılavuzu

Bu doküman, `BullshitCore.lsl` scriptinin çalışma prensiplerini, teknik detaylarını ve oyun mekaniklerini açıklamaktadır.

## 📋 Genel Bakış

`BullshitCore.lsl`, Second Life içinde harici bir sunucuya ihtiyaç duymadan çalışan, %100 LSL tabanlı bir kart oyunu motorudur. Oyun, oyuncuların dürüstlük ve blöf yeteneklerini test eden klasik "Bullshit" (veya Cheat) oyununu simüle eder.

---

## 🚀 Temel Özellikler

- **Dinamik Oyuncu Sistemi**: Masaya oturan (Sit) 2-8 oyuncuyu otomatik olarak algılar.
- **Deste Yönetimi**: 52 kartlık desteyi her oyun başında otomatik karıştırır (**Fisher-Yates Shuffle**) ve dağıtır.
- **Gizli El Yönetimi**: Oyuncular kartlarını özel **Dialog Menüleri (Mavi Pencere)** üzerinden yönetir.
- **Blöf Kontrolü**: Atılan her kartın gerçek ve beyan edilen değerini takip eder.
- **Görsel/İşitsel Efektler**: Hovertext bilgilendirmesi, partikül efektleri ve ses geri bildirimleri içerir.

---

## 🛠️ Teknik Çalışma Mantığı

Script, bir **State Machine (Durum Makinesi)** mimarisi üzerine kurulmuştur:

### 1. Durumlar (States)
- **`default`**: Oyuncuların masaya oturmasını bekler. En az 2 kişi olduğunda oyunun başlatılmasına izin verir.
- **`start_game`**: Kartları karıştırır ve oyunculara paylaştırır.
- **`play`**: Sıradaki oyuncunun hamlesini yapmasını ve diğerlerinin itirazlarını bekler.
- **`challenge`**: Bir "Bullshit!" itirazı yapıldığında devreye girer, kartları kontrol eder ve cezayı (yerdeki kartları almayı) uygular.

### 2. Önemli Fonksiyonlar
- **`Shuffle`**: Desteyi randomize eder.
- **`ShowSelectionMenu`**: Oyuncuya elindeki kartlardan seçim yapabileceği bir menü sunar.
- **`DoParticles`**: İtiraz sonuçlarına göre görsel geri bildirim sağlar (Kırmızı: Blöf, Yeşil: Doğru, Altın: Galibiyet).
- **`UpdateHovertext`**: Oyunun anlık durumunu masanın üzerinde gösterir.

---

## �️ Fiziksel Kurulum (Masa ve Oturma Düzeni)

Bu script, Second Life'ın **Linkset** (birbirine bağlı objeler) yapısını kullanarak çalışacak şekilde güncellenmiştir. Sadece bir daire (prim) yeterli değildir; oyuncuların "oturabilmesi" için aşağıdaki yapıyı kurmanız önerilir:

1.  **Ana Masa (Root Prim)**: Masayı temsil eden ana objeniz. Scripti (`BullshitCore.lsl`) bu objenin içine atın.
2.  **Oturma Primleri (Linked Prims)**: Masanın etrafına oyuncu sayısı kadar (maksimum 8) küçük primler (veya görünmez kutular) yerleştirin.
3.  **Linkleme**: Tüm oturma primlerini seçin, en son ana masayı (root) seçin ve **Ctrl + L** ile birbirine bağlayın.
4.  **Sit Target Ayarı**: Her oturma primine basit bir sit-target scripti ile oturma pozisyonunu tanımlamanız yararlı olur.

Script, bu linkset üzerindeki herhangi bir prime oturan avatarları otomatik olarak algılayıp oyuna dahil edecektir.

---

## �🎮 Nasıl Oynanır?

1.  **Katılım**: Masaya oturun. Oyuncu sayısı sağlandığında bir kişi masaya tıklayarak oyunu başlatır.
2.  **Sıra Takibi**: Masadaki yazıda hangi kart değerinin (`Required Rank`) atılması gerektiği yazar. (Örneğin: "Required Rank: 2s").
3.  **Kart Atma**: Sıradaki oyuncu masaya tıklar, elindeki kartlardan 1-4 adet seçer ve "PLAY" butonuna basar.
4.  **İtiraz (Bullshit!)**: Başka bir oyuncu kart attığında, masaya tıklayıp "BULLSHIT!" butonuna basarak itiraz edebilirsiniz.
5.  **Cezalar**: 
    - İtiraz haklıysa (oyuncu blöf yapmışsa), blöf yapan yerdeki tüm kartları alır.
    - İtiraz haksızsa (oyuncu doğru söylemişse), itiraz eden yerdeki tüm kartları alır.
6.  **Kazanma**: Elindeki kartları tamamen bitiren oyuncu oyunu kazanır.

---

## 🔒 Teknik Notlar ve Limitler

- **Hafıza**: LSL script hafıza limitleri nedeniyle oyuncu elleri metin (`string`) olarak saklanır.
- **Menzil**: Dialog menüleri ve bölge içi mesajlar (`llShout`) 100 metrelik bir alanı kapsar.
- **Kimlik Doğrulama**: Oyuncu tespiti `llAvatarOnSitTarget` ile sit-target üzerinden yapılır.

---

