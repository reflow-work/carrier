import { Chart, registerables } from 'chart.js'

Chart.register(...registerables)

const randomNum = () => Math.floor(Math.random() * (235 - 52 + 1) + 52);
const randomRGB = () => `rgb(${randomNum()}, ${randomNum()}, ${randomNum()})`;

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
      const parsedData = {}
      const nonDateKeys = Object.keys(data[0]).filter((k) => k !== "date")
      nonDateKeys.forEach((k) => { parsedData[k] = [] })
      data.forEach((datum) => {
        const date = datum.date
        nonDateKeys.forEach((k) => { parsedData[k].push({ x: date, y: datum[k] }) })
      })
      for (const k in parsedData) {
        const currentData = parsedData[k].reverse()
        const label = k
        let color = "#E4D6A7"
        if (k.endsWith("sum")) {
          color = colors.sum
        } else if (k.endsWith("over")) {
          color = colors.over
        } else if (k.endsWith("offset")) {
          color = colors.offset
        } else {
          color = colors.default
        }
        const dataset = {
          label,
          data: currentData,
          borderColor: color,
        }
        chart.data.datasets.push(dataset)
      }
      chart.options.scales['x'].title.text = columns[0]
      chart.options.scales['y'].title.text = columns[1]
      chart.update()
    })
  }
}

export default ChartHook
