USE QuanLySieuThi;
GO

-- Chạy trên CSDL đã chạy 01 đến 06. Bộ test này dùng mã TST và chỉ nên chạy một lần trên database test.
-- 1) Trigger nhập hàng nhiều dòng: tồn SP01 tăng 10, SP02 tăng 20, tổng tiền = 140000.
EXEC sp_ThemPhieuNhap 'TSTPN1','NCC01','NV01';
INSERT CT_PHIEU_NHAP VALUES ('TSTPN1','SP01',10,4000),('TSTPN1','SP02',20,5000);
SELECT * FROM PHIEU_NHAP WHERE MaPN='TSTPN1';

-- 2) UPDATE chi tiết nhập: tồn kho và tổng tiền phải thay đổi theo chênh lệch.
UPDATE CT_PHIEU_NHAP SET SoLuongNhap=15, DonGiaNhap=4500 WHERE MaPN='TSTPN1' AND MaSP='SP01';
SELECT * FROM vw_LichSuNhapHang WHERE MaPN='TSTPN1';

-- 3) Test lỗi nhập số âm.
BEGIN TRY EXEC sp_ThemChiTietPhieuNhap 'TSTPN1','SP03',-1,1000; THROW 59901,N'Test thất bại: dữ liệu âm đã được chấp nhận.',1; END TRY
BEGIN CATCH IF ERROR_NUMBER()=59901 THROW; ELSE PRINT N'PASS: chặn số lượng nhập âm.'; END CATCH;

-- 4) Test bán vượt tồn.
EXEC sp_TaoHoaDon @MaHD='TSTHD1', @MaKH='KH01', @MaNV='NV02';
BEGIN TRY EXEC sp_ThemChiTietHoaDon 'TSTHD1','SP01',999999; THROW 59902,N'Test thất bại: bán vượt tồn.',1; END TRY
BEGIN CATCH IF ERROR_NUMBER()=59902 THROW; ELSE PRINT N'PASS: chặn bán vượt tồn.'; END CATCH;

-- 5) Hủy hóa đơn: hóa đơn còn lịch sử, chi tiết bị hoàn kho.
EXEC sp_HuyHoaDon 'TSTHD1';
SELECT MaHD,TrangThai FROM HOA_DON WHERE MaHD='TSTHD1';

-- 6) Không cho xóa hóa đơn trực tiếp.
BEGIN TRY DELETE FROM HOA_DON WHERE MaHD='TSTHD1'; THROW 59903,N'Test thất bại: đã xóa được hóa đơn.',1; END TRY
BEGIN CATCH IF ERROR_NUMBER()=59903 THROW; ELSE PRINT N'PASS: không cho xóa hóa đơn trực tiếp.'; END CATCH;
GO
