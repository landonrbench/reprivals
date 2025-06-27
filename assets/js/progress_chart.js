// Progress Chart Hook for Workout Results
export const ProgressChart = {
  mounted() {
    this.initChart();
  },

  updated() {
    this.initChart();
  },

  initChart() {
    const canvas = this.el;
    const ctx = canvas.getContext("2d");
    const chartData = JSON.parse(canvas.dataset.chartData || "[]");
    const metric = canvas.dataset.metric;

    // Clear canvas
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    if (chartData.length === 0) {
      return;
    }

    // Set canvas size
    const dpr = window.devicePixelRatio || 1;
    const rect = canvas.getBoundingClientRect();
    canvas.width = rect.width * dpr;
    canvas.height = rect.height * dpr;
    ctx.scale(dpr, dpr);

    const width = rect.width;
    const height = rect.height;
    const padding = 40;
    const chartWidth = width - padding * 2;
    const chartHeight = height - padding * 2;

    // Prepare data
    const values = chartData.map((d) => d.value);
    const minValue = Math.min(...values);
    const maxValue = Math.max(...values);
    const valueRange = maxValue - minValue || 1;

    // Draw background
    ctx.fillStyle = "#f8f9fa";
    ctx.fillRect(0, 0, width, height);

    // Draw grid lines
    ctx.strokeStyle = "#e9ecef";
    ctx.lineWidth = 1;

    // Horizontal grid lines
    for (let i = 0; i <= 4; i++) {
      const y = padding + (chartHeight / 4) * i;
      ctx.beginPath();
      ctx.moveTo(padding, y);
      ctx.lineTo(width - padding, y);
      ctx.stroke();
    }

    // Draw axis labels
    ctx.fillStyle = "#6c757d";
    ctx.font = "12px sans-serif";
    ctx.textAlign = "right";

    // Y-axis labels
    for (let i = 0; i <= 4; i++) {
      const value = maxValue - (valueRange / 4) * i;
      const y = padding + (chartHeight / 4) * i;
      const label = this.formatValue(value, metric);
      ctx.fillText(label, padding - 10, y + 4);
    }

    // Draw data line
    if (chartData.length > 1) {
      ctx.strokeStyle = "#dc3545";
      ctx.lineWidth = 3;
      ctx.beginPath();

      chartData.forEach((point, index) => {
        const x = padding + (chartWidth / (chartData.length - 1)) * index;
        const y =
          padding +
          chartHeight -
          ((point.value - minValue) / valueRange) * chartHeight;

        if (index === 0) {
          ctx.moveTo(x, y);
        } else {
          ctx.lineTo(x, y);
        }
      });

      ctx.stroke();
    }

    // Draw data points
    ctx.fillStyle = "#dc3545";
    chartData.forEach((point, index) => {
      const x =
        padding + (chartWidth / Math.max(chartData.length - 1, 1)) * index;
      const y =
        padding +
        chartHeight -
        ((point.value - minValue) / valueRange) * chartHeight;

      ctx.beginPath();
      ctx.arc(x, y, 4, 0, Math.PI * 2);
      ctx.fill();
    });

    // Draw X-axis labels
    ctx.fillStyle = "#6c757d";
    ctx.font = "10px sans-serif";
    ctx.textAlign = "center";

    chartData.forEach((point, index) => {
      if (
        chartData.length <= 5 ||
        index % Math.ceil(chartData.length / 5) === 0
      ) {
        const x =
          padding + (chartWidth / Math.max(chartData.length - 1, 1)) * index;
        const y = height - padding + 15;
        ctx.fillText(point.date, x, y);
      }
    });
  },

  formatValue(value, metric) {
    switch (metric) {
      case "For Time":
        // Convert seconds back to MM:SS format
        const minutes = Math.floor(value / 60);
        const seconds = Math.floor(value % 60);
        return `${minutes}:${seconds.toString().padStart(2, "0")}`;
      case "Weight":
        return `${Math.round(value)}`;
      case "For Reps":
        return `${Math.round(value)}`;
      default:
        return `${Math.round(value)}`;
    }
  },
};
