// See the Tailwind configuration guide for advanced usage
// https://tailwindcss.com/docs/configuration

let plugin = require('tailwindcss/plugin')

module.exports = {
  content: [
    './js/**/*.js',
    '../lib/*_web.ex',
    '../lib/*_web/**/*.*ex'
  ],
  theme: {
    extend: {
      colors: {
        base: "#F9F9FA",
        "base-dark": "#161615",
        "base-dark-hover": "#1F1F1F"
      },
      fontFamily: {
        lato: ["Lato", "ui-sans-serif", "system-ui"],
      },
      fontSize: {
        h1: ["42px", { "lineHeight": "48px", "fontWeight": "700" }],
        h2: ["36px", { "lineHeight": "44px", "fontWeight": "700" }],
        h3: ["24px", { "lineHeight": "32px", "fontWeight": "700" }],
        h4: ["18px", { "lineHeight": "24px", "fontWeight": "700" }],
        slackHeader: ["22px", { "lineHeight": "30px", "fontWeight": "700" }],
        body1: ["16px", { "lineHeight": "24px", "fontWeight": "400" }],
        body2: ["14px", { "lineHeight": "20px", "fontWeight": "400" }],
        body3: ["12px", { "lineHeight": "16px", "fontWeight": "400" }],
        slackBody: ["15px", { "lineHeight": "22px", "fontWeight": "400" }],
      },
      animation: {
        "spin-slow": "spin 18s linear infinite",
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('daisyui'),
    plugin(({ addVariant }) => addVariant('phx-no-feedback', ['&.phx-no-feedback', '.phx-no-feedback &'])),
    plugin(({ addVariant }) => addVariant('phx-click-loading', ['&.phx-click-loading', '.phx-click-loading &'])),
    plugin(({ addVariant }) => addVariant('phx-submit-loading', ['&.phx-submit-loading', '.phx-submit-loading &'])),
    plugin(({ addVariant }) => addVariant('phx-change-loading', ['&.phx-change-loading', '.phx-change-loading &']))
  ],
  daisyui: {
    themes: [
      {
        mytheme: {
          neutral: "#f0f0f0",
          "neutral-content": "#000000",

          primary: "#000000",
          "primary-content": "#ffffff",

          secondary: "#f6d860",
          
          accent: "#37cdbe",

          "base-100": "#ffffff",
          "base-200": "#f0f0f0",
          "base-content": "#161615"
        }
      }
    ]
  }
}
