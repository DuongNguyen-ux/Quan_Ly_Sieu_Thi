# Demo Các Lỗi Đồng Thời (Concurrency Issues) trên SSMS

> [!IMPORTANT]
> **Cách thực hiện:** Mở **2 cửa sổ Query** riêng biệt trong SSMS (mỗi cửa sổ = 1 Session/Transaction khác nhau). Chạy các lệnh **theo đúng thứ tự bước** được đánh số.

> [!WARNING]
> **Chạy từng bước:** Mỗi khối SQL đánh dấu "Bước X" là **một lần bôi đen → Execute** riêng. Sau mỗi demo nhớ **reset dữ liệu** trước khi chạy demo tiếp.

> [!NOTE]
> Tất cả ví dụ đều dùng database `QuanLySieuThi` và bảng `SAN_PHAM` (sản phẩm `SP01` — Mì Hảo Hảo, `SoLuongTon = 500`, `GiaBan = 4500`).

---

## 1. 🔴 Lost Update (Mất cập nhật)

### Giải thích
Hai transaction cùng đọc một giá trị, rồi cùng cập nhật → kết quả của transaction trước bị ghi đè bởi transaction sau.

**Kịch bản:** Nhân viên A nhập thêm 100 gói mì, nhân viên B nhập thêm 50 gói mì. Đáng lẽ tổng = 500 + 100 + 50 = **650**, nhưng chỉ còn **550** (mất 100 của A).

### 1A. Demo GÂY LỖI

#### 🪟 Session 1 (Query Window 1)
```sql
-- ===== Bước 1: Đọc SoLuongTon, lưu vào bảng tạm =====
USE QuanLySieuThi;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRANSACTION;

DROP TABLE IF EXISTS #s1;
SELECT SoLuongTon AS GiaTri INTO #s1 FROM SAN_PHAM WHERE MaSP = 'SP01';
SELECT N'Session 1 đọc SoLuongTon =' AS [Info], GiaTri FROM #s1;
-- KẾT QUẢ: 500
-- ⏸ DỪNG → Sang Session 2 chạy Bước 2
```

```sql
-- ===== Bước 3: Cập nhật +100 rồi COMMIT =====
UPDATE SAN_PHAM SET SoLuongTon = (SELECT GiaTri FROM #s1) + 100 WHERE MaSP = 'SP01';
COMMIT;
SELECT N'Session 1 ghi SoLuongTon =' AS [Info], SoLuongTon FROM SAN_PHAM WHERE MaSP='SP01';
-- ⏸ DỪNG → Sang Session 2 chạy Bước 4
```

#### 🪟 Session 2 (Query Window 2)
```sql
-- ===== Bước 2: Đọc SoLuongTon (Session 1 chưa COMMIT) =====
USE QuanLySieuThi;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRANSACTION;

DROP TABLE IF EXISTS #s2;
SELECT SoLuongTon AS GiaTri INTO #s2 FROM SAN_PHAM WHERE MaSP = 'SP01';
SELECT N'Session 2 đọc SoLuongTon =' AS [Info], GiaTri FROM #s2;
-- KẾT QUẢ: 500 (vẫn giá trị cũ)
-- ⏸ DỪNG → Quay lại Session 1 chạy Bước 3
```

```sql
-- ===== Bước 4: Cập nhật +50 → GHI ĐÈ kết quả Session 1! =====
UPDATE SAN_PHAM SET SoLuongTon = (SELECT GiaTri FROM #s2) + 50 WHERE MaSP = 'SP01';
COMMIT;
SELECT N'Session 2 ghi SoLuongTon =' AS [Info], SoLuongTon FROM SAN_PHAM WHERE MaSP='SP01';
```

#### 🔍 Kiểm tra
```sql
-- ===== Bước 5 =====
SELECT MaSP, TenSP, SoLuongTon FROM SAN_PHAM WHERE MaSP = 'SP01';
-- ❌ KẾT QUẢ: SoLuongTon = 550 (thay vì 650) → Lost Update!
```

#### ♻️ Reset
```sql
UPDATE SAN_PHAM SET SoLuongTon = 500 WHERE MaSP = 'SP01';
```

