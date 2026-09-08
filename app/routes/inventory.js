const express = require('express');
const router = express.Router();
const { getPool, sql } = require('../config/db');

function generateId(prefix) {
  const now = new Date();
  const dateStr = now.toISOString().slice(2, 10).replace(/-/g, '');
  const randStr = Math.floor(1000 + Math.random() * 9000);
  return `${prefix}${dateStr.slice(-2)}${randStr}`.slice(0, 10);
}

// POST /api/inventory/receipt-full - Lập phiếu nhập hàng hoàn chỉnh (nhiều sản phẩm)
router.post('/receipt-full', async (req, res) => {
  try {
    const { maNCC, maNV, items, ngayNhap } = req.body;
    if (!maNCC || !maNV) return res.status(400).json({ error: 'Nhà cung cấp và nhân viên là bắt buộc.' });
    if (!items || !items.length) return res.status(400).json({ error: 'Cần ít nhất một sản phẩm để nhập kho.' });

    const pool = await getPool();
    const maPN = generateId('PN');

    // 1. Tạo phiếu nhập
    await pool.request()
      .input('MaPN', sql.VarChar(10), maPN)
      .input('MaNCC', sql.VarChar(10), maNCC)
      .input('MaNV', sql.VarChar(10), maNV)
      .input('NgayNhap', sql.Date, ngayNhap ? new Date(ngayNhap) : null)
      .execute('sp_ThemPhieuNhap');

    // 2. Thêm từng sản phẩm vào phiếu nhập (kích hoạt trigger tăng tồn kho)
    for (const item of items) {
      await pool.request()
        .input('MaPN', sql.VarChar(10), maPN)
        .input('MaSP', sql.VarChar(10), item.maSP)
        .input('SoLuongNhap', sql.Int, parseInt(item.soLuongNhap))
        .input('DonGiaNhap', sql.Decimal(18, 2), parseFloat(item.donGiaNhap))
        .execute('sp_ThemChiTietPhieuNhap');
    }

    // 3. Lấy thông tin phiếu nhập vừa tạo
    const pnRes = await pool.request()
      .input('MaPN', sql.VarChar(10), maPN)
      .query(`
        SELECT PN.MaPN, PN.NgayNhap, PN.TongTien, NCC.TenNCC, NV.HoTen AS TenNhanVien
        FROM PHIEU_NHAP PN
        JOIN NHA_CUNG_CAP NCC ON NCC.MaNCC = PN.MaNCC
        JOIN NHAN_VIEN NV ON NV.MaNV = PN.MaNV
        WHERE PN.MaPN = @MaPN
      `);

    res.status(201).json({
      success: true,
      message: `Nhập kho thành công cho phiếu ${maPN}! Tồn kho các sản phẩm đã được tự động cập nhật.`,
      receipt: pnRes.recordset[0]
    });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// GET /api/inventory/low-stock - Xem danh sách sản phẩm sắp hết hàng
router.get('/low-stock', async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().query('SELECT * FROM vw_SanPhamSapHet ORDER BY SoLuongTon ASC');
    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/inventory/history - Lịch sử nhập hàng từ View
router.get('/history', async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().query(`
      SELECT TOP 50 * 
      FROM vw_LichSuNhapHang 
      ORDER BY NgayNhap DESC, MaPN DESC
    `);
    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;

