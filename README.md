# 🛒 HỆ THỐNG QUẢN LÝ SIÊU THỊ

## 1. Giới thiệu

**Hệ thống Quản lý Siêu thị** là bài tập lớn môn **Hệ quản trị cơ sở dữ liệu**, được xây dựng trên **Microsoft SQL Server** và sử dụng ngôn ngữ **T-SQL**.

Hệ thống được thiết kế nhằm quản lý các nghiệp vụ cơ bản của một siêu thị như:

* Quản lý danh mục sản phẩm
* Quản lý sản phẩm
* Quản lý nhà cung cấp
* Quản lý nhân viên
* Quản lý khách hàng
* Quản lý nhập hàng
* Quản lý tồn kho
* Quản lý bán hàng
* Quản lý hóa đơn
* Quản lý thanh toán
* Thống kê và báo cáo

---

# 2. Mục tiêu dự án

Dự án nhằm xây dựng một cơ sở dữ liệu có cấu trúc rõ ràng, đảm bảo tính toàn vẹn và hỗ trợ các nghiệp vụ chính của siêu thị.

Các mục tiêu chính:

* Phân tích bài toán quản lý siêu thị.
* Xác định các đối tượng và nghiệp vụ của hệ thống.
* Thiết kế mô hình dữ liệu phù hợp.
* Xác định các thuộc tính, khóa chính và khóa ngoại.
* Xác định các mối quan hệ giữa các bảng.
* Xây dựng cơ sở dữ liệu trên SQL Server.
* Sử dụng Constraint để đảm bảo tính toàn vẹn dữ liệu.
* Xây dựng View phục vụ truy vấn và báo cáo.
* Xây dựng Stored Procedure phục vụ nghiệp vụ.
* Xây dựng Function phục vụ tính toán.
* Xây dựng Trigger để tự động xử lý dữ liệu.
* Kiểm thử các chức năng và ràng buộc của hệ thống.

---

# 3. Công nghệ sử dụng

| Công nghệ                           | Mục đích                            |
| ----------------------------------- | ----------------------------------- |
| Microsoft SQL Server                | Hệ quản trị cơ sở dữ liệu           |
| T-SQL                               | Ngôn ngữ truy vấn và lập trình CSDL |
| SQL Server Management Studio (SSMS) | Quản lý và thực thi SQL             |
| Git / GitHub                        | Quản lý mã nguồn và làm việc nhóm   |
| Draw.io / ERD Tool                  | Thiết kế sơ đồ ERD                  |
| Microsoft Excel                     | Quản lý tiến độ và phân công        |

---

# 4. Phạm vi hệ thống

Hệ thống tập trung vào các nghiệp vụ chính:

```text
QUẢN LÝ SIÊU THỊ
│
├── Quản lý danh mục
├── Quản lý sản phẩm
├── Quản lý nhà cung cấp
├── Quản lý nhân viên
├── Quản lý khách hàng
│
├── Quản lý nhập hàng
├── Quản lý tồn kho
│
├── Quản lý bán hàng
├── Quản lý hóa đơn
├── Quản lý thanh toán
│
└── Thống kê và báo cáo
```

Các chức năng như quản lý lương, chấm công, nhiều chi nhánh hoặc hệ thống khuyến mãi nâng cao không nằm trong phạm vi phiên bản hiện tại.

---

# 5. Các tác nhân

Hệ thống gồm các tác nhân chính:

### 5.1. Quản trị viên

Có thể:

* Quản lý dữ liệu hệ thống.
* Quản lý nhân viên.
* Quản lý sản phẩm.
* Quản lý danh mục.
* Kiểm tra dữ liệu.

### 5.2. Nhân viên

Có thể:

* Bán hàng.
* Lập hóa đơn.
* Nhập hàng.
* Tra cứu sản phẩm.
* Tra cứu khách hàng.

### 5.3. Quản lý

Có thể:

* Theo dõi doanh thu.
* Theo dõi tồn kho.
* Xem sản phẩm bán chạy.
* Xem báo cáo nhập hàng.
* Theo dõi hoạt động kinh doanh.

---

# 6. Mô hình dữ liệu

Các bảng chính của hệ thống:

