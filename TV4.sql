USE QuanLySieuThi;
GO

/* ============================================================================
   TV4 - MODULE BÁN HÀNG & KHÁCH HÀNG
   CSDL: QuanLySieuThi
   Phụ trách: HOA_DON, CT_HOA_DON, THANH_TOAN
   Sử dụng bảng có sẵn: KHACH_HANG, NHAN_VIEN, SAN_PHAM

   Quy trình:
   Khách hàng -> Chọn sản phẩm -> Kiểm tra tồn kho -> Tạo hóa đơn
   -> Chi tiết hóa đơn -> Thanh toán -> Trừ tồn kho -> Cập nhật điểm KH
   ============================================================================ */

/* ============================================================================
   0. XÓA CÁC ĐỐI TƯỢNG TV4 NẾU ĐÃ TỒN TẠI (để có thể chạy lại file)
   ============================================================================ */
DROP TRIGGER IF EXISTS trg_CapNhatKhoVaTongTien_CTHD;
GO

DROP PROCEDURE IF EXISTS sp_TraCuuHoaDon;
DROP PROCEDURE IF EXISTS sp_ThanhToanHoaDon;
DROP PROCEDURE IF EXISTS sp_ThemChiTietHoaDon;
DROP PROCEDURE IF EXISTS sp_TaoHoaDon;
GO

DROP FUNCTION IF EXISTS fn_TinhDiemKhachHang;
DROP FUNCTION IF EXISTS fn_TinhTongHoaDon;
DROP FUNCTION IF EXISTS fn_TinhThanhTien;
GO

DROP TABLE IF EXISTS THANH_TOAN;
DROP TABLE IF EXISTS CT_HOA_DON;
DROP TABLE IF EXISTS HOA_DON;
GO

/* ============================================================================
   1. TẠO BẢNG HÓA ĐƠN
   ============================================================================ */
CREATE TABLE HOA_DON (
    MaHD        VARCHAR(10)     NOT NULL,
    NgayLap     DATETIME        NOT NULL DEFAULT GETDATE(),
    MaKH        VARCHAR(10)     NULL,
    MaNV        VARCHAR(10)     NOT NULL,
    TongTien    DECIMAL(18, 2)  NOT NULL DEFAULT 0,
    TrangThai   NVARCHAR(30)    NOT NULL DEFAULT N'Chưa thanh toán',

    CONSTRAINT PK_HOA_DON PRIMARY KEY (MaHD),

    CONSTRAINT FK_HD_KHACH_HANG
        FOREIGN KEY (MaKH) REFERENCES KHACH_HANG(MaKH),

    CONSTRAINT FK_HD_NHAN_VIEN
        FOREIGN KEY (MaNV) REFERENCES NHAN_VIEN(MaNV),

    CONSTRAINT CK_HD_TongTien
        CHECK (TongTien >= 0),

    CONSTRAINT CK_HD_TrangThai
        CHECK (TrangThai IN (N'Chưa thanh toán', N'Đã thanh toán', N'Đã hủy'))
);
GO

/* ============================================================================
   2. TẠO BẢNG CHI TIẾT HÓA ĐƠN
   ============================================================================ */
CREATE TABLE CT_HOA_DON (
    MaHD        VARCHAR(10)     NOT NULL,
    MaSP        VARCHAR(10)     NOT NULL,
    SoLuong     INT             NOT NULL,
    DonGia      DECIMAL(18, 2)  NOT NULL,

    CONSTRAINT PK_CT_HOA_DON PRIMARY KEY (MaHD, MaSP),

    CONSTRAINT FK_CTHD_HOA_DON
        FOREIGN KEY (MaHD) REFERENCES HOA_DON(MaHD) ON DELETE CASCADE,

    CONSTRAINT FK_CTHD_SAN_PHAM
        FOREIGN KEY (MaSP) REFERENCES SAN_PHAM(MaSP),

    CONSTRAINT CK_CTHD_SoLuong
        CHECK (SoLuong > 0),

    CONSTRAINT CK_CTHD_DonGia
        CHECK (DonGia >= 0)
);
GO

/* ============================================================================
   3. TẠO BẢNG THANH TOÁN
   Mỗi hóa đơn chỉ được ghi nhận một giao dịch thanh toán thành công trong module.
   ============================================================================ */
