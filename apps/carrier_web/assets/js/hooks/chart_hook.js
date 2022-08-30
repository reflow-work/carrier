import { Chart, registerables } from 'chart.js'

Chart.register(...registerables)

const colors = {
  default: "#1C110A",
  current: "#E9B44C",
  previous: "#9B2915",
  over: "#50A2A7",
}

const ChartHook = {
  mounted() {
    const ctx = this.el.getContext('2d')
    const column_key = this.el.id.split("-").at(-1)
    const chart = new Chart(ctx, {
      type: 'line',
      data: {
        datasets: [],
        labels: []
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
            grid: {
              display: false,
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

    this.handleEvent("input_data", ({ columns, data }) => {
      chart.data.datasets = []
      chart.data.labels = []
      const labels = []
      const nonDateKeys = columns.filter((k) => k !== "date")
      const ticks = Object.fromEntries(nonDateKeys.map((k) => {
        const innerObject = {
          current: [],
          previous: [],
        }
        return [k, innerObject]
      }))
      data.forEach((datum) => {
        labels.push(datum.date)
        nonDateKeys.forEach((k) => {
          const currentPeriodKey = k + "_window_sum"
          const previousPeriodKey = k + "_window_sum_offset"
          ticks[k].current.push(datum[currentPeriodKey])
          ticks[k].previous.push(datum[previousPeriodKey])
        })
      })
      const datasets = []
      for (const k in ticks) {
        for (const period in ticks[k]) {
          const dataset = {
            label: [period, k].join("_"),
            data: ticks[k][period],
            borderColor: colors[period],
          }
          datasets.push(dataset)
        }
      }
      chart.data.datasets = datasets
      chart.data.labels = labels
      chart.options.scales['x'].title.text = "date"
      chart.options.scales['y'].title.text = columns[1]
      chart.update()
    })
  }
}

export default ChartHook
