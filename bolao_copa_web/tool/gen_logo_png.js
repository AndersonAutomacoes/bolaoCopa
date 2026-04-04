/**
 * Generates assets/branding/logo.png (128x128, green + gold circle).
 * Run: node tool/gen_logo_png.js
 */
const fs = require("fs");
const path = require("path");
const zlib = require("zlib");

function crc32(buf) {
  let c = 0xffffffff;
  for (let i = 0; i < buf.length; i++) {
    c ^= buf[i];
    for (let k = 0; k < 8; k++) {
      c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    }
  }
  return (c ^ 0xffffffff) >>> 0;
}

function chunk(typeStr, data) {
  const type = Buffer.from(typeStr, "ascii");
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length, 0);
  const crcBuf = Buffer.concat([type, data]);
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(crcBuf), 0);
  return Buffer.concat([len, type, data, crc]);
}

const w = 128;
const h = 128;
const cx = w / 2;
const cy = h / 2;
const rad = 38;
const raw = [];
for (let y = 0; y < h; y++) {
  raw.push(0); // filter
  for (let x = 0; x < w; x++) {
    const dx = x - cx + 0.5;
    const dy = y - cy + 0.5;
    const inCircle = dx * dx + dy * dy <= rad * rad;
    if (inCircle) {
      raw.push(0xc9, 0xa2, 0x27, 255);
    } else {
      raw.push(0x1b, 0x7f, 0x3a, 255);
    }
  }
}
const idat = zlib.deflateSync(Buffer.from(raw), { level: 9 });

const ihdr = Buffer.alloc(13);
ihdr.writeUInt32BE(w, 0);
ihdr.writeUInt32BE(h, 4);
ihdr[8] = 8;
ihdr[9] = 6;
ihdr[10] = 0;
ihdr[11] = 0;
ihdr[12] = 0;

const sig = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
const png = Buffer.concat([
  sig,
  chunk("IHDR", ihdr),
  chunk("IDAT", idat),
  chunk("IEND", Buffer.alloc(0)),
]);

const out = path.join(__dirname, "..", "assets", "branding", "logo.png");
fs.mkdirSync(path.dirname(out), { recursive: true });
fs.writeFileSync(out, png);
console.log("Wrote", out, png.length, "bytes");
