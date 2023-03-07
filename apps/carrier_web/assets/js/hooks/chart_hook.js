import { Chart, registerables } from 'chart.js'

Chart.register(...registerables)

const colors = {
  default: "#1C110A",
  current: "#C91000",
  previous: "#92B3F4",
}

const getScaleBounds = (ns) => {
  const { value: flooredMinSF, e: flooredMinE } = getFlooredMin(ns)
  const { value: ceiledMaxSF, e: ceiledMaxE } = getCeiledMax(ns)
  const flooredMin = parseFloat(`${flooredMinSF}e${flooredMinE}`)
  const ceiledMax = parseFloat(`${ceiledMaxSF}e${ceiledMaxE}`)
  let finalMin, finalMax
  if (ceiledMaxE > flooredMinE) {
    finalMax = ceiledMax
    finalMin = getMaxNumberWithEButSmallerThanGivenValue(ceiledMaxE, flooredMin)
  } else if (ceiledMaxE < flooredMinE) {
    finalMax = getMinNumberWithEButLargerThanGivenValue(flooredMinE, ceiledMax)
    finalMin = flooredMin
  } else {
    finalMax = ceiledMax
    finalMin = flooredMin
  }
  return { max: finalMax, min: finalMin }
}

const getMinNumberWithEButLargerThanGivenValue = (e, value) => {
  const rec = (candidateSF, value) => {
    const candidate = parseFloat(`${candidateSF}e${e}`)
    if (candidate >= value) {
      return candidate
    } else {
      return rec(candidateSF + 1, value)
    }
  }
  return rec(-9, value)
}

const getMaxNumberWithEButSmallerThanGivenValue = (e, value) => {
  const rec = (candidateSF, value) => {
    const candidate = parseFloat(`${candidateSF}e${e}`)
    if (candidate <= value) {
      return candidate
    } else {
      return rec(candidateSF - 1, value)
    }
  }
  return rec(9, value)
}

const getFlooredMin = (ns) => {
  const [significantFigures, exponent] = (Math.min(...ns)).toExponential().split('e')
  const flooredSignificantFigures = Math.floor(parseFloat(significantFigures)).toString()
  return { value: flooredSignificantFigures, e: parseInt(exponent) }
}

const getCeiledMax = (ns) => {
  const [significantFigures, exponent] = (Math.max(...ns)).toExponential().split('e')
  const ceiledSignificantFigures = Math.ceil(parseFloat(significantFigures)).toString()
  return { value: ceiledSignificantFigures, e: parseInt(exponent) }
}

const getTickCount = (min, max) => {
  const diff = (max - min) / parseInt(`1e${min.toExponential().split('e')[1]}`)
  if (diff % 19 === 0) {
    return 20
  } else if (diff % 17 === 0) {
    return 18
  } else if (diff % 13 === 0) {
    return 14
  } else if (diff % 11 === 0) {
    return 12
  } else if (diff % 7 === 0) {
    return 8
  } else if (diff % 5 === 0) {
    return 6
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
        responsive: true,
        maintainAspectRatio: false,
        layout: {
          padding: {
            right: 12
          }
        },
        elements: {
          point: {
            radius: 0,
          }
        },
        plugins: {
          legend: {
            display: true,
            labels: {
              boxWidth: 20,
              font: {
                size: 12,
                weight: 500,
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
              size: 13,
            },
            text: 'TITLE',
            padding: {
              top: 26,
              bottom: 34
            },
          }
        },
        scales: {
          y: {
            title: {
              display: true,
              font: {
                size: 12,
                weight: 700,
                color: '#929292'
              }
            },
            grid: {
              borderDash: [6, 6]
            },
            ticks: {
              count: 50,
              font: {
                size: 12,
                weight: 700,
                color: '#929292'
              }
            },
            padding: {
              left: -60,
            }
          },
          x: {
            title: {
              display: true,
              font: {
                size: 12,
                weight: 700,
                color: '#929292'
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
                size: 12,
                weight: 700,
                color: '#929292'
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
      const { max: maxScale, min: minScale } = getScaleBounds(all_data)
      const titleText = meta.window_size === 1 ? `${key} 일일 데이터` : `${key} 7일 이동합계`
      chart.options.scales.y.max = maxScale
      chart.options.scales.y.min = minScale
      chart.options.scales.y.ticks.count = getTickCount(minScale, maxScale)
      chart.data.datasets = [current_dataset, previous_dataset]
      chart.data.labels = labels
      chart.options.plugins.title.text = titleText
      chart.update()
    })
  }
}

export default ChartHook
