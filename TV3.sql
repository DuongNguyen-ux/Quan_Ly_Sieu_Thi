USE QuanLySieuThi;
GO

-- 1. TẠO BẢNG DỮ LIỆU
CREATE TABLE PHIEU_NHAP (
    MaPN        VARCHAR(10)     NOT NULL PRIMARY KEY,
    NgayNhap    DATE            NOT NULL DEFAULT GETDATE(),
    MaNCC       VARCHAR(10)     NOT NULL REFERENCES NHA_CUNG_CAP(MaNCC) ON UPDATE CASCADE,
    MaNV        VARCHAR(10)     NOT NULL REFERENCES NHAN_VIEN(MaNV) ON UPDATE CASCADE,
    TongTien    DECIMAL(18, 2)  NOT NULL DEFAULT 0 CHECK (TongTien >= 0)
);
GO

CREATE TABLE CT_PHIEU_NHAP (
    MaPN        VARCHAR(10)     NOT NULL REFERENCES PHIEU_NHAP(MaPN) ON DELETE CASCADE,
    MaSP        VARCHAR(10)     NOT NULL REFERENCES SAN_PHAM(MaSP) ON UPDATE CASCADE,
    SoLuongNhap INT             NOT NULL CHECK (SoLuongNhap > 0),
    DonGiaNhap  DECIMAL(18, 2)  NOT NULL CHECK (DonGiaNhap >= 0),
    PRIMARY KEY (MaPN, MaSP)
);
GO

-- 2. ĐỐI TƯỢNG 1: VIEW (KHUNG NHÌN)
-- Xem lịch sử nhập hàng chi tiết
CREATE VIEW vw_LichSuNhapHang AS
SELECT 
    PN.MaPN, PN.NgayNhap, NCC.TenNCC, NV.HoTen AS NhanVienNhap, 
    SP.TenSP, CT.SoLuongNhap, CT.DonGiaNhap
FROM PHIEU_NHAP PN
JOIN CT_PHIEU_NHAP CT ON PN.MaPN = CT.MaPN
JOIN SAN_PHAM SP ON CT.MaSP = SP.MaSP
JOIN NHA_CUNG_CAP NCC ON PN.MaNCC = NCC.MaNCC
JOIN NHAN_VIEN NV ON PN.MaNV = NV.MaNV;
GO

-- 3. ĐỐI TƯỢNG 2: FUNCTION (HÀM)
-- Kiểm tra số lượng tồn kho hiện tại của 1 sản phẩm
CREATE FUNCTION fn_KiemTraTonKho (@MaSP VARCHAR(10))
RETURNS INT
AS
BEGIN
    DECLARE @TonKho INT;
    SELECT @TonKho = SoLuongTon FROM SAN_PHAM WHERE MaSP = @MaSP;
    RETURN @TonKho;
END;
GO

-- 4. ĐỐI TƯỢNG 3: STORED PROCEDURE (THỦ TỤC) & GIAO TÁC (TRANSACTION)
-- Procedure 1: Tạo phiếu nhập (Tạo Header)
CREATE PROCEDURE sp_ThemPhieuNhap
    @MaPN VARCHAR(10), @MaNCC VARCHAR(10), @MaNV VARCHAR(10), @NgayNhap DATE
AS
BEGIN
    INSERT INTO PHIEU_NHAP (MaPN, NgayNhap, MaNCC, MaNV, TongTien)
    VALUES (@MaPN, @NgayNhap, @MaNCC, @MaNV, 0);
END;
GO

-- Procedure 2: Thêm chi tiết phiếu nhập (Sử dụng Giao tác)
CREATE PROCEDURE sp_ThemChiTietPhieuNhap
    @MaPN VARCHAR(10), @MaSP VARCHAR(10), @SoLuongNhap INT, @DonGiaNhap DECIMAL(18,2)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION; 
        
        INSERT INTO CT_PHIEU_NHAP (MaPN, MaSP, SoLuongNhap, DonGiaNhap)
        VALUES (@MaPN, @MaSP, @SoLuongNhap, @DonGiaNhap);
        
        COMMIT TRANSACTION;
        PRINT N'Thêm chi tiết phiếu nhập thành công!';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT N'Lỗi: Đã hủy bỏ thao tác để bảo vệ dữ liệu.';
    END CATCH
END;
GO

-- 5. ĐỐI TƯỢNG 4: TRIGGER (TRÌNH KÍCH HOẠT)
-- Trigger 1: Tự động cộng tồn kho và tiền khi nhập hàng
CREATE TRIGGER trg_CapNhatTonKho_SauNhap
ON CT_PHIEU_NHAP
AFTER INSERT
AS
BEGIN
    UPDATE SAN_PHAM
    SET SoLuongTon = SoLuongTon + inserted.SoLuongNhap
    FROM SAN_PHAM JOIN inserted ON SAN_PHAM.MaSP = inserted.MaSP;

    UPDATE PHIEU_NHAP
    SET TongTien = TongTien + (inserted.SoLuongNhap * inserted.DonGiaNhap)
    FROM PHIEU_NHAP JOIN inserted ON PHIEU_NHAP.MaPN = inserted.MaPN;
END;
GO

-- Trigger 2: Trừ lại tồn kho và tiền nếu xóa nhầm chi tiết phiếu nhập
CREATE TRIGGER trg_HoanTonKho_SauXoa
ON CT_PHIEU_NHAP
AFTER DELETE
AS
BEGIN
    UPDATE SAN_PHAM
    SET SoLuongTon = SoLuongTon - deleted.SoLuongNhap
    FROM SAN_PHAM JOIN deleted ON SAN_PHAM.MaSP = deleted.MaSP;

    UPDATE PHIEU_NHAP
    SET TongTien = TongTien - (deleted.SoLuongNhap * deleted.DonGiaNhap)
    FROM PHIEU_NHAP JOIN deleted ON PHIEU_NHAP.MaPN = deleted.MaPN;
END;
GO

-- 6. KIỂM THỬ (TEST)
EXEC sp_ThemPhieuNhap 'PN01', 'NCC01', 'NV01', '2026-08-17';
EXEC sp_ThemChiTietPhieuNhap 'PN01', 'SP01', 50, 4000;
EXEC sp_ThemChiTietPhieuNhap 'PN01', 'SP02', 10, 150000;

SELECT dbo.fn_KiemTraTonKho('SP01') AS TonKho_SP01;
SELECT * FROM vw_LichSuNhapHang;
GO