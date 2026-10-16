const fs = require('fs');
const path = require('path');
const pngToIco = require('png-to-ico').default || require('png-to-ico');

const inputPng = path.join(__dirname, 'assets', 'icon.png');
const outputIco = path.join(__dirname, 'assets', 'icon.ico');

pngToIco(inputPng)
  .then(buf => {
    fs.writeFileSync(outputIco, buf);
    console.log('SUCCESS: Generated authentic Windows multi-res icon.ico with length:', buf.length);
  })
  .catch(err => {
    console.error('ERROR converting icon:', err);
    process.exit(1);
  });
