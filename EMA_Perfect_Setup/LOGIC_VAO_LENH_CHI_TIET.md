# PHÂN TÍCH LOGIC VÀO LỆNH CHI TIẾT

## 📋 Tổng quan Logic Vào Lệnh

Bot này sử dụng hệ thống **EMA Multi-Timeframe** kết hợp với **RSI** và các bộ lọc nâng cao để tìm tín hiệu vào lệnh. Logic được thực hiện qua 2 hàm chính:

1. **`OnTick()`** - Phát hiện khi nến đóng và gọi xử lý tín hiệu
2. **`ProcessSignalOnBarClose()`** - Xử lý tín hiệu chính với các bộ lọc
3. **`GetEntrySignal()`** - Kiểm tra điều kiện vào lệnh chi tiết

---

## 🔄 Luồng Xử Lý Tín Hiệu

### Bước 1: OnTick() - Phát hiện nến đóng
- Bot kiểm tra tất cả các symbol mỗi khi có tick mới
- Chỉ xử lý khi **nến đã đóng** (bar 1) để tránh repaint
- Đánh dấu nến đã xử lý để tránh xử lý trùng lặp
- Gọi hàm `ProcessSignalOnBarClose()` để xử lý tín hiệu

### Bước 2: ProcessSignalOnBarClose() - Xử lý tín hiệu
- Kiểm tra giới hạn số tín hiệu mỗi ngày
- Kiểm tra spread (phải ≤ InpMaxSpread)
- Gọi `GetEntrySignal()` để kiểm tra điều kiện vào lệnh
- Validate tín hiệu qua Signal Validator
- Kiểm tra Noise Filters (nếu bật)
- Kiểm tra Fakeout Detection (nếu bật)
- Tính điểm (scoring) nếu tất cả điều kiện đều đúng
- Chỉ cảnh báo khi điểm ≥ 85 (Perfect Setup)

### Bước 3: GetEntrySignal() - Kiểm tra điều kiện chi tiết
- Kiểm tra 8 điều kiện BUY hoặc 8 điều kiện SELL
- Trả về: 0 (không có tín hiệu), 1 (BUY), -1 (SELL)

---

## ✅ ĐIỀU KIỆN KÍCH HOẠT LỆNH BUY

Bot sẽ kích hoạt tín hiệu **BUY** khi **TẤT CẢ** 8 điều kiện sau đều đúng:

### Điều kiện BUY 1: H1 - Giá phải ở trên EMA 50
- **Kiểm tra**: Giá đóng cửa (bar 1) > EMA 50 H1
- **Mục đích**: Xác nhận xu hướng tăng trên khung thời gian lớn (H1)
- **Logic**: Nếu giá <= EMA 50 H1 → Không phải tín hiệu BUY

### Điều kiện BUY 2: H1 - Các EMA phải sắp xếp theo thứ tự tăng
- **Kiểm tra**: EMA 9 H1 > EMA 21 H1 > EMA 50 H1
- **Mục đích**: Xác nhận xu hướng tăng mạnh trên H1
- **Logic**: EMA phải "mở rộng" theo hướng tăng (fast > medium > slow)

### Điều kiện BUY 3: M5 - Các EMA phải sắp xếp theo thứ tự tăng
- **Kiểm tra**: EMA 9 M5 > EMA 21 M5 > EMA 50 M5
- **Mục đích**: Xác nhận xu hướng tăng trên khung thời gian tín hiệu (M5)
- **Logic**: EMA phải "mở rộng" theo hướng tăng trên M5

### Điều kiện BUY 4: M5 - EMA 9 phải cắt lên trên EMA 21
- **Kiểm tra**: 
  - EMA 9 hiện tại (bar 1) > EMA 21 hiện tại (bar 1)
  - EMA 9 nến trước (bar 2) ≤ EMA 21 nến trước (bar 2)
- **Mục đích**: Xác nhận tín hiệu mua mới xuất hiện (crossover)
- **Logic**: Đây là tín hiệu động - EMA 9 vừa cắt lên EMA 21

### Điều kiện BUY 5: M5 - Nến đã đóng phải đóng trên EMA 9
- **Kiểm tra**: Giá đóng cửa (bar 1) > EMA 9 M5
- **Mục đích**: Xác nhận momentum tăng mạnh
- **Logic**: Giá phải đóng trên đường EMA nhanh nhất

