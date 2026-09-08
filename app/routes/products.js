const express = require('express');
const router = express.Router();
const { getPool, sql } = require('../config/db');

// GET /api/categories - Lấy danh sách danh mục
router.get('/categories', async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().query('SELECT MaDM, TenDM FROM DANH_MUC ORDER BY MaDM');
    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/products - Lấy danh sách sản phẩm (hỗ trợ lọc theo danh mục hoặc tìm kiếm)
router.get('/products', async (req, res) => {
  try {
    const { category, search } = req.query;
    const pool = await getPool();
    const request = pool.request();
    
    let query = `
      SELECT SP.MaSP, SP.TenSP, SP.DonViTinh, SP.GiaBan, SP.SoLuongTon, SP.MaDM, DM.TenDM,
             CASE 
               WHEN SP.SoLuongTon = 0 THEN 'OUT_OF_STOCK'
               WHEN SP.SoLuongTon <= 20 THEN 'LOW_STOCK'
               ELSE 'IN_STOCK'
             END AS TrangThaiTonKho
      FROM SAN_PHAM SP
      JOIN DANH_MUC DM ON DM.MaDM = SP.MaDM
      WHERE 1=1
    `;

    if (category) {
      query += ` AND SP.MaDM = @category`;
      request.input('category', sql.VarChar(10), category);
    }

    if (search) {
      query += ` AND (SP.MaSP LIKE @search OR SP.TenSP LIKE @search)`;
      request.input('search', sql.NVarChar(150), `%${search}%`);
    }

    query += ` ORDER BY SP.MaDM, SP.MaSP`;

    const result = await request.query(query);
    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// GET /api/products/:id - Chi tiết 1 sản phẩm
router.get('/products/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const pool = await getPool();
    const result = await pool.request()
      .input('id', sql.VarChar(10), id)
      .query(`
        SELECT SP.*, DM.TenDM 
        FROM SAN_PHAM SP 
        JOIN DANH_MUC DM ON DM.MaDM = SP.MaDM 
        WHERE SP.MaSP = @id
      `);
    if (result.recordset.length === 0) {
      return res.status(404).json({ error: 'Không tìm thấy sản phẩm' });
    }
    res.json(result.recordset[0]);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;

