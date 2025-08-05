# SQL-satis-analizi
# 📊 Müşteri ve Sipariş Analizi | SQL + Excel

Bu proje, müşteri bilgileri ve sipariş verileri üzerinden **SQL kullanılarak yapılan veri analizlerini** içermektedir. Amaç; müşteri segmentasyonu, sipariş davranışları ve temel iş zekası göstergeleri üretmektir.

---

## 🔍 Proje Amacı

- Müşteri yaş gruplarını belirlemek  
- Satışlara göre müşteri segmentleri oluşturmak  
- Sipariş tarihlerini kullanarak zaman bazlı analiz yapmak  
- Ortalama sipariş değeri ve aylık harcama hesaplamak

---

## 📁 Dosyalar

| Dosya Adı             | Açıklama                                      |
|----------------------|-----------------------------------------------|
| `veri.xlsx`          | Müşteri ve sipariş verilerini içeren Excel dosyası |
| `sql_queries.sql`    | Kullanılan tüm SQL sorgularını içerir         |
| `dashboard_gorsel.png` | power bı ekran görüntüsü   |

---

## 🧾 Kullanılan SQL Sorguları (Örnek)

### 1. Yaş Gruplarını Oluşturma

```sql
SELECT *,
  CASE 
    WHEN AGE < 30 THEN 'Under 30'
    WHEN AGE BETWEEN 30 AND 39 THEN '30-39'
    WHEN AGE BETWEEN 40 AND 49 THEN '40-49'
    ELSE '50 and Above'
  END AS AGE_GROUP
FROM customers;
