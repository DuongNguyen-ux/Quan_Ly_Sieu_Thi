// Báo cáo & Thống kê (Dashboard & Analytics)
let revenueChart = null;

async function initReports() {
  await Promise.all([
    loadDashboardKPIs(),
    loadRevenueChart(),
    loadBestSellers(),
    loadRecentInvoices()
  ]);
}

// 1. Tải KPIs tổng quan
async function loadDashboardKPIs() {
  try {
    const data = await API.get('/api/reports/dashboard');

    document.getElementById('kpi-revenue').innerText = formatMoney(data.TongDoanhThu);
    document.getElementById('kpi-orders').innerText = (data.TongHoaDonThanhCong || 0).toLocaleString('vi-VN');
    document.getElementById('kpi-products').innerText = (data.TongSanPham || 0).toLocaleString('vi-VN');
    document.getElementById('kpi-customers').innerText = (data.TongKhachHang || 0).toLocaleString('vi-VN');

    const lowStockAlert = document.getElementById('kpi-low-stock-alert');
    if (lowStockAlert) {
      if (data.SoSanPhamSapHet > 0) {
        lowStockAlert.innerHTML = `<span class="text-rose-600 font-semibold"><i class="fas fa-triangle-exclamation mr-1"></i>Có ${data.SoSanPhamSapHet} sản phẩm sắp hết</span>`;
      } else {
        lowStockAlert.innerHTML = `<span class="text-emerald-600"><i class="fas fa-check-circle mr-1"></i>Tồn kho an toàn</span>`;
      }
    }
  } catch (err) {
    console.error('Lỗi tải KPIs:', err);
  }
}

