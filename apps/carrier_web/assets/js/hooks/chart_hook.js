import { Chart, registerables } from 'chart.js'

Chart.register(...registerables)

const colors = {
  default: "#1C110A",
  current: "#C91000",
  previous: "#92B3F4",
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

const deriveTickCount = (min, max) => {
  const diff = max - min
  if (diff % 5 === 0) {
    return 6
  } else if (diff % 6 === 0) {
    return 7
  } else if (diff % 4 === 0) {
    return 5
  } else if (diff % 3 === 0) {
    return 4
  } else if (diff % 2 === 0) {
    return 3
  } else {
    return 2
  }
}

const bgColorPlugIn = {
  id: 'custom_canvas_background_color',
  beforeDraw: (chart) => {
    const { ctx } = chart;
    ctx.save();
    ctx.globalCompositeOperation = 'destination-over';
    ctx.fillStyle = 'white';
    ctx.fillRect(0, 0, chart.width, chart.height);
    ctx.restore();
  }
};

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
      plugins: [bgColorPlugIn],
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
                size: 12,
                weight: 700,
                color: '#929292',
              },
              boxHeight: 1,
            },
            position: 'right',
          },
          title: {
            display: true,
            color: '#929292',
            font: {
              weight: 'bold',
              size: 12,
            },
            text: 'TITLE',
            padding: 30,
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
            grid: {
              borderDash: [6, 6],
            },
            ticks: {
              count: 5,
              font: {
                size: 20,
                weight: 700,
              },
            },
            padding: {
              left: -60,
            }
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
      const maxScale = getMaxScale(all_data)
      const minScale = getMinScale(all_data)
      chart.options.scales.y.max = maxScale
      chart.options.scales.y.min = minScale
      chart.options.scales.y.ticks.count = deriveTickCount(minScale, maxScale)
      chart.data.datasets = [current_dataset, previous_dataset]
      chart.data.labels = labels
      chart.options.plugins.title.text = `${key} 일일 데이터`
      chart.update()
    })
  }
}

export default ChartHook
