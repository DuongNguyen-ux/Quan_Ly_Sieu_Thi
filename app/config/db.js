const sql = require('mssql/msnodesqlv8');

const config = {
  connectionString: 'Driver={ODBC Driver 17 for SQL Server};Server=localhost\\SQLEXPRESS;Database=QuanLySieuThi;Trusted_Connection=yes;'
};

let pool = null;

async function getPool() {
  if (!pool) {
    try {
      pool = await new sql.ConnectionPool(config).connect();
      console.log('✅ Đã kết nối thành công tới SQL Server (QuanLySieuThi)');
    } catch (err) {
      console.error('❌ Lỗi kết nối CSDL SQL Server:', err.message);
      throw err;
    }
  }
  return pool;
}

module.exports = {
  sql,
  getPool
};