### 1B. Demo CÁCH SỬA — Dùng `UPDLOCK` khi đọc

> **Nguyên lý:** Thêm hint `WITH (UPDLOCK)` vào SELECT → khóa row ngay khi đọc → session khác phải **chờ** đến khi transaction đầu COMMIT mới được đọc.

#### 🪟 Session 1 (Query Window 1)
```sql
-- ===== Bước 1: Đọc với UPDLOCK → khóa row SP01 =====
USE QuanLySieuThi;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRANSACTION;

DROP TABLE IF EXISTS #s1;
-- ✅ Thêm WITH (UPDLOCK) để giữ khóa khi đọc
SELECT SoLuongTon AS GiaTri INTO #s1 FROM SAN_PHAM WITH (UPDLOCK) WHERE MaSP = 'SP01';
SELECT N'Session 1 đọc + KHÓA SoLuongTon =' AS [Info], GiaTri FROM #s1;
-- KẾT QUẢ: 500
-- ⏸ DỪNG → Sang Session 2 chạy Bước 2
```

#### 🪟 Session 2 (Query Window 2)
```sql
-- ===== Bước 2: Cũng đọc với UPDLOCK → BỊ BLOCK chờ! =====
USE QuanLySieuThi;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRANSACTION;

DROP TABLE IF EXISTS #s2;
-- ⏳ Lệnh này sẽ BỊ BLOCK vì Session 1 đang giữ khóa UPDLOCK trên SP01
SELECT SoLuongTon AS GiaTri INTO #s2 FROM SAN_PHAM WITH (UPDLOCK) WHERE MaSP = 'SP01';
SELECT N'Session 2 đọc SoLuongTon =' AS [Info], GiaTri FROM #s2;
-- Session 2 đang chờ... (Executing...)
-- ⏸ Quay lại Session 1 chạy Bước 3
```

#### 🪟 Quay lại Session 1
```sql
-- ===== Bước 3: Cập nhật +100 rồi COMMIT → Giải phóng khóa =====
UPDATE SAN_PHAM SET SoLuongTon = (SELECT GiaTri FROM #s1) + 100 WHERE MaSP = 'SP01';
COMMIT;
SELECT N'Session 1 COMMIT. SoLuongTon =' AS [Info], SoLuongTon FROM SAN_PHAM WHERE MaSP='SP01';
-- KẾT QUẢ: 600
-- → Session 2 tự động hết block, đọc được giá trị MỚI = 600
```

#### 🪟 Quay lại Session 2 (đã tự hết block)
```sql
-- ===== Bước 4: Session 2 đọc được 600 (giá trị mới), cập nhật +50 =====
-- Session 2 đã đọc GiaTri = 600 (sau khi Session 1 COMMIT)
-- Kiểm tra:
SELECT N'Session 2 đọc được GiaTri =' AS [Info], GiaTri FROM #s2;
-- KẾT QUẢ: 600

UPDATE SAN_PHAM SET SoLuongTon = (SELECT GiaTri FROM #s2) + 50 WHERE MaSP = 'SP01';
COMMIT;
```

#### 🔍 Kiểm tra
```sql
-- ===== Bước 5 =====
SELECT MaSP, TenSP, SoLuongTon FROM SAN_PHAM WHERE MaSP = 'SP01';
-- ✅ KẾT QUẢ: SoLuongTon = 650 → Đúng! Không còn Lost Update!
```

#### ♻️ Reset
```sql
UPDATE SAN_PHAM SET SoLuongTon = 500 WHERE MaSP = 'SP01';
```

---

## 2. 🟡 Dirty Read (Đọc bẩn)

### Giải thích
Một transaction đọc được dữ liệu **chưa COMMIT** của transaction khác. Nếu transaction kia ROLLBACK, thì dữ liệu đã đọc là sai (dữ liệu "bẩn").

**Kịch bản:** Nhân viên A giảm giá SP01 xuống 3000đ (chưa commit). Nhân viên B đọc thấy giá 3000đ → lập hóa đơn sai giá. Sau đó A hủy giao dịch → giá thực tế vẫn là 4500đ.

