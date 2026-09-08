const express = require('express');
const router = express.Router();
const { getPool, sql } = require('../config/db');

// Helper sinh mã tự động an toàn
function generateId(prefix) {
  const now = new Date();
  const dateStr = now.toISOString().slice(2, 10).replace(/-/g, ''); // VD: 260908
  const randStr = Math.floor(1000 + Math.random() * 9000); // 4 số ngẫu nhiên
  return `${prefix}${dateStr.slice(-2)}${randStr}`.slice(0, 10); // Đảm bảo <= 10 ký tự
}

// POST /api/pos/orders - Tạo hóa đơn mới
router.post('/orders', async (req, res) => {
  try {
    const { maNV, maKH } = req.body;
    if (!maNV) return res.status(400).json({ error: 'Mã nhân viên là bắt buộc.' });

    const pool = await getPool();
    const maHD = generateId('HD');

    await pool.request()
      .input('MaHD', sql.VarChar(10), maHD)
      .input('MaNV', sql.VarChar(10), maNV)
      .input('MaKH', sql.VarChar(10), maKH || null)
      .execute('sp_TaoHoaDon');

    res.status(201).json({
      success: true,
      maHD,
      maNV,
      maKH: maKH || null,
      trangThai: 'Chưa thanh toán'
    });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// POST /api/pos/orders/:id/items - Thêm sản phẩm vào hóa đơn
router.post('/orders/:id/items', async (req, res) => {
  try {
    const { id: maHD } = req.params;
    const { maSP, soLuong } = req.body;

    if (!maSP || !soLuong || soLuong <= 0) {
      return res.status(400).json({ error: 'Mã sản phẩm và số lượng (>0) là bắt buộc.' });
    }

    const pool = await getPool();
    await pool.request()
      .input('MaHD', sql.VarChar(10), maHD)
      .input('MaSP', sql.VarChar(10), maSP)
      .input('SoLuong', sql.Int, parseInt(soLuong))
      .execute('sp_ThemChiTietHoaDon');

    // Lấy lại chi tiết hóa đơn cập nhật
    const itemsRes = await pool.request()
      .input('MaHD', sql.VarChar(10), maHD)
      .query(`
        SELECT CT.MaSP, SP.TenSP, CT.SoLuong, CT.DonGia, (CT.SoLuong * CT.DonGia) AS ThanhTien
        FROM CT_HOA_DON CT
        JOIN SAN_PHAM SP ON SP.MaSP = CT.MaSP
        WHERE CT.MaHD = @MaHD
      `);

    const hdRes = await pool.request()
      .input('MaHD', sql.VarChar(10), maHD)
      .query('SELECT TongTien, TrangThai FROM HOA_DON WHERE MaHD = @MaHD');

    res.json({
      success: true,
      maHD,
      tongTien: hdRes.recordset[0]?.TongTien || 0,
      trangThai: hdRes.recordset[0]?.TrangThai,
      items: itemsRes.recordset
    });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// POST /api/pos/orders/:id/checkout - Thanh toán hóa đơn
router.post('/orders/:id/checkout', async (req, res) => {
  try {
    const { id: maHD } = req.params;
    const { phuongThuc } = req.body;

    if (!phuongThuc) return res.status(400).json({ error: 'Vui lòng chọn phương thức thanh toán.' });

    const pool = await getPool();
    const maTT = generateId('TT');

    await pool.request()
      .input('MaTT', sql.VarChar(10), maTT)
      .input('MaHD', sql.VarChar(10), maHD)
      .input('PhuongThuc', sql.NVarChar(30), phuongThuc)
      .execute('sp_ThanhToanHoaDon');

    // Lấy thông tin hóa đơn và khách hàng sau thanh toán
    const infoRes = await pool.request()
      .input('MaHD', sql.VarChar(10), maHD)
      .query(`
        SELECT HD.MaHD, HD.NgayLap, HD.TongTien, HD.TrangThai, HD.MaKH,
               KH.HoTen AS TenKhachHang, KH.DiemTichLuy,
               NV.HoTen AS TenNhanVien,
               TT.MaTT, TT.PhuongThuc, TT.NgayThanhToan,
               dbo.fn_TinhDiemKhachHang(HD.TongTien) AS DiemNhanDuoc
        FROM HOA_DON HD
        LEFT JOIN KHACH_HANG KH ON KH.MaKH = HD.MaKH
        JOIN NHAN_VIEN NV ON NV.MaNV = HD.MaNV
        JOIN THANH_TOAN TT ON TT.MaHD = HD.MaHD
        WHERE HD.MaHD = @MaHD
      `);

    res.json({
      success: true,
      message: 'Thanh toán hóa đơn thành công!',
      order: infoRes.recordset[0]
    });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// POST /api/pos/orders/:id/cancel - Hủy hóa đơn
router.post('/orders/:id/cancel', async (req, res) => {
  try {
    const { id: maHD } = req.params;
    const pool = await getPool();

    await pool.request()
      .input('MaHD', sql.VarChar(10), maHD)
      .execute('sp_HuyHoaDon');

    res.json({ success: true, message: `Hóa đơn ${maHD} đã được hủy và hoàn trả kho thành công!` });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// POST /api/pos/checkout-full - Tạo đơn và thanh toán nhanh 1 bước từ giỏ hàng
router.post('/checkout-full', async (req, res) => {
  try {
    const { maNV, maKH, items, phuongThuc } = req.body;
    if (!maNV) return res.status(400).json({ error: 'Chưa chọn nhân viên thu ngân.' });
    if (!items || !items.length) return res.status(400).json({ error: 'Giỏ hàng đang trống.' });

    const pool = await getPool();
    const maHD = generateId('HD');
    const maTT = generateId('TT');

    // 1. Tạo hóa đơn
    await pool.request()
      .input('MaHD', sql.VarChar(10), maHD)
      .input('MaNV', sql.VarChar(10), maNV)
      .input('MaKH', sql.VarChar(10), maKH || null)
      .execute('sp_TaoHoaDon');

    // 2. Thêm từng mặt hàng
    for (const item of items) {
      await pool.request()
        .input('MaHD', sql.VarChar(10), maHD)
        .input('MaSP', sql.VarChar(10), item.maSP)
        .input('SoLuong', sql.Int, parseInt(item.soLuong))
        .execute('sp_ThemChiTietHoaDon');
    }

    // 3. Thanh toán hóa đơn
    await pool.request()
      .input('MaTT', sql.VarChar(10), maTT)
      .input('MaHD', sql.VarChar(10), maHD)
      .input('PhuongThuc', sql.NVarChar(30), phuongThuc || 'Tiền mặt')
      .execute('sp_ThanhToanHoaDon');

    // 4. Lấy chi tiết đơn hàng hoàn chỉnh để trả về in hóa đơn
    const receiptRes = await pool.request()
      .input('MaHD', sql.VarChar(10), maHD)
      .query(`
        SELECT HD.MaHD, HD.NgayLap, HD.TongTien, HD.TrangThai, HD.MaKH,
               ISNULL(KH.HoTen, N'Khách vãng lai') AS TenKhachHang, 
               ISNULL(KH.DiemTichLuy, 0) AS DiemTichLuy,
               NV.HoTen AS TenNhanVien,
               TT.MaTT, TT.PhuongThuc, TT.NgayThanhToan,
               dbo.fn_TinhDiemKhachHang(HD.TongTien) AS DiemNhanDuoc
        FROM HOA_DON HD
        LEFT JOIN KHACH_HANG KH ON KH.MaKH = HD.MaKH
        JOIN NHAN_VIEN NV ON NV.MaNV = HD.MaNV
        JOIN THANH_TOAN TT ON TT.MaHD = HD.MaHD
        WHERE HD.MaHD = @MaHD
      `);

    const itemsDetail = await pool.request()
      .input('MaHD', sql.VarChar(10), maHD)
      .query(`
        SELECT CT.MaSP, SP.TenSP, SP.DonViTinh, CT.SoLuong, CT.DonGia, (CT.SoLuong * CT.DonGia) AS ThanhTien
        FROM CT_HOA_DON CT
        JOIN SAN_PHAM SP ON SP.MaSP = CT.MaSP
        WHERE CT.MaHD = @MaHD
      `);

    res.status(201).json({
      success: true,
      receipt: {
        ...receiptRes.recordset[0],
        items: itemsDetail.recordset
      }
    });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// GET /api/pos/recent-invoices - Danh sách hóa đơn gần đây
router.get('/recent-invoices', async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().query(`
      SELECT TOP 20 
             HD.MaHD, HD.NgayLap, HD.TongTien, HD.TrangThai,
             ISNULL(KH.HoTen, N'Khách vãng lai') AS TenKhachHang,
             NV.HoTen AS TenNhanVien,
             TT.PhuongThuc
      FROM HOA_DON HD
      LEFT JOIN KHACH_HANG KH ON KH.MaKH = HD.MaKH
      JOIN NHAN_VIEN NV ON NV.MaNV = HD.MaNV
      LEFT JOIN THANH_TOAN TT ON TT.MaHD = HD.MaHD
      ORDER BY HD.NgayLap DESC
    `);
    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/pos/orders/:id - Tra cứu chi tiết một hóa đơn
router.get('/orders/:id', async (req, res) => {
  try {
    const { id: maHD } = req.params;
    const pool = await getPool();

    const orderRes = await pool.request()
      .input('MaHD', sql.VarChar(10), maHD)
      .query(`
        SELECT HD.MaHD, HD.NgayLap, HD.TongTien, HD.TrangThai, HD.MaKH,
               ISNULL(KH.HoTen, N'Khách vãng lai') AS TenKhachHang,
               NV.HoTen AS TenNhanVien,
               TT.MaTT, TT.PhuongThuc, TT.NgayThanhToan
        FROM HOA_DON HD
        LEFT JOIN KHACH_HANG KH ON KH.MaKH = HD.MaKH
        JOIN NHAN_VIEN NV ON NV.MaNV = HD.MaNV
        LEFT JOIN THANH_TOAN TT ON TT.MaHD = HD.MaHD
        WHERE HD.MaHD = @MaHD
      `);

    if (orderRes.recordset.length === 0) {
      return res.status(404).json({ error: 'Không tìm thấy hóa đơn' });
    }

    const itemsRes = await pool.request()
      .input('MaHD', sql.VarChar(10), maHD)
      .query(`
        SELECT CT.MaSP, SP.TenSP, SP.DonViTinh, CT.SoLuong, CT.DonGia, (CT.SoLuong * CT.DonGia) AS ThanhTien
        FROM CT_HOA_DON CT
        JOIN SAN_PHAM SP ON SP.MaSP = CT.MaSP
        WHERE CT.MaHD = @MaHD
      `);

    res.json({
      order: orderRes.recordset[0],
      items: itemsRes.recordset
    });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
