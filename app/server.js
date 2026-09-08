const express = require('express');
const cors = require('cors');
const path = require('path');
const { getPool } = require('./config/db');

const productsRouter = require('./routes/products');
const partnersRouter = require('./routes/partners');
const posRouter = require('./routes/pos');
const inventoryRouter = require('./routes/inventory');
const reportsRouter = require('./routes/reports');

const app = express();
const PORT = process.env.PORT || 3000;

// Middlewares
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Phục vụ giao diện tĩnh
app.use(express.static(path.join(__dirname, 'public')));

// Đăng ký API Routes
app.use('/api', productsRouter);
app.use('/api/partners', partnersRouter);
app.use('/api/pos', posRouter);
app.use('/api/inventory', inventoryRouter);
app.use('/api/reports', reportsRouter);

// Health check endpoint
app.get('/api/health', async (req, res) => {
  try {
    const pool = await getPool();
    const result = await pool.request().query('SELECT @@SERVERNAME AS ServerName, DB_NAME() AS DatabaseName');
    res.json({
      status: 'OK',
      message: 'Hệ thống Quản lý Siêu thị đang hoạt động bình thường',
      database: result.recordset[0]
    });
  } catch (err) {
    res.status(500).json({ status: 'ERROR', error: err.message });
  }
});

// Chuyển hướng các route không khớp về trang chủ
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Khởi động server
app.listen(PORT, async () => {
  console.log(`=======================================================`);
  console.log(`🚀 ỨNG DỤNG QUẢN LÝ SIÊU THỊ ĐANG CHẠY TẠI:`);
  console.log(`👉 http://localhost:${PORT}`);
  console.log(`=======================================================`);
  try {
    await getPool();
  } catch (err) {
    console.warn('⚠️ Cảnh báo: Chưa kết nối được SQL Server khi khởi động.');
  }
});