### 2A. Demo GÂY LỖI — Dùng `READ UNCOMMITTED`

#### 🪟 Session 1 (Query Window 1)
```sql
-- ===== Bước 1: Cập nhật giá nhưng CHƯA COMMIT =====
USE QuanLySieuThi;
BEGIN TRANSACTION;

UPDATE SAN_PHAM SET GiaBan = 3000 WHERE MaSP = 'SP01';
SELECT N'Session 1 UPDATE GiaBan = 3000 (chưa COMMIT)' AS [Info];
-- ⏸ DỪNG → Sang Session 2 chạy Bước 2
```

#### 🪟 Session 2 (Query Window 2)
```sql
-- ===== Bước 2: Đọc với READ UNCOMMITTED → Dirty Read! =====
USE QuanLySieuThi;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT MaSP, TenSP, GiaBan FROM SAN_PHAM WHERE MaSP = 'SP01';
-- ❌ KẾT QUẢ: GiaBan = 3000 ← Dirty Read! Dữ liệu chưa COMMIT
-- ⏸ DỪNG → Quay lại Session 1 chạy Bước 3
```

#### 🪟 Quay lại Session 1
```sql
-- ===== Bước 3: ROLLBACK → chứng minh dữ liệu Session 2 đọc là SAI =====
ROLLBACK;
SELECT N'Session 1 ROLLBACK. GiaBan thực tế =' AS [Info], GiaBan FROM SAN_PHAM WHERE MaSP='SP01';
-- KẾT QUẢ: GiaBan = 4500 → Session 2 đã đọc dữ liệu bẩn!
```

### 2B. Demo CÁCH SỬA — Dùng `READ COMMITTED` (mặc định)

> **Nguyên lý:** `READ COMMITTED` chỉ cho phép đọc dữ liệu đã COMMIT → Session 2 sẽ bị **block** cho tới khi Session 1 COMMIT hoặc ROLLBACK.

#### 🪟 Session 1 (Query Window 1)
```sql
-- ===== Bước 1: Cập nhật giá nhưng CHƯA COMMIT =====
USE QuanLySieuThi;
BEGIN TRANSACTION;

UPDATE SAN_PHAM SET GiaBan = 3000 WHERE MaSP = 'SP01';
SELECT N'Session 1 UPDATE GiaBan = 3000 (chưa COMMIT)' AS [Info];
-- ⏸ DỪNG → Sang Session 2 chạy Bước 2
```

#### 🪟 Session 2 (Query Window 2)
```sql
-- ===== Bước 2: Đọc với READ COMMITTED → BỊ BLOCK! =====
USE QuanLySieuThi;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED; -- ✅ Mặc định

SELECT MaSP, TenSP, GiaBan FROM SAN_PHAM WHERE MaSP = 'SP01';
-- ⏳ Session 2 BỊ BLOCK, đang chờ Session 1 COMMIT/ROLLBACK...
-- → KHÔNG đọc được dữ liệu bẩn!
```

#### 🪟 Quay lại Session 1
```sql
-- ===== Bước 3: ROLLBACK → Session 2 tự hết block =====
ROLLBACK;
SELECT N'Session 1 ROLLBACK.' AS [Info];
-- → Session 2 tự động chạy tiếp, đọc được GiaBan = 4500 (giá trị đúng)
```

#### 🔍 Kiểm tra Session 2
```
-- Session 2 trả về: GiaBan = 4500 ✅ Đúng! Không có Dirty Read!
```

---

## 3. 🟠 Non-Repeatable Read (Đọc không lặp lại)

### Giải thích
Trong cùng một transaction, đọc cùng một row **2 lần** nhưng ra **kết quả khác nhau**, vì transaction khác đã UPDATE & COMMIT giữa 2 lần đọc.

**Kịch bản:** Session 1 đọc giá SP01 = 4500đ, rồi Session 2 cập nhật giá = 5000đ và COMMIT. Session 1 đọc lại → thấy 5000đ (khác lần trước).

