// API Client & Utility Helpers
const API = {
  async get(url) {
    try {
      const res = await fetch(url);
      if (!res.ok) {
        const error = await res.json();
        throw new Error(error.error || 'Yêu cầu không thành công');
      }
      return await res.json();
    } catch (err) {
      console.error(`API GET ${url} error:`, err);
      throw err;
    }
  },

  async post(url, data) {
    try {
      const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
      });
      if (!res.ok) {
        const error = await res.json();
        throw new Error(error.error || 'Thao tác thất bại');
      }
      return await res.json();
    } catch (err) {
      console.error(`API POST ${url} error:`, err);
      throw err;
    }
  }
};

// Định dạng tiền tệ VNĐ (VD: 45.000 đ)
function formatMoney(amount) {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(amount || 0);
}

// Định dạng ngày giờ VN
function formatDateTime(dt) {
  if (!dt) return '';
  return new Date(dt).toLocaleString('vi-VN');
}

// Hiển thị Toast thông báo trực quan
function showToast(message, type = 'success') {
  const container = document.getElementById('toast-container');
  if (!container) return;

  const toast = document.createElement('div');
  const bgColor = type === 'success' ? 'bg-emerald-600' : (type === 'error' ? 'bg-rose-600' : 'bg-blue-600');
  const icon = type === 'success' ? 'fa-check-circle' : (type === 'error' ? 'fa-exclamation-triangle' : 'fa-info-circle');

  toast.className = `${bgColor} text-white px-4 py-3 rounded-lg shadow-lg flex items-center gap-3 transform transition-all duration-300 translate-y-2 opacity-0 text-sm font-medium z-50`;
  toast.innerHTML = `
    <i class="fas ${icon} text-lg"></i>
    <span>${message}</span>
  `;

  container.appendChild(toast);

  // Hiệu ứng hiện ra
  setTimeout(() => {
    toast.classList.remove('translate-y-2', 'opacity-0');
  }, 10);

  // Tự động biến mất sau 3.5 giây
  setTimeout(() => {
    toast.classList.add('opacity-0', 'translate-y-2');
    setTimeout(() => toast.remove(), 300);
  }, 3500);
}