| STT | Bảng            | Chức năng            |
| --: | --------------- | -------------------- |
|   1 | `DANH_MUC`      | Quản lý danh mục     |
|   2 | `SAN_PHAM`      | Quản lý sản phẩm     |
|   3 | `NHA_CUNG_CAP`  | Quản lý nhà cung cấp |
|   4 | `NHAN_VIEN`     | Quản lý nhân viên    |
|   5 | `KHACH_HANG`    | Quản lý khách hàng   |
|   6 | `PHIEU_NHAP`    | Quản lý phiếu nhập   |
|   7 | `CT_PHIEU_NHAP` | Chi tiết phiếu nhập  |
|   8 | `HOA_DON`       | Quản lý hóa đơn      |
|   9 | `CT_HOA_DON`    | Chi tiết hóa đơn     |
|  10 | `THANH_TOAN`    | Quản lý thanh toán   |

---

# 7. Quan hệ giữa các bảng

Mô hình quan hệ tổng quát:

```text
DANH_MUC
    │
    │ 1 - N
    ▼
SAN_PHAM
    │
    ├───────────────┐
    │               │
    ▼               ▼
CT_PHIEU_NHAP    CT_HOA_DON
    │               │
    ▼               ▼
PHIEU_NHAP        HOA_DON
    │               │
    │               ├── KHACH_HANG
    │               │
    │               ├── NHAN_VIEN
    │               │
    │               └── THANH_TOAN
    │
    ├── NHA_CUNG_CAP
    │
    └── NHAN_VIEN
```

---

# 8. Khóa chính và khóa ngoại

### Primary Key

Một số PK chính:

```text
DANH_MUC.MaDM
SAN_PHAM.MaSP
NHA_CUNG_CAP.MaNCC
NHAN_VIEN.MaNV
KHACH_HANG.MaKH
PHIEU_NHAP.MaPN
HOA_DON.MaHD
THANH_TOAN.MaTT
```

### Composite Primary Key

Hai bảng chi tiết sử dụng khóa chính ghép:

```text
CT_PHIEU_NHAP
PK = (MaPN, MaSP)

CT_HOA_DON
PK = (MaHD, MaSP)
```

### Foreign Key

Ví dụ:

```text
SAN_PHAM.MaDM
    → DANH_MUC.MaDM

PHIEU_NHAP.MaNCC
    → NHA_CUNG_CAP.MaNCC

PHIEU_NHAP.MaNV
    → NHAN_VIEN.MaNV

CT_PHIEU_NHAP.MaPN
    → PHIEU_NHAP.MaPN

CT_PHIEU_NHAP.MaSP
    → SAN_PHAM.MaSP

HOA_DON.MaKH
    → KHACH_HANG.MaKH

HOA_DON.MaNV
    → NHAN_VIEN.MaNV

CT_HOA_DON.MaHD
    → HOA_DON.MaHD

CT_HOA_DON.MaSP
    → SAN_PHAM.MaSP

THANH_TOAN.MaHD
    → HOA_DON.MaHD
```

---

# 9. Ràng buộc dữ liệu

Hệ thống sử dụng các ràng buộc nhằm đảm bảo tính toàn vẹn dữ liệu.

### 9.1. Primary Key

Đảm bảo mỗi bản ghi có mã định danh duy nhất.

### 9.2. Foreign Key

Đảm bảo dữ liệu giữa các bảng có mối liên hệ hợp lệ.

### 9.3. NOT NULL

Các trường bắt buộc không được để trống.

### 9.4. UNIQUE

Đảm bảo các dữ liệu như số điện thoại hoặc email không bị trùng nếu nghiệp vụ yêu cầu.

### 9.5. CHECK

Ví dụ:

```sql
GiaBan > 0
SoLuong > 0
SoLuongTon >= 0
```

### 9.6. DEFAULT

Ví dụ:

```text
DiemTichLuy = 0
SoLuongTon = 0
```

---

# 10. Các đối tượng SQL

## 10.1. View

View được sử dụng để phục vụ các truy vấn và báo cáo thường xuyên.

Dự kiến:

```text
vw_ChiTietHoaDon
vw_DoanhThu
vw_SanPhamBanChay
vw_SanPhamSapHet
```

---

## 10.2. Stored Procedure

Stored Procedure được sử dụng để thực hiện các nghiệp vụ của hệ thống.

Dự kiến:

```text
sp_ThemPhieuNhap
sp_TraCuuPhieuNhap
sp_TaoHoaDon
sp_TraCuuHoaDon
sp_TimKiemSanPham
sp_ThongKeDoanhThu
```