CREATE TABLE THANH_TOAN (
    MaTT            VARCHAR(10)     NOT NULL,
    MaHD            VARCHAR(10)     NOT NULL,
    NgayThanhToan   DATETIME        NOT NULL DEFAULT GETDATE(),
    SoTien          DECIMAL(18, 2)  NOT NULL,
    PhuongThuc      NVARCHAR(30)    NOT NULL,
    TrangThai       NVARCHAR(30)    NOT NULL DEFAULT N'Thành công',

    CONSTRAINT PK_THANH_TOAN PRIMARY KEY (MaTT),

    CONSTRAINT UQ_THANH_TOAN_MaHD UNIQUE (MaHD),

    CONSTRAINT FK_TT_HOA_DON
        FOREIGN KEY (MaHD) REFERENCES HOA_DON(MaHD),

    CONSTRAINT CK_TT_SoTien
        CHECK (SoTien > 0),

    CONSTRAINT CK_TT_PhuongThuc
        CHECK (PhuongThuc IN (N'Tiền mặt', N'Chuyển khoản', N'Thẻ', N'Ví điện tử')),

    CONSTRAINT CK_TT_TrangThai
        CHECK (TrangThai IN (N'Thành công', N'Thất bại'))
);
GO

/* ============================================================================
   4. FUNCTION 1 - TÍNH THÀNH TIỀN
   Thành tiền = Số lượng * Đơn giá
   ============================================================================ */
CREATE FUNCTION fn_TinhThanhTien
(
    @SoLuong INT,
    @DonGia DECIMAL(18, 2)
)
RETURNS DECIMAL(18, 2)
AS
BEGIN
    RETURN ISNULL(@SoLuong, 0) * ISNULL(@DonGia, 0);
END;
GO

/* ============================================================================
   5. FUNCTION 2 - TÍNH TỔNG HÓA ĐƠN
   ============================================================================ */
CREATE FUNCTION fn_TinhTongHoaDon
(
    @MaHD VARCHAR(10)
)
RETURNS DECIMAL(18, 2)
AS
BEGIN
    DECLARE @TongTien DECIMAL(18, 2);

    SELECT @TongTien = ISNULL(SUM(SoLuong * DonGia), 0)
    FROM CT_HOA_DON
    WHERE MaHD = @MaHD;

    RETURN ISNULL(@TongTien, 0);
END;
GO

/* ============================================================================
   6. FUNCTION 3 - TÍNH ĐIỂM KHÁCH HÀNG
   Quy ước: mỗi 10.000 VNĐ = 1 điểm, lấy phần nguyên.
   ============================================================================ */
CREATE FUNCTION fn_TinhDiemKhachHang
(
    @TongTien DECIMAL(18, 2)
)
RETURNS INT
AS
BEGIN
    DECLARE @Diem INT;

    SET @Diem = FLOOR(ISNULL(@TongTien, 0) / 10000);

    RETURN @Diem;
END;
GO

/* ============================================================================
   7. TRIGGER - QUẢN LÝ TỒN KHO VÀ TỰ ĐỘNG CẬP NHẬT TỔNG TIỀN

   - INSERT CT_HOA_DON : trừ tồn kho.
   - UPDATE SoLuong    : trừ/thêm phần chênh lệch tồn kho.
   - DELETE CT_HOA_DON : hoàn lại tồn kho.
   - Đồng thời tính lại TongTien của các hóa đơn bị ảnh hưởng.

   Trigger xử lý đúng cả trường hợp nhiều dòng được INSERT/UPDATE/DELETE cùng lúc.
   ============================================================================ */
