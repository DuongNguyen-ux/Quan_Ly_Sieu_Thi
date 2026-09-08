// Main Application Controller & Navigation
let currentTab = 'pos';

document.addEventListener('DOMContentLoaded', async () => {
  // 1. Khởi động đồng hồ thời gian thực
  startLiveClock();

  // 2. Kiểm tra kết nối CSDL
  checkSystemHealth();

  // 3. Khởi tạo POS làm màn hình mặc định
  await initPOS();

  // 4. Lắng nghe phím tắt POS tiện lợi (F9 để thanh toán, Esc đóng modal)
  document.addEventListener('keydown', (e) => {
    if (e.key === 'F9') {
      e.preventDefault();
      openCheckoutModal();
    }
    if (e.key === 'Escape') {
      closeCheckoutModal();
      closeReceiptModal();
      closeAddCustomerModal();
    }
  });
});

// Đồng hồ hệ thống
function startLiveClock() {
  const clockEl = document.getElementById('live-clock');
  function update() {
    const now = new Date();
    if (clockEl) {
      clockEl.innerText = now.toLocaleDateString('vi-VN') + ' ' + now.toLocaleTimeString('vi-VN');
    }
  }
  update();
  setInterval(update, 1000);
}

// Kiểm tra sức khỏe hệ thống & CSDL
async function checkSystemHealth() {
  const badge = document.getElementById('db-status-badge');
  try {
    const res = await API.get('/api/health');
    if (res.status === 'OK' && badge) {
      badge.innerHTML = `<span class="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span><span>SQL Server: Kết nối tốt</span>`;
      badge.className = 'flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-emerald-50 text-emerald-700 text-xs font-medium border border-emerald-200';
    }
  } catch (err) {
    if (badge) {
      badge.innerHTML = `<span class="w-2 h-2 rounded-full bg-rose-500"></span><span>Mất kết nối CSDL</span>`;
      badge.className = 'flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-rose-50 text-rose-700 text-xs font-medium border border-rose-200';
    }
  }
}

// Chuyển đổi giữa các phân hệ (Tabs)
function switchTab(tabName) {
  currentTab = tabName;

  // Ẩn tất cả các nội dung tab
  document.querySelectorAll('.tab-content').forEach(el => el.classList.add('hidden'));

  // Bỏ active tất cả các nút tab
  document.querySelectorAll('.nav-tab-btn').forEach(btn => {
    btn.classList.remove('bg-emerald-600', 'text-white', 'shadow-sm');
    btn.classList.add('text-slate-600', 'hover:bg-slate-100');
  });

  // Hiện tab được chọn
  const activeContent = document.getElementById(`tab-${tabName}`);
  if (activeContent) activeContent.classList.remove('hidden');

  // Active nút được chọn
  const activeBtn = document.getElementById(`btn-tab-${tabName}`);
  if (activeBtn) {
    activeBtn.classList.remove('text-slate-600', 'hover:bg-slate-100');
    activeBtn.classList.add('bg-emerald-600', 'text-white', 'shadow-sm');
  }

  // Khởi tạo/Tải lại dữ liệu cho tab tương ứng
  if (tabName === 'pos') {
    loadProducts().then(() => renderProducts());
  } else if (tabName === 'inventory') {
    initInventory();
  } else if (tabName === 'reports') {
    initReports();
  } else if (tabName === 'partners') {
    renderPartnersTab();
  }
}

// Hiển thị Tab Đối tác & Nhân sự
async function renderPartnersTab() {
  await loadPartners();

  // Bảng Khách hàng
  const custTable = document.getElementById('partners-cust-list');
  if (custTable) {
    custTable.innerHTML = customers.map(c => `
      <tr class="border-b border-slate-100 hover:bg-slate-50 text-xs">
        <td class="py-2.5 px-3 font-mono font-bold text-slate-800">${c.MaKH}</td>
        <td class="py-2.5 px-3 font-semibold text-slate-800">${c.HoTen}</td>
        <td class="py-2.5 px-3 font-mono text-slate-600">${c.DienThoai}</td>
        <td class="py-2.5 px-3 text-center">
          <span class="bg-amber-100 text-amber-800 px-2 py-0.5 rounded-full font-bold text-[11px]">
            ${c.DiemTichLuy} điểm
          </span>
        </td>
      </tr>
    `).join('');
  }

  // Bảng Nhân viên
  const empTable = document.getElementById('partners-emp-list');
  if (empTable) {
    empTable.innerHTML = employees.map(e => `
      <tr class="border-b border-slate-100 hover:bg-slate-50 text-xs">
        <td class="py-2.5 px-3 font-mono font-bold text-indigo-600">${e.MaNV}</td>
        <td class="py-2.5 px-3 font-semibold text-slate-800">${e.HoTen}</td>
        <td class="py-2.5 px-3 text-slate-600">${e.ChucVu}</td>
        <td class="py-2.5 px-3 font-mono text-slate-600">${e.DienThoai}</td>
        <td class="py-2.5 px-3 text-right font-medium text-slate-700">${formatMoney(e.Luong)}</td>
      </tr>
    `).join('');
  }

  // Bảng Nhà cung cấp
  const suppTable = document.getElementById('partners-supp-list');
  if (suppTable) {
    const suppliers = await API.get('/api/partners/suppliers');
    suppTable.innerHTML = suppliers.map(s => `
      <tr class="border-b border-slate-100 hover:bg-slate-50 text-xs">
        <td class="py-2.5 px-3 font-mono font-bold text-emerald-600">${s.MaNCC}</td>
        <td class="py-2.5 px-3 font-semibold text-slate-800">${s.TenNCC}</td>
        <td class="py-2.5 px-3 font-mono text-slate-600">${s.DienThoai}</td>
        <td class="py-2.5 px-3 text-slate-500 truncate max-w-[200px]">${s.DiaChi || '—'}</td>
        <td class="py-2.5 px-3 text-slate-500">${s.Email || '—'}</td>
      </tr>
    `).join('');
  }
}

