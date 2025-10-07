import { Controller } from "@hotwired/stimulus"

// Chart.jsがグローバルに読み込まれているのでアクセス
// import Chart from "chart.js" は使わずにwindow.Chartを使用

export default class extends Controller {
  static targets = ["bloodPressure", "pulse"]
  static values = { 
    data: Object 
  }

  connect() {
    this.initializeCharts()
  }

  disconnect() {
    this.destroyCharts()
  }

  initializeCharts() {
    // Chart.jsが利用可能かチェック
    if (typeof Chart === 'undefined') {
      console.error('Chart.js が読み込まれていません')
      return
    }

    // 既存のチャートを破棄
    this.destroyCharts()

    console.log('Chart data from controller:', this.dataValue)

    // Chart.js の初期設定
    Chart.defaults.font.family = "'Hiragino Sans', 'Hiragino Kaku Gothic ProN', 'ヒラギノ角ゴ ProN W3', 'メイリオ', 'Meiryo', sans-serif"
    Chart.defaults.color = '#495057'

    // データが存在する場合はグラフを作成（ラベルだけあればデータがnullでも表示）
    if (this.dataValue && this.dataValue.labels) {
      this.createBloodPressureChart()
      this.createPulseChart()
    }
  }

  createBloodPressureChart() {
    if (!this.hasBloodPressureTarget) return

    const ctx = this.bloodPressureTarget.getContext('2d')
    this.bloodPressureChart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: this.dataValue.labels,
        datasets: [
          {
            label: '最高血圧 (mmHg)',
            data: this.dataValue.systolic,
            borderColor: '#dc3545',
            backgroundColor: 'rgba(220, 53, 69, 0.1)',
            borderWidth: 3,
            fill: false,
            tension: 0.1,
            pointBackgroundColor: '#dc3545',
            pointBorderColor: '#fff',
            pointBorderWidth: 2,
            pointRadius: 5,
            spanGaps: true
          },
          {
            label: '最低血圧 (mmHg)',
            data: this.dataValue.diastolic,
            borderColor: '#007bff',
            backgroundColor: 'rgba(0, 123, 255, 0.1)',
            borderWidth: 3,
            fill: false,
            tension: 0.1,
            pointBackgroundColor: '#007bff',
            pointBorderColor: '#fff',
            pointBorderWidth: 2,
            pointRadius: 5,
            spanGaps: true
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          title: {
            display: true,
            text: '血圧推移グラフ',
            font: {
              size: 16,
              weight: 'bold'
            }
          },
          legend: {
            position: 'top',
          }
        },
        scales: {
          y: {
            beginAtZero: false,
            suggestedMin: 40,
            suggestedMax: 200,
            title: {
              display: true,
              text: '血圧 (mmHg)'
            },
            grid: {
              color: 'rgba(0, 0, 0, 0.1)'
            }
          },
          x: {
            title: {
              display: true,
              text: '測定日時'
            },
            grid: {
              color: 'rgba(0, 0, 0, 0.1)'
            },
            ticks: {
              maxRotation: 0,
              minRotation: 0
            }
          }
        },
        interaction: {
          intersect: false,
          mode: 'index'
        }
      }
    })
  }

  createPulseChart() {
    if (!this.hasPulseTarget) return

    const ctx = this.pulseTarget.getContext('2d')
    this.pulseChart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: this.dataValue.labels,
        datasets: [
          {
            label: '脈拍 (bpm)',
            data: this.dataValue.pulse,
            borderColor: '#28a745',
            backgroundColor: 'rgba(40, 167, 69, 0.1)',
            borderWidth: 3,
            fill: true,
            tension: 0.1,
            pointBackgroundColor: '#28a745',
            pointBorderColor: '#fff',
            pointBorderWidth: 2,
            pointRadius: 5,
            spanGaps: true
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          title: {
            display: true,
            text: '脈拍推移グラフ',
            font: {
              size: 16,
              weight: 'bold'
            }
          },
          legend: {
            position: 'top',
          }
        },
        scales: {
          y: {
            beginAtZero: false,
            suggestedMin: 40,
            suggestedMax: 120,
            title: {
              display: true,
              text: '脈拍 (bpm)'
            },
            grid: {
              color: 'rgba(0, 0, 0, 0.1)'
            }
          },
          x: {
            title: {
              display: true,
              text: '測定日時'
            },
            grid: {
              color: 'rgba(0, 0, 0, 0.1)'
            },
            ticks: {
              maxRotation: 0,
              minRotation: 0
            }
          }
        },
        interaction: {
          intersect: false,
          mode: 'index'
        }
      }
    })
  }

  destroyCharts() {
    if (this.bloodPressureChart) {
      this.bloodPressureChart.destroy()
      this.bloodPressureChart = null
    }
    
    if (this.pulseChart) {
      this.pulseChart.destroy()
      this.pulseChart = null
    }
  }
}