### Điều kiện BUY 6: M5 - Giá, EMA 9, và EMA 21 đều phải ở trên EMA 50
- **Kiểm tra**: 
  - Giá > EMA 50 M5
  - EMA 9 > EMA 50 M5
  - EMA 21 > EMA 50 M5
- **Mục đích**: Xác nhận vị trí giá và các EMA đều trong vùng tăng
- **Logic**: Tất cả đều phải ở trên đường EMA chậm (EMA 50)

### Điều kiện BUY 7: M5 - RSI phải > ngưỡng mua
- **Kiểm tra**: RSI > InpRSI_BuyLevel (mặc định = 50)
- **Mục đích**: Xác nhận momentum tăng qua chỉ báo RSI
- **Logic**: RSI > 50 cho thấy áp lực mua mạnh
- **Lưu ý**: Chỉ kiểm tra nếu bật sử dụng RSI (InpUseRSI = true)

### Điều kiện BUY 8: M5 - Các EMA phải có khoảng cách tách biệt rõ ràng
- **Kiểm tra**: Khoảng cách giữa các EMA ≥ InpMinEMASeparation (mặc định = 8 pips)
- **Mục đích**: Tránh tín hiệu khi EMA quá gần nhau (thị trường sideway)
- **Logic**: EMA phải có khoảng cách đủ lớn để xác nhận xu hướng rõ ràng

---

## ✅ ĐIỀU KIỆN KÍCH HOẠT LỆNH SELL

Bot sẽ kích hoạt tín hiệu **SELL** khi **TẤT CẢ** 8 điều kiện sau đều đúng:

### Điều kiện SELL 1: H1 - Giá phải ở dưới EMA 50
- **Kiểm tra**: Giá đóng cửa (bar 1) < EMA 50 H1
- **Mục đích**: Xác nhận xu hướng giảm trên khung thời gian lớn (H1)
- **Logic**: Nếu giá >= EMA 50 H1 → Không phải tín hiệu SELL

### Điều kiện SELL 2: H1 - Các EMA phải sắp xếp theo thứ tự giảm
- **Kiểm tra**: EMA 9 H1 < EMA 21 H1 < EMA 50 H1
- **Mục đích**: Xác nhận xu hướng giảm mạnh trên H1
- **Logic**: EMA phải "mở rộng" theo hướng giảm (fast < medium < slow)

### Điều kiện SELL 3: M5 - Các EMA phải sắp xếp theo thứ tự giảm
- **Kiểm tra**: EMA 9 M5 < EMA 21 M5 < EMA 50 M5
- **Mục đích**: Xác nhận xu hướng giảm trên khung thời gian tín hiệu (M5)
- **Logic**: EMA phải "mở rộng" theo hướng giảm trên M5

### Điều kiện SELL 4: M5 - EMA 9 phải cắt xuống dưới EMA 21
- **Kiểm tra**: 
  - EMA 9 hiện tại (bar 1) < EMA 21 hiện tại (bar 1)
  - EMA 9 nến trước (bar 2) ≥ EMA 21 nến trước (bar 2)
- **Mục đích**: Xác nhận tín hiệu bán mới xuất hiện (crossover)
- **Logic**: Đây là tín hiệu động - EMA 9 vừa cắt xuống EMA 21

### Điều kiện SELL 5: M5 - Nến đã đóng phải đóng dưới EMA 9
- **Kiểm tra**: Giá đóng cửa (bar 1) < EMA 9 M5
- **Mục đích**: Xác nhận momentum giảm mạnh
- **Logic**: Giá phải đóng dưới đường EMA nhanh nhất

### Điều kiện SELL 6: M5 - Giá, EMA 9, và EMA 21 đều phải ở dưới EMA 50
- **Kiểm tra**: 
  - Giá < EMA 50 M5
  - EMA 9 < EMA 50 M5
  - EMA 21 < EMA 50 M5
- **Mục đích**: Xác nhận vị trí giá và các EMA đều trong vùng giảm
- **Logic**: Tất cả đều phải ở dưới đường EMA chậm (EMA 50)

### Điều kiện SELL 7: M5 - RSI phải < ngưỡng bán
- **Kiểm tra**: RSI < InpRSI_SellLevel (mặc định = 50)
- **Mục đích**: Xác nhận momentum giảm qua chỉ báo RSI
- **Logic**: RSI < 50 cho thấy áp lực bán mạnh
- **Lưu ý**: Chỉ kiểm tra nếu bật sử dụng RSI (InpUseRSI = true)