### 3A. Demo GÂY LỖI — Dùng `READ COMMITTED`

#### 🪟 Session 1 (Query Window 1)
```sql
-- ===== Bước 1: Đọc lần 1 =====
USE QuanLySieuThi;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRANSACTION;

SELECT MaSP, TenSP, GiaBan FROM SAN_PHAM WHERE MaSP = 'SP01';
-- KẾT QUẢ lần 1: GiaBan = 4500
-- ⏸ DỪNG → Sang Session 2 chạy Bước 2
```

#### 🪟 Session 2 (Query Window 2)
```sql
-- ===== Bước 2: Cập nhật giá và COMMIT ngay =====
USE QuanLySieuThi;
UPDATE SAN_PHAM SET GiaBan = 5000 WHERE MaSP = 'SP01';
SELECT N'Session 2 UPDATE GiaBan = 5000 và auto-COMMIT' AS [Info];
-- ⏸ DỪNG → Quay lại Session 1 chạy Bước 3
```

#### 🪟 Quay lại Session 1
```sql
-- ===== Bước 3: Đọc lần 2 trong CÙNG transaction =====
SELECT MaSP, TenSP, GiaBan FROM SAN_PHAM WHERE MaSP = 'SP01';
-- ❌ KẾT QUẢ lần 2: GiaBan = 5000 ← KHÁC lần 1! → Non-Repeatable Read!
COMMIT;
```

#### ♻️ Reset
```sql
UPDATE SAN_PHAM SET GiaBan = 4500 WHERE MaSP = 'SP01';
```

### 3B. Demo CÁCH SỬA — Dùng `REPEATABLE READ`

> **Nguyên lý:** `REPEATABLE READ` giữ shared lock trên các row đã đọc suốt transaction → session khác **không thể UPDATE** row đó cho đến khi transaction kết thúc.

#### 🪟 Session 1 (Query Window 1)
```sql
-- ===== Bước 1: Đọc lần 1 với REPEATABLE READ =====
USE QuanLySieuThi;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ; -- ✅ Khóa row đã đọc
BEGIN TRANSACTION;

SELECT MaSP, TenSP, GiaBan FROM SAN_PHAM WHERE MaSP = 'SP01';
-- KẾT QUẢ lần 1: GiaBan = 4500
-- ⏸ DỪNG → Sang Session 2 chạy Bước 2
```

#### 🪟 Session 2 (Query Window 2)
```sql
-- ===== Bước 2: Cố UPDATE giá → BỊ BLOCK! =====
USE QuanLySieuThi;
UPDATE SAN_PHAM SET GiaBan = 5000 WHERE MaSP = 'SP01';
-- ⏳ BỊ BLOCK! Session 1 đang giữ shared lock trên SP01
-- Session 2 phải chờ Session 1 COMMIT mới UPDATE được
```

#### 🪟 Quay lại Session 1
```sql
-- ===== Bước 3: Đọc lần 2 → vẫn GIỐNG lần 1! =====
SELECT MaSP, TenSP, GiaBan FROM SAN_PHAM WHERE MaSP = 'SP01';
-- ✅ KẾT QUẢ lần 2: GiaBan = 4500 ← GIỐNG lần 1! Không còn Non-Repeatable Read!
COMMIT;
-- → Session 2 tự hết block, UPDATE thành công
```

#### ♻️ Reset
```sql
UPDATE SAN_PHAM SET GiaBan = 4500 WHERE MaSP = 'SP01';
```

---

## 4. 🟣 Phantom Read (Đọc ma)

### Giải thích
Trong cùng một transaction, chạy cùng một câu SELECT **2 lần** nhưng lần sau xuất hiện thêm **row mới** do transaction khác INSERT & COMMIT.

**Kịch bản:** Session 1 đếm sản phẩm danh mục DM03 (Đồ uống) = 5 SP. Session 2 INSERT thêm 1 SP mới. Session 1 đếm lại → thấy 6 SP (row "ma" xuất hiện).

### 4A. Demo GÂY LỖI — Dùng `REPEATABLE READ`

> Lưu ý: `REPEATABLE READ` chặn Non-Repeatable Read nhưng **KHÔNG** chặn Phantom Read.

