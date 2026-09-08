const express = require('express');
const router = express.Router();
const { getPool, sql } = require('../config/db');

// GET /api/partners/employees - Danh sách nhân viên
router.get('/employees', async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().query(`
      SELECT MaNV, HoTen, ChucVu, DienThoai, NgayVaoLam, Luong 
      FROM NHAN_VIEN 
      ORDER BY MaNV
    `);
    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/partners/customers - Danh sách khách hàng
router.get('/customers', async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().query(`
      SELECT MaKH, HoTen, DienThoai, DiemTichLuy 
      FROM KHACH_HANG 
      ORDER BY DiemTichLuy DESC, MaKH
    `);
    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/partners/customers - Tạo nhanh khách hàng mới
router.post('/customers', async (req, res) => {
  try {
    const { hoTen, dienThoai } = req.body;
    if (!hoTen || !dienThoai) {
      return res.status(400).json({ error: 'Họ tên và số điện thoại là bắt buộc.' });
    }

    const pool = await getPool();
    
    // Tự động sinh mã KH mới (VD: KH09, KH10...)
    const countRes = await pool.request().query("SELECT COUNT(*) AS total FROM KHACH_HANG");
    const nextNum = (countRes.recordset[0].total + 1).toString().padStart(2, '0');
    let maKH = `KH${nextNum}`;

    // Kiểm tra trùng mã
    const existRes = await pool.request().input('maKH', sql.VarChar(10), maKH).query("SELECT 1 FROM KHACH_HANG WHERE MaKH = @maKH");
    if (existRes.recordset.length > 0) {
      maKH = `KH${Date.now().toString().slice(-4)}`;
    }

    await pool.request()
      .input('maKH', sql.VarChar(10), maKH)
      .input('hoTen', sql.NVarChar(100), hoTen)
      .input('dienThoai', sql.VarChar(15), dienThoai)
      .query(`INSERT INTO KHACH_HANG (MaKH, HoTen, DienThoai, DiemTichLuy) VALUES (@maKH, @hoTen, @dienThoai, 0)`);

    res.status(201).json({ success: true, maKH, hoTen, dienThoai, diemTichLuy: 0 });
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

// GET /api/partners/suppliers - Danh sách nhà cung cấp
router.get('/suppliers', async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().query(`
      SELECT MaNCC, TenNCC, DiaChi, DienThoai, Email 
      FROM NHA_CUNG_CAP 
      ORDER BY MaNCC
    `);
    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;

