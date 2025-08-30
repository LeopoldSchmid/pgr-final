const colors = require('tailwindcss/colors')

module.exports = {
  content: [
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}'
  ],
  theme: {
    extend: {
      colors: {
        'primary-accent': '#E4A094',
        'background-primary': '#F5F4F9',
        'background-primary-dark': '#D4D1D7',
        'background-secondary': '#C9E0DD',
        'background-secondary-dark': '#B2CECB',
        'text-primary': '#1C1C1E',
        'text-secondary': '#1C1C1E',
        'accent-yellow': '#DDCA7E',
        'accent-yellow-dark': '#D0B64F',
        'accent-green': '#A9B9A2',
        'accent-green-dark': '#94A68F',
        'accent-red': '#E4A094',
        'accent-red-dark': '#D09484',
        'accent-purple': '#BEC8F9',
        'accent-purple-dark': '#7A83B3',
        'accent-teal': '#C9E0DD',
        'accent-teal-dark': '#B2CECB',
        'accent-brown': '#EFE2DB',
        'accent-brown-dark': '#E1CEC7',
      },
      fontFamily: {
        'sans': ['Instrument Sans', 'system-ui', 'sans-serif'],
      },
    },
  },
  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/aspect-ratio'),
    require('@tailwindcss/typography'),
  ],
}
