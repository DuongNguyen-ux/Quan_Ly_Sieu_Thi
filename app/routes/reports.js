const express = require('express');
const router = express.Router();
const { getPool } = require('../config/db');

// GET /api/reports/dashboard - Tổng quan KPIs siêu thị
router.get('/dashboard', async (req, res) => {
  try {
    const pool = await getPool();
    const statsRes = await pool.request().query(`
      SELECT 
        ISNULL((SELECT SUM(TongTien) FROM HOA_DON WHERE TrangThai = N'Đã thanh toán'), 0) AS TongDoanhThu,
        (SELECT COUNT(*) FROM HOA_DON WHERE TrangThai = N'Đã thanh toán') AS TongHoaDonThanhCong,
        (SELECT COUNT(*) FROM HOA_DON WHERE TrangThai = N'Đã hủy') AS TongHoaDonHuy,
        (SELECT COUNT(*) FROM SAN_PHAM) AS TongSanPham,
        (SELECT COUNT(*) FROM SAN_PHAM WHERE SoLuongTon <= 20) AS SoSanPhamSapHet,
        (SELECT COUNT(*) FROM KHACH_HANG) AS TongKhachHang,
        (SELECT COUNT(*) FROM NHAN_VIEN) AS TongNhanVien,
        ISNULL((SELECT SUM(TongTien) FROM PHIEU_NHAP), 0) AS TongTienNhapHang
    `);

    res.json(statsRes.recordset[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/reports/revenue-by-day - Doanh thu theo ngày (vw_DoanhThuTheoNgay)
router.get('/revenue-by-day', async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().query(`
      SELECT CONVERT(VARCHAR(10), Ngay, 120) AS Ngay, SoHoaDon, DoanhThu 
      FROM vw_DoanhThuTheoNgay 
      ORDER BY Ngay ASC
    `);
    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/reports/best-sellers - Top sản phẩm bán chạy (vw_SanPhamBanChay)
router.get('/best-sellers', async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().query(`
      SELECT TOP 10 MaSP, TenSP, SoLuongDaBan, DoanhThu 
      FROM vw_SanPhamBanChay 
      ORDER BY SoLuongDaBan DESC, DoanhThu DESC
    `);
    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;