#### 🪟 Session 1 (Query Window 1)
```sql
-- ===== Bước 1: Đếm sản phẩm đồ uống lần 1 =====
USE QuanLySieuThi;
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN TRANSACTION;

SELECT COUNT(*) AS SoSanPham FROM SAN_PHAM WHERE MaDM = 'DM03';
-- KẾT QUẢ lần 1: SoSanPham = 5
SELECT MaSP, TenSP FROM SAN_PHAM WHERE MaDM = 'DM03';
-- ⏸ DỪNG → Sang Session 2 chạy Bước 2
```

#### 🪟 Session 2 (Query Window 2)
```sql
-- ===== Bước 2: INSERT sản phẩm mới vào DM03 =====
USE QuanLySieuThi;
INSERT INTO SAN_PHAM (MaSP, TenSP, DonViTinh, GiaBan, SoLuongTon, MaDM)
VALUES ('SP99', N'Nước dừa tươi 500ml', N'Chai', 15000, 100, 'DM03');
SELECT N'Session 2 INSERT SP99 thành công' AS [Info];
-- ⏸ DỪNG → Quay lại Session 1 chạy Bước 3
```

#### 🪟 Quay lại Session 1
```sql
-- ===== Bước 3: Đếm lại trong CÙNG transaction =====
SELECT COUNT(*) AS SoSanPham FROM SAN_PHAM WHERE MaDM = 'DM03';
-- ❌ KẾT QUẢ lần 2: SoSanPham = 6 ← Phantom Read! Row "ma" xuất hiện!
SELECT MaSP, TenSP FROM SAN_PHAM WHERE MaDM = 'DM03';
-- Thấy thêm SP99 - Nước dừa tươi 500ml
COMMIT;
```

#### ♻️ Reset
```sql
DELETE FROM SAN_PHAM WHERE MaSP = 'SP99';
```

### 4B. Demo CÁCH SỬA — Dùng `SERIALIZABLE`

> **Nguyên lý:** `SERIALIZABLE` khóa cả **range** (khoảng giá trị) → session khác **không thể INSERT** row mới khớp điều kiện WHERE cho đến khi transaction kết thúc.

#### 🪟 Session 1 (Query Window 1)
```sql
-- ===== Bước 1: Đếm lần 1 với SERIALIZABLE =====
USE QuanLySieuThi;
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE; -- ✅ Khóa cả range
BEGIN TRANSACTION;

SELECT COUNT(*) AS SoSanPham FROM SAN_PHAM WHERE MaDM = 'DM03';
-- KẾT QUẢ lần 1: SoSanPham = 5
SELECT MaSP, TenSP FROM SAN_PHAM WHERE MaDM = 'DM03';
-- ⏸ DỪNG → Sang Session 2 chạy Bước 2
```

#### 🪟 Session 2 (Query Window 2)
```sql
-- ===== Bước 2: Cố INSERT sản phẩm mới → BỊ BLOCK! =====
USE QuanLySieuThi;
INSERT INTO SAN_PHAM (MaSP, TenSP, DonViTinh, GiaBan, SoLuongTon, MaDM)
VALUES ('SP99', N'Nước dừa tươi 500ml', N'Chai', 15000, 100, 'DM03');
-- ⏳ BỊ BLOCK! SERIALIZABLE khóa range MaDM='DM03'
-- Session 2 phải chờ Session 1 COMMIT
```

#### 🪟 Quay lại Session 1
```sql
-- ===== Bước 3: Đếm lại → vẫn GIỐNG lần 1! =====
SELECT COUNT(*) AS SoSanPham FROM SAN_PHAM WHERE MaDM = 'DM03';
-- ✅ KẾT QUẢ lần 2: SoSanPham = 5 ← GIỐNG lần 1! Không có Phantom Read!
SELECT MaSP, TenSP FROM SAN_PHAM WHERE MaDM = 'DM03';
-- Vẫn chỉ 5 sản phẩm cũ
COMMIT;
-- → Session 2 tự hết block, INSERT thành công
```