---

## 10.3. Function

Function được sử dụng cho các nghiệp vụ tính toán.

Dự kiến:

```text
fn_TinhThanhTien
fn_TinhTongHoaDon
fn_TinhDiemKhachHang
```

---

## 10.4. Trigger

Trigger được sử dụng để tự động xử lý dữ liệu sau khi có thay đổi.

### Nhập hàng

```text
PHIEU_NHAP
      ↓
CT_PHIEU_NHAP
      ↓
TRIGGER
      ↓
Tăng SAN_PHAM.SoLuongTon
```

### Bán hàng

```text
HOA_DON
      ↓
CT_HOA_DON
      ↓
TRIGGER
      ↓
Giảm SAN_PHAM.SoLuongTon
```

### Kiểm tra tồn kho

Hệ thống không cho phép bán sản phẩm nếu:

```text
SoLuongBan > SoLuongTon
```

---

# 11. Quy trình nghiệp vụ chính

## 11.1. Nhập hàng

```text
Chọn nhà cung cấp
        ↓
Nhân viên lập phiếu nhập
        ↓
Chọn sản phẩm
        ↓
Nhập số lượng + giá nhập
        ↓
Lưu chi tiết phiếu nhập
        ↓
Cập nhật tồn kho
```

## 11.2. Bán hàng

```text
Khách hàng
    ↓
Nhân viên
    ↓
Chọn sản phẩm
    ↓
Kiểm tra tồn kho
    ↓
Tạo hóa đơn
    ↓
Thêm chi tiết hóa đơn
    ↓
Thanh toán
    ↓
Giảm tồn kho
```

---

# 12. Phân công thành viên

| Thành viên | Vai trò                          | Công việc                                                |
| ---------- | -------------------------------- | -------------------------------------------------------- |
| TV1        | Trưởng nhóm / Database Architect | Phân tích, ERD, thiết kế CSDL, PK/FK, constraint, review |
| TV2        | Database Developer               | Tạo database, tables, PK/FK, dữ liệu mẫu                 |
| TV3        | Inventory Developer              | Nhập hàng, Procedure và Trigger tồn kho                  |
| TV4        | Sales Developer                  | Bán hàng, Function, Procedure, Trigger                   |
| TV5        | SQL Analyst / QA                 | View, thống kê, kiểm thử, hỗ trợ báo cáo                 |

---

# 13. Cấu trúc thư mục dự án

Đề xuất cấu trúc repository:

```text
QuanLySieuThi/
│
├── README.md
│
├── docs/
│   ├── PhanTichBaiToan.docx
│   ├── ERD.png
│   ├── MoHinhQuanHe.png
│   └── BaoCao.docx
│
├── database/
│   ├── 01_CreateDatabase.sql
│   ├── 02_CreateTables.sql
│   ├── 03_Constraints.sql
│   └── 04_InsertData.sql
│
├── views/
│   └── Views.sql
│
├── functions/
│   └── Functions.sql
│
├── procedures/
│   └── StoredProcedures.sql
│
├── triggers/
│   └── Triggers.sql
│
├── tests/
│   └── TestCases.sql
│
└── project-management/
    └── Template_Quan_Ly_Sieu_Thi.xlsx
```

---

# 14. Quy tắc làm việc nhóm

### Trước khi code

Không tự ý thay đổi:

* Tên bảng.
* Tên cột.
* PK.
* FK.
* Kiểu dữ liệu.
* Quan hệ giữa các bảng.

Mọi thay đổi lớn phải được thống nhất với trưởng nhóm.

### Khi code

Mỗi thành viên làm đúng module được giao.

Ví dụ:

```text
TV2 → database/
TV3 → procedures/ + triggers/ nhập hàng
TV4 → functions/ + procedures/ + triggers/ bán hàng
TV5 → views/ + tests/
```

### Khi hoàn thành

Thành viên phải:

1. Test code.
2. Ghi chú những thay đổi.
3. Đưa code lên repository.
4. Thông báo cho trưởng nhóm.
5. Trưởng nhóm review trước khi tích hợp.

---

# 15. Quy trình phát triển