CREATE TRIGGER trg_CapNhatKhoVaTongTien_CTHD
ON CT_HOA_DON
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    /*
       Delta > 0  : số lượng cần trừ khỏi kho.
       Delta < 0  : số lượng cần hoàn lại kho.
    */

    -- Kiểm tra tồn kho trước khi cập nhật.
    IF EXISTS
    (
        SELECT 1
        FROM SAN_PHAM SP
        JOIN
        (
            SELECT MaSP, SUM(Delta) AS Delta
            FROM
            (
                SELECT MaSP, SUM(SoLuong) AS Delta
                FROM inserted
                GROUP BY MaSP

                UNION ALL

                SELECT MaSP, -SUM(SoLuong) AS Delta
                FROM deleted
                GROUP BY MaSP
            ) X
            GROUP BY MaSP
        ) BD ON SP.MaSP = BD.MaSP
        WHERE BD.Delta > 0
          AND SP.SoLuongTon < BD.Delta
    )
    BEGIN
        RAISERROR(N'Số lượng tồn kho không đủ để thực hiện giao dịch bán hàng!', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END;

    -- Cập nhật kho theo phần chênh lệch giữa inserted và deleted.
    UPDATE SP
    SET SP.SoLuongTon = SP.SoLuongTon - BD.Delta
    FROM SAN_PHAM SP
    JOIN
    (
        SELECT MaSP, SUM(Delta) AS Delta
        FROM
        (
            SELECT MaSP, SUM(SoLuong) AS Delta
            FROM inserted
            GROUP BY MaSP

            UNION ALL

            SELECT MaSP, -SUM(SoLuong) AS Delta
            FROM deleted
            GROUP BY MaSP
        ) X
        GROUP BY MaSP
    ) BD ON SP.MaSP = BD.MaSP
    WHERE BD.Delta <> 0;

    /* Tính lại tổng tiền của tất cả hóa đơn bị ảnh hưởng. */
    UPDATE HD
    SET HD.TongTien = dbo.fn_TinhTongHoaDon(HD.MaHD)
    FROM HOA_DON HD
    WHERE HD.MaHD IN
    (
        SELECT MaHD FROM inserted
        UNION
        SELECT MaHD FROM deleted
    );
END;
GO

/* ============================================================================
   8. PROCEDURE 1 - TẠO HÓA ĐƠN
   ============================================================================ */
CREATE PROCEDURE sp_TaoHoaDon
    @MaHD VARCHAR(10),
    @MaKH VARCHAR(10) = NULL,
    @MaNV VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (SELECT 1 FROM HOA_DON WHERE MaHD = @MaHD)
    BEGIN
        RAISERROR(N'Mã hóa đơn đã tồn tại!', 16, 1);
        RETURN;
    END;

    IF @MaKH IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM KHACH_HANG WHERE MaKH = @MaKH)
    BEGIN
        RAISERROR(N'Khách hàng không tồn tại!', 16, 1);
        RETURN;
    END;

    IF NOT EXISTS (SELECT 1 FROM NHAN_VIEN WHERE MaNV = @MaNV)
    BEGIN
        RAISERROR(N'Nhân viên không tồn tại!', 16, 1);
        RETURN;
    END;

    INSERT INTO HOA_DON (MaHD, NgayLap, MaKH, MaNV, TongTien, TrangThai)
    VALUES (@MaHD, GETDATE(), @MaKH, @MaNV, 0, N'Chưa thanh toán');

    PRINT N'Tạo hóa đơn thành công!';
END;
GO

/* ============================================================================
   9. PROCEDURE 2 - THÊM CHI TIẾT HÓA ĐƠN

   - Kiểm tra hóa đơn.
   - Kiểm tra trạng thái hóa đơn.
   - Kiểm tra sản phẩm và tồn kho.
   - Lấy GiaBan hiện tại làm DonGia trên hóa đơn.
   - Nếu sản phẩm đã có trong hóa đơn: cộng thêm số lượng.
   - Trigger sẽ tự động trừ tồn kho và cập nhật TongTien.
   ============================================================================ */
CREATE PROCEDURE sp_ThemChiTietHoaDon
    @MaHD VARCHAR(10),
    @MaSP VARCHAR(10),
    @SoLuong INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @GiaBan DECIMAL(18, 2);
    DECLARE @SoLuongTon INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF NOT EXISTS (SELECT 1 FROM HOA_DON WHERE MaHD = @MaHD)
            THROW 50001, N'Hóa đơn không tồn tại!', 1;

        IF EXISTS
        (
            SELECT 1
            FROM HOA_DON
            WHERE MaHD = @MaHD
              AND TrangThai <> N'Chưa thanh toán'
        )
            THROW 50002, N'Chỉ được thêm sản phẩm vào hóa đơn chưa thanh toán!', 1;

        IF @SoLuong <= 0
            THROW 50003, N'Số lượng bán phải lớn hơn 0!', 1;

        SELECT
            @GiaBan = GiaBan,
            @SoLuongTon = SoLuongTon
        FROM SAN_PHAM WITH (UPDLOCK, HOLDLOCK)
        WHERE MaSP = @MaSP;

        IF @GiaBan IS NULL
            THROW 50004, N'Sản phẩm không tồn tại!', 1;

        IF @SoLuongTon < @SoLuong
            THROW 50005, N'Số lượng tồn kho không đủ!', 1;

        IF EXISTS
        (
            SELECT 1
            FROM CT_HOA_DON
            WHERE MaHD = @MaHD
              AND MaSP = @MaSP
        )
        BEGIN
            UPDATE CT_HOA_DON
            SET SoLuong = SoLuong + @SoLuong
            WHERE MaHD = @MaHD
              AND MaSP = @MaSP;
        END
        ELSE
        BEGIN
            INSERT INTO CT_HOA_DON (MaHD, MaSP, SoLuong, DonGia)
            VALUES (@MaHD, @MaSP, @SoLuong, @GiaBan);
        END;

        COMMIT TRANSACTION;
        PRINT N'Thêm chi tiết hóa đơn thành công!';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