#### ♻️ Reset
```sql
DELETE FROM SAN_PHAM WHERE MaSP = 'SP99';
```

---

## 5. 💀 Deadlock (Khóa chết)

### Giải thích
Hai transaction giữ khóa lẫn nhau theo thứ tự ngược nhau → cả hai đều chờ nhau mãi mãi. SQL Server sẽ **tự phát hiện** và **kill** 1 trong 2 (victim).

**Kịch bản:** Session 1 khóa SP01 rồi muốn khóa SP02. Session 2 khóa SP02 rồi muốn khóa SP01. → Deadlock!

### 5A. Demo GÂY LỖI — Khóa theo thứ tự NGƯỢC

#### 🪟 Session 1 (Query Window 1)
```sql
-- ===== Bước 1: Khóa SP01 trước =====
USE QuanLySieuThi;
BEGIN TRANSACTION;

UPDATE SAN_PHAM SET SoLuongTon = SoLuongTon + 10 WHERE MaSP = 'SP01';
SELECT N'Session 1: Đã khóa SP01' AS [Info];
-- ⏸ DỪNG → Sang Session 2 chạy Bước 2
```

#### 🪟 Session 2 (Query Window 2)
```sql
-- ===== Bước 2: Khóa SP02 trước (thứ tự NGƯỢC!) =====
USE QuanLySieuThi;
BEGIN TRANSACTION;

UPDATE SAN_PHAM SET SoLuongTon = SoLuongTon + 20 WHERE MaSP = 'SP02';
SELECT N'Session 2: Đã khóa SP02' AS [Info];
-- ⏸ DỪNG → Quay lại Session 1 chạy Bước 3
```

#### 🪟 Quay lại Session 1
```sql
-- ===== Bước 3: Yêu cầu khóa SP02 → BỊ BLOCK =====
UPDATE SAN_PHAM SET SoLuongTon = SoLuongTon + 10 WHERE MaSP = 'SP02';
-- ⏳ Session 1 chờ SP02 (Session 2 đang giữ)...
-- ⏸ NHANH CHÓNG sang Session 2 chạy Bước 4 (trong khi Session 1 đang chờ)
```

#### 🪟 Quay lại Session 2
```sql
-- ===== Bước 4: Yêu cầu khóa SP01 → DEADLOCK! =====
UPDATE SAN_PHAM SET SoLuongTon = SoLuongTon + 20 WHERE MaSP = 'SP01';
-- ❌ SQL Server phát hiện Deadlock!
-- Msg 1205: Transaction was deadlocked and has been chosen as the deadlock victim.
-- 1 session bị kill, session còn lại chạy tiếp thành công
```

#### 🪟 Session còn lại (không bị kill)
```sql
-- ===== Bước 5 =====
COMMIT;
-- Hoặc ROLLBACK nếu muốn hủy
```

#### ♻️ Reset
```sql
IF @@TRANCOUNT > 0 ROLLBACK; -- Dọn transaction còn dở
UPDATE SAN_PHAM SET SoLuongTon = 500 WHERE MaSP = 'SP01';
UPDATE SAN_PHAM SET SoLuongTon = 50  WHERE MaSP = 'SP02';
```

### 5B. Demo CÁCH SỬA — Khóa theo CÙNG THỨ TỰ

> **Nguyên lý:** Cả 2 session đều khóa **SP01 trước, SP02 sau** (cùng thứ tự) → không bao giờ xảy ra vòng chờ → không Deadlock.

#### 🪟 Session 1 (Query Window 1)
```sql
-- ===== Bước 1: Khóa SP01 trước =====
USE QuanLySieuThi;
BEGIN TRANSACTION;

UPDATE SAN_PHAM SET SoLuongTon = SoLuongTon + 10 WHERE MaSP = 'SP01'; -- ✅ Khóa SP01
SELECT N'Session 1: Đã khóa SP01' AS [Info];
-- ⏸ DỪNG → Sang Session 2 chạy Bước 2
```