```text
PHÂN TÍCH
    ↓
XÁC ĐỊNH THỰC THỂ
    ↓
XÁC ĐỊNH THUỘC TÍNH
    ↓
PK / FK
    ↓
ERD
    ↓
MÔ HÌNH QUAN HỆ
    ↓
CREATE DATABASE
    ↓
CREATE TABLE
    ↓
INSERT DATA
    ↓
VIEW / FUNCTION / PROCEDURE / TRIGGER
    ↓
KIỂM THỬ
    ↓
HOÀN THIỆN BÁO CÁO
    ↓
THUYẾT TRÌNH / DEMO
```

---

# 16. Kiểm thử

Các trường hợp cần kiểm thử:

### Sản phẩm

* Thêm sản phẩm hợp lệ.
* Không cho phép trùng mã sản phẩm.
* Không cho phép giá bán <= 0.
* Không cho phép tồn kho < 0.

### Nhập hàng

* Tạo phiếu nhập.
* Thêm chi tiết phiếu nhập.
* Kiểm tra số lượng nhập.
* Kiểm tra Trigger tăng tồn kho.

### Bán hàng

* Tạo hóa đơn.
* Thêm sản phẩm vào hóa đơn.
* Kiểm tra tồn kho.
* Không cho bán vượt tồn.
* Kiểm tra Trigger giảm tồn kho.
* Kiểm tra tổng tiền.

### Thanh toán

* Kiểm tra số tiền thanh toán.
* Kiểm tra phương thức thanh toán.
* Đảm bảo hóa đơn tồn tại trước khi thanh toán.

### Báo cáo

* Kiểm tra doanh thu.
* Kiểm tra sản phẩm bán chạy.
* Kiểm tra sản phẩm sắp hết.
* Kiểm tra dữ liệu View.

---

# 17. Kết quả dự kiến

Sau khi hoàn thành, hệ thống có thể:

* Quản lý thông tin sản phẩm.
* Quản lý danh mục.
* Quản lý nhà cung cấp.
* Quản lý nhân viên.
* Quản lý khách hàng.
* Quản lý quá trình nhập hàng.
* Tự động cập nhật tồn kho.
* Quản lý quá trình bán hàng.
* Tạo và quản lý hóa đơn.
* Quản lý thanh toán.
* Thống kê doanh thu.
* Thống kê sản phẩm bán chạy.
* Kiểm soát các ràng buộc dữ liệu.
* Minh họa việc sử dụng View, Function, Stored Procedure và Trigger trong SQL Server.

---

# 18. Trạng thái dự án

```text
[ ] Phân tích bài toán
[ ] Xác định thực thể
[ ] Xác định thuộc tính
[ ] Xác định PK/FK
[ ] Xác định ràng buộc
[ ] Hoàn thành ERD
[ ] Hoàn thành mô hình quan hệ
[ ] Tạo Database
[ ] Tạo Tables
[ ] Insert dữ liệu mẫu
[ ] Hoàn thành Views
[ ] Hoàn thành Functions
[ ] Hoàn thành Stored Procedures
[ ] Hoàn thành Triggers
[ ] Kiểm thử
[ ] Hoàn thành báo cáo
[ ] Hoàn thành slide
[ ] Demo
[ ] Thuyết trình
```

---

# 19. Thành viên

**Nhóm:** 5 thành viên

| STT | Thành viên | Vai trò             |
| --: | ---------- | ------------------- |
|   1 | TV1        | Trưởng nhóm         |
|   2 | TV2        | Database Developer  |
|   3 | TV3        | Inventory Developer |
|   4 | TV4        | Sales Developer     |
|   5 | TV5        | SQL Analyst / QA    |

> Cập nhật tên thành viên thực tế của nhóm trước khi nộp báo cáo.

---

# 20. Kết luận

Dự án **Hệ thống Quản lý Siêu thị** áp dụng kiến thức về hệ quản trị cơ sở dữ liệu để xây dựng một hệ thống quản lý dữ liệu có cấu trúc và đảm bảo tính toàn vẹn.

Thông qua dự án, nhóm thực hành các kiến thức:

* Phân tích bài toán.
* Thiết kế ERD.
* Mô hình quan hệ.
* Primary Key / Foreign Key.
* Constraint.
* SQL Server.
* T-SQL.
* View.
* Stored Procedure.
* Function.
* Trigger.
* Kiểm thử cơ sở dữ liệu.
* Làm việc nhóm và quản lý mã nguồn.
