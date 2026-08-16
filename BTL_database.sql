USE master;
GO

-- 1. TẠO CƠ SỞ DỮ LIỆU
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'QuanLySieuThi')
BEGIN
    CREATE DATABASE QuanLySieuThi;
END;
GO

USE QuanLySieuThi;
GO

-- Xóa các bảng cũ theo đúng thứ tự ràng buộc khóa ngoại (nếu có chạy lại)
DROP TABLE IF EXISTS KHACH_HANG;
DROP TABLE IF EXISTS NHAN_VIEN;
DROP TABLE IF EXISTS SAN_PHAM;
DROP TABLE IF EXISTS NHA_CUNG_CAP;
DROP TABLE IF EXISTS DANH_MUC;
GO

-- 2. KHỞI TẠO CÁC BẢNG NỀN TẢNG VÀ CÁC RÀNG BUỘC (PK, FK, CHECK, DEFAULT, UNIQUE)

CREATE TABLE DANH_MUC (
    MaDM VARCHAR(10) NOT NULL,
    TenDM NVARCHAR(100) NOT NULL,
    
    CONSTRAINT PK_DANH_MUC PRIMARY KEY (MaDM),
    CONSTRAINT UQ_TenDM UNIQUE (TenDM)
);
GO

CREATE TABLE NHA_CUNG_CAP (
    MaNCC VARCHAR(10) NOT NULL,
    TenNCC NVARCHAR(150) NOT NULL,
    DiaChi NVARCHAR(255) NULL,
    DienThoai VARCHAR(15) NOT NULL,
    Email VARCHAR(100) NULL,
    
    CONSTRAINT PK_NHA_CUNG_CAP PRIMARY KEY (MaNCC),
    CONSTRAINT UQ_NCC_DienThoai UNIQUE (DienThoai),
    CONSTRAINT CK_NCC_Email CHECK (Email LIKE '%@%.%') -- Ràng buộc định dạng email
);
GO

CREATE TABLE SAN_PHAM (
    MaSP VARCHAR(10) NOT NULL,
    TenSP NVARCHAR(150) NOT NULL,
    DonViTinh NVARCHAR(30) NOT NULL DEFAULT N'Cái',
    GiaBan DECIMAL(18, 2) NOT NULL DEFAULT 0,
    SoLuongTon INT NOT NULL DEFAULT 0,
    MaDM VARCHAR(10) NOT NULL,
    
    CONSTRAINT PK_SAN_PHAM PRIMARY KEY (MaSP),
    CONSTRAINT CK_SP_GiaBan CHECK (GiaBan >= 0),
    CONSTRAINT CK_SP_SoLuong CHECK (SoLuongTon >= 0),
    CONSTRAINT FK_SP_DANHMUC FOREIGN KEY (MaDM) REFERENCES DANH_MUC(MaDM) ON UPDATE CASCADE
);
GO

CREATE TABLE NHAN_VIEN (
    MaNV VARCHAR(10) NOT NULL,
    HoTen NVARCHAR(100) NOT NULL,
    ChucVu NVARCHAR(50) NOT NULL DEFAULT N'Nhân viên bán hàng',
    DienThoai VARCHAR(15) NOT NULL,
    NgayVaoLam DATE NOT NULL DEFAULT GETDATE(),
    Luong DECIMAL(18, 2) NOT NULL,
    
    CONSTRAINT PK_NHAN_VIEN PRIMARY KEY (MaNV),
    CONSTRAINT UQ_NV_DienThoai UNIQUE (DienThoai),
    CONSTRAINT CK_NV_Luong CHECK (Luong > 0)
);
GO

CREATE TABLE KHACH_HANG (
    MaKH VARCHAR(10) NOT NULL,
    HoTen NVARCHAR(100) NOT NULL,
    DienThoai VARCHAR(15) NOT NULL,
    DiemTichLuy INT NOT NULL DEFAULT 0,
    
    CONSTRAINT PK_KHACH_HANG PRIMARY KEY (MaKH),
    CONSTRAINT UQ_KH_DienThoai UNIQUE (DienThoai),
    CONSTRAINT CK_KH_Diem CHECK (DiemTichLuy >= 0)
);
GO

-- 3. NẠP DỮ LIỆU MẪU (SEED DATA) Cho 5 bảng cơ bản

INSERT INTO DANH_MUC (MaDM, TenDM) VALUES 
('DM01', N'Thực phẩm khô'),
('DM02', N'Hóa mỹ phẩm'),
('DM03', N'Đồ uống giải khát');

INSERT INTO NHA_CUNG_CAP (MaNCC, TenNCC, DiaChi, DienThoai, Email) VALUES 
('NCC01', N'Công ty Unilever Việt Nam', N'Quận 7, TP.HCM', '0281234567', 'info@unilever.com'),
('NCC02', N'Công ty CP Acecook Việt Nam', N'Quận Tân Phú, TP.HCM', '0287654321', 'contact@acecook.vn');

INSERT INTO SAN_PHAM (MaSP, TenSP, DonViTinh, GiaBan, SoLuongTon, MaDM) VALUES 
('SP01', N'Mì Hảo Hảo Tôm Chua Cay', N'Gói', 4500, 500, 'DM01'),
('SP02', N'Dầu gội Clear Bạc Hà 650g', N'Chai', 155000, 50, 'DM02'),
('SP03', N'Nước khoáng Aquafina 500ml', N'Chai', 6000, 200, 'DM03');

INSERT INTO NHAN_VIEN (MaNV, HoTen, ChucVu, DienThoai, Luong) VALUES 
('NV01', N'Nguyễn Văn Hùng', N'Quản lý siêu thị', '0912345678', 15000000),
('NV02', N'Lê Thị Mai', N'Nhân viên bán hàng', '0987654321', 7000000);

INSERT INTO KHACH_HANG (MaKH, HoTen, DienThoai, DiemTichLuy) VALUES 
('KH01', N'Phạm Minh Tuấn', '0909112233', 120),
('KH02', N'Hoàng Thu Thủy', '0933445566', 45);
GO

SELECT * FROM SAN_PHAM;