#### 🪟 Session 2 (Query Window 2)
```sql
-- ===== Bước 2: CŨNG khóa SP01 trước (CÙNG THỨ TỰ!) → BỊ BLOCK =====
USE QuanLySieuThi;
BEGIN TRANSACTION;

UPDATE SAN_PHAM SET SoLuongTon = SoLuongTon + 20 WHERE MaSP = 'SP01'; -- ✅ Cùng thứ tự
-- ⏳ BỊ BLOCK chờ Session 1 giải phóng SP01 (KHÔNG phải Deadlock!)
-- ⏸ Quay lại Session 1 chạy Bước 3
```

#### 🪟 Quay lại Session 1
```sql
-- ===== Bước 3: Khóa SP02, rồi COMMIT → Giải phóng tất cả khóa =====
UPDATE SAN_PHAM SET SoLuongTon = SoLuongTon + 10 WHERE MaSP = 'SP02';
COMMIT;
SELECT N'Session 1 COMMIT thành công!' AS [Info];
-- → Session 2 tự hết block, tiếp tục chạy
```

#### 🪟 Quay lại Session 2 (đã hết block)
```sql
-- ===== Bước 4: Session 2 tiếp tục, khóa SP02 rồi COMMIT =====
UPDATE SAN_PHAM SET SoLuongTon = SoLuongTon + 20 WHERE MaSP = 'SP02';
COMMIT;
SELECT N'Session 2 COMMIT thành công!' AS [Info];
-- ✅ Không có Deadlock! Cả 2 session đều thành công!
```

#### 🔍 Kiểm tra
```sql
-- ===== Bước 5 =====
SELECT MaSP, TenSP, SoLuongTon FROM SAN_PHAM WHERE MaSP IN ('SP01','SP02');
-- ✅ SP01: 500 + 10 + 20 = 530
-- ✅ SP02: 50 + 10 + 20 = 80
-- Cả 2 đều cập nhật đúng, không mất dữ liệu!
```

#### ♻️ Reset
```sql
UPDATE SAN_PHAM SET SoLuongTon = 500 WHERE MaSP = 'SP01';
UPDATE SAN_PHAM SET SoLuongTon = 50  WHERE MaSP = 'SP02';
```

---

## 📋 Bảng Tổng Kết

| Lỗi | Nguyên nhân | Demo gây lỗi | Cách sửa |
|---|---|---|---|
| **Lost Update** | 2 TXN cùng đọc → cùng ghi đè | `READ COMMITTED` (không khóa khi đọc) | `SELECT ... WITH (UPDLOCK)` |
| **Dirty Read** | Đọc dữ liệu chưa COMMIT | `READ UNCOMMITTED` | `READ COMMITTED` (mặc định) |
| **Non-Repeatable Read** | Row bị UPDATE giữa 2 lần đọc | `READ COMMITTED` | `REPEATABLE READ` |
| **Phantom Read** | Row mới INSERT giữa 2 lần đọc | `REPEATABLE READ` | `SERIALIZABLE` |
| **Deadlock** | Khóa theo thứ tự ngược nhau | Khóa SP01→SP02 vs SP02→SP01 | Khóa cùng thứ tự SP01→SP02 |

## 📊 Isolation Level vs. Lỗi

| Isolation Level | Dirty Read | Non-Repeatable Read | Phantom Read |
|---|---|---|---|
| READ UNCOMMITTED | ❌ Có | ❌ Có | ❌ Có |
| READ COMMITTED | ✅ Chặn | ❌ Có | ❌ Có |
| REPEATABLE READ | ✅ Chặn | ✅ Chặn | ❌ Có |
| SERIALIZABLE | ✅ Chặn | ✅ Chặn | ✅ Chặn |
| SNAPSHOT | ✅ Chặn | ✅ Chặn | ✅ Chặn |

> [!CAUTION]
> Sau mỗi demo, nhớ **COMMIT** hoặc **ROLLBACK** tất cả transaction đang mở, và **reset dữ liệu** về giá trị ban đầu trước khi chạy demo tiếp theo. Nếu bị "Executing..." quá lâu, nhấn `Alt+Break` để cancel rồi chạy `IF @@TRANCOUNT > 0 ROLLBACK;`
