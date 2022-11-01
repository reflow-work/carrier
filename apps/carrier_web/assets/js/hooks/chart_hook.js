import { Chart, registerables } from 'chart.js'

Chart.register(...registerables)

const colors = {
  default: "#1C110A",
  current: "#1b9e77",
  previous: "#d95f02",
}

const getMinScale = (ns) => {
  const [significantFigures, exponent] = (Math.min(...ns)).toPrecision(2).split('e')
  const flooredSignificantFigures = ((Math.floor(parseFloat(significantFigures) * 2)) / 2).toString()
  return parseFloat(`${flooredSignificantFigures}e${exponent}`)
}

const getMaxScale = (ns) => {
  const [significantFigures, exponent] = (Math.max(...ns)).toPrecision(2).split('e')
  const ceiledSignificantFigures = ((Math.ceil(parseFloat(significantFigures) * 2)) / 2).toString()
  return parseFloat(`${ceiledSignificantFigures}e${exponent}`)
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
        elements: {
          point: {
            radius: 0,
          }
        },
        plugins: {
          legend: {
            display: true,
            labels: {
              font: {
                size: 18,
                weight: 700,
              }
            }
          }
        },
        scales: {
          y: {
            title: {
              display: true,
              font: {
                size: 20,
                weight: 700,
              }
            },
            ticks: {
              count: 5,
              font: {
                size: 20,
                weight: 700,
              },
            },
          },
          x: {
            title: {
              display: true,
              font: {
                size: 20,
                weight: 700,
              }
            },
            grid: {
              display: false,
            },
            ticks: {
              callback: function(value, index, ticks) {
                if (index % (Math.floor(ticks.length / 4)) === 0 || index === ticks.length - 1) {
                  return this.getLabelForValue(value).split("-").slice(1).join("/")
                } else {
                  return null
                }
              },
              font: {
                size: 20,
                weight: 700,
              }
            },
          }
        }
      }
    })
    this.handleEvent(`input_data_${column_key}`, ({ meta, data }) => {
      // Clear previous chart data
      chart.data.datasets = []
      chart.data.labels = []
      const labels = []
      const current = []
      const previous = []
      const key = meta.label
      const date_column_name = meta.date_column_name
      data.forEach((datum) => {
        labels.push(datum[date_column_name])
        const currentPeriodKey = key + "_window_sum"
        const previousPeriodKey = key + "_window_sum_offset"
        current.push(datum[currentPeriodKey])
        previous.push(datum[previousPeriodKey])
      })
      const current_dataset = {
        label: "최근 28일",
        data: current,
        borderColor: colors.current,
      }
      const previous_dataset = {
        label: "지난 28일",
        data: previous,
        borderColor: colors.previous,
        borderDash: [3, 3],
      }
      const all_data = current.concat(previous)
      chart.options.scales.y.max = getMaxScale(all_data)
      chart.options.scales.y.min = getMinScale(all_data)
      chart.data.datasets = [current_dataset, previous_dataset]
      chart.data.labels = labels
      chart.update()
    })
  }
}

export default ChartHook