### Điều kiện SELL 8: M5 - Các EMA phải có khoảng cách tách biệt rõ ràng
- **Kiểm tra**: Khoảng cách giữa các EMA ≥ InpMinEMASeparation (mặc định = 8 pips)
- **Mục đích**: Tránh tín hiệu khi EMA quá gần nhau (thị trường sideway)
- **Logic**: EMA phải có khoảng cách đủ lớn để xác nhận xu hướng rõ ràng

---

## 📊 CÁC CHỈ BÁO ĐƯỢC SỬ DỤNG VÀ THAM SỐ

### 1. EMA (Exponential Moving Average)

#### EMA trên H1 (Timeframe xu hướng)
- **EMA Fast (EMA 9)**: Period = 9
- **EMA Medium (EMA 21)**: Period = 21
- **EMA Slow (EMA 50)**: Period = 50
- **Method**: EMA (Exponential Moving Average)
- **Applied Price**: Close (giá đóng cửa)
- **Mục đích**: Xác định xu hướng chính trên khung thời gian lớn

#### EMA trên M5 (Timeframe tín hiệu)
- **EMA Fast (EMA 9)**: Period = 9
- **EMA Medium (EMA 21)**: Period = 21
- **EMA Slow (EMA 50)**: Period = 50
- **Method**: EMA (Exponential Moving Average)
- **Applied Price**: Close (giá đóng cửa)
- **Mục đích**: Tìm điểm vào lệnh trên khung thời gian nhỏ

#### Tham số EMA (có thể tùy chỉnh)
- `InpEMA_Fast = 9` - Period của EMA nhanh
- `InpEMA_Medium = 21` - Period của EMA trung bình
- `InpEMA_Slow = 50` - Period của EMA chậm
- `InpEMA_Method = MODE_EMA` - Phương pháp tính (EMA)
- `InpEMA_Price = PRICE_CLOSE` - Giá áp dụng (giá đóng cửa)

### 2. RSI (Relative Strength Index)

#### Tham số RSI
- **Period**: 14 (mặc định)
- **Buy Threshold**: > 50 (mặc định)
- **Sell Threshold**: < 50 (mặc định)
- **Mục đích**: Xác nhận momentum và lực mua/bán

#### Tham số RSI (có thể tùy chỉnh)
- `InpUseRSI = true` - Bật/tắt sử dụng RSI
- `InpRSI_Period = 14` - Period của RSI
- `InpRSI_BuyLevel = 50` - Ngưỡng mua (RSI phải > giá trị này)
- `InpRSI_SellLevel = 50` - Ngưỡng bán (RSI phải < giá trị này)

### 3. ADX (Average Directional Index) - Tùy chọn

#### Tham số ADX (nếu bật Momentum Filter)
- **Period**: 14 (mặc định)
- **Min ADX**: 20.0 (mặc định)
- **Mục đích**: Lọc nhiễu - chỉ giao dịch khi thị trường có xu hướng rõ ràng

#### Tham số ADX (có thể tùy chỉnh)
- `InpUseMomentumFilter = true` - Bật/tắt momentum filter
- `InpUseADXForMomentum = true` - Sử dụng ADX (true) hoặc RSI (false)
- `InpADX_Period = 14` - Period của ADX
- `InpMinADX = 20.0` - ADX tối thiểu để xác nhận xu hướng

### 4. Volume Filter - Tùy chọn

#### Tham số Volume Filter
- **Volume Period**: 10 candles (mặc định)
- **Mục đích**: Chỉ vào lệnh khi volume cao hơn trung bình

#### Tham số Volume (có thể tùy chỉnh)
- `InpUseVolumeFilter = true` - Bật/tắt volume filter
- `InpVolumePeriod = 10` - Số nến để tính volume trung bình

---

## 🔍 CÁC BỘ LỌC BỔ SUNG (Nếu bật)

### 1. Spread Filter
- **Kiểm tra**: Spread ≤ InpMaxSpread (mặc định = 2.5 pips)
- **Mục đích**: Tránh vào lệnh khi spread quá cao
- **Logic**: Nếu spread > 2.5 pips → Từ chối tín hiệu

