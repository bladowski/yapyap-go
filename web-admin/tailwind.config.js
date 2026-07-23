/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        yapyap: {
          green: '#00B341',
          'green-dark': '#008a32',
        },
      },
    },
  },
  plugins: [],
};
