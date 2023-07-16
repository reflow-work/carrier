const infiniteScrollMargin = 400
const infiniteScrollThreshold = 100

export default InfiniteScrollHook = {
  mounted() {
    this.observer = new IntersectionObserver(
      (entries) => {
        const target = entries[0]

        if (target.isIntersecting) {
          this.loadMore()
        }
      },
      {
        root: null,
        rootMargin: `${infiniteScrollMargin}px`,
        threshold: 1.0
      }
    )

    this.observer.observe(this.el)
  },
  updated() {
    if (this.checkVisible(this.el)) {
      this.loadMore()
    }
  },
  destroyed() {
    this.observer.unobserve(this.el);
  },
  loadMore() {
    this.pushEvent("load_more")
  },
  checkVisible(el) {
    var rect = el.getBoundingClientRect()
    var viewHeight = Math.max(document.documentElement.clientHeight, window.innerHeight)

    return rect.top - infiniteScrollMargin - infiniteScrollThreshold <= viewHeight
  }
}
