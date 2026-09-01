USE QuanLySieuThi;
GO

DROP VIEW IF EXISTS vw_LichSuNhapHang;
DROP TRIGGER IF EXISTS trg_CTPN_CapNhatKho;
DROP PROCEDURE IF EXISTS sp_ThemChiTietPhieuNhap;
DROP PROCEDURE IF EXISTS sp_ThemPhieuNhap;
DROP FUNCTION IF EXISTS fn_KiemTraTonKho;
GO

CREATE VIEW vw_LichSuNhapHang AS
SELECT PN.MaPN, PN.NgayNhap, NCC.TenNCC, NV.HoTen AS NhanVienNhap,
       SP.MaSP, SP.TenSP, CT.SoLuongNhap, CT.DonGiaNhap,
       CT.SoLuongNhap * CT.DonGiaNhap AS ThanhTien
FROM PHIEU_NHAP PN
JOIN CT_PHIEU_NHAP CT ON CT.MaPN = PN.MaPN
JOIN SAN_PHAM SP ON SP.MaSP = CT.MaSP
JOIN NHA_CUNG_CAP NCC ON NCC.MaNCC = PN.MaNCC
JOIN NHAN_VIEN NV ON NV.MaNV = PN.MaNV;
GO

CREATE FUNCTION fn_KiemTraTonKho(@MaSP VARCHAR(10))
RETURNS INT
AS
BEGIN
    RETURN ISNULL((SELECT SoLuongTon FROM SAN_PHAM WHERE MaSP = @MaSP), 0);
END;
GO

CREATE PROCEDURE sp_ThemPhieuNhap
    @MaPN VARCHAR(10), @MaNCC VARCHAR(10), @MaNV VARCHAR(10), @NgayNhap DATE = NULL
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    BEGIN TRY
        IF NULLIF(LTRIM(RTRIM(@MaPN)), '') IS NULL THROW 51001, N'Mã phiếu nhập không hợp lệ.', 1;
        IF EXISTS (SELECT 1 FROM PHIEU_NHAP WHERE MaPN = @MaPN) THROW 51002, N'Mã phiếu nhập đã tồn tại.', 1;
        IF NOT EXISTS (SELECT 1 FROM NHA_CUNG_CAP WHERE MaNCC = @MaNCC) THROW 51003, N'Nhà cung cấp không tồn tại.', 1;
        IF NOT EXISTS (SELECT 1 FROM NHAN_VIEN WHERE MaNV = @MaNV) THROW 51004, N'Nhân viên không tồn tại.', 1;
        SET @NgayNhap = ISNULL(@NgayNhap, CONVERT(date, GETDATE()));
        IF @NgayNhap > CONVERT(date, GETDATE()) THROW 51005, N'Ngày nhập không được ở tương lai.', 1;
        INSERT INTO PHIEU_NHAP(MaPN, NgayNhap, MaNCC, MaNV) VALUES(@MaPN, @NgayNhap, @MaNCC, @MaNV);
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH;
END;
GO

CREATE PROCEDURE sp_ThemChiTietPhieuNhap
    @MaPN VARCHAR(10), @MaSP VARCHAR(10), @SoLuongNhap INT, @DonGiaNhap DECIMAL(18,2)
AS
BEGIN
    SET NOCOUNT ON; SET XACT_ABORT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        IF NOT EXISTS (SELECT 1 FROM PHIEU_NHAP WITH (UPDLOCK, HOLDLOCK) WHERE MaPN = @MaPN)
            THROW 51006, N'Phiếu nhập không tồn tại.', 1;
        IF NOT EXISTS (SELECT 1 FROM SAN_PHAM WHERE MaSP = @MaSP)
            THROW 51007, N'Sản phẩm không tồn tại.', 1;
        IF @SoLuongNhap <= 0 THROW 51008, N'Số lượng nhập phải lớn hơn 0.', 1;
        IF @DonGiaNhap <= 0 THROW 51009, N'Đơn giá nhập phải lớn hơn 0.', 1;
        INSERT INTO CT_PHIEU_NHAP(MaPN, MaSP, SoLuongNhap, DonGiaNhap)
        VALUES(@MaPN, @MaSP, @SoLuongNhap, @DonGiaNhap);
        COMMIT;
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0 ROLLBACK;
        THROW;
    END CATCH;
END;
GO

CREATE TRIGGER trg_CTPN_CapNhatKho
ON CT_PHIEU_NHAP
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Delta TABLE(MaSP VARCHAR(10) PRIMARY KEY, Delta INT NOT NULL);
    INSERT INTO @Delta(MaSP, Delta)
    SELECT MaSP, SUM(Delta) FROM (
        SELECT MaSP, SoLuongNhap AS Delta FROM inserted
        UNION ALL
        SELECT MaSP, -SoLuongNhap FROM deleted
    ) D GROUP BY MaSP;

    IF EXISTS (SELECT 1 FROM SAN_PHAM SP JOIN @Delta D ON D.MaSP = SP.MaSP
               WHERE D.Delta < 0 AND SP.SoLuongTon < -D.Delta)
    BEGIN
        RAISERROR(N'Số lượng tồn kho không đủ.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    UPDATE SP SET SoLuongTon = SP.SoLuongTon + D.Delta
    FROM SAN_PHAM SP JOIN @Delta D ON D.MaSP = SP.MaSP WHERE D.Delta <> 0;

    UPDATE PN SET TongTien = ISNULL((SELECT SUM(SoLuongNhap * DonGiaNhap)
                                     FROM CT_PHIEU_NHAP CT WHERE CT.MaPN = PN.MaPN), 0)
    FROM PHIEU_NHAP PN
    WHERE PN.MaPN IN (SELECT MaPN FROM inserted UNION SELECT MaPN FROM deleted);
END;
GO
