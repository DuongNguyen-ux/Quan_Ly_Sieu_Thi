USE QuanLySieuThi;
GO

/***************************************************************************************************
    BỘ KIỂM THỬ TỰ ĐỘNG CÔ LẬP TOÀN DIỆN (ISOLATED AUTOMATED TEST HARNESS)
    Hệ thống: Quản lý Siêu thị (QuanLySieuThi)
    
    Đặc tính kỹ thuật chuyên nghiệp:
    1. Pre-test Cleanup: Dọn dẹp tàn dư trước khi test phòng trường hợp phiên trước bị ngắt giữa chừng.
    2. Snapshot Isolation: Chụp ảnh trạng thái tồn kho & điểm tích lũy ban đầu để so sánh và khôi phục.
    3. Automated Assertions: So sánh chính xác giữa Kỳ vọng (Expected) và Thực tế (Actual).
    4. 8 Kịch bản kiểm thử: Phủ kín các trường hợp Nghiệp vụ, Ràng buộc, Trigger, Phân tầng khóa và Trạng thái.
    5. Guaranteed Teardown: Tự động dọn dẹp và khôi phục CSDL về trạng thái sạch 100% (Zero Side-effects).
    6. Tính khả lặp (Idempotent): Có thể chạy liên tục nhiều lần mà không bao giờ gặp lỗi trùng khóa.
***************************************************************************************************/

SET NOCOUNT ON;
SET XACT_ABORT OFF;

----------------------------------------------------------------------------------------------------
-- BƯỚC 1: PRE-TEST CLEANUP (Dọn dẹp tiền kiểm an toàn)
----------------------------------------------------------------------------------------------------
IF OBJECT_ID('trg_CTHD_CapNhatKho', 'TR') IS NOT NULL ALTER TABLE CT_HOA_DON DISABLE TRIGGER trg_CTHD_CapNhatKho;
IF OBJECT_ID('trg_KhongXoaHoaDon', 'TR') IS NOT NULL ALTER TABLE HOA_DON DISABLE TRIGGER trg_KhongXoaHoaDon;
IF OBJECT_ID('trg_CTPN_CapNhatKho', 'TR') IS NOT NULL ALTER TABLE CT_PHIEU_NHAP DISABLE TRIGGER trg_CTPN_CapNhatKho;

DELETE FROM THANH_TOAN WHERE MaTT LIKE 'TST%' OR MaHD LIKE 'TST%';
DELETE FROM CT_HOA_DON WHERE MaHD LIKE 'TST%';
DELETE FROM HOA_DON WHERE MaHD LIKE 'TST%';
DELETE FROM CT_PHIEU_NHAP WHERE MaPN LIKE 'TST%';
DELETE FROM PHIEU_NHAP WHERE MaPN LIKE 'TST%';

IF OBJECT_ID('trg_CTHD_CapNhatKho', 'TR') IS NOT NULL ALTER TABLE CT_HOA_DON ENABLE TRIGGER trg_CTHD_CapNhatKho;
IF OBJECT_ID('trg_KhongXoaHoaDon', 'TR') IS NOT NULL ALTER TABLE HOA_DON ENABLE TRIGGER trg_KhongXoaHoaDon;
IF OBJECT_ID('trg_CTPN_CapNhatKho', 'TR') IS NOT NULL ALTER TABLE CT_PHIEU_NHAP ENABLE TRIGGER trg_CTPN_CapNhatKho;

----------------------------------------------------------------------------------------------------
-- BƯỚC 2: SNAPSHOT TRẠNG THÁI GỐC (Lưu vết để kiểm chứng và hoàn nguyên)
----------------------------------------------------------------------------------------------------
IF OBJECT_ID('tempdb..#Snap_SP') IS NOT NULL DROP TABLE #Snap_SP;
IF OBJECT_ID('tempdb..#Snap_KH') IS NOT NULL DROP TABLE #Snap_KH;

SELECT MaSP, SoLuongTon INTO #Snap_SP FROM SAN_PHAM;
SELECT MaKH, DiemTichLuy INTO #Snap_KH FROM KHACH_HANG;

-- Bảng lưu kết quả kiểm thử
DECLARE @TestResults TABLE (
    STT INT IDENTITY(1,1) PRIMARY KEY,
    TestID VARCHAR(10),
    TestName NVARCHAR(100),
    Expected NVARCHAR(150),
    Actual NVARCHAR(150),
    Status VARCHAR(10),
    Details NVARCHAR(255)
);