/* ============================================================================
   10. PROCEDURE 3 - THANH TOÁN HÓA ĐƠN

   - Kiểm tra hóa đơn hợp lệ và chưa thanh toán.
   - Ghi nhận THANH_TOAN.
   - Chuyển trạng thái hóa đơn thành Đã thanh toán.
   - Cộng điểm tích lũy cho khách hàng: 10.000 VNĐ = 1 điểm.
   ============================================================================ */
CREATE PROCEDURE sp_ThanhToanHoaDon
    @MaTT VARCHAR(10),
    @MaHD VARCHAR(10),
    @PhuongThuc NVARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TongTien DECIMAL(18, 2);
    DECLARE @MaKH VARCHAR(10);
    DECLARE @DiemCong INT;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF EXISTS (SELECT 1 FROM THANH_TOAN WHERE MaTT = @MaTT)
            THROW 50006, N'Mã thanh toán đã tồn tại!', 1;

        IF NOT EXISTS (SELECT 1 FROM HOA_DON WHERE MaHD = @MaHD)
            THROW 50007, N'Hóa đơn không tồn tại!', 1;

        IF EXISTS (SELECT 1 FROM THANH_TOAN WHERE MaHD = @MaHD)
            THROW 50008, N'Hóa đơn đã có giao dịch thanh toán!', 1;

        IF EXISTS
        (
            SELECT 1
            FROM HOA_DON
            WHERE MaHD = @MaHD
              AND TrangThai <> N'Chưa thanh toán'
        )
            THROW 50009, N'Hóa đơn không ở trạng thái Chưa thanh toán!', 1;

        IF @PhuongThuc NOT IN (N'Tiền mặt', N'Chuyển khoản', N'Thẻ', N'Ví điện tử')
            THROW 50010, N'Phương thức thanh toán không hợp lệ!', 1;

        SELECT
            @TongTien = TongTien,
            @MaKH = MaKH
        FROM HOA_DON WITH (UPDLOCK, HOLDLOCK)
        WHERE MaHD = @MaHD;

        IF ISNULL(@TongTien, 0) <= 0
            THROW 50011, N'Hóa đơn chưa có sản phẩm nên không thể thanh toán!', 1;

        INSERT INTO THANH_TOAN
            (MaTT, MaHD, NgayThanhToan, SoTien, PhuongThuc, TrangThai)
        VALUES
            (@MaTT, @MaHD, GETDATE(), @TongTien, @PhuongThuc, N'Thành công');

        UPDATE HOA_DON
        SET TrangThai = N'Đã thanh toán'
        WHERE MaHD = @MaHD;

        IF @MaKH IS NOT NULL
        BEGIN
            SET @DiemCong = dbo.fn_TinhDiemKhachHang(@TongTien);

            UPDATE KHACH_HANG
            SET DiemTichLuy = DiemTichLuy + @DiemCong
            WHERE MaKH = @MaKH;
        END;

        COMMIT TRANSACTION;
        PRINT N'Thanh toán hóa đơn thành công!';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO

/* ============================================================================
   11. PROCEDURE 4 - TRA CỨU HÓA ĐƠN
   Trả về 3 tập kết quả:
   1) Thông tin chung của hóa đơn.
   2) Chi tiết sản phẩm.
   3) Thông tin thanh toán.
   ============================================================================ */