### 2. Noise Reduction Filters (Nếu bật)
- **Multi-Timeframe Filter**: Đảm bảo tín hiệu phù hợp với xu hướng khung thời gian cao hơn (H4/D1)
- **Momentum Filter**: Lọc nhiễu - chỉ giao dịch khi thị trường có xu hướng (ADX > 20 hoặc RSI > 55)
- **Volume Filter**: Chỉ vào lệnh khi volume cao hơn trung bình 10 nến

### 3. Fakeout Detection (Nếu bật)
- **Confirmation Candles**: Yêu cầu 2-3 nến xác nhận
- **Min Momentum**: Tối thiểu 3 pips movement
- **Max Crossovers**: Tối đa 3 lần crossover trong 10 nến (tránh thị trường choppy)

### 4. Signal Validation
- Kiểm tra các điều kiện bổ sung qua Signal Validator
- Đảm bảo tín hiệu đáp ứng các tiêu chuẩn chất lượng

---

## 📈 HỆ THỐNG ĐIỂM (SCORING SYSTEM)

Sau khi tất cả điều kiện trên đều đúng, bot sẽ tính điểm từ 0-100:

- **Perfect Setup**: ≥ 85 điểm → Cảnh báo
- **Good Setup**: 70-84 điểm → Tùy chọn hiển thị
- **Weak Setup**: 50-69 điểm → Tùy chọn hiển thị

### Các yếu tố tính điểm:
1. **Trend Alignment** (25 điểm) - Sự phù hợp với xu hướng
2. **EMA Quality** (20 điểm) - Chất lượng EMA
3. **Signal Strength** (20 điểm) - Sức mạnh tín hiệu
4. **Confirmation** (15 điểm) - Xác nhận
5. **Market Conditions** (10 điểm) - Điều kiện thị trường
6. **Context & Timing** (10 điểm) - Bối cảnh và thời điểm

---

## ⚠️ LƯU Ý QUAN TRỌNG

1. **Anti-Repaint**: Bot chỉ sử dụng dữ liệu từ nến đã đóng (bar 1), không sử dụng nến đang hình thành (bar 0)

2. **Tất cả điều kiện phải đúng**: Tín hiệu chỉ xuất hiện khi **TẤT CẢ** 8 điều kiện đều thỏa mãn

3. **Điểm số**: Ngay cả khi tất cả điều kiện đúng, bot chỉ cảnh báo khi điểm ≥ 85 (Perfect Setup)

4. **Bộ lọc bổ sung**: Các bộ lọc như Noise Filter, Fakeout Detection có thể từ chối tín hiệu ngay cả khi 8 điều kiện cơ bản đều đúng

5. **Không tự động vào lệnh**: Bot chỉ cảnh báo, trader tự quyết định có vào lệnh hay không

---

## 📝 TÓM TẮT

### Điều kiện BUY (8 điều kiện):
1. ✅ H1: Giá > EMA 50
2. ✅ H1: EMA 9 > EMA 21 > EMA 50
3. ✅ M5: EMA 9 > EMA 21 > EMA 50
4. ✅ M5: EMA 9 cắt lên EMA 21
5. ✅ M5: Giá đóng trên EMA 9
6. ✅ M5: Giá, EMA 9, EMA 21 đều trên EMA 50
7. ✅ M5: RSI > 50 (nếu bật)
8. ✅ M5: EMA có khoảng cách ≥ 8 pips

### Điều kiện SELL (8 điều kiện):
1. ✅ H1: Giá < EMA 50
2. ✅ H1: EMA 9 < EMA 21 < EMA 50
3. ✅ M5: EMA 9 < EMA 21 < EMA 50
4. ✅ M5: EMA 9 cắt xuống EMA 21
5. ✅ M5: Giá đóng dưới EMA 9
6. ✅ M5: Giá, EMA 9, EMA 21 đều dưới EMA 50
7. ✅ M5: RSI < 50 (nếu bật)
8. ✅ M5: EMA có khoảng cách ≥ 8 pips

### Chỉ báo sử dụng:
- **EMA**: 3 đường (9, 21, 50) trên H1 và M5
- **RSI**: Period 14, ngưỡng 50
- **ADX**: Period 14, min 20 (tùy chọn)
- **Volume**: So sánh với trung bình 10 nến (tùy chọn)

---

**Tài liệu này giải thích chi tiết logic vào lệnh của bot. Tất cả điều kiện phải được thỏa mãn đồng thời để có tín hiệu vào lệnh.**