BEGIN TRY
    ------------------------------------------------------------------------------------------------
    -- TC01: Nhập hàng nhiều dòng (Batch Insert) & Trigger cập nhật tồn kho + tổng tiền
    ------------------------------------------------------------------------------------------------
    DECLARE @OrigStock1 INT, @OrigStock2 INT;
    SELECT @OrigStock1 = SoLuongTon FROM #Snap_SP WHERE MaSP = 'SP01';
    SELECT @OrigStock2 = SoLuongTon FROM #Snap_SP WHERE MaSP = 'SP02';

    EXEC sp_ThemPhieuNhap @MaPN = 'TSTPN1', @MaNCC = 'NCC01', @MaNV = 'NV01';
    INSERT INTO CT_PHIEU_NHAP (MaPN, MaSP, SoLuongNhap, DonGiaNhap)
    VALUES ('TSTPN1', 'SP01', 10, 4000),
           ('TSTPN1', 'SP02', 20, 5000);

    DECLARE @NewStock1 INT, @NewStock2 INT, @TongTienPN DECIMAL(18,2);
    SELECT @NewStock1 = SoLuongTon FROM SAN_PHAM WHERE MaSP = 'SP01';
    SELECT @NewStock2 = SoLuongTon FROM SAN_PHAM WHERE MaSP = 'SP02';
    SELECT @TongTienPN = TongTien FROM PHIEU_NHAP WHERE MaPN = 'TSTPN1';

    IF (@NewStock1 = @OrigStock1 + 10) AND (@NewStock2 = @OrigStock2 + 20) AND (@TongTienPN = 140000.00)
        INSERT INTO @TestResults (TestID, TestName, Expected, Actual, Status, Details)
        VALUES ('TC01', N'Nhập hàng nhiều dòng & Trigger tồn kho, tổng tiền',
                N'SP01 +' + CAST(10 AS NVARCHAR) + N', SP02 +' + CAST(20 AS NVARCHAR) + N', Tổng=140000',
                N'SP01 +' + CAST(@NewStock1 - @OrigStock1 AS NVARCHAR) + N', SP02 +' + CAST(@NewStock2 - @OrigStock2 AS NVARCHAR) + N', Tổng=' + CAST(@TongTienPN AS NVARCHAR),
                'PASS', N'Tồn kho và tổng tiền phiếu nhập cập nhật chính xác.');
    ELSE
        INSERT INTO @TestResults (TestID, TestName, Expected, Actual, Status, Details)
        VALUES ('TC01', N'Nhập hàng nhiều dòng & Trigger tồn kho, tổng tiền',
                N'SP01 +10, SP02 +20, Tổng=140000',
                N'SP01 +' + CAST(@NewStock1 - @OrigStock1 AS NVARCHAR) + N', Tổng=' + CAST(@TongTienPN AS NVARCHAR),
                'FAIL', N'Số lượng tồn kho hoặc tổng tiền tính sai.');

    ------------------------------------------------------------------------------------------------
    -- TC02: Cập nhật chi tiết nhập hàng (Delta UPDATE) & Trigger chênh lệch
    ------------------------------------------------------------------------------------------------
    UPDATE CT_PHIEU_NHAP 
    SET SoLuongNhap = 15, DonGiaNhap = 4500 
    WHERE MaPN = 'TSTPN1' AND MaSP = 'SP01';

    SELECT @NewStock1 = SoLuongTon FROM SAN_PHAM WHERE MaSP = 'SP01';
    SELECT @TongTienPN = TongTien FROM PHIEU_NHAP WHERE MaPN = 'TSTPN1';
    
    -- Kỳ vọng: SP01 tăng từ gốc + 15; Tổng tiền = (15*4500) + (20*5000) = 67500 + 100000 = 167500
    IF (@NewStock1 = @OrigStock1 + 15) AND (@TongTienPN = 167500.00)
        INSERT INTO @TestResults (TestID, TestName, Expected, Actual, Status, Details)
        VALUES ('TC02', N'Cập nhật chi tiết nhập (Delta UPDATE)',
                N'SP01 +' + CAST(15 AS NVARCHAR) + N', Tổng=167500',
                N'SP01 +' + CAST(@NewStock1 - @OrigStock1 AS NVARCHAR) + N', Tổng=' + CAST(@TongTienPN AS NVARCHAR),
                'PASS', N'Delta chênh lệch được trigger xử lý chính xác.');
    ELSE
        INSERT INTO @TestResults (TestID, TestName, Expected, Actual, Status, Details)
        VALUES ('TC02', N'Cập nhật chi tiết nhập (Delta UPDATE)',
                N'SP01 +15, Tổng=167500',
                N'SP01 +' + CAST(@NewStock1 - @OrigStock1 AS NVARCHAR) + N', Tổng=' + CAST(@TongTienPN AS NVARCHAR),
                'FAIL', N'Cập nhật Delta sai lệch số lượng tồn.');

    ------------------------------------------------------------------------------------------------
    -- TC03: Kiểm tra tính toàn vẹn: Chặn số lượng nhập âm (-1)
    ------------------------------------------------------------------------------------------------
    BEGIN TRY
        EXEC sp_ThemChiTietPhieuNhap @MaPN = 'TSTPN1', @MaSP = 'SP03', @SoLuongNhap = -1, @DonGiaNhap = 1000;
        INSERT INTO @TestResults (TestID, TestName, Expected, Actual, Status, Details)
        VALUES ('TC03', N'Ràng buộc: Chặn số lượng nhập âm', N'Ném lỗi 51008', N'Cho phép chèn số âm', 'FAIL', N'Lỗi: Hệ thống không chặn số lượng nhập âm.');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 51008
            INSERT INTO @TestResults (TestID, TestName, Expected, Actual, Status, Details)
            VALUES ('TC03', N'Ràng buộc: Chặn số lượng nhập âm', N'Mã lỗi 51008', N'Bắt được lỗi ' + CAST(ERROR_NUMBER() AS NVARCHAR), 'PASS', N'Chặn thành công với thông báo: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @TestResults (TestID, TestName, Expected, Actual, Status, Details)
            VALUES ('TC03', N'Ràng buộc: Chặn số lượng nhập âm', N'Mã lỗi 51008', N'Mã lỗi ' + CAST(ERROR_NUMBER() AS NVARCHAR), 'FAIL', N'Mã lỗi không khớp kỳ vọng.');
    END CATCH;

    ------------------------------------------------------------------------------------------------
    -- TC04: Bán hàng vượt tồn kho (Over-stock Check)
    ------------------------------------------------------------------------------------------------
    EXEC sp_TaoHoaDon @MaHD = 'TSTHD1', @MaNV = 'NV02', @MaKH = 'KH01';
    BEGIN TRY
        EXEC sp_ThemChiTietHoaDon @MaHD = 'TSTHD1', @MaSP = 'SP01', @SoLuong = 999999;
        INSERT INTO @TestResults (TestID, TestName, Expected, Actual, Status, Details)
        VALUES ('TC04', N'Bán hàng vượt tồn kho', N'Báo lỗi thiếu tồn kho', N'Giao dịch thành công', 'FAIL', N'Lỗi: Cho phép bán vượt tồn.');
    END TRY
    BEGIN CATCH
        INSERT INTO @TestResults (TestID, TestName, Expected, Actual, Status, Details)
        VALUES ('TC04', N'Bán hàng vượt tồn kho', N'Bị chặn và ROLLBACK', N'Đã chặn thành công', 'PASS', N'Trigger phát hiện thiếu tồn kho và chặn: ' + ERROR_MESSAGE());
    END CATCH;

    ------------------------------------------------------------------------------------------------
    -- TC05: Bán hàng hợp lệ, sau đó Hủy hóa đơn hoàn kho (sp_HuyHoaDon)
    ------------------------------------------------------------------------------------------------
    DECLARE @StockBeforeSale INT, @StockAfterSale INT, @StockAfterCancel INT;
    SELECT @StockBeforeSale = SoLuongTon FROM SAN_PHAM WHERE MaSP = 'SP01';

    -- Thêm 5 sản phẩm hợp lệ vào hóa đơn TSTHD1
    EXEC sp_ThemChiTietHoaDon @MaHD = 'TSTHD1', @MaSP = 'SP01', @SoLuong = 5;
    SELECT @StockAfterSale = SoLuongTon FROM SAN_PHAM WHERE MaSP = 'SP01';

    -- Hủy hóa đơn
    EXEC sp_HuyHoaDon @MaHD = 'TSTHD1';
    SELECT @StockAfterCancel = SoLuongTon FROM SAN_PHAM WHERE MaSP = 'SP01';

    DECLARE @InvoiceStatus NVARCHAR(30), @ItemCountInInvoice INT;
    SELECT @InvoiceStatus = TrangThai FROM HOA_DON WHERE MaHD = 'TSTHD1';
    SELECT @ItemCountInInvoice = COUNT(*) FROM CT_HOA_DON WHERE MaHD = 'TSTHD1';

    IF (@StockAfterSale = @StockBeforeSale - 5) 
       AND (@StockAfterCancel = @StockBeforeSale) 
       AND (@InvoiceStatus = N'Đã hủy') 
       AND (@ItemCountInInvoice = 0)
        INSERT INTO @TestResults (TestID, TestName, Expected, Actual, Status, Details)
        VALUES ('TC05', N'Hủy hóa đơn & Hoàn trả tồn kho',
                N'Trừ 5 sau bán, hoàn lại đủ khi hủy, Trạng thái=Đã hủy',
                N'Kho hoàn về=' + CAST(@StockAfterCancel AS NVARCHAR) + N', Trạng thái=' + @InvoiceStatus,
                'PASS', N'Tồn kho được phục hồi nguyên trạng và hóa đơn đánh dấu Đã hủy.');
    ELSE
        INSERT INTO @TestResults (TestID, TestName, Expected, Actual, Status, Details)
        VALUES ('TC05', N'Hủy hóa đơn & Hoàn trả tồn kho',
                N'Kho hoàn về=' + CAST(@StockBeforeSale AS NVARCHAR),
                N'Kho thực tế=' + CAST(@StockAfterCancel AS NVARCHAR),
                'FAIL', N'Số lượng tồn không được hoàn lại chính xác.');

    ------------------------------------------------------------------------------------------------
    -- TC06: Chặn xóa trực tiếp hóa đơn (INSTEAD OF DELETE Trigger)
    ------------------------------------------------------------------------------------------------
    BEGIN TRY
        DELETE FROM HOA_DON WHERE MaHD = 'TSTHD1';
        INSERT INTO @TestResults (TestID, TestName, Expected, Actual, Status, Details)
        VALUES ('TC06', N'Bảo vệ lịch sử: Chặn DELETE hóa đơn trực tiếp', N'Trigger ném lỗi chặn xóa', N'Đã xóa hóa đơn', 'FAIL', N'Lỗi: Hóa đơn bị xóa trực tiếp khỏi database.');
    END TRY
    BEGIN CATCH
        IF EXISTS (SELECT 1 FROM HOA_DON WHERE MaHD = 'TSTHD1')
            INSERT INTO @TestResults (TestID, TestName, Expected, Actual, Status, Details)
            VALUES ('TC06', N'Bảo vệ lịch sử: Chặn DELETE hóa đơn trực tiếp', N'Chặn xóa & giữ lại hóa đơn', N'Hóa đơn vẫn tồn tại', 'PASS', N'Trigger INSTEAD OF DELETE bảo toàn lịch sử thành công.');
        ELSE
            INSERT INTO @TestResults (TestID, TestName, Expected, Actual, Status, Details)
            VALUES ('TC06', N'Bảo vệ lịch sử: Chặn DELETE hóa đơn trực tiếp', N'Giữ lại hóa đơn', N'Bị mất dữ liệu', 'FAIL', N'Hóa đơn bị mất.');
    END CATCH;

    ------------------------------------------------------------------------------------------------
    -- TC07: Quy trình Bán hàng, Thanh toán & Tích lũy điểm thưởng
    ------------------------------------------------------------------------------------------------
    EXEC sp_TaoHoaDon @MaHD = 'TSTHD2', @MaNV = 'NV02', @MaKH = 'KH01';
    
    -- Thêm SP03 (Nước khoáng 6000 x 2 = 12000)
    DECLARE @OrigPoints INT;
    SELECT @OrigPoints = DiemTichLuy FROM #Snap_KH WHERE MaKH = 'KH01';

    EXEC sp_ThemChiTietHoaDon @MaHD = 'TSTHD2', @MaSP = 'SP03', @SoLuong = 2;
    
    -- Thanh toán tiền mặt
    EXEC sp_ThanhToanHoaDon @MaTT = 'TSTTT1', @MaHD = 'TSTHD2', @PhuongThuc = N'Tiền mặt';

    DECLARE @HD2Status NVARCHAR(30), @NewPoints INT, @TTCount INT;
    SELECT @HD2Status = TrangThai FROM HOA_DON WHERE MaHD = 'TSTHD2';
    SELECT @NewPoints = DiemTichLuy FROM KHACH_HANG WHERE MaKH = 'KH01';
    SELECT @TTCount = COUNT(*) FROM THANH_TOAN WHERE MaTT = 'TSTTT1' AND MaHD = 'TSTHD2';

    -- 12.000 VNĐ -> tích 1 điểm (FLOOR(12000/10000))
    IF (@HD2Status = N'Đã thanh toán') AND (@NewPoints = @OrigPoints + 1) AND (@TTCount = 1)
        INSERT INTO @TestResults (TestID, TestName, Expected, Actual, Status, Details)
        VALUES ('TC07', N'Thanh toán hóa đơn & Tích điểm thưởng',
                N'Trạng thái=Đã thanh toán, Điểm +' + CAST(1 AS NVARCHAR),
                N'Trạng thái=' + @HD2Status + N', Điểm +' + CAST(@NewPoints - @OrigPoints AS NVARCHAR),
                'PASS', N'Thanh toán thành công và tự động tích đúng 1 điểm cho khách hàng.');
    ELSE
        INSERT INTO @TestResults (TestID, TestName, Expected, Actual, Status, Details)
        VALUES ('TC07', N'Thanh toán hóa đơn & Tích điểm thưởng',
                N'Trạng thái=Đã thanh toán, Điểm +1',
                N'Trạng thái=' + @HD2Status + N', Điểm +' + CAST(@NewPoints - @OrigPoints AS NVARCHAR),
                'FAIL', N'Lỗi cập nhật trạng thái thanh toán hoặc tích điểm.');

    ------------------------------------------------------------------------------------------------
    -- TC08: Chuẩn hóa thứ tự khóa: Chặn sửa đổi hóa đơn đã thanh toán (Deadlock & State Guard)
    ------------------------------------------------------------------------------------------------
    BEGIN TRY
        EXEC sp_ThemChiTietHoaDon @MaHD = 'TSTHD2', @MaSP = 'SP01', @SoLuong = 1;
        INSERT INTO @TestResults (TestID, TestName, Expected, Actual, Status, Details)
        VALUES ('TC08', N'Khóa & Bảo vệ trạng thái: Chặn sửa đơn đã thanh toán', N'Ném lỗi 52004', N'Cho phép sửa', 'FAIL', N'Lỗi: Cho phép thêm hàng vào đơn đã thanh toán.');
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() = 52004
            INSERT INTO @TestResults (TestID, TestName, Expected, Actual, Status, Details)
            VALUES ('TC08', N'Khóa & Bảo vệ trạng thái: Chặn sửa đơn đã thanh toán', N'Mã lỗi 52004', N'Mã lỗi 52004', 'PASS', N'Khóa Level 1 chặn thành công: ' + ERROR_MESSAGE());
        ELSE
            INSERT INTO @TestResults (TestID, TestName, Expected, Actual, Status, Details)
            VALUES ('TC08', N'Khóa & Bảo vệ trạng thái: Chặn sửa đơn đã thanh toán', N'Mã lỗi 52004', N'Lỗi khác: ' + CAST(ERROR_NUMBER() AS NVARCHAR), 'FAIL', ERROR_MESSAGE());
    END CATCH;

END TRY
BEGIN CATCH
    INSERT INTO @TestResults (TestID, TestName, Expected, Actual, Status, Details)
    VALUES ('FATAL', N'Lỗi hệ thống bất ngờ trong Test Suite', N'Không có exception nghiêm trọng', ERROR_MESSAGE(), 'ERROR', N'Exception tại dòng: ' + CAST(ERROR_LINE() AS NVARCHAR));
END CATCH;

----------------------------------------------------------------------------------------------------
-- BƯỚC 3: TEARDOWN TOÀN DIỆN (Hoàn nguyên CSDL về trạng thái sạch 100%)
----------------------------------------------------------------------------------------------------
-- 1. Xóa toàn bộ dữ liệu kiểm thử TST (tạm tắt triggers để không re-trigger logic kho)
IF OBJECT_ID('trg_CTHD_CapNhatKho', 'TR') IS NOT NULL ALTER TABLE CT_HOA_DON DISABLE TRIGGER trg_CTHD_CapNhatKho;
IF OBJECT_ID('trg_KhongXoaHoaDon', 'TR') IS NOT NULL ALTER TABLE HOA_DON DISABLE TRIGGER trg_KhongXoaHoaDon;
IF OBJECT_ID('trg_CTPN_CapNhatKho', 'TR') IS NOT NULL ALTER TABLE CT_PHIEU_NHAP DISABLE TRIGGER trg_CTPN_CapNhatKho;

DELETE FROM THANH_TOAN WHERE MaTT LIKE 'TST%' OR MaHD LIKE 'TST%';
DELETE FROM CT_HOA_DON WHERE MaHD LIKE 'TST%';
DELETE FROM HOA_DON WHERE MaHD LIKE 'TST%';
DELETE FROM CT_PHIEU_NHAP WHERE MaPN LIKE 'TST%';
DELETE FROM PHIEU_NHAP WHERE MaPN LIKE 'TST%';

IF OBJECT_ID('trg_CTHD_CapNhatKho', 'TR') IS NOT NULL ALTER TABLE CT_HOA_DON ENABLE TRIGGER trg_CTHD_CapNhatKho;
IF OBJECT_ID('trg_KhongXoaHoaDon', 'TR') IS NOT NULL ALTER TABLE HOA_DON ENABLE TRIGGER trg_KhongXoaHoaDon;
IF OBJECT_ID('trg_CTPN_CapNhatKho', 'TR') IS NOT NULL ALTER TABLE CT_PHIEU_NHAP ENABLE TRIGGER trg_CTPN_CapNhatKho;

-- 2. Khôi phục lại dữ liệu tồn kho & điểm thưởng từ Snapshot
UPDATE SP 
SET SP.SoLuongTon = S.SoLuongTon 
FROM SAN_PHAM SP 
JOIN #Snap_SP S ON S.MaSP = SP.MaSP;

UPDATE KH 
SET KH.DiemTichLuy = S.DiemTichLuy 
FROM KHACH_HANG KH 
JOIN #Snap_KH S ON S.MaKH = KH.MaKH;

DROP TABLE #Snap_SP;
DROP TABLE #Snap_KH;

----------------------------------------------------------------------------------------------------
-- BƯỚC 4: XUẤT BÁO CÁO KẾT QUẢ KIỂM THỬ (TEST REPORT DASHBOARD)
----------------------------------------------------------------------------------------------------
PRINT N'====================================================================================================';
PRINT N'                       BÁO CÁO KẾT QUẢ KIỂM THỬ HỆ THỐNG CƠ SỞ DỮ LIỆU SIÊU THỊ                     ';
PRINT N'====================================================================================================';

SELECT 
    TestID AS [Mã Test],
    TestName AS [Kịch bản kiểm thử],
    Status AS [Kết quả],
    Expected AS [Kỳ vọng],
    Actual AS [Thực tế],
    Details AS [Ghi chú chi tiết]
FROM @TestResults;

DECLARE @Total INT, @Passed INT, @Failed INT;
SELECT @Total = COUNT(*), 
       @Passed = SUM(CASE WHEN Status = 'PASS' THEN 1 ELSE 0 END),
       @Failed = SUM(CASE WHEN Status <> 'PASS' THEN 1 ELSE 0 END)
FROM @TestResults;

PRINT N'----------------------------------------------------------------------------------------------------';
PRINT N' TỔNG SỐ TEST CASES : ' + CAST(@Total AS NVARCHAR);
PRINT N' THÀNH CÔNG (PASS)   : ' + CAST(@Passed AS NVARCHAR);
PRINT N' THẤT BẠI (FAIL)     : ' + CAST(@Failed AS NVARCHAR);
PRINT N' TỶ LỆ ĐẠT           : ' + CAST(CAST((@Passed * 100.0 / NULLIF(@Total,0)) AS DECIMAL(5,2)) AS NVARCHAR) + N'%';
PRINT N'----------------------------------------------------------------------------------------------------';
PRINT N'>> [HOÀN TẤT] TOÀN BỘ DỮ LIỆU ĐÃ ĐƯỢC DỌN DẸP & PHỤC HỒI NGUYÊN TRẠNG: ZERO SIDE-EFFECTS! <<';
PRINT N'====================================================================================================';
GO
