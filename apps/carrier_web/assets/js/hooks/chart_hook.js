import { Chart, registerables } from 'chart.js'

Chart.register(...registerables)

const ChartHook = {
  mounted() {
    const ctx = this.el.getContext('2d')
    const chart = new Chart(ctx, {
      type: 'line',
      data: {
        datasets: [{
          label: 'Data',
          data: [],
        }]
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
    this.handleEvent("input_data", ({ labels, data }) => {
      chart.data.datasets[0].data = data
      chart.options.scales['x'].title.text = labels[0]
      chart.options.scales['y'].title.text = labels[1]
      chart.update()
    })
  }
}

export default ChartHook
