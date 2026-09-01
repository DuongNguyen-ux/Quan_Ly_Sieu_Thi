# 🛒 HỆ THỐNG QUẢN LÝ SIÊU THỊ (SUPERMARKET MANAGEMENT SYSTEM)

![SQL Server](https://img.shields.io/badge/Database-Microsoft%20SQL%20Server-red?style=flat&logo=microsoftsqlserver)
![T-SQL](https://img.shields.io/badge/Language-T--SQL-blue?style=flat)
![Status](https://img.shields.io/badge/Status-Completed-brightgreen?style=flat)

---

## 📋 MỤC LỤC
1. [Giới thiệu](#1-giới-thiệu)
2. [Mục tiêu dự án](#2-mục-tiêu-dự-án)
3. [Công nghệ & Công cụ](#3-công-nghệ--công-cụ)
4. [Cấu trúc thư mục dự án](#4-cấu-trúc-thư-mục-dự-án)
5. [Hướng dẫn cài đặt & Chạy script](#5-hướng-dẫn-cài-đặt--chạy-script)
6. [Phạm vi hệ thống](#6-phạm-vi-hệ-thống)
7. [Các tác nhân hệ thống](#7-các-tác-nhân-hệ-thống)
8. [Mô hình dữ liệu & Bảng cơ sở dữ liệu](#8-mô-hình-dữ-liệu--bảng-cơ-sở-dữ-liệu)
9. [Khóa chính, Khóa ngoại & Ràng buộc](#9-khóa-chính-khóa-ngoại--ràng-buộc)
10. [Các đối tượng SQL (T-SQL Objects)](#10-các-đối-tượng-sql-t-sql-objects)
11. [Quy trình nghiệp vụ chính](#11-quy-trình-nghiệp-vụ-chính)
12. [Kiểm thử hệ thống (Test Cases)](#12-kiểm-thử-hệ-thống-test-cases)
13. [Trạng thái dự án](#13-trạng-thái-dự-án)
14. [Phân công công việc & Quy tắc nhóm](#14-phân-công-công-việc--quy-tắc-nhóm)
15. [Kết luận & Hướng phát triển](#15-kết-luận--hướng-phát-triển)

---

## 1. Giới thiệu

**Hệ thống Quản lý Siêu thị** là bài tập lớn môn **Hệ quản trị cơ sở dữ liệu**, được thiết kế và cài đặt hoàn chỉnh trên hệ quản trị **Microsoft SQL Server** bằng ngôn ngữ **T-SQL**.

Hệ thống cung cấp giải pháp lưu trữ tập trung, tự động hóa và duy trì tính toàn vẹn dữ liệu cho các nghiệp vụ siêu thị cốt lõi:

- **Quản lý danh mục & Sản phẩm:** Phân loại sản phẩm, quản lý đơn giá bán, đơn vị tính, theo dõi số lượng tồn kho realtime.
- **Quản lý đối tác & Nhân sự:** Lưu trữ nhà cung cấp, thông tin nhân viên và danh sách khách hàng tích điểm.
- **Quản lý nhập hàng (Inventory Management):** Lập phiếu nhập, tự động tính tổng tiền phiếu nhập và tự động tăng tồn kho thông qua Trigger.
- **Quản lý bán hàng & Hóa đơn (Sales & Invoicing):** Tạo hóa đơn, thêm sản phẩm, kiểm tra tồn kho trước khi bán, tự động trừ tồn kho, tính thành tiền và quản lý lịch sử hóa đơn.
- **Quản lý thanh toán & Tích điểm:** Ghi nhận thanh toán đa phương thức (Tiền mặt, Chuyển khoản, Thẻ, Ví điện tử) và tự động tích điểm thưởng cho khách hàng (10.000 VNĐ = 1 điểm).
- **Thống kê & Báo cáo:** Cung cấp các View báo cáo doanh thu theo ngày, sản phẩm bán chạy, cảnh báo sản phẩm sắp hết hàng và lịch sử nhập hàng.

---

## 2. Mục tiêu dự án

* **Phân tích nghiệp vụ:** Xác định chính xác các thực thể, thuộc tính, ràng buộc và quy trình vận hành siêu thị.
* **Thiết kế cơ sở dữ liệu chuẩn hóa:** Xây dựng mô hình ERD và chuyển đổi sang Mô hình quan hệ đạt chuẩn (3NF).
* **Đảm bảo tính toàn vẹn dữ liệu:** Áp dụng đầy đủ các ràng buộc `PRIMARY KEY`, `FOREIGN KEY`, `NOT NULL`, `UNIQUE`, `CHECK`, và `DEFAULT`.
* **Lập trình T-SQL nâng cao:**
  * Xây dựng **Stored Procedures** kết hợp `TRANSACTION` và `TRY...CATCH` để đảm bảo tính nguyên tố (ACID).
  * Xây dựng **Functions** hỗ trợ kiểm tra tồn kho, tính tổng tiền và điểm thưởng.
  * Xây dựng **Triggers** tự động cập nhật tồn kho (hỗ trợ cả thao tác tập hợp nhiều dòng INSERT/UPDATE/DELETE) và chặn xóa trực tiếp hóa đơn.
  * Xây dựng **Views** tối ưu cho truy vấn báo cáo.
* **Kiểm thử tự động:** Viết bộ kịch bản test case đánh giá cả trường hợp hợp lệ (Happy Path) và không hợp lệ (Error Handling).

---

## 3. Công nghệ & Công cụ

| Công nghệ / Công cụ | Mục đích sử dụng |
| :--- | :--- |
| **Microsoft SQL Server** | Hệ quản trị cơ sở dữ liệu quan hệ (RDBMS) |
| **T-SQL (Transact-SQL)** | Ngôn ngữ lập trình CSDL (DDL, DML, Stored Proc, Trigger, Function, View) |
| **SQL Server Management Studio (SSMS)** | Công cụ quản lý, soạn thảo và thực thi SQL scripts |
| **Git / GitHub** | Quản lý mã nguồn dự án |
| **Markdown** | Trình bày tài liệu hướng dẫn và phân tích bài toán |

---

## 4. Cấu trúc thư mục dự án

```text
Quan_Ly_Sieu_Thi/
├── README.md                 # Tài liệu hướng dẫn tổng quan dự án
├── docs/
│   └── QLST.md              # Tài liệu phân tích yêu cầu, thiết kế & thuyết minh chi tiết
├── database/
│   ├── 01_CreateDatabase.sql # Script khởi tạo CSDL QuanLySieuThi
│   ├── 02_CreateTables.sql   # Script tạo 10 bảng, khóa chính/ngoại, UNIQUE, CHECK, INDEX
│   ├── 03_SeedData.sql       # Script chèn dữ liệu mẫu (8 DM, 6 NCC, 6 NV, 8 KH, 50 SP)
│   ├── 04_Inventory.sql      # Script nghiệp vụ kho (View, Function, Stored Proc, Trigger)
│   ├── 05_Sales.sql          # Script nghiệp vụ bán hàng (Functions, Trigger, Stored Procs)
│   └── 06_Reports.sql        # Script tạo 4 View báo cáo & thống kê
└── tests/
    └── 07_Tests.sql          # Script kịch bản kiểm thử tự động (Test Cases)
```

---

## 5. Hướng dẫn cài đặt & Chạy script

### Thứ tự thực thi (Bắt buộc)

Để cơ sở dữ liệu được khởi tạo đúng và không bị lỗi phụ thuộc khóa ngoại, hãy chạy các file SQL theo thứ tự từ `01` đến `07`:

1. `database/01_CreateDatabase.sql` *(Tạo Database QuanLySieuThi)*
2. `database/02_CreateTables.sql` *(Tạo cấu trúc 10 bảng & các ràng buộc)*
3. `database/03_SeedData.sql` *(Nạp dữ liệu mẫu ban đầu)*
4. `database/04_Inventory.sql` *(Cài đặt các thủ tục, hàm, view, trigger nhập hàng)*
5. `database/05_Sales.sql` *(Cài đặt thủ tục, hàm, trigger bán hàng & thanh toán)*
6. `database/06_Reports.sql` *(Cài đặt các View báo cáo thống kê)*
7. `tests/07_Tests.sql` *(Chạy bộ kiểm thử chức năng - Tùy chọn)*

### Cách 1: Thực thi trong SSMS (SQL Server Management Studio)
1. Mở SSMS và kết nối tới SQL Server Instance của bạn.
2. Mở từng file `.sql` theo đúng thứ tự trên.
3. Bấm **Execute** (hoặc phím `F5`) để chạy từng file.

### Cách 2: Thực thi bằng Command Line (`sqlcmd`)
Mở Terminal / PowerShell tại thư mục dự án và chạy các lệnh sau:

```bash
sqlcmd -S . -i database\01_CreateDatabase.sql
sqlcmd -S . -i database\02_CreateTables.sql
sqlcmd -S . -i database\03_SeedData.sql
sqlcmd -S . -i database\04_Inventory.sql
sqlcmd -S . -i database\05_Sales.sql
sqlcmd -S . -i database\06_Reports.sql
sqlcmd -S . -i tests\07_Tests.sql
```

> ⚠️ **Lưu ý:** File `02_CreateTables.sql` có lệnh `DROP TABLE IF EXISTS` theo đúng thứ tự phụ thuộc khóa ngoại, giúp bạn có thể chạy lại script an toàn khi cần reset cấu trúc bảng.

---

## 6. Phạm vi hệ thống

```text
QUẢN LÝ SIÊU THỊ
│
├── 1. Quản lý danh mục & Sản phẩm
│    ├── Danh mục sản phẩm (DANH_MUC)
│    └── Sản phẩm & Tồn kho (SAN_PHAM)
│
├── 2. Quản lý đối tác & Nhân sự
│    ├── Nhà cung cấp (NHA_CUNG_CAP)
│    ├── Nhân viên (NHAN_VIEN)
│    └── Khách hàng tích điểm (KHACH_HANG)
│
├── 3. Nghiệp vụ nhập kho (Inventory)
│    ├── Lập phiếu nhập hàng (PHIEU_NHAP)
│    ├── Thêm chi tiết nhập (CT_PHIEU_NHAP)
│    └── Tự động cộng tồn kho & tính tổng tiền (Trigger)
│
├── 4. Nghiệp vụ bán hàng (Sales)
│    ├── Lập hóa đơn bán (HOA_DON)
│    ├── Thêm chi tiết hóa đơn (CT_HOA_DON)
│    ├── Kiểm tra tồn kho & Tự động trừ tồn kho (Trigger)
│    └── Hủy hóa đơn hoàn kho (Stored Procedure)
│
├── 5. Thanh toán & Khách hàng thân thiết
│    ├── Ghi nhận thanh toán (THANH_TOAN)
│    └── Tự động tính điểm thưởng khách hàng (Function)
│
└── 6. Báo cáo & Thống kê (Reports)
     ├── Lịch sử nhập hàng (vw_LichSuNhapHang)
     ├── Chi tiết hóa đơn bán hàng (vw_ChiTietHoaDon)
     ├── Doanh thu theo ngày (vw_DoanhThuTheoNgay)
     ├── Thống kê sản phẩm bán chạy (vw_SanPhamBanChay)
     └── Cảnh báo sản phẩm sắp hết (vw_SanPhamSapHet)
```

---

## 7. Các tác nhân hệ thống

* **Quản trị viên / Quản lý:** Quản lý dữ liệu danh mục, sản phẩm, nhân viên, nhà cung cấp; xem báo cáo doanh thu, sản phẩm bán chạy và cảnh báo tồn kho.
* **Nhân viên kho:** Lập phiếu nhập hàng từ nhà cung cấp, cập nhật chi tiết phiếu nhập. Hệ thống tự động tính tổng tiền và tăng số lượng tồn kho.
* **Nhân viên bán hàng / Thu ngân:** Lập hóa đơn bán hàng, thêm sản phẩm vào hóa đơn (hệ thống chặn bán nếu vượt tồn kho), thực hiện thanh toán và hủy hóa đơn chưa thanh toán khi có yêu cầu.
* **Khách hàng:** Mua hàng, nhận hóa đơn, được tích điểm thưởng theo giá trị hóa đơn (hỗ trợ cả khách vãng lai không đăng ký thông tin).

---

## 8. Mô hình dữ liệu & Bảng cơ sở dữ liệu

Cơ sở dữ liệu gồm **10 bảng** được thiết kế chuẩn hóa:

| STT | Bảng | Tên đối tượng | Chức năng chính |
| :--: | :--- | :--- | :--- |
| 1 | `DANH_MUC` | Danh mục sản phẩm | Quản lý phân loại ngành hàng |
| 2 | `SAN_PHAM` | Sản phẩm | Quản lý thông tin mặt hàng, giá bán, số lượng tồn |
| 3 | `NHA_CUNG_CAP` | Nhà cung cấp | Lưu trữ đối tác cung cấp hàng |
| 4 | `NHAN_VIEN` | Nhân viên | Lưu trữ thông tin nhân sự và chức vụ |
| 5 | `KHACH_HANG` | Khách hàng | Quản lý thông tin khách hàng và điểm tích lũy |
| 6 | `PHIEU_NHAP` | Phiếu nhập | Quản lý thông tin chung các đợt nhập hàng |
| 7 | `CT_PHIEU_NHAP` | Chi tiết phiếu nhập | Chi tiết từng mặt hàng nhập, số lượng và giá nhập |
| 8 | `HOA_DON` | Hóa đơn | Quản lý hóa đơn bán hàng và trạng thái thanh toán |
| 9 | `CT_HOA_DON` | Chi tiết hóa đơn | Chi tiết từng sản phẩm trong hóa đơn bán |
| 10 | `THANH_TOAN` | Thanh toán | Quản lý lịch sử giao dịch thanh toán hóa đơn |

### Sơ đồ quan hệ tổng quát

```text
DANH_MUC (1) ───────────< (N) SAN_PHAM
                               │
            ┌──────────────────┴──────────────────┐
            │ (1)                                 │ (1)
            ▼ (N)                                 ▼ (N)
     CT_PHIEU_NHAP                             CT_HOA_DON
            │ (N)                                 │ (N)
            ▼ (1)                                 ▼ (1)
     PHIEU_NHAP                                HOA_DON ───────────< (1) THANH_TOAN
      │       │                                 │       │
  (N) │       │ (N)                         (N) │       │ (N)
      ▼       ▼                                 ▼       ▼
NHA_CUNG_CAP NHAN_VIEN                      NHAN_VIEN KHACH_HANG (NCho/1Null)
```

---

## 9. Khóa chính, Khóa ngoại & Ràng buộc

### 9.1. Khóa chính (Primary Key)
* **Khóa đơn:**
  * `DANH_MUC(MaDM)`
  * `NHA_CUNG_CAP(MaNCC)`
  * `NHAN_VIEN(MaNV)`
  * `KHACH_HANG(MaKH)`
  * `SAN_PHAM(MaSP)`
  * `PHIEU_NHAP(MaPN)`
  * `HOA_DON(MaHD)`
  * `THANH_TOAN(MaTT)`
* **Khóa phức hợp (Composite PK):**
  * `CT_PHIEU_NHAP(MaPN, MaSP)`
  * `CT_HOA_DON(MaHD, MaSP)`

### 9.2. Khóa ngoại (Foreign Key)
* `SAN_PHAM.MaDM` $\rightarrow$ `DANH_MUC.MaDM`
* `PHIEU_NHAP.MaNCC` $\rightarrow$ `NHA_CUNG_CAP.MaNCC`
* `PHIEU_NHAP.MaNV` $\rightarrow$ `NHAN_VIEN.MaNV`
* `CT_PHIEU_NHAP.MaPN` $\rightarrow$ `PHIEU_NHAP.MaPN`
* `CT_PHIEU_NHAP.MaSP` $\rightarrow$ `SAN_PHAM.MaSP`
* `HOA_DON.MaKH` $\rightarrow$ `KHACH_HANG.MaKH` *(Cho phép NULL đối với khách vãng lai)*
* `HOA_DON.MaNV` $\rightarrow$ `NHAN_VIEN.MaNV`
* `CT_HOA_DON.MaHD` $\rightarrow$ `HOA_DON.MaHD`
* `CT_HOA_DON.MaSP` $\rightarrow$ `SAN_PHAM.MaSP`
* `THANH_TOAN.MaHD` $\rightarrow$ `HOA_DON.MaHD`

### 9.3. Ràng buộc toàn vẹn (Constraints)
* **UNIQUE Constraints:** `DANH_MUC.TenDM`, `NHA_CUNG_CAP.DienThoai`, `NHAN_VIEN.DienThoai`, `KHACH_HANG.DienThoai`, `THANH_TOAN.MaHD` (Đảm bảo 1 hóa đơn chỉ thanh toán 1 lần).
* **CHECK Constraints:**
  * `GiaBan > 0`, `SoLuongTon >= 0`
  * `SoLuongNhap > 0`, `DonGiaNhap > 0`
  * `SoLuong > 0`, `DonGia > 0`
  * `Luong > 0` (Nhân viên), `DiemTichLuy >= 0` (Khách hàng)
  * `TrangThai` hóa đơn: `IN (N'Chưa thanh toán', N'Đã thanh toán', N'Đã hủy')`
  * `PhuongThuc` thanh toán: `IN (N'Tiền mặt', N'Chuyển khoản', N'Thẻ', N'Ví điện tử')`
  * `TrangThai` thanh toán: `IN (N'Thành công', N'Thất bại')`
* **DEFAULT Constraints:**
  * `NHAN_VIEN.NgayVaoLam` = Ngày hiện tại
  * `KHACH_HANG.DiemTichLuy` = 0
  * `SAN_PHAM.SoLuongTon` = 0, `DonViTinh` = N'Cái'
  * `PHIEU_NHAP.TongTien` = 0, `NgayNhap` = Ngày hiện tại
  * `HOA_DON.TongTien` = 0, `NgayLap` = Thời gian hiện tại, `TrangThai` = N'Chưa thanh toán'

---

## 10. Các đối tượng SQL (T-SQL Objects)

### 10.1. Functions (Hàm)

| Tên Function | Tham số | Nội dung / Chức năng |
| :--- | :--- | :--- |
| `fn_KiemTraTonKho` | `@MaSP VARCHAR(10)` | Trả về số lượng tồn kho hiện tại của sản phẩm. |
| `fn_TinhThanhTien` | `@SoLuong INT, @DonGia DECIMAL` | Trả về giá trị Thành tiền (`SoLuong * DonGia`). |
| `fn_TinhTongHoaDon` | `@MaHD VARCHAR(10)` | Tính tổng tiền của hóa đơn từ bảng `CT_HOA_DON`. |
| `fn_TinhDiemKhachHang`| `@TongTien DECIMAL` | Quy đổi tổng tiền hóa đơn ra điểm thưởng (`FLOOR(TongTien / 10000)`). |

### 10.2. Stored Procedures (Thủ tục)

| Tên Stored Procedure | Chức năng & Xử lý nghiệp vụ |
| :--- | :--- |
| `sp_ThemPhieuNhap` | Tạo phiếu nhập mới. Kiểm tra mã trùng, kiểm tra sự tồn tại của NCC và NV, kiểm tra ngày nhập không ở tương lai. |
| `sp_ThemChiTietPhieuNhap`| Thêm chi tiết phiếu nhập trong `TRANSACTION`. Kiểm tra phiếu nhập, sản phẩm, số lượng/đơn giá > 0. Kích hoạt trigger tự động cập nhật tồn kho và tổng tiền phiếu nhập. |
| `sp_TaoHoaDon` | Tạo hóa đơn bán hàng mới ở trạng thái `Chưa thanh toán`. Cho phép `@MaKH` NULL (khách vãng lai). |
| `sp_ThemChiTietHoaDon` | Thêm sản phẩm vào hóa đơn chưa thanh toán. Tự động lấy giá bán hiện tại của sản phẩm. Nếu sản phẩm đã có trong hóa đơn thì cộng dồn số lượng. Kích hoạt trigger kiểm tra tồn kho và trừ tồn kho. |
| `sp_ThanhToanHoaDon` | Thực hiện thanh toán hóa đơn. Kiểm tra trạng thái hóa đơn, số tiền > 0, phương thức hợp lệ. Đổi trạng thái hóa đơn thành `Đã thanh toán`, tạo bản ghi `THANH_TOAN` và tự động tích điểm cho khách hàng. |
| `sp_HuyHoaDon` | Hủy hóa đơn chưa thanh toán trong `TRANSACTION`. Xóa các chi tiết hóa đơn (trigger sẽ hoàn trả số lượng vào kho) và chuyển trạng thái hóa đơn thành `Đã hủy`. |

### 10.3. Triggers (Cò dại / Bẫy sự kiện)

| Tên Trigger | Bảng tác động | Loại Trigger | Chức năng |
| :--- | :--- | :--- | :--- |
| `trg_CTPN_CapNhatKho` | `CT_PHIEU_NHAP` | `AFTER INSERT, UPDATE, DELETE` | Cập nhật số lượng tồn kho theo chênh lệch (`inserted` vs `deleted`). Tính toán đúng ngay cả khi thực hiện thao tác tập hợp trên nhiều dòng (Batch Processing). Tự động cập nhật `TongTien` trên `PHIEU_NHAP`. |
| `trg_CTHD_CapNhatKho` | `CT_HOA_DON` | `AFTER INSERT, UPDATE, DELETE` | Trừ số lượng tồn kho khi xuất bán. Chặn thao tác nếu hóa đơn không ở trạng thái `Chưa thanh toán`. Kiểm tra và `ROLLBACK` nếu số lượng bán vượt quá tồn kho. Tự động cập nhật `TongTien` trên `HOA_DON`. |
| `trg_KhongXoaHoaDon` | `HOA_DON` | `INSTEAD OF DELETE` | Hủy thao tác xóa trực tiếp hóa đơn và báo lỗi. Bắt buộc người dùng sử dụng `sp_HuyHoaDon` để bảo lưu lịch sử giao dịch. |

### 10.4. Views (Chế độ xem báo cáo)

| Tên View | Mục đích báo cáo |
| :--- | :--- |
| `vw_LichSuNhapHang` | Tổng hợp chi tiết lịch sử nhập hàng gồm: Mã phiếu, Ngày nhập, Nhà cung cấp, Nhân viên nhập, Tên sản phẩm, Số lượng, Đơn giá nhập, Thành tiền. |
| `vw_ChiTietHoaDon` | Tra cứu chi tiết từng dòng hóa đơn bán hàng kèm thông tin khách hàng, nhân viên bán và thành tiền. |
| `vw_DoanhThuTheoNgay` | Thống kê tổng số hóa đơn và tổng doanh thu thực tế theo từng ngày (chỉ tính hóa đơn `Đã thanh toán`). |
| `vw_SanPhamBanChay` | Thống kê sản phẩm theo tổng số lượng đã bán và tổng doanh thu mang về. |
| `vw_SanPhamSapHet` | Liệt kê các sản phẩm có số lượng tồn kho `SoLuongTon <= 20` để kịp thời lập kế hoạch nhập hàng. |

---

## 11. Quy trình nghiệp vụ chính

### 11.1. Quy trình Nhập hàng

```text
[Nhân viên Kho] ──► sp_ThemPhieuNhap ──► Tạo PHIEU_NHAP (Trạng thái mở)
                                               │
                                               ▼
                        sp_ThemChiTietPhieuNhap (Thêm sản phẩm + Số lượng + Giá)
                                               │
                                               ▼
                        Trigger trg_CTPN_CapNhatKho tự động:
                        ├── Tăng SAN_PHAM.SoLuongTon
                        └── Cập nhật PHIEU_NHAP.TongTien
```

### 11.2. Quy trình Bán hàng & Thanh toán

```text
[Thu ngân] ──► sp_TaoHoaDon ──► Tạo HOA_DON (Trạng thái: Chưa thanh toán)
                                      │
                                      ▼
               sp_ThemChiTietHoaDon ──► Trigger trg_CTHD_CapNhatKho:
                                        ├── Kiểm tra SoLuong <= SoLuongTon?
                                        │   ├── KHÔNG ──► RAISERROR & ROLLBACK
                                        │   └── CÓ ────► Trừ SAN_PHAM.SoLuongTon
                                        └── Cập nhật HOA_DON.TongTien
                                      │
                                      ▼
               sp_ThanhToanHoaDon ──► Tạo THANH_TOAN (Thành công)
                                     ├── Cập nhật HOA_DON.TrangThai = 'Đã thanh toán'
                                     └── Tích điểm cho KHACH_HANG (fn_TinhDiemKhachHang)
```

---

## 12. Kiểm thử hệ thống (Test Cases)

Bộ kiểm thử được viết trong file `tests/07_Tests.sql` nhằm xác minh hoạt động của toàn bộ hệ thống:

| Test Case ID | Kịch bản kiểm thử | Hành vi mong đợi | Kết quả |
| :--: | :--- | :--- | :--: |
| **TC01** | Nhập hàng nhiều dòng sản phẩm cùng lúc bằng `INSERT` | Tồn kho các sản phẩm tăng chính xác, `TongTien` phiếu nhập tự động cập nhật | **PASS** |
| **TC02** | Cập nhật số lượng nhập (`UPDATE CT_PHIEU_NHAP`) | Tồn kho tăng/giảm theo đúng số lượng chênh lệch (Delta) | **PASS** |
| **TC03** | Thêm chi tiết phiếu nhập với số lượng âm (`-1`) | Procedure ném lỗi `51008`, bị chặn thành công | **PASS** |
| **TC04** | Bán sản phẩm với số lượng vượt tồn kho (`999999`) | Trigger ném lỗi tồn kho không đủ, giao dịch bị `ROLLBACK` | **PASS** |
| **TC05** | Hủy hóa đơn chưa thanh toán (`sp_HuyHoaDon`) | Hóa đơn đổi thành `Đã hủy`, số lượng sản phẩm được hoàn trả lại kho | **PASS** |
| **TC06** | Xóa trực tiếp hóa đơn (`DELETE FROM HOA_DON`) | Trigger `trg_KhongXoaHoaDon` chặn thao tác, thông báo dùng `sp_HuyHoaDon` | **PASS** |

---

## 13. Trạng thái dự án

- [x] Phân tích bài toán & Yêu cầu nghiệp vụ
- [x] Xác định thực thể & Thuộc tính
- [x] Thiết kế khóa chính, khóa ngoại & Mô hình quan hệ (3NF)
- [x] Đầy đủ các ràng buộc toàn vẹn (`NOT NULL`, `UNIQUE`, `CHECK`, `DEFAULT`)
- [x] Viết script khởi tạo cơ sở dữ liệu (`01_CreateDatabase.sql`)
- [x] Viết script tạo bảng & chỉ mục (`02_CreateTables.sql`)
- [x] Nạp dữ liệu mẫu phong phú (`03_SeedData.sql`)
- [x] Cài đặt nghiệp vụ Nhập kho & Trigger tồn kho (`04_Inventory.sql`)
- [x] Cài đặt nghiệp vụ Bán hàng, Thanh toán & Hủy hóa đơn (`05_Sales.sql`)
- [x] Cài đặt chế độ xem báo cáo & thống kê (`06_Reports.sql`)
- [x] Viết kịch bản kiểm thử tự động (`07_Tests.sql`)
- [x] Hoàn thiện tài liệu thuyết minh chi tiết (`docs/QLST.md`)
- [x] Hoàn thiện tài liệu hướng dẫn (`README.md`)

---

## 14. Phân công công việc & Quy tắc nhóm

### 14.1. Phân công vai trò

| Thành viên | Vai trò | Trách nhiệm chính |
| :--- | :--- | :--- |
| **TV1** | Trưởng nhóm / Database Architect | Phân tích bài toán, thiết kế ERD, Mô hình quan hệ, định nghĩa PK/FK, Review mã nguồn & tài liệu. |
| **TV2** | Database Developer | Xây dựng script tạo Database, Tables, Indexes, Constraints và nạp Seed Data. |
| **TV3** | Inventory Developer | Xây dựng Stored Procedures, Functions, Trigger xử lý kho & phiếu nhập. |
| **TV4** | Sales Developer | Xây dựng Stored Procedures, Functions, Trigger bán hàng, thanh toán & hủy hóa đơn. |
| **TV5** | SQL Analyst / QA | Thiết kế Views báo cáo thống kê, viết Test Cases kiểm thử & tổng hợp báo cáo. |

### 14.2. Quy tắc làm việc nhóm

1. **Chuẩn hóa cấu trúc CSDL:** Không tự ý sửa đổi tên bảng, tên cột, kiểu dữ liệu hoặc khóa chính/ngoại khi chưa có sự thống nhất của nhóm.
2. **Quy tắc đặt tên (Naming Convention):**
   * Bảng & Cột: Sử dụng chữ hoa hoa phân cách bằng dấu gạch dưới (VD: `SAN_PHAM`, `SoLuongTon`).
   * Stored Procedure: Tiền tố `sp_` (VD: `sp_TaoHoaDon`).
   * Function: Tiền tố `fn_` (VD: `fn_TinhTongHoaDon`).
   * Trigger: Tiền tố `trg_` (VD: `trg_CTHD_CapNhatKho`).
   * View: Tiền tố `vw_` (VD: `vw_DoanhThuTheoNgay`).
3. **Quản lý mã nguồn:** Thực thi và kiểm thử kịch bản cá nhân trước khi thực hiện Pull Request/Commit lên repository chung.

---

## 15. Kết luận & Hướng phát triển

### 15.1. Kết luận
Dự án **Hệ thống Quản lý Siêu thị** đã giải quyết trọn vẹn các yêu cầu quản lý cơ bản trong siêu thị. Việc ứng dụng linh hoạt các đối tượng nâng cao trong SQL Server (Stored Procedures, Functions, Triggers, Views, Transactions) giúp hệ thống hoạt động ổn định, chính xác, tự động hóa cập nhật tồn kho và bảo vệ dữ liệu khỏi các thao tác không hợp lệ.

### 15.2. Hướng phát triển trong tương lai
- **Phân quyền & Bảo mật:** Bổ sung bảng tài khoản, vai trò (Roles) và phân quyền truy cập theo từng chức vụ (Quản lý, Thu ngân, Kiểm kho).
- **Quản lý nâng cao:** Bổ sung quản lý mã giảm giá, chương trình khuyến mãi, thuế VAT, hạn sử dụng sản phẩm (Batch/Expiry Date) và quản lý nhiều chi nhánh.
- **Tích hợp ứng dụng:** Xây dựng phần mềm giao diện người dùng (Desktop App / Web App) kết nối tới CSDL SQL Server để phục vụ thao tác bán hàng tại điểm bán (POS).

---
*Báo cáo môn học Hệ quản trị Cơ sở dữ liệu.*
