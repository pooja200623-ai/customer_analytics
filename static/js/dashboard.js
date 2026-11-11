/**
 * Customer Segmentation & Purchase Behavior Analytics
 * Dashboard Charts & Interactive Behaviors
 */

document.addEventListener('DOMContentLoaded', function () {
  // 1. Mobile Sidebar Toggle
  const sidebar = document.getElementById('sidebar');
  const sidebarToggle = document.getElementById('sidebarToggle');

  if (sidebarToggle && sidebar) {
    sidebarToggle.addEventListener('click', function () {
      sidebar.classList.toggle('open');
    });

    // Close sidebar on click outside on mobile
    document.addEventListener('click', function (e) {
      if (
        window.innerWidth <= 860 &&
        sidebar.classList.contains('open') &&
        !sidebar.contains(e.target) &&
        !sidebarToggle.contains(e.target)
      ) {
        sidebar.classList.remove('open');
      }
    });
  }

  // 2. Chart.js Global Configurations
  Chart.defaults.font.family = "'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif";
  Chart.defaults.color = '#64748b';
  Chart.defaults.scale.grid.color = '#f1f5f9';

  // -------------------------------------------------------------
  // CHART 1: Monthly Sales (Bar + Line Hybrid)
  // -------------------------------------------------------------
  const monthlySalesCtx = document.getElementById('monthlySalesChart');
  if (monthlySalesCtx) {
    new Chart(monthlySalesCtx, {
      type: 'bar',
      data: {
        labels: [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ],
        datasets: [
          {
            type: 'line',
            label: 'Order Volume',
            data: [6, 8, 7, 10, 9, 12, 11, 14, 15, 13, 16, 18],
            borderColor: '#f59e0b',
            borderWidth: 2.5,
            pointBackgroundColor: '#ffffff',
            pointBorderColor: '#f59e0b',
            pointBorderWidth: 2,
            pointRadius: 4,
            pointHoverRadius: 6,
            yAxisID: 'yOrders',
            tension: 0.35,
          },
          {
            type: 'bar',
            label: 'Sales Revenue (₹ in Lakhs)',
            data: [1.85, 2.20, 1.95, 2.80, 2.45, 3.10, 2.90, 3.65, 3.90, 3.40, 4.15, 4.80],
            backgroundColor: 'rgba(37, 99, 235, 0.85)',
            hoverBackgroundColor: '#1d4ed8',
            borderRadius: 6,
            barPercentage: 0.55,
            yAxisID: 'yRevenue',
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        interaction: {
          mode: 'index',
          intersect: false,
        },
        plugins: {
          legend: {
            position: 'top',
            align: 'end',
            labels: {
              boxWidth: 12,
              usePointStyle: true,
              pointStyle: 'circle',
              font: { size: 12, weight: 500 }
            }
          },
          tooltip: {
            backgroundColor: '#0f172a',
            titleColor: '#ffffff',
            bodyColor: '#cbd5e1',
            padding: 12,
            boxPadding: 6,
            usePointStyle: true,
            callbacks: {
              label: function (context) {
                if (context.dataset.type === 'bar') {
                  return ` Revenue: ₹${(context.raw * 100000).toLocaleString('en-IN')}`;
                }
                return ` Orders: ${context.raw} orders`;
              }
            }
          }
        },
        scales: {
          x: {
            grid: { display: false }
          },
          yRevenue: {
            type: 'linear',
            position: 'left',
            grid: { borderDash: [4, 4] },
            ticks: {
              callback: function (val) {
                return '₹' + val + 'L';
              }
            }
          },
          yOrders: {
            type: 'linear',
            position: 'right',
            grid: { display: false },
            ticks: {
              stepSize: 5
            }
          }
        }
      }
    });
  }

  // -------------------------------------------------------------
  // CHART 2: Customer Segments (Doughnut Chart)
  // -------------------------------------------------------------
  const customerSegmentsCtx = document.getElementById('customerSegmentsChart');
  if (customerSegmentsCtx) {
    new Chart(customerSegmentsCtx, {
      type: 'doughnut',
      data: {
        labels: ['Platinum', 'Gold', 'Silver', 'Bronze', 'New'],
        datasets: [{
          data: [5, 7, 9, 6, 3],
          backgroundColor: [
            '#6366f1', // Platinum (Indigo)
            '#f59e0b', // Gold (Amber)
            '#94a3b8', // Silver (Slate)
            '#ea580c', // Bronze (Orange)
            '#10b981'  // New (Emerald)
          ],
          borderWidth: 3,
          borderColor: '#ffffff',
          hoverOffset: 6
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        cutout: '72%',
        plugins: {
          legend: {
            position: 'bottom',
            labels: {
              boxWidth: 12,
              usePointStyle: true,
              pointStyle: 'circle',
              padding: 14,
              font: { size: 12, weight: 500 }
            }
          },
          tooltip: {
            backgroundColor: '#0f172a',
            padding: 12,
            usePointStyle: true,
            callbacks: {
              label: function (context) {
                const total = context.dataset.data.reduce((a, b) => a + b, 0);
                const pct = ((context.raw / total) * 100).toFixed(1);
                return ` ${context.label}: ${context.raw} customers (${pct}%)`;
              }
            }
          }
        }
      }
    });
  }

  // -------------------------------------------------------------
  // CHART 3: Revenue Trends (Smooth Area Line Chart)
  // -------------------------------------------------------------
  const revenueTrendsCtx = document.getElementById('revenueTrendsChart');
  if (revenueTrendsCtx) {
    // Generate gradient fill
    const ctx = revenueTrendsCtx.getContext('2d');
    const gradient = ctx.createLinearGradient(0, 0, 0, 260);
    gradient.addColorStop(0, 'rgba(37, 99, 235, 0.28)');
    gradient.addColorStop(1, 'rgba(37, 99, 235, 0.00)');

    new Chart(revenueTrendsCtx, {
      type: 'line',
      data: {
        labels: [
          'Week 1', 'Week 2', 'Week 3', 'Week 4',
          'Week 5', 'Week 6', 'Week 7', 'Week 8',
          'Week 9', 'Week 10', 'Week 11', 'Week 12'
        ],
        datasets: [{
          label: 'Weekly Revenue (₹)',
          data: [
            115000, 142000, 128000, 169000,
            154000, 192000, 185000, 224000,
            210000, 248000, 235000, 280000
          ],
          borderColor: '#2563eb',
          backgroundColor: gradient,
          fill: true,
          tension: 0.4,
          borderWidth: 2.5,
          pointBackgroundColor: '#ffffff',
          pointBorderColor: '#2563eb',
          pointBorderWidth: 2,
          pointRadius: 4,
          pointHoverRadius: 6,
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          tooltip: {
            backgroundColor: '#0f172a',
            padding: 12,
            callbacks: {
              label: function (context) {
                return ` Revenue: ₹${context.raw.toLocaleString('en-IN')}`;
              }
            }
          }
        },
        scales: {
          x: {
            grid: { display: false }
          },
          y: {
            grid: { borderDash: [4, 4] },
            ticks: {
              callback: function (val) {
                return '₹' + (val / 1000) + 'k';
              }
            }
          }
        }
      }
    });
  }

  // Interactive filter pill toggles
  const filterPills = document.querySelectorAll('.filter-pill');
  filterPills.forEach(pill => {
    pill.addEventListener('click', function () {
      const parent = this.closest('.chart-filter-pills');
      if (parent) {
        parent.querySelectorAll('.filter-pill').forEach(p => p.classList.remove('active'));
        this.classList.add('active');
      }
    });
  });
});