// 2. Biểu đồ Doanh thu theo ngày (Chart.js)
async function loadRevenueChart() {
  try {
    const data = await API.get('/api/reports/revenue-by-day');
    const ctx = document.getElementById('revenue-chart')?.getContext('2d');
    if (!ctx) return;

    const labels = data.map(d => d.Ngay);
    const revenues = data.map(d => d.DoanhThu);
    const orderCounts = data.map(d => d.SoHoaDon);

    if (revenueChart) {
      revenueChart.destroy();
    }

    revenueChart = new Chart(ctx, {
      type: 'bar',
      data: {
        labels: labels.length ? labels : ['Hôm nay'],
        datasets: [
          {
            label: 'Doanh thu (VNĐ)',
            data: revenues.length ? revenues : [0],
            backgroundColor: 'rgba(16, 185, 129, 0.7)',
            borderColor: 'rgb(16, 185, 129)',
            borderWidth: 1.5,
            borderRadius: 6,
            yAxisID: 'y'
          },
          {
            label: 'Số lượng hóa đơn',
            data: orderCounts.length ? orderCounts : [0],
            type: 'line',
            borderColor: 'rgb(59, 130, 246)',
            backgroundColor: 'rgba(59, 130, 246, 0.1)',
            borderWidth: 2,
            tension: 0.3,
            fill: false,
            yAxisID: 'y1'
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { position: 'top', labels: { font: { family: 'Inter', size: 12 } } },
          tooltip: {
            callbacks: {
              label: function(context) {
                if (context.dataset.yAxisID === 'y') {
                  return ' Doanh thu: ' + formatMoney(context.raw);
                }
                return ' Đơn hàng: ' + context.raw + ' hóa đơn';
              }
            }
          }
        },
        scales: {
          y: {
            type: 'linear',
            display: true,
            position: 'left',
            ticks: {
              callback: val => (val >= 1000000 ? (val / 1000000) + ' Tr' : (val / 1000) + ' k')
            }
          },
          y1: {
            type: 'linear',
            display: true,
            position: 'right',
            grid: { drawOnChartArea: false },
            ticks: { precision: 0 }
          }
        }
      }
    });
  } catch (err) {
    console.error('Lỗi tải biểu đồ doanh thu:', err);
  }
}

// 3. Danh sách Sản phẩm bán chạy
async function loadBestSellers() {
  try {
    const data = await API.get('/api/reports/best-sellers');
    const container = document.getElementById('report-best-sellers-list');
    if (!container) return;

    if (data.length === 0) {
      container.innerHTML = `<tr><td colspan="4" class="py-6 text-center text-slate-400 text-xs">Chưa có giao dịch bán hàng nào thành công.</td></tr>`;
      return;
    }

    container.innerHTML = data.map((item, idx) => `
      <tr class="border-b border-slate-100 hover:bg-slate-50/50 text-xs">
        <td class="py-2.5 px-3">
          <span class="w-5 h-5 inline-flex items-center justify-center rounded-full text-[10px] font-bold ${idx < 3 ? 'bg-amber-100 text-amber-700' : 'bg-slate-100 text-slate-600'}">
            ${idx + 1}
          </span>
        </td>
        <td class="py-2.5 px-3 font-semibold text-slate-800">${item.TenSP} <span class="text-slate-400 font-mono text-[10px]">(${item.MaSP})</span></td>
        <td class="py-2.5 px-3 text-center font-bold text-indigo-600">${item.SoLuongDaBan.toLocaleString('vi-VN')}</td>
        <td class="py-2.5 px-3 text-right font-bold text-emerald-600">${formatMoney(item.DoanhThu)}</td>
      </tr>
    `).join('');
  } catch (err) {
    console.error('Lỗi tải sản phẩm bán chạy:', err);
  }
}

// 4. Danh sách hóa đơn gần đây
async function loadRecentInvoices() {
  try {
    const invoices = await API.get('/api/pos/recent-invoices');
    const container = document.getElementById('recent-invoices-list');
    if (!container) return;

    if (invoices.length === 0) {
      container.innerHTML = `<tr><td colspan="7" class="py-6 text-center text-slate-400 text-xs">Chưa có hóa đơn nào</td></tr>`;
      return;
    }

    container.innerHTML = invoices.map(inv => {
      const isPaid = inv.TrangThai === 'Đã thanh toán';
      const isCancelled = inv.TrangThai === 'Đã hủy';

      const statusBadge = isPaid
        ? `<span class="bg-emerald-100 text-emerald-700 text-[10px] font-bold px-2 py-0.5 rounded-full">Đã thanh toán</span>`
        : (isCancelled
            ? `<span class="bg-slate-100 text-slate-600 text-[10px] font-bold px-2 py-0.5 rounded-full">Đã hủy</span>`
            : `<span class="bg-amber-100 text-amber-700 text-[10px] font-bold px-2 py-0.5 rounded-full">Chờ thanh toán</span>`);

      return `
        <tr class="border-b border-slate-100 hover:bg-slate-50/50 text-xs">
          <td class="py-2.5 px-3 font-mono font-bold text-slate-800">${inv.MaHD}</td>
          <td class="py-2.5 px-3 text-slate-500">${formatDateTime(inv.NgayLap)}</td>
          <td class="py-2.5 px-3 font-medium text-slate-700">${inv.TenKhachHang}</td>
          <td class="py-2.5 px-3 text-slate-600">${inv.TenNhanVien}</td>
          <td class="py-2.5 px-3 text-right font-bold text-emerald-600">${formatMoney(inv.TongTien)}</td>
          <td class="py-2.5 px-3 text-center">${statusBadge}</td>
          <td class="py-2.5 px-3 text-center">
            <button onclick="viewInvoiceDetail('${inv.MaHD}')" class="text-indigo-600 hover:text-indigo-800 text-xs font-semibold">
              <i class="fas fa-eye mr-1"></i>Xem
            </button>
          </td>
        </tr>
      `;
    }).join('');
  } catch (err) {
    console.error('Lỗi tải hóa đơn gần đây:', err);
  }
}

// Xem chi tiết một hóa đơn trong Modal
async function viewInvoiceDetail(maHD) {
  try {
    const data = await API.get(`/api/pos/orders/${maHD}`);
    const { order, items } = data;

    const receipt = {
      MaHD: order.MaHD,
      NgayLap: order.NgayLap,
      TenNhanVien: order.TenNhanVien,
      TenKhachHang: order.TenKhachHang,
      PhuongThuc: order.PhuongThuc || 'Chưa thanh toán',
      TongTien: order.TongTien,
      DiemNhanDuoc: Math.floor(order.TongTien / 10000),
      items: items
    };

    openReceiptModal(receipt);
  } catch (err) {
    showToast('Lỗi xem hóa đơn: ' + err.message, 'error');
  }
}

