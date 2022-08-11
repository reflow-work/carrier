import { Chart, registerables } from 'chart.js'

Chart.register(...registerables)

const colors = {
  default: "#1C110A",
  sum: "#E9B44C",
  offset: "#9B2915",
  over: "#50A2A7",
}

const ChartHook = {
  mounted() {
    const ctx = this.el.getContext('2d')
    const chart = new Chart(ctx, {
      type: 'line',
      data: {
        datasets: []
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
          }
        }
      }
    })
    this.handleEvent("input_data", ({ columns, data }) => {
      chart.data.datasets = []
      const nonDateKeys = Object.keys(data[0]).filter((k) => k !== "date")
      const currentPeriodKey = nonDateKeys.find((k) => k.endsWith("sum"))
      const previousPeriodKey = nonDateKeys.find((k) => k.endsWith("offset"))
      const currentPeriodData = data.map((datum) => {
        return { x: datum.date, y: datum[currentPeriodKey] }
      })
      const currentPeriodDataset = {
        label: currentPeriodKey,
        data: currentPeriodData,
        borderColor: colors.sum,
      }
      const previousPeriodData = data.map((datum) => {
        return { x: datum.date, y: datum[previousPeriodKey] }
      })
      const previousPeriodDataset = {
        label: previousPeriodKey,
        data: previousPeriodData,
        borderColor: colors.offset,
      }
      chart.data.datasets = [currentPeriodDataset, previousPeriodDataset]
      chart.options.scales['x'].title.text = columns[0]
      chart.options.scales['y'].title.text = columns[1]
      chart.update()
    })
  }
}

export default ChartHook
