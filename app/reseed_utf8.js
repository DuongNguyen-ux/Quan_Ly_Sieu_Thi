const fs = require('fs');
const path = require('path');
const { getPool, sql } = require('./config/db');

async function reseed() {
  const pool = await getPool();
  console.log('Connected to SQL Server, beginning clean UTF-8 re-seed...');

  const files = [
    '../database/02_CreateTables.sql',
    '../database/03_SeedData.sql',
    '../database/04_Inventory.sql',
    '../database/05_Sales.sql',
    '../database/06_Reports.sql'
  ];

  for (const file of files) {
    const filePath = path.join(__dirname, file);
    const content = fs.readFileSync(filePath, 'utf8');
    // Tách các batch theo GO
    const batches = content
      .split(/^\s*GO\s*$/gmi)
      .map(b => b.trim())
      .filter(b => b.length > 0);

    console.log(`Executing ${path.basename(file)} (${batches.length} batches)...`);
    for (const batch of batches) {
      try {
        await pool.request().query(batch);
      } catch (err) {
        console.error(`Error in ${path.basename(file)}:`, err.message);
        throw err;
      }
    }
  }

  console.log(' RE-SEED THÀNH CÔNG! Kiểm tra lại dữ liệu mẫu...');
  const testDm = await pool.request().query('SELECT TOP 5 MaDM, TenDM FROM DANH_MUC');
  console.log('DANH_MUC:', testDm.recordset);

  const testSp = await pool.request().query('SELECT TOP 5 MaSP, TenSP FROM SAN_PHAM');
  console.log('SAN_PHAM:', testSp.recordset);

  const testNv = await pool.request().query('SELECT TOP 5 MaNV, HoTen FROM NHAN_VIEN');
  console.log('NHAN_VIEN:', testNv.recordset);

  process.exit(0);
}

reseed().catch(err => {
  console.error('Fatal reseed error:', err);
  process.exit(1);
});