CREATE PROCEDURE sp_TraCuuHoaDon
    @MaHD VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM HOA_DON WHERE MaHD = @MaHD)
    BEGIN
        RAISERROR(N'Hóa đơn không tồn tại!', 16, 1);
        RETURN;
    END;

    -- 1. Thông tin chung hóa đơn
    SELECT
        HD.MaHD,
        HD.NgayLap,
        HD.MaKH,
        KH.HoTen AS TenKhachHang,
        KH.DienThoai,
        HD.MaNV,
        NV.HoTen AS NhanVienBanHang,
        HD.TongTien,
        HD.TrangThai
    FROM HOA_DON HD
    LEFT JOIN KHACH_HANG KH ON HD.MaKH = KH.MaKH
    JOIN NHAN_VIEN NV ON HD.MaNV = NV.MaNV
    WHERE HD.MaHD = @MaHD;

    -- 2. Chi tiết sản phẩm
    SELECT
        CT.MaSP,
        SP.TenSP,
        SP.DonViTinh,
        CT.SoLuong,
        CT.DonGia,
        dbo.fn_TinhThanhTien(CT.SoLuong, CT.DonGia) AS ThanhTien
    FROM CT_HOA_DON CT
    JOIN SAN_PHAM SP ON CT.MaSP = SP.MaSP
    WHERE CT.MaHD = @MaHD
    ORDER BY CT.MaSP;

    -- 3. Thông tin thanh toán
    SELECT
        MaTT,
        NgayThanhToan,
        SoTien,
        PhuongThuc,
        TrangThai
    FROM THANH_TOAN
    WHERE MaHD = @MaHD;
END;
GO

/* ============================================================================
   12. KIỂM THỬ MODULE TV4

   BỎ DẤU -- ở các lệnh dưới đây khi muốn demo.
   Dữ liệu test sử dụng đúng seed data của BTL_database.sql:
   KH01, NV02, SP01, SP02.

   Nếu đã chạy TV3.sql thì tồn SP01/SP02 sẽ cao hơn dữ liệu seed ban đầu,
   nhưng quy trình TV4 vẫn hoạt động bình thường.
   ============================================================================ */

-- A. Kiểm tra tồn kho trước khi bán
-- SELECT MaSP, TenSP, GiaBan, SoLuongTon
-- FROM SAN_PHAM
-- WHERE MaSP IN ('SP01', 'SP02');

-- B. Tạo hóa đơn cho KH01, nhân viên NV02
-- EXEC sp_TaoHoaDon
--     @MaHD = 'HD01',
--     @MaKH = 'KH01',
--     @MaNV = 'NV02';

-- C. Bán 3 gói SP01 và 2 chai SP02
-- EXEC sp_ThemChiTietHoaDon
--     @MaHD = 'HD01',
--     @MaSP = 'SP01',
--     @SoLuong = 3;

-- EXEC sp_ThemChiTietHoaDon
--     @MaHD = 'HD01',
--     @MaSP = 'SP02',
--     @SoLuong = 2;

-- D. Kiểm tra chi tiết, tổng tiền và tồn kho sau bán
-- SELECT * FROM CT_HOA_DON WHERE MaHD = 'HD01';
-- SELECT * FROM HOA_DON WHERE MaHD = 'HD01';
-- SELECT MaSP, TenSP, SoLuongTon
-- FROM SAN_PHAM
-- WHERE MaSP IN ('SP01', 'SP02');

-- E. Kiểm tra các function
-- SELECT dbo.fn_TinhThanhTien(3, 4500) AS ThanhTien_Mau;
-- SELECT dbo.fn_TinhTongHoaDon('HD01') AS TongHoaDon_HD01;
-- SELECT dbo.fn_TinhDiemKhachHang(dbo.fn_TinhTongHoaDon('HD01')) AS DiemCong_HD01;

-- F. Thanh toán hóa đơn
-- EXEC sp_ThanhToanHoaDon
--     @MaTT = 'TT01',
--     @MaHD = 'HD01',
--     @PhuongThuc = N'Tiền mặt';

-- G. Kiểm tra trạng thái hóa đơn, thanh toán và điểm KH
-- SELECT * FROM HOA_DON WHERE MaHD = 'HD01';
-- SELECT * FROM THANH_TOAN WHERE MaHD = 'HD01';
-- SELECT MaKH, HoTen, DiemTichLuy FROM KHACH_HANG WHERE MaKH = 'KH01';

-- H. Tra cứu hóa đơn đầy đủ
-- EXEC sp_TraCuuHoaDon @MaHD = 'HD01';

/* ============================================================================
   KẾT THÚC TV4
   ============================================================================ */
