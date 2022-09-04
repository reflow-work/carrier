import { Chart, registerables } from 'chart.js'

Chart.register(...registerables)

const colors = {
  default: "#1C110A",
  current: "#E9B44C",
  previous: "#9B2915",
}

const ChartHook = {
  mounted() {
    const ctx = this.el.getContext('2d')
    const column_key = this.el.id.split("-").at(-1)
    const chart = new Chart(ctx, {
      type: 'line',
      data: {
        datasets: [],
        labels: [],
      },
      options: {
        scales: {
          y: {
            title: {
              display: true,
            },
          },
          x: {
            title: {
              display: true,
            },
            ticks: {
              callback: function(value, index, _ticks) {
                if (index % 7 === 0 || index === 27) {
                  return this.getLabelForValue(value)
                } else {
                  return null
                }
              },
            },
          }
        }
      }
    })
    this.handleEvent(`input_data_${column_key}`, ({ meta, data }) => {
      // Clear previous chart data
      chart.data.datasets = []
      chart.data.labels = []
      const key = meta.label
      const labels = []
      const current = []
      const previous = []
      data.forEach((datum) => {
        labels.push(datum.date)
        const currentPeriodKey = key + "_window_sum"
        const previousPeriodKey = key + "_window_sum_offset"
        current.push(datum[currentPeriodKey])
        previous.push(datum[previousPeriodKey])
      })
      const current_dataset = {
        label: "Current",
        data: current,
        borderColor: colors.current,
      }
      const previous_dataset = {
        label: "Previous",
        data: previous,
        borderColor: colors.previous,
      }
      chart.data.datasets = [current_dataset, previous_dataset]
      chart.data.labels = labels
      chart.options.scales['x'].title.text = "date"
      chart.options.scales['y'].title.text = key
      chart.update()
    })
  }
}

export default ChartHook